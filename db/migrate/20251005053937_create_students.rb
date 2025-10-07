class CreateStudents < ActiveRecord::Migration[8.0]
  def change
    create_table :students do |t|
      t.string :name
      t.string :cpf
      t.string :registration
      t.string :email
      t.string :course
      t.string :qr_code_hash

      t.timestamps
    end
  end
end
