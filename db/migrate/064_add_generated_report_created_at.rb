class AddGeneratedReportCreatedAt < ActiveRecord::Migration
  def self.up
    add_column :generated_reports, :created_at, :timestamp
  end

  def self.down
    remove_column :generated_reports, :created_at
  end
end
