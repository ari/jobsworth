# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 130) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id",       :default => 0,                     :null => false
    t.integer  "company_id",    :default => 0,                     :null => false
    t.integer  "customer_id",   :default => 0,                     :null => false
    t.integer  "project_id",    :default => 0,                     :null => false
    t.integer  "activity_type", :default => 0,                     :null => false
    t.string   "body",          :default => "",                    :null => false
    t.datetime "created_at",    :default => '1970-01-01 00:00:00', :null => false
  end

  create_table "chat_messages", :force => true do |t|
    t.integer  "chat_id"
    t.integer  "user_id"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "archived"
  end

  add_index "chat_messages", ["chat_id", "created_at"], :name => "chat_messages_1_idx"

  create_table "chats", :force => true do |t|
    t.integer  "user_id"
    t.integer  "target_id"
    t.integer  "active",     :default => 1
    t.integer  "position",   :default => 0
    t.integer  "last_seen",  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "chats", ["user_id", "target_id"], :name => "chats_1_idx"

  create_table "companies", :force => true do |t|
    t.string   "name",                :limit => 200, :default => "", :null => false
    t.string   "contact_email",       :limit => 200
    t.string   "contact_name",        :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subdomain",                          :default => "", :null => false
    t.integer  "show_wiki"
    t.integer  "show_forum"
    t.integer  "show_chat"
    t.integer  "show_messaging"
    t.integer  "restricted_userlist"
  end

  add_index "companies", ["subdomain"], :name => "companies_subdomain_key", :unique => true

  create_table "customers", :force => true do |t|
    t.integer  "company_id",                   :default => 0,  :null => false
    t.string   "name",          :limit => 200, :default => "", :null => false
    t.string   "contact_email", :limit => 200
    t.string   "contact_name",  :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "css"
    t.integer  "bytea_id"
  end

  add_index "customers", ["company_id", "name"], :name => "customers_1_idx"

  create_table "dependencies", :id => false, :force => true do |t|
    t.integer "task_id"
    t.integer "dependency_id"
  end

  add_index "dependencies", ["task_id", "dependency_id"], :name => "dependencies_1_idx"
  add_index "dependencies", ["task_id", "dependency_id"], :name => "dependencies_2_idx"

  create_table "emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.string   "subject"
    t.text     "body"
    t.integer  "company_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  add_index "event_logs", ["company_id", "project_id"], :name => "event_logs_1_idx"

  create_table "forums", :force => true do |t|
    t.integer "company_id"
    t.integer "project_id"
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",     :default => 0
    t.integer "posts_count",      :default => 0
    t.integer "position"
    t.text    "description_html"
  end

  add_index "forums", ["company_id"], :name => "forums_company_id_idx"

  create_table "generated_reports", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.string   "filename"
    t.text     "report"
    t.datetime "created_at"
  end

  create_table "ical_entries", :force => true do |t|
    t.integer "task_id"
    t.integer "work_log_id"
    t.text    "body"
  end

  add_index "ical_entries", ["task_id"], :name => "ical_entries_task_id_idx"
  add_index "ical_entries", ["work_log_id"], :name => "ical_entries_work_log_id_idx"

  create_table "locales", :force => true do |t|
    t.string   "locale"
    t.string   "key"
    t.text     "singular"
    t.text     "plural"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "same"
  end

  add_index "locales", ["locale", "key"], :name => "locales_locale_key", :unique => true

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
    t.integer  "scheduled"
  end

  add_index "milestones", ["company_id", "project_id"], :name => "milestones_1_idx"
  add_index "milestones", ["company_id"], :name => "milestones_company_id_idx"
  add_index "milestones", ["project_id"], :name => "milestones_project_id_idx"

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "moderatorships_forum_id_idx"

  create_table "monitorships", :force => true do |t|
    t.integer "monitorship_id"
    t.integer "user_id"
    t.integer "active"
    t.string  "monitorship_type"
  end

  add_index "monitorships", ["user_id"], :name => "monitorships_user_id_idx"

  create_table "news_items", :force => true do |t|
    t.datetime "created_at"
    t.text     "body"
    t.integer  "portal"
  end

  create_table "notifications", :force => true do |t|
    t.integer "task_id"
    t.integer "user_id"
  end

  add_index "notifications", ["task_id", "user_id"], :name => "notifications_1_idx"

  create_table "pages", :force => true do |t|
    t.string   "name",       :limit => 200, :default => "", :null => false
    t.text     "body"
    t.integer  "company_id",                :default => 0,  :null => false
    t.integer  "user_id",                   :default => 0,  :null => false
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  add_index "pages", ["name", "company_id", "updated_at"], :name => "pages_1_idx"
  add_index "pages", ["company_id"], :name => "pages_company_id_idx"

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id"
    t.text     "body_html"
  end

  add_index "posts", ["created_at", "forum_id"], :name => "posts_1_idx"
  add_index "posts", ["user_id", "forum_id"], :name => "posts_2_idx"
  add_index "posts", ["topic_id"], :name => "posts_topic_id_idx"

  create_table "project_files", :force => true do |t|
    t.integer  "company_id",                       :default => 0,                          :null => false
    t.integer  "project_id",                       :default => 0,                          :null => false
    t.integer  "customer_id",                      :default => 0,                          :null => false
    t.string   "name",              :limit => 200, :default => "",                         :null => false
    t.integer  "bytea_id",                         :default => 0,                          :null => false
    t.integer  "file_type",                        :default => 0,                          :null => false
    t.datetime "created_at",                       :default => '1970-01-01 00:00:00',      :null => false
    t.datetime "updated_at",                       :default => '1970-01-01 00:00:00',      :null => false
    t.string   "filename",          :limit => 200, :default => "",                         :null => false
    t.integer  "thumbnail_id"
    t.integer  "file_size"
    t.integer  "task_id"
    t.string   "mime_type",                        :default => "application/octet-stream"
    t.integer  "project_folder_id"
    t.integer  "user_id"
  end

  add_index "project_files", ["company_id"], :name => "project_files_company_id_idx"
  add_index "project_files", ["project_folder_id"], :name => "project_files_project_folder_id_idx"
  add_index "project_files", ["task_id"], :name => "project_files_task_id_idx"

  create_table "project_folders", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.integer  "company_id"
  end

  add_index "project_folders", ["parent_id"], :name => "project_folders_parent_id_idx"
  add_index "project_folders", ["project_id"], :name => "project_folders_project_id_idx"

  create_table "project_permissions", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.integer  "can_comment"
    t.integer  "can_work"
    t.integer  "can_report"
    t.integer  "can_create"
    t.integer  "can_edit"
    t.integer  "can_reassign"
    t.integer  "can_prioritize"
    t.integer  "can_close"
    t.integer  "can_grant"
    t.integer  "can_milestone"
  end

  add_index "project_permissions", ["project_id", "user_id"], :name => "project_permissions_1_idx"
  add_index "project_permissions", ["user_id"], :name => "project_permissions_user_id_idx"

  create_table "projects", :force => true do |t|
    t.string   "name",           :limit => 200, :default => "", :null => false
    t.integer  "user_id",                       :default => 0,  :null => false
    t.integer  "company_id",                    :default => 0,  :null => false
    t.integer  "customer_id",                   :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "critical_count",                :default => 0
    t.integer  "normal_count",                  :default => 0
    t.integer  "low_count",                     :default => 0
    t.text     "description"
    t.integer  "create_forum"
  end

  add_index "projects", ["name", "customer_id", "completed_at"], :name => "projects_1_idx"
  add_index "projects", ["company_id"], :name => "projects_company_id_idx"
  add_index "projects", ["customer_id"], :name => "projects_customer_id_idx"

  create_table "schema_migrations", :primary_key => "version", :force => true do |t|
  end

  add_index "schema_migrations", ["version"], :name => "unique_schema_migrations", :unique => true

  create_table "scm_changesets", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "scm_project_id"
    t.string   "author"
    t.integer  "changeset_num"
    t.datetime "commit_date"
    t.string   "changeset_rev"
    t.text     "message"
  end

  add_index "scm_changesets", ["author"], :name => "scm_changesets_author_idx"
  add_index "scm_changesets", ["commit_date"], :name => "scm_changesets_commit_date_idx"

  create_table "scm_files", :force => true do |t|
    t.integer  "project_id"
    t.integer  "company_id"
    t.text     "name"
    t.text     "path"
    t.string   "state"
    t.datetime "commit_date"
  end

  add_index "scm_files", ["project_id"], :name => "scm_files_project_id_idx"

  create_table "scm_projects", :force => true do |t|
    t.integer  "project_id"
    t.integer  "company_id"
    t.string   "scm_type"
    t.datetime "last_commit_date"
    t.datetime "last_update"
    t.datetime "last_checkout"
    t.text     "module"
    t.text     "location"
  end

  create_table "scm_revisions", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "scm_changeset_id"
    t.integer  "scm_file_id"
    t.string   "revision"
    t.string   "author"
    t.datetime "commit_date"
    t.string   "state"
  end

  add_index "scm_revisions", ["scm_changeset_id"], :name => "scm_revisions_scm_changeset_id_idx"
  add_index "scm_revisions", ["scm_file_id"], :name => "scm_revisions_scm_file_id_idx"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :limit => 32
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_idx", :unique => true
  add_index "sessions", ["updated_at"], :name => "sessions_updated_at_idx"

  create_table "sheets", :force => true do |t|
    t.integer  "user_id",         :default => 0, :null => false
    t.integer  "task_id",         :default => 0, :null => false
    t.integer  "project_id",      :default => 0, :null => false
    t.datetime "created_at"
    t.text     "body"
    t.datetime "paused_at"
    t.integer  "paused_duration", :default => 0
  end

  add_index "sheets", ["task_id"], :name => "sheets_task_id_idx"
  add_index "sheets", ["user_id"], :name => "sheets_user_id_idx"

  create_table "shout_channel_subscriptions", :force => true do |t|
    t.integer "shout_channel_id"
    t.integer "user_id"
  end

  add_index "shout_channel_subscriptions", ["shout_channel_id", "user_id"], :name => "shout_channel_subscriptions_shout_channel_id_idx"
  add_index "shout_channel_subscriptions", ["user_id"], :name => "shout_channel_subscriptions_user_id_idx"

  create_table "shout_channels", :force => true do |t|
    t.integer "company_id"
    t.integer "project_id"
    t.string  "name"
    t.text    "description"
    t.integer "public"
  end

  add_index "shout_channels", ["company_id"], :name => "shout_channels_company_id_idx"

  create_table "shouts", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.text     "body"
    t.integer  "shout_channel_id"
    t.integer  "message_type",     :default => 0
    t.string   "nick"
  end

  add_index "shouts", ["company_id"], :name => "shouts_company_id_idx"
  add_index "shouts", ["created_at"], :name => "shouts_created_at_idx"
  add_index "shouts", ["shout_channel_id"], :name => "shouts_shout_channel_id_idx"

  create_table "tags", :force => true do |t|
    t.integer "company_id"
    t.string  "name"
  end

  add_index "tags", ["company_id", "name"], :name => "tags_1_idx"

  create_table "task_owners", :force => true do |t|
    t.integer "user_id"
    t.integer "task_id"
  end

  add_index "task_owners", ["user_id", "task_id"], :name => "task_owners_1_idx"
  add_index "task_owners", ["user_id", "task_id"], :name => "task_owners_2_idx"

  create_table "task_tags", :id => false, :force => true do |t|
    t.integer "tag_id"
    t.integer "task_id"
  end

  add_index "task_tags", ["tag_id", "task_id"], :name => "task_tags_1_idx"
  add_index "task_tags", ["tag_id", "task_id"], :name => "task_tags_task_id_idx"

  create_table "tasks", :force => true do |t|
    t.string   "name",               :limit => 200, :default => "",                    :null => false
    t.integer  "project_id",                        :default => 0,                     :null => false
    t.integer  "position",                          :default => 0,                     :null => false
    t.datetime "created_at",                        :default => '1970-01-01 00:00:00', :null => false
    t.datetime "due_at"
    t.datetime "updated_at",                        :default => '1970-01-01 00:00:00', :null => false
    t.datetime "completed_at"
    t.integer  "duration",                          :default => 1
    t.integer  "hidden",                            :default => 0
    t.integer  "milestone_id"
    t.text     "description"
    t.integer  "company_id"
    t.integer  "priority",                          :default => 0
    t.integer  "updated_by_id"
    t.integer  "severity_id",                       :default => 0
    t.integer  "type_id",                           :default => 0
    t.integer  "task_num",                          :default => 0
    t.integer  "status",                            :default => 0
    t.string   "requested_by"
    t.integer  "creator_id"
    t.string   "notify_emails"
    t.string   "repeat"
    t.datetime "hide_until"
    t.datetime "scheduled_at"
    t.integer  "scheduled_duration"
    t.integer  "scheduled"
    t.integer  "worked_minutes",                    :default => 0
  end

  add_index "tasks", ["project_id", "milestone_id"], :name => "tasks_1_idx"
  add_index "tasks", ["company_id"], :name => "tasks_company_id_idx"
  add_index "tasks", ["project_id", "hidden", "milestone_id", "company_id", "type_id", "status"], :name => "tasks_company_id_project_id_idx"
  add_index "tasks", ["due_at"], :name => "tasks_due_at_idx"
  add_index "tasks", ["milestone_id"], :name => "tasks_milestone_id_idx"

  create_table "todos", :force => true do |t|
    t.integer  "task_id"
    t.string   "name"
    t.integer  "position"
    t.integer  "creator_id"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "todos", ["task_id"], :name => "todos_task_id_idx"

  create_table "topics", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hits",         :default => 0
    t.integer  "sticky",       :default => 0
    t.integer  "posts_count",  :default => 0
    t.datetime "replied_at"
    t.integer  "locked"
    t.integer  "replied_by"
    t.integer  "last_post_id"
  end

  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "topics_1_idx"
  add_index "topics", ["forum_id"], :name => "topics_forum_id_idx"

  create_table "users", :force => true do |t|
    t.string   "name",                   :limit => 200, :default => "",      :null => false
    t.string   "username",               :limit => 200, :default => "",      :null => false
    t.string   "password",               :limit => 200, :default => "",      :null => false
    t.integer  "company_id",                            :default => 0,       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  :limit => 200
    t.datetime "last_login_at"
    t.integer  "admin",                                 :default => 0
    t.string   "time_zone"
    t.integer  "option_tracktime"
    t.integer  "option_externalclients"
    t.integer  "option_tooltips"
    t.integer  "seen_news_id",                          :default => 0
    t.integer  "last_project_id"
    t.datetime "last_seen_at"
    t.datetime "last_ping_at"
    t.integer  "last_milestone_id"
    t.integer  "last_filter"
    t.string   "date_format"
    t.string   "time_format"
    t.integer  "send_notifications",                    :default => 1
    t.integer  "receive_notifications",                 :default => 1
    t.string   "uuid"
    t.integer  "seen_welcome",                          :default => 0
    t.string   "locale",                                :default => "en_US"
    t.integer  "duration_format",                       :default => 0
    t.integer  "workday_duration",                      :default => 480
    t.integer  "posts_count",                           :default => 0
    t.integer  "newsletter",                            :default => 1
    t.integer  "option_avatars",                        :default => 1
    t.string   "autologin"
    t.datetime "remember_until"
    t.integer  "option_floating_chat"
    t.integer  "days_per_week",                         :default => 5
    t.integer  "enable_sounds"
    t.boolean  "create_projects",                       :default => true
    t.boolean  "show_type_icons",                       :default => true
  end

  add_index "users", ["name", "company_id"], :name => "users_1_idx"
  add_index "users", ["autologin"], :name => "users_autologin_idx"
  add_index "users", ["last_seen_at"], :name => "users_last_seen_at_idx"
  add_index "users", ["username"], :name => "users_username_idx"
  add_index "users", ["uuid"], :name => "users_uuid_idx"

  create_table "views", :force => true do |t|
    t.string  "name"
    t.integer "company_id"
    t.integer "user_id"
    t.integer "shared",              :default => 0
    t.integer "auto_group",          :default => 0
    t.integer "filter_customer_id",  :default => 0
    t.integer "filter_project_id",   :default => 0
    t.integer "filter_milestone_id", :default => 0
    t.integer "filter_user_id",      :default => 0
    t.string  "filter_tags",         :default => ""
    t.integer "filter_status",       :default => 0
    t.integer "filter_type_id",      :default => 0
    t.integer "hide_dependencies"
    t.integer "sort",                :default => 0
  end

  add_index "views", ["name", "company_id", "shared"], :name => "views_1_idx"
  add_index "views", ["company_id"], :name => "views_company_id_idx"

  create_table "widgets", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.string   "name"
    t.integer  "widget_type", :default => 0
    t.integer  "number",      :default => 5
    t.integer  "mine"
    t.string   "order_by"
    t.string   "group_by"
    t.string   "filter_by"
    t.integer  "collapsed"
    t.integer  "column",      :default => 0
    t.integer  "position",    :default => 0
    t.integer  "configured"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "gadget_url"
  end

  add_index "widgets", ["user_id", "column", "position"], :name => "widgets_1_idx"
  add_index "widgets", ["user_id"], :name => "widgets_user_id_idx"

  create_table "wiki_pages", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.datetime "locked_at"
    t.integer  "locked_by"
  end

  add_index "wiki_pages", ["company_id"], :name => "wiki_pages_company_id_idx"

  create_table "wiki_references", :force => true do |t|
    t.integer  "wiki_page_id"
    t.string   "referenced_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wiki_references", ["wiki_page_id"], :name => "wiki_references_wiki_page_id_idx"

  create_table "wiki_revisions", :force => true do |t|
    t.integer  "wiki_page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.integer  "user_id"
    t.string   "change"
  end

  add_index "wiki_revisions", ["wiki_page_id"], :name => "wiki_revisions_wiki_page_id_idx"

  create_table "work_logs", :force => true do |t|
    t.integer  "user_id",          :default => 0,                     :null => false
    t.integer  "task_id"
    t.integer  "project_id",       :default => 0,                     :null => false
    t.integer  "company_id",       :default => 0,                     :null => false
    t.integer  "customer_id",      :default => 0,                     :null => false
    t.datetime "started_at",       :default => '1970-01-01 00:00:00', :null => false
    t.integer  "duration",         :default => 0,                     :null => false
    t.text     "body"
    t.integer  "log_type",         :default => 0
    t.integer  "scm_changeset_id"
    t.integer  "paused_duration",  :default => 0
    t.integer  "comment"
  end

  add_index "work_logs", ["user_id", "task_id"], :name => "work_logs_1_idx"
  add_index "work_logs", ["company_id"], :name => "work_logs_company_id_idx"
  add_index "work_logs", ["customer_id"], :name => "work_logs_customer_id_idx"
  add_index "work_logs", ["task_id", "project_id", "duration"], :name => "work_logs_project_id_task_id_duration_idx"
  add_index "work_logs", ["task_id", "project_id"], :name => "work_logs_project_id_task_id_index"
  add_index "work_logs", ["task_id", "project_id", "duration", "log_type"], :name => "work_logs_project_id_task_id_log_type_duration_idx"
  add_index "work_logs", ["task_id", "started_at"], :name => "work_logs_task_id_created_at"
  add_index "work_logs", ["user_id", "started_at"], :name => "work_logs_user_id_started_at_idx"

end
