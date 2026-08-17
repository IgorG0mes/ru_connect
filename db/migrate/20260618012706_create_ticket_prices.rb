class CreateTicketPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_prices do |t|
      t.string :payable_type, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :ticket_prices, :payable_type, unique: true
  end
end
