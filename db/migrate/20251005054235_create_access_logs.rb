class CreateAccessLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :access_logs do |t|
      t.integer :status
      t.datetime :access_time
      t.string :denial_reason
      t.references :personable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
