module Test::Spec::Rails
  class TestStatus < TestDummy

    def should_equal(status, message=nil)
      assert_response status, message
    end
    alias :should_be :should_equal
    
    def to_s
      @response.response_code.to_s
    end

  end
end

