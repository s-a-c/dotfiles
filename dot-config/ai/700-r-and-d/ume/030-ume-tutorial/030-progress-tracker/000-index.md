# Progress Tracker

<link rel="stylesheet" href="../assets/css/styles.css">

We'll build the UME features in phases, broken down into smaller, manageable milestones. Mark these off as you complete them!

*(Note: [UI] indicates sections with specific framework implementations)*

<ul class="progress-tracker">
<li><span class="done">[✅]</span> <strong>Phase 0: Laying the Foundation</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>0.1:</strong> Create Laravel 12 Project (using the interactive installer,
    select <strong>Livewire Starter Kit</strong> + Volt + Pest)</li>
    <li><span class="done">[✅]</span> <strong>0.2:</strong> Configure Environment (`.env` Setup)</li>
    <li><span class="done">[✅]</span> <strong>0.3:</strong> Install FilamentPHP</li>
    <li><span class="done">[✅]</span> <strong>0.4:</strong> Install Core Backend Packages (Incl. Parental, Spatie, etc.)</li>
    <li><span class="done">[✅]</span> <strong>0.5:</strong> Publish Configurations & Run Initial Migrations</li>
    <li><span class="done">[✅]</span> <strong>0.6:</strong> Configuring Laravel Pulse Access</li>
    <li><span class="done">[✅]</span> <strong>0.7:</strong> Install Flux UI Components</li>
    <li><span class="done">[✅]</span> <strong>0.8:</strong> First Git Commit</li>
    </ul>
</li>
<li><span class="done">[✅]</span> <strong>Phase 1: Building the Core Models & Architecture (with STI)</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>1.1:</strong> Understanding Single Table Inheritance (STI) & Parental</li>
    <li><span class="done">[✅]</span> <strong>1.2:</strong> Creating the `UserType` Enum</li>
    <li><span class="done">[✅]</span> <strong>1.3:</strong> Understanding Traits & Model Events</li>
    <li><span class="done">[✅]</span> <strong>1.4:</strong> Create `HasUlid` Trait</li>
    <li><span class="done">[✅]</span> <strong>1.5:</strong> Create `HasUserTracking` Trait</li>
    <li><span class="done">[✅]</span> <strong>1.6:</strong> Understanding Database Migrations</li>
    <li><span class="done">[✅]</span> <strong>1.7:</strong> Enhance `users` Table Migration (Add `type`, Name Components, State, etc.)</li>
    <li><span class="done">[✅]</span> <strong>1.8:</strong> Understanding Eloquent Models & Relationships</li>
    <li><span class="done">[✅]</span> <strong>1.9:</strong> Update `User` Model (Apply `HasChildren`, Traits, Casts, Relationships, Name Accessor)</li>
    <li><span class="done">[✅]</span> <strong>1.10:</strong> Create Child Models (`Admin`, `Manager`, `Practitioner` with `HasParent`)</li>
    <li><span class="done">[✅]</span> <strong>1.11:</strong> Create `Team` Model & Migration</li>
    <li><span class="done">[✅]</span> <strong>1.12:</strong> Create `team_user` Pivot Table Migration</li>
    <li><span class="done">[✅]</span> <strong>1.13:</strong> Understanding Factories & Seeders</li>
    <li><span class="done">[✅]</span> <strong>1.14:</strong> Update `UserFactory` (Handle `type`, Add State Methods)</li>
    <li><span class="done">[✅]</span> <strong>1.15:</strong> Create Child Model Factories (`AdminFactory`, etc.)</li>
    <li><span class="done">[✅]</span> <strong>1.16:</strong> Create `UserSeeder` & `TeamSeeder` (Seed different user types)</li>
    <li><span class="done">[✅]</span> <strong>1.17:</strong> Update `DatabaseSeeder`</li>
    <li><span class="done">[✅]</span> <strong>1.18:</strong> Understanding The Service Layer</li>
    <li><span class="done">[✅]</span> <strong>1.19:</strong> Create `BaseService`</li>
    <li><span class="done">[✅]</span> <strong>1.20:</strong> Initial Filament Resource Setup (User with Type Management & Team)</li>
    <li><span class="done">[✅]</span> <strong>1.21:</strong> Phase 1 Git Commit</li>
    </ul>
