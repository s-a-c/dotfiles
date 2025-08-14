# Phase 3: Teams & Permissions Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of teams and permissions in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Understanding Team-Based Permissions

### Questions

1. **What package is used to implement role-based permissions in the UME tutorial?**
   - A) laravel/fortify
   - B) tightenco/parental
   - C) spatie/laravel-permission
   - D) laravel/sanctum

2. **What is the difference between a role and a permission in the context of the UME tutorial?**
   - A) They are the same thing
   - B) Roles are collections of permissions
   - C) Permissions are collections of roles
   - D) Roles are for users, permissions are for teams

3. **How are team-specific permissions implemented in the UME tutorial?**
   - A) By creating a separate permission table for each team
   - B) By using a polymorphic relationship
   - C) By adding a team_id column to the permissions table
   - D) By using a pivot table with team_id

4. **What is the purpose of the `HasTeams` trait in the UME tutorial?**
   - A) To allow users to create teams
   - B) To define the relationship between users and teams
   - C) To manage team permissions
   - D) To track team activity

### Exercise

**Implement a team-based permission system.**

Create a simplified version of the team-based permission system from the UME tutorial:

1. Set up the necessary tables using migrations
2. Create Role and Permission models
3. Implement a TeamHasPermissions trait
4. Create methods to assign and check permissions in a team context
5. Implement middleware to check team permissions
6. Create a simple UI for managing team permissions
7. Write tests to verify the permission system works correctly

Include code snippets for each step and explain your implementation choices.

## Set 2: Team Management and Invitations

### Questions

1. **How are team invitations handled in the UME tutorial?**
   - A) By sending an email with a registration link
   - B) By creating an invitation record and sending an email with a token
   - C) By adding users directly to teams without invitation
   - D) By using a third-party invitation service

2. **What is the purpose of the team_user pivot table?**
   - A) To store team settings
   - B) To track which users belong to which teams
   - C) To manage team permissions
   - D) To store team activity logs

3. **What role does the current_team_id column serve in the users table?**
   - A) It's not used
   - B) It indicates which team the user is currently viewing/working with
   - C) It indicates which team the user created first
   - D) It indicates the user's favorite team

4. **How can a user switch between teams in the UME tutorial?**
   - A) By logging out and logging back in
   - B) By using the team switcher in the UI
   - C) By changing their profile settings
   - D) Users can only belong to one team

### Exercise

**Implement a team invitation system.**

Create a team invitation system with the following features:

1. Create a migration for the team_invitations table
2. Implement a TeamInvitation model
3. Create a controller for sending and accepting invitations
4. Implement email notifications for invitations
5. Create Livewire components for:
   - Sending invitations
   - Listing pending invitations
   - Accepting/rejecting invitations
6. Add validation and error handling
7. Implement authorization policies for team management
8. Write tests for the invitation system

Include code snippets for each step and explain your implementation choices.

## Additional Resources

- [Spatie Laravel Permission Documentation](https://spatie.be/docs/laravel-permission)
- [Laravel Relationships Documentation](https://laravel.com/docs/eloquent-relationships)
- [Laravel Authorization Documentation](https://laravel.com/docs/authorization)
- [Laravel Notifications Documentation](https://laravel.com/docs/notifications)
