require "rails_helper"

RSpec.describe PaymentsController, type: :request do
  def create_student
    Student.create!(
      name:         "Aluno #{SecureRandom.hex(4)}",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "stu_#{SecureRandom.hex(4)}@example.com",
      course:       "Engenharia",
      status:       :active
    )
  end

  def sgid_for(record)
    record.to_sgid(for: PaymentsController::SGID_PURPOSE).to_s
  end

  before do
    TicketPrice.find_or_create_by!(payable_type: "Student") { |tp| tp.price = 6.25 }
  end

  describe "POST /payments (create)" do
    it "computes amount from quantity x unit price and redirects to the Mercado Pago checkout" do
      student = create_student
      allow(MercadoPagoService).to receive(:create_preference).and_return("https://mp/checkout")

      expect {
        post payments_path, params: { payable_sgid: sgid_for(student), quantity: "3" }
      }.to change { student.payments.count }.by(1)

      expect(response).to redirect_to("https://mp/checkout")
      payment = student.payments.last
      expect(payment).to be_pending
      expect(payment.quantity).to eq(3)
      expect(payment.amount).to eq(18.75)
    end

    it "does not create a payment when the quantity is out of range" do
      student = create_student

      expect {
        post payments_path, params: { payable_sgid: sgid_for(student), quantity: "0" }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(finder_path(cpf: student.cpf))
    end

    it "redirects with an error when no ticket price is configured for the type" do
      TicketPrice.where(payable_type: "Student").delete_all
      student = create_student

      expect {
        post payments_path, params: { payable_sgid: sgid_for(student), quantity: "3" }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(finder_path(cpf: student.cpf))
    end

    it "rejects an invalid/tampered signed global id" do
      expect {
        post payments_path, params: { payable_sgid: "tampered", quantity: "3" }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(finder_path)
    end
  end

  describe "POST /webhooks/mercadopago" do
    def create_pending_payment(student, ref:, quantity: 3, amount: 19.50)
      student.payments.create!(quantity: quantity, amount: amount, external_reference: ref, status: :pending)
    end

    it "credits the tickets once when the payment is approved" do
      student = create_student
      payment = create_pending_payment(student, ref: "ext-1")

      allow(MercadoPagoService).to receive(:valid_signature?).and_return(true)
      allow(MercadoPagoService).to receive(:fetch_payment).and_return(
        "status" => "approved", "transaction_amount" => 19.50, "external_reference" => "ext-1"
      )

      expect {
        post mercadopago_webhook_path, params: { type: "payment", "data.id" => "MP-1" }
      }.to change { student.reload.ticket_balance }.by(3)

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to be_approved
    end

    it "does not credit twice for duplicated notifications" do
      student = create_student
      create_pending_payment(student, ref: "ext-2")

      allow(MercadoPagoService).to receive(:valid_signature?).and_return(true)
      allow(MercadoPagoService).to receive(:fetch_payment).and_return(
        "status" => "approved", "transaction_amount" => 19.50, "external_reference" => "ext-2"
      )

      post mercadopago_webhook_path, params: { type: "payment", "data.id" => "MP-2" }

      expect {
        post mercadopago_webhook_path, params: { type: "payment", "data.id" => "MP-2" }
      }.not_to change { student.reload.ticket_balance }
    end

    it "returns 401 and does not credit when the signature is invalid" do
      student = create_student
      create_pending_payment(student, ref: "ext-3")

      allow(MercadoPagoService).to receive(:verify_webhook_signature?).and_return(true)
      allow(MercadoPagoService).to receive(:valid_signature?).and_return(false)
      expect(MercadoPagoService).not_to receive(:fetch_payment)

      expect {
        post mercadopago_webhook_path, params: { type: "payment", "data.id" => "MP-3" }
      }.not_to change { student.reload.ticket_balance }

      expect(response).to have_http_status(:unauthorized)
    end

    it "processes without a valid signature when verification is disabled" do
      student = create_student
      create_pending_payment(student, ref: "ext-noverify")

      allow(MercadoPagoService).to receive(:verify_webhook_signature?).and_return(false)
      expect(MercadoPagoService).not_to receive(:valid_signature?)
      allow(MercadoPagoService).to receive(:fetch_payment).and_return(
        "status" => "approved", "transaction_amount" => 19.50, "external_reference" => "ext-noverify"
      )

      expect {
        post mercadopago_webhook_path, params: { type: "payment", "data.id" => "MP-NV" }
      }.to change { student.reload.ticket_balance }.by(3)

      expect(response).to have_http_status(:ok)
    end

    it "credits via the IPN format (topic=payment, id)" do
      student = create_student
      create_pending_payment(student, ref: "ext-ipn")

      allow(MercadoPagoService).to receive(:valid_signature?).and_return(true)
      allow(MercadoPagoService).to receive(:fetch_payment).and_return(
        "status" => "approved", "transaction_amount" => 19.50, "external_reference" => "ext-ipn"
      )

      expect {
        post mercadopago_webhook_path, params: { topic: "payment", id: "MP-IPN" }
      }.to change { student.reload.ticket_balance }.by(3)
    end

    it "credits via a merchant_order notification" do
      student = create_student
      create_pending_payment(student, ref: "ext-mo")

      allow(MercadoPagoService).to receive(:valid_signature?).and_return(true)
      allow(MercadoPagoService).to receive(:fetch_merchant_order).and_return(
        "external_reference" => "ext-mo",
        "payments" => [
          { "id" => 999, "status" => "rejected", "transaction_amount" => 19.50 },
          { "id" => 1000, "status" => "approved", "transaction_amount" => 19.50 }
        ]
      )

      expect {
        post mercadopago_webhook_path, params: { topic: "merchant_order", id: "ORDER-1" }
      }.to change { student.reload.ticket_balance }.by(3)
    end
  end

  describe "status pages" do
    it "renders the success page without crediting anything" do
      get payment_success_path
      expect(response).to be_successful
    end

    it "renders the pending page" do
      get payment_pending_path
      expect(response).to be_successful
    end

    it "renders the failure page" do
      get payment_failure_path
      expect(response).to be_successful
    end
  end
end
