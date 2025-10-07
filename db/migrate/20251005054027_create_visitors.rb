class CreateVisitors < ActiveRecord::Migration[8.0]
  def change
    create_table :visitors do |t|
      t.string :name
      t.string :cpf
      t.string :email
      t.string :qr_code_hash

      t.timestamps
    end
  end
end
