module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Then /^(?:|I )should see "([^"]*)"(?: within( any)? "([^"]*)")?$/ do |text, any, selector|
  if any
    if selector
      if page.respond_to? :should
        page.should have_css(selector, :text => text)
      else
        assert page.has_css(selector, :text => text)
      end
    else
      if page.respond_to? :should
        page.should have_content(text)
      else
        assert page.has_content?(text)
      end
    end
  else
    with_scope(selector) do
      if page.respond_to? :should
        page.should have_content(text)
      else
        assert page.has_content?(text)
      end
    end
  end
end
