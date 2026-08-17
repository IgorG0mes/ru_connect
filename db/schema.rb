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

ActiveRecord::Schema[8.1].define(version: 2026_06_18_012708) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "access_logs", force: :cascade do |t|
    t.string "access_result"
    t.datetime "access_time"
    t.datetime "created_at", null: false
    t.bigint "personable_id", null: false
    t.string "personable_type", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["personable_type", "personable_id"], name: "index_access_logs_on_personable"
  end

  create_table "daily_menus", force: :cascade do |t|
    t.string "animal_protein", default: "", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.string "dessert_one", default: "", null: false
    t.string "dessert_two"
    t.bigint "meal_id", null: false
    t.string "salad_one", default: "", null: false
    t.string "salad_three"
    t.string "salad_two"
    t.string "side_dish_one", default: "", null: false
    t.string "side_dish_three"
    t.string "side_dish_two"
    t.datetime "updated_at", null: false
    t.string "vegan_protein", default: "", null: false
    t.index ["meal_id"], name: "index_daily_menus_on_meal_id"
  end

  create_table "meals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.time "end_at"
    t.string "name"
    t.time "start_at"
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "external_reference", null: false
    t.string "mp_payment_id"
    t.string "mp_preference_id"
    t.bigint "payable_id", null: false
    t.string "payable_type", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["external_reference"], name: "index_payments_on_external_reference", unique: true
    t.index ["mp_payment_id"], name: "index_payments_on_mp_payment_id"
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "resource", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id", "resource", "action"], name: "index_permissions_on_role_id_and_resource_and_action", unique: true
    t.index ["role_id"], name: "index_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "students", force: :cascade do |t|
    t.string "course"
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "qr_code_hash"
    t.string "registration"
    t.integer "status", default: 0, null: false
    t.integer "ticket_balance", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["qr_code_hash"], name: "index_students_on_qr_code_hash", unique: true
    t.index ["registration"], name: "index_students_on_registration", unique: true
  end

  create_table "ticket_prices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "payable_type", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["payable_type"], name: "index_ticket_prices_on_payable_type", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "role_id"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "visitors", force: :cascade do |t|
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "qr_code_hash"
    t.integer "ticket_balance", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "daily_menus", "meals"
  add_foreign_key "permissions", "roles"
end
