# encoding: UTF-8
class Trigger::ActionFactory
  attr_accessor :id, :name, :class_name

  def initialize(id=nil, name=nil, class_name=nil)
    self.id = id
    self.name = name
    self.class_name = class_name
  end

  def self.all
    @@instances ||= [self.new(1, "Reassign task to user", "Trigger::ReassignTask"),
                     self.new(2, "Send email", "Trigger::SendEmail"),
                     self.new(3, "Set due date", "Trigger::SetDueDate")]
  end

  def self.find(id)
    self.all.detect{|action| action.id == id.to_i }
  end

  def self.find_by_name(name)
    self.all.detect{|action| action.name == name}
  end
  def build(params={ })
    eval(self.class_name).new(params)
  end
end
