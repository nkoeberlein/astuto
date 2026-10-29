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

ActiveRecord::Schema[8.1].define(version: 2026_10_29_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id", null: false
    t.string "common_token_prefix", null: false
    t.string "random_token_prefix", null: false
    t.string "token_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_api_keys_on_tenant_id"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
    t.index ["user_id", "tenant_id"], name: "index_api_keys_on_user_id_and_tenant_id", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id"
    t.string "actor_label"
    t.string "action", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "subject_label"
    t.jsonb "field_changes", default: {}, null: false
    t.string "source", default: "app", null: false
    t.string "ip"
    t.datetime "created_at", null: false
    t.index ["tenant_id", "action"], name: "index_audit_events_on_tenant_id_and_action"
    t.index ["tenant_id", "created_at"], name: "index_audit_events_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_audit_events_on_tenant_id"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "boards", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", null: false
    t.bigint "tenant_id", null: false
    t.string "slug"
    t.index ["name", "tenant_id"], name: "index_boards_on_name_and_tenant_id", unique: true
    t.index ["slug", "tenant_id"], name: "index_boards_on_slug_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_boards_on_tenant_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_post_update", default: false, null: false
    t.bigint "tenant_id", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["tenant_id"], name: "index_comments_on_tenant_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["post_id"], name: "index_follows_on_post_id"
    t.index ["tenant_id"], name: "index_follows_on_tenant_id"
    t.index ["user_id", "post_id"], name: "index_follows_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "email", null: false
    t.string "token_digest", null: false
    t.datetime "accepted_at", precision: nil
    t.bigint "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email", "tenant_id"], name: "index_invitations_on_email_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_invitations_on_tenant_id"
  end

  create_table "ldap_configs", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.boolean "enabled", default: false, null: false
    t.string "label", default: "Company account", null: false
    t.string "host"
    t.integer "port", default: 389, null: false
    t.string "encryption", default: "start_tls", null: false
    t.boolean "verify_certificate", default: true, null: false
    t.string "base_dn"
    t.string "bind_dn"
    t.string "bind_password_ciphertext"
    t.string "user_filter", default: "(|(uid=%{login})(sAMAccountName=%{login})(mail=%{login}))", null: false
    t.string "email_attribute", default: "mail", null: false
    t.string "name_attribute", default: "displayName", null: false
    t.boolean "auto_create_users", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_ldap_configs_on_tenant_id", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["tenant_id"], name: "index_likes_on_tenant_id"
    t.index ["user_id", "post_id"], name: "index_likes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "o_auths", force: :cascade do |t|
    t.string "name", null: false
    t.string "logo"
    t.boolean "is_enabled", default: false, null: false
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.string "authorize_url", null: false
    t.string "token_url", null: false
    t.string "profile_url", null: false
    t.string "scope", null: false
    t.string "json_user_name_path"
    t.string "json_user_email_path", null: false
    t.bigint "tenant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.jsonb "profile_headers", default: [], null: false
    t.index ["name", "tenant_id"], name: "index_o_auths_on_name_and_tenant_id", unique: true
    t.index ["slug", "tenant_id"], name: "index_o_auths_on_slug_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_o_auths_on_tenant_id"
  end

  create_table "post_status_changes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.bigint "post_status_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["post_id"], name: "index_post_status_changes_on_post_id"
    t.index ["post_status_id"], name: "index_post_status_changes_on_post_status_id"
    t.index ["tenant_id"], name: "index_post_status_changes_on_tenant_id"
    t.index ["user_id"], name: "index_post_status_changes_on_user_id"
  end

  create_table "post_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", null: false
    t.boolean "show_in_roadmap", default: false, null: false
    t.bigint "tenant_id", null: false
    t.index ["name", "tenant_id"], name: "index_post_statuses_on_name_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_post_statuses_on_tenant_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "board_id", null: false
    t.bigint "user_id"
    t.bigint "post_status_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.string "slug"
    t.integer "approval_status", default: 0, null: false
    t.index ["board_id"], name: "index_posts_on_board_id"
    t.index ["post_status_id"], name: "index_posts_on_post_status_id"
    t.index ["slug", "tenant_id"], name: "index_posts_on_slug_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_posts_on_tenant_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "saml_configs", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.boolean "enabled", default: false, null: false
    t.string "label", default: "Single sign-on", null: false
    t.string "idp_entity_id"
    t.string "idp_sso_url"
    t.text "idp_cert"
    t.string "email_attribute"
    t.string "name_attribute"
    t.boolean "auto_create_users", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_saml_configs_on_tenant_id", unique: true
  end

  create_table "tenant_default_o_auths", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "o_auth_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["o_auth_id"], name: "index_tenant_default_o_auths_on_o_auth_id"
    t.index ["tenant_id"], name: "index_tenant_default_o_auths_on_tenant_id"
  end

  create_table "tenant_settings", force: :cascade do |t|
    t.integer "brand_display", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_vote_count", default: true, null: false
    t.boolean "show_vote_button_in_board", default: true, null: false
    t.integer "root_board_id", default: 0, null: false
    t.boolean "show_roadmap_in_header", default: true, null: false
    t.integer "collapse_boards_in_header", default: 0, null: false
    t.text "custom_css"
    t.boolean "show_powered_by", default: true, null: false
    t.boolean "allow_anonymous_feedback", default: true, null: false
    t.integer "feedback_approval_policy", default: 0, null: false
    t.boolean "is_private", default: false, null: false
    t.integer "email_registration_policy", default: 0, null: false
    t.string "allowed_email_domains"
    t.boolean "use_browser_locale", default: false, null: false
    t.integer "logo_links_to", default: 0, null: false
    t.string "logo_custom_url"
    t.boolean "hide_unused_statuses_in_filter_by_status", default: false, null: false
    t.boolean "roadmap_enabled", default: true, null: false
    t.string "default_post_sorting", default: "trending", null: false
    t.jsonb "custom_links", default: [], null: false
    t.boolean "login_only_with_oauth", default: false, null: false
    t.integer "mail_logo_size", default: 64, null: false
    t.boolean "use_gravatar", default: true, null: false
    t.boolean "require_two_factor_for_staff", default: false, null: false
    t.index ["tenant_id"], name: "index_tenant_settings_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "site_name", null: false
    t.string "site_logo"
    t.string "subdomain", null: false
    t.string "locale", default: "en"
    t.string "custom_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.string "site_favicon"
    t.index ["custom_domain"], name: "index_tenants_on_custom_domain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.string "full_name"
    t.boolean "notifications_enabled", default: true, null: false
    t.integer "status"
    t.bigint "tenant_id", null: false
    t.string "oauth_token"
    t.boolean "has_set_password", default: true, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "recap_notification_frequency", default: 0, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "otp_secret_ciphertext"
    t.datetime "otp_enabled_at"
    t.bigint "otp_last_used_at"
    t.jsonb "otp_backup_code_digests", default: [], null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email", "tenant_id"], name: "index_users_on_email_and_tenant_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.bigint "webhook_id", null: false
    t.bigint "tenant_id", null: false
    t.string "trigger", null: false
    t.boolean "is_test", default: false, null: false
    t.boolean "success", default: false, null: false
    t.integer "http_status"
    t.integer "duration_ms"
    t.text "error"
    t.text "response_body"
    t.datetime "created_at", null: false
    t.index ["tenant_id"], name: "index_webhook_deliveries_on_tenant_id"
    t.index ["webhook_id", "created_at"], name: "index_webhook_deliveries_on_webhook_id_and_created_at"
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "is_enabled", default: false, null: false
    t.integer "trigger", default: 0, null: false
    t.string "url", null: false
    t.text "http_body"
    t.integer "http_method", default: 0, null: false
    t.json "http_headers"
    t.bigint "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signing_secret"
    t.index ["name", "tenant_id"], name: "index_webhooks_on_name_and_tenant_id", unique: true
    t.index ["tenant_id"], name: "index_webhooks_on_tenant_id"
  end

  add_foreign_key "api_keys", "tenants"
  add_foreign_key "api_keys", "users"
  add_foreign_key "audit_events", "tenants"
  add_foreign_key "audit_events", "users", on_delete: :nullify
  add_foreign_key "boards", "tenants"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "tenants"
  add_foreign_key "comments", "users"
  add_foreign_key "follows", "posts"
  add_foreign_key "follows", "tenants"
  add_foreign_key "follows", "users"
  add_foreign_key "invitations", "tenants"
  add_foreign_key "ldap_configs", "tenants"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "tenants"
  add_foreign_key "likes", "users"
  add_foreign_key "o_auths", "tenants"
  add_foreign_key "post_status_changes", "post_statuses"
  add_foreign_key "post_status_changes", "posts"
  add_foreign_key "post_status_changes", "tenants"
  add_foreign_key "post_status_changes", "users"
  add_foreign_key "post_statuses", "tenants"
  add_foreign_key "posts", "boards"
  add_foreign_key "posts", "post_statuses"
  add_foreign_key "posts", "tenants"
  add_foreign_key "posts", "users"
  add_foreign_key "saml_configs", "tenants"
  add_foreign_key "tenant_default_o_auths", "o_auths"
  add_foreign_key "tenant_default_o_auths", "tenants"
  add_foreign_key "tenant_settings", "tenants"
  add_foreign_key "users", "tenants"
  add_foreign_key "webhook_deliveries", "tenants"
  add_foreign_key "webhook_deliveries", "webhooks", on_delete: :cascade
  add_foreign_key "webhooks", "tenants"
end
