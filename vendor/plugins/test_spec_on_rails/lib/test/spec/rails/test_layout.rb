module Test::Spec::Rails
  class TestLayout < TestDummy

    def should_equal(expected, message=nil)
      layout = @response.layout.gsub(/layouts\//, '')
      assert_equal layout, expected, message
    end
    alias :should_be :should_equal
    
    def to_s
      @response.rendered_file
    end
    
  end
end
