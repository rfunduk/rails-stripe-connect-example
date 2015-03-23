# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150318194136) do

  create_table "users", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "email",                  limit: 255
    t.string   "password_digest",        limit: 255
    t.string   "publishable_key",        limit: 255
    t.string   "secret_key",             limit: 255
    t.string   "stripe_user_id",         limit: 255
    t.string   "currency",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stripe_account_type"
    t.text     "stripe_account_status",              default: "{}"
  end

end
