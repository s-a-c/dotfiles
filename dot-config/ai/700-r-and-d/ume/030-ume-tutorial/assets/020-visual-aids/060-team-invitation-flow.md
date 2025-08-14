# Team Invitation Flow

<link rel="stylesheet" href="../css/styles.css">
<link rel="stylesheet" href="../css/ume-docs-enhancements.css">
<script src="../js/ume-docs-enhancements.js"></script>

## Overview

This visual aid illustrates the team invitation flow in the UME system, showing how users are invited to teams and how those invitations are processed through various states.

## Invitation Process Flow

The following sequence diagram shows the complete team invitation process:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
sequenceDiagram
    actor TeamAdmin
    actor InvitedUser
    participant TeamUI
    participant InvitationController
    participant TeamModel
    participant InvitationModel
    participant MailService
    participant InvitationUI
    
    %% Invitation Creation
    TeamAdmin->>TeamUI: Navigate to team members
    TeamUI->>TeamAdmin: Show team members page
    TeamAdmin->>TeamUI: Click "Invite Member"
    TeamUI->>TeamAdmin: Show invitation form
    TeamAdmin->>TeamUI: Enter email and role
    TeamUI->>InvitationController: POST /teams/{team}/invitations
    InvitationController->>TeamModel: findOrFail(teamId)
    TeamModel-->>InvitationController: Team instance
    InvitationController->>InvitationController: authorize('inviteToTeam', team)
    InvitationController->>InvitationModel: create(team, email, role)
    InvitationModel-->>InvitationController: Invitation instance
    InvitationController->>MailService: send(TeamInvitationMail)
    MailService-->>InvitationController: success
    InvitationController-->>TeamUI: 200 OK with invitation
    TeamUI-->>TeamAdmin: Show success message
    
    %% Invitation Acceptance
    InvitedUser->>InvitationUI: Click invitation link in email
    InvitationUI->>InvitationController: GET /invitations/{token}
    InvitationController->>InvitationModel: findByToken(token)
    InvitationModel-->>InvitationController: Invitation instance
    InvitationController->>InvitationController: validateInvitation(invitation)
    
    alt Invalid or expired invitation
        InvitationController-->>InvitationUI: Redirect with error
        InvitationUI-->>InvitedUser: Show error message
    else Valid invitation
        InvitationController-->>InvitationUI: Show acceptance form
        InvitationUI-->>InvitedUser: Display acceptance form
        
        InvitedUser->>InvitationUI: Click "Accept Invitation"
        InvitationUI->>InvitationController: POST /invitations/{token}/accept
        InvitationController->>InvitationModel: findByToken(token)
        InvitationModel-->>InvitationController: Invitation instance
        
        alt User not logged in
            InvitationController-->>InvitationUI: Redirect to login
            InvitationUI-->>InvitedUser: Show login form
            InvitedUser->>InvitationUI: Login
            InvitationUI->>InvitationController: POST /invitations/{token}/accept
        end
        
        InvitationController->>InvitationModel: accept(user)
        InvitationModel->>TeamModel: addMember(user, role)
        TeamModel-->>InvitationModel: success
        InvitationModel-->>InvitationController: success
        InvitationController-->>InvitationUI: Redirect to team
        InvitationUI-->>InvitedUser: Show team dashboard
    end
    
    %% Invitation Rejection
    alt User rejects invitation
        InvitedUser->>InvitationUI: Click "Decline Invitation"
        InvitationUI->>InvitationController: POST /invitations/{token}/decline
        InvitationController->>InvitationModel: findByToken(token)
        InvitationModel-->>InvitationController: Invitation instance
        InvitationController->>InvitationModel: decline()
        InvitationModel-->>InvitationController: success
        InvitationController-->>InvitationUI: Redirect with message
        InvitationUI-->>InvitedUser: Show confirmation message
    end
    
    %% Invitation Cancellation
    alt Admin cancels invitation
        TeamAdmin->>TeamUI: View pending invitations
        TeamUI->>TeamAdmin: Show pending invitations
        TeamAdmin->>TeamUI: Click "Cancel Invitation"
        TeamUI->>InvitationController: DELETE /teams/{team}/invitations/{invitation}
        InvitationController->>TeamModel: findOrFail(teamId)
        TeamModel-->>InvitationController: Team instance
        InvitationController->>InvitationController: authorize('cancelInvitation', team)
        InvitationController->>InvitationModel: findOrFail(invitationId)
        InvitationModel-->>InvitationController: Invitation instance
        InvitationController->>InvitationModel: cancel()
        InvitationModel-->>InvitationController: success
        InvitationController-->>TeamUI: 200 OK
        TeamUI-->>TeamAdmin: Update invitation list
    end
```

<div class="mermaid-caption">Figure 1: Team Invitation Process Flow</div>

## Invitation State Machine

The following state diagram shows the possible states of a team invitation:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
stateDiagram-v2
    [*] --> Pending: create
    Pending --> Accepted: accept
    Pending --> Declined: decline
    Pending --> Expired: expire (14 days)
    Pending --> Cancelled: cancel
    Accepted --> [*]
    Declined --> [*]
    Expired --> [*]
    Cancelled --> [*]
```

<div class="mermaid-caption">Figure 2: Team Invitation State Machine</div>

## State Descriptions

