class MakeTagNameUniqueWithinACompany < ActiveRecord::Migration

  # need to update task_tags table, could use ActiveRecord helpers.
  class TaskTag < ActiveRecord::Base; end

  def up
    Tag.transaction do
      Tag.all.each { |tag|
        duplicate_tags = Tag.where(:company_id => tag.company_id, :name => tag.name).reject { |t| t.id == tag.id }
        if duplicate_tags.present?
          TaskTag.where(:tag_id => tag.id).update_all :tag_id => duplicate_tags.first.id
          raise "Tasks exist for tag \##{tag.id}" if tag.tasks(true).any? # sanity check
          puts "Destroying tag \##{tag.id}"
          tag.destroy
        end
      }
    end
    remove_index :tags, [:company_id, :name]
    add_index :tags, [:company_id, :name], :unique => true
  end

  def down
    remove_index :tags, [:company_id, :name]
    add_index :tags, [:company_id, :name]
  end
end
