# Permission/Role State Machine Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

## Introduction

These exercises will help you practice implementing and working with state machines for permissions and roles in Laravel applications. You'll apply the concepts learned in the Permission/Role State Machine section of the tutorial.

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Sample Answers**:
> - [Main: Permission & Role State Machine Answers](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers.md)
> - [Part 2: Implementation Details for Permission States](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part2.md)
> - [Part 3: Implementation Details for Role States](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part3.md)
> - [Part 4: State Transitions Implementation](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part4.md)
> - [Part 5: Integration with Laravel Models](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part5.md)
> - [Part 6: Testing Permission State Machines](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part6.md)
> - [Part 7: Testing Role State Machines](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part7.md)
> - [Part 8: Advanced Permission Scenarios](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part8.md)
> - [Part 9: Advanced Role Scenarios](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part9.md)
> - [Part 10: Integration with UI Components](../070-sample-answers/040-042-permission-role-state-machine-exercises-answers-part10.md)

## Exercise 1: Implementing a Custom Permission State

Create a new state for the permission state machine called `PendingApproval` that represents a permission that has been submitted for approval but not yet approved.

1. Create the `PendingApproval` state class in the appropriate directory
2. Update the `PermissionState` configuration to include the new state
3. Create a transition class for transitioning from `Draft` to `PendingApproval`
4. Implement the state-specific behavior methods for the new state

## Exercise 2: Extending the Role State Machine

Extend the role state machine to include a `Suspended` state that represents a role that has been temporarily suspended due to a security incident.

1. Add a new case to the `RoleStatus` enum for the `SUSPENDED` state
2. Create the `Suspended` state class in the appropriate directory
3. Update the `RoleState` configuration to include the new state and transitions
4. Create transition classes for transitioning to and from the `Suspended` state
5. Implement the state-specific behavior methods for the new state

## Exercise 3: Creating a Permission History Feature

Implement a feature to track the history of permission state changes.

1. Create a `PermissionHistory` model and migration
2. Update the permission transition classes to record history entries
3. Create a controller method to display the history of a permission
4. Create a view to display the permission history

## Exercise 4: Implementing Batch State Transitions

Implement a feature to perform batch state transitions on multiple permissions or roles at once.

1. Create a controller method to handle batch transitions
2. Create a form to select multiple permissions/roles and the desired transition
3. Implement the logic to perform the transitions and handle errors
4. Create a view to display the results of the batch operation

## Exercise 5: Creating a Permission Approval Workflow

Implement a complete approval workflow for permissions that includes multiple steps and approvers.

1. Create additional states for the approval workflow (e.g., `PendingFirstApproval`, `PendingSecondApproval`)
2. Create transition classes for each step in the workflow
3. Implement a notification system to notify approvers when a permission is ready for their approval
4. Create views for each step in the approval process

## Exercise 6: Implementing Role Inheritance with State Awareness

Implement a role inheritance system that takes into account the state of the roles.

1. Create a `RoleInheritance` model and migration to track role inheritance relationships
2. Update the role state classes to handle inheritance behavior based on state
3. Create a service class to resolve effective permissions taking into account role inheritance and states
4. Create tests to verify the inheritance behavior

## Exercise 7: Creating a Permission/Role Dashboard

Create a dashboard to visualize the state of permissions and roles in the system.

1. Create a controller to gather statistics about permission and role states
2. Create a view with charts and graphs to display the statistics
3. Implement filters to view statistics by team, guard, or other criteria
4. Add real-time updates using Laravel Echo and WebSockets

## Exercise 8: Implementing State-Based Authorization

Extend the Laravel authorization system to take into account the state of permissions and roles.

1. Create a custom authorization gate that checks permission/role states
2. Create middleware to check permission/role states
3. Update the `can` and `cannot` methods to be state-aware
4. Create tests to verify the authorization behavior

## Exercise 9: Creating a Permission/Role Audit System

Implement an audit system to track changes to permissions and roles, including state changes.

1. Create an `Audit` model and migration
2. Update the permission and role models to record audit entries
3. Create a controller and views to display the audit log
4. Implement filters and search for the audit log

## Exercise 10: Implementing Team-Scoped Permission/Role States

Extend the permission and role state machines to be team-scoped, allowing different teams to have different states for the same permission or role.

1. Update the permission and role models to support team-scoped states
2. Create a service class to resolve the effective state for a permission or role in a given team context
3. Update the controllers and views to handle team-scoped states
4. Create tests to verify the team-scoping behavior

## Submission Guidelines

For each exercise:

1. Create a new branch for your implementation
2. Implement the required features
3. Write tests to verify your implementation
4. Create a pull request with your changes
5. Include a README.md file explaining your implementation and any design decisions you made

## Evaluation Criteria

Your exercises will be evaluated based on:

1. Correctness: Does the implementation work as expected?
2. Code quality: Is the code well-organized, readable, and maintainable?
3. Test coverage: Are there comprehensive tests for the implementation?
4. Documentation: Is the implementation well-documented?
5. Design: Are the design decisions appropriate for the requirements?