### Pending
- **Description**: Initial state after an invitation is created
- **Capabilities**: Can be accepted, declined, cancelled, or expired
- **Transitions**:
  - To **Accepted**: When the invited user accepts the invitation
  - To **Declined**: When the invited user declines the invitation
  - To **Expired**: Automatically after 14 days if not accepted or declined
  - To **Cancelled**: When a team administrator cancels the invitation

### Accepted
- **Description**: The invitation has been accepted by the invited user
- **Capabilities**: Terminal state, no further transitions
- **Side Effects**: User is added to the team with the specified role

### Declined
- **Description**: The invitation has been declined by the invited user
- **Capabilities**: Terminal state, no further transitions
- **Side Effects**: Team administrators are notified of the decline

### Expired
- **Description**: The invitation has expired without being accepted or declined
- **Capabilities**: Terminal state, no further transitions
- **Side Effects**: Team administrators may be notified of the expiration

### Cancelled
- **Description**: The invitation has been cancelled by a team administrator
- **Capabilities**: Terminal state, no further transitions
- **Side Effects**: Invited user may be notified of the cancellation

## Data Flow Diagram

The following diagram illustrates how data flows through the team invitation system:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
graph TD
    %% Data Sources
    TeamAdmin[Team Administrator] -->|Creates invitation| InvitationForm[Invitation Form]
    InvitationForm -->|Submits data| InvitationController[Invitation Controller]
    InvitationController -->|Stores| Database[(Database)]
    Database -->|Retrieves| MailQueue[Mail Queue]
    MailQueue -->|Sends| Email[Email Service]
    Email -->|Delivers| InvitedUser[Invited User]
    InvitedUser -->|Responds to| InvitationLink[Invitation Link]
    InvitationLink -->|Processes| ResponseController[Response Controller]
    ResponseController -->|Updates| Database
    Database -->|Notifies| NotificationService[Notification Service]
    NotificationService -->|Alerts| TeamAdmin
    
    %% Data Elements
    subgraph "Invitation Data"
        InvitationData1[Team ID]
        InvitationData2[Email Address]
        InvitationData3[Role]
        InvitationData4[Token]
        InvitationData5[Expiration Date]
        InvitationData6[Status]
    end
    
    InvitationForm -.->|Collects| InvitationData1
    InvitationForm -.->|Collects| InvitationData2
    InvitationForm -.->|Collects| InvitationData3
    InvitationController -.->|Generates| InvitationData4
    InvitationController -.->|Sets| InvitationData5
    ResponseController -.->|Updates| InvitationData6
```

<div class="mermaid-caption">Figure 3: Team Invitation Data Flow</div>

## Implementation with Laravel Model States

The team invitation state machine is implemented using the `spatie/laravel-model-states` package, which provides a clean way to define states and transitions.

### State Class Hierarchy

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
classDiagram
    class State {
        <<abstract>>
        +config()
    }
    class InvitationState {
        <<abstract>>
        +getLabel()
        +getColor()
        +config()
    }
    class Pending {
        +getLabel()
        +getColor()
        +canAccept()
        +canDecline()
        +canCancel()
    }
    class Accepted {
        +getLabel()
        +getColor()
        +canAccept()
        +canDecline()
        +canCancel()
    }
    class Declined {
        +getLabel()
        +getColor()
        +canAccept()
        +canDecline()
        +canCancel()
    }
    class Expired {
        +getLabel()
        +getColor()
        +canAccept()
        +canDecline()
        +canCancel()
    }
    class Cancelled {
        +getLabel()
        +getColor()
        +canAccept()
        +canDecline()
        +canCancel()
    }
    
    State <|-- InvitationState
    InvitationState <|-- Pending
    InvitationState <|-- Accepted
    InvitationState <|-- Declined
    InvitationState <|-- Expired
    InvitationState <|-- Cancelled
```

<div class="mermaid-caption">Figure 4: Invitation State Class Hierarchy</div>

## Database Schema

The following entity relationship diagram shows the database schema for team invitations:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#f3f4f6', 'lineColor': '#6b7280', 'textColor': '#111827', 'mainBkg': '#ffffff', 'secondaryColor': '#60a5fa', 'tertiaryColor': '#e5e7eb'}}}%%
erDiagram
    TEAMS ||--o{ TEAM_INVITATIONS : "sends"
    USERS ||--o{ TEAM_INVITATIONS : "receives"
    USERS ||--o{ TEAM_INVITATIONS : "creates"
    
    TEAMS {
        uuid id
        string name
        string description
        uuid owner_id
        string status
        timestamp created_at
        timestamp updated_at
    }
    
    USERS {
        uuid id
        string name
        string email
        string type
        timestamp created_at
        timestamp updated_at
    }
    
    TEAM_INVITATIONS {
        uuid id
        uuid team_id
        string email
        string token
        string role
        string status
        uuid invited_by_id
        uuid accepted_by_id
        timestamp accepted_at
        timestamp declined_at
        timestamp expires_at
        timestamp created_at
        timestamp updated_at
    }
```

<div class="mermaid-caption">Figure 5: Team Invitation Database Schema</div>

## Related Resources

- [Team Management Implementation](../../050-implementation/040-phase3-teams-permissions/010-team-management.md)
- [Team Invitation Implementation](../../050-implementation/040-phase3-teams-permissions/020-team-invitations.md)
- [State Machine Implementation](../../050-implementation/030-phase2-auth-profile/050-user-account-states.md)
- [spatie/laravel-model-states Documentation](https://spatie.be/docs/laravel-model-states)
- [Diagram Style Guide](./diagram-style-guide.md)
