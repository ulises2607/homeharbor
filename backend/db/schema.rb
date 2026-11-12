# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_020000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "boats", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.text "description", null: false
    t.string "port", null: false
    t.string "time_zone", default: "Etc/GMT+3", null: false
    t.integer "capacity", null: false
    t.integer "daily_rate_cents", null: false
    t.string "currency", default: "USD", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "id"], name: "index_boats_on_active_and_id"
    t.index ["owner_id"], name: "index_boats_on_owner_id"
    t.check_constraint "capacity > 0", name: "boats_positive_capacity"
    t.check_constraint "currency::text = 'USD'::text", name: "boats_usd_currency"
    t.check_constraint "daily_rate_cents > 0", name: "boats_positive_rate"
    t.check_constraint "time_zone::text = 'Etc/GMT+3'::text", name: "boats_fixed_time_zone"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "boat_id", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "passengers", null: false
    t.string "status", default: "confirmed", null: false
    t.bigint "daily_rate_cents", null: false
    t.bigint "total_cents", null: false
    t.string "currency", null: false
    t.string "time_zone", null: false
    t.string "idempotency_key", limit: 36, null: false
    t.string "request_fingerprint", limit: 64, null: false
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["boat_id"], name: "index_reservations_on_boat_id"
    t.index ["user_id", "idempotency_key"], name: "index_reservations_on_user_and_key", unique: true
    t.index ["user_id"], name: "index_reservations_on_user_id"
    t.check_constraint "currency::text = 'USD'::text AND time_zone::text = 'Etc/GMT+3'::text", name: "reservations_currency_and_zone"
    t.check_constraint "daily_rate_cents > 0 AND total_cents = ((ends_on - starts_on)::bigint * daily_rate_cents)", name: "reservations_valid_price"
    t.check_constraint "isfinite(starts_on) AND isfinite(ends_on) AND ends_on > starts_on", name: "reservations_valid_interval"
    t.check_constraint "passengers >= 1 AND passengers <= 500", name: "reservations_positive_passengers"
    t.check_constraint "status::text = 'confirmed'::text AND cancelled_at IS NULL OR status::text = 'cancelled'::text AND cancelled_at IS NOT NULL", name: "reservations_valid_status"
    t.exclusion_constraint "boat_id WITH =, daterange(starts_on, ends_on, '[)'::text) WITH &&", where: "(status)::text = 'confirmed'::text", using: :gist, name: "reservations_no_overlap"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "trackable"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "boats", "users", column: "owner_id"
  add_foreign_key "reservations", "boats"
  add_foreign_key "reservations", "users"
end
