Feature: Disable contract creation at app level

@contact_creation_allowed
Scenario: Seeing the contacts tab if enabled at app level
  Given I am logged in as admin
  Then I should see "Contacts" within any ".nav"

@contact_creation_forbidden
Scenario: Not seeing the contacts tab if disabled at app level
  Given I am logged in as admin
  Then I should not see "Contacts" within any ".nav"
