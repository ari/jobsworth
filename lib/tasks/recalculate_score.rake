namespace :jobsworth do
  desc 'Recalculates the score for all the open tasks'
  task :rescore => :environment do
    puts "Recalculating the score of all open tasks"
    Task.open_only.each do |task|
      task.save(:validate => false)  
    end
    puts "Done."
  end
end
