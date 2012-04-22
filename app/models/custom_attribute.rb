# encoding: UTF-8
class CustomAttribute < ActiveRecord::Base
  validates_presence_of :attributable_type
  validates_presence_of :display_name
  validates_presence_of :company_id

  belongs_to :company
  has_many :custom_attribute_values, :dependent => :destroy
  belongs_to :attributable, :polymorphic => true

  has_many :custom_attribute_choices, :order => "position asc", :dependent => :destroy
  accepts_nested_attributes_for(:custom_attribute_choices, :allow_destroy => true)

  scope :by_type, lambda { |type| where(attributable_type: type) }

  ###
  # Returns the attributes setup for the given type in company.
  ###
  def self.attributes_for(company, type)
    conds = { :attributable_type => type }
    return company.custom_attributes.order("position").where(conds)
  end

  ###
  # Returns true if this attribute has a preset list of
  # possible choices
  ###
  def preset?
    custom_attribute_choices.any?
  end

  ###
  # Updates the custom_choice_attributes association based on 
  # the given params.
  # Any choices not included in the params will be deleted.
  ###
  def choice_attributes=(params)
    return if params.nil?
    choices = custom_attribute_choices.clone

    updated = []

    # need to sort to ensure new attributes are created at end of list
    params = params.sort_by { |id, attrs| id.to_i }

    params.each do |id, attrs|
      choice = choices.detect { |ca| ca.id == id.to_i }
      if choice.nil?
        # create a new one
        choice = custom_attribute_choices.build(attrs)
      end

      updated << choice
      choice.update_attributes(attrs)
    end

    missing = choices - updated
    missing.each { |c| c.destroy }
  end

  ###
  # Returns the preset choices for this custom attribute, 
  # one per line.
  ###
  def choices_as_text
    values = custom_attribute_choices.map { |c| c.value }
    values.join("\n")
  end

  ###
  # Sets the choices for this custom attribute from the given string.
  # str should have one choice per line.
  ###
  def choices_as_text=(str)
    choice_values = str.split("\n").map { |s| s.strip }
    choice_values = choice_values.compact.uniq

    if choice_values.any?
      custom_attribute_choices.clear

      choice_values.each_with_index do |val, i|
        custom_attribute_choices.build(:value => val, :position => i)
      end
    end
  end
end






# == Schema Information
#
# Table name: custom_attributes
#
#  id                  :integer(4)      not null, primary key
#  company_id          :integer(4)
#  attributable_type   :string(255)
#  display_name        :string(255)
#  ldap_attribute_type :string(255)
#  mandatory           :boolean(1)
#  multiple            :boolean(1)
#  max_length          :integer(4)
#  position            :integer(4)
#  created_at          :datetime
#  updated_at          :datetime
#
# Indexes
#
#  index_custom_attributes_on_company_id_and_attributable_type  (company_id,attributable_type)
#

