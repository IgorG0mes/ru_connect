class RestructureDailyMenuFields < ActiveRecord::Migration[8.1]
  def change
    remove_column :daily_menus, :main_dish, :string
    remove_column :daily_menus, :side_dish, :string
    remove_column :daily_menus, :salad,     :string
    remove_column :daily_menus, :dessert,   :string

    add_column :daily_menus, :animal_protein,  :string, null: false, default: ""
    add_column :daily_menus, :vegan_protein,   :string, null: false, default: ""
    add_column :daily_menus, :side_dish_one,   :string, null: false, default: ""
    add_column :daily_menus, :side_dish_two,   :string
    add_column :daily_menus, :side_dish_three, :string
    add_column :daily_menus, :salad_one,       :string, null: false, default: ""
    add_column :daily_menus, :salad_two,       :string
    add_column :daily_menus, :salad_three,     :string
    add_column :daily_menus, :dessert_one,     :string, null: false, default: ""
    add_column :daily_menus, :dessert_two,     :string
  end
end
