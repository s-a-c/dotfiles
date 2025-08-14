# Team Invitations Workflow

:::interactive-code
title: Implementing a Team Invitation System
description: This example demonstrates how to implement a complete team invitation system with different states, expiration handling, and role assignment.
language: php
editable: true
code: |
  <?php
  
  namespace App\Models;
  
  use DateTime;
  use DateInterval;
  use Exception;
  
  // Invitation state enum
  enum InvitationState: string {
      case Pending = 'pending';
      case Accepted = 'accepted';
      case Declined = 'declined';
      case Expired = 'expired';
      case Revoked = 'revoked';
      
      public function label(): string {
          return match($this) {
              self::Pending => 'Pending',
              self::Accepted => 'Accepted',
              self::Declined => 'Declined',
              self::Expired => 'Expired',
              self::Revoked => 'Revoked',
          };
      }
      
      public function description(): string {
          return match($this) {
              self::Pending => 'Invitation has been sent but not yet accepted or declined',
              self::Accepted => 'Invitation has been accepted by the recipient',
              self::Declined => 'Invitation has been declined by the recipient',
              self::Expired => 'Invitation has expired without being accepted or declined',
              self::Revoked => 'Invitation has been revoked by the sender',
          };
      }
      
      public function canTransitionTo(InvitationState $state): bool {
          return match($this) {
              self::Pending => in_array($state, [self::Accepted, self::Declined, self::Expired, self::Revoked]),
              self::Accepted => false, // Terminal state
              self::Declined => false, // Terminal state
              self::Expired => false, // Terminal state
              self::Revoked => false, // Terminal state
          };
      }
  }
  
  // Team invitation class
  class TeamInvitation {
      private int $id;
      private Team $team;
      private string $email;
      private string $role;
      private User $invitedBy;
      private InvitationState $state;
      private DateTime $createdAt;
      private DateTime $expiresAt;
      private ?DateTime $respondedAt = null;
      private ?User $invitedUser = null;
      
      // Default expiration time (7 days)
      private const DEFAULT_EXPIRATION = 'P7D';
      
      public function __construct(
          int $id,
          Team $team,
          string $email,
          string $role,
          User $invitedBy,
          ?DateInterval $expiration = null
      ) {
          $this->id = $id;
          $this->team = $team;
          $this->email = $email;
          $this->role = $role;
          $this->invitedBy = $invitedBy;
          $this->state = InvitationState::Pending;
          $this->createdAt = new DateTime();
          
          // Set expiration date
          $expiration = $expiration ?? new DateInterval(self::DEFAULT_EXPIRATION);
          $this->expiresAt = (new DateTime())->add($expiration);
      }
      
      /**
       * Get the invitation ID.
       *
       * @return int
       */
      public function getId(): int {
          return $this->id;
      }
      
      /**
       * Get the team.
       *
       * @return Team
       */
      public function getTeam(): Team {
          return $this->team;
      }
      
      /**
       * Get the email address.
       *
       * @return string
       */
      public function getEmail(): string {
          return $this->email;
      }
      
      /**
       * Get the role.
       *
       * @return string
       */
      public function getRole(): string {
          return $this->role;
      }
      
      /**
       * Get the user who sent the invitation.
       *
       * @return User
       */
      public function getInvitedBy(): User {
          return $this->invitedBy;
      }
      
      /**
       * Get the invitation state.
       *
       * @return InvitationState
       */
      public function getState(): InvitationState {
          return $this->state;
      }
      
      /**
       * Get the creation date.
       *
       * @return DateTime
       */
      public function getCreatedAt(): DateTime {
          return $this->createdAt;
      }
      
      /**
       * Get the expiration date.
       *
       * @return DateTime
       */
      public function getExpiresAt(): DateTime {
          return $this->expiresAt;
      }
      
      /**
       * Get the response date.
       *
       * @return DateTime|null
       */
      public function getRespondedAt(): ?DateTime {
          return $this->respondedAt;
      }
      
      /**
       * Get the invited user (if known).
       *
       * @return User|null
       */
      public function getInvitedUser(): ?User {
          return $this->invitedUser;
      }
      
      /**
       * Set the invited user.
       *
       * @param User $user
       * @return self
       */
      public function setInvitedUser(User $user): self {
          $this->invitedUser = $user;
          return $this;
      }
      
      /**
       * Check if the invitation is pending.
       *
       * @return bool
       */
      public function isPending(): bool {
          return $this->state === InvitationState::Pending;
      }
      
      /**
       * Check if the invitation is accepted.
       *
       * @return bool
       */
      public function isAccepted(): bool {
          return $this->state === InvitationState::Accepted;
      }
      
      /**
       * Check if the invitation is declined.
       *
       * @return bool
       */
      public function isDeclined(): bool {
          return $this->state === InvitationState::Declined;
      }
      
      /**
       * Check if the invitation is expired.
       *
       * @return bool
       */
      public function isExpired(): bool {
          if ($this->state === InvitationState::Expired) {
              return true;
          }
          
          // Check if the invitation has expired but hasn't been marked as such
          if ($this->state === InvitationState::Pending && new DateTime() > $this->expiresAt) {
              $this->expire();
              return true;
          }
          
          return false;
      }
      
      /**
       * Check if the invitation is revoked.
       *
       * @return bool
       */
      public function isRevoked(): bool {
          return $this->state === InvitationState::Revoked;
      }
      
      /**
       * Check if the invitation can be accepted.
       *
       * @return bool
       */
      public function canBeAccepted(): bool {
          return $this->state === InvitationState::Pending && !$this->isExpired();
      }
      
      /**
       * Accept the invitation.
       *
       * @param User $user
       * @return self
       * @throws Exception If the invitation cannot be accepted
       */
      public function accept(User $user): self {
          if (!$this->canBeAccepted()) {
              throw new Exception("Invitation cannot be accepted");
          }
          
          // Transition to accepted state
          $this->transitionTo(InvitationState::Accepted);
          $this->respondedAt = new DateTime();
          $this->invitedUser = $user;
          
          // Add the user to the team
          $this->team->addMember($user, $this->role);
          
          return $this;
      }
      
      /**
       * Decline the invitation.
       *
       * @param User|null $user
       * @return self
       * @throws Exception If the invitation cannot be declined
       */
      public function decline(?User $user = null): self {
          if (!$this->state->canTransitionTo(InvitationState::Declined)) {
              throw new Exception("Invitation cannot be declined");
          }
          
          // Transition to declined state
          $this->transitionTo(InvitationState::Declined);
          $this->respondedAt = new DateTime();
          
          if ($user) {
              $this->invitedUser = $user;
          }
          
          return $this;
      }
      
      /**
       * Expire the invitation.
       *
       * @return self
       * @throws Exception If the invitation cannot be expired
       */
      public function expire(): self {
          if (!$this->state->canTransitionTo(InvitationState::Expired)) {
              throw new Exception("Invitation cannot be expired");
          }
          
          // Transition to expired state
          $this->transitionTo(InvitationState::Expired);
          
          return $this;
      }
      
      /**
       * Revoke the invitation.
       *
       * @return self
       * @throws Exception If the invitation cannot be revoked
       */
      public function revoke(): self {
          if (!$this->state->canTransitionTo(InvitationState::Revoked)) {
              throw new Exception("Invitation cannot be revoked");
          }
          
          // Transition to revoked state
          $this->transitionTo(InvitationState::Revoked);
          
          return $this;
      }
      
      /**
       * Transition to a new state.
       *
       * @param InvitationState $state
       * @return self
       * @throws Exception If the transition is not allowed
       */
      private function transitionTo(InvitationState $state): self {
          if (!$this->state->canTransitionTo($state)) {
              throw new Exception("Cannot transition from {$this->state->value} to {$state->value}");
          }
          
          $this->state = $state;
          
          return $this;
      }
      
      /**
       * Get a summary of the invitation.
       *
       * @return string
       */
      public function getSummary(): string {
          $summary = "Invitation #{$this->id} to {$this->email} for team \"{$this->team->getName()}\"";
          $summary .= " ({$this->state->label()})";
          
          return $summary;
      }
      
      /**
       * Get detailed information about the invitation.
       *
       * @return string
       */
      public function getDetails(): string {
          $details = "Invitation #{$this->id}\n";
          $details .= "- Team: {$this->team->getName()}\n";
          $details .= "- Email: {$this->email}\n";
          $details .= "- Role: {$this->role}\n";
          $details .= "- Invited by: {$this->invitedBy->getName()}\n";
          $details .= "- State: {$this->state->label()} ({$this->state->description()})\n";
          $details .= "- Created at: {$this->createdAt->format('Y-m-d H:i:s')}\n";
          $details .= "- Expires at: {$this->expiresAt->format('Y-m-d H:i:s')}\n";
          
          if ($this->respondedAt) {
              $details .= "- Responded at: {$this->respondedAt->format('Y-m-d H:i:s')}\n";
          }
          
          if ($this->invitedUser) {
              $details .= "- Invited user: {$this->invitedUser->getName()}\n";
          }
          
          return $details;
      }
  }
  
  // Team invitation manager
  class TeamInvitationManager {
      private array $invitations = [];
      private int $nextId = 1;
      
      /**
       * Create a new invitation.
       *
       * @param Team $team
       * @param string $email
       * @param string $role
       * @param User $invitedBy
       * @param DateInterval|null $expiration
       * @return TeamInvitation
       * @throws Exception If the user doesn't have permission to invite
       */
      public function createInvitation(
          Team $team,
          string $email,
          string $role,
          User $invitedBy,
          ?DateInterval $expiration = null
      ): TeamInvitation {
          // Check if the user has permission to invite
          if (!$team->userHasPermission($invitedBy, 'team:invite')) {
              throw new Exception("User does not have permission to invite members");
          }
          
          // Check if there's already a pending invitation for this email
          foreach ($this->invitations as $invitation) {
              if ($invitation->getTeam()->getId() === $team->getId() &&
                  $invitation->getEmail() === $email &&
                  $invitation->isPending()) {
                  throw new Exception("There is already a pending invitation for this email");
              }
          }
          
          // Create the invitation
          $invitation = new TeamInvitation(
              $this->nextId++,
              $team,
              $email,
              $role,
              $invitedBy,
              $expiration
          );
          
          // Store the invitation
          $this->invitations[$invitation->getId()] = $invitation;
          
          // In a real app, this would send an email
          echo "Sending invitation email to {$email}\n";
          echo "Invitation link: https://example.com/invitations/{$invitation->getId()}\n";
          
          return $invitation;
      }
      
      /**
       * Get an invitation by ID.
       *
       * @param int $id
       * @return TeamInvitation|null
       */
      public function getInvitation(int $id): ?TeamInvitation {
          return $this->invitations[$id] ?? null;
      }
      
      /**
       * Get all invitations for a team.
       *
       * @param Team $team
       * @return array
       */
      public function getTeamInvitations(Team $team): array {
          $invitations = [];
          
          foreach ($this->invitations as $invitation) {
              if ($invitation->getTeam()->getId() === $team->getId()) {
                  $invitations[] = $invitation;
              }
          }
          
          return $invitations;
      }
      
      /**
       * Get all pending invitations for an email.
       *
       * @param string $email
       * @return array
       */
      public function getPendingInvitationsForEmail(string $email): array {
          $invitations = [];
          
          foreach ($this->invitations as $invitation) {
              if ($invitation->getEmail() === $email && $invitation->isPending()) {
                  $invitations[] = $invitation;
              }
          }
          
          return $invitations;
      }
      
      /**
       * Process expired invitations.
       *
       * @return int Number of invitations expired
       */
      public function processExpiredInvitations(): int {
          $count = 0;
          
          foreach ($this->invitations as $invitation) {
              if ($invitation->isPending() && new DateTime() > $invitation->getExpiresAt()) {
                  $invitation->expire();
                  $count++;
              }
          }
          
          return $count;
      }
      
      /**
       * Resend an invitation.
       *
       * @param int $id
       * @return TeamInvitation
       * @throws Exception If the invitation cannot be resent
       */
      public function resendInvitation(int $id): TeamInvitation {
          $invitation = $this->getInvitation($id);
          
          if (!$invitation) {
              throw new Exception("Invitation not found");
          }
          
          if (!$invitation->isPending()) {
              throw new Exception("Only pending invitations can be resent");
          }
          
          // Update the expiration date
          $newInvitation = $this->createInvitation(
              $invitation->getTeam(),
              $invitation->getEmail(),
              $invitation->getRole(),
              $invitation->getInvitedBy()
          );
          
          // Revoke the old invitation
          $invitation->revoke();
          
          return $newInvitation;
      }
  }
  
  // Simple User and Team classes for demonstration
  class User {
      private int $id;
      private string $name;
      private string $email;
      
      public function __construct(int $id, string $name, string $email) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
      }
      
      public function getId(): int {
          return $this->id;
      }
      
      public function getName(): string {
          return $this->name;
      }
      
      public function getEmail(): string {
          return $this->email;
      }
  }
  
  class Team {
      private int $id;
      private string $name;
      private array $members = [];
      private array $permissions = [];
      
      public function __construct(int $id, string $name) {
          $this->id = $id;
          $this->name = $name;
          
          // Add default permissions
          $this->permissions['team:invite'] = true;
      }
      
      public function getId(): int {
          return $this->id;
      }
      
      public function getName(): string {
          return $this->name;
      }
      
      public function addMember(User $user, string $role): self {
          $this->members[$user->getId()] = [
              'user' => $user,
              'role' => $role,
          ];
          
          echo "{$user->getName()} added to team \"{$this->name}\" as {$role}\n";
          
          return $this;
      }
      
      public function userHasPermission(User $user, string $permission): bool {
          // For simplicity, we'll assume all users have all permissions
          return isset($this->permissions[$permission]) && $this->permissions[$permission];
      }
  }
  
  // Example usage
  
  // Create users
  $admin = new User(1, 'Admin User', 'admin@example.com');
  $user1 = new User(2, 'John Doe', 'john@example.com');
  $user2 = new User(3, 'Jane Smith', 'jane@example.com');
  
  // Create a team
  $team = new Team(1, 'Development Team');
  $team->addMember($admin, 'admin');
  
  // Create invitation manager
  $invitationManager = new TeamInvitationManager();
  
  // Create invitations
  echo "Creating invitations...\n";
  $invitation1 = $invitationManager->createInvitation($team, 'john@example.com', 'member', $admin);
  $invitation2 = $invitationManager->createInvitation($team, 'jane@example.com', 'member', $admin);
  
  // Display invitation details
  echo "\nInvitation details:\n";
  echo $invitation1->getDetails();
  
  // Accept an invitation
  echo "\nAccepting invitation...\n";
  $invitation1->accept($user1);
  
  // Decline an invitation
  echo "\nDeclining invitation...\n";
  $invitation2->decline($user2);
  
  // Try to accept a declined invitation
  echo "\nTrying to accept a declined invitation...\n";
  try {
      $invitation2->accept($user2);
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Create an invitation with a short expiration
  echo "\nCreating invitation with short expiration...\n";
  $shortExpiration = new DateInterval('PT10S'); // 10 seconds
  $invitation3 = $invitationManager->createInvitation(
      $team,
      'quick@example.com',
      'member',
      $admin,
      $shortExpiration
  );
  
  // Simulate time passing
  echo "Waiting for invitation to expire...\n";
  sleep(2); // In a real app, we wouldn't actually sleep
  
  // Check if the invitation is expired
  echo "Is invitation expired? " . ($invitation3->isExpired() ? "Yes\n" : "No\n");
  
  // Process expired invitations
  echo "\nProcessing expired invitations...\n";
  $expiredCount = $invitationManager->processExpiredInvitations();
  echo "Expired {$expiredCount} invitations\n";
  
  // Try to accept an expired invitation
  echo "\nTrying to accept an expired invitation...\n";
  try {
      $invitation3->accept(new User(4, 'Quick User', 'quick@example.com'));
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Resend an invitation
  echo "\nResending invitation...\n";
  try {
      $newInvitation = $invitationManager->resendInvitation($invitation3->getId());
      echo "New invitation created: " . $newInvitation->getSummary() . "\n";
  } catch (Exception $e) {
      echo "Error: " . $e->getMessage() . "\n";
  }
  
  // Get all invitations for a team
  echo "\nTeam invitations:\n";
  $teamInvitations = $invitationManager->getTeamInvitations($team);
  foreach ($teamInvitations as $invitation) {
      echo "- " . $invitation->getSummary() . "\n";
  }
explanation: |
  This example demonstrates a comprehensive team invitation system:
  
  1. **Invitation States**: Invitations can be in one of five states:
     - **Pending**: Invitation has been sent but not yet accepted or declined
     - **Accepted**: Invitation has been accepted by the recipient
     - **Declined**: Invitation has been declined by the recipient
     - **Expired**: Invitation has expired without being accepted or declined
     - **Revoked**: Invitation has been revoked by the sender
  
  2. **State Transitions**: The system enforces valid state transitions:
     - Pending → Accepted/Declined/Expired/Revoked
     - Accepted/Declined/Expired/Revoked → (no further transitions)
  
  3. **Expiration Handling**: Invitations automatically expire after a configurable period:
     - Default expiration is 7 days
     - Custom expiration periods can be specified
     - Expired invitations cannot be accepted or declined
  
  4. **Invitation Management**: The `TeamInvitationManager` provides methods to:
     - Create new invitations
     - Retrieve invitations by ID or email
     - Process expired invitations
     - Resend invitations (revoke the old one and create a new one)
  
  5. **Team Integration**: When an invitation is accepted, the user is automatically added to the team with the specified role.
  
  Key features of the implementation:
  
  - **Type Safety**: Using PHP 8.1 enums for invitation states
  - **Permission Checking**: Verifying that users have permission to invite others
  - **Duplicate Prevention**: Preventing multiple pending invitations for the same email
  - **Detailed Tracking**: Recording who sent the invitation, when it was created, and when it was responded to
  
  In a real Laravel application:
  - Invitations would be stored in a database table
  - Emails would be sent using Laravel's mail system
  - The system would integrate with Laravel's authentication and authorization
  - Background jobs would process expired invitations
challenges:
  - Add support for team invitation limits (e.g., teams can only have a certain number of pending invitations)
  - Implement a bulk invitation system that can invite multiple users at once
  - Create a method to transfer ownership of a team through a special invitation
  - Add support for invitation reminders that are sent automatically after a certain period
  - Implement an approval workflow where team admins must approve new members after they accept invitations
:::
