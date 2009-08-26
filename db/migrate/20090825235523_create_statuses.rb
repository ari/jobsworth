class CreateStatuses < ActiveRecord::Migration
  def self.up
    create_table :statuses do |t|
      t.integer :company_id
      t.string :name

      t.timestamps
    end

    Company.all.each do |company|
      Status.create_default_statuses(company)
    end
  end

  def self.down
    drop_table :statuses
  end
end
