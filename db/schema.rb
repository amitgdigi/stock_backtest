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

ActiveRecord::Schema[8.0].define(version: 2025_08_05_082534) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "backtests", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "investment_amount", precision: 15, scale: 2, null: false
    t.decimal "sell_profit_percentage", precision: 5, scale: 2, null: false
    t.decimal "buy_dip_percentage", precision: 5, scale: 2, null: false
    t.decimal "reinvestment_percentage", precision: 5, scale: 2
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "maximum_buy_amount", precision: 10, scale: 2
    t.index ["stock_id"], name: "index_backtests_on_stock_id"
  end

  create_table "stock_prices", force: :cascade do |t|
    t.bigint "stock_id", null: false
    t.date "date", null: false
    t.decimal "open_price", precision: 10, scale: 2
    t.decimal "close_price", precision: 10, scale: 2, null: false
    t.decimal "high_price", precision: 10, scale: 2
    t.decimal "low_price", precision: 10, scale: 2
    t.integer "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id", "date"], name: "index_stock_prices_on_stock_id_and_date", unique: true
    t.index ["stock_id"], name: "index_stock_prices_on_stock_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "name"
    t.string "ticker"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "listing_date"
    t.index ["ticker"], name: "index_stocks_on_ticker", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "backtest_id", null: false
    t.string "transaction_type", null: false
    t.date "date", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "quantity", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "open", default: true
    t.index ["backtest_id"], name: "index_transactions_on_backtest_id"
  end

  add_foreign_key "backtests", "stocks"
  add_foreign_key "stock_prices", "stocks"
  add_foreign_key "transactions", "backtests"
end
