Feature: Restrict billing use at company level

Scenario: Seeing the billing tab if enabled at company level (default true)
  Given I am logged in as admin with 3 projects
  Then I should see "Billing" within any ".nav"

Scenario: Not seeing the billing tab if disabled at company level (default true)
  Given I am logged in as admin_with_no_billing with 3 projects
  Then I should not see "Billing" within any ".nav"