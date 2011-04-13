# encoding: UTF-8
# Discussion forums for a company.
#
# Can be public across all registered users, private to a company, 
# or private to a project

class Forum < ActiveRecord::Base

  belongs_to :company
  belongs_to :project

  acts_as_list :scope => :company_id

  validates_presence_of :name

  has_many :moderatorships, :dependent => :destroy
  has_many :moderators, :through => :moderatorships, :source => :user, :order => 'users.name'

  has_many :monitorships, :as => :monitorship, :dependent => :destroy
  has_many :monitors, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :source => :user, :order => 'users.last_sign_in_at'
  has_many :topics, :order => 'sticky desc, replied_at desc', :dependent => :destroy 

  # this is used to see if a forum is "fresh"... we can't use topics because it puts
  # stickies first even if they are not the most recently modified
  has_many :recent_topics, :class_name => 'Topic', :order => 'replied_at desc' 

  has_many :posts, :order => 'posts.created_at desc' do
    def last
      @last_post ||= includes(:user).first
    end
  end

  format_attribute :description
end



# == Schema Information
#
# Table name: forums
#
#  id               :integer(4)      not null, primary key
#  company_id       :integer(4)
#  project_id       :integer(4)
#  name             :string(255)
#  description      :string(255)
#  topics_count     :integer(4)      default(0)
#  posts_count      :integer(4)      default(0)
#  position         :integer(4)
#  description_html :text
#

