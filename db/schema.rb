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

ActiveRecord::Schema[8.1].define(version: 2026_07_14_094433) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "course_domains", force: :cascade do |t|
    t.boolean "ask_location", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "enrollment_open", default: true, null: false
    t.boolean "link_mode", default: false, null: false
    t.string "link_secret", null: false
    t.string "locale", default: "en", null: false
    t.boolean "location_bumper", default: false, null: false
    t.string "location_type", default: "table", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_course_domains_on_slug", unique: true
  end

  create_table "hands", force: :cascade do |t|
    t.bigint "assist_membership_id"
    t.datetime "claimed_at"
    t.datetime "closed_at"
    t.integer "course_domain_id", null: false
    t.datetime "created_at", null: false
    t.boolean "done", default: false, null: false
    t.string "evaluation"
    t.text "help_question"
    t.boolean "helpline", default: false, null: false
    t.string "location"
    t.integer "membership_id", null: false
    t.text "note"
    t.string "source_label"
    t.string "subject"
    t.boolean "success", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["assist_membership_id"], name: "index_hands_on_assist_membership_id"
    t.index ["course_domain_id", "done"], name: "index_hands_on_course_domain_id_and_done"
    t.index ["course_domain_id"], name: "index_hands_on_course_domain_id"
    t.index ["membership_id"], name: "index_hands_on_membership_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "course_domain_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "invited_by_id"
    t.integer "role", default: 1, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["course_domain_id", "email"], name: "index_invitations_on_course_domain_id_and_email"
    t.index ["course_domain_id"], name: "index_invitations_on_course_domain_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "available_until"
    t.integer "course_domain_id", null: false
    t.datetime "created_at", null: false
    t.integer "invited_by_id"
    t.string "last_location"
    t.datetime "last_seen_at"
    t.string "locale"
    t.integer "role", default: 0, null: false
    t.string "source_label"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["course_domain_id"], name: "index_memberships_on_course_domain_id"
    t.index ["invited_by_id"], name: "index_memberships_on_invited_by_id"
    t.index ["user_id", "course_domain_id"], name: "index_memberships_on_user_id_and_course_domain_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "author_membership_id"
    t.integer "course_domain_id", null: false
    t.datetime "created_at", null: false
    t.boolean "log", default: false, null: false
    t.integer "membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_membership_id"], name: "index_notes_on_author_membership_id"
    t.index ["course_domain_id", "membership_id"], name: "index_notes_on_course_domain_id_and_membership_id"
    t.index ["course_domain_id"], name: "index_notes_on_course_domain_id"
    t.index ["membership_id"], name: "index_notes_on_membership_id"
  end

  create_table "presences", force: :cascade do |t|
    t.datetime "connected_at", null: false
    t.integer "course_domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_ping_at", null: false
    t.string "location"
    t.integer "membership_id", null: false
    t.string "source_label"
    t.datetime "updated_at", null: false
    t.index ["course_domain_id"], name: "index_presences_on_course_domain_id"
    t.index ["last_ping_at"], name: "index_presences_on_last_ping_at"
    t.index ["membership_id", "source_label"], name: "index_presences_on_membership_id_and_source_label", unique: true
    t.index ["membership_id"], name: "index_presences_on_membership_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "var", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.integer "channel_hash", limit: 8, null: false
    t.datetime "created_at", null: false
    t.binary "payload", limit: 536870912, null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "login"
    t.string "name"
    t.string "student_number"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "hands", "course_domains"
  add_foreign_key "hands", "memberships"
  add_foreign_key "hands", "memberships", column: "assist_membership_id"
  add_foreign_key "invitations", "course_domains"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "memberships", "course_domains"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "users", column: "invited_by_id"
  add_foreign_key "notes", "course_domains"
  add_foreign_key "notes", "memberships"
  add_foreign_key "notes", "memberships", column: "author_membership_id"
  add_foreign_key "presences", "course_domains"
  add_foreign_key "presences", "memberships"
end
