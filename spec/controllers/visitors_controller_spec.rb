require "rails_helper"

RSpec.describe VisitorsController, type: :request do
  def valid_visitor_params(overrides = {})
    {
      name:  "Ana Visitante",
      cpf:   CPF.generate(stripped: true),
      email: "ana_#{SecureRandom.hex(4)}@example.com"
    }.merge(overrides)
  end

  def create_visitor(overrides = {})
    Visitor.create!(valid_visitor_params(overrides))
  end

  before { ActionMailer::Base.deliveries.clear }

  describe "unauthenticated access" do
    it "redirects to sign-in for index" do
      get visitors_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign-in for show" do
      visitor = create_visitor
      get visitor_path(visitor)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /visitors (index)" do
      it "returns 200 without query" do
        get visitors_path
        expect(response).to be_successful
      end

      it "returns results when searching by name" do
        create_visitor(name: "Carlos Buscavel")
        get visitors_path, params: { q: "Buscavel" }
        expect(response).to be_successful
        expect(response.body).to include("Buscavel")
      end

      it "returns results when searching by cpf" do
        cpf = CPF.generate(stripped: true)
        create_visitor(cpf: cpf)
        get visitors_path, params: { q: cpf }
        expect(response).to be_successful
      end

      it "accepts page param" do
        get visitors_path, params: { q: "a", page: 1 }
        expect(response).to be_successful
      end
    end

    describe "GET /visitors/new" do
      it "returns 200" do
        get new_visitor_path
        expect(response).to be_successful
      end

      it "pre-fills cpf when identifier param is present" do
        cpf = CPF.generate(stripped: true)
        get new_visitor_path, params: { identifier: cpf }
        expect(response).to be_successful
        expect(response.body).to include(cpf.gsub(/\D/, ""))
      end
    end

    describe "POST /visitors (create)" do
      context "with valid params" do
        it "creates visitor and redirects to visitors_path" do
          expect {
            post visitors_path, params: { visitor: valid_visitor_params }
          }.to change(Visitor, :count).by(1)
          expect(response).to redirect_to(visitors_path)
        end

        it "sends welcome email when visitor has email" do
          post visitors_path, params: { visitor: valid_visitor_params(email: "novo@example.com") }
          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries.last.to).to eq(["novo@example.com"])
          expect(ActionMailer::Base.deliveries.last.subject).to include("Bem-vindo")
        end

        it "does not send email when visitor has no email" do
          post visitors_path, params: { visitor: valid_visitor_params(email: "") }
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      context "with invalid params" do
        it "renders :new with 422" do
          post visitors_path, params: { visitor: { name: "", cpf: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /visitors/:id (show)" do
      it "returns 200" do
        visitor = create_visitor
        get visitor_path(visitor)
        expect(response).to be_successful
      end
    end

    describe "GET /visitors/:id/edit" do
      it "returns 200" do
        visitor = create_visitor
        get edit_visitor_path(visitor)
        expect(response).to be_successful
      end
    end

    describe "PATCH /visitors/:id (update)" do
      context "with valid params" do
        it "updates and redirects to visitor" do
          visitor = create_visitor
          patch visitor_path(visitor), params: { visitor: { name: "Novo Nome" } }
          expect(response).to redirect_to(visitor_path(visitor))
          expect(visitor.reload.name).to eq("Novo Nome")
        end
      end

      context "with invalid params" do
        it "renders :edit with 422" do
          visitor = create_visitor
          patch visitor_path(visitor), params: { visitor: { cpf: "000" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "DELETE /visitors/:id (destroy)" do
      it "destroys visitor and redirects to visitors_path" do
        visitor = create_visitor
        expect {
          delete visitor_path(visitor)
        }.to change(Visitor, :count).by(-1)
        expect(response).to redirect_to(visitors_path)
      end
    end

    describe "POST /visitors/:id/regenerate_qr" do
      let(:visitor) { create_visitor }

      it "responds with turbo_stream when Accept header is set" do
        post regenerate_qr_visitor_path(visitor),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to be_successful
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "redirects to visitor on plain html request" do
        post regenerate_qr_visitor_path(visitor)
        expect(response).to redirect_to(visitor_path(visitor))
      end

      it "updates the qr_code_hash" do
        old_hash = visitor.qr_code_hash
        post regenerate_qr_visitor_path(visitor)
        expect(visitor.reload.qr_code_hash).not_to eq(old_hash)
      end

      it "sends qr_code_regenerated email when visitor has email" do
        post regenerate_qr_visitor_path(visitor)
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.last.subject).to include("novo QR Code")
      end

      it "does not send email when visitor has no email" do
        visitor_no_email = create_visitor(email: "")
        post regenerate_qr_visitor_path(visitor_no_email)
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    describe "POST /visitors/:id/send_qr_email" do
      it "sends email and redirects with notice when visitor has email" do
        visitor = create_visitor(email: "visitante@example.com")
        post send_qr_email_visitor_path(visitor)
        expect(response).to redirect_to(visitor_path(visitor))
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.last.to).to eq(["visitante@example.com"])
      end

      it "redirects with alert and sends no email when visitor has no email" do
        visitor = create_visitor(email: "")
        post send_qr_email_visitor_path(visitor)
        expect(response).to redirect_to(visitor_path(visitor))
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root" do
      get visitors_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects show to root" do
      visitor = create_visitor
      get visitor_path(visitor)
      expect(response).to redirect_to(root_path)
    end

    it "redirects new to root" do
      get new_visitor_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects create to root" do
      post visitors_path, params: { visitor: valid_visitor_params }
      expect(response).to redirect_to(root_path)
    end

    it "redirects edit to root" do
      visitor = create_visitor
      get edit_visitor_path(visitor)
      expect(response).to redirect_to(root_path)
    end

    it "redirects update to root" do
      visitor = create_visitor
      patch visitor_path(visitor), params: { visitor: { name: "X" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects destroy to root" do
      visitor = create_visitor
      delete visitor_path(visitor)
      expect(response).to redirect_to(root_path)
    end

    it "redirects regenerate_qr to root" do
      visitor = create_visitor
      post regenerate_qr_visitor_path(visitor)
      expect(response).to redirect_to(root_path)
    end

    it "redirects send_qr_email to root" do
      visitor = create_visitor
      post send_qr_email_visitor_path(visitor)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "Visitor", "index")
      grant(plain_role, "Visitor", "show")
      grant(plain_role, "Visitor", "new")
      grant(plain_role, "Visitor", "edit")
      grant(plain_role, "Visitor", "destroy")
      grant(plain_role, "Visitor", "regenerate_qr")
      grant(plain_role, "Visitor", "send_qr_email")
    end

    it "can access index" do
      get visitors_path
      expect(response).to be_successful
    end

    it "can access show" do
      visitor = create_visitor
      get visitor_path(visitor)
      expect(response).to be_successful
    end

    it "can access new" do
      get new_visitor_path
      expect(response).to be_successful
    end

    it "can create visitor" do
      expect {
        post visitors_path, params: { visitor: valid_visitor_params }
      }.to change(Visitor, :count).by(1)
      expect(response).to redirect_to(visitors_path)
    end

    it "can access edit" do
      visitor = create_visitor
      get edit_visitor_path(visitor)
      expect(response).to be_successful
    end

    it "can update visitor" do
      visitor = create_visitor
      patch visitor_path(visitor), params: { visitor: { name: "Atualizado" } }
      expect(response).to redirect_to(visitor_path(visitor))
    end

    it "can destroy visitor" do
      visitor = create_visitor
      expect {
        delete visitor_path(visitor)
      }.to change(Visitor, :count).by(-1)
      expect(response).to redirect_to(visitors_path)
    end

    it "can regenerate qr via html" do
      visitor = create_visitor
      post regenerate_qr_visitor_path(visitor)
      expect(response).to redirect_to(visitor_path(visitor))
    end

    it "can regenerate qr via turbo_stream" do
      visitor = create_visitor
      post regenerate_qr_visitor_path(visitor),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to be_successful
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "can send qr email" do
      visitor = create_visitor(email: "visitante@example.com")
      post send_qr_email_visitor_path(visitor)
      expect(response).to redirect_to(visitor_path(visitor))
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
