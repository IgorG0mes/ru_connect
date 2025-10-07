class CreateDailyMenus < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_menus do |t|
      t.references :meal, null: false, foreign_key: true
      t.date :date
      t.string :main_dish
      t.string :side_dish
      t.string :salad
      t.string :dessert

      t.timestamps
    end
  end
end
