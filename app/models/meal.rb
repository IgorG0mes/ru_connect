class Meal < ApplicationRecord
  validates :name, presence: true

  def self.find_current
    current_time = Time.zone.now.strftime("%H:%M:%S")

    meals = Meal.all.select do |meal|
      start_time = meal.start_at.strftime("%H:%M:%S")
      end_time   = meal.end_at.strftime("%H:%M:%S")

      if start_time <= end_time
        current_time.between?(start_time, end_time)
      else
        # Janela que cruza a meia-noite (ex.: jantar 22:00–01:00).
        current_time >= start_time || current_time <= end_time
      end
    end

    meals.first
  end
end
