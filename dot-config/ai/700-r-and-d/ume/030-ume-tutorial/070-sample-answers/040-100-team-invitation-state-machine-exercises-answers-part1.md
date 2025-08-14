# Team Invitation State Machine Exercises - Sample Answers (Part 1)

<link rel="stylesheet" href="../assets/css/styles.css">

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Exercise File**: [Team Invitation State Machine Exercises](../060-exercises/040-050-team-invitation-state-machine-exercises.md)
>
> **Part 1 of 8**: This is the first part of the Team Invitation State Machine exercises answers. See the [exercise file](../060-exercises/040-050-team-invitation-state-machine-exercises.md) for links to all parts.

## Exercise 1: Understanding Team Invitation States

**Answer the following questions about the team invitation state machine:**

1. **Which package is used to implement the team invitation state machine?**
   - **Answer: C) spatie/laravel-model-states**
   - **Explanation:** We use the Spatie Laravel Model States package to implement state machines in our Laravel application, including the team invitation state machine.

2. **What is the default state for a newly created team invitation?**
   - **Answer: B) Pending**
   - **Explanation:** In our implementation, new team invitations start in the Pending state, as defined in the `TeamInvitationState::config()` method and the `TeamInvitation` model's `boot` method.

3. **Which of the following is NOT a valid state for a team invitation in our implementation?**
   - **Answer: C) Canceled**
   - **Explanation:** Our implementation uses Pending, Accepted, Rejected, Expired, and Revoked states. There is no Canceled state in the current implementation.

4. **Which transition is responsible for adding a user to a team?**
   - **Answer: B) AcceptInvitationTransition**
   - **Explanation:** The `AcceptInvitationTransition` class handles adding the user to the team when they accept an invitation, as shown in its `handle` method.

5. **What happens when a team invitation expires?**
   - **Answer: B) It transitions to the Expired state**
   - **Explanation:** When an invitation expires, it transitions from the Pending state to the Expired state using the `ExpireInvitationTransition` class. This is typically handled by the `team-invitations:expire` command.
