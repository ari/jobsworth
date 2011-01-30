class AddComponentsPosition < ActiveRecord::Migration
  def self.up
    add_column :components, :position, :integer

    @components = Component.all
    @components.each do | c |
      c.position = 0
      c.save
    end
  end

  def self.down
    remove_column :components, :position
  end
end
