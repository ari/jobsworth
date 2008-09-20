module Test::Spec::Rails::ShouldRender
  # Test that something was rendered:
  #   request.should.render
  #
  # Test that a specific template was rendered:
  #   request.should.render 'foo'
  #
  def render(template = '')
    @object.assert_response :success
    @object.assert_template template unless template.blank?
  end
end

module Test::Spec::Rails::ShouldNotRender
  # Test that we didn't render
  def redirect(template = '')
    @object.assert_response :redirect # TODO: fix me
  end
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldRender)
Test::Spec::ShouldNot.send(:include, Test::Spec::Rails::ShouldNotRender)
