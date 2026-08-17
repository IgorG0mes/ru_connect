require "rails_helper"

RSpec.describe Payment, type: :model do
  def build_student
    Student.create!(
      name:         "Aluno #{SecureRandom.hex(4)}",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "stu_#{SecureRandom.hex(4)}@example.com",
      course:       "Engenharia",
      status:       :active
    )
  end

  def build_payment(overrides = {})
    Payment.new({
      payable:            build_student,
      quantity:           3,
      amount:             19.50,
      external_reference: SecureRandom.uuid,
      status:             :pending
    }.merge(overrides))
  end

  describe "validations" do
    it "is valid with default attributes" do
      expect(build_payment).to be_valid
    end

    it "requires an external_reference" do
      payment = build_payment(external_reference: nil)
      expect(payment).not_to be_valid
      expect(payment.errors[:external_reference]).to be_present
    end

    it "enforces uniqueness of external_reference" do
      ref = SecureRandom.uuid
      build_payment(external_reference: ref).save!
      dup = build_payment(external_reference: ref)
      expect(dup).not_to be_valid
      expect(dup.errors[:external_reference]).to be_present
    end

    it "rejects a quantity below 1" do
      expect(build_payment(quantity: 0)).not_to be_valid
    end

    it "rejects a quantity above the maximum" do
      expect(build_payment(quantity: Payment::MAX_QUANTITY + 1)).not_to be_valid
    end

    it "rejects a non-integer quantity" do
      expect(build_payment(quantity: 1.5)).not_to be_valid
    end
  end

  describe "enum status" do
    it "defines the expected statuses" do
      expect(Payment.statuses).to eq(
        "pending" => 0, "approved" => 1, "rejected" => 2, "cancelled" => 3, "refunded" => 4
      )
    end
  end

  describe "#confirm_and_credit!" do
    it "credits the payable with the purchased quantity of tickets" do
      payment = build_payment(quantity: 3, amount: 19.50)
      payment.save!

      expect {
        payment.confirm_and_credit!(mp_amount: 19.50, mp_payment_id: "MP-1")
      }.to change { payment.payable.reload.ticket_balance }.by(3)

      expect(payment.reload).to be_approved
      expect(payment.mp_payment_id).to eq("MP-1")
    end

    it "is idempotent: a second call does not credit again" do
      payment = build_payment(quantity: 3, amount: 19.50)
      payment.save!
      payment.confirm_and_credit!(mp_amount: 19.50, mp_payment_id: "MP-1")

      expect {
        payment.confirm_and_credit!(mp_amount: 19.50, mp_payment_id: "MP-1")
      }.not_to change { payment.payable.reload.ticket_balance }
    end

    it "raises and does not credit when the confirmed amount diverges" do
      payment = build_payment(quantity: 3, amount: 19.50)
      payment.save!

      expect {
        payment.confirm_and_credit!(mp_amount: 5.0, mp_payment_id: "MP-1")
      }.to raise_error(ArgumentError)

      expect(payment.payable.reload.ticket_balance).to eq(0)
      expect(payment.reload).to be_pending
    end
  end
end
