class CreateKeywords < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :keywords do |t|
      t.integer :company_id
      t.integer :task_filter_id
      t.string :word

      t.timestamps
    end

    foreign_key(:keywords, :task_filter_id, :task_filters)
  end

  def self.down
    drop_table :keywords
  end
end
