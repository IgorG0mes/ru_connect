require "rails_helper"

RSpec.describe StudentsController, type: :request do
  def valid_student_params(overrides = {})
    {
      name:         "João Silva",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "joao_#{SecureRandom.hex(4)}@example.com",
      course:       "Engenharia",
      status:       "active"
    }.merge(overrides)
  end

  def create_student(overrides = {})
    Student.create!(valid_student_params(overrides))
  end

  describe "unauthenticated access" do
    it "redirects to sign-in for index" do
      get students_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign-in for show" do
      student = create_student
      get student_path(student)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  before { ActionMailer::Base.deliveries.clear }

  describe "as admin" do
    include_context "with admin"

    describe "GET /students (index)" do
      it "returns 200 without query" do
        get students_path
        expect(response).to be_successful
      end

      it "returns results when searching by name" do
        create_student(name: "Maria Buscavel")
        get students_path, params: { q: "Buscavel" }
        expect(response).to be_successful
        expect(response.body).to include("Buscavel")
      end

      it "returns results when searching by registration" do
        reg = "REG_#{SecureRandom.hex(4)}"
        create_student(registration: reg)
        get students_path, params: { q: reg }
        expect(response).to be_successful
        expect(response.body).to include(reg)
      end

      it "paginates results (page param accepted)" do
        get students_path, params: { q: "a", page: 1 }
        expect(response).to be_successful
      end
    end

    describe "GET /students/new" do
      it "returns 200" do
        get new_student_path
        expect(response).to be_successful
      end

      it "pre-fills cpf when identifier is a valid CPF" do
        cpf = CPF.generate(stripped: true)
        get new_student_path, params: { identifier: cpf }
        expect(response).to be_successful
        expect(response.body).to include(cpf.gsub(/\D/, ""))
      end

      it "pre-fills registration when identifier is not a CPF" do
        get new_student_path, params: { identifier: "MAT12345" }
        expect(response).to be_successful
        expect(response.body).to include("MAT12345")
      end
    end

    describe "POST /students (create)" do
      context "with valid params" do
        it "creates the student and redirects to students_path" do
          expect {
            post students_path, params: { student: valid_student_params }
          }.to change(Student, :count).by(1)
          expect(response).to redirect_to(students_path)
        end

        it "sends welcome email when student has email" do
          post students_path, params: { student: valid_student_params(email: "novo@example.com") }
          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries.last.to).to eq(["novo@example.com"])
          expect(ActionMailer::Base.deliveries.last.subject).to include("Bem-vindo")
        end

        it "does not send email when student has no email" do
          post students_path, params: { student: valid_student_params(email: "") }
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      context "with invalid params" do
        it "renders :new with 422" do
          post students_path, params: { student: { name: "", cpf: "000" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /students/:id (show)" do
      it "returns 200" do
        student = create_student
        get student_path(student)
        expect(response).to be_successful
      end
    end

    describe "GET /students/:id/edit" do
      it "returns 200" do
        student = create_student
        get edit_student_path(student)
        expect(response).to be_successful
      end
    end

    describe "PATCH /students/:id (update)" do
      context "with valid params" do
        it "updates and redirects to student" do
          student = create_student
          patch student_path(student), params: { student: { name: "Novo Nome" } }
          expect(response).to redirect_to(student_path(student))
          expect(student.reload.name).to eq("Novo Nome")
        end
      end

      context "with invalid params (bad cpf)" do
        it "renders :edit with 422" do
          student = create_student
          patch student_path(student), params: { student: { cpf: "000" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "DELETE /students/:id (destroy)" do
      it "destroys the student and redirects to students_path" do
        student = create_student
        expect {
          delete student_path(student)
        }.to change(Student, :count).by(-1)
        expect(response).to redirect_to(students_path)
      end
    end

    describe "POST /students/:id/regenerate_qr" do
      let(:student) { create_student }

      it "responds with turbo_stream when Accept header is set" do
        post regenerate_qr_student_path(student),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to be_successful
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects to student on plain html request" do
        post regenerate_qr_student_path(student)
        expect(response).to redirect_to(student_path(student))
      end

      it "updates the qr_code_hash" do
        old_hash = student.qr_code_hash
        post regenerate_qr_student_path(student)
        expect(student.reload.qr_code_hash).not_to eq(old_hash)
      end

      it "sends qr_code_regenerated email when student has email" do
        post regenerate_qr_student_path(student)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.last.subject).to include("novo QR Code")
      end

      it "does not send email when student has no email" do
        student_no_email = create_student(email: "")
        post regenerate_qr_student_path(student_no_email)
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    describe "POST /students/:id/send_qr_email" do
      it "sends email and redirects with notice when student has email" do
        student = create_student(email: "aluno@example.com")
        post send_qr_email_student_path(student)
        expect(response).to redirect_to(student_path(student))
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.last.to).to eq(["aluno@example.com"])
      end

      it "redirects with alert and sends no email when student has no email" do
        student = create_student(email: "")
        post send_qr_email_student_path(student)
        expect(response).to redirect_to(student_path(student))
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root" do
      get students_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects show to root" do
      student = create_student
      get student_path(student)
      expect(response).to redirect_to(root_path)
    end

    it "redirects new to root" do
      get new_student_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects create to root" do
      post students_path, params: { student: valid_student_params }
      expect(response).to redirect_to(root_path)
    end

    it "redirects edit to root" do
      student = create_student
      get edit_student_path(student)
      expect(response).to redirect_to(root_path)
    end

    it "redirects update to root" do
      student = create_student
      patch student_path(student), params: { student: { name: "X" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects destroy to root" do
      student = create_student
      delete student_path(student)
      expect(response).to redirect_to(root_path)
    end

    it "redirects regenerate_qr to root" do
      student = create_student
      post regenerate_qr_student_path(student)
      expect(response).to redirect_to(root_path)
    end

    it "redirects send_qr_email to root" do
      student = create_student
      post send_qr_email_student_path(student)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "Student", "index")
      grant(plain_role, "Student", "show")
      grant(plain_role, "Student", "new")
      grant(plain_role, "Student", "edit")
      grant(plain_role, "Student", "destroy")
      grant(plain_role, "Student", "regenerate_qr")
      grant(plain_role, "Student", "send_qr_email")
    end

    it "can access index" do
      get students_path
      expect(response).to be_successful
    end

    it "can access show" do
      student = create_student
      get student_path(student)
      expect(response).to be_successful
    end

    it "can access new" do
      get new_student_path
      expect(response).to be_successful
    end

    it "can create a student" do
      expect {
        post students_path, params: { student: valid_student_params }
      }.to change(Student, :count).by(1)
      expect(response).to redirect_to(students_path)
    end

    it "can access edit" do
      student = create_student
      get edit_student_path(student)
      expect(response).to be_successful
    end

    it "can update a student" do
      student = create_student
      patch student_path(student), params: { student: { name: "Atualizado" } }
      expect(response).to redirect_to(student_path(student))
    end

    it "can destroy a student" do
      student = create_student
      expect {
        delete student_path(student)
      }.to change(Student, :count).by(-1)
      expect(response).to redirect_to(students_path)
    end

    it "can regenerate qr via html" do
      student = create_student
      post regenerate_qr_student_path(student)
      expect(response).to redirect_to(student_path(student))
    end

    it "can regenerate qr via turbo_stream" do
      student = create_student
      post regenerate_qr_student_path(student),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to be_successful
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "can send qr email" do
      student = create_student(email: "aluno@example.com")
      post send_qr_email_student_path(student)
      expect(response).to redirect_to(student_path(student))
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
