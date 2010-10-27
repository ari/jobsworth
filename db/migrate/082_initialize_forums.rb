class InitializeForums < ActiveRecord::Migration
  def self.up
    say_with_time "Creating global forums.." do
      Forum.new( :name => "General", :description => "Talk about whatever you want.", :description_html => "<p>Talk about whatever you want.</p>", :position => 0 ).save
      Forum.new( :name => "Support", :description => "Problems using ClockingIT?", :description_html => "<p>Promlems using ClockingIT?</p>", :position => 1 ).save
    end

    say_with_time "Creating company forums.." do
      Company.all.each{ |c|
        Forum.new( :name => c.name, :company_id => c.id, :position => 0).save
      }
    end

    say_with_time "Creating project forums.." do
      Project.all.each{ |p|
        Forum.new( :name => p.full_name, :project_id => p.id, :company_id => p.company_id, :position => 0).save
      }
    end

    add_index :forums, "company_id"

  end

  def self.down

    drop_index :forums, "company_id"

    Forum.all.each{  |f|
      f.destroy
    }
  end
end
