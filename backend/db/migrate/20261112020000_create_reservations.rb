class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    enable_extension "btree_gist" unless extension_enabled?("btree_gist")
    create_table :reservations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :boat, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :passengers, null: false
      t.string :status, null: false, default: "confirmed"
      t.bigint :daily_rate_cents, null: false
      t.bigint :total_cents, null: false
      t.string :currency, null: false
      t.string :time_zone, null: false
      t.string :idempotency_key, null: false, limit: 36
      t.string :request_fingerprint, null: false, limit: 64
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :reservations, [:user_id, :idempotency_key], unique: true, name: "index_reservations_on_user_and_key"
    add_check_constraint :reservations, "isfinite(starts_on) AND isfinite(ends_on) AND ends_on > starts_on", name: "reservations_valid_interval"
    add_check_constraint :reservations, "passengers BETWEEN 1 AND 500", name: "reservations_positive_passengers"
    add_check_constraint :reservations, "daily_rate_cents > 0 AND total_cents = (ends_on - starts_on)::bigint * daily_rate_cents", name: "reservations_valid_price"
    add_check_constraint :reservations, "currency = 'USD' AND time_zone = 'Etc/GMT+3'", name: "reservations_currency_and_zone"
    add_check_constraint :reservations, "(status = 'confirmed' AND cancelled_at IS NULL) OR (status = 'cancelled' AND cancelled_at IS NOT NULL)", name: "reservations_valid_status"
    add_exclusion_constraint :reservations, "boat_id WITH =, daterange(starts_on, ends_on, '[)') WITH &&",
      using: :gist, where: "status = 'confirmed'", name: "reservations_no_overlap"
  end
end
