class ChangeReportColumnInGeneratedReportsToLongtext < ActiveRecord::Migration
  def up
    change_column :generated_reports, :report, :text, :limit => 4.gigabytes - 1
  end

  def down
    change_column :generated_reports, :report, :text, :limit => 64.kilobytes - 1
  end
end
