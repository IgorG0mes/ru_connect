require "mercadopago"
require "mercadopago/webhook/validator"

class MercadoPagoService
  class << self
    def create_preference(payment, back_urls:, notification_url:)
      result = sdk.preference.create({
        items: [
          {
            title: "#{payment.quantity} ficha(s) - RU Connect",
            quantity: 1,
            currency_id: "BRL",
            unit_price: payment.amount.to_f
          }
        ],
        external_reference: payment.external_reference,
        back_urls: back_urls,
        auto_return: "approved",
        notification_url: notification_url
      })

      response = result[:response]
      init_point = response.is_a?(Hash) ? (response["init_point"].presence || response["sandbox_init_point"]) : nil

      unless success_status?(result[:status]) && init_point.present?
        raise "criacao de preference falhou (status=#{result[:status]})"
      end

      payment.update!(mp_preference_id: response["id"])
      init_point
    end

    def fetch_payment(mp_payment_id)
      sdk.payment.get(mp_payment_id)[:response]
    end

    def fetch_merchant_order(order_id)
      sdk.merchant_order.get(order_id)[:response]
    end

    def verify_webhook_signature?
      ENV.fetch("MP_VERIFY_WEBHOOK_SIGNATURE", "true") != "false"
    end

    def valid_signature?(x_signature:, x_request_id:, data_id:)
      last_reason = nil
      webhook_secrets.each do |secret|
        Mercadopago::Webhook::Validator.validate(x_signature, x_request_id, data_id, secret)
        return true
      rescue Mercadopago::Webhook::InvalidWebhookSignatureError => e
        last_reason = e.reason
      end
      Rails.logger.warn("[mercadopago] assinatura de webhook invalida: #{last_reason}") if last_reason
      false
    end

    private

    def success_status?(status)
      (200..299).cover?(status.to_i)
    end

    def sdk
      Mercadopago::SDK.new(access_token)
    end

    def access_token
      ENV.fetch("MP_ACCESS_TOKEN")
    end

    def webhook_secrets
      ENV.fetch("MP_WEBHOOK_SECRET").split(",").map(&:strip).reject(&:empty?)
    end
  end
end
