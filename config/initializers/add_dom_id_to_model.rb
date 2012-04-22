ActiveRecord::Base.class_eval do
  include ActionView::Helpers::TagHelper, ActionView::Helpers::TextHelper

  def dom_id
    [self.class.name.downcase.pluralize.dasherize, id] * '-'
  end
end
