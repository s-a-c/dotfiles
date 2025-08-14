# Branch Information for Implementation Phases

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides detailed information about the branch structure in the UME repositories. Understanding this structure will help you navigate the codebase and find the specific implementation stage you're looking for.

## Branching Strategy Overview

The UME repositories follow a structured branching strategy designed to:

1. Provide clear progression through implementation phases
2. Allow easy navigation to specific implementation steps
3. Maintain stable reference points for each tutorial section
4. Support parallel development of features
5. Facilitate contributions from the community

## Main Branches

Each repository contains these primary branches:

| Branch | Purpose | Stability |
|--------|---------|-----------|
| `main` | Production-ready code | Stable |
| `develop` | Integration branch for features | Mostly stable |
| `staging` | Pre-release testing | Varies |

## Phase Branches

Each implementation phase has a dedicated branch:

| Branch | Phase | Description |
|--------|-------|-------------|
| `phase0` | Foundation | Basic setup and configuration |
| `phase1` | Core Models | User models and STI implementation |
| `phase2` | Auth & Profiles | Authentication and profile management |
| `phase3` | Teams & Permissions | Team and permission implementation |
| `phase4` | Real-time Features | WebSocket and real-time features |
| `phase5` | Advanced Features | Advanced features and optimizations |
| `phase6` | Polishing | Final polishing and refinements |

## Step Branches

Each phase is broken down into implementation steps, with a branch for each step:

| Branch Pattern | Description | Example |
|----------------|-------------|---------|
| `phase{n}-step{m}` | Step m of Phase n | `phase1-step3` |

## Feature Branches

Feature branches are used for developing specific features:

| Branch Pattern | Description | Example |
|----------------|-------------|---------|
| `feature/{name}` | Feature development | `feature/user-tracking` |
| `bugfix/{name}` | Bug fix | `bugfix/auth-redirect` |
| `refactor/{name}` | Code refactoring | `refactor/model-traits` |
| `docs/{name}` | Documentation updates | `docs/api-reference` |

## Branch Relationships

The following diagram illustrates the relationships between branches:

```
main
 ├── phase0
 │    ├── phase0-step1
 │    ├── phase0-step2
 │    └── phase0-step3
 ├── phase1
 │    ├── phase1-step1
 │    ├── phase1-step2
 │    └── phase1-step3
 ├── phase2
 │    ├── phase2-step1
 │    ├── phase2-step2
 │    └── phase2-step3
 └── develop
      ├── feature/user-tracking
      ├── feature/team-permissions
      └── bugfix/auth-redirect
```

## Phase 0: Foundation Branches

The Foundation phase establishes the basic structure and configuration:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase0-step1` | Project setup | `composer.json`, `.env.example` |
| `phase0-step2` | Package installation | `config/app.php` |
| `phase0-step3` | Configuration | Various config files |
| `phase0-step4` | PHP 8 Attributes setup | `app/Attributes/` |
| `phase0-step5` | Livewire/Volt setup | `resources/views/components/` |

## Phase 1: Core Models Branches

The Core Models phase implements the user model structure:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase1-step1` | Database design | `database/migrations/` |
| `phase1-step2` | User model | `app/Models/User.php` |
| `phase1-step3` | Single Table Inheritance | `app/Models/User.php` |
| `phase1-step4` | User types | `app/Models/Admin.php`, etc. |
| `phase1-step5` | HasUlid trait | `app/Traits/HasUlid.php` |
| `phase1-step6` | HasUserTracking trait | `app/Traits/HasUserTracking.php` |
| `phase1-step7` | Child models | Various model files |
| `phase1-step8` | Model factories | `database/factories/` |
| `phase1-step9` | Model tests | `tests/Unit/Models/` |

## Phase 2: Auth & Profiles Branches

The Auth & Profiles phase implements authentication and user profiles:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase2-step1` | Fortify setup | `app/Providers/FortifyServiceProvider.php` |
| `phase2-step2` | Login/registration | `resources/views/auth/` |
| `phase2-step3` | Two-factor auth | `app/Actions/EnableTwoFactorAuth.php` |
| `phase2-step4` | Profile management | `app/Http/Controllers/ProfileController.php` |
| `phase2-step5` | Profile UI | `resources/views/profile/` |
| `phase2-step6` | State machines | `app/States/` |
| `phase2-step7` | Account states | `app/States/UserState.php` |
| `phase2-step8` | State transitions | `app/Transitions/` |
| `phase2-step9` | File uploads | `app/Services/FileUploadService.php` |

## Phase 3: Teams & Permissions Branches

The Teams & Permissions phase implements team management and permissions:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase3-step1` | Team model | `app/Models/Team.php` |
| `phase3-step2` | Team relationships | `app/Models/Team.php`, `app/Models/User.php` |
| `phase3-step3` | Team management UI | `resources/views/teams/` |
| `phase3-step4` | Permission model | `app/Models/Permission.php` |
| `phase3-step5` | Role-based access | `app/Models/Role.php` |
| `phase3-step6` | Team permissions | `app/Services/TeamPermissionService.php` |
| `phase3-step7` | Team hierarchy | `app/Models/Team.php` |
| `phase3-step8` | Team state machine | `app/States/TeamState.php` |
| `phase3-step9` | Organization lifecycle | `app/Services/OrganizationService.php` |

