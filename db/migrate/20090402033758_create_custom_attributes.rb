class CreateCustomAttributes < ActiveRecord::Migration
  def self.up
    create_table :custom_attributes do |t|
      t.integer :company_id
      t.string :attributable_type
      t.string :display_name
      t.string :ldap_attribute_type
      t.boolean :mandatory
      t.boolean :multiple
      t.integer :max_length
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_attributes
  end
end
