class Post < ActiveRecord::Base
  belongs_to :forum, :counter_cache => true
  belongs_to :user,  :counter_cache => true
  belongs_to :topic, :counter_cache => true
  has_one    :event_log, :as => :target, :dependent => :destroy

  acts_as_ferret :fields => ['company_id', 'project_id', 'body', 'forum_id']

  format_attribute :body

  before_create { |r| r.forum_id = r.topic.forum_id }

  after_create  { |r|
    Topic.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?', r.created_at, r.user_id, r.id], ['id = ?', r.topic_id])

    if r.id
      l = r.create_event_log
      l.company_id = r.company_id
      l.project_id = r.project_id
      l.user_id = r.user_id
      l.event_type = EventLog::FORUM_NEW_POST
      l.created_at = r.created_at
      l.save
    end

  }
  after_destroy { |r| t = Topic.find(r.topic_id) ; Topic.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?', t.posts.last.created_at, t.posts.last.user_id, t.posts.last.id], ['id = ?', t.id]) if t.posts.last }

  validates_presence_of :user_id, :body, :topic
  attr_accessible :body

  def editable_by?(user)
    user && (user.id == user_id || (user.admin? && topic.forum.company_id == user.company_id) || user.admin > 2 || user.moderator_of?(topic.forum_id))
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :topic_title << :forum_name
    super
  end

  def company_id
    self.forum.company_id
  end

  def project_id
    self.forum.project_id
  end

  def started_at
    self.created_at
  end
  
end
