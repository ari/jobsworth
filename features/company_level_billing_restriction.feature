Feature: Restrict billing use at company level

Scenario: Seeing the billing tab if billing is enabled at company level
  Given I am logged in as admin with 3 projects
  Then I should see "Billing" within any ".nav"

Scenario: Not seeing the billing tab if billing is disabled at company level
  Given I am logged in as admin_with_no_billing with 3 projects
  Then I should not see "Billing" within any ".nav"

Scenario: Seeing the services tab if billing is enabled at company level
  Given I am logged in as admin with 3 projects
  When I follow "Company Settings"
  Then I should see "Services" within any ".nav"

Scenario: Not seeing the services tab if billing is disabled at company level
  Given I am logged in as admin_with_no_billing with 3 projects
  When I follow "Company Settings"
  Then I should not see "Services" within any ".nav"

Scenario: Seeing the suppress billing checkbox if billing is enabled at company level
  Given I am logged in as admin with 3 projects
  And I am on a project edit page
  Then I should see "Suppress Billing"

Scenario: Not seeing the suppress billing checkbox if billing is disabled at company level
  Given I am logged in as admin_with_no_billing with 3 projects
  And I am on a project edit page
  Then I should not see "Suppress Billing"

Scenario: Seeing the suppress billing checkbox if billing is enabled at company level
  Given I am logged in as admin with 3 projects
  And I am on a project show page
  Then I should see "Suppress Billing"

Scenario: Not seeing the suppress billing checkbox if billing is disabled at company level
  Given I am logged in as admin_with_no_billing with 3 projects
  And I am on a project show page
  Then I should not see "Suppress Billing"