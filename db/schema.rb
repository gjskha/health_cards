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

ActiveRecord::Schema.define(version: 2021_06_22_174803) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "immunizations", force: :cascade do |t|
    t.bigint "patient_id"
    t.bigint "vaccine_id"
    t.string "json"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_immunizations_on_patient_id"
    t.index ["vaccine_id"], name: "index_immunizations_on_vaccine_id"
  end

  create_table "lab_results", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "json"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["patient_id"], name: "index_lab_results_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.string "json"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "vaccines", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.integer "doses_required"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
