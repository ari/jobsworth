class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= exception_table_name %>", :force => true do |t|
      t.column :exception_class, :string
      t.column :controller_name, :string
      t.column :action_name,     :string
      t.column :message,         :string
      t.column :backtrace,       :text
      t.column :environment,     :text
      t.column :request,         :text
      t.column :created_at,      :datetime
    end
  end

  def self.down
    drop_table "<%= exception_table_name %>"
  end
end
