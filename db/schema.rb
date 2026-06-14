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

ActiveRecord::Schema[8.1].define(version: 2026_04_09_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_settings", force: :cascade do |t|
    t.time "closing_hours", default: "2000-01-01 22:00:00", null: false
    t.datetime "created_at", null: false
    t.string "dojo_warden_secret"
    t.integer "free_cancellation_hours", default: 4, null: false
    t.decimal "max_play_discount", precision: 5, scale: 2, default: "10.0", null: false
    t.integer "max_play_discount_hours_required", default: 100, null: false
    t.integer "min_hours_before_reservation", default: 2, null: false
    t.time "opening_hours", default: "2000-01-01 14:00:00", null: false
    t.integer "start_late_tolerance", default: 15, null: false
    t.datetime "updated_at", null: false
    t.string "working_days", default: ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"], null: false, array: true
  end

  create_table "friends", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "friend_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
  end

  create_table "game_plays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.bigint "machine_id"
    t.datetime "play_ended_at"
    t.datetime "play_started_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_game_plays_on_game_id"
    t.index ["machine_id"], name: "index_game_plays_on_machine_id"
    t.index ["user_id"], name: "index_game_plays_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.boolean "controller_support", default: false, null: false
    t.boolean "coop", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "game_identifier"
    t.string "genre", default: "FPS", null: false
    t.boolean "multiplayer", default: true, null: false
    t.string "name", null: false
    t.string "platform", default: "PC", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hour_transactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "hours_amount", null: false
    t.string "notice"
    t.bigint "receiver_id", null: false
    t.string "receiver_type", null: false
    t.bigint "sender_id", null: false
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_hour_transactions_on_receiver_id"
    t.index ["receiver_type", "receiver_id"], name: "index_hour_transactions_on_receiver_type_and_receiver_id"
    t.index ["sender_id"], name: "index_hour_transactions_on_sender_id"
  end

  create_table "machine_hours", force: :cascade do |t|
    t.boolean "convertible", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "expires", default: false, null: false
    t.datetime "expires_at"
    t.float "hours_amount", default: 1.0, null: false
    t.string "hours_status", default: "active", null: false
    t.string "hours_type", default: "playhours", null: false
    t.float "start_amount", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.float "used_hours", default: 0.0, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_machine_hours_on_user_id"
  end

  create_table "machines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.time "end_work_hours", default: "2000-01-01 22:00:00", null: false
    t.text "hardware_configuration"
    t.string "machine_type", null: false
    t.string "name", default: "", null: false
    t.integer "reservation_priority", default: 0, null: false
    t.time "start_work_hours", default: "2000-01-01 14:00:00", null: false
    t.string "status", default: "maintenance", null: false
    t.datetime "updated_at", null: false
    t.integer "warden_callback_port"
    t.string "warden_callback_secret"
    t.string "warden_global_ip"
    t.string "warden_local_ip"
    t.string "working_days", default: ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"], null: false, array: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon", default: "notifications"
    t.text "long_description"
    t.boolean "read", default: false, null: false
    t.string "short_description", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "prices", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.float "amount", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.text "description"
    t.string "hours_type", default: "playhours", null: false
    t.string "name", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "reservations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.datetime "end_time", null: false
    t.string "finish_job_id"
    t.string "late_cancellation_job_id"
    t.bigint "machine_id", null: false
    t.text "notes"
    t.datetime "start_time", null: false
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["machine_id"], name: "index_reservations_on_machine_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "discount_admin", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "discount_play", precision: 5, scale: 2, default: "0.0", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.string "name"
    t.float "played_hours", default: 0.0, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "game_plays", "games"
  add_foreign_key "game_plays", "machines"
  add_foreign_key "game_plays", "users"
  add_foreign_key "hour_transactions", "users", column: "sender_id"
  add_foreign_key "machine_hours", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "reservations", "machines"
  add_foreign_key "reservations", "users"
  add_foreign_key "reservations", "users", column: "creator_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
