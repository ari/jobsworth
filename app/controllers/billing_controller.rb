# encoding: UTF-8
require "csv"

# Massage the WorkLogs in different ways, saving reports for later access
# as well as CSV downloading.
#
class BillingController < ApplicationController
  def index
    sql_filter = ""
    date_filter = ""

    @tags = Tag.top_counts(current_user.company)
    @users = User.order('name').where('users.company_id = ?', current_user.company_id).joins("INNER JOIN project_permissions ON project_permissions.user_id = users.id")
    @custom_attributes = current_user.company.custom_attributes.by_type("WorkLog")

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
      flash[:alert] = _("Empty report, log more work!") if params[:report]
    end
  end

  def get_csv
    @report = GeneratedReport.where("user_id = ? AND company_id = ?", current_user.id, current_user.company_id).find(params[:id])
    if @report
      send_data(@report.report,
                :type => 'text/csv; charset=utf-8; header=present',
                :filename => @report.filename)
    else
      redirect_to :index
    end
  end
end
