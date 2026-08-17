class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :payable, polymorphic: true, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false
      t.string :mp_preference_id
      t.string :mp_payment_id
      t.string :external_reference, null: false

      t.timestamps
    end

    add_index :payments, :external_reference, unique: true
    add_index :payments, :mp_payment_id
  end
end
