class SetProjectDefaultEstimate < ActiveRecord::Migration
  def up
    Project.all.each do |p|
      next if p.default_estimate and p.default_estimate > 0
      p.default_estimate = 1.0
      p.save
    end
  end

  def down
  end
end
