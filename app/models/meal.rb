class Meal < ApplicationRecord
  def self.find_current
    current_time = Time.zone.now

    Meal.where("start_at <= ? AND end_at >= ?", current_time, current_time).first
  end
end
