class AddQuantityToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :quantity, :integer, default: 1, null: false
  end
end
