require "rails_helper"

RSpec.describe PermissionsController, type: :request do
  def non_admin_role(name: "staff_#{SecureRandom.hex(4)}")
    Role.create!(name: name)
  end

  describe "unauthenticated access" do
    it "redirects index to sign-in" do
      get permissions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects toggle to sign-in" do
      post toggle_permissions_path, params: { role_id: 1, resource: "Student", permission_action: "index" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /permissions (index)" do
      it "returns 200" do
        get permissions_path
        expect(response).to be_successful
      end

      it "excludes admin role from @roles" do
        non_admin = non_admin_role
        get permissions_path
        expect(response.body).to include(non_admin.name.capitalize)
        expect(response.body).not_to match(/permissions\?role_id=#{admin_role.id}"[^0-9]/)
      end

      it "accepts role_id param to select role" do
        role = non_admin_role
        get permissions_path, params: { role_id: role.id }
        expect(response).to be_successful
      end
    end

    describe "POST /permissions/toggle" do
      let(:role) { non_admin_role }

      context "when permission does not exist (should create it)" do
        it "creates the permission and responds with turbo_stream" do
          expect {
            post toggle_permissions_path,
                 params:  { role_id: role.id, resource: "Student", permission_action: "index" },
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change(Permission, :count).by(1)
          expect(response).to be_successful
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      context "when permission already exists (should destroy it)" do
        it "destroys the permission and responds with turbo_stream" do
          Permission.create!(role: role, resource: "Student", action: "index")
          Rails.cache.clear

          expect {
            post toggle_permissions_path,
                 params:  { role_id: role.id, resource: "Student", permission_action: "index" },
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change(Permission, :count).by(-1)
          expect(response).to be_successful
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      it "toggles on different resources" do
        post toggle_permissions_path,
             params:  { role_id: role.id, resource: "Meal", permission_action: "new" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to be_successful
        expect(Permission.exists?(role: role, resource: "Meal", action: "new")).to be true
      end
    end
  end

  describe "as non-admin" do
    include_context "with unauthorized user"

    it "redirects index to root" do
      get permissions_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects toggle to root" do
      role = non_admin_role
      post toggle_permissions_path,
           params: { role_id: role.id, resource: "Student", permission_action: "index" }
      expect(response).to redirect_to(root_path)
    end
  end
end
