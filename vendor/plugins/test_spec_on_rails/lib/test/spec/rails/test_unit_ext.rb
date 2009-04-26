class Test::Unit::TestCase
  def page #:nodoc:
    self
  end
  alias :response :page
  alias :request  :page
  alias :view     :page
  
  def output
    @response.body
  end
  alias :to_s  :output
  alias :body  :output
  alias :html  :output
  alias :xhtml :output
  
  def url
    Test::Spec::Rails::TestUrl.new(self)
  end
  
  def status
    Test::Spec::Rails::TestStatus.new(self)
  end
  
  def template
    Test::Spec::Rails::TestTemplate.new(self)
  end
  
  def layout
    Test::Spec::Rails::TestLayout.new(self)
  end  
end
