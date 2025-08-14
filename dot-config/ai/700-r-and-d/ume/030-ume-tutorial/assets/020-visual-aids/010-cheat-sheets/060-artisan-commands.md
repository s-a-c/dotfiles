# UME Artisan Commands Reference

<link rel="stylesheet" href="../../css/styles.css">
<link rel="stylesheet" href="../../css/ume-docs-enhancements.css">
<script src="../../js/ume-docs-enhancements.js"></script>

## Overview

This reference guide provides a comprehensive list of Artisan commands specific to the UME (User Model Enhancements) system. These commands help you manage users, teams, permissions, and other UME-related features from the command line.

## Installation Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:install` | Installs all UME components | `--force`: Overwrite existing files<br>`--teams`: Include team features<br>`--api`: Include API features<br>`--realtime`: Include real-time features |
| `php artisan ume:publish` | Publishes UME configuration files | `--force`: Overwrite existing files<br>`--config`: Publish only configuration<br>`--migrations`: Publish only migrations<br>`--views`: Publish only views |

## User Management Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:user:create` | Creates a new user | `--name=`: User's name<br>`--email=`: User's email<br>`--password=`: User's password<br>`--type=`: User type class<br>`--verified`: Mark email as verified |
| `php artisan ume:user:list` | Lists all users | `--type=`: Filter by user type<br>`--status=`: Filter by user status<br>`--team=`: Filter by team membership |
| `php artisan ume:user:promote` | Promotes a user to a different type | `--email=`: User's email<br>`--type=`: New user type class |
| `php artisan ume:user:verify` | Verifies a user's email | `--email=`: User's email |
| `php artisan ume:user:status` | Changes a user's status | `--email=`: User's email<br>`--status=`: New status |

## Team Management Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:team:create` | Creates a new team | `--name=`: Team name<br>`--owner=`: Owner's email<br>`--description=`: Team description |
| `php artisan ume:team:list` | Lists all teams | `--owner=`: Filter by owner<br>`--status=`: Filter by team status |
| `php artisan ume:team:add-member` | Adds a member to a team | `--team=`: Team name or ID<br>`--email=`: User's email<br>`--role=`: Role in the team |
| `php artisan ume:team:remove-member` | Removes a member from a team | `--team=`: Team name or ID<br>`--email=`: User's email |
| `php artisan ume:team:status` | Changes a team's status | `--team=`: Team name or ID<br>`--status=`: New status |

## Permission Management Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:permission:create` | Creates a new permission | `--name=`: Permission name<br>`--guard=`: Guard name |
| `php artisan ume:permission:list` | Lists all permissions | `--guard=`: Filter by guard |
| `php artisan ume:role:create` | Creates a new role | `--name=`: Role name<br>`--guard=`: Guard name<br>`--permissions=`: Comma-separated list of permissions |
| `php artisan ume:role:list` | Lists all roles | `--guard=`: Filter by guard |
| `php artisan ume:role:assign` | Assigns a role to a user | `--email=`: User's email<br>`--role=`: Role name<br>`--team=`: Team name or ID (for team roles) |
| `php artisan ume:role:revoke` | Revokes a role from a user | `--email=`: User's email<br>`--role=`: Role name<br>`--team=`: Team name or ID (for team roles) |

## Database Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:migrate:fresh` | Refreshes the database with UME migrations | `--seed`: Seed the database<br>`--demo`: Include demo data |
| `php artisan ume:db:seed` | Seeds the database with UME data | `--class=`: Seeder class<br>`--demo`: Include demo data |
| `php artisan ume:db:backup` | Backs up UME-related database tables | `--path=`: Backup path |
| `php artisan ume:db:restore` | Restores UME-related database tables | `--path=`: Backup path |

## State Machine Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:state:list` | Lists all available states | `--model=`: Model class |
| `php artisan ume:state:transition` | Transitions a model to a new state | `--model=`: Model class<br>`--id=`: Model ID<br>`--state=`: New state<br>`--field=`: State field (default: status) |
| `php artisan ume:state:history` | Shows state transition history | `--model=`: Model class<br>`--id=`: Model ID<br>`--field=`: State field (default: status) |

