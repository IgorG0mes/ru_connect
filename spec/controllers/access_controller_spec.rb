require "rails_helper"

RSpec.describe AccessController, type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def create_student(cpf: CPF.generate(stripped: true), registration: "REG_#{SecureRandom.hex(4)}", ticket_balance: 5)
    Student.create!(
      name:           "Estudante #{SecureRandom.hex(4)}",
      cpf:            cpf,
      registration:   registration,
      email:          "stu_#{SecureRandom.hex(4)}@example.com",
      course:         "Medicina",
      status:         :active,
      ticket_balance: ticket_balance
    )
  end

  def create_visitor(cpf: CPF.generate(stripped: true), ticket_balance: 5)
    Visitor.create!(
      name:           "Visitante #{SecureRandom.hex(4)}",
      cpf:            cpf,
      email:          "vis_#{SecureRandom.hex(4)}@example.com",
      ticket_balance: ticket_balance
    )
  end

  def create_current_meal
    Meal.create!(
      name:     "Refeicao_#{SecureRandom.hex(3)}",
      start_at: (Time.current - 1.hour).strftime("%H:%M"),
      end_at:   (Time.current + 1.hour).strftime("%H:%M")
    )
  end

  describe "unauthenticated access" do
    it "redirects GET /identify to sign-in" do
      get identify_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects POST /identify to sign-in" do
      post identify_path, params: { identifier: "test" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /identify (identification)" do
      it "returns 200" do
        get identify_path
        expect(response).to be_successful
      end
    end

    describe "POST /identify (process_identification)" do
      context "when identifier is blank" do
        it "renders identification page" do
          post identify_path, params: { identifier: "" }
          expect(response).to be_successful
        end

        it "responds with turbo_stream when Accept header is set" do
          post identify_path,
               params:  { identifier: "" },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "does not create an access_log" do
          expect {
            post identify_path, params: { identifier: "" }
          }.not_to change(AccessLog, :count)
        end
      end

      context "when identifier has 11 digits but is not a valid CPF" do
        it "renders identification without creating log" do
          expect {
            post identify_path, params: { identifier: "00000000000" }
          }.not_to change(AccessLog, :count)
          expect(response).to be_successful
        end

        it "responds with turbo_stream" do
          post identify_path,
               params:  { identifier: "00000000000" },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      context "when identifier is valid but no person exists" do
        it "does not create an access_log" do
          expect {
            post identify_path, params: { identifier: CPF.generate(stripped: true) }
          }.not_to change(AccessLog, :count)
          expect(response).to be_successful
        end
      end

      context "when student is found but no meal is active" do
        it "creates AccessLog with warning status" do
          student = create_student
          expect {
            post identify_path, params: { identifier: student.registration }
          }.to change(AccessLog, :count).by(1)
          expect(AccessLog.last.status).to eq("warning")
        end
      end

      context "when student is found, meal is active, and not yet consumed today" do
        it "creates AccessLog with allowed status" do
          student = create_student
          create_current_meal
          expect {
            post identify_path, params: { identifier: student.registration }
          }.to change(AccessLog, :count).by(1)
          log = AccessLog.last
          expect(log.personable).to eq(student)
          expect(log.status).to eq("allowed")
        end

        it "consumes one ticket on a granted access" do
          student = create_student(ticket_balance: 3)
          create_current_meal
          expect {
            post identify_path, params: { identifier: student.registration }
          }.to change { student.reload.ticket_balance }.by(-1)
        end
      end

      context "when student has no tickets" do
        it "denies access and does not consume" do
          student = create_student(ticket_balance: 0)
          create_current_meal
          expect {
            post identify_path, params: { identifier: student.registration }
          }.to change(AccessLog, :count).by(1)
          expect(AccessLog.last.status).to eq("denied")
          expect(student.reload.ticket_balance).to eq(0)
        end

        it "responds with turbo_stream" do
          student = create_student
          create_current_meal
          post identify_path,
               params:  { identifier: student.registration },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response).to be_successful
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      context "when student is found, meal is active, but already consumed for that meal today" do
        it "creates AccessLog with denied status" do
          student = create_student
          meal = create_current_meal
          AccessLog.create!(personable: student, meal: meal, status: :allowed, access_result: "Aprovado", access_time: Time.current)
          expect {
            post identify_path, params: { identifier: student.registration }
          }.to change(AccessLog, :count).by(1)
          expect(AccessLog.last.status).to eq("denied")
        end
      end

      context "lunch and dinner access on the same day" do
        let!(:lunch)  { Meal.create!(name: "Almoço", start_at: "11:00", end_at: "14:00") }
        let!(:dinner) { Meal.create!(name: "Jantar", start_at: "18:00", end_at: "21:00") }

        it "allows access at lunch time" do
          student = create_student
          travel_to Time.zone.now.change(hour: 12, min: 0) do
            post identify_path, params: { identifier: student.registration }
          end
          expect(AccessLog.last.status).to eq("allowed")
          expect(AccessLog.last.meal).to eq(lunch)
        end

        it "denies a second access attempt at lunch time" do
          student = create_student
          travel_to Time.zone.now.change(hour: 12, min: 0) do
            post identify_path, params: { identifier: student.registration }
            expect {
              post identify_path, params: { identifier: student.registration }
            }.to change(AccessLog, :count).by(1)
          end
          expect(AccessLog.last.status).to eq("denied")
        end

        it "allows access at dinner time even after lunch was already consumed" do
          student = create_student
          travel_to(Time.zone.now.change(hour: 12, min: 0)) { post identify_path, params: { identifier: student.registration } }
          travel_to Time.zone.now.change(hour: 19, min: 0) do
            post identify_path, params: { identifier: student.registration }
          end
          expect(AccessLog.last.status).to eq("allowed")
          expect(AccessLog.last.meal).to eq(dinner)
        end

        it "denies a second access attempt at dinner time" do
          student = create_student
          travel_to(Time.zone.now.change(hour: 12, min: 0)) { post identify_path, params: { identifier: student.registration } }
          travel_to Time.zone.now.change(hour: 19, min: 0) do
            post identify_path, params: { identifier: student.registration }
            expect {
              post identify_path, params: { identifier: student.registration }
            }.to change(AccessLog, :count).by(1)
          end
          expect(AccessLog.last.status).to eq("denied")
        end
      end

      context "when identifier is a valid CPF matching a student" do
        it "finds the student and creates a log" do
          cpf     = CPF.generate(stripped: true)
          student = create_student(cpf: cpf)
          create_current_meal
          expect {
            post identify_path, params: { identifier: cpf }
          }.to change(AccessLog, :count).by(1)
          expect(AccessLog.last.personable).to eq(student)
        end
      end

      context "when identifier is the student qr_code_hash" do
        it "finds the student and creates a log" do
          student = create_student
          create_current_meal
          expect {
            post identify_path, params: { identifier: student.qr_code_hash }
          }.to change(AccessLog, :count).by(1)
          expect(AccessLog.last.personable).to eq(student)
        end
      end

      context "when visitor is found and meal is active" do
        it "creates allowed AccessLog for visitor" do
          cpf     = CPF.generate(stripped: true)
          visitor = create_visitor(cpf: cpf)
          create_current_meal
          expect {
            post identify_path, params: { identifier: cpf }
          }.to change(AccessLog, :count).by(1)
          log = AccessLog.last
          expect(log.personable).to eq(visitor)
          expect(log.status).to eq("allowed")
        end
      end

      context "when identifier is visitor qr_code_hash" do
        it "finds the visitor and creates a log" do
          visitor = create_visitor
          create_current_meal
          expect {
            post identify_path, params: { identifier: visitor.qr_code_hash }
          }.to change(AccessLog, :count).by(1)
          expect(AccessLog.last.personable).to eq(visitor)
        end
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects GET /identify to root" do
      get identify_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects POST /identify to root" do
      post identify_path, params: { identifier: "test" }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted access permission" do
    include_context "with unauthorized user"

    before { grant(plain_role, "Access", "index") }

    it "can access GET /identify" do
      get identify_path
      expect(response).to be_successful
    end

    it "can POST /identify with a student identifier" do
      student = create_student
      create_current_meal
      expect {
        post identify_path, params: { identifier: student.registration }
      }.to change(AccessLog, :count).by(1)
    end
  end
end
