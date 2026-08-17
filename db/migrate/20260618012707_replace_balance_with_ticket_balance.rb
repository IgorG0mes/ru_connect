class ReplaceBalanceWithTicketBalance < ActiveRecord::Migration[8.1]
  def change
    remove_column :students, :balance, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    remove_column :visitors, :balance, :decimal, precision: 10, scale: 2, default: "0.0", null: false

    add_column :students, :ticket_balance, :integer, default: 0, null: false
    add_column :visitors, :ticket_balance, :integer, default: 0, null: false
  end
end
