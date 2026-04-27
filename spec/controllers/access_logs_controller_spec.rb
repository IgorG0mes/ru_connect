require "rails_helper"

RSpec.describe AccessLogsController, type: :request do
  def create_student
    Student.create!(
      name:         "Estudante #{SecureRandom.hex(4)}",
      cpf:          CPF.generate(stripped: true),
      registration: "REG_#{SecureRandom.hex(4)}",
      email:        "stu_#{SecureRandom.hex(4)}@example.com",
      course:       "Ciencia",
      status:       :active
    )
  end

  def create_access_log(overrides = {})
    student = overrides.delete(:personable) || create_student
    AccessLog.create!({ personable: student, status: :allowed, access_result: "Aprovado" }.merge(overrides))
  end

  describe "unauthenticated access" do
    it "redirects index to sign-in" do
      get access_logs_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /access_logs (index)" do
      it "returns 200" do
        get access_logs_path
        expect(response).to be_successful
      end

      it "lists access logs" do
        create_access_log
        get access_logs_path
        expect(response).to be_successful
      end

      it "paginates (10 per page)" do
        get access_logs_path, params: { page: 1 }
        expect(response).to be_successful
      end
    end

    describe "DELETE /access_logs/:id (destroy)" do
      context "html request" do
        it "destroys log and redirects to access_logs_url" do
          log = create_access_log
          expect {
            delete access_log_path(log)
          }.to change(AccessLog, :count).by(-1)
          expect(response).to redirect_to(access_logs_url)
        end
      end

      context "turbo_stream request" do
        it "destroys log and responds with turbo_stream" do
          log = create_access_log
          expect {
            delete access_log_path(log), headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change(AccessLog, :count).by(-1)
          expect(response).to be_successful
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      it "handles not found gracefully" do
        delete access_log_path(id: 999_999)
        expect(response).to redirect_to(access_logs_url)
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root" do
      get access_logs_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects destroy to root" do
      log = create_access_log
      delete access_log_path(log)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "AccessLog", "index")
      grant(plain_role, "AccessLog", "destroy")
    end

    it "can access index" do
      get access_logs_path
      expect(response).to be_successful
    end

    it "can destroy log via html" do
      log = create_access_log
      expect {
        delete access_log_path(log)
      }.to change(AccessLog, :count).by(-1)
      expect(response).to redirect_to(access_logs_url)
    end

    it "can destroy log via turbo_stream" do
      log = create_access_log
      delete access_log_path(log), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to be_successful
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
