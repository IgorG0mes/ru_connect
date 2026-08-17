class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: :webhook

  SGID_PURPOSE = "payment_topup".freeze

  rate_limit to: 10, within: 1.minute, by: -> { session.id.presence || request.ip },
             with: -> { redirect_to finder_path, alert: I18n.t("flash.payments.rate_limited") },
             only: [:create]

  def create
    payable = locate_payable
    return redirect_to(finder_path, alert: t("flash.payments.invalid_person")) unless payable

    unit_price = TicketPrice.price_for(payable.class.name)
    return redirect_to(finder_path(cpf: payable.cpf), alert: t("flash.payments.price_unset")) unless unit_price

    quantity = params[:quantity].to_i
    payment = payable.payments.new(
      quantity: quantity,
      amount: unit_price * quantity,
      external_reference: SecureRandom.uuid,
      status: :pending
    )

    unless payment.save
      return redirect_to finder_path(cpf: payable.cpf), alert: t("flash.payments.invalid_quantity")
    end

    init_point = MercadoPagoService.create_preference(
      payment,
      back_urls: {
        success: payment_success_url,
        failure: payment_failure_url,
        pending: payment_pending_url
      },
      notification_url: mercadopago_webhook_url
    )

    redirect_to init_point, allow_other_host: true
  rescue => e
    Rails.logger.error("[payments] falha ao iniciar pagamento: #{e.class}: #{e.message}")
    redirect_to finder_path, alert: t("flash.payments.gateway_error")
  end

  def webhook
    return head :unauthorized unless signature_ok?

    if resource_id.present?
      case notification_topic
      when "payment"        then process_payment_notification(resource_id)
      when "merchant_order" then process_merchant_order_notification(resource_id)
      else Rails.logger.info("[payments] webhook ignorado: topic=#{notification_topic.inspect}")
      end
    end

    head :ok
  end

  def success
    @payment = Payment.find_by(external_reference: params[:external_reference])
    @person = @payment&.payable
  end

  def failure; end
  def pending; end

  private

  def locate_payable
    return if params[:payable_sgid].blank?

    GlobalID::Locator.locate_signed(params[:payable_sgid], for: SGID_PURPOSE)
  end

  def signature_ok?
    return true unless MercadoPagoService.verify_webhook_signature?

    valid_signature?
  end

  def valid_signature?
    MercadoPagoService.valid_signature?(
      x_signature: request.headers["x-signature"],
      x_request_id: request.headers["x-request-id"],
      data_id: resource_id
    )
  end

  def notification_topic
    (params[:type] || params[:topic]).to_s
  end

  def resource_id
    request.query_parameters["data.id"].presence ||
      params["data.id"].presence ||
      params.dig(:data, :id).presence ||
      request.query_parameters["id"].presence ||
      params["id"].presence
  end

  def process_payment_notification(mp_payment_id)
    mp_payment = MercadoPagoService.fetch_payment(mp_payment_id)
    credit_payment(external_reference: mp_payment["external_reference"],
                   status: mp_payment["status"],
                   amount: mp_payment["transaction_amount"],
                   mp_payment_id: mp_payment_id)
  end

  def process_merchant_order_notification(order_id)
    order = MercadoPagoService.fetch_merchant_order(order_id)
    approved = (order["payments"] || []).find { |p| p["status"] == "approved" }
    return unless approved

    credit_payment(external_reference: order["external_reference"],
                   status: "approved",
                   amount: approved["transaction_amount"],
                   mp_payment_id: approved["id"].to_s)
  end

  def credit_payment(external_reference:, status:, amount:, mp_payment_id:)
    return unless status == "approved"

    payment = Payment.find_by(external_reference: external_reference)
    return unless payment

    payment.confirm_and_credit!(mp_amount: amount, mp_payment_id: mp_payment_id)
  rescue ArgumentError => e
    Rails.logger.error("[payments] inconsistencia ao creditar pagamento #{mp_payment_id}: #{e.message}")
  end
end
