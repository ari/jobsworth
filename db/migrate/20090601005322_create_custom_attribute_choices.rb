class CreateCustomAttributeChoices < ActiveRecord::Migration
  def self.up
    create_table :custom_attribute_choices do |t|
      t.integer :custom_attribute_id
      t.string :value
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_attribute_choices
  end
end
