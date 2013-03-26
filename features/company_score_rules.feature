Feature: Control usage of score rules at company level

  Scenario: Seeing the score rules tab on company edit page if enabled at company level (default true)
    Given I have all score rules related test data and logged in as admin
     When I am on current common user "company" edit page
     Then I should see "Score Rules" within any ".nav"

  Scenario: Not Seeing the score rules tab on company edit page if disabled at company level
    Given I have all score rules related test data and logged in as admin_with_no_score_rules
     When I am on current common user "company" edit page
     Then I should not see "Score Rules" within any ".nav"

  Scenario: Seeing the score rules tab on project edit page if enabled at company level
    Given I have all score rules related test data and logged in as admin
     When I am on current common user 1. "project" edit page
     Then I should see "Score Rules" within any ".nav"

  Scenario: Not Seeing the score rules tab on project edit page  if disabled at company level
    Given I have all score rules related test data and logged in as admin_with_no_score_rules
     When I am on current common user 1. "project" edit page
     Then I should not see "Score Rules" within any ".nav"

  Scenario: Seeing the score rules tab on milestone edit page if enabled at company level
    Given I have all score rules related test data and logged in as admin
     When I am on current common user 1. "milestone" edit page
     Then I should see "Score Rules"

  Scenario: Not Seeing the score rules tab on milestone edit page if disabled at company level
    Given I have all score rules related test data and logged in as admin_with_no_score_rules
     When I am on current common user 1. "milestone" edit page
     Then I should not see "Score Rules"

  Scenario: Not Seeing the score rules tab on milestone edit page if disabled at company level
    Given I have all score rules related test data and logged in as admin_with_no_score_rules
     When I am on current common user 1. "milestone" edit page
     Then I should not see "Score Rules"
