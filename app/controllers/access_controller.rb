class AccessController < ApplicationController
  skip_before_action :authenticate_user!, only: [:identification]
  before_action :load_today_logs, only: [:identification, :process_identification]

  def identification
  end

  def process_identification
    identifier = params[:identifier]

    if identifier.blank?
      flash.now[:access_alert] = t("flash.access.blank_identifier")
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("toast_container", partial: "access/identification_result")
        end
        format.html { render :identification }
      end
      return
    end

    normalized = normalize_identifier(identifier)
    if normalized&.length == 11 && !CPF.valid?(normalized)
      flash.now[:access_alert] = t("flash.access.invalid_cpf")
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("toast_container", partial: "access/identification_result")
        end
        format.html { render :identification }
      end
      return
    end

    person = find_person(identifier)

    if person
      meal = Meal.find_current
      access_log = record_access_attempt(person, meal)

      case access_log.status.to_sym
      when :allowed
        flash.now[:access_notice] = t("flash.access.access_granted", name: person.name, meal: meal.name.downcase)
      when :denied
        flash.now[:access_alert] = t("flash.access.access_denied", result: access_log.access_result)
      when :warning
        flash.now[:access_alert] = t("flash.access.access_warning", result: access_log.access_result)
      end
    else
      flash.now[:access_alert] = t("flash.access.not_found")
      flash.now[:access_identifier] = identifier
      access_log = nil
    end

    respond_to do |format|
      format.turbo_stream do
        streams = [ turbo_stream.prepend("toast_container", partial: "access/identification_result") ]
        streams << turbo_stream.prepend("today_logs_body", partial: "access_logs/log_card", locals: { log: access_log }) if access_log
        streams << turbo_stream.append("toast_container", partial: "access/register_trigger", locals: { identifier: identifier }) if access_log.nil?
        render turbo_stream: streams
      end
      format.html { render :identification }
    end
  end

  private

  def normalize_identifier(identifier)
    return unless identifier.present?

    identifier.to_s.gsub(/[^0-9]/, "")
  end

  def load_today_logs
    return unless user_signed_in?

    @today_logs = AccessLog.includes(:personable)
                           .where(created_at: Time.zone.now.all_day)
                           .order(created_at: :desc)
                           .limit(30)
  end

  def find_person(identifier)
    normalized_id = normalize_identifier(identifier)
    Student.find_by(qr_code_hash: identifier) ||
    Student.find_by(registration: identifier) ||
    Student.find_by(cpf: normalized_id) ||
    Visitor.find_by(qr_code_hash: identifier) ||
    Visitor.find_by(cpf: normalized_id)
  end

  def record_access_attempt(person, meal)
    if meal.nil?
      return AccessLog.create(
        personable: person,
        status: :warning,
        access_result: I18n.t("flash.access.no_meal")
      )
    end

    if AccessLog.exists?(personable: person, status: :allowed, created_at: Date.current.all_day)
      return AccessLog.create(
        personable: person,
        status: :denied,
        access_result: I18n.t("flash.access.already_consumed")
      )
    end

    AccessLog.create!(
      personable: person,
      status: :allowed,
      access_time: Time.current,
      access_result: I18n.t("flash.access.approved", meal: meal.name.capitalize)
    )
  end
end
