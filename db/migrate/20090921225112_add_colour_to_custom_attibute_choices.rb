class AddColourToCustomAttibuteChoices < ActiveRecord::Migration
  def self.up
    add_column :custom_attribute_choices, :color, :string
  end

  def self.down
    remove_column :custom_attribute_choices, :color
  end
end
