module Scorable
  def self.included(class_name)
    # Creates a score_rules association on the class
    # represented by 'class_name'
    class_name.class_eval do
      has_many  :score_rules, :as => :controlled_by, :dependent => :destroy
    end 
  end
end
