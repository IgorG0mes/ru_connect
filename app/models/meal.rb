class Meal < ApplicationRecord
  def self.find_current
    current_time = Time.zone.now.strftime("%H:%M:%S")

    meals = Meal.all.select do |meal|
      start_time = meal.start_at.strftime("%H:%M:%S")
      end_time   = meal.end_at.strftime("%H:%M:%S")

      current_time.between?(start_time, end_time)
    end

    meals.first
  end
end
