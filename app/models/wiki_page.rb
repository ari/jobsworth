class WikiPage < ActiveRecord::Base
  has_many :revisions, :class_name => 'WikiRevision', :order => 'id'
  has_one  :current_revision, :class_name => 'WikiRevision', :order => 'id DESC'
  belongs_to :company

  LOCKING_PERIOD = 30.minutes

  def lock(time, locked_by)
    update_attributes(:locked_at => time, :locked_by => locked_by)
  end

  def lock_duration(time)
    ((time - locked_at) / 60).to_i unless locked_at.nil?
  end

  def unlock
    update_attribute(:locked_at, nil)
  end

  def locked?(comparison_time)
    locked_at + LOCKING_PERIOD > comparison_time unless locked_at.nil?
  end

  def continous_revision?(time, author)
    (current_revision.author == author) && (revised_at + 30.minutes > time)
  end

  def to_html
    body = current_revision.body

    RedCloth.new(body).to_html
  end

end
