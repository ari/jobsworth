module Test::Spec::Rails::ShouldRedirect
  # Test that we were redirected somewhere:
  #   request.should.redirect
  #
  # Test that we were redirected to a specific url:
  #   request.should.redirect :controller => 'foo', :action => 'bar'
  # or:
  #   request.should.be.redirected foo_url(@foo)
  #
  def redirect(options = {})
    if options.empty?
      @object.assert_response :redirect
    else
      @object.assert_redirected_to options
    end
  end
  alias :redirect_to   :redirect
  alias :redirected    :redirect
  alias :redirected_to :redirect
end

module Test::Spec::Rails::ShouldNotRedirect
  # Test that we weren't redirected
  def redirect(options = {})
    @object.assert_response :success # FIXME
  end
  alias :redirect_to   :redirect
  alias :redirected    :redirect
  alias :redirected_to :redirect
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldRedirect)
Test::Spec::ShouldNot.send(:include, Test::Spec::Rails::ShouldNotRedirect)
