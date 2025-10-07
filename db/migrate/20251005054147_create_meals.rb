class CreateMeals < ActiveRecord::Migration[8.0]
  def change
    create_table :meals do |t|
      t.string :name
      t.time :start_at
      t.time :end_at

      t.timestamps
    end
  end
end
