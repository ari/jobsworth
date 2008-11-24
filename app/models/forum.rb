# Discussion forums for a company.
#
# Can be public across all registered users, private to a company, 
# or private to a project

class Forum < ActiveRecord::Base

  belongs_to :company
  belongs_to :project

  acts_as_list :scope => 'company_id'

  validates_presence_of :name

  has_many :moderatorships, :dependent => :destroy
  has_many :moderators, :through => :moderatorships, :source => :user, :order => 'users.name'

  has_many :monitorships, :as => :monitorship, :dependent => :destroy
  has_many :monitors, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :source => :user, :order => 'users.last_login_at'

  has_many :topics, :order => 'sticky desc, replied_at desc', :dependent => :destroy do
    def first
      @first_topic ||= find(:first)
    end
  end

  # this is used to see if a forum is "fresh"... we can't use topics because it puts
  # stickies first even if they are not the most recently modified
  has_many :recent_topics, :class_name => 'Topic', :order => 'replied_at desc' do
    def first
      @first_recent_topic ||= find(:first)
    end
  end

  has_many :posts, :order => 'posts.created_at desc' do
    def last
      @last_post ||= find(:first, :include => :user)
    end
  end

  format_attribute :description
end
