class DeleteInProgressFromFilters < ActiveRecord::Migration
  def self.up
    puts "Change all broken qualifiers for status to 'Open' status and remove duplicates"
    TaskFilter.all.each do |filter|
      open_status = filter.company.statuses.find_by_name("Open")
      filter.qualifiers.for("Status").each do |qualifier|
        unless filter.company.statuses.find_by_id(qualifier.qualifiable_id)
          puts "Filter #{filter.id} : change status qualifier from in progress to open"
          qualifier.qualifiable_id= open_status.id
          qualifier.save!
        end
      end
      h=Hash.new(0)
      filter.qualifiers.for("Status").each do |qualifier|
        h[qualifier.qualifiable_id] +=1
        if h[qualifier.qualifiable_id]>1
          puts "Filter #{filter.id}: Remove duplicated qualifier #{qualifier.id} for status"
          TaskFilterQualifier.delete qualifier
        end
      end
    end
  end

  def self.down
  end
end
