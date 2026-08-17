class AddStatusAndBalanceToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :status, :integer, default: 0, null: false
    add_column :students, :balance, :decimal, precision: 10, scale: 2, default: "0.0", null: false
  end
end
