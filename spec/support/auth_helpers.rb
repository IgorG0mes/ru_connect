RSpec.shared_context "with admin" do
  let(:admin_role) { Role.find_or_create_by!(name: "admin") }
  let(:admin) do
    User.create!(
      username: "admin_#{SecureRandom.hex(4)}",
      email:    "admin_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role:     admin_role
    )
  end

  before { sign_in admin }
end

RSpec.shared_context "with unauthorized user" do
  let(:plain_role) { Role.create!(name: "employee_#{SecureRandom.hex(4)}") }
  let(:plain_user) do
    User.create!(
      username: "user_#{SecureRandom.hex(4)}",
      email:    "user_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      role:     plain_role
    )
  end

  before { sign_in plain_user }
end

def grant(role, resource, action)
  Permission.find_or_create_by!(role: role, resource: resource, action: action)
  Rails.cache.clear
end
