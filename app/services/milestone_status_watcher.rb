class MilestoneStatusWatcher

  def self.update_status
    Rails.logger.tagged('SCHEDULER TEST') do |logger|
      logger.error 'Service is working.'
      logger.error "#{Milestone.must_started_today.count} milestones are waiting update."
      Milestone.must_started_today.update_all(status: Milestone::STATUSES.index(:open))
      logger.error "#{Milestone.must_started_today.count} milestones are not updated."
    end
  end

end
