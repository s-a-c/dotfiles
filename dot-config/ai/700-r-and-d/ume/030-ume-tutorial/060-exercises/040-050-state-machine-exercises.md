# State Machine Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of state machines in the UME tutorial. Each set contains questions and a practical exercise.

> **Related Tutorial Section**: [Phase 2: Auth & Profiles](../050-implementation/030-phase2-auth-profile/000-index.md)
>
> **Sample Answers**: [State Machine Exercises Answers](../070-sample-answers/040-031-state-machine-exercises-answers.md)

## Set 1: State Machine Basics

### Questions

1. **What is a state machine?**
   - A) A physical machine that stores application state
   - B) A design pattern that defines possible states and transitions between them
   - C) A database schema for storing state information
   - D) A JavaScript framework for managing UI state

2. **Which package is used to implement state machines in the UME tutorial?**
   - A) laravel/fortify
   - B) tightenco/parental
   - C) spatie/laravel-model-states
   - D) laravel/sanctum

3. **What is the benefit of using a state machine for user status?**
   - A) It makes the code more complex
   - B) It enforces valid state transitions and encapsulates state-specific behavior
   - C) It's required by Laravel
   - D) It improves database performance

4. **What is a transition in the context of state machines?**
   - A) A method that changes the state of a model
   - B) A database migration
   - C) A UI animation
   - D) A route change

### Exercise

**Implement a simple state machine for a task management system.**

Create a state machine for a task with the following states:
- Todo
- InProgress
- UnderReview
- Done
- Cancelled

For each state:
1. Define the state class
2. Define allowed transitions
3. Implement any special behavior for the state

Then, create a simple test that demonstrates the state machine in action, showing how a task moves through different states.

## Set 2: Advanced State Machine Concepts

### Questions

1. **What is a transition class in Spatie's Laravel Model States package?**
   - A) A class that defines how to move from one state to another
   - B) A class that defines the UI for state transitions
   - C) A class that handles database migrations
   - D) A class that manages state synchronization

2. **How can you add validation to a state transition?**
   - A) You can't; validation is not supported
   - B) By adding validation rules to the transition class
   - C) By using a separate validator class
   - D) By adding validation rules to the state classes

3. **What is the purpose of the `registerStates` method in a model using state machines?**
   - A) To register the model with the state machine
   - B) To define the default state
   - C) To register all possible states and their transitions
   - D) To create database columns for states

4. **How can you query models by their state?**
   - A) You can't; states are not queryable
   - B) Using the `whereState` method
   - C) Using the `state()` scope
   - D) Using a custom query builder

### Exercise

**Implement an account status state machine.**

Create a state machine for user account status with the following states:
- Pending
- Active
- Deactivated
- Suspended

Implement the following:

1. Create a new `Locked` state class that extends `AccountState`
2. Add a new case to the `AccountStatus` enum for the locked state
3. Update the state machine configuration to allow transitions:
   - From `Active` to `Locked`
   - From `Locked` to `Active`
   - From `Locked` to `Deactivated`
4. Create a transition class for the `Active` to `Locked` transition that:
   - Requires a reason for locking the account
   - Records the lock reason and timestamp
   - Sends an email notification to the user
5. Create a controller action to lock and unlock user accounts
6. Add a view for locked accounts
7. Update the middleware to handle locked accounts
8. Write tests for the new state and transitions

Submit your implementation with code for all the required components and tests.

## Set 3: State Machine Integration

### Questions

1. **How can you integrate a state machine with email verification?**
   - A) You can't, they are unrelated concepts
   - B) By transitioning the account state when the email is verified
   - C) By sending an email when the state changes
   - D) By verifying the email when the state changes

2. **What is the benefit of using transition classes instead of direct transitions?**
   - A) Transition classes are faster
   - B) Transition classes allow you to encapsulate transition logic
   - C) Transition classes are required by the Spatie package
   - D) Transition classes use less memory

3. **How can you handle side effects when a state changes?**
   - A) You can't; state machines don't support side effects
   - B) By implementing methods in the state classes
   - C) By using event listeners
   - D) Both B and C

4. **What is the relationship between state machines and the observer pattern?**
   - A) They are unrelated concepts
   - B) State machines can use observers to react to state changes
   - C) Observers can use state machines to track state
   - D) They are competing patterns that should not be used together

### Exercise

**Implement a Multi-Step Form with State Machine**

Create a multi-step form for a user registration process that uses a state machine to track the user's progress through the form. The form should have the following steps:

1. Basic Information (name, email)
2. Account Details (username, password)
3. Profile Information (bio, avatar)
4. Preferences (notifications, theme)
5. Confirmation

For each step:
1. Create a state class representing that step
2. Define allowed transitions to the next and previous steps
3. Implement validation for each step
4. Store the form data in the session between steps

Create a controller that handles the form submission for each step and transitions the state machine accordingly. Also, create a view for each step that shows the user's progress through the form.

Finally, write tests to ensure the form works correctly and that users can't skip steps or submit invalid data.

Submit your implementation with code for all the required components and tests.

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states/v2/introduction)
- [Laravel Fortify Documentation](https://laravel.com/docs/fortify)
- [Laravel Testing Documentation](https://laravel.com/docs/testing)
