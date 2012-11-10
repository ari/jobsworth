class FixDuplicateTemplateTaskNum < ActiveRecord::Migration
  def up
    query = "SELECT task_num, COUNT(task_num) FROM tasks GROUP BY task_num HAVING ( COUNT(task_num) > 1 )"
    result = ActiveRecord::Base.connection.execute(query)
    result.each do |arr|
      task_num = arr[0]
      count = arr[1]

      puts "WARNING: #{count} tasks have the same task_num #{task_num}"

      while AbstractTask.where(:task_num => task_num).count > 1
        # try to change template task_num first
        task = Template.where(:task_num => task_num).first || AbstractTask.where(:task_num => task_num).first
        max = AbstractTask.maximum(:task_num)
        task.update_column(:task_num, max + 1)

        puts "Fix: change task #{task.name} number from #{task_num} to #{max + 1}"
      end
    end
  end

  def down
  end
end
