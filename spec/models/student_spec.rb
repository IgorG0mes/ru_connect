require "rails_helper"

RSpec.describe Student, type: :model do
  def build_student(overrides = {})
    Student.new({
      name:         "João Silva",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "joao_#{SecureRandom.hex(4)}@example.com",
      course:       "Engenharia",
      status:       "active"
    }.merge(overrides))
  end

  describe "validations" do
    it "is valid with default attributes" do
      expect(build_student).to be_valid
    end

    it "is invalid with a negative ticket_balance" do
      student = build_student(ticket_balance: -1)
      expect(student).not_to be_valid
      expect(student.errors[:ticket_balance]).to be_present
    end

    it "is valid with a zero ticket_balance" do
      expect(build_student(ticket_balance: 0)).to be_valid
    end

    it "is invalid with a malformed cpf" do
      student = build_student(cpf: "12345678900")
      expect(student).not_to be_valid
      expect(student.errors[:cpf]).to be_present
    end

    it "is valid when cpf is blank" do
      expect(build_student(cpf: "")).to be_valid
    end
  end

  describe "enum status" do
    it "defines the expected statuses" do
      expect(Student.statuses).to eq(
        "active" => 0, "inactive" => 1, "suspended" => 2, "graduated" => 3
      )
    end
  end

  describe "callbacks" do
    it "strips non-digit characters from cpf before validation" do
      cpf = CPF.generate
      student = build_student(cpf: cpf)
      student.valid?
      expect(student.cpf).to eq(cpf.gsub(/\D/, ""))
    end

    it "generates a qr_code_hash after create" do
      student = build_student
      student.save!
      expect(student.reload.qr_code_hash).to be_present
    end
  end

  describe "associations" do
    it "has many polymorphic access_logs" do
      student = build_student
      student.save!
      log = student.access_logs.create!(status: :allowed)
      expect(log.personable).to eq(student)
      expect(log.personable_type).to eq("Student")
    end
  end

  describe "#generate_qr_code_svg" do
    it "returns nil when qr_code_hash is blank" do
      student = build_student
      expect(student.generate_qr_code_svg).to be_nil
    end

    it "returns an svg string when qr_code_hash is present" do
      student = build_student
      student.save!
      expect(student.generate_qr_code_svg).to include("<svg")
    end
  end

  describe "ticket wallet" do
    it "credits tickets" do
      student = build_student
      student.save!
      expect { student.credit_tickets!(3) }.to change { student.reload.ticket_balance }.by(3)
    end

    it "consumes one ticket and returns true when there is balance" do
      student = build_student(ticket_balance: 2)
      student.save!
      expect(student.consume_ticket!).to be(true)
      expect(student.reload.ticket_balance).to eq(1)
    end

    it "does not consume and returns false when balance is zero" do
      student = build_student(ticket_balance: 0)
      student.save!
      expect(student.consume_ticket!).to be(false)
      expect(student.reload.ticket_balance).to eq(0)
    end
  end
end
