class ImportOldEvents < ActiveRecord::Migration
  def self.up
    say_with_time("Importing Wiki Pages..") do
      WikiPage.all.each do |page|
        created = false
        page.revisions.each do |rev|
          l = page.event_logs.new
          l.company_id = page.company_id
          l.project_id = page.project_id
          l.user_id = rev.user_id
          l.created_at = rev.created_at
          l.event_type = (created ? EventLog::WIKI_MODIFIED : EventLog::WIKI_CREATED)
          l.save
          created = true
        end
      end
    end

    say_with_time("Importing Project Files..") do
      ProjectFile.all.each do |file|
        l = file.event_logs.new
        l.company_id = file.company_id
        l.project_id = file.project_id
        l.user_id = file.user_id
        l.event_type = EventLog::FILE_UPLOADED
        l.created_at = file.created_at
        l.save
      end
    end

    say_with_time("Importing Forum Posts") do
      Post.all.each do |post|
        l = post.create_event_log
        l.company_id = post.company_id
        l.project_id = post.project_id
        l.user_id = post.user_id
        l.event_type = EventLog::FORUM_NEW_POST
        l.created_at = post.created_at
        l.save
      end
    end

  end

  def self.down
    execute("DELETE FROM event_logs WHERE event_type='Post'")
    execute("DELETE FROM event_logs WHERE event_type='ProjectFile'")
    execute("DELETE FROM event_logs WHERE event_type='WikiPage'")
  end
end
