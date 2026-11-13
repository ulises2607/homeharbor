class CreateReservationNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :reservation_notifications do |t|
      t.references :reservation, null: false, foreign_key: true
      t.string :event, null: false
      t.string :audience, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :available_at, null: false
      t.datetime :delivered_at
      t.datetime :failed_at
      t.string :last_error
      t.timestamps
    end
    add_index :reservation_notifications, [:reservation_id, :event, :audience], unique: true, name: "index_reservation_notifications_on_event_recipient"
    add_index :reservation_notifications, :available_at, where: "delivered_at IS NULL AND failed_at IS NULL", name: "index_reservation_notifications_pending"
    add_check_constraint :reservation_notifications, "event IN ('confirmed', 'cancelled') AND audience IN ('customer', 'owner')", name: "reservation_notifications_valid_event"
    add_check_constraint :reservation_notifications, "attempts >= 0", name: "reservation_notifications_valid_attempts"
  end
end
