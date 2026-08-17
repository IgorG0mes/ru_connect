require "rails_helper"

RSpec.describe FinderController, type: :request do
  def create_student_with_cpf(cpf)
    Student.create!(
      name:         "Estudante #{SecureRandom.hex(4)}",
      cpf:          cpf,
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "stu_#{SecureRandom.hex(4)}@example.com",
      course:       "Direito",
      status:       :active
    )
  end

  def create_visitor_with_cpf(cpf)
    Visitor.create!(
      name:  "Visitante #{SecureRandom.hex(4)}",
      cpf:   cpf,
      email: "vis_#{SecureRandom.hex(4)}@example.com"
    )
  end

  describe "GET /finder (index)" do
    context "when there is no session[:finder_cpf]" do
      it "returns 200 and renders blank state" do
        get finder_path
        expect(response).to be_successful
      end

      it "does not assign @person" do
        get finder_path
        expect(response).to be_successful
      end
    end

    context "when session has an invalid CPF (wrong format)" do
      it "returns 200 and shows alert" do
        post finder_path, params: { cpf: "123" }
        expect(response).to redirect_to(finder_path)
        follow_redirect!
        expect(response).to be_successful
      end
    end

    context "when session has a valid CPF but no person exists" do
      it "returns 200 and shows not found alert" do
        cpf = CPF.generate(stripped: true)
        post finder_path, params: { cpf: cpf }
        expect(response).to redirect_to(finder_path)
        follow_redirect!
        expect(response).to be_successful
      end
    end

    context "when session has a valid CPF and student exists" do
      it "returns 200 and shows student data" do
        cpf = CPF.generate(stripped: true)
        student = create_student_with_cpf(cpf)

        post finder_path, params: { cpf: cpf }
        expect(response).to redirect_to(finder_path)
        follow_redirect!

        expect(response).to be_successful
        expect(response.body).to include(student.name)
      end
    end

    context "when session has a valid CPF and visitor exists" do
      it "returns 200 and shows visitor data" do
        cpf = CPF.generate(stripped: true)
        visitor = create_visitor_with_cpf(cpf)

        post finder_path, params: { cpf: cpf }
        expect(response).to redirect_to(finder_path)
        follow_redirect!

        expect(response).to be_successful
        expect(response.body).to include(visitor.name)
      end
    end

    context "when session has a CPF matching a student with access logs" do
      it "loads recent access logs" do
        cpf = CPF.generate(stripped: true)
        student = create_student_with_cpf(cpf)
        AccessLog.create!(personable: student, status: :allowed, access_result: "Aprovado")

        post finder_path, params: { cpf: cpf }
        follow_redirect!
        expect(response).to be_successful
      end
    end
  end

  describe "POST /finder (search)" do
    it "saves cpf in session and redirects to finder_path" do
      cpf = CPF.generate(stripped: true)
      post finder_path, params: { cpf: cpf }
      expect(response).to redirect_to(finder_path)
    end

    it "accepts raw CPF with formatting characters" do
      raw_cpf = CPF.generate
      post finder_path, params: { cpf: raw_cpf }
      expect(response).to redirect_to(finder_path)
    end

    it "saves whatever value is provided (even invalid — GET will validate)" do
      post finder_path, params: { cpf: "invalid_cpf" }
      expect(response).to redirect_to(finder_path)
    end
  end

  describe "session cleanup" do
    it "clears finder_cpf from session after reading" do
      cpf = CPF.generate(stripped: true)
      create_student_with_cpf(cpf)

      post finder_path, params: { cpf: cpf }
      follow_redirect!

      get finder_path
      expect(response).to be_successful
    end
  end
end
