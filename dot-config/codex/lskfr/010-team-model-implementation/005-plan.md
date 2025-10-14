 # Plan: Team Model Enhancement Implementation

 ## 1. Overview
 This document breaks down the [PRD](../005-prd-enhance-team-model-guide.md) into actionable tasks.

 ## 2. Model & Database
 - [x] Create `Team` model (app/Models/Team.php)
 - [x] Update `teams` migration to include:
   - `parent_id` (nullable, foreign key)
   - `is_active` (boolean, default `true`)
   - `allow_subteams` (boolean, default `true`)
 - [x] Create `team_invitations` table migration
 - [x] Create `TeamInvitation` model (app/Models/TeamInvitation.php)
 - [x] Create `TeamUser` pivot model (app/Models/TeamUser.php)

 ## 3. Factories & Seeders
 - [x] Create `TeamFactory` (database/factories/TeamFactory.php)
 - [x] Create `TeamUserFactory` (database/factories/TeamUserFactory.php)
 - [x] Create `TeamSeeder` (database/seeders/TeamSeeder.php)
 - [x] Create `TeamUserSeeder` (database/seeders/TeamUserSeeder.php)

 ## 4. Relationships & Business Logic
 - [x] Implement relationships in `Team`:
   - `parent()`, `children()`, `ancestors()`, `descendants()`
   - `members()` via `team_users` pivot
 - [x] Add helper methods:
   - `addMember()`, `removeMember()`, `hasMember()`, `hasMemberInHierarchy()`
   - `allowsSubteams()`, `isRootLevel()`, `createSubteam()`
 - [x] Implement invitation logic in `TeamInvitation`:
   - `generateToken()`, `hasExpired()`, `accept()`

 ## 5. Authorization & Policies
 - [ ] Create `TeamPolicy` (app/Policies/TeamPolicy.php)
 - [ ] Register policy in `AuthServiceProvider`
 - [ ] Define rules for:
   - `view`, `createSubteam`, `manageMembers`, `delete`

 ## 6. Controllers & Routes
 - [ ] Create `TeamController` with CRUD endpoints
 - [ ] Create `TeamInvitationController` for invite flow
 - [ ] Add routes in `routes/web.php` (and/or `api.php`)

 ## 7. Validation & Requests
 - [ ] Create Form Request classes:
   - `StoreTeamRequest`, `UpdateTeamRequest`
   - `StoreInvitationRequest`

 ## 8. Tests
 - [ ] Unit tests for models and policies
 - [ ] Feature tests for:
   - Team creation (default parent, root-level restriction)
   - Invitation creation (missing team_id, allow_subteams)
   - Invitation acceptance (expired token)

 ## 9. Frontend Integration
 - [ ] Build team management UI in two stacks:
   - [ ] Volt SFC with Folio routing
   - [ ] InertiaJS with React
 - [ ] Invitation UI with mandatory team selector and toggle for subteams (both stacks)

 ## 10. Documentation
 - [ ] Update docs/guides with new implementation details
 - [ ] Ensure code examples and diagrams match implementation

## 11. Active Team Persistence
- [ ] Create migration to add `current_team_id` to `users` table
- [ ] Update User model: add `teams()` and `currentTeam()` relations, and `current_team_id` to fillable
- [ ] Add `setCurrentTeam()` method on User model
- [ ] Enhance `Team::addMember()` to auto-assign `current_team_id` if null
- [ ] Enhance `Team::removeMember()` to clear `current_team_id` when removed
- [ ] Add unit tests for active team functionality
- [ ] Update docs with active team usage examples

## 12. Queueing Mailables & Notifications
- [ ] Ensure all Mailables implement `ShouldQueue` and queue on `mailables` queue
- [ ] Ensure all Notifications implement `ShouldQueue` and queue on `notifications` queue
- [ ] Update dispatch calls to use `queue()` for mail and notifications
- [ ] Add or update tests to assert that Mailables and Notifications are queued correctly
- [ ] Update documentation with implementation and usage examples for queues
<<<<<<< HEAD
- [ ] Schedule queue workers for mailables and notifications (every 5 minutes)
=======
- [ ] Schedule queue workers for mailables and notifications (every 5 minutes)
>>>>>>> origin/develop
