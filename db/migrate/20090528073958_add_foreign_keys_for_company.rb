require "migration_helpers"

class AddForeignKeysForCompany < ActiveRecord::Migration 
  extend MigrationHelpers
  
  TABLES = {
    :companies => [
                   :activities, :custom_attributes, :customers, :emails, :event_logs,
                   :forums, :generated_reports, :milestones, :pages, :project_files,
                   :project_permissions, :projects, :properties, :resource_types,
                   :resources, :scm_changesets, :scm_files, :scm_projects, :scm_revisions,
                   :shout_channels, :shouts, :tags, :users, :views, :widgets, :work_logs, 
                   :wiki_pages 
                  ],
    :users => [ 
               :activities, :chat_messages, :chats, :emails, :event_logs, :generated_reports,
               :milestones, :moderatorships, :monitorships, :notifications, 
               :pages, :posts, :project_files, :project_permissions, :projects,
               :scm_changesets, :scm_revisions, :sheets, :shout_channel_subscriptions,
               :shouts, :task_owners, :topics, :views, :widgets, :wiki_revisions,
               :work_logs, :work_logs_notifications
              ],
    :tasks => [ 
               :dependencies, :ical_entries, :notifications, :resources_tasks,
               :sheets, :task_owners, :task_property_values, :task_tags, :todos,
               :work_logs 
              ]
  }

  def self.up
    TABLES.each do |reference_name, tables|
      column_name = reference_name.to_s.singularize.foreign_key

      tables.each do |table| 
        begin
          foreign_key(table, column_name, reference_name)
        rescue
          puts "ERROR"
          puts $!
        end
      end
    end
  end

  def self.down
    TABLES.each do |reference_name, tables|
      column_name = reference_name.to_s.singularize.foreign_key
      tables.each do |table| 
        begin
          remove_foreign_key(table, column_name, reference_name) 
        rescue
          puts $!
        end
      end
    end
  end
end
