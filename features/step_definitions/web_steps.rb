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

Then /^(?:|I )should not see "([^"]*)"(?: within( any)? "([^"]*)")?$/ do |text, any, selector|
  if any
    if selector
      if page.respond_to? :should
        page.should_not have_css(selector, :text => text)
      else
        assert page.has_no_css(selector, :text => text)
      end
    else
      if page.respond_to? :should
        page.should_not have_content(text)
      else
        assert page.has_no_content?(text)
      end
    end
  else
    with_scope(selector) do
      if page.respond_to? :should
        page.should have_no_content(text)
      else
        assert page.has_no_content?(text)
      end
    end
  end
end

When /^(?:|I )follow "([^"]*)"(?: within "([^"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^I click locator "([^"]*)"$/ do |locator|
  find(:xpath, "//*[contains(concat(' ', normalize-space(@class), ' '), ' #{locator} ')]").click
end