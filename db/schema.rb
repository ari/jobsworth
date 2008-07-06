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

ActiveRecord::Schema.define(:version => 125) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id",       :default => 0,  :null => false
    t.integer  "company_id",    :default => 0,  :null => false
    t.integer  "customer_id",   :default => 0,  :null => false
    t.integer  "project_id",    :default => 0,  :null => false
    t.integer  "activity_type", :default => 0,  :null => false
    t.string   "body",          :default => "", :null => false
    t.datetime "created_at",                    :null => false
  end

  create_table "chat_messages", :force => true do |t|
    t.integer  "chat_id"
    t.integer  "user_id"
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",   :default => false
  end

  add_index "chat_messages", ["chat_id", "created_at"], :name => "index_chat_messages_on_chat_id_and_created_at"

  create_table "chats", :force => true do |t|
    t.integer  "user_id"
    t.integer  "target_id"
    t.integer  "active",     :default => 1
    t.integer  "position",   :default => 0
    t.integer  "last_seen",  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "chats", ["user_id", "target_id"], :name => "index_chats_on_user_id_and_target_id"
  add_index "chats", ["user_id", "position"], :name => "index_chats_on_user_id_and_position"

  create_table "companies", :force => true do |t|
    t.string   "name",                :limit => 200, :default => "",    :null => false
    t.string   "contact_email",       :limit => 200
    t.string   "contact_name",        :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subdomain",                          :default => "",    :null => false
    t.boolean  "show_wiki",                          :default => true
    t.boolean  "show_forum",                         :default => true
    t.boolean  "show_chat",                          :default => true
    t.boolean  "show_messaging",                     :default => true
    t.boolean  "restricted_userlist",                :default => false
  end

  add_index "companies", ["subdomain"], :name => "companies_subdomain_index", :unique => true

  create_table "customers", :force => true do |t|
    t.integer  "company_id",                   :default => 0,  :null => false
    t.string   "name",          :limit => 200, :default => "", :null => false
    t.string   "contact_email", :limit => 200
    t.string   "contact_name",  :limit => 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "css"
    t.integer  "binary_id"
  end

  add_index "customers", ["company_id", "name"], :name => "customers_company_id_index"

  create_table "dependencies", :id => false, :force => true do |t|
    t.integer "task_id"
    t.integer "dependency_id"
  end

  add_index "dependencies", ["task_id"], :name => "dependencies_task_id_index"
  add_index "dependencies", ["dependency_id"], :name => "dependencies_dependency_id_index"

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

  add_index "event_logs", ["company_id", "project_id"], :name => "index_event_logs_on_company_id_and_project_id"
  add_index "event_logs", ["target_id", "target_type"], :name => "index_event_logs_on_target_id_and_target_type"

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

  add_index "forums", ["company_id"], :name => "index_forums_on_company_id"

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

  add_index "ical_entries", ["task_id"], :name => "index_ical_entries_on_task_id"
  add_index "ical_entries", ["work_log_id"], :name => "index_ical_entries_on_work_log_id"

  create_table "locales", :force => true do |t|
    t.string   "locale"
    t.string   "key"
    t.text     "singular"
    t.text     "plural"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "same",       :default => false
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
  end

  add_index "milestones", ["company_id"], :name => "milestones_company_id_index"
  add_index "milestones", ["project_id"], :name => "milestones_project_id_index"
  add_index "milestones", ["company_id", "project_id"], :name => "milestones_company_project_index"

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monitorships", :force => true do |t|
    t.integer "monitorship_id"
    t.integer "user_id"
    t.boolean "active",           :default => true
    t.string  "monitorship_type"
  end

  add_index "monitorships", ["user_id"], :name => "index_monitorships_on_user_id"

  create_table "news_items", :force => true do |t|
    t.datetime "created_at"
    t.text     "body"
    t.boolean  "portal",     :default => true
  end

  create_table "notifications", :force => true do |t|
    t.integer "task_id"
    t.integer "user_id"
  end

  add_index "notifications", ["user_id"], :name => "index_notifications_on_user_id"
  add_index "notifications", ["task_id"], :name => "index_notifications_on_task_id"

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

  add_index "pages", ["company_id"], :name => "pages_company_id_index"

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id"
    t.text     "body_html"
  end

  add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"
  add_index "posts", ["topic_id"], :name => "index_posts_on_topic_id"

  create_table "project_files", :force => true do |t|
    t.integer  "company_id",                       :default => 0,                          :null => false
    t.integer  "project_id",                       :default => 0,                          :null => false
    t.integer  "customer_id",                      :default => 0,                          :null => false
    t.string   "name",              :limit => 200, :default => "",                         :null => false
    t.integer  "binary_id",                        :default => 0,                          :null => false
    t.integer  "file_type",                        :default => 0,                          :null => false
    t.datetime "created_at",                                                               :null => false
    t.datetime "updated_at",                                                               :null => false
    t.string   "filename",          :limit => 200, :default => "",                         :null => false
    t.integer  "thumbnail_id"
    t.integer  "file_size"
    t.integer  "task_id"
    t.string   "mime_type",                        :default => "application/octet-stream"
    t.integer  "project_folder_id"
    t.integer  "user_id"
  end

  add_index "project_files", ["company_id"], :name => "project_files_company_id_index"
  add_index "project_files", ["project_folder_id"], :name => "index_project_files_on_project_folder_id"
  add_index "project_files", ["task_id"], :name => "index_project_files_on_task_id"

  create_table "project_folders", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.integer  "company_id"
  end

  add_index "project_folders", ["project_id"], :name => "index_project_folders_on_project_id"
  add_index "project_folders", ["parent_id"], :name => "index_project_folders_on_parent_id"

  create_table "project_permissions", :force => true do |t|
    t.integer  "company_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.boolean  "can_comment",    :default => false
    t.boolean  "can_work",       :default => false
    t.boolean  "can_report",     :default => false
    t.boolean  "can_create",     :default => false
    t.boolean  "can_edit",       :default => false
    t.boolean  "can_reassign",   :default => false
    t.boolean  "can_prioritize", :default => false
    t.boolean  "can_close",      :default => false
    t.boolean  "can_grant",      :default => false
    t.boolean  "can_milestone",  :default => false
  end

  add_index "project_permissions", ["project_id"], :name => "project_permissions_project_id_index"
  add_index "project_permissions", ["user_id"], :name => "project_permissions_user_id_index"

  create_table "projects", :force => true do |t|
    t.string   "name",           :limit => 200, :default => "",   :null => false
    t.integer  "user_id",                       :default => 0,    :null => false
    t.integer  "company_id",                    :default => 0,    :null => false
    t.integer  "customer_id",                   :default => 0,    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "critical_count",                :default => 0
    t.integer  "normal_count",                  :default => 0
    t.integer  "low_count",                     :default => 0
    t.text     "description"
    t.boolean  "create_forum",                  :default => true
  end

  add_index "projects", ["company_id"], :name => "projects_company_id_index"
  add_index "projects", ["customer_id"], :name => "projects_customer_id_index"

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

  add_index "scm_changesets", ["commit_date"], :name => "scm_changesets_commit_date_index"
  add_index "scm_changesets", ["author"], :name => "scm_changesets_author_index"

  create_table "scm_files", :force => true do |t|
    t.integer  "project_id"
    t.integer  "company_id"
    t.text     "name"
    t.text     "path"
    t.string   "state"
    t.datetime "commit_date"
  end

  add_index "scm_files", ["project_id"], :name => "scm_files_project_id_index"

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

  add_index "scm_revisions", ["scm_changeset_id"], :name => "scm_revisions_scm_changeset_id_index"
  add_index "scm_revisions", ["scm_file_id"], :name => "scm_revisions_scm_file_id_index"

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

  create_table "shout_channel_subscriptions", :force => true do |t|
    t.integer "shout_channel_id"
    t.integer "user_id"
  end

  add_index "shout_channel_subscriptions", ["shout_channel_id"], :name => "index_shout_channel_subscriptions_on_shout_channel_id"
  add_index "shout_channel_subscriptions", ["user_id"], :name => "index_shout_channel_subscriptions_on_user_id"

  create_table "shout_channels", :force => true do |t|
    t.integer "company_id"
    t.integer "project_id"
    t.string  "name"
    t.text    "description"
    t.integer "public"
  end

  add_index "shout_channels", ["company_id"], :name => "index_shout_channels_on_company_id"

  create_table "shouts", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.text     "body"
    t.integer  "shout_channel_id"
    t.integer  "message_type",     :default => 0
    t.string   "nick"
  end

  add_index "shouts", ["created_at"], :name => "shouts_created_at_index"
  add_index "shouts", ["company_id"], :name => "shouts_company_id_index"
  add_index "shouts", ["shout_channel_id"], :name => "index_shouts_on_shout_channel_id"

  create_table "tags", :force => true do |t|
    t.integer "company_id"
    t.string  "name"
  end

  add_index "tags", ["company_id", "name"], :name => "index_tags_on_company_id_and_name"

  create_table "task_owners", :force => true do |t|
    t.integer "user_id"
    t.integer "task_id"
  end

  add_index "task_owners", ["user_id"], :name => "task_owners_user_id_index"
  add_index "task_owners", ["task_id"], :name => "task_owners_task_id_index"

  create_table "task_tags", :id => false, :force => true do |t|
    t.integer "tag_id"
    t.integer "task_id"
  end

  add_index "task_tags", ["tag_id"], :name => "task_tags_tag_id_index"
  add_index "task_tags", ["task_id"], :name => "task_tags_task_id_index"

  create_table "tasks", :force => true do |t|
    t.string   "name",               :limit => 200, :default => "",    :null => false
    t.integer  "project_id",                        :default => 0,     :null => false
    t.integer  "position",                          :default => 0,     :null => false
    t.datetime "created_at",                                           :null => false
    t.datetime "due_at"
    t.datetime "updated_at",                                           :null => false
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
    t.boolean  "scheduled",                         :default => false
  end

  add_index "tasks", ["project_id", "milestone_id"], :name => "tasks_project_id_index"
  add_index "tasks", ["company_id"], :name => "tasks_company_id_index"
  add_index "tasks", ["project_id", "completed_at"], :name => "tasks_project_completed_index"
  add_index "tasks", ["milestone_id"], :name => "index_tasks_on_milestone_id"
  add_index "tasks", ["due_at"], :name => "tasks_due_at_idx"

  create_table "todos", :force => true do |t|
    t.integer  "task_id"
    t.string   "name"
    t.integer  "position"
    t.integer  "creator_id"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "todos", ["task_id"], :name => "index_todos_on_task_id"

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
    t.boolean  "locked",       :default => false
    t.integer  "replied_by"
    t.integer  "last_post_id"
  end

  add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"
  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"

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
    t.boolean  "option_floating_chat",                  :default => true
    t.integer  "days_per_week",                         :default => 5
    t.boolean  "enable_sounds",                         :default => true
  end

  add_index "users", ["uuid"], :name => "users_uuid_index"
  add_index "users", ["username"], :name => "users_username_index"
  add_index "users", ["company_id"], :name => "users_company_id_index"
  add_index "users", ["last_seen_at"], :name => "index_users_on_last_seen_at"
  add_index "users", ["autologin"], :name => "index_users_on_autologin"

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

  add_index "views", ["company_id"], :name => "views_company_id_index"

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

  add_index "wiki_revisions", ["wiki_page_id"], :name => "wiki_revisions_wiki_page_id_index"

  create_table "work_logs", :force => true do |t|
    t.integer  "user_id",          :default => 0,     :null => false
    t.integer  "task_id"
    t.integer  "project_id",       :default => 0,     :null => false
    t.integer  "company_id",       :default => 0,     :null => false
    t.integer  "customer_id",      :default => 0,     :null => false
    t.datetime "started_at",                          :null => false
    t.integer  "duration",         :default => 0,     :null => false
    t.text     "body"
    t.integer  "log_type",         :default => 0
    t.integer  "scm_changeset_id"
    t.integer  "paused_duration",  :default => 0
    t.boolean  "comment",          :default => false
  end

  add_index "work_logs", ["user_id", "task_id"], :name => "work_logs_user_id_index"
  add_index "work_logs", ["task_id", "log_type"], :name => "work_logs_task_id_index"
  add_index "work_logs", ["company_id"], :name => "work_logs_company_id_index"
  add_index "work_logs", ["project_id"], :name => "work_logs_project_id_index"
  add_index "work_logs", ["customer_id"], :name => "work_logs_customer_id_index"

end
