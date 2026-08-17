require "rails_helper"

RSpec.describe User, type: :model do
  let(:role) { Role.create!(name: "role_#{SecureRandom.hex(4)}") }

  def build_user(overrides = {})
    User.new({
      username: "user_#{SecureRandom.hex(4)}",
      email:    "user_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role:     role
    }.merge(overrides))
  end

  describe "validations" do
    it "is valid with username, email, password and role" do
      expect(build_user).to be_valid
    end

    it "is invalid without a username" do
      user = build_user(username: nil)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "is invalid with a duplicate username" do
      build_user(username: "repetido").save!
      user = build_user(username: "repetido")
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "is invalid without an email (devise validatable)" do
      user = build_user(email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "is invalid without a password (devise validatable)" do
      user = build_user(password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end

  describe "associations" do
    it "is invalid without a role" do
      user = build_user(role: nil)
      expect(user).not_to be_valid
      expect(user.errors[:role]).to be_present
    end
  end
end
