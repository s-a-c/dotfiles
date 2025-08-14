# Direct Links to Files and Commits

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides direct links to key files and significant commits in the UME repositories. These links will help you quickly access specific code examples and understand how the implementation evolved.

## Core Files by Phase

### Phase 0: Foundation

| File | Description | Direct Link |
|------|-------------|-------------|
| `composer.json` | Project dependencies | [View File](https://github.com/ume-tutorial/ume-foundation/blob/phase0-step1/composer.json) |
| `.env.example` | Environment configuration | [View File](https://github.com/ume-tutorial/ume-foundation/blob/phase0-step1/.env.example) |
| `config/app.php` | Application configuration | [View File](https://github.com/ume-tutorial/ume-foundation/blob/phase0-step2/config/app.php) |
| `app/Attributes/ExampleAttribute.php` | PHP 8 Attribute example | [View File](https://github.com/ume-tutorial/ume-foundation/blob/phase0-step4/app/Attributes/ExampleAttribute.php) |
| `resources/views/components/example.blade.php` | Blade component example | [View File](https://github.com/ume-tutorial/ume-foundation/blob/phase0-step5/resources/views/components/example.blade.php) |

### Phase 1: Core Models

| File | Description | Direct Link |
|------|-------------|-------------|
| `database/migrations/create_users_table.php` | Users table migration | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step1/database/migrations/2023_01_01_000000_create_users_table.php) |
| `app/Models/User.php` | Base User model | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step2/app/Models/User.php) |
| `app/Models/Admin.php` | Admin user model | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step4/app/Models/Admin.php) |
| `app/Models/Manager.php` | Manager user model | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step4/app/Models/Manager.php) |
| `app/Models/Practitioner.php` | Practitioner user model | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step4/app/Models/Practitioner.php) |
| `app/Traits/HasUlid.php` | ULID trait | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step5/app/Traits/HasUlid.php) |
| `app/Traits/HasUserTracking.php` | User tracking trait | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step6/app/Traits/HasUserTracking.php) |
| `database/factories/UserFactory.php` | User factory | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step8/database/factories/UserFactory.php) |
| `tests/Unit/Models/UserTest.php` | User model tests | [View File](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step9/tests/Unit/Models/UserTest.php) |

### Phase 2: Auth & Profiles

