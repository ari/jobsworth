module Test::Spec::Rails
  class TestTemplate < TestDummy

    def should_equal(template, message=nil)
      assert_template template, message
    end
    alias :should_be :should_equal
    
    def to_s
      @response.rendered_file
    end
    
  end
end
