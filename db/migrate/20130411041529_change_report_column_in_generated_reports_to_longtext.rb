class ChangeReportColumnInGeneratedReportsToLongtext < ActiveRecord::Migration
  def up
    change_column :generated_reports, :report, :text,
      :limit => Proc.new { ActiveRecord::Base.connection.adapter_name == 'MySQL' ? (4.gigabytes -1) : (1.gigabyte - 1) }.call
  end

  def down
    change_column :generated_reports, :report, :text, :limit => 64.kilobytes - 1
  end
end
