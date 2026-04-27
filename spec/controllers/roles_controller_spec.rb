require "rails_helper"

RSpec.describe RolesController, type: :request do
  def create_role(name: "role_#{SecureRandom.hex(4)}")
    Role.create!(name: name)
  end

  describe "unauthenticated access" do
    it "redirects index to sign-in" do
      get roles_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /roles (index)" do
      it "returns 200" do
        get roles_path
        expect(response).to be_successful
      end

      it "lists all roles" do
        role = create_role
        get roles_path
        expect(response.body).to include(role.name)
      end
    end

    describe "GET /roles/new" do
      it "returns 200" do
        get new_role_path
        expect(response).to be_successful
      end
    end

    describe "POST /roles (create)" do
      context "with valid params" do
        it "creates role and redirects to roles_path" do
          expect {
            post roles_path, params: { role: { name: "coordenador_#{SecureRandom.hex(3)}" } }
          }.to change(Role, :count).by(1)
          expect(response).to redirect_to(roles_path)
        end
      end

      context "with invalid params" do
        it "renders :new with 422" do
          post roles_path, params: { role: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /roles/:id/edit" do
      it "returns 200" do
        role = create_role
        get edit_role_path(role)
        expect(response).to be_successful
      end
    end

    describe "PATCH /roles/:id (update)" do
      context "with valid params" do
        it "updates and redirects to roles_path" do
          role     = create_role
          new_name = "updated_#{SecureRandom.hex(3)}"
          patch role_path(role), params: { role: { name: new_name } }
          expect(response).to redirect_to(roles_path)
          expect(role.reload.name).to eq(new_name)
        end
      end

      context "with invalid params" do
        it "renders :edit with 422" do
          role = create_role
          patch role_path(role), params: { role: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "DELETE /roles/:id (destroy)" do
      context "html request" do
        it "destroys role and redirects to roles_path" do
          role = create_role
          expect {
            delete role_path(role)
          }.to change(Role, :count).by(-1)
          expect(response).to redirect_to(roles_path)
        end
      end

      context "turbo_stream request" do
        it "destroys role and responds with turbo_stream" do
          role = create_role
          expect {
            delete role_path(role), headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change(Role, :count).by(-1)
          expect(response).to be_successful
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root"  do
      get roles_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects new to root" do
      get new_role_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects create to root" do
      post roles_path, params: { role: { name: "test" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects edit to root" do
      role = create_role
      get edit_role_path(role)
      expect(response).to redirect_to(root_path)
    end

    it "redirects update to root" do
      role = create_role
      patch role_path(role), params: { role: { name: "x" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects destroy to root" do
      role = create_role
      delete role_path(role)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "Role", "index")
      grant(plain_role, "Role", "new")
      grant(plain_role, "Role", "edit")
      grant(plain_role, "Role", "destroy")
    end

    it "can access index" do
      get roles_path
      expect(response).to be_successful
    end

    it "can access new" do
      get new_role_path
      expect(response).to be_successful
    end

    it "can create role" do
      expect {
        post roles_path, params: { role: { name: "novorole_#{SecureRandom.hex(3)}" } }
      }.to change(Role, :count).by(1)
      expect(response).to redirect_to(roles_path)
    end

    it "can access edit" do
      role = create_role
      get edit_role_path(role)
      expect(response).to be_successful
    end

    it "can update role" do
      role = create_role
      patch role_path(role), params: { role: { name: "atualizado_#{SecureRandom.hex(3)}" } }
      expect(response).to redirect_to(roles_path)
    end

    it "can destroy role via html" do
      role = create_role
      expect {
        delete role_path(role)
      }.to change(Role, :count).by(-1)
      expect(response).to redirect_to(roles_path)
    end

    it "can destroy role via turbo_stream" do
      role = create_role
      delete role_path(role), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to be_successful
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
