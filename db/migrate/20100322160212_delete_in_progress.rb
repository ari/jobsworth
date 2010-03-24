class DeleteInProgress < ActiveRecord::Migration
  def self.up
     Task.all.each do |t|
      if t.status>0 then
        t.status-= 1
        #even if task not valid, we must change status
        t.save(false)
      end
    end
    Status.find_all_by_name("in progress").each{|s| s.destroy}
    puts '='*80
    TaskFilter.all.each do |filter|
      filter.qualifiers.for("Status").each do |qualifier|
        unless filter.company.statuses.find_by_id(qualifier.qualifiable_id)
          puts "Filter #{filter.id} : change status qualifier from in progress to open"
          qualifier.qualifiable_id=filter.company.statuses.find_by_name("Open").id
          qualifier.save!
        end
      end
    end
  end

  def self.down
  end
end