## Real-time Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:reverb:install` | Installs and configures Laravel Reverb | `--host=`: Reverb host<br>`--port=`: Reverb port |
| `php artisan ume:reverb:start` | Starts the Reverb server | `--host=`: Reverb host<br>`--port=`: Reverb port |
| `php artisan ume:reverb:stop` | Stops the Reverb server | |
| `php artisan ume:reverb:status` | Shows the Reverb server status | |

## Development Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:make:user-type` | Creates a new user type class | `--name=`: Class name |
| `php artisan ume:make:state` | Creates a new state class | `--name=`: Class name<br>`--model=`: Model class |
| `php artisan ume:make:transition` | Creates a new transition class | `--name=`: Class name<br>`--from=`: From state<br>`--to=`: To state |
| `php artisan ume:make:trait` | Creates a new trait | `--name=`: Trait name |
| `php artisan ume:make:team-model` | Creates a new team-related model | `--name=`: Model name |

## Testing Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:test` | Runs UME-specific tests | `--filter=`: Filter tests by name<br>`--group=`: Filter tests by group |
| `php artisan ume:test:user` | Runs user-related tests | `--filter=`: Filter tests by name |
| `php artisan ume:test:team` | Runs team-related tests | `--filter=`: Filter tests by name |
| `php artisan ume:test:permission` | Runs permission-related tests | `--filter=`: Filter tests by name |
| `php artisan ume:test:state` | Runs state-related tests | `--filter=`: Filter tests by name |

## Maintenance Commands

| Command | Description | Options |
|---------|-------------|---------|
| `php artisan ume:cache:clear` | Clears UME-specific caches | `--permission`: Clear permission cache<br>`--state`: Clear state cache |
| `php artisan ume:cache:rebuild` | Rebuilds UME-specific caches | `--permission`: Rebuild permission cache<br>`--state`: Rebuild state cache |
| `php artisan ume:audit:generate` | Generates audit reports | `--model=`: Model class<br>`--from=`: Start date<br>`--to=`: End date<br>`--output=`: Output format (html, csv, json) |
| `php artisan ume:cleanup` | Cleans up temporary UME data | `--older-than=`: Age in days |

## Command Examples

### Creating a New Admin User

```bash
php artisan ume:user:create --name="Admin User" --email="admin@example.com" --password="secure_password" --type="App\\Models\\Admin" --verified
```

### Creating a Team and Adding Members

```bash
# Create a team
php artisan ume:team:create --name="Development Team" --owner="owner@example.com" --description="Our development team"

# Add members
php artisan ume:team:add-member --team="Development Team" --email="dev1@example.com" --role="developer"
php artisan ume:team:add-member --team="Development Team" --email="dev2@example.com" --role="developer"
php artisan ume:team:add-member --team="Development Team" --email="lead@example.com" --role="team_lead"
```

### Managing Permissions and Roles

```bash
# Create permissions
php artisan ume:permission:create --name="edit-posts" --guard="web"
php artisan ume:permission:create --name="delete-posts" --guard="web"
php artisan ume:permission:create --name="publish-posts" --guard="web"

# Create a role with permissions
php artisan ume:role:create --name="editor" --guard="web" --permissions="edit-posts,publish-posts"

# Assign role to user
php artisan ume:role:assign --email="editor@example.com" --role="editor"

# Assign team role
php artisan ume:role:assign --email="team-editor@example.com" --role="editor" --team="Development Team"
```

### State Transitions

```bash
# List available states for User model
php artisan ume:state:list --model="App\\Models\\User"

# Transition a user to active state
php artisan ume:state:transition --model="App\\Models\\User" --id=1 --state="App\\States\\Active"

# View state history
php artisan ume:state:history --model="App\\Models\\User" --id=1
```

## Command Output Formats

Most UME commands support multiple output formats:

- **Table**: Default format for list commands
- **JSON**: Add `--format=json` to get JSON output
- **CSV**: Add `--format=csv` to get CSV output
- **Count**: Add `--format=count` to get only the count

Example:

```bash
php artisan ume:user:list --type="App\\Models\\Admin" --format=json
```

## Related Resources

- [Quick Start Guide](../../../090-quick-start/000-index.md)
- [Common Patterns and Snippets](050-common-patterns-snippets.md)
- [UME Implementation Guide](../../../050-implementation/000-index.md)
