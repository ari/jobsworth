require "fastercsv"
# Massage the WorkLogs in different ways, saving reports for later access
# as well as CSV downloading.
#
class ReportsController < ApplicationController
  def list
    sql_filter = ""
    date_filter = ""

    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids})
    @users = User.find(:all, :order => 'name', :conditions => ['users.company_id = ?', current_user.company_id], :joins => "INNER JOIN project_permissions ON project_permissions.user_id = users.id")
    
    if options = params[:report]
      report = WorklogReport.new(self, options)
      start_date = report.start_date
      end_date = report.end_date
      @type = report.type

      @logs = report.work_logs
      @range = report.range

      @column_headers = report.column_headers
      @column_totals = report.column_totals
      @rows = report.rows
      @row_totals = report.row_totals
      @total = report.total
      @generated_report = report.generated_report
    end

    if @generated_report.nil?
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
