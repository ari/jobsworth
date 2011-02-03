class ChangeDueTasklistcolPreference < ActiveRecord::Migration
  def self.up
    User.all.each{|user|
      begin
        tasklistcols=user.preference('tasklistcols')
        next if tasklistcols.blank?
        columns=JSON.parse(tasklistcols)
        due= columns.detect{ |col| col["name"] == "due" }
        unless due.nil?
          due.delete("sorttype")
          due.delete("formatter")
          due["label"]= "target date"
          user.preference_attributes = [ [ 'tasklistcols', columns.to_json ] ]
        end
      rescue Exception=> e
        p e
      end
    }
  end

  def self.down
  end
end
