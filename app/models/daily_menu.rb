class DailyMenu < ApplicationRecord
  belongs_to :meal

  validates :meal_id, uniqueness: { scope: :date }
  validates :date, :main_dish, :side_dish, presence: true
end
