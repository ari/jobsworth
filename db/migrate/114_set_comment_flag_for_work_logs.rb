class SetCommentFlagForWorkLogs < ActiveRecord::Migration
  def self.up
    logs = WorkLog.all
    logs.each do |l|
      next if l.body.nil? || l.body.length == 0
      if /<strong>/.match(l.body)
        if /<br\/>/.match(l.body)
          l.comment = true
        end 
      else 
        l.comment = true
      end
      l.save
    end
  end

  def self.down
  end
end
