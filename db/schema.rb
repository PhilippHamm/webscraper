# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_08_06_201211) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "car_dealers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url_path"
  end

  create_table "cars", force: :cascade do |t|
    t.string "title"
    t.string "price"
    t.string "damage_condition"
    t.string "category"
    t.string "country_version"
    t.string "consumption"
    t.string "mileage"
    t.string "cubic_capacity"
    t.string "power"
    t.string "fuel"
    t.string "emission"
    t.string "num_seats"
    t.string "door_count"
    t.string "transmission"
    t.string "emission_class"
    t.string "emssion_sticker"
    t.string "first_registration"
    t.string "hu"
    t.string "climatisation"
    t.string "park_assist"
    t.string "airbag"
    t.string "manufacturer_color_name"
    t.string "color"
    t.string "interior"
    t.string "image_one"
    t.string "image_two"
    t.string "image_three"
    t.string "image_four"
    t.string "image_five"
    t.string "image_six"
    t.string "image_seven"
    t.string "image_eight"
    t.string "image_nine"
    t.string "image_ten"
    t.string "features"
    t.string "dealer_name"
    t.string "dealer_postal_code"
    t.string "dealer_city"
    t.string "dealer_address"
    t.string "dealer_phone"
    t.string "dealer_rating"
    t.string "publishing_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
