require "rails_helper"

RSpec.describe Meal, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(Meal.new(name: "Almoço")).to be_valid
    end

    it "is invalid without a name" do
      meal = Meal.new(name: nil)
      expect(meal).not_to be_valid
      expect(meal.errors[:name]).to be_present
    end
  end

  describe ".find_current" do
    let(:fixed_now) { Time.zone.parse("2026-06-11 12:00:00") }

    before { allow(Time.zone).to receive(:now).and_return(fixed_now) }

    it "returns the meal whose time window contains the current time" do
      lunch = Meal.create!(name: "Almoço", start_at: "11:00", end_at: "14:00")
      Meal.create!(name: "Café", start_at: "06:00", end_at: "09:00")

      expect(Meal.find_current).to eq(lunch)
    end

    it "returns nil when no meal window contains the current time" do
      Meal.create!(name: "Café", start_at: "06:00", end_at: "09:00")
      Meal.create!(name: "Jantar", start_at: "18:00", end_at: "21:00")

      expect(Meal.find_current).to be_nil
    end
  end
end
