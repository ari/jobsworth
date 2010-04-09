Feature: Manage access_controls
  In order to use access control across the entire company
  users with can_only_see_watched permission on project must see only own tasks in this project

  Scenario: User with can only see watched permission on all project
    Given I logged in as user
    And I have permission can only see watched on all projects
    When I click on Overview menu
    Then I go to activities/list
    And I see only my tasks

    When I click on Task menu
    Then I go to tasks/list
    When I remove all filters
    Then I see only my tasks

    When I click on Timeline menu
    Then I go to timeline/list
    And I see only my tasks

    When I click on Reports menu
    And I select Custom in Time Range
    And I type 1/1/2000 in From
    And I type 1/1/2011 in To
    And I push Run Report button
    Then I see only my tasks

    When type "e" in query
    And I press Enter key
    Then I go to sesearch/search
    And I see only my tasks

  Scenario: User with can only see watched permission on first project
    Given I logged in as user
    And I have permission can only see watched on first project
    When I click on Overview menu
    Then I go to activities/list
    And I see only my tasks in first project
    And I see all tasks in all projects except first

    When I click on Task menu
    Then I go to tasks/list
    When I remove all filters
    Then I see only my tasks in first project
    And I see all tasks in all projects except first

    When I click on Timeline menu
    Then I go to timeline/list
    And I see only my tasks in first project
    And I see all tasks in all projects except first

    When I click on Reports menu
    And I select Custom in Time Range
    And I type 1/1/2000 in From
    And I type 1/1/2011 in To
    And I push Run Report button
    Then I see only my tasks in first project
    And I see all tasks in all projects except first

    When type "e" in query
    And I press Enter key
    Then I go to sesearch/search
    And I see only my tasks in first project
    And I see all tasks in all projects exept first

  Scenario: User without  can only see watched permission on all project
    Given I logged in as user
    And I not have permission can only see wathced on all projects
    When I click on Overview menu
    Then I go to activities/list
    And I see all tasks

    When I click on Task menu
    Then I go to tasks/list
    When I remove all filters
    Then I see all tasks

    When I click on Timeline menu
    Then I go to timeline/list
    And I see all tasks

    When I click on Reports menu
    And I select Custom in Time Range
    And I type 1/1/2000 in From
    And I type 1/1/2011 in To
    And I push Run Report button
    Then I see all tasks

    When type "e" in query
    And I press Enter key
    Then I go to sesearch/search
    And I see all tasks
