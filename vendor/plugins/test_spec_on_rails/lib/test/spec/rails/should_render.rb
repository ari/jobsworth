module Test::Spec::Rails::ShouldRender
  # Test that something was rendered:
  #   request.should.render
  #
  # Test that a specific template was rendered:
  #   request.should.render 'foo'
  #
  # Test that a template was rendered with a specific response code:
  #   request.should.render 'foo', :error
  #
  def render(template = '', response = :success)
    @object.assert_response response
    @object.assert_template template unless template.blank?
  end
end

module Test::Spec::Rails::ShouldNotRender
  # Test that we didn't render
  def render(template = '', response = :success)
    @object.assert_response :redirect
  end
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldRender)
Test::Spec::ShouldNot.send(:include, Test::Spec::Rails::ShouldNotRender)
