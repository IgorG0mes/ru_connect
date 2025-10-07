class AccessController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :identification, :process_identification ]

  def identification
  end

  def process_identification
    identifier = params[:identifier]

    person = find_person(identifier)

    if person
      meal = Meal.find_current

      access_log = record_access_attempt(person, meal)

      case access_log.status.to_sym
      when :allowed
        flash.now[:notice] = "ACESSO LIBERADO! Bem-vindo(a) #{person.name}."
      when :denied
        flash.now[:alert] = "ACESSO NEGADO: #{access_log.denial_reason}"
      when :warning
        flash.now[:alert] = "AVISO: #{access_log.denial_reason}"
      end
    else
      flash.now[:alert] = "Usuário não encontrado. Necessário Cadastro."
    end

    render :identification
  end

  private

  def find_person(identifier)
    Student.find_by(qr_code_hash: identifier) ||
    Student.find_by(registration: identifier) ||
    Student.find_by(cpf: identifier) ||
    Visitor.find_by(qr_code_hash: identifier) ||
    Visitor.find_by(cpf: identifier)
  end

  def record_access_attempt(person, meal)
    if meal.nil?
      return AccessLog.create(
        personable: person,
        status: :warning,
        denial_reason: "Refeição não está disponível no horário atual."
      )
    end

    if AccessLog.exists?(personable: person, status: :allowed, created_at: Date.current.all_day)
      return AccessLog.create(
        personable: person,
        status: :denied,
        denial_reason: "Não é possível acessar novamente. Acesso já consumido hoje."
      )
    end

    AccessLog.create!(personable: person, status: :allowed, access_time: Time.current)
  end
end
