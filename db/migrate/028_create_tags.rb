class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      # t.column :name, :string
      t.column :company_id, :integer
      t.column :name, :string
    end

    create_table( :task_tags, :id => false) do |t|
      t.column :tag_id, :integer
      t.column :task_id, :integer
    end

    Task.all.each do |t|
      unless t.component.nil?
	t.set_tags(t.component.tag_name)
	t.save
	print "#{t.name} => "
	t.tags.each do |tag|
	   print "#{tag.name},"
	end
	print "\n"
      end 
    end

    
  end

  def self.down
    drop_table :tags
    drop_table :task_tags
  end
end
