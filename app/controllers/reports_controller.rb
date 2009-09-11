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

  def get_projects
    if params[:client_id].to_i == 0
      @projects = (current_user.projects.find(:all, :order => 'name').collect {|p| "{\"text\":\"#{(p.name + " / " + p.customer.name).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" } +
        current_user.completed_projects.find(:all, :order => 'name').collect {|p| "{\"text\":\"#{(p.name + " / " + p.customer.name + " - " + _('Completed')).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" }).join(',')
    else
      @projects = (current_user.projects.find(:all, :order => 'name' , :conditions => ["projects.customer_id = ?", params[:client_id] ]).collect {|p| "{\"text\":\"#{p.name.gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" } +
                   current_user.completed_projects.find(:all, :order => 'name' , :conditions => ["projects.customer_id = ?", params[:client_id] ]).collect {|p| "{\"text\":\"#{(p.name + " - " + _('Completed')).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" }
                   ).join(',')
    end

    res = '{"options":[{"value":"0", "text":"' + _('[Active Projects]') + '"},{"value":"-1", "text":"' + _('[Any Project]') + '"},{"value":"-2", "text":"' + _('[Closed Projects]') + '"}'

    res << ", #{@projects}" unless @projects.nil? || @projects.empty?
    res << ']}'
    render :text => res
  end

end
