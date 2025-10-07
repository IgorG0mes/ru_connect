class AddUniqueIndexToStudentIdentifiers < ActiveRecord::Migration[8.0]
  def change
    add_index :students, :registration, unique: true
    add_index :students, :qr_code_hash, unique: true
  end
end
