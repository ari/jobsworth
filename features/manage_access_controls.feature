Feature: Manage access_controls
  In order to use access control across the entire company
  users with can_only_see_watched permission on project must see only own tasks in this project

  Scenario: User with can only see watched permission on all project
    Given I logged in as user
    And I have permission can only see watched on all projects
    When I follow "Overview" within "tabmenu"
    Then I should be on activities/list
    And I see only my tasks

    When I follow "Task" within "tabmenu"
    Then I should be on tasks/list
    When I remove all filters
    Then I see only my tasks

    When I follow "Timeline" within "tabmenu"
    Then I should be on timeline/list
    And I see only my tasks

    When I follow "Reports" within "tabmenu"
    And I select "Custom" from "Time Range"
    And I fill in "From" with "1/1/2000"
    And I fill in "To" with "1/1/2011"
    And I push "Run Report" button
    Then I see only my tasks

    When fill in "query" with "e"
    And I press Enter key
    Then I should be on sesearch/search
    And I see only my tasks

  Scenario: User with can only see watched permission on first project
    Given I logged in as user
    And I have permission can only see watched on first project
    When I follow "Overview" within "tabmenu"
    Then I should be on activities/list
    And I see only my tasks in first project
    And I see all tasks in all projects except first

    When I follow "Task" within "tabmenu"
    Then I should be on tasks/list
    When I remove all filters
    Then I see only my tasks in first project
    And I see all tasks in all projects except first

    When I follow "Timeline" within "tabmenu"
    Then I should be on timeline/list
    And I see only my tasks in first project
    And I see all tasks in all projects except first

    When I follow "Reports" within "tabmenu"
    And I select "Custom" from "Time Range"
    And I fill in "From" with "1/1/2000"
    And I fill in "To" with "1/1/2011"
    And I push "Run Report" button
    Then I see only my tasks in first project
    And I see all tasks in all projects except first

    When fill in "query" with "e"
    And I press Enter key
    Then I should be on sesearch/search
    And I see only my tasks in first project
    And I see all tasks in all projects exept first

  Scenario: User without  can only see watched permission on all project
    Given I logged in as user
    And I not have permission can only see wathced on all projects
    When I follow "Overview" within "tabmenu"
    Then I should be on activities/list
    And I see all tasks

    When I follow "Task" within "tabmenu"
    Then I go to tasks/list
    When I remove all filters
    Then I see all tasks

    When I follow "Timeline" within "tabmenu"
    Then I should be on timeline/list
    And I see all tasks

    When I follow "Reports" within "tabmenu"
    And I select "Custom" from "Time Range"
    And I fill in "From" with "1/1/2000"
    And I fill in "To" with "1/1/2011"
    And I push "Run Report" button
    Then I see all tasks

    When fill in "query" with "e"
    And I press Enter key
    Then I should be on sesearch/search
    And I see all tasks
