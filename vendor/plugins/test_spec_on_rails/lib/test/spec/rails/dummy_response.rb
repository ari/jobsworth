module Test::Spec::Rails
  class DummyResponse < TestDummy

    attr_reader :body, :headers

    def initialize(body, headers=nil)
      if headers.nil?
        response = body.instance_variable_get('@response')
        @body, @headers = response.body, response.headers
      else
        @body, @headers = body, headers
      end
      @response = self
    end
    
    def html_document
      @html_document ||= HTML::Document.new(@body)
    end
    
  end
end
