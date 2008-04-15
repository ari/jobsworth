module Test::Spec::Rails::ShouldRoute
  # Specify that a set of url options route to a path.
  # This translates directly to assert_generates 
  # Example:
  #     {:controller => "items", :action => "show", :id =>"1"}.should.route_to "/items/1"  
  # 
  # See also http://api.rubyonrails.org/classes/ActionController/Assertions/RoutingAssertions.html#M000367
  def route_to(options)
    assert_generates(options, @object)
  end

  # Specify that a path should be routable from a set of url options.
  # This translates directly to assert_recognizes 
  # Examples:
  #     {:path => "/items/1", :method => :get}.should.route_from :controller => "items", :action => "show", :id =>"1"
  #     {:path => "/items/1?print=true", :method => :get}.should.route_from({:controller => "items", :action => "show", :id =>"1"}, {:print => true})
  #
  # See also http://api.rubyonrails.org/classes/ActionController/Assertions/RoutingAssertions.html#M000366
  def route_from(options, extras={})
    assert_recognizes(options, @object, extras)
  end
  
  # Specify that a path should be routable from a set of url options and vice versa.
  # This translates directly to assert_routing 
  # Examples:
  #     "/items/1".should.route :controller => "items", :action => "show", :id =>"1"
  #
  # See also http://api.rubyonrails.org/classes/ActionController/Assertions/RoutingAssertions.html#M000368
  def route(options)
    assert_routing(@object, options)
  end
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldRoute)
