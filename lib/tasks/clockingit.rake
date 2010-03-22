namespace :clockingit do

  desc "Move task in progress to open"
  task :move_task_in_progress_to_open => :environment do
    Task.all.each do |t| 
      if t.status>0 then
        t.status-= 1
        t.save!
      end
    end
    Status.find_all_by_name("in progress").each{|s| s.destroy}
  end
end

