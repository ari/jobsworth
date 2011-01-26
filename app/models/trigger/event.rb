# encoding: UTF-8
class Trigger::Event
  CREATED= 1
  UPDATED= 2

  attr_accessor :id, :name
  def initialize(params={ })
    self.id=params[:id]
    self.name=params[:name]
  end

  def self.all
    @@instances ||= [self.new(:id=>1, :name=>"Task created"), self.new(:id=>2, :name=>"Task updated")]
  end

  def self.find(id)
    self.all.detect{|event| event.id == id }
  end
end