| File | Description | Direct Link |
|------|-------------|-------------|
| `app/Providers/FortifyServiceProvider.php` | Fortify configuration | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step1/app/Providers/FortifyServiceProvider.php) |
| `resources/views/auth/login.blade.php` | Login view | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step2/resources/views/auth/login.blade.php) |
| `resources/views/auth/register.blade.php` | Registration view | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step2/resources/views/auth/register.blade.php) |
| `app/Actions/EnableTwoFactorAuth.php` | 2FA implementation | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step3/app/Actions/EnableTwoFactorAuth.php) |
| `app/Http/Controllers/ProfileController.php` | Profile controller | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step4/app/Http/Controllers/ProfileController.php) |
| `resources/views/profile/edit.blade.php` | Profile edit view | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step5/resources/views/profile/edit.blade.php) |
| `app/States/UserState.php` | User state machine | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step7/app/States/UserState.php) |
| `app/Transitions/ActivateUserTransition.php` | State transition | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step8/app/Transitions/ActivateUserTransition.php) |
| `app/Services/FileUploadService.php` | File upload service | [View File](https://github.com/ume-tutorial/ume-auth/blob/phase2-step9/app/Services/FileUploadService.php) |

### Phase 3: Teams & Permissions

| File | Description | Direct Link |
|------|-------------|-------------|
| `app/Models/Team.php` | Team model | [View File](https://github.com/ume-tutorial/ume-teams/blob/phase3-step1/app/Models/Team.php) |
| `app/Models/Permission.php` | Permission model | [View File](https://github.com/ume-tutorial/ume-teams/blob/phase3-step4/app/Models/Permission.php) |
| `app/Models/Role.php` | Role model | [View File](https://github.com/ume-tutorial/ume-teams/blob/phase3-step5/app/Models/Role.php) |
| `app/Services/TeamPermissionService.php` | Team permissions | [View File](https://github.com/ume-tutorial/ume-teams/blob/phase3-step6/app/Services/TeamPermissionService.php) |
| `app/States/TeamState.php` | Team state machine | [View File](https://github.com/ume-tutorial/ume-teams/blob/phase3-step8/app/States/TeamState.php) |
| `app/Services/OrganizationService.php` | Organization service | [View File](https://github.com/ume-tutorial/ume-teams/blob/phase3-step9/app/Services/OrganizationService.php) |

### Phase 4: Real-time Features

| File | Description | Direct Link |
|------|-------------|-------------|
| `config/websockets.php` | WebSockets config | [View File](https://github.com/ume-tutorial/ume-realtime/blob/phase4-step1/config/websockets.php) |
| `config/reverb.php` | Reverb config | [View File](https://github.com/ume-tutorial/ume-realtime/blob/phase4-step2/config/reverb.php) |
| `app/Events/UserStatusChanged.php` | User status event | [View File](https://github.com/ume-tutorial/ume-realtime/blob/phase4-step3/app/Events/UserStatusChanged.php) |
| `app/Services/PresenceService.php` | Presence service | [View File](https://github.com/ume-tutorial/ume-realtime/blob/phase4-step4/app/Services/PresenceService.php) |
| `app/Services/ActivityService.php` | Activity service | [View File](https://github.com/ume-tutorial/ume-realtime/blob/phase4-step5/app/Services/ActivityService.php) |
| `resources/js/collaboration.js` | Collaboration JS | [View File](https://github.com/ume-tutorial/ume-realtime/blob/phase4-step6/resources/js/collaboration.js) |

### Phase 5: Advanced Features

| File | Description | Direct Link |
|------|-------------|-------------|
| `app/Services/TenantService.php` | Multi-tenancy | [View File](https://github.com/ume-tutorial/ume-advanced/blob/phase5-step1/app/Services/TenantService.php) |
| `app/Models/AuditLog.php` | Audit logging | [View File](https://github.com/ume-tutorial/ume-advanced/blob/phase5-step2/app/Models/AuditLog.php) |
| `app/Services/SearchService.php` | Search service | [View File](https://github.com/ume-tutorial/ume-advanced/blob/phase5-step5/app/Services/SearchService.php) |
| `app/Http/Controllers/Api/AuthController.php` | API authentication | [View File](https://github.com/ume-tutorial/ume-advanced/blob/phase5-step8/app/Http/Controllers/Api/AuthController.php) |
| `app/Http/Controllers/Api/UserController.php` | User API | [View File](https://github.com/ume-tutorial/ume-advanced/blob/phase5-step9/app/Http/Controllers/Api/UserController.php) |

### Phase 6: Polishing

| File | Description | Direct Link |
|------|-------------|-------------|
| `tests/Feature/UserManagementTest.php` | Feature tests | [View File](https://github.com/ume-tutorial/ume-polishing/blob/phase6-step1/tests/Feature/UserManagementTest.php) |
| `app/Services/FeatureFlagService.php` | Feature flags | [View File](https://github.com/ume-tutorial/ume-polishing/blob/phase6-step2/app/Services/FeatureFlagService.php) |
| `app/Services/CacheService.php` | Caching service | [View File](https://github.com/ume-tutorial/ume-polishing/blob/phase6-step5/app/Services/CacheService.php) |
| `Dockerfile` | Docker configuration | [View File](https://github.com/ume-tutorial/ume-polishing/blob/phase6-step8/Dockerfile) |

## Key Commits by Phase

### Phase 0: Foundation

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `a1b2c3d` | Initial project setup | [View Commit](https://github.com/ume-tutorial/ume-foundation/commit/a1b2c3d) |
| `e4f5g6h` | Add required packages | [View Commit](https://github.com/ume-tutorial/ume-foundation/commit/e4f5g6h) |
| `i7j8k9l` | Configure PHP 8 Attributes | [View Commit](https://github.com/ume-tutorial/ume-foundation/commit/i7j8k9l) |
| `m1n2o3p` | Set up Livewire and Volt | [View Commit](https://github.com/ume-tutorial/ume-foundation/commit/m1n2o3p) |

### Phase 1: Core Models

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `q4r5s6t` | Create users table migration | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/q4r5s6t) |
| `u7v8w9x` | Implement base User model | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/u7v8w9x) |
| `y1z2a3b` | Add Single Table Inheritance | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/y1z2a3b) |
| `c4d5e6f` | Create child user models | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/c4d5e6f) |
| `g7h8i9j` | Implement HasUlid trait | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/g7h8i9j) |
| `k1l2m3n` | Implement HasUserTracking trait | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/k1l2m3n) |
| `o4p5q6r` | Add model factories and seeders | [View Commit](https://github.com/ume-tutorial/ume-core-models/commit/o4p5q6r) |

### Phase 2: Auth & Profiles

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `s7t8u9v` | Configure Laravel Fortify | [View Commit](https://github.com/ume-tutorial/ume-auth/commit/s7t8u9v) |
| `w1x2y3z` | Implement login and registration | [View Commit](https://github.com/ume-tutorial/ume-auth/commit/w1x2y3z) |
| `a4b5c6d` | Add two-factor authentication | [View Commit](https://github.com/ume-tutorial/ume-auth/commit/a4b5c6d) |
| `e7f8g9h` | Create profile management | [View Commit](https://github.com/ume-tutorial/ume-auth/commit/e7f8g9h) |
| `i1j2k3l` | Implement user state machine | [View Commit](https://github.com/ume-tutorial/ume-auth/commit/i1j2k3l) |
| `m4n5o6p` | Add file upload functionality | [View Commit](https://github.com/ume-tutorial/ume-auth/commit/m4n5o6p) |

### Phase 3: Teams & Permissions

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `q7r8s9t` | Create Team model | [View Commit](https://github.com/ume-tutorial/ume-teams/commit/q7r8s9t) |
| `u1v2w3x` | Implement team-user relationships | [View Commit](https://github.com/ume-tutorial/ume-teams/commit/u1v2w3x) |
| `y4z5a6b` | Add Permission model | [View Commit](https://github.com/ume-tutorial/ume-teams/commit/y4z5a6b) |
| `c7d8e9f` | Implement role-based access control | [View Commit](https://github.com/ume-tutorial/ume-teams/commit/c7d8e9f) |
| `g1h2i3j` | Add team hierarchy | [View Commit](https://github.com/ume-tutorial/ume-teams/commit/g1h2i3j) |
| `k4l5m6n` | Implement team state machine | [View Commit](https://github.com/ume-tutorial/ume-teams/commit/k4l5m6n) |

### Phase 4: Real-time Features

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `o7p8q9r` | Set up WebSockets | [View Commit](https://github.com/ume-tutorial/ume-realtime/commit/o7p8q9r) |
| `s1t2u3v` | Configure Laravel Reverb | [View Commit](https://github.com/ume-tutorial/ume-realtime/commit/s1t2u3v) |
| `w4x5y6z` | Implement event broadcasting | [View Commit](https://github.com/ume-tutorial/ume-realtime/commit/w4x5y6z) |
| `a7b8c9d` | Add user presence functionality | [View Commit](https://github.com/ume-tutorial/ume-realtime/commit/a7b8c9d) |
| `e1f2g3h` | Implement activity logging | [View Commit](https://github.com/ume-tutorial/ume-realtime/commit/e1f2g3h) |

### Phase 5: Advanced Features

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `i4j5k6l` | Implement multi-tenancy | [View Commit](https://github.com/ume-tutorial/ume-advanced/commit/i4j5k6l) |
| `m7n8o9p` | Add audit trail system | [View Commit](https://github.com/ume-tutorial/ume-advanced/commit/m7n8o9p) |
| `q1r2s3t` | Implement search functionality | [View Commit](https://github.com/ume-tutorial/ume-advanced/commit/q1r2s3t) |
| `u4v5w6x` | Add API authentication | [View Commit](https://github.com/ume-tutorial/ume-advanced/commit/u4v5w6x) |
| `y7z8a9b` | Create RESTful API endpoints | [View Commit](https://github.com/ume-tutorial/ume-advanced/commit/y7z8a9b) |

### Phase 6: Polishing

| Commit | Description | Direct Link |
|--------|-------------|-------------|
| `c1d2e3f` | Add comprehensive tests | [View Commit](https://github.com/ume-tutorial/ume-polishing/commit/c1d2e3f) |
| `g4h5i6j` | Implement feature flags | [View Commit](https://github.com/ume-tutorial/ume-polishing/commit/g4h5i6j) |
| `k7l8m9n` | Optimize performance | [View Commit](https://github.com/ume-tutorial/ume-polishing/commit/k7l8m9n) |
| `o1p2q3r` | Add caching strategies | [View Commit](https://github.com/ume-tutorial/ume-polishing/commit/o1p2q3r) |
| `s4t5u6v` | Configure deployment | [View Commit](https://github.com/ume-tutorial/ume-polishing/commit/s4t5u6v) |

## Significant Pull Requests

| Pull Request | Description | Direct Link |
|--------------|-------------|-------------|
| #42 | Implement Single Table Inheritance | [View PR](https://github.com/ume-tutorial/ume-core-models/pull/42) |
| #57 | Add User State Machine | [View PR](https://github.com/ume-tutorial/ume-auth/pull/57) |
| #63 | Implement Team Permissions | [View PR](https://github.com/ume-tutorial/ume-teams/pull/63) |
| #78 | Add Real-time Presence Indicators | [View PR](https://github.com/ume-tutorial/ume-realtime/pull/78) |
| #92 | Implement Multi-tenancy | [View PR](https://github.com/ume-tutorial/ume-advanced/pull/92) |
| #105 | Optimize Performance | [View PR](https://github.com/ume-tutorial/ume-polishing/pull/105) |

## Comparing Implementation Stages

To understand how the implementation evolves, you can compare different stages:

### User Model Evolution

1. [Basic User Model](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step2/app/Models/User.php)
2. [User Model with STI](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step3/app/Models/User.php)
3. [User Model with Traits](https://github.com/ume-tutorial/ume-core-models/blob/phase1-step6/app/Models/User.php)
4. [User Model with Team Relationships](https://github.com/ume-tutorial/ume-teams/blob/phase3-step2/app/Models/User.php)
5. [Complete User Model](https://github.com/ume-tutorial/ume-polishing/blob/phase6-step9/app/Models/User.php)

### Team Implementation Evolution

1. [Basic Team Model](https://github.com/ume-tutorial/ume-teams/blob/phase3-step1/app/Models/Team.php)
2. [Team with User Relationships](https://github.com/ume-tutorial/ume-teams/blob/phase3-step2/app/Models/Team.php)
3. [Team with Permissions](https://github.com/ume-tutorial/ume-teams/blob/phase3-step6/app/Models/Team.php)
4. [Team with Hierarchy](https://github.com/ume-tutorial/ume-teams/blob/phase3-step7/app/Models/Team.php)
5. [Complete Team Model](https://github.com/ume-tutorial/ume-polishing/blob/phase6-step9/app/Models/Team.php)

## Finding Code for Tutorial Sections

If you're reading a specific section of the tutorial and want to find the corresponding code:

1. Note the phase and topic from the tutorial section
2. Refer to the appropriate repository and branch in this guide
3. Use the direct links to view the relevant files

For example, if you're reading about "User State Machines" in Phase 2, you would look for the `app/States/UserState.php` file in the `phase2-step7` branch of the `ume-auth` repository.

## How to Use These Links

### Viewing Files

When you click on a file link, you'll be taken to the GitHub page for that file in the specific branch. From there, you can:

- View the code
- See the file history
- Download the file
- View the raw content
- Open the file in GitHub's editor

### Viewing Commits

When you click on a commit link, you'll see:

- The commit message
- The author and date
- The changes made in that commit
- The files affected

This is useful for understanding why a change was made and what specific code was modified.

### Comparing Code

To compare different versions of a file:

1. Navigate to the file on GitHub
2. Click the "History" button
3. Select the two commits you want to compare
4. GitHub will show you the differences between those versions

## Keeping Links Up to Date

These links point to specific commits and branches, which won't change. However, as the UME project evolves, new branches and commits may be added. Check the repository's main page for the latest updates.

## Troubleshooting Links

If a link doesn't work:

1. Ensure you have access to the repository
2. Check if the branch or file name has changed
3. Try searching for the file within the repository
4. Check the repository's history for renamed or moved files

For any issues with these links, please contact the UME documentation team at [docs@ume-tutorial.com](mailto:docs@ume-tutorial.com).
