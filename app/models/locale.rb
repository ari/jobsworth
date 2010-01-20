# Translations of strings used in ClockingIT

class Locale < ActiveRecord::Base
  belongs_to :user
end

# == Schema Information
#
# Table name: locales
#
#  id         :integer(4)      not null, primary key
#  locale     :string(6)
#  key        :string(255)
#  singular   :text
#  plural     :text
#  user_id    :integer(4)
#  created_at :datetime
#  updated_at :datetime
#  same       :boolean(1)      default(FALSE)
#

