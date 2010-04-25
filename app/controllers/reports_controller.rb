if RUBY_VERSION < "1.9"
  require "fastercsv"
else
  require "csv"
end

# Massage the WorkLogs in different ways, saving reports for later access
# as well as CSV downloading.
#
class ReportsController < ApplicationController
  def list
    sql_filter = ""
    date_filter = ""

    @tags = Tag.top_counts(current_user.company)
    @users = User.find(:all, :order => 'name', :conditions => ['users.company_id = ?', current_user.company_id], :joins => "INNER JOIN project_permissions ON project_permissions.user_id = users.id")

    if options = params[:report]
      @worklog_report = WorklogReport.new(self, options)

      @column_headers = @worklog_report.column_headers
      @column_totals = @worklog_report.column_totals
      @rows = @worklog_report.rows
      @row_totals = @worklog_report.row_totals
      @total = @worklog_report.total
      @generated_report = @worklog_report.generated_report
    end

    if @column_headers.nil? or @column_headers.length <= 1
      flash['notice'] = _("Empty report, log more work!") if params[:report]
    end
  end

  def get_csv
    @report = GeneratedReport.find(params[:id], :conditions => ["user_id = ? AND company_id = ?", current_user.id, current_user.company_id])
    if @report
      send_data(@report.report,
                :type => 'text/csv; charset=utf-8; header=present',
                :filename => @report.filename)
    else
      redirect_to :action => 'list'
    end
  end
end
