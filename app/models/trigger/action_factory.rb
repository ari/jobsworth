# encoding: UTF-8
class Trigger::ActionFactory
  attr_accessor :id, :name, :class_name

  def initialize(id=nil, name=nil, class_name=nil)
    self.id = id
    self.name = name
    self.class_name = class_name
  end

  def self.all
    @@instances ||= [self.new(1, "Reassign task to user", "RessignTask"),
                     self.new(2, "Send email", "SendEmail"),
                     self.new(3, "Set due date", "SetDueDate")]
  end

  def self.find(id)
    self.all.detect{|action| action.id == id }
  end

  def self.find_by_name(name)
    self.all.detect{|action| action.name == name}
  end
end
