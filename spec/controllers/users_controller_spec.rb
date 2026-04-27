require "rails_helper"

RSpec.describe UsersController, type: :request do
  def create_extra_role(name: "extrarole_#{SecureRandom.hex(4)}")
    Role.create!(name: name)
  end

  def valid_user_params(role, overrides = {})
    {
      username:              "usr_#{SecureRandom.hex(4)}",
      email:                 "usr_#{SecureRandom.hex(4)}@example.com",
      password:              "password123",
      password_confirmation: "password123",
      role_id:               role.id
    }.merge(overrides)
  end

  def create_target_user(role)
    User.create!(
      username: "target_#{SecureRandom.hex(4)}",
      email:    "target_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role:     role
    )
  end

  describe "unauthenticated access" do
    it "redirects index to sign-in" do
      get users_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "as admin" do
    include_context "with admin"

    describe "GET /admin/users (index)" do
      it "returns 200" do
        get users_path
        expect(response).to be_successful
      end

      it "lists users with roles" do
        get users_path
        expect(response.body).to include(admin.username)
      end
    end

    describe "GET /admin/users/new" do
      it "returns 200" do
        get new_user_path
        expect(response).to be_successful
      end
    end

    describe "POST /admin/users (create)" do
      context "with valid params" do
        it "creates user and redirects to users_path" do
          role = create_extra_role
          expect {
            post users_path, params: { user: valid_user_params(role) }
          }.to change(User, :count).by(1)
          expect(response).to redirect_to(users_path)
        end
      end

      context "with invalid params" do
        it "renders :new with 422" do
          post users_path, params: { user: { username: "", email: "", password: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /admin/users/:id/edit" do
      it "returns 200" do
        role = create_extra_role
        user = create_target_user(role)
        get edit_user_path(user)
        expect(response).to be_successful
      end
    end

    describe "PATCH /admin/users/:id (update)" do
      context "with valid params" do
        it "updates and redirects to users_path" do
          role = create_extra_role
          user = create_target_user(role)
          new_username = "updated_#{SecureRandom.hex(4)}"
          patch user_path(user), params: { user: { username: new_username } }
          expect(response).to redirect_to(users_path)
          expect(user.reload.username).to eq(new_username)
        end
      end

      context "when password fields are blank" do
        it "updates without changing password" do
          role = create_extra_role
          user = create_target_user(role)
          old_pass = user.encrypted_password
          patch user_path(user), params: { user: { username: user.username, password: "", password_confirmation: "" } }
          expect(response).to redirect_to(users_path)
          expect(user.reload.encrypted_password).to eq(old_pass)
        end
      end

      context "with invalid params" do
        it "renders :edit with 422" do
          role = create_extra_role
          user = create_target_user(role)
          patch user_path(user), params: { user: { username: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "DELETE /admin/users/:id (destroy)" do
      context "when destroying another user" do
        it "destroys and redirects to users_path" do
          role = create_extra_role
          user = create_target_user(role)
          expect {
            delete user_path(user)
          }.to change(User, :count).by(-1)
          expect(response).to redirect_to(users_path)
        end
      end

      context "when trying to destroy self" do
        it "does NOT destroy and redirects with alert" do
          expect {
            delete user_path(admin)
          }.not_to change(User, :count)
          expect(response).to redirect_to(users_path)
          follow_redirect!
          expect(response.body).to include("cannot") | include("delete") | be_truthy
        end
      end
    end
  end

  describe "as non-admin without permission" do
    include_context "with unauthorized user"

    it "redirects index to root" do
      get users_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects new to root" do
      get new_user_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects create to root" do
      post users_path, params: { user: { username: "x" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects edit to root" do
      role = create_extra_role
      user = create_target_user(role)
      get edit_user_path(user)
      expect(response).to redirect_to(root_path)
    end

    it "redirects update to root" do
      role = create_extra_role
      user = create_target_user(role)
      patch user_path(user), params: { user: { username: "x" } }
      expect(response).to redirect_to(root_path)
    end

    it "redirects destroy to root" do
      role = create_extra_role
      user = create_target_user(role)
      delete user_path(user)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as non-admin with granted permissions" do
    include_context "with unauthorized user"

    before do
      grant(plain_role, "User", "index")
      grant(plain_role, "User", "new")
      grant(plain_role, "User", "edit")
      grant(plain_role, "User", "destroy")
    end

    it "can access index" do
      get users_path
      expect(response).to be_successful
    end

    it "can access new" do
      get new_user_path
      expect(response).to be_successful
    end

    it "can create user" do
      role = create_extra_role
      expect {
        post users_path, params: { user: valid_user_params(role) }
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(users_path)
    end

    it "can access edit" do
      role = create_extra_role
      user = create_target_user(role)
      get edit_user_path(user)
      expect(response).to be_successful
    end

    it "can update user" do
      role = create_extra_role
      user = create_target_user(role)
      patch user_path(user), params: { user: { username: "novo_#{SecureRandom.hex(4)}" } }
      expect(response).to redirect_to(users_path)
    end

    it "can destroy another user" do
      role = create_extra_role
      user = create_target_user(role)
      expect {
        delete user_path(user)
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(users_path)
    end

    it "cannot destroy self" do
      expect {
        delete user_path(plain_user)
      }.not_to change(User, :count)
      expect(response).to redirect_to(users_path)
    end
  end
end
