require "rails_helper"

RSpec.describe DailyMenu, type: :model do
  let(:meal) { Meal.create!(name: "Almoço", start_at: "11:00", end_at: "14:00") }

  def build_daily_menu(overrides = {})
    DailyMenu.new({
      meal:           meal,
      date:           Date.new(2026, 6, 11),
      animal_protein: "Frango grelhado",
      vegan_protein:  "Grão de bico",
      side_dish_one:  "Arroz",
      salad_one:      "Alface",
      dessert_one:    "Gelatina"
    }.merge(overrides))
  end

  describe "validations" do
    it "is valid with all required attributes" do
      expect(build_daily_menu).to be_valid
    end

    %i[animal_protein vegan_protein side_dish_one salad_one dessert_one].each do |attribute|
      it "is invalid without #{attribute}" do
        menu = build_daily_menu(attribute => "")
        expect(menu).not_to be_valid
        expect(menu.errors[attribute]).to be_present
      end
    end

    it "is invalid without a date" do
      menu = build_daily_menu(date: nil)
      expect(menu).not_to be_valid
      expect(menu.errors[:date]).to be_present
    end

    it "is invalid with the same meal on the same date" do
      build_daily_menu.save!
      menu = build_daily_menu
      expect(menu).not_to be_valid
      expect(menu.errors[:meal_id]).to be_present
    end

    it "allows the same meal on a different date" do
      build_daily_menu.save!
      menu = build_daily_menu(date: Date.new(2026, 6, 12))
      expect(menu).to be_valid
    end
  end

  describe "associations" do
    it "is invalid without a meal" do
      menu = build_daily_menu(meal: nil)
      expect(menu).not_to be_valid
      expect(menu.errors[:meal]).to be_present
    end
  end
end