</li>
<li><span class="next">[ ]</span> <strong>Phase 2: Authentication, Profile Basics & State Machine</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>2.1:</strong> Understanding Fortify & Authentication</li>
    <li><span class="done">[✅]</span> <strong>2.2:</strong> Configure Fortify Features</li>
    <li><span class="done">[✅]</span> <strong>2.3:</strong> Understanding Enums & State Machines</li>
    <li><span class="done">[✅]</span> <strong>2.4:</strong> Define `AccountStatus` Enum</li>
    <li><span class="done">[✅]</span> <strong>2.5:</strong> Create Account State Machine Classes</li>
    <li><span class="done">[✅]</span> <strong>2.6:</strong> Understanding Email Verification Flow</li>
    <li><span class="done">[✅]</span> <strong>2.7:</strong> Integrate State Machine with Email Verification</li>
    <li><span class="done">[✅]</span> <strong>2.8:</strong> Understanding Two-Factor Authentication (2FA - Fortify Backend)</li>
    <li><span class="next">[ ]</span> <strong>2.9:</strong> Implement 2FA UI [UI] (Livewire/Volt with Flux UI, Filament, Conceptual React/Vue)</li>
    <li><span class="next">[ ]</span> <strong>2.10:</strong> Implement Profile Information UI [UI] (Livewire/Volt with Flux UI, Filament, Conceptual React/Vue)</li>
    <li><span class="done">[✅]</span> <strong>2.11:</strong> Understanding File Uploads & `spatie/laravel-medialibrary`</li>
    <li><span class="next">[ ]</span> <strong>2.12:</strong> Implement Avatar Upload Backend</li>
    <li><span class="next">[ ]</span> <strong>2.13:</strong> Implement Avatar Upload UI [UI] (Livewire/Volt with Flux UI, Filament, Conceptual React/Vue)</li>
    <li><span class="done">[✅]</span> <strong>2.14:</strong> Understanding Dependency Injection & Service Providers</li>
    <li><span class="next">[ ]</span> <strong>2.15:</strong> Create `UserService` (Handles Creation Logic)</li>
    <li><span class="next">[ ]</span> <strong>2.16:</strong> Create `UserTypeService` & `UserTypeChanged` Event</li>
    <li><span class="next">[ ]</span> <strong>2.17:</strong> Customize Fortify's User Creation (Use Services, Set Default Type)</li>
    <li><span class="done">[✅]</span> <strong>2.18:</strong> Understanding Events & Listeners</li>
    <li><span class="next">[ ]</span> <strong>2.19:</strong> Define Initial Events & Listeners (Incl. Type Change)</li>
    <li><span class="next">[ ]</span> <strong>2.20:</strong> Register Events & Listeners</li>
    <li><span class="next">[ ]</span> <strong>2.21:</strong> Phase 2 Git Commit</li>
    </ul>
</li>
<li><span class="next">[ ]</span> <strong>Phase 3: Implementing Teams and Permissions</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>3.1:</strong> Understanding `spatie/laravel-permission` & Team Scoping</li>
    <li><span class="next">[ ]</span> <strong>3.2:</strong> Configure `spatie/laravel-permission` for Teams</li>
    <li><span class="next">[ ]</span> <strong>3.3:</strong> Create `PermissionSeeder` (Assign Roles based on Team/User Type)</li>
    <li><span class="next">[ ]</span> <strong>3.4:</strong> Create `TeamService`</li>
    <li><span class="done">[✅]</span> <strong>3.5:</strong> Understanding Resource Controllers & Authorization (Policies)</li>
    <li><span class="next">[ ]</span> <strong>3.6:</strong> Set up Team Management Backend (Routes, Controllers, Policy - Consider User Types)</li>
    <li><span class="next">[ ]</span> <strong>3.7:</strong> Implement Team Management UI [UI] (Livewire/Volt with Flux UI, Filament, Conceptual React/Vue)</li>
    <li><span class="done">[✅]</span> <strong>3.8:</strong> Understanding Middleware</li>
    <li><span class="next">[ ]</span> <strong>3.9:</strong> Create Optional `EnsureUserHasTeamRole` Middleware</li>
    <li><span class="next">[ ]</span> <strong>3.10:</strong> Phase 3 Git Commit</li>
    </ul>
</li>
<li><span class="next">[ ]</span> <strong>Phase 4: Real-time Foundation & Activity Logging</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>4.1:</strong> Understanding WebSockets, Reverb & Echo</li>
    <li><span class="done">[✅]</span> <strong>4.2:</strong> Set Up Laravel Reverb</li>
    <li><span class="done">[✅]</span> <strong>4.3:</strong> Configure Laravel Echo (Backend & Frontend)</li>
    <li><span class="done">[✅]</span> <strong>4.4:</strong> Implement Presence Status Backend (Enum, Migration, Cast)</li>
    <li><span class="done">[✅]</span> <strong>4.5:</strong> Create `PresenceChanged` Broadcast Event</li>
    <li><span class="done">[✅]</span> <strong>4.6:</strong> Create Login/Logout Presence Listeners</li>
    <li><span class="done">[✅]</span> <strong>4.7:</strong> Understanding Contextual Activity Logging</li>
    <li><span class="next">[ ]</span> <strong>4.8:</strong> Implement Activity Logging via Listeners</li>
    <li><span class="next">[ ]</span> <strong>4.9:</strong> Phase 4 Git Commit</li>
    </ul>
