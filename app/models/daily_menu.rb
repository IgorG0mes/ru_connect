class DailyMenu < ApplicationRecord
  belongs_to :meal

  validates :meal_id, uniqueness: { scope: :date }
  validates :date, :animal_protein, :vegan_protein, :side_dish_one, :salad_one, :dessert_one, presence: true
end
