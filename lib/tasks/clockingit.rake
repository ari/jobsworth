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
  desc "Show number of tasks broken by migration 'DeleteInProgress' "
  task :show_number_of_broken_tasks => :environment do
    Task.all.each_with_index do |task, index|
      unless task.valid?
        puts "="*80
        puts "Number of broken tasks:#{index}"
        puts "="*80
        break
      end
    end
  end
end

