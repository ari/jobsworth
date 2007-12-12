namespace :ferret do

  desc "Rebuild all Indexes"
  task :rebuild_all_indexes => [:environment] do
    ["Task", "WorkLog", "Shout", "Post", "WikiPage"].each { |s| s.constantize.rebuild_index }
  end
end

