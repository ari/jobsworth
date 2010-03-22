Feature: Manage access_controls
  In order to use access control across the entire company
  Company admin
  wants set access level for tasks, milestones, projects, work logs

  Scenario: Register new access_control
    Given I am on the new access_control page
    And I press "Create"

  Scenario: Delete access_control
    Given the following access_controls:
      ||
      ||
      ||
      ||
      ||
    When I delete the 3rd access_control
    Then I should see the following access_controls:
      ||
      ||
      ||
      ||

  Scenario: Set access level for project
    Given I logged in as "admin"
    And I am on the projects page
    Given the following projects
      | name   | customer |
      | first  | internal |
      | second | external |
    Given the following access levels
      | name   | color | icon    | accesible object |
      | low    | white | low.jpg | project          |
      | secure | black | sec.jpg | project          |
    When I click on "first project"  link
    Then I receive  "project edit" page for "first"
    When I select "low" from "access levels" list
    And I click "Save" button
    Then I receive "projects" page
    And I see "first" project with "white" background

