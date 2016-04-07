class MilestoneStatusWatcher

  def self.update_status
    Milestone.must_started_today.update_all(status: Milestone::STATUSES.index(:open))
  end

end
