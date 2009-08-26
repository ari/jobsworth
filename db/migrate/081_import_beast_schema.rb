class ImportBeastSchema < ActiveRecord::Migration
  def self.up
    create_table "forums", :force => true do |t|
      t.column "company_id",       :integer
      t.column "project_id",       :integer
      t.column "name",             :string
      t.column "description",      :string
      t.column "topics_count",     :integer, :default => 0
      t.column "posts_count",      :integer, :default => 0
      t.column "position",         :integer
      t.column "description_html", :text
    end

    create_table "logged_exceptions", :force => true do |t|
      t.column "exception_class", :string
      t.column "controller_name", :string
      t.column "action_name",     :string
      t.column "message",         :string
      t.column "backtrace",       :text
      t.column "environment",     :text
      t.column "request",         :text
      t.column "created_at",      :datetime
    end

    create_table "moderatorships", :force => true do |t|
      t.column "forum_id", :integer
      t.column "user_id",  :integer
    end

    add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

    create_table "monitorships", :force => true do |t|
      t.column "topic_id", :integer
      t.column "user_id",  :integer
      t.column "active",   :boolean, :default => true
    end

    create_table "posts", :force => true do |t|
      t.column "user_id",    :integer
      t.column "topic_id",   :integer
      t.column "body",       :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "forum_id",   :integer
      t.column "body_html",  :text
    end

    add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
    add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

    create_table "topics", :force => true do |t|
      t.column "forum_id",     :integer
      t.column "user_id",      :integer
      t.column "title",        :string
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "hits",         :integer,  :default => 0
      t.column "sticky",       :integer,  :default => 0
      t.column "posts_count",  :integer,  :default => 0
      t.column "replied_at",   :datetime
      t.column "locked",       :boolean,  :default => false
      t.column "replied_by",   :integer
      t.column "last_post_id", :integer
    end

    add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"
    add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
    add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"


    add_column :users,  "posts_count",          :integer,  :default => 0

    add_index "users", "last_seen_at", :name => "index_users_on_last_seen_at"
  end

  def self.down
    drop_index  :users, "last_seen_at"
    remove_column :users, "posts_count"

    drop_table    :topics
    drop_table    :posts
    drop_table    :monitorships
    drop_table    :moderatorships
    drop_table    :logged_exceptions
    drop_table    :forums
  end
end
