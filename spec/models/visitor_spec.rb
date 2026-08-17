require "rails_helper"

RSpec.describe Visitor, type: :model do
  def build_visitor(overrides = {})
    Visitor.new({
      name:  "Ana Visitante",
      cpf:   CPF.generate(stripped: true),
      email: "ana_#{SecureRandom.hex(4)}@example.com"
    }.merge(overrides))
  end

  describe "validations" do
    it "is valid with default attributes" do
      expect(build_visitor).to be_valid
    end

    it "is invalid without a name" do
      visitor = build_visitor(name: nil)
      expect(visitor).not_to be_valid
      expect(visitor.errors[:name]).to be_present
    end

    it "is invalid without a cpf" do
      visitor = build_visitor(cpf: nil)
      expect(visitor).not_to be_valid
      expect(visitor.errors[:cpf]).to be_present
    end

    it "is invalid with a malformed cpf" do
      visitor = build_visitor(cpf: "12345678900")
      expect(visitor).not_to be_valid
      expect(visitor.errors[:cpf]).to be_present
    end

    it "is invalid with a negative ticket_balance" do
      visitor = build_visitor(ticket_balance: -1)
      expect(visitor).not_to be_valid
      expect(visitor.errors[:ticket_balance]).to be_present
    end
  end

  describe "ticket wallet" do
    it "credits and consumes tickets" do
      visitor = build_visitor(ticket_balance: 1)
      visitor.save!
      visitor.credit_tickets!(2)
      expect(visitor.reload.ticket_balance).to eq(3)
      expect(visitor.consume_ticket!).to be(true)
      expect(visitor.reload.ticket_balance).to eq(2)
    end
  end

  describe "callbacks" do
    it "strips non-digit characters from cpf before validation" do
      cpf = CPF.generate
      visitor = build_visitor(cpf: cpf)
      visitor.valid?
      expect(visitor.cpf).to eq(cpf.gsub(/\D/, ""))
    end

    it "generates a qr_code_hash after create" do
      visitor = build_visitor
      visitor.save!
      expect(visitor.reload.qr_code_hash).to be_present
    end
  end

  describe "associations" do
    it "has many polymorphic access_logs" do
      visitor = build_visitor
      visitor.save!
      log = visitor.access_logs.create!(status: :allowed)
      expect(log.personable).to eq(visitor)
      expect(log.personable_type).to eq("Visitor")
    end
  end

  describe "#generate_qr_code_svg" do
    it "returns nil when qr_code_hash is blank" do
      visitor = build_visitor
      expect(visitor.generate_qr_code_svg).to be_nil
    end

    it "returns an svg string when qr_code_hash is present" do
      visitor = build_visitor
      visitor.save!
      expect(visitor.generate_qr_code_svg).to include("<svg")
    end
  end
end
