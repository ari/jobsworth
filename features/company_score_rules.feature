Feature: Control usage of score rules at company level

  Scenario Outline:
    Given I have all score rules related test data and logged in as <user>
     When <page>
     Then <result>

    Examples:
       | user                      | page                                                          | result                                           |
       | admin                     | I am on current common user "company" edit page               | I should see "Score Rules" within any ".nav"     |
       | admin_with_no_score_rules | I am on current common user "company" edit page               | I should not see "Score Rules" within any ".nav" |
       | admin                     | I am on current common user 1. "project" edit page            | I should see "Score Rules" within any ".nav"     |
       | admin_with_no_score_rules | I am on current common user 1. "project" edit page            | I should not see "Score Rules" within any ".nav" |
       | admin                     | I am on current common user 1. "milestone" edit page          | I should see "Score Rules"                       |
       | admin_with_no_score_rules | I am on current common user 1. "milestone" edit page          | I should not see "Score Rules"                   |
       | admin                     | I am on a customer edit page                                  | I should see "Score Rules"                       |
       | admin_with_no_score_rules | I am on a customer edit page                                  | I should not see "Score Rules"                   |


  Scenario: Not Seeing the score rules tab on properties edit page if disabled at company level
    Given I have all score rules related test data and logged in as admin_with_no_score_rules
     When I am on a property edit page
     Then I should not see "Score Rules"

  Scenario: Seeing the score rules tab on properties edit page if enabled at company level
    Given I have all score rules related test data and logged in as admin
     When I am on a property edit page
     Then I should see "Score Rules"
