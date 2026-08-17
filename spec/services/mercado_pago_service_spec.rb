require "rails_helper"

RSpec.describe MercadoPagoService do
  let(:secret) { "test_webhook_secret" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("MP_WEBHOOK_SECRET").and_return(secret)
  end

  def signed_header(data_id:, request_id:, ts:)
    manifest = "id:#{data_id.downcase};request-id:#{request_id};ts:#{ts};"
    hash = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)
    "ts=#{ts},v1=#{hash}"
  end

  describe ".valid_signature?" do
    let(:data_id)    { "1234567890" }
    let(:request_id) { "req-#{SecureRandom.hex(4)}" }
    let(:ts)         { Time.now.to_i.to_s }

    it "returns true for a correctly signed, recent notification (ts em segundos)" do
      header = signed_header(data_id: data_id, request_id: request_id, ts: ts)

      expect(
        described_class.valid_signature?(
          x_signature: header, x_request_id: request_id, data_id: data_id
        )
      ).to be(true)
    end

    it "accepts a signature made with the SECOND of several configured secrets" do
      prod_secret = "prod_webhook_secret"
      allow(ENV).to receive(:fetch).with("MP_WEBHOOK_SECRET").and_return("#{secret},#{prod_secret}")

      manifest = "id:#{data_id.downcase};request-id:#{request_id};ts:#{ts};"
      hash = OpenSSL::HMAC.hexdigest("SHA256", prod_secret, manifest)
      header = "ts=#{ts},v1=#{hash}"

      expect(
        described_class.valid_signature?(
          x_signature: header, x_request_id: request_id, data_id: data_id
        )
      ).to be(true)
    end

    it "returns false when the signature hash is tampered" do
      header = "ts=#{ts},v1=deadbeef"

      expect(
        described_class.valid_signature?(
          x_signature: header, x_request_id: request_id, data_id: data_id
        )
      ).to be(false)
    end

    it "returns false when the signature header is missing" do
      expect(
        described_class.valid_signature?(
          x_signature: nil, x_request_id: request_id, data_id: data_id
        )
      ).to be(false)
    end

    it "still validates a correctly-signed older notification (suporta retentativas do MP)" do
      old_ts = (Time.now.to_i - 3_600).to_s
      header = signed_header(data_id: data_id, request_id: request_id, ts: old_ts)

      expect(
        described_class.valid_signature?(
          x_signature: header, x_request_id: request_id, data_id: data_id
        )
      ).to be(true)
    end
  end

  describe ".create_preference" do
    let(:payment) { instance_double(Payment, amount: BigDecimal("25.0"), quantity: 2, external_reference: "ext-1") }
    let(:preference_resource) { instance_double(Mercadopago::Preference) }
    let(:sdk) { instance_double(Mercadopago::SDK, preference: preference_resource) }

    before do
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk)
      allow(ENV).to receive(:fetch).with("MP_ACCESS_TOKEN").and_return("token")
    end

    def call
      described_class.create_preference(
        payment,
        back_urls: { success: "s", failure: "f", pending: "p" },
        notification_url: "https://app/webhooks/mercadopago"
      )
    end

    it "passes the preference data as a positional Hash and returns the init_point" do
      expect(preference_resource).to receive(:create)
        .with(hash_including(:items, :external_reference, :back_urls, :auto_return, :notification_url))
        .and_return(status: 201, response: { "id" => "PREF-1", "init_point" => "https://mp/checkout" })
      expect(payment).to receive(:update!).with(mp_preference_id: "PREF-1")

      expect(call).to eq("https://mp/checkout")
    end

    it "raises when the Mercado Pago response is not successful" do
      allow(preference_resource).to receive(:create).and_return(
        status: 403, response: { "message" => "unauthorized" }
      )

      expect { call }.to raise_error(/preference/)
    end
  end
end
