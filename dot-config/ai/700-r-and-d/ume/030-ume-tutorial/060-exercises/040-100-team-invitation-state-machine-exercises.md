# Team Invitation State Machine Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of the team invitation state machine implementation in the UME tutorial. Each set contains questions and a practical exercise.

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Sample Answers**:
> - [Part 1: Introduction and Basic Concepts](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part1.md)
> - [Part 2: Implementation Details for Invitation States](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part2.md)
> - [Part 3: Invitation State Transitions](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part3.md)
> - [Part 4: Integration with Invitation Models](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part4.md)
> - [Part 5: Email Notifications for Invitations](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part5.md)
> - [Part 6: UI Components for Invitations](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part6.md)
> - [Part 7: Testing Invitation State Machines](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part7.md)
> - [Part 8: Advanced Invitation Scenarios](../070-sample-answers/040-050-team-invitation-state-machine-exercises-answers-part8.md)

## Exercise 1: Understanding Team Invitation States

**Answer the following questions about the team invitation state machine:**

1. Which package is used to implement the team invitation state machine?
   - A) spatie/laravel-model-flags
   - B) spatie/laravel-model-status
   - C) spatie/laravel-model-states
   - D) spatie/laravel-enum

2. What is the default state for a newly created team invitation?
   - A) Accepted
   - B) Pending
   - C) Rejected
   - D) Expired

3. Which of the following is NOT a valid state for a team invitation in our implementation?
   - A) Pending
   - B) Accepted
   - C) Canceled
   - D) Revoked

4. Which transition is responsible for adding a user to a team?
   - A) RejectInvitationTransition
   - B) AcceptInvitationTransition
   - C) ExpireInvitationTransition
   - D) RevokeInvitationTransition

5. What happens when a team invitation expires?
   - A) It is automatically deleted from the database
   - B) It transitions to the Expired state
   - C) It remains in the Pending state but is marked as invalid
   - D) It transitions to the Rejected state

## Exercise 2: Implementing a Custom Transition

**Implement a new transition called `ResendInvitationTransition` that extends the expiration date of a pending invitation and logs the action.**

The transition should:
1. Only work on invitations in the Pending state
2. Extend the expiration date by 7 days from the current date
3. Log the action using Laravel's logging system
4. Record the action in the activity log
5. Return the invitation in the Pending state (same state, just updated expiration)

## Exercise 3: Adding a New State

**Implement a new state called `Canceled` for team invitations.**

The new state should:
1. Be added to the TeamInvitationStatus enum
2. Have a concrete state class that extends TeamInvitationState
3. Have appropriate UI colors and icons
4. Allow transitions from Pending to Canceled
5. Not allow transitions from Canceled to any other state

## Exercise 4: Implementing a State History Feature

**Implement a feature to track the history of state changes for team invitations.**

Create a `TeamInvitationStateHistory` model that:
1. Records each state transition
2. Stores the from_state, to_state, reason (if provided), and user who performed the transition
3. Has a relationship to the TeamInvitation model
4. Has a relationship to the User model (for the user who performed the transition)

Then, modify the transition classes to record state changes in this history model.

## Exercise 5: Creating a Dashboard for Team Invitation Management

**Create a Livewire component for a team invitation management dashboard.**

The dashboard should:
1. Display all team invitations grouped by state (Pending, Accepted, Rejected, Expired, Revoked)
2. Allow filtering by state
3. Allow searching by email
4. Show the expiration date and time remaining for pending invitations
5. Allow team administrators to perform actions like resend, revoke, etc.
6. Include pagination for large numbers of invitations

## Exercise 6: Implementing Batch Invitations

**Implement a feature to send batch invitations to multiple email addresses at once.**

Create:
1. A form that accepts multiple email addresses (comma or newline separated)
2. A controller method that processes the batch invitation
3. A job that sends the invitations in the background
4. A way to track the progress of the batch invitation process
5. Error handling for invalid email addresses

## Exercise 7: Testing State Transitions

**Write comprehensive tests for the team invitation state machine.**

Create tests that:
1. Verify that new invitations are created in the Pending state
2. Test all valid state transitions
3. Test that invalid transitions throw appropriate exceptions
4. Test the behavior of the TeamInvitation model's helper methods (isValid, hasExpired, etc.)
5. Test the authorization policies for team invitations

## Exercise 8: Implementing Invitation Reminders

**Implement a feature to send reminder emails for pending invitations.**

Create:
1. A command that identifies pending invitations that are about to expire (e.g., in 2 days)
2. A notification class for the reminder email
3. A schedule to run the command daily
4. A way for team administrators to manually trigger reminders
5. A limit on how many reminders can be sent for a single invitation

## Additional Resources

- [Spatie Laravel Model States Documentation](https://spatie.be/docs/laravel-model-states)
- [Laravel Notifications Documentation](https://laravel.com/docs/10.x/notifications)
- [Laravel Queues Documentation](https://laravel.com/docs/10.x/queues)
- [Laravel Testing Documentation](https://laravel.com/docs/10.x/testing)
