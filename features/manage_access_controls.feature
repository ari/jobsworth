Feature: Manage access_controls
  In order to use access control across the entire company
  users with can_only_see_watched permission on project must see only own tasks in this project
  Background:
    Given system with users, projects and tasks
    Given all task names prefixed by watchers names

  Scenario: User without can see unwatched permission on all project
    Given I logged in as user
    And I not have permission can see unwatched on all projects
    When I follow "Overview" within "#tabmenu"
    Then I should be on activities
    And I see only my tasks

    When I follow "Tasks" within "#tabmenu"
    Then I should be on tasks
    When I remove all filters
    Then I see only my tasks

    When I follow "Timeline" within "#tabmenu"
    Then I should be on timeline
    And I see only my tasks

    When I follow "Reports" within "#tabmenu"
    And I select "Custom" from "Time Range"
    And I fill in "From" with "1/1/2000"
    And I fill in "To" with "1/1/2011"
    And I press "Run Report"
    Then I see only my tasks

    When fill in "query" with "e"
    And I press Enter key
    Then I should be on sesearch/search
    And I see only my tasks

  Scenario: User without can see unwatched permission on first project
    Given I logged in as user
    And I not have permission can see unwatched on first project
    When I follow "Overview" within "#tabmenu"
    Then I should be on activities
    And I see only my tasks in first project
    And I see all tasks in all projects except first

    When I follow "Task" within "#tabmenu"
    Then I should be on tasks
    When I remove all filters
    Then I see only my tasks in first project
    And I see all tasks in all projects except first

    When I follow "Timeline" within "#tabmenu"
    Then I should be on timeline
    And I see only my tasks in first project
    And I see all tasks in all projects except first

    When I follow "Reports" within "#tabmenu"
    And I select "Custom" from "Time Range"
    And I fill in "From" with "1/1/2000"
    And I fill in "To" with "1/1/2011"
    And I press "Run Report"
    Then I see only my tasks in first project
    And I see all tasks in all projects except first

    When fill in "query" with "e"
    And I press Enter key
    Then I should be on sesearch/search
    And I see only my tasks in first project
    And I see all tasks in all projects exept first

  Scenario: User with can see unwatched permission on all project
    Given I logged in as user
    And I have permission can see unwathced on all projects
    When I follow "Overview" within "#tabmenu"
    Then I should be on activities
    And I see all tasks

    When I follow "Task" within "#tabmenu"
    Then I go to tasks
    When I remove all filters
    Then I see all tasks

    When I follow "Timeline" within "#tabmenu"
    Then I should be on timeline
    And I see all tasks

    When I follow "Reports" within "#tabmenu"
    And I select "Custom" from "Time Range"
    And I fill in "From" with "1/1/2000"
    And I fill in "To" with "1/1/2011"
    And I press "Run Report"
    Then I see all tasks

    When fill in "query" with "e"
    And I press Enter key
    Then I should be on sesearch/search
    And I see all tasks
