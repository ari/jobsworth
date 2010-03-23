class DeleteInProgress < ActiveRecord::Migration
  def self.up
     Task.all.each do |t| 
      if t.status>0 then
        t.status-= 1
        t.save!
      end
    end
    Status.find_all_by_name("in progress").each{|s| s.destroy}
  end

  def self.down
  end
end
