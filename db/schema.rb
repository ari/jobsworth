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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120628060528) do

  create_table "access_levels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activities", :force => true do |t|
    t.integer  "user_id",       :default => 0,  :null => false
    t.integer  "company_id",    :default => 0,  :null => false
    t.integer  "customer_id",   :default => 0,  :null => false
    t.integer  "project_id",    :default => 0,  :null => false
    t.integer  "activity_type", :default => 0,  :null => false
    t.string   "body",          :default => "", :null => false
    t.datetime "created_at",                    :null => false
  end

  add_index "activities", ["company_id"], :name => "fk_activities_company_id"
  add_index "activities", ["customer_id"], :name => "fk_activities_customer_id"
  add_index "activities", ["user_id"], :name => "fk_activities_user_id"

  create_table "companies", :force => true do |t|
    t.string   "name",                       :limit => 200, :default => "",   :null => false
    t.string   "contact_email",              :limit => 200
    t.string   "contact_name",               :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subdomain",                                 :default => "",   :null => false
    t.boolean  "show_wiki",                                 :default => true
    t.string   "suppressed_email_addresses"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
  end

  add_index "companies", ["subdomain"], :name => "index_companies_on_subdomain", :unique => true

  create_table "custom_attribute_choices", :force => true do |t|
    t.integer  "custom_attribute_id"
    t.string   "value"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color"
  end

  add_index "custom_attribute_choices", ["custom_attribute_id"], :name => "index_custom_attribute_choices_on_custom_attribute_id"

  create_table "custom_attribute_values", :force => true do |t|
    t.integer  "custom_attribute_id"
    t.integer  "attributable_id"
    t.string   "attributable_type"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "choice_id"
  end

  add_index "custom_attribute_values", ["attributable_id", "attributable_type"], :name => "by_attributables"
  add_index "custom_attribute_values", ["custom_attribute_id"], :name => "index_custom_attribute_values_on_custom_attribute_id"

  create_table "custom_attributes", :force => true do |t|
    t.integer  "company_id"
    t.string   "attributable_type"
    t.string   "display_name"
    t.string   "ldap_attribute_type"
    t.boolean  "mandatory"
    t.boolean  "multiple"
    t.integer  "max_length"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custom_attributes", ["company_id", "attributable_type"], :name => "index_custom_attributes_on_company_id_and_attributable_type"

  create_table "customers", :force => true do |t|
    t.integer  "company_id",                  :default => 0,    :null => false
    t.string   "name",         :limit => 200, :default => "",   :null => false
    t.string   "contact_name", :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                      :default => true
  end

  add_index "customers", ["company_id", "name"], :name => "customers_company_id_index"

  create_table "dependencies", :id => false, :force => true do |t|
    t.integer "task_id"
    t.integer "dependency_id"
  end

  add_index "dependencies", ["dependency_id"], :name => "dependencies_dependency_id_index"
  add_index "dependencies", ["task_id"], :name => "dependencies_task_id_index"

  create_table "email_address_tasks", :id => false, :force => true do |t|
    t.integer  "task_id"
    t.integer  "email_address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_addresses", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.boolean  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_addresses", ["user_id"], :name => "fk_email_addresses_user_id"

  create_table "email_deliveries", :force => true do |t|
    t.integer  "work_log_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.integer  "user_id"
  end

  add_index "email_deliveries", ["status"], :name => "index_email_deliveries_on_status"

  create_table "event_logs", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "event_type"
    t.string   "target_type"
    t.integer  "target_id"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user"
  end

  add_index "event_logs", ["company_id", "project_id"], :name => "index_event_logs_on_company_id_and_project_id"
  add_index "event_logs", ["target_id", "target_type"], :name => "index_event_logs_on_target_id_and_target_type"
  add_index "event_logs", ["user_id"], :name => "fk_event_logs_user_id"

  create_table "generated_reports", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.string   "filename"
    t.text     "report"
    t.datetime "created_at"
  end

  add_index "generated_reports", ["company_id"], :name => "fk_generated_reports_company_id"
  add_index "generated_reports", ["user_id"], :name => "fk_generated_reports_user_id"

  create_table "ical_entries", :force => true do |t|
    t.integer "task_id"
    t.integer "work_log_id"
    t.text    "body"
  end

  add_index "ical_entries", ["task_id"], :name => "index_ical_entries_on_task_id"
  add_index "ical_entries", ["work_log_id"], :name => "index_ical_entries_on_work_log_id"

  create_table "keywords", :force => true do |t|
    t.integer  "company_id"
    t.integer  "task_filter_id"
    t.string   "word"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reversed",       :default => false
  end

  add_index "keywords", ["task_filter_id"], :name => "fk_keywords_task_filter_id"

  create_table "locales", :force => true do |t|
    t.string   "locale",     :limit => 6
    t.string   "key"
    t.text     "singular"
    t.text     "plural"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "same",                    :default => false
  end

  add_index "locales", ["locale", "key"], :name => "index_locales_on_locale_and_key", :unique => true

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.string   "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "milestones", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.datetime "due_at"
    t.integer  "position"
    t.datetime "completed_at"
    t.integer  "total_tasks",     :default => 0
    t.integer  "completed_tasks", :default => 0
    t.datetime "scheduled_at"
    t.boolean  "scheduled",       :default => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "milestones", ["company_id", "project_id"], :name => "milestones_company_project_index"
  add_index "milestones", ["company_id"], :name => "milestones_company_id_index"
  add_index "milestones", ["project_id"], :name => "milestones_project_id_index"
  add_index "milestones", ["user_id"], :name => "fk_milestones_user_id"

  create_table "news_items", :force => true do |t|
    t.datetime "created_at"
    t.text     "body"
    t.boolean  "portal",     :default => true
  end

  create_table "organizational_units", :force => true do |t|
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "active",      :default => true
  end

  add_index "organizational_units", ["customer_id"], :name => "fk_organizational_units_customer_id"

  create_table "pages", :force => true do |t|
    t.string   "name",         :limit => 200, :default => "",    :null => false
    t.text     "body"
    t.integer  "company_id",                  :default => 0,     :null => false
    t.integer  "user_id",                     :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.integer  "notable_id"
    t.string   "notable_type"
    t.boolean  "snippet",                     :default => false
  end

  add_index "pages", ["company_id"], :name => "pages_company_id_index"
  add_index "pages", ["notable_id", "notable_type"], :name => "index_pages_on_notable_id_and_notable_type"
  add_index "pages", ["user_id"], :name => "fk_pages_user_id"

  create_table "preferences", :force => true do |t|
    t.integer  "preferencable_id"
    t.string   "preferencable_type"
    t.string   "key"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "preferences", ["preferencable_id", "preferencable_type"], :name => "index_preferences_on_preferencable_id_and_preferencable_type"

  create_table "project_files", :force => true do |t|
    t.integer  "company_id",        :default => 0, :null => false
    t.integer  "project_id",        :default => 0, :null => false
    t.integer  "customer_id",       :default => 0, :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "thumbnail_id"
    t.integer  "task_id"
    t.integer  "project_folder_id"
    t.integer  "user_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size",                   :null => false
    t.datetime "file_updated_at"
    t.string   "uri",                              :null => false
    t.integer  "work_log_id"
  end

  add_index "project_files", ["company_id"], :name => "project_files_company_id_index"
  add_index "project_files", ["customer_id"], :name => "fk_project_files_customer_id"
  add_index "project_files", ["project_folder_id"], :name => "index_project_files_on_project_folder_id"
  add_index "project_files", ["task_id"], :name => "index_project_files_on_task_id"
  add_index "project_files", ["user_id"], :name => "fk_project_files_user_id"

  create_table "project_folders", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.integer  "company_id"
  end

  add_index "project_folders", ["parent_id"], :name => "index_project_folders_on_parent_id"
  add_index "project_folders", ["project_id"], :name => "index_project_folders_on_project_id"

  create_table "project_permissions", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.boolean  "can_comment",       :default => false
    t.boolean  "can_work",          :default => false
    t.boolean  "can_report",        :default => false
    t.boolean  "can_create",        :default => false
    t.boolean  "can_edit",          :default => false
    t.boolean  "can_reassign",      :default => false
    t.boolean  "can_close",         :default => false
    t.boolean  "can_grant",         :default => false
    t.boolean  "can_milestone",     :default => false
    t.boolean  "can_see_unwatched", :default => true
  end

  add_index "project_permissions", ["company_id"], :name => "fk_project_permissions_company_id"
  add_index "project_permissions", ["project_id"], :name => "project_permissions_project_id_index"
  add_index "project_permissions", ["user_id"], :name => "project_permissions_user_id_index"

  create_table "projects", :force => true do |t|
    t.string   "name",             :limit => 200,                               :default => "",    :null => false
    t.integer  "company_id",                                                    :default => 0,     :null => false
    t.integer  "customer_id",                                                   :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "critical_count",                                                :default => 0
    t.integer  "normal_count",                                                  :default => 0
    t.integer  "low_count",                                                     :default => 0
    t.text     "description"
    t.integer  "open_tasks"
    t.integer  "total_tasks"
    t.integer  "total_milestones"
    t.integer  "open_milestones"
    t.decimal  "default_estimate",                :precision => 5, :scale => 2, :default => 1.0
    t.boolean  "suppressBilling",                                               :default => false, :null => false
  end

  add_index "projects", ["company_id"], :name => "projects_company_id_index"
  add_index "projects", ["customer_id"], :name => "projects_customer_id_index"

  create_table "properties", :force => true do |t|
    t.integer  "company_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "default_sort"
    t.boolean  "default_color"
    t.boolean  "mandatory",     :default => false
  end

  add_index "properties", ["company_id"], :name => "index_properties_on_company_id"

  create_table "property_values", :force => true do |t|
    t.integer  "property_id"
    t.string   "value"
    t.string   "color"
    t.boolean  "default"
    t.integer  "position",                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_url",    :limit => 1000
  end

  add_index "property_values", ["property_id"], :name => "index_property_values_on_property_id"

  create_table "resource_attributes", :force => true do |t|
    t.integer  "resource_id"
    t.integer  "resource_type_attribute_id"
    t.string   "value"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_attributes", ["resource_id"], :name => "fk_resource_attributes_resource_id"
  add_index "resource_attributes", ["resource_type_attribute_id"], :name => "fk_resource_attributes_resource_type_attribute_id"

  create_table "resource_type_attributes", :force => true do |t|
    t.integer  "resource_type_id"
    t.string   "name"
    t.boolean  "is_mandatory"
    t.boolean  "allows_multiple"
    t.boolean  "is_password"
    t.string   "validation_regex"
    t.integer  "default_field_length"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_type_attributes", ["resource_type_id"], :name => "fk_resource_type_attributes_resource_type_id"

  create_table "resource_types", :force => true do |t|
    t.integer  "company_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_types", ["company_id"], :name => "fk_resource_types_company_id"

  create_table "resources", :force => true do |t|
    t.integer  "company_id"
    t.integer  "resource_type_id"
    t.integer  "parent_id"
    t.string   "name"
    t.integer  "customer_id"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",           :default => true
  end

  add_index "resources", ["company_id"], :name => "fk_resources_company_id"

  create_table "resources_tasks", :id => false, :force => true do |t|
    t.integer "resource_id"
    t.integer "task_id"
  end

  add_index "resources_tasks", ["resource_id"], :name => "index_resources_tasks_on_resource_id"
  add_index "resources_tasks", ["task_id"], :name => "index_resources_tasks_on_task_id"

  create_table "scm_changesets", :force => true do |t|
    t.integer  "user_id"
    t.integer  "scm_project_id"
    t.string   "author"
    t.integer  "changeset_num"
    t.datetime "commit_date"
    t.string   "changeset_rev"
    t.text     "message"
    t.integer  "scm_files_count"
    t.integer  "task_id"
  end

  add_index "scm_changesets", ["author"], :name => "scm_changesets_author_index"
  add_index "scm_changesets", ["commit_date"], :name => "scm_changesets_commit_date_index"
  add_index "scm_changesets", ["user_id"], :name => "fk_scm_changesets_user_id"

  create_table "scm_files", :force => true do |t|
    t.text    "path"
    t.string  "state"
    t.integer "scm_changeset_id"
  end

  add_index "scm_files", ["scm_changeset_id"], :name => "index_scm_files_on_scm_changeset_id"

  create_table "scm_projects", :force => true do |t|
    t.integer  "project_id"
    t.integer  "company_id"
    t.string   "scm_type"
    t.datetime "last_commit_date"
    t.datetime "last_update"
    t.datetime "last_checkout"
    t.text     "module"
    t.text     "location"
    t.string   "secret_key"
  end

  add_index "scm_projects", ["company_id"], :name => "fk_scm_projects_company_id"

  create_table "score_rules", :force => true do |t|
    t.string   "name"
    t.integer  "score"
    t.integer  "score_type"
    t.decimal  "exponent",           :precision => 5, :scale => 2, :default => 1.0
    t.integer  "controlled_by_id"
    t.string   "controlled_by_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "score_rules", ["controlled_by_id"], :name => "index_score_rules_on_controlled_by_id"
  add_index "score_rules", ["score_type"], :name => "index_score_rules_on_score_type"

  create_table "service_level_agreements", :force => true do |t|
    t.integer  "service_id"
    t.integer  "customer_id"
    t.boolean  "billable"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"
  add_index "sessions", ["updated_at"], :name => "sessions_updated_at"

  create_table "sheets", :force => true do |t|
    t.integer  "user_id",         :default => 0, :null => false
    t.integer  "task_id",         :default => 0, :null => false
    t.integer  "project_id",      :default => 0, :null => false
    t.datetime "created_at"
    t.text     "body"
    t.datetime "paused_at"
    t.integer  "paused_duration", :default => 0
  end

  add_index "sheets", ["task_id"], :name => "index_sheets_on_task_id"
  add_index "sheets", ["user_id"], :name => "index_sheets_on_user_id"

  create_table "statuses", :force => true do |t|
    t.integer  "company_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.integer "company_id"
    t.string  "name"
  end

  add_index "tags", ["company_id", "name"], :name => "index_tags_on_company_id_and_name"

  create_table "task_customers", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_customers", ["customer_id"], :name => "fk_task_customers_customer_id"
  add_index "task_customers", ["task_id"], :name => "fk_task_customers_task_id"

  create_table "task_filter_qualifiers", :force => true do |t|
    t.integer  "task_filter_id"
    t.string   "qualifiable_type"
    t.integer  "qualifiable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "qualifiable_column"
    t.boolean  "reversed",           :default => false
  end

  add_index "task_filter_qualifiers", ["task_filter_id"], :name => "fk_task_filter_qualifiers_task_filter_id"

  create_table "task_filter_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "task_filter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_filter_users", ["task_filter_id"], :name => "index_task_filter_users_on_task_filter_id"
  add_index "task_filter_users", ["user_id"], :name => "index_task_filter_users_on_user_id"

  create_table "task_filters", :force => true do |t|
    t.string   "name"
    t.integer  "company_id"
    t.integer  "user_id"
    t.boolean  "shared"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "system",             :default => false
    t.boolean  "unread_only",        :default => false
    t.integer  "recent_for_user_id"
  end

  add_index "task_filters", ["company_id"], :name => "fk_task_filters_company_id"
  add_index "task_filters", ["user_id"], :name => "fk_task_filters_user_id"

  create_table "task_property_values", :force => true do |t|
    t.integer "task_id"
    t.integer "property_id"
    t.integer "property_value_id"
  end

  add_index "task_property_values", ["task_id", "property_id"], :name => "task_property", :unique => true

  create_table "task_tags", :id => false, :force => true do |t|
    t.integer "tag_id"
    t.integer "task_id"
  end

  add_index "task_tags", ["tag_id"], :name => "task_tags_tag_id_index"
  add_index "task_tags", ["task_id"], :name => "task_tags_task_id_index"

  create_table "task_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "task_id"
    t.string   "type",       :default => "TaskOwner"
    t.boolean  "unread"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_users", ["task_id"], :name => "index_task_users_on_task_id"
  add_index "task_users", ["user_id"], :name => "index_task_users_on_user_id"

  create_table "tasks", :force => true do |t|
    t.string   "name",               :limit => 200,                               :default => "",     :null => false
    t.integer  "project_id",                                                      :default => 0,      :null => false
    t.integer  "position",                                                        :default => 0,      :null => false
    t.datetime "created_at",                                                                          :null => false
    t.datetime "due_at"
    t.datetime "updated_at",                                                                          :null => false
    t.datetime "completed_at"
    t.integer  "duration",                                                        :default => 1
    t.integer  "hidden",                                                          :default => 0
    t.integer  "milestone_id"
    t.text     "description"
    t.integer  "company_id"
    t.integer  "priority",                                                        :default => 0
    t.integer  "updated_by_id"
    t.integer  "severity_id",                                                     :default => 0
    t.integer  "type_id",                                                         :default => 0
    t.integer  "task_num",                                                        :default => 0
    t.integer  "status",                                                          :default => 0
    t.integer  "creator_id"
    t.datetime "hide_until"
    t.datetime "scheduled_at"
    t.integer  "scheduled_duration"
    t.boolean  "scheduled",                                                       :default => false
    t.integer  "worked_minutes",                                                  :default => 0
    t.string   "type",                                                            :default => "Task"
    t.integer  "weight",                                                          :default => 0
    t.integer  "weight_adjustment",                                               :default => 0
    t.boolean  "wait_for_customer",                                               :default => false
    t.decimal  "estimate",                          :precision => 5, :scale => 2
    t.integer  "service_id"
    t.boolean  "isQuoted",                                                        :default => false,  :null => false
  end

  add_index "tasks", ["company_id"], :name => "tasks_company_id_index"
  add_index "tasks", ["due_at"], :name => "tasks_due_at_idx"
  add_index "tasks", ["milestone_id"], :name => "index_tasks_on_milestone_id"
  add_index "tasks", ["project_id", "completed_at"], :name => "tasks_project_completed_index"
  add_index "tasks", ["project_id", "milestone_id"], :name => "tasks_project_id_index"
  add_index "tasks", ["type", "task_num", "company_id"], :name => "index_tasks_on_type_and_task_num_and_company_id", :unique => true

  create_table "time_ranges", :force => true do |t|
    t.string   "name"
    t.text     "start"
    t.text     "end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "todos", :force => true do |t|
    t.integer  "task_id"
    t.string   "name"
    t.integer  "position"
    t.integer  "creator_id"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "completed_by_user_id"
  end

  add_index "todos", ["task_id"], :name => "index_todos_on_task_id"

  create_table "trigger_actions", :force => true do |t|
    t.integer  "trigger_id"
    t.string   "name"
    t.string   "type"
    t.integer  "argument"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "triggers", :force => true do |t|
    t.integer  "company_id"
    t.integer  "task_filter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "event_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name",                       :limit => 200, :default => "",                            :null => false
    t.string   "username",                   :limit => 200, :default => "",                            :null => false
    t.integer  "company_id",                                :default => 0,                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "admin",                                     :default => 0
    t.string   "time_zone"
    t.integer  "option_tracktime"
    t.integer  "seen_news_id",                              :default => 0
    t.integer  "last_project_id"
    t.datetime "last_seen_at"
    t.datetime "last_ping_at"
    t.integer  "last_milestone_id"
    t.integer  "last_filter"
    t.string   "date_format",                               :default => "%d/%m/%Y",                    :null => false
    t.string   "time_format",                               :default => "%H:%M",                       :null => false
    t.integer  "receive_notifications",                     :default => 1
    t.string   "uuid",                                                                                 :null => false
    t.integer  "seen_welcome",                              :default => 0
    t.string   "locale",                                    :default => "en_US"
    t.integer  "duration_format",                           :default => 0
    t.integer  "workday_duration",                          :default => 480
    t.integer  "newsletter",                                :default => 1
    t.integer  "option_avatars",                            :default => 1
    t.string   "autologin",                                                                            :null => false
    t.datetime "remember_until"
    t.boolean  "option_floating_chat",                      :default => true
    t.integer  "days_per_week",                             :default => 5
    t.boolean  "enable_sounds",                             :default => true
    t.boolean  "create_projects",                           :default => true
    t.boolean  "show_type_icons",                           :default => true
    t.boolean  "receive_own_notifications",                 :default => true
    t.boolean  "use_resources"
    t.integer  "customer_id"
    t.boolean  "active",                                    :default => true
    t.boolean  "read_clients",                              :default => false
    t.boolean  "create_clients",                            :default => false
    t.boolean  "edit_clients",                              :default => false
    t.boolean  "can_approve_work_logs"
    t.boolean  "auto_add_to_customer_tasks"
    t.integer  "access_level_id",                           :default => 1
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.boolean  "use_triggers",                              :default => false
    t.string   "encrypted_password",         :limit => 128, :default => "",                            :null => false
    t.string   "password_salt",                             :default => "",                            :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                             :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "working_hours",                             :default => "8.0|8.0|8.0|8.0|8.0|0.0|0.0", :null => false
    t.datetime "reset_password_sent_at"
  end

  add_index "users", ["autologin"], :name => "index_users_on_autologin"
  add_index "users", ["company_id"], :name => "users_company_id_index"
  add_index "users", ["customer_id"], :name => "index_users_on_customer_id"
  add_index "users", ["last_seen_at"], :name => "index_users_on_last_seen_at"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username", "company_id"], :name => "index_users_on_username_and_company_id", :unique => true
  add_index "users", ["uuid"], :name => "users_uuid_index"

  create_table "widgets", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.string   "name"
    t.integer  "widget_type", :default => 0
    t.integer  "number",      :default => 5
    t.boolean  "mine"
    t.string   "order_by"
    t.string   "group_by"
    t.string   "filter_by"
    t.boolean  "collapsed",   :default => false
    t.integer  "column",      :default => 0
    t.integer  "position",    :default => 0
    t.boolean  "configured",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "gadget_url"
  end

  add_index "widgets", ["company_id"], :name => "fk_widgets_company_id"
  add_index "widgets", ["user_id"], :name => "index_widgets_on_user_id"

  create_table "wiki_pages", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.datetime "locked_at"
    t.integer  "locked_by"
  end

  add_index "wiki_pages", ["company_id"], :name => "wiki_pages_company_id_index"

  create_table "wiki_references", :force => true do |t|
    t.integer  "wiki_page_id"
    t.string   "referenced_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wiki_references", ["wiki_page_id"], :name => "index_wiki_references_on_wiki_page_id"

  create_table "wiki_revisions", :force => true do |t|
    t.integer  "wiki_page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.integer  "user_id"
    t.string   "change"
  end

  add_index "wiki_revisions", ["user_id"], :name => "fk_wiki_revisions_user_id"
  add_index "wiki_revisions", ["wiki_page_id"], :name => "wiki_revisions_wiki_page_id_index"

  create_table "work_logs", :force => true do |t|
    t.integer  "user_id",          :default => 0
    t.integer  "task_id"
    t.integer  "project_id",       :default => 0, :null => false
    t.integer  "company_id",       :default => 0, :null => false
    t.integer  "customer_id",      :default => 0, :null => false
    t.datetime "started_at",                      :null => false
    t.integer  "duration",         :default => 0, :null => false
    t.text     "body"
    t.integer  "paused_duration",  :default => 0
    t.datetime "exported"
    t.integer  "status",           :default => 0
    t.integer  "access_level_id",  :default => 1
    t.integer  "email_address_id"
  end

  add_index "work_logs", ["company_id"], :name => "work_logs_company_id_index"
  add_index "work_logs", ["customer_id"], :name => "work_logs_customer_id_index"
  add_index "work_logs", ["project_id"], :name => "work_logs_project_id_index"
  add_index "work_logs", ["task_id", "started_at"], :name => "index_work_logs_on_task_id_and_started_at"
  add_index "work_logs", ["task_id"], :name => "work_logs_task_id_index"
  add_index "work_logs", ["user_id", "task_id"], :name => "work_logs_user_id_index"

end