## Phase 4: Real-time Features Branches

The Real-time Features phase implements WebSockets and real-time functionality:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase4-step1` | WebSockets setup | `config/websockets.php` |
| `phase4-step2` | Reverb setup | `config/reverb.php` |
| `phase4-step3` | Event broadcasting | `app/Events/` |
| `phase4-step4` | User presence | `app/Services/PresenceService.php` |
| `phase4-step5` | Activity logging | `app/Services/ActivityService.php` |
| `phase4-step6` | Real-time collaboration | `resources/js/collaboration.js` |

## Phase 5: Advanced Features Branches

The Advanced Features phase implements more sophisticated functionality:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase5-step1` | Multi-tenancy | `app/Services/TenantService.php` |
| `phase5-step2` | Audit trails | `app/Models/AuditLog.php` |
| `phase5-step3` | Compliance features | `app/Services/ComplianceService.php` |
| `phase5-step4` | Data retention | `app/Services/DataRetentionService.php` |
| `phase5-step5` | Search implementation | `app/Services/SearchService.php` |
| `phase5-step6` | User analytics | `app/Services/AnalyticsService.php` |
| `phase5-step7` | Reporting | `app/Services/ReportingService.php` |
| `phase5-step8` | API authentication | `app/Http/Controllers/Api/AuthController.php` |
| `phase5-step9` | API endpoints | `app/Http/Controllers/Api/` |

## Phase 6: Polishing Branches

The Polishing phase refines and optimizes the implementation:

| Branch | Description | Key Files |
|--------|-------------|-----------|
| `phase6-step1` | Testing | `tests/` |
| `phase6-step2` | Feature flags | `app/Services/FeatureFlagService.php` |
| `phase6-step3` | UI polish | `resources/css/`, `resources/js/` |
| `phase6-step4` | Performance optimization | Various files |
| `phase6-step5` | Caching strategies | `app/Services/CacheService.php` |
| `phase6-step6` | Database optimization | Database-related files |
| `phase6-step7` | Scaling considerations | Various files |
| `phase6-step8` | Deployment strategies | `Dockerfile`, CI/CD files |
| `phase6-step9` | Database migrations | `database/migrations/` |

## Working with Branches

### Viewing Available Branches

To see all available branches:

```bash
git branch -a
```

### Checking Out a Branch

To switch to a specific branch:

```bash
git checkout phase2-step3
```

### Creating a New Branch

To create a new branch based on an existing one:

```bash
git checkout -b feature/my-feature phase2-step3
```

### Comparing Branches

To see the differences between branches:

```bash
git diff phase1-step1 phase1-step2
```

### Finding the Right Branch

If you're following the tutorial and want to find the branch that corresponds to a specific section:

1. Identify the phase and step from the tutorial section
2. Check out the corresponding branch
3. If you're between steps, choose the earlier step branch

## Branch Naming Conventions

When creating your own branches, follow these conventions:

- Use lowercase letters and hyphens
- Start feature branches with `feature/`
- Start bug fix branches with `bugfix/`
- Start refactoring branches with `refactor/`
- Start documentation branches with `docs/`
- Use descriptive names that indicate the purpose

Example: `feature/team-invitation-system`

## Tagging Strategy

In addition to branches, repositories use tags to mark significant points:

| Tag Pattern | Description | Example |
|-------------|-------------|---------|
| `v{major}.{minor}.{patch}` | Version releases | `v1.2.3` |
| `phase{n}-complete` | Completed phase | `phase2-complete` |
| `tutorial-{section}` | Tutorial section reference | `tutorial-auth-profiles` |

To list all tags:

```bash
git tag -l
```

To check out a specific tag:

```bash
git checkout tags/phase2-complete
```

## Contributing to Branches

When contributing to the UME repositories:

1. Create a feature branch from the appropriate phase branch
2. Make your changes
3. Submit a pull request to the original phase branch
4. Include a clear description of your changes

For more details, see the [Contributing Guidelines](020-contributing-guidelines.md).

## Branch Protection

The following branches are protected and require pull requests for changes:

- `main`
- `develop`
- `phase{n}` (all phase branches)

Direct pushes to these branches are not allowed.

## Finding Changes Between Steps

To see what changed between steps:

```bash
git log --oneline phase1-step1..phase1-step2
```

To see the actual code changes:

```bash
git diff phase1-step1..phase1-step2
```

## Troubleshooting Branch Issues

### Branch Not Found

If a branch is not found:

1. Ensure you have the latest updates: `git fetch --all`
2. Check if the branch exists remotely: `git branch -a`
3. If it exists remotely, create a local tracking branch: `git checkout -b phase1-step1 origin/phase1-step1`

### Conflicts When Switching Branches

If you encounter conflicts when switching branches:

1. Commit or stash your changes: `git stash`
2. Switch to the desired branch: `git checkout phase2-step3`
3. Apply your stashed changes if needed: `git stash pop`

## Additional Resources

- [Git Branching Documentation](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/)
- [UME Repository Guidelines](020-repository-guidelines.md)
