 # PRD: Enhance Team Model Guide

 ## 1. Introduction

 ### 1.1 Purpose

 The purpose of this PRD is to refactor and enhance the existing Team Model Guide
 to enforce stricter hierarchy rules and invitation capabilities. Why? Because
 we love structure and despise chaos – especially root-level team anarchy.

 ### 1.2 Scope

 This document defines requirements for:
 - Default team creation hierarchy
 - Root-level team creation restrictions
 - Invitation subteam creation controls
 - Mandatory invitation target selection

 For those who prefer living in color and boxes instead of walls of text, feast
 your eyes on this shiny flowchart:

 ```mermaid
 flowchart TD
    A["Inviter<br/>Team Member"] -->|Create Team| B[New Subteam]
     C[Super-admin] -->|Create Root Team| D[Root Team]
     E[Regular User] -.->|Direct Call| X[Forbidden]
     classDef inviter fill:#f96,stroke:#333,color:#000
     classDef superAdmin fill:#6cf,stroke:#333,color:#000
     classDef forbidden fill:#f66,stroke:#333,stroke-dasharray:5,5,color:#000
     class A inviter
     class B inviter
     class C superAdmin
     class D superAdmin
     class E forbidden
     class X forbidden
 ```

 ## 2. References

 ### 2.1 Existing Documentation

- [Team Model Guide](../docs/guides/models/TeamModelGuide.md)
- [Team Model Guide Directory](../docs/guides/team_model/000-index.md)

 ## 3. Requirements

 ### 3.1 Default Team Creation Hierarchy

 #### 3.1.1 Description

 By default, any new team is created as a child of the team belonging to the
 user who initiates the creation (the inviter). No orphaned teams allowed.

 #### 3.1.2 Rationale
 
 - Ensures organizational structure remains intact.
 - Prevents orphaned teams wandering aimlessly in the void.

 #### 3.1.3 Acceptance Criteria

 - When user X (member of Team A) creates a team, the new team's `parent_id`
   must equal A.id.
 - If no inviter context exists (e.g., direct API call), the system
   rejects non-super-admin requests with a 403 error.

 ### 3.2 Root-Level Team Creation Restrictions

 #### 3.2.1 Description

 Only users sporting the `super-admin` cape can create teams with `parent_id = null`.
 Because let's face it, superheroes should have exclusive privileges.

 #### 3.2.2 Acceptance Criteria

 - Non-super-admins attempting to set `parent_id` to null receive a 403
   (Forbidden) error.
 - Super-admins breeze through and spawn root-level teams via standard flow.

 ### 3.3 Invitation Subteam Creation Controls

 #### 3.3.1 Description

 Team owners may disable the `allow_subteams` flag on invitations to prevent
 invitees from spawning their own sub-squads (yes, teenager metaphor intended).

 #### 3.3.2 Acceptance Criteria

 - The invitation payload includes a boolean `allow_subteams` (default: true).
 - If `allow_subteams = false`, the invitee’s `allowsSubteams()` method returns false.

 ### 3.4 Mandatory Invitation Target Selection

 #### 3.4.1 Description

 Forms and APIs must demand a specific `team_id` for each invitation.
 No more mystery invites floating in the void.

 #### 3.4.2 Acceptance Criteria

 - Invitation endpoint rejects requests missing `team_id`.
 - UI highlights team selection as a mandatory dropdown with a friendly red asterisk.

 ## 4. User Stories

 ### 4.1 As a team owner

 I want to disable subteam creation for an invitee so that I prevent
 off-structure team growth.

 ### 4.2 As a non-super-admin user

 I want to create teams only under my existing teams so that I cannot
 mess up the root organization and cause chaos.

 ### 4.3 As a super-admin

 I want to create new root-level teams so that I can bootstrap top-level
 departments like the overlord I am (in the best sense).

 ## 5. Non-functional Requirements

 ### 5.1 Security

 - All hierarchy checks must be enforced server-side.
 - Permissions must be covered by unit and feature tests.

 ### 5.2 Usability

 - Invitation UI must clearly indicate mandatory selection and subteam controls.
 - Use friendly tooltips and colored highlights to guide users.

 ## 6. Dependencies

