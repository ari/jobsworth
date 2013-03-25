Feature: Restrict billing use at company level

@javascriot
Scenario: Seeing the billing tab if enabled at company level (default true)
  Given I am logged in as admin with 3 projects
  Then show me the page
  Then I should see "Billing" within any ".nav"