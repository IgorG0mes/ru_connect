class FinderController < ApplicationController
  skip_before_action :authenticate_user!
  rate_limit to: 10, within: 1.minute, by: -> { session.id },
             with: -> { redirect_to finder_path, alert: I18n.t("finder.index.rate_limited") },
             only: [:search]

  def index
    cpf_raw = session.delete(:finder_cpf)
    return unless cpf_raw.present?

    cpf = cpf_raw.to_s.gsub(/[^0-9]/, "")

    unless cpf.length == 11 && CPF.valid?(cpf)
      flash.now[:alert] = t("finder.index.invalid_cpf")
      return
    end

    @person = Student.find_by(cpf: cpf) || Visitor.find_by(cpf: cpf)
    @person_type = @person.class.name.downcase.to_sym if @person

    if @person
      @recent_logs = @person.access_logs.order(created_at: :desc).limit(3)
    else
      flash.now[:alert] = t("finder.index.not_found")
    end
  end

  def search
    session[:finder_cpf] = params[:cpf]
    redirect_to finder_path
  end
end
