class AddGeneratedReports < ActiveRecord::Migration
  def self.up
    create_table :generated_reports do |t|
      t.column :company_id, :integer
      t.column :user_id, :integer
      t.column :filename, :string
      t.column :report, :text
    end

  end

  def self.down
    drop_table :generated_reports
  end
end