</li>
<li><span class="next">[ ]</span> <strong>Phase 5: Advanced Features & Real-time Implementation</strong>
    <ul>
    <li><span class="next">[ ]</span> <strong>5.1:</strong> Implement Impersonation Feature [UI] (Consider permissions based on Admin type)</li>
    <li><span class="next">[ ]</span> <strong>5.2:</strong> Implement Comments Feature [UI]</li>
    <li><span class="next">[ ]</span> <strong>5.3:</strong> Implement User Settings Feature [UI]</li>
    <li><span class="done">[✅]</span> <strong>5.4:</strong> Understanding Full-Text Search (Scout & Typesense)</li>
    <li><span class="next">[ ]</span> <strong>5.5:</strong> Implement Search Backend (Scout Config, Model Setup, Indexing - Works with Base User)</li>
    <li><span class="next">[ ]</span> <strong>5.6:</strong> Implement Search Frontend [UI]</li>
    <li><span class="done">[✅]</span> <strong>5.7:</strong> Understanding Broadcasting Channels & Authorization</li>
    <li><span class="next">[ ]</span> <strong>5.8:</strong> Define Broadcast Channel Authorizations (`channels.php`)</li>
    <li><span class="next">[ ]</span> <strong>5.9:</strong> Implement Real-time Presence UI [UI]</li>
    <li><span class="next">[ ]</span> <strong>5.10:</strong> Implement Real-time Chat Backend (Model, Service, API, Event)</li>
    <li><span class="next">[ ]</span> <strong>5.11:</strong> Implement Real-time Chat UI [UI]</li>
    <li><span class="done">[✅]</span> <strong>5.12:</strong> Understanding API Authentication (Passport & Sanctum)</li>
    <li><span class="next">[ ]</span> <strong>5.13:</strong> Configure API Authentication Guards (Both Passport & Sanctum)</li>
    <li><span class="next">[ ]</span> <strong>5.14:</strong> Set Up Passport and Sanctum for API Authentication</li>
    <li><span class="next">[ ]</span> <strong>5.15:</strong> Implement Filament User Type Change Action</li>
    <li><span class="next">[ ]</span> <strong>5.16:</strong> Phase 5 Git Commit</li>
    </ul>
</li>
<li><span class="next">[ ]</span> <strong>Phase 6: Polishing, Testing & Deployment</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>6.1:</strong> Understanding Internationalization (i18n)</li>
    <li><span class="next">[ ]</span> <strong>6.2:</strong> Implement i18n (Backend)</li>
    <li><span class="next">[ ]</span> <strong>6.3:</strong> Implement Locale Switching [UI]</li>
    <li><span class="done">[✅]</span> <strong>6.4:</strong> Understanding Feature Flags (Pennant)</li>
    <li><span class="next">[ ]</span> <strong>6.5:</strong> Implement Feature Flags</li>
    <li><span class="done">[✅]</span> <strong>6.6:</strong> Understanding Testing (Unit, Feature, Browser - PestPHP)</li>
    <li><span class="next">[ ]</span> <strong>6.7:</strong> Writing Tests (Examples - PestPHP, Filament - Include STI Tests)</li>
    <li><span class="next">[ ]</span> <strong>6.8:</strong> Understanding Performance Optimization (STI Considerations)</li>
    <li><span class="next">[ ]</span> <strong>6.9:</strong> Apply Performance Considerations</li>
    <li><span class="next">[ ]</span> <strong>6.10:</strong> Write Documentation (README, PHPDoc)</li>
    <li><span class="next">[ ]</span> <strong>6.11:</strong> Set Up Data Backups (`spatie/laravel-backup`)</li>
    <li><span class="next">[ ]</span> <strong>6.12:</strong> Understanding Deployment</li>
    <li><span class="next">[ ]</span> <strong>6.13:</strong> Prepare for Deployment</li>
    <li><span class="next">[ ]</span> <strong>6.14:</strong> Final Git Commit</li>
    </ul>
</li>
</ul>

As you complete each step, you can mark it as done by changing the `[ ]` to `[✅]` in this file. Phase 1 is complete, and parts of Phases 2 and 4 have been implemented. The current branch is working on HasChildrenTrait implementation.
