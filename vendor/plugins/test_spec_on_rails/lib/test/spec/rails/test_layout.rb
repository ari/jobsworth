module Test::Spec::Rails
  class TestLayout < TestDummy

    def should_equal(expected, message=nil)
      layout = @response.layout.gsub(/layouts\//, '') if @response.layout
      assert_equal expected, layout, message
    end
    alias :should_be :should_equal
    
    def to_s
      @response.rendered_file
    end
    
  end
end
