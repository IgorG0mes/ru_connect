require "rails_helper"

RSpec.describe Role, type: :model do
  def build_role(overrides = {})
    Role.new({ name: "role_#{SecureRandom.hex(4)}" }.merge(overrides))
  end

  describe "validations" do
    it "is valid with a name" do
      expect(build_role).to be_valid
    end

    it "is invalid without a name" do
      role = build_role(name: nil)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to be_present
    end

    it "is invalid with a duplicate name" do
      build_role(name: "duplicada").save!
      role = build_role(name: "duplicada")
      expect(role).not_to be_valid
      expect(role.errors[:name]).to be_present
    end
  end

  describe "associations" do
    it "destroys dependent permissions when destroyed" do
      role = build_role
      role.save!
      role.permissions.create!(resource: "Student", action: "index")

      expect { role.destroy }.to change(Permission, :count).by(-1)
    end
  end
end
