class AddBalanceToVisitors < ActiveRecord::Migration[8.1]
  def change
    add_column :visitors, :balance, :decimal, precision: 10, scale: 2, default: "0.0", null: false
  end
end
