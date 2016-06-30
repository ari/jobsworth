class DeleteInProgress < ActiveRecord::Migration
  def self.up
     TaskRecord.all.each do |t|
      if t.status>0 then
        t.status-= 1
        #even if task not valid, we must change status
        t.save(false)
      end
    end
    Status.where(:name => 'in progress').each{|s| s.destroy}
  end

  def self.down
  end
end
