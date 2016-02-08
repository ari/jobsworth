require 'spec_helper'

describe ApplicationHelper do

  describe '#link_to_function' do
    it 'should return an anchor tag with a property of "data-function"' do
      expect(helper.link_to_function "Greeting", "alert('Hello world!')", :class => "nav_link")
        .to eql '<a class="nav_link" href="#" data-function="alert(\'Hello world!\'); return false;">Greeting</a>'
    end
  end

end
