class PrepareAccountsAndBoats < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :failed_attempts, from: nil, to: 0
    change_column_null :users, :failed_attempts, false, 0

    create_table :boats do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description, null: false
      t.string :port, null: false
      t.string :time_zone, null: false, default: "America/Argentina/Buenos_Aires"
      t.integer :capacity, null: false
      t.integer :daily_rate_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_check_constraint :boats, "capacity > 0", name: "boats_positive_capacity"
    add_check_constraint :boats, "daily_rate_cents > 0", name: "boats_positive_rate"
    add_index :boats, [:active, :id]
  end
end
