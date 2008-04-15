module Test::Spec::Rails
  class TestUrl < TestDummy

    def initialize(testcase)
      super(testcase)
      @params = @request.symbolized_path_parameters
      @path   = @request.path
    end

    def should_equal(wanted, defaults={}, extras={}, message=nil)
      if wanted.is_a?(Hash)
        assert_recognizes(wanted, @path, defaults, message)
      else
        assert_generates(wanted, @params, defaults, extras, message)
      end
    end
    alias :should_be :should_equal
    
    def to_s
      @path
    end

  end
end

