# encoding: UTF-8
###
# Properties are used to describe tasks. Each property has a number of
# PropertyValues which define the values available for the user to choose
# from.
#
# Properties can be created and edited by users in the system and so can
# have any PropertyValues a user needs.

# Examples of potential properties include Priority, Status, Sub-project
# - anything that suits a company's workflow..
###
class Property < ActiveRecord::Base
  belongs_to :company
  has_many :property_values, :order => "position asc, id asc", :dependent => :destroy

  after_save :clear_other_default_colors
  after_save :update_project_counts
  before_destroy :remove_invalid_task_property_values

  # Returns an array of the default values that should be
  # used when creating a new company.
  def self.defaults
    res = []
    res << [ { :name => _("Type") },
             [ { :value => _("Task"),        :icon_url => "task.png", :default => true },
               { :value => _("New Feature"), :icon_url => "new_feature.png" },
               { :value => _("Defect"),      :icon_url => "bug.png" },
               { :value => _("Improvement"), :icon_url => "change.png" }
             ]]
    res << [ { :name => _("Priority"), :default_sort => true, :default_color => true },
             [ { :value => _("Critical"), :color => "#FF6666" },
               { :value => _("Urgent"),   :color => "#FF6666" },
               { :value => _("High"),     :color => "#F2AB99" },
               { :value => _("Normal"),   :color => "#B0D295", :default => true },
               { :value => _("Low"),      :color => "#F3F3F3" },
               { :value => _("Lowest"),   :color => "#F3F3F3" }
             ]]
    res << [ { :name => _("Severity"), :default_sort => true },
             [ { :value => _("Blocker") },
               { :value => _("Critical") },
               { :value => _("Major") },
               { :value => _("Normal"), :default => true },
               { :value => _("Minor") },
               { :value => _("Trivial") }
             ]]

    return res
  end

  ###
  # Returns an array of all properties for company which
  # have colors set up for their property values.
  ###
  def self.all_with_colors(company)
    props = company.properties.select do |p|
      p.property_values.detect { |pv| !pv.color.blank? }
    end

    return props
  end

  ###
  # Returns an array of all properties for company which
  # have icons set up for their property values.
  ###
  def self.all_with_icons(company)
    props = company.properties.select do |p|
      p.has_icons?
    end

    return props
  end

  ###
  # Finds the property matching the given filter_name
  ###
  def self.find_by_filter_name(company, filter_name)
    return if !filter_name

    match = filter_name.match(/property_(\d+)/)
    return company.properties.find(match[1]) if match
  end

  # Returns true if the values for this property have icons
  # set up
  def has_icons?
    property_values.detect { |pv| pv.icon_url.present? }
  end

  ###
  # Returns a name suitable for use as a div id or similar.
  ###
  def filter_name
    @filter_name ||= "property_#{ id }"
  end

  ###
  # Returns the first property value set as default, or nil if none.
  ###
  def default_value
    property_values.detect { |pv| pv.default }
  end

  def to_s
    name
  end

  ###
  # Clears any tasks which have a value for this
  # property set.
  ###
  def remove_invalid_task_property_values
    tpvs = TaskPropertyValue.where({:property_id => id })
    tpvs.each { |tpv| tpv.destroy }
  end

  ###
  # Only one property can be used to color tasks, so this
  # method will ensure only one property will have the
  # default_colors attribute set.
  ###
  def clear_other_default_colors
    if self.default_color
      other_properties = company.properties - [ self ]
      other_properties.each do |p|
        if p.default_color
          p.default_color = false
          p.save
        end
      end
    end
  end

  ###
  # Update critical, low and normal counts on this companys projects.
  # If we've change the sort defaults, these counts may change, so
  # we need to update them on save.
  ###
  def update_project_counts
    company.projects.each do |p|
      p.update_project_stats
      p.save
    end
  end
end






# == Schema Information
#
# Table name: properties
#
#  id            :integer(4)      not null, primary key
#  company_id    :integer(4)
#  name          :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  default_sort  :boolean(1)
#  default_color :boolean(1)
#  mandatory     :boolean(1)      default(FALSE)
#
# Indexes
#
#  index_properties_on_company_id  (company_id)
#

