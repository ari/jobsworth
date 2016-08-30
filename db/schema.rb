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

ActiveRecord::Schema.define(version: 20160830064101) do

  create_table "access_levels", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "companies", force: :cascade do |t|
    t.string   "name",                       limit: 200,   default: "",   null: false
    t.string   "contact_email",              limit: 200
    t.string   "contact_name",               limit: 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subdomain",                  limit: 255,   default: "",   null: false
    t.boolean  "show_wiki",                                default: true
    t.text     "suppressed_email_addresses", limit: 65535
    t.string   "logo_file_name",             limit: 255
    t.string   "logo_content_type",          limit: 255
    t.integer  "logo_file_size",             limit: 4
    t.datetime "logo_updated_at"
    t.boolean  "use_resources",                            default: true
    t.boolean  "use_billing",                              default: true
    t.boolean  "use_score_rules",                          default: true
  end

  add_index "companies", ["subdomain"], name: "index_companies_on_subdomain", unique: true, using: :btree

  create_table "custom_attribute_choices", force: :cascade do |t|
    t.integer  "custom_attribute_id", limit: 4
    t.string   "value",               limit: 255
    t.integer  "position",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color",               limit: 255
  end

  add_index "custom_attribute_choices", ["custom_attribute_id"], name: "index_custom_attribute_choices_on_custom_attribute_id", using: :btree

  create_table "custom_attribute_values", force: :cascade do |t|
    t.integer  "custom_attribute_id", limit: 4
    t.integer  "attributable_id",     limit: 4
    t.string   "attributable_type",   limit: 255
    t.text     "value",               limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "choice_id",           limit: 4
  end

  add_index "custom_attribute_values", ["attributable_id", "attributable_type"], name: "by_attributables", using: :btree
  add_index "custom_attribute_values", ["custom_attribute_id"], name: "index_custom_attribute_values_on_custom_attribute_id", using: :btree

  create_table "custom_attributes", force: :cascade do |t|
    t.integer  "company_id",          limit: 4
    t.string   "attributable_type",   limit: 255
    t.string   "display_name",        limit: 255
    t.string   "ldap_attribute_type", limit: 255
    t.boolean  "mandatory"
    t.boolean  "multiple"
    t.integer  "max_length",          limit: 4
    t.integer  "position",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custom_attributes", ["company_id", "attributable_type"], name: "index_custom_attributes_on_company_id_and_attributable_type", using: :btree

  create_table "customers", force: :cascade do |t|
    t.integer  "company_id",   limit: 4,   default: 0,    null: false
    t.string   "name",         limit: 200, default: "",   null: false
    t.string   "contact_name", limit: 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                   default: true
  end

  add_index "customers", ["company_id", "name"], name: "customers_company_id_index", using: :btree

  create_table "default_project_users", force: :cascade do |t|
    t.integer  "project_id", limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "dependencies", id: false, force: :cascade do |t|
    t.integer "task_id",       limit: 4
    t.integer "dependency_id", limit: 4
  end

  add_index "dependencies", ["dependency_id"], name: "dependencies_dependency_id_index", using: :btree
  add_index "dependencies", ["task_id"], name: "dependencies_task_id_index", using: :btree

  create_table "email_address_tasks", id: false, force: :cascade do |t|
    t.integer  "task_id",          limit: 4
    t.integer  "email_address_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_addresses", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "email",      limit: 255
    t.boolean  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id", limit: 4
  end

  add_index "email_addresses", ["email"], name: "index_email_addresses_on_email", unique: true, using: :btree
  add_index "email_addresses", ["user_id"], name: "fk_email_addresses_user_id", using: :btree

  create_table "email_deliveries", force: :cascade do |t|
    t.integer  "work_log_id", limit: 4
    t.string   "status",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",       limit: 255
    t.integer  "user_id",     limit: 4
  end

  add_index "email_deliveries", ["status"], name: "index_email_deliveries_on_status", using: :btree
  add_index "email_deliveries", ["work_log_id"], name: "index_email_deliveries_on_work_log_id", using: :btree

  create_table "event_logs", force: :cascade do |t|
    t.integer  "company_id",  limit: 4
    t.integer  "project_id",  limit: 4
    t.integer  "user_id",     limit: 4
    t.integer  "event_type",  limit: 4
    t.string   "target_type", limit: 255
    t.integer  "target_id",   limit: 4
    t.string   "title",       limit: 255
    t.text     "body",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user",        limit: 255
  end

  add_index "event_logs", ["company_id", "project_id"], name: "index_event_logs_on_company_id_and_project_id", using: :btree
  add_index "event_logs", ["target_id", "target_type"], name: "index_event_logs_on_target_id_and_target_type", using: :btree
  add_index "event_logs", ["user_id"], name: "fk_event_logs_user_id", using: :btree

  create_table "generated_reports", force: :cascade do |t|
    t.integer  "company_id", limit: 4
    t.integer  "user_id",    limit: 4
    t.string   "filename",   limit: 255
    t.text     "report",     limit: 4294967295
    t.datetime "created_at"
  end

  add_index "generated_reports", ["company_id"], name: "fk_generated_reports_company_id", using: :btree
  add_index "generated_reports", ["user_id"], name: "fk_generated_reports_user_id", using: :btree

  create_table "ical_entries", force: :cascade do |t|
    t.integer "task_id",     limit: 4
    t.integer "work_log_id", limit: 4
    t.text    "body",        limit: 65535
  end

  add_index "ical_entries", ["task_id"], name: "index_ical_entries_on_task_id", using: :btree
  add_index "ical_entries", ["work_log_id"], name: "index_ical_entries_on_work_log_id", using: :btree

  create_table "keywords", force: :cascade do |t|
    t.integer  "company_id",     limit: 4
    t.integer  "task_filter_id", limit: 4
    t.string   "word",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reversed",                   default: false
  end

  add_index "keywords", ["task_filter_id"], name: "fk_keywords_task_filter_id", using: :btree

  create_table "locales", force: :cascade do |t|
    t.string   "locale",     limit: 6
    t.string   "key",        limit: 255
    t.text     "singular",   limit: 65535
    t.text     "plural",     limit: 65535
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "same",                     default: false
  end

  add_index "locales", ["locale", "key"], name: "index_locales_on_locale_and_key", unique: true, using: :btree

  create_table "milestones", force: :cascade do |t|
    t.integer  "company_id",      limit: 4
    t.integer  "project_id",      limit: 4
    t.integer  "user_id",         limit: 4
    t.string   "name",            limit: 255
    t.text     "description",     limit: 65535
    t.datetime "due_at"
    t.integer  "position",        limit: 4
    t.datetime "completed_at"
    t.integer  "total_tasks",     limit: 4,     default: 0
    t.integer  "completed_tasks", limit: 4,     default: 0
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "status",          limit: 4
    t.datetime "start_at"
  end

  add_index "milestones", ["company_id", "project_id"], name: "milestones_company_project_index", using: :btree
  add_index "milestones", ["company_id"], name: "milestones_company_id_index", using: :btree
  add_index "milestones", ["project_id"], name: "milestones_project_id_index", using: :btree
  add_index "milestones", ["user_id"], name: "fk_milestones_user_id", using: :btree

  create_table "news_items", force: :cascade do |t|
    t.datetime "created_at"
    t.text     "body",       limit: 65535
    t.boolean  "portal",                   default: true
    t.integer  "company_id", limit: 4
  end

  create_table "organizational_units", force: :cascade do |t|
    t.integer  "customer_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",        limit: 255
    t.boolean  "active",                  default: true
  end

  add_index "organizational_units", ["customer_id"], name: "fk_organizational_units_customer_id", using: :btree

  create_table "preferences", force: :cascade do |t|
    t.integer  "preferencable_id",   limit: 4
    t.string   "preferencable_type", limit: 255
    t.string   "key",                limit: 255
    t.text     "value",              limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["preferencable_id", "preferencable_type"], name: "index_preferences_on_preferencable_id_and_preferencable_type", using: :btree

  create_table "project_files", force: :cascade do |t|
    t.integer  "company_id",        limit: 4,   default: 0, null: false
    t.integer  "project_id",        limit: 4,   default: 0, null: false
    t.integer  "customer_id",       limit: 4,   default: 0, null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "thumbnail_id",      limit: 4
    t.integer  "task_id",           limit: 4
    t.integer  "user_id",           limit: 4
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4,               null: false
    t.datetime "file_updated_at"
    t.string   "uri",               limit: 255,             null: false
    t.integer  "work_log_id",       limit: 4
  end

  add_index "project_files", ["company_id"], name: "project_files_company_id_index", using: :btree
  add_index "project_files", ["customer_id"], name: "fk_project_files_customer_id", using: :btree
  add_index "project_files", ["task_id"], name: "index_project_files_on_task_id", using: :btree
  add_index "project_files", ["user_id"], name: "fk_project_files_user_id", using: :btree

  create_table "project_permissions", force: :cascade do |t|
    t.integer  "company_id",        limit: 4
    t.integer  "project_id",        limit: 4
    t.integer  "user_id",           limit: 4
    t.datetime "created_at"
    t.boolean  "can_comment",                 default: false
    t.boolean  "can_work",                    default: false
    t.boolean  "can_report",                  default: false
    t.boolean  "can_create",                  default: false
    t.boolean  "can_edit",                    default: false
    t.boolean  "can_reassign",                default: false
    t.boolean  "can_close",                   default: false
    t.boolean  "can_grant",                   default: false
    t.boolean  "can_milestone",               default: false
    t.boolean  "can_see_unwatched",           default: true
  end

  add_index "project_permissions", ["company_id"], name: "fk_project_permissions_company_id", using: :btree
  add_index "project_permissions", ["project_id"], name: "project_permissions_project_id_index", using: :btree
  add_index "project_permissions", ["user_id"], name: "project_permissions_user_id_index", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",             limit: 200,                           default: "",    null: false
    t.integer  "company_id",       limit: 4,                             default: 0,     null: false
    t.integer  "customer_id",      limit: 4,                             default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "critical_count",   limit: 4,                             default: 0
    t.integer  "normal_count",     limit: 4,                             default: 0
    t.integer  "low_count",        limit: 4,                             default: 0
    t.text     "description",      limit: 65535
    t.integer  "open_tasks",       limit: 4
    t.integer  "total_tasks",      limit: 4
    t.integer  "total_milestones", limit: 4
    t.integer  "open_milestones",  limit: 4
    t.decimal  "default_estimate",               precision: 5, scale: 2, default: 1.0
    t.boolean  "suppressBilling",                                        default: false, null: false
  end

  add_index "projects", ["company_id"], name: "projects_company_id_index", using: :btree
  add_index "projects", ["customer_id"], name: "projects_customer_id_index", using: :btree

  create_table "properties", force: :cascade do |t|
    t.integer  "company_id",    limit: 4
    t.string   "name",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "default_sort"
    t.boolean  "default_color"
    t.boolean  "mandatory",                 default: false
  end

  add_index "properties", ["company_id"], name: "index_properties_on_company_id", using: :btree

  create_table "property_values", force: :cascade do |t|
    t.integer  "property_id", limit: 4
    t.string   "value",       limit: 255
    t.string   "color",       limit: 255
    t.boolean  "default"
    t.integer  "position",    limit: 4,    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_url",    limit: 1000
  end

  add_index "property_values", ["property_id"], name: "index_property_values_on_property_id", using: :btree

  create_table "resource_attributes", force: :cascade do |t|
    t.integer  "resource_id",                limit: 4
    t.integer  "resource_type_attribute_id", limit: 4
    t.string   "value",                      limit: 255
    t.string   "password",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_attributes", ["resource_id"], name: "fk_resource_attributes_resource_id", using: :btree
  add_index "resource_attributes", ["resource_type_attribute_id"], name: "fk_resource_attributes_resource_type_attribute_id", using: :btree

  create_table "resource_type_attributes", force: :cascade do |t|
    t.integer  "resource_type_id",     limit: 4
    t.string   "name",                 limit: 255
    t.boolean  "is_mandatory"
    t.boolean  "allows_multiple"
    t.boolean  "is_password"
    t.string   "validation_regex",     limit: 255
    t.integer  "default_field_length", limit: 4
    t.integer  "position",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_type_attributes", ["resource_type_id"], name: "fk_resource_type_attributes_resource_type_id", using: :btree

  create_table "resource_types", force: :cascade do |t|
    t.integer  "company_id", limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_types", ["company_id"], name: "fk_resource_types_company_id", using: :btree

  create_table "resources", force: :cascade do |t|
    t.integer  "company_id",       limit: 4
    t.integer  "resource_type_id", limit: 4
    t.integer  "parent_id",        limit: 4
    t.string   "name",             limit: 255
    t.integer  "customer_id",      limit: 4
    t.text     "notes",            limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                         default: true
  end

  add_index "resources", ["company_id"], name: "fk_resources_company_id", using: :btree

  create_table "resources_tasks", id: false, force: :cascade do |t|
    t.integer "resource_id", limit: 4
    t.integer "task_id",     limit: 4
  end

  add_index "resources_tasks", ["resource_id"], name: "index_resources_tasks_on_resource_id", using: :btree
  add_index "resources_tasks", ["task_id"], name: "index_resources_tasks_on_task_id", using: :btree

  create_table "scm_changesets", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.integer  "scm_project_id",  limit: 4
    t.string   "author",          limit: 255
    t.integer  "changeset_num",   limit: 4
    t.datetime "commit_date"
    t.string   "changeset_rev",   limit: 255
    t.text     "message",         limit: 65535
    t.integer  "scm_files_count", limit: 4
    t.integer  "task_id",         limit: 4
  end

  add_index "scm_changesets", ["author"], name: "scm_changesets_author_index", using: :btree
  add_index "scm_changesets", ["commit_date"], name: "scm_changesets_commit_date_index", using: :btree
  add_index "scm_changesets", ["user_id"], name: "fk_scm_changesets_user_id", using: :btree

  create_table "scm_files", force: :cascade do |t|
    t.text    "path",             limit: 65535
    t.string  "state",            limit: 255
    t.integer "scm_changeset_id", limit: 4
  end

  add_index "scm_files", ["scm_changeset_id"], name: "index_scm_files_on_scm_changeset_id", using: :btree

  create_table "scm_projects", force: :cascade do |t|
    t.integer  "project_id",       limit: 4
    t.integer  "company_id",       limit: 4
    t.string   "scm_type",         limit: 255
    t.datetime "last_commit_date"
    t.datetime "last_update"
    t.datetime "last_checkout"
    t.text     "module",           limit: 65535
    t.text     "location",         limit: 65535
    t.string   "secret_key",       limit: 255
  end

  add_index "scm_projects", ["company_id"], name: "fk_scm_projects_company_id", using: :btree

  create_table "score_rules", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.integer  "score",              limit: 4
    t.integer  "score_type",         limit: 4
    t.decimal  "exponent",                       precision: 5, scale: 2, default: 1.0
    t.integer  "controlled_by_id",   limit: 4
    t.string   "controlled_by_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "score_rules", ["controlled_by_id"], name: "index_score_rules_on_controlled_by_id", using: :btree
  add_index "score_rules", ["score_type"], name: "index_score_rules_on_score_type", using: :btree

  create_table "service_level_agreements", force: :cascade do |t|
    t.integer  "service_id",  limit: 4
    t.integer  "customer_id", limit: 4
    t.boolean  "billable"
    t.integer  "company_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.integer  "company_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255
    t.text     "data",       limit: 65535
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "sessions_session_id_index", using: :btree
  add_index "sessions", ["updated_at"], name: "sessions_updated_at", using: :btree

  create_table "sheets", force: :cascade do |t|
    t.integer  "user_id",         limit: 4,     default: 0, null: false
    t.integer  "task_id",         limit: 4,     default: 0, null: false
    t.integer  "project_id",      limit: 4,     default: 0, null: false
    t.datetime "created_at"
    t.text     "body",            limit: 65535
    t.datetime "paused_at"
    t.integer  "paused_duration", limit: 4,     default: 0
  end

  add_index "sheets", ["task_id"], name: "index_sheets_on_task_id", using: :btree
  add_index "sheets", ["user_id"], name: "index_sheets_on_user_id", using: :btree

  create_table "snippets", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.text     "body",       limit: 65535
    t.integer  "company_id", limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",   limit: 4
  end

  create_table "stages_stage_models", force: :cascade do |t|
    t.integer  "stage_id",       limit: 4
    t.integer  "stage_model_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "statuses", force: :cascade do |t|
    t.integer  "company_id", limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "company_id", limit: 4
    t.string  "name",       limit: 255
  end

  add_index "tags", ["company_id", "name"], name: "index_tags_on_company_id_and_name", unique: true, using: :btree

  create_table "task_customers", force: :cascade do |t|
    t.integer  "customer_id", limit: 4
    t.integer  "task_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_customers", ["customer_id"], name: "fk_task_customers_customer_id", using: :btree
  add_index "task_customers", ["task_id"], name: "fk_task_customers_task_id", using: :btree

  create_table "task_filter_qualifiers", force: :cascade do |t|
    t.integer  "task_filter_id",     limit: 4
    t.string   "qualifiable_type",   limit: 255
    t.integer  "qualifiable_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "qualifiable_column", limit: 255
    t.boolean  "reversed",                       default: false
  end

  add_index "task_filter_qualifiers", ["task_filter_id"], name: "fk_task_filter_qualifiers_task_filter_id", using: :btree

  create_table "task_filter_users", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "task_filter_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_filter_users", ["task_filter_id"], name: "index_task_filter_users_on_task_filter_id", using: :btree
  add_index "task_filter_users", ["user_id"], name: "index_task_filter_users_on_user_id", using: :btree

  create_table "task_filters", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.integer  "company_id",         limit: 4
    t.integer  "user_id",            limit: 4
    t.boolean  "shared"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "system",                         default: false
    t.boolean  "unread_only",                    default: false
    t.integer  "recent_for_user_id", limit: 4
    t.boolean  "unassigned"
  end

  add_index "task_filters", ["company_id"], name: "fk_task_filters_company_id", using: :btree
  add_index "task_filters", ["user_id"], name: "fk_task_filters_user_id", using: :btree

  create_table "task_property_values", force: :cascade do |t|
    t.integer "task_id",           limit: 4
    t.integer "property_id",       limit: 4
    t.integer "property_value_id", limit: 4
  end

  add_index "task_property_values", ["task_id", "property_id"], name: "task_property", unique: true, using: :btree

  create_table "task_tags", id: false, force: :cascade do |t|
    t.integer "tag_id",  limit: 4
    t.integer "task_id", limit: 4
  end

  add_index "task_tags", ["tag_id"], name: "task_tags_tag_id_index", using: :btree
  add_index "task_tags", ["task_id"], name: "task_tags_task_id_index", using: :btree

  create_table "task_users", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "task_id",    limit: 4
    t.string   "type",       limit: 255, default: "TaskOwner"
    t.boolean  "unread"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_users", ["task_id"], name: "index_task_users_on_task_id", using: :btree
  add_index "task_users", ["unread", "user_id"], name: "index_task_users_on_unread_and_user_id", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.string   "name",                   limit: 200,   default: "",     null: false
    t.integer  "project_id",             limit: 4,     default: 0,      null: false
    t.integer  "position",               limit: 4,     default: 0,      null: false
    t.datetime "created_at",                                            null: false
    t.datetime "due_at"
    t.datetime "updated_at",                                            null: false
    t.datetime "completed_at"
    t.integer  "duration",               limit: 4,     default: 1
    t.integer  "hidden",                 limit: 4,     default: 0
    t.integer  "milestone_id",           limit: 4
    t.text     "description",            limit: 65535
    t.integer  "company_id",             limit: 4
    t.integer  "priority",               limit: 4,     default: 0
    t.integer  "updated_by_id",          limit: 4
    t.integer  "severity_id",            limit: 4,     default: 0
    t.integer  "type_id",                limit: 4,     default: 0
    t.integer  "task_num",               limit: 4,     default: 0
    t.integer  "status",                 limit: 4,     default: 0
    t.integer  "creator_id",             limit: 4
    t.datetime "hide_until"
    t.integer  "worked_minutes",         limit: 4,     default: 0
    t.string   "type",                   limit: 255,   default: "Task"
    t.integer  "weight",                 limit: 4,     default: 0
    t.integer  "weight_adjustment",      limit: 4,     default: 0
    t.boolean  "wait_for_customer",                    default: false
    t.integer  "service_id",             limit: 4
    t.boolean  "isQuoted",                             default: false,  null: false
    t.datetime "estimate_date"
    t.integer  "position_task_template", limit: 4
  end

  add_index "tasks", ["company_id"], name: "tasks_company_id_index", using: :btree
  add_index "tasks", ["due_at"], name: "tasks_due_at_idx", using: :btree
  add_index "tasks", ["milestone_id"], name: "index_tasks_on_milestone_id", using: :btree
  add_index "tasks", ["project_id", "completed_at"], name: "tasks_project_completed_index", using: :btree
  add_index "tasks", ["project_id", "milestone_id"], name: "tasks_project_id_index", using: :btree
  add_index "tasks", ["type", "task_num", "company_id"], name: "index_tasks_on_type_and_task_num_and_company_id", unique: true, using: :btree

  create_table "time_ranges", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.text     "start",      limit: 65535
    t.text     "end",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "todos", force: :cascade do |t|
    t.integer  "task_id",              limit: 4
    t.string   "name",                 limit: 255
    t.integer  "position",             limit: 4
    t.integer  "creator_id",           limit: 4
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "completed_by_user_id", limit: 4
  end

  add_index "todos", ["task_id"], name: "index_todos_on_task_id", using: :btree

  create_table "trigger_actions", force: :cascade do |t|
    t.integer  "trigger_id", limit: 4
    t.string   "name",       limit: 255
    t.string   "type",       limit: 255
    t.integer  "argument",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "triggers", force: :cascade do |t|
    t.integer  "company_id",     limit: 4
    t.integer  "task_filter_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "event_id",       limit: 4
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                       limit: 200, default: "",         null: false
    t.string   "username",                   limit: 200, default: "",         null: false
    t.integer  "company_id",                 limit: 4,   default: 0,          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "admin",                      limit: 4,   default: 0
    t.string   "time_zone",                  limit: 255
    t.integer  "option_tracktime",           limit: 4
    t.integer  "seen_news_id",               limit: 4,   default: 0
    t.integer  "last_project_id",            limit: 4
    t.datetime "last_seen_at"
    t.datetime "last_ping_at"
    t.integer  "last_milestone_id",          limit: 4
    t.integer  "last_filter",                limit: 4
    t.string   "date_format",                limit: 255, default: "%d/%m/%Y", null: false
    t.string   "time_format",                limit: 255, default: "%H:%M",    null: false
    t.string   "uuid",                       limit: 255,                      null: false
    t.integer  "seen_welcome",               limit: 4,   default: 0
    t.string   "locale",                     limit: 255, default: "en_US"
    t.integer  "option_avatars",             limit: 4,   default: 1
    t.string   "autologin",                  limit: 255,                      null: false
    t.datetime "remember_until"
    t.boolean  "option_floating_chat",                   default: true
    t.boolean  "create_projects",                        default: true
    t.boolean  "receive_own_notifications",              default: false
    t.boolean  "use_resources"
    t.integer  "customer_id",                limit: 4
    t.boolean  "active",                                 default: true
    t.boolean  "read_clients",                           default: false
    t.boolean  "create_clients",                         default: false
    t.boolean  "edit_clients",                           default: false
    t.boolean  "can_approve_work_logs"
    t.boolean  "auto_add_to_customer_tasks"
    t.integer  "access_level_id",            limit: 4,   default: 1
    t.string   "avatar_file_name",           limit: 255
    t.string   "avatar_content_type",        limit: 255
    t.integer  "avatar_file_size",           limit: 4
    t.datetime "avatar_updated_at"
    t.string   "encrypted_password",         limit: 128, default: "",         null: false
    t.string   "password_salt",              limit: 255, default: "",         null: false
    t.string   "reset_password_token",       limit: 255
    t.string   "remember_token",             limit: 255
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",              limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",         limit: 255
    t.string   "last_sign_in_ip",            limit: 255
    t.datetime "reset_password_sent_at"
    t.boolean  "need_schedule"
    t.boolean  "receive_notifications",                  default: true
    t.boolean  "comment_private_by_default",             default: false
  end

  add_index "users", ["autologin"], name: "index_users_on_autologin", using: :btree
  add_index "users", ["company_id"], name: "users_company_id_index", using: :btree
  add_index "users", ["customer_id"], name: "index_users_on_customer_id", using: :btree
  add_index "users", ["last_seen_at"], name: "index_users_on_last_seen_at", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username", "company_id"], name: "index_users_on_username_and_company_id", unique: true, using: :btree
  add_index "users", ["uuid"], name: "users_uuid_index", using: :btree

  create_table "widgets", force: :cascade do |t|
    t.integer  "company_id",  limit: 4
    t.integer  "user_id",     limit: 4
    t.string   "name",        limit: 255
    t.integer  "widget_type", limit: 4,     default: 0
    t.integer  "number",      limit: 4,     default: 5
    t.boolean  "mine"
    t.string   "order_by",    limit: 255
    t.string   "group_by",    limit: 255
    t.string   "filter_by",   limit: 255
    t.boolean  "collapsed",                 default: false
    t.integer  "column",      limit: 4,     default: 0
    t.integer  "position",    limit: 4,     default: 0
    t.boolean  "configured",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "gadget_url",  limit: 65535
  end

  add_index "widgets", ["company_id"], name: "fk_widgets_company_id", using: :btree
  add_index "widgets", ["user_id"], name: "index_widgets_on_user_id", using: :btree

  create_table "wiki_pages", force: :cascade do |t|
    t.integer  "company_id", limit: 4
    t.integer  "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.datetime "locked_at"
    t.integer  "locked_by",  limit: 4
  end

  add_index "wiki_pages", ["company_id"], name: "wiki_pages_company_id_index", using: :btree

  create_table "wiki_references", force: :cascade do |t|
    t.integer  "wiki_page_id",    limit: 4
    t.string   "referenced_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wiki_references", ["wiki_page_id"], name: "index_wiki_references_on_wiki_page_id", using: :btree

  create_table "wiki_revisions", force: :cascade do |t|
    t.integer  "wiki_page_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body",         limit: 65535
    t.integer  "user_id",      limit: 4
    t.string   "change",       limit: 255
  end

  add_index "wiki_revisions", ["user_id"], name: "fk_wiki_revisions_user_id", using: :btree
  add_index "wiki_revisions", ["wiki_page_id"], name: "wiki_revisions_wiki_page_id_index", using: :btree

  create_table "work_logs", force: :cascade do |t|
    t.integer  "user_id",          limit: 4,     default: 0
    t.integer  "task_id",          limit: 4
    t.integer  "project_id",       limit: 4,     default: 0, null: false
    t.integer  "company_id",       limit: 4,     default: 0, null: false
    t.integer  "customer_id",      limit: 4,     default: 0, null: false
    t.datetime "started_at",                                 null: false
    t.integer  "duration",         limit: 4,     default: 0, null: false
    t.text     "body",             limit: 65535
    t.datetime "exported"
    t.integer  "status",           limit: 4,     default: 0
    t.integer  "access_level_id",  limit: 4,     default: 1
    t.integer  "email_address_id", limit: 4
  end

  add_index "work_logs", ["company_id"], name: "work_logs_company_id_index", using: :btree
  add_index "work_logs", ["customer_id"], name: "work_logs_customer_id_index", using: :btree
  add_index "work_logs", ["project_id"], name: "work_logs_project_id_index", using: :btree
  add_index "work_logs", ["task_id", "started_at"], name: "index_work_logs_on_task_id_and_started_at", using: :btree
  add_index "work_logs", ["task_id"], name: "work_logs_task_id_index", using: :btree
  add_index "work_logs", ["user_id", "task_id"], name: "work_logs_user_id_index", using: :btree

  create_table "work_plans", force: :cascade do |t|
    t.decimal  "monday",               precision: 1, default: 8
    t.decimal  "tuesday",              precision: 1, default: 8
    t.decimal  "wednesday",            precision: 1, default: 8
    t.decimal  "thursday",             precision: 1, default: 8
    t.decimal  "friday",               precision: 1, default: 8
    t.decimal  "saturday",             precision: 1, default: 0
    t.decimal  "sunday",               precision: 1, default: 0
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_plans", ["user_id"], name: "index_work_plans_on_user_id", using: :btree

end
