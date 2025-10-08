class DailyMenu < ApplicationRecord
  belongs_to :meal

  validates :meal_id, uniqueness: { scope: :date, message: "Já existe um cardápio para esta refeição nesta data." }
  validates :date, :main_dish, :side_dish, presence: true
end