- Eloquent team model enhancements ([see current implementation](../docs/guides/models/TeamModelGuide.md)).
 - Frontend form updates in the team management module.

 ## 7. Out of Scope

 - Bulk invitation workflows.
 - Cross-application team federation.

 ## 8. Glossary

 - **Inviter**: The user initiating team creation or sending an invitation.
 - **Super-admin**: A user with the highest privileges, capable of creating
   root-level teams.
 - **allow_subteams**: A boolean flag controlling subteam creation rights.
 
 ## 9. Implementation Plan

 ### 9.1 Plan Document

 For the deeply detailed breakdown of tasks, behold the [Plan Document](../010-team-model-implementation/005-plan.md). Essentially, it's our holy grail of steps needed to slay the implementation dragon.

 ### 9.2 Visual Plan Flowchart

 For the visual learners among us (you know who you are), here's a shiny flowchart of the key phases, complete with bold colors to soothe your eyes:

 ```mermaid
 flowchart LR
     A["1. Model & DB Setup"]:::phase
     B["2. Logic & Policies"]:::phase
     C["3. Controllers & Routes"]:::phase
     D["4. Validation & Requests"]:::phase
     E["5. Testing"]:::phase
     F["6. Frontend Integration"]:::phase
     A --> B --> C --> D --> E --> F
     classDef phase fill:#b3e5fc,stroke:#0277bd,stroke-width:2px,font-weight:bold,color:#000;
 ```

 ### 9.3 Timeline Gantt Chart

 And because we love color-coded timelines (who doesn't?), here's our glittering Gantt chart:

 ```mermaid
 %%{init: {"themeVariables": {"textColor":"#000000","axisTextColor":"#000000","sectionTextColor":"#000000","taskTextColor":"#000000"}}}%%
 gantt
     title Team Model Enhancement Milestones
     dateFormat  YYYY-MM-DD
     axisFormat  %m/%d
     section Milestones
     Planning Complete              :done,    m1, 2025-04-18, 0d
     Model & Migration Setup        :active,  m2, 2025-04-20, 1d
     Business Logic & Relationships :         m3, 2025-04-22, 1d
     Authorization                  :         m4, 2025-04-23, 1d
     Controllers & Routes           :         m5, 2025-04-24, 1d
     Validation & Requests          :crit,    m6, 2025-04-24, 0d
     Testing                         :         m7, 2025-04-25, 1d
     Frontend Integration           :         m8, 2025-04-26, 1d
     Documentation Update           :         m9, 2025-04-27, 1d
     Final Review & Merge           :         m10,2025-04-28, 1d
 ```

 ## 10. Milestones

 ### 10.1 Milestones Document

 All the glorious milestones are chronicled in the [Milestones](../010-team-model-implementation/010-milestones.md) file. For your convenience, here's a quick snapshot:

 | Milestone                         | Description                                     | Target Date   | Status   |
 |-----------------------------------|-------------------------------------------------|---------------|----------|
 | Planning Complete                 | PRD review & implementation plan approved       | 2025-04-18    | Done     |
 | Model & Migration Setup           | Team & Invitation models + migrations           | 2025-04-20    | Pending  |
 | Business Logic & Relationships    | Implement team hierarchy & invitation logic     | 2025-04-22    | Pending  |
 | Authorization                     | Policies and service provider registration      | 2025-04-23    | Pending  |
 | Controllers & Routes              | RESTful endpoints for teams & invitations       | 2025-04-24    | Pending  |
 | Validation & Requests             | Form Request classes & validation rules         | 2025-04-24    | Pending  |
 | Testing                           | Unit & feature tests                            | 2025-04-25    | Pending  |
 | Frontend Integration              | Volt SFC with Folio routing + InertiaJS + React | 2025-04-26    | Pending  |
 | Documentation Update              | Sync docs/guides with actual implementation     | 2025-04-27    | Pending  |
 | Final Review & Merge              | Code review, adjustments, and merge to main     | 2025-04-28    | Pending  |

 ## 11. Progress Tracking

 ### 11.1 Progress Document

 Keep your finger on the pulse with the [Progress Tracker](../010-team-model-implementation/015-progress.md). Here's where we mark our victories (and occasional stumbles):

 - Last updated: 2025-04-18
