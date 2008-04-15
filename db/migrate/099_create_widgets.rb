class CreateWidgets < ActiveRecord::Migration
  def self.up
    create_table :widgets do |t|
      t.integer  :company_id
      t.integer  :user_id
      t.string   :name
      t.integer  :widget_type
      t.integer  :number
      t.string   :order_by
      t.string   :group_by
      t.string   :filter_by
      t.boolean  :collapsed
      t.integer  :column
      t.integer  :position

      t.timestamps
    end

    add_index :widgets, :company_id
    add_index :widgets, :user_id
  end

  def self.down
    drop_table :widgets
  end
end
