class Topic < ActiveRecord::Base
  belongs_to :forum, :counter_cache => true
  belongs_to :user
  has_many :monitorships
  has_many :monitors, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :source => :user, :order => 'users.login'

  has_many :posts, :order => 'posts.created_at', :dependent => :destroy do
    def last
      @last_post ||= find(:first, :order => 'posts.created_at desc')
    end
  end

  belongs_to :replied_by_user, :foreign_key => "replied_by", :class_name => "User"
  
  validates_presence_of :forum, :user, :title
  before_create :set_default_replied_at_and_sticky
  before_save   :check_for_changing_forums

  attr_accessible :title
  # to help with the create form
  attr_accessor :body

  def check_for_changing_forums
    return if new_record?
    old=Topic.find(id)
    if old.forum_id!=forum_id
      set_post_forum_id
      Forum.update_all ["posts_count = posts_count - ?", posts_count], ["id = ?", old.forum_id]
      Forum.update_all ["posts_count = posts_count + ?", posts_count], ["id = ?", forum_id]
    end
  end

  def voice_count
    posts.count(:select => "DISTINCT user_id")
  end
  
  def voices
    # TODO - optimize
    posts.map { |p| p.user }.uniq
  end
  
  def hit!
    self.class.increment_counter :hits, id
  end

  def sticky?() sticky == 1 end

  def views() hits end

  def paged?() posts_count > 25 end
  
  def last_page
    (posts_count.to_f / 25.0).ceil.to_i
  end

  def editable_by?(user)
    user && (user.id == user_id || user.admin? || user.moderator_of?(forum_id))
  end
  
  protected
    def set_default_replied_at_and_sticky
      self.replied_at = Time.now.utc
      self.sticky   ||= 0
    end

    def set_post_forum_id
      Post.update_all ['forum_id = ?', forum_id], ['topic_id = ?', id]
    end
end
