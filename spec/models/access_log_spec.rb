require "rails_helper"

RSpec.describe AccessLog, type: :model do
  let(:student) do
    Student.create!(
      name:         "João Silva",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      course:       "Engenharia",
      status:       "active"
    )
  end

  let(:visitor) do
    Visitor.create!(
      name: "Ana Visitante",
      cpf:  CPF.generate(stripped: true)
    )
  end

  describe "validations" do
    it "is valid with a status and a personable" do
      expect(AccessLog.new(personable: student, status: :allowed)).to be_valid
    end

    it "is invalid without a status" do
      log = AccessLog.new(personable: student, status: nil)
      expect(log).not_to be_valid
      expect(log.errors[:status]).to be_present
    end

    it "is invalid without a personable" do
      expect(AccessLog.new(status: :allowed)).not_to be_valid
    end
  end

  describe "enum status" do
    it "defines the expected statuses" do
      expect(AccessLog.statuses).to eq(
        "allowed" => 0, "denied" => 1, "warning" => 2
      )
    end
  end

  describe "#identifier" do
    it "returns the registration for a student" do
      log = AccessLog.new(personable: student, status: :allowed)
      expect(log.identifier).to eq(student.registration)
    end

    it "falls back to the cpf when the student has no registration" do
      student.update!(registration: nil)
      log = AccessLog.new(personable: student, status: :allowed)
      expect(log.identifier).to eq(student.cpf)
    end

    it "returns the cpf for a visitor" do
      log = AccessLog.new(personable: visitor, status: :allowed)
      expect(log.identifier).to eq(visitor.cpf)
    end
  end

  describe "#person_name" do
    it "returns the personable name" do
      log = AccessLog.new(personable: student, status: :allowed)
      expect(log.person_name).to eq(student.name)
    end
  end

  describe "#course_name" do
    it "returns the course for a student" do
      log = AccessLog.new(personable: student, status: :allowed)
      expect(log.course_name).to eq(student.course)
    end

    it "returns the visitor fallback for a visitor (no course)" do
      log = AccessLog.new(personable: visitor, status: :allowed)
      expect(log.course_name).to eq(I18n.t("models.access_log.visitor_fallback"))
    end
  end
end
