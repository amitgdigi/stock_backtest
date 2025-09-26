class CreateSolidTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_queue_blocked_executions, force: :cascade, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.string :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.index [:concurrency_key, :priority, :job_id], name: "index_solid_queue_blocked_executions_for_release", force: :cascade, if_not_exists: true
      t.index [:expires_at, :concurrency_key], name: "index_solid_queue_blocked_executions_for_maintenance", force: :cascade, if_not_exists: true
      t.index [:job_id], name: "index_solid_queue_blocked_executions_on_job_id", unique: true, force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_claimed_executions, force: :cascade, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.bigint :process_id
      t.datetime :created_at, null: false
      t.index [:job_id], name: "index_solid_queue_claimed_executions_on_job_id", unique: true, force: :cascade, if_not_exists: true
      t.index [:process_id, :job_id], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id", force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_failed_executions, force: :cascade, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.text :error
      t.datetime :created_at, null: false
      t.index [:job_id], name: "index_solid_queue_failed_executions_on_job_id", unique: true, force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_jobs, force: :cascade, if_not_exists: true do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.integer :priority, default: 0, null: false
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:active_job_id], name: "index_solid_queue_jobs_on_active_job_id", force: :cascade, if_not_exists: true
      t.index [:class_name], name: "index_solid_queue_jobs_on_class_name", force: :cascade, if_not_exists: true
      t.index [:finished_at], name: "index_solid_queue_jobs_on_finished_at", force: :cascade, if_not_exists: true
      t.index [:queue_name, :finished_at], name: "index_solid_queue_jobs_for_filtering", force: :cascade, if_not_exists: true
      t.index [:scheduled_at, :finished_at], name: "index_solid_queue_jobs_for_alerting", force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_pauses, force: :cascade, if_not_exists: true do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false
      t.index [:queue_name], name: "index_solid_queue_pauses_on_queue_name", unique: true, force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_processes, force: :cascade, if_not_exists: true do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint :supervisor_id
      t.integer :pid, null: false
      t.string :hostname
      t.text :metadata
      t.datetime :created_at, null: false
      t.string :name
      t.index [:last_heartbeat_at], name: "index_solid_queue_processes_on_last_heartbeat_at", force: :cascade, if_not_exists: true
      t.index [:supervisor_id], name: "index_solid_queue_processes_on_supervisor_id", force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_ready_executions, force: :cascade, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :created_at, null: false
      t.index [:job_id], name: "index_solid_queue_ready_executions_on_job_id", unique: true, force: :cascade, if_not_exists: true
      t.index [:priority, :job_id], name: "index_solid_queue_poll_all", force: :cascade, if_not_exists: true
      t.index [:queue_name, :priority, :job_id], name: "index_solid_queue_poll_by_queue", force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_recurring_executions, force: :cascade, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.string :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false
      t.index [:job_id], name: "index_solid_queue_recurring_executions_on_job_id", unique: true, force: :cascade, if_not_exists: true
      t.index [:task_key, :run_at], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true, force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_recurring_tasks, force: :cascade, if_not_exists: true do |t|
      t.string :key, null: false
      t.string :task, null: false
      t.text :schedule, null: false
      t.datetime :run_at, null: false
      t.integer :priority, default: 0
      t.jsonb :arguments, default: {}
      t.string :queue_name
      t.datetime :created_at, null: false
      t.index [:key], name: "index_solid_queue_recurring_tasks_on_key", unique: true, force: :cascade, if_not_exists: true
      t.index [:run_at], name: "index_solid_queue_recurring_tasks_on_run_at", force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_scheduled_executions, force: :cascade, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false
      t.index [:job_id], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true, force: :cascade, if_not_exists: true
      t.index [:scheduled_at, :priority, :job_id], name: "index_solid_queue_dispatch_all", force: :cascade, if_not_exists: true
    end

    create_table :solid_queue_semaphores, force: :cascade, if_not_exists: true do |t|
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:expires_at], name: "index_solid_queue_semaphores_on_expires_at", force: :cascade, if_not_exists: true
      t.index [:key, :value], name: "index_solid_queue_semaphores_on_key_and_value", force: :cascade, if_not_exists: true
      t.index [:key], name: "index_solid_queue_semaphores_on_key", unique: true, force: :cascade, if_not_exists: true
    end

    create_table :solid_cable_messages, force: :cascade, if_not_exists: true do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false
      t.index [:channel], name: "index_solid_cable_messages_on_channel", force: :cascade, if_not_exists: true
      t.index [:channel_hash], name: "index_solid_cable_messages_on_channel_hash", force: :cascade, if_not_exists: true
      t.index [:created_at], name: "index_solid_cable_messages_on_created_at", force: :cascade, if_not_exists: true
    end

    create_table :solid_cache_entries, force: :cascade, if_not_exists: true do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false
      t.index [:byte_size], name: "index_solid_cache_entries_on_byte_size", force: :cascade, if_not_exists: true
      t.index [:key_hash, :byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size", force: :cascade, if_not_exists: true
      t.index [:key_hash], name: "index_solid_cache_entries_on_key_hash", unique: true, force: :cascade, if_not_exists: true
    end
  end
end
