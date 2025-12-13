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

ActiveRecord::Schema[8.0].define(version: 2025_11_17_161314) do
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

  create_table "ipo_stocks", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "investment_amount", precision: 15, scale: 2, null: false
    t.decimal "maximum_buy_amount", precision: 10, scale: 2
    t.decimal "sell_profit_percentage", precision: 5, scale: 2, null: false
    t.decimal "first_buy_percentage", precision: 5, scale: 2, null: false
    t.decimal "buy_dip_percentage", precision: 5, scale: 2, null: false
    t.decimal "reinvestment_percentage", precision: 5, scale: 2
    t.decimal "total_amount", precision: 15, scale: 2
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_bought_amount_for_stock", precision: 15, scale: 2
  end

  create_table "ipo_stocks_stocks", id: false, force: :cascade do |t|
    t.bigint "ipo_stock_id", null: false
    t.bigint "stock_id", null: false
    t.index ["ipo_stock_id", "stock_id"], name: "index_ipo_stocks_stocks_on_ipo_stock_id_and_stock_id", unique: true
    t.index ["stock_id", "ipo_stock_id"], name: "index_ipo_stocks_stocks_on_stock_id_and_ipo_stock_id"
  end

  create_table "multi_stocks", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "investment_amount", precision: 15, scale: 2, null: false
    t.decimal "maximum_buy_amount", precision: 10, scale: 2
    t.decimal "sell_profit_percentage", precision: 5, scale: 2, null: false
    t.decimal "buy_dip_percentage", precision: 5, scale: 2, null: false
    t.decimal "reinvestment_percentage", precision: 5, scale: 2
    t.decimal "total_amount", precision: 15, scale: 2
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "multi_stocks_stocks", id: false, force: :cascade do |t|
    t.bigint "multi_stock_id", null: false
    t.bigint "stock_id", null: false
    t.index ["multi_stock_id", "stock_id"], name: "index_multi_stocks_stocks_on_multi_stock_id_and_stock_id", unique: true
    t.index ["stock_id", "multi_stock_id"], name: "index_multi_stocks_stocks_on_stock_id_and_multi_stock_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "task", null: false
    t.text "schedule", null: false
    t.datetime "run_at", null: false
    t.integer "priority", default: 0
    t.jsonb "arguments", default: {}
    t.string "queue_name"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["run_at"], name: "index_solid_queue_recurring_tasks_on_run_at"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.bigint "backtest_id"
    t.integer "kind", default: 0, null: false
    t.date "date", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "quantity", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "open", default: true
    t.bigint "multi_stock_id"
    t.bigint "stock_id"
    t.decimal "total_amount", precision: 15, scale: 2
    t.bigint "ipo_stock_id"
    t.decimal "stock_amount", precision: 15, scale: 2
    t.index ["backtest_id"], name: "index_transactions_on_backtest_id"
    t.index ["ipo_stock_id"], name: "index_transactions_on_ipo_stock_id"
    t.index ["multi_stock_id"], name: "index_transactions_on_multi_stock_id"
    t.index ["stock_id"], name: "index_transactions_on_stock_id"
  end

  add_foreign_key "backtests", "stocks"
  add_foreign_key "stock_prices", "stocks"
  add_foreign_key "transactions", "backtests"
  add_foreign_key "transactions", "ipo_stocks"
  add_foreign_key "transactions", "multi_stocks"
  add_foreign_key "transactions", "stocks"
end
