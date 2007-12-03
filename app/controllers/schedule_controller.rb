# Generate a calendar showing completed and due Tasks for a Company
# TODO: Simple Events
class ScheduleController < ApplicationController

  def list

    today = Time.now.to_date

    @year = params[:year] unless params[:year].nil?
    @month = params[:month] unless params[:month].nil?

    @year ||= today.year
    @month ||= today.month


    # Find all tasks for the current month, should probably be adjusted to use
    # TimeZone for current User instead of UTC.
    @tasks = Task.find(:all, :order => 'tasks.duration desc, tasks.name', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.company_id = '#{current_user.company_id}' AND ((tasks.due_at is NOT NULL AND tasks.due_at > '#{@year}-#{@month}-01 00:00:00' AND tasks.due_at < '#{@year}-#{@month}-31 23:59:59') OR (tasks.completed_at is NOT NULL AND tasks.completed_at > '#{@year}-#{@month}-01 00:00:00' AND tasks.completed_at < '#{@year}-#{@month}-31 23:59:59'))", ], :include => [:milestone] )
    @milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    @dates = {}

    # Mark milestones
    @milestones.each do |m|
      unless m.due_at.nil?
        @dates[tz.utc_to_local(m.due_at).to_date] ||= []
        @dates[tz.utc_to_local(m.due_at).to_date] << m
      end
    end

    # Mark all tasks
    @tasks.each do |t|
      due_date = tz.utc_to_local(t.due_at).to_date unless t.due_at.nil?
      due_date ||= tz.utc_to_local(t.completed_at).to_date unless t.completed_at.nil?


      @dates[due_date] ||= []

      duration = t.duration

      days = (duration / (60*8)) - 1

      days = 0 if days < 0

      found = false
      slot = 0
      until found
        found = true

        done = days
        d = -1

        while done >= 0
          d += 1
          next if ((due_date - d).wday == 0 || (due_date - d).wday == 6) && !(due_date.wday == 0 || due_date.wday == 6)
          #            logger.info "Checking #{due_date-d} for slot #{slot}"
          unless @dates[due_date - d].nil? || @dates[due_date - d][slot].nil?
              found = false
            #              logger.info "Conflict.."
          end
          done -= 1
        end
        slot += 1 unless found
      end

      while days >= 0
        days -= 1
        @dates[due_date] ||= []
        @dates[due_date][slot] = t
        due_date -= 1
        due_date -= 1 if due_date.wday == 6
        due_date -= 2 if due_date.wday == 0
      end

    end

  end

  # New event
  def new
  end

  # Edit event
  def edit
  end

  # Create event
  def create
  end

  # Update event
  def update
  end

  # Delte event
  def delete
  end

  # Refresh calendar on Event addition / task completion
  def refresh
  end
end
