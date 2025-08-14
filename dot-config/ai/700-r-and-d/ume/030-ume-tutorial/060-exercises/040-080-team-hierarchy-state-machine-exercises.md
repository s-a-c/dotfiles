# Team Hierarchy State Machine Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of the team hierarchy state machine implementation in the UME tutorial. Each set contains questions and a practical exercise.

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Sample Answers**:
> - [Team Hierarchy State Machine Exercises Answers (Main)](../070-sample-answers/040-045-team-hierarchy-state-machine-exercises-answers.md)
> - [Part 2: Implementation Details](../070-sample-answers/040-045-team-hierarchy-state-machine-exercises-answers-part2.md)
> - [Part 3: Team Hierarchy Transitions](../070-sample-answers/040-045-team-hierarchy-state-machine-exercises-answers-part3.md)
> - [Part 4: Integration with Team Models](../070-sample-answers/040-045-team-hierarchy-state-machine-exercises-answers-part4.md)
> - [Part 5: Testing Team Hierarchy State Machines](../070-sample-answers/040-045-team-hierarchy-state-machine-exercises-answers-part5.md)

## Set 1: Team Hierarchy State Machine Basics

### Questions

1. **What is the purpose of using a state machine for team hierarchies?**
   - A) To make the code more complex
   - B) To enforce valid state transitions and encapsulate state-specific behavior
   - C) To reduce database queries
   - D) To improve UI performance

2. **Which package is used to implement the team hierarchy state machine?**
   - A) laravel/jetstream
   - B) spatie/laravel-permission
   - C) spatie/laravel-model-states
   - D) laravel/sanctum

3. **What is the default state for a newly created team?**
   - A) Active
   - B) Pending
   - C) Suspended
   - D) Archived

4. **Which of the following is NOT a valid state for a team in our implementation?**
   - A) Pending
   - B) Active
   - C) Suspended
   - D) Deleted

### Exercise

**Implement a basic team hierarchy state machine.**

Create a simplified version of the team hierarchy state machine with the following states:
- Draft
- Published
- Archived

For each state:
1. Create the state class
2. Define allowed transitions
3. Implement a method `canBeViewed()` that returns:
   - `false` for Draft teams
   - `true` for Published teams
   - `true` for Archived teams (but only for admins)

Then, create a simple test that demonstrates the state machine in action, showing how a team moves through different states.

## Set 2: Advanced State Machine Concepts

### Questions

1. **What is a transition class in the context of our team hierarchy state machine?**
   - A) A class that defines how to move from one state to another
   - B) A class that handles database migrations
   - C) A class that manages team memberships
   - D) A class that renders the UI for state transitions

2. **Which of the following is a valid transition in our team hierarchy state machine?**
   - A) Archived → Suspended
   - B) Pending → Suspended
   - C) Active → Archived
   - D) Suspended → Pending

3. **What happens when you try to make an invalid state transition?**
   - A) The transition is silently ignored
   - B) The application crashes
   - C) A `TransitionNotFound` exception is thrown
   - D) The state is reset to the default

4. **Which feature allows state transitions to affect child teams?**
   - A) State inheritance
   - B) Cascading transitions
   - C) State propagation
   - D) Hierarchical states

### Exercise

**Implement a team status state machine with cascading transitions.**

Create a state machine for team status with the following requirements:

1. Create the following states:
   - `Draft`: Initial state, not visible to regular users
   - `Active`: Fully operational team
   - `OnHold`: Temporarily paused team
   - `Discontinued`: Permanently discontinued team

2. Implement the following transitions:
   - `PublishTeamTransition`: Draft → Active
   - `PauseTeamTransition`: Active → OnHold
   - `ResumeTeamTransition`: OnHold → Active
   - `DiscontinueTeamTransition`: Active/OnHold → Discontinued

3. Add a `cascadeToChildren` parameter to each transition that, when true, applies the same transition to all child teams

4. Create a controller method that handles the "pause team" action, including:
   - Authorization check (only admins or team owners can pause a team)
   - Validation of input
   - Execution of the transition
   - Proper error handling
   - Success/error messages

5. Write tests for the state machine, including tests for cascading transitions

## Set 3: State Machine Integration

### Questions

1. **How can you query teams by their state?**
   - A) Using a custom scope
   - B) Using the `whereState()` method
   - C) Using a regular where clause
   - D) Using the `filterByState()` method

2. **Which of the following is NOT a benefit of using a state machine for team hierarchies?**
   - A) Enforced workflows
   - B) Validation of transitions
   - C) Improved database performance
   - D) Business logic encapsulation

3. **How can you visualize the current state of a team in the UI?**
   - A) By using the state's `tailwindClasses()` method
   - B) By manually checking the state and applying classes
   - C) By using a dedicated visualization component
   - D) All of the above

4. **What is the purpose of the `TeamStateFilter` component?**
   - A) To filter teams by their state in the UI
   - B) To change the state of multiple teams at once
   - C) To validate state transitions
   - D) To display the state history of a team

### Exercise

**Implement a team state history and audit log.**

Create a system to track the history of team state changes:

1. Create a `TeamStateHistory` model with the following fields:
   - `team_id`: The ID of the team
   - `from_state`: The previous state
   - `to_state`: The new state
   - `reason`: The reason for the state change
   - `changed_by_id`: The ID of the user who made the change
   - `created_at`: Timestamp of the change

2. Modify the transition classes to record state changes in the history table

3. Create a `TeamStateHistoryController` and corresponding routes to:
   - View the state history of a specific team
   - Filter history by state, user, or date range
   - Export the history to CSV

4. Create a Livewire component to display the state history in the UI, including:
   - Pagination
   - Filtering options
   - Sorting options

5. Add a feature to revert to a previous state (if the transition is valid)

6. Write tests for the history tracking and viewing functionality

Submit your implementation with code for all the required components and tests.

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Laravel Livewire Documentation](https://laravel-livewire.com/docs)
- [Laravel Testing Documentation](https://laravel.com/docs/testing)
