class CustomAttribute < ActiveRecord::Base
  validates_presence_of :attributable_type
  validates_presence_of :display_name
  validates_presence_of :company_id

  belongs_to :company
  has_many :custom_attribute_values, :dependent => :destroy
  belongs_to :attributable, :polymorphic => true

  has_many :custom_attribute_choices, :dependent => :destroy
  accepts_nested_attributes_for(:custom_attribute_values, :allow_destroy => true)

  ###
  # Returns the attributes setup for the given type in company.
  ###
  def self.attributes_for(company, type)
    conds = { :attributable_type => type }
    return company.custom_attributes.find(:all, :order => "position", 
                                          :conditions => conds)
  end

  ###
  # Returns true if this attribute has a preset list of
  # possible choices
  ###
  def preset?
    custom_attribute_choices.any?
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
