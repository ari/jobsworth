# encoding: UTF-8
# Stand-alone Page (called Note inside the application) with information a user frequently
# needs.

class Page < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  belongs_to :notable, :polymorphic => true
  has_one    :event_log, :as => :target

  validates_presence_of :name
  validate :validate_presence_of_notable

  scope :projects, where("notable_type = 'Project'")
  scope :snippets, where("snippet = ?", true)

  after_create { |page| page.setup_event_log( EventLog::PAGE_CREATED, "- #{page.name} Created") }
  
  before_update do |page|
    body= page.changes.has_key?('name') ? "- #{page.changes['name'][0]} -> #{page.changes['name'][1]}\n" : ""
    body+= "- #{page.name} Modified\n" if page.changes.has_key?('body')
    page.setup_event_log(EventLog::PAGE_MODIFIED, body)
  end

  before_destroy { |page| page.setup_event_log(EventLog::PAGE_DELETED,  "-#{page.name} Deleted") }

  def setup_event_log(type, body)
    log = create_event_log
    log.user = user
    log.title= "Page"
    log.company = company
    log.project_id = notable_id if notable_type == "Project"
    log.event_type=type
    log.body=body
    log.save!
  end

  protected

  def validate_presence_of_notable
    if notable.nil?
      errors.add(:base, "Target required")
    end
  end
end







# == Schema Information
#
# Table name: pages
#
#  id           :integer(4)      not null, primary key
#  name         :string(200)     default(""), not null
#  body         :text
#  company_id   :integer(4)      default(0), not null
#  user_id      :integer(4)      default(0), not null
#  created_at   :datetime
#  updated_at   :datetime
#  position     :integer(4)
#  notable_id   :integer(4)
#  notable_type :string(255)
#  snippet      :boolean(1)      default(FALSE)
#
# Indexes
#
#  pages_company_id_index                      (company_id)
#  index_pages_on_notable_id_and_notable_type  (notable_id,notable_type)
#  fk_pages_user_id                            (user_id)
#

