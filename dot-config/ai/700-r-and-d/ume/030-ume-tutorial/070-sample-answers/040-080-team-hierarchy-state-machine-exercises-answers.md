# Team Hierarchy State Machine Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the Team Hierarchy State Machine exercises from the UME tutorial.

> **Related Tutorial Section**: [Phase 3: Teams & Permissions](../050-implementation/040-phase3-teams-permissions/000-index.md)
>
> **Exercise File**: [Team Hierarchy State Machine Exercises](../060-exercises/040-045-team-hierarchy-state-machine-exercises.md)
>
> **Main File**: This is the main file of the Team Hierarchy State Machine exercises answers. See the [exercise file](../060-exercises/040-045-team-hierarchy-state-machine-exercises.md) for links to all parts.

## Set 1: Team Hierarchy State Machine Basics

### Question Answers

1. **What is the purpose of using a state machine for team hierarchies?**
   - **Answer: B) To enforce valid state transitions and encapsulate state-specific behavior**
   - **Explanation:** A state machine ensures that teams can only transition between states in predefined ways, and each state can encapsulate specific behavior relevant to that state.

2. **Which package is used to implement the team hierarchy state machine?**
   - **Answer: C) spatie/laravel-model-states**
   - **Explanation:** We use the Spatie Laravel Model States package to implement state machines in our Laravel application.

3. **What is the default state for a newly created team?**
   - **Answer: B) Pending**
   - **Explanation:** In our implementation, new teams start in the Pending state and require approval to become Active.

4. **Which of the following is NOT a valid state for a team in our implementation?**
   - **Answer: D) Deleted**
   - **Explanation:** Our implementation uses Pending, Active, Suspended, and Archived states. We use soft deletes for actual deletion rather than a state.

### Exercise Answer

Here's a simplified implementation of a team hierarchy state machine with Draft, Published, and Archived states:

First, let's create an enum for the states:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum TeamStatus: string
{
    case DRAFT = 'draft';
    case PUBLISHED = 'published';
    case ARCHIVED = 'archived';

    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::PUBLISHED => 'Published',
            self::ARCHIVED => 'Archived',
        };
    }
}
```

Next, let's create the base state class:

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;
use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

abstract class TeamStatus extends State
{
    abstract public static function status(): TeamStatus;

    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Draft::class)
            ->allowTransition(Draft::class, Published::class)
            ->allowTransition(Published::class, Archived::class)
            ->allowTransition(Archived::class, Published::class);
    }

    abstract public function canBeViewed(): bool;
}
```

Now, let's create the concrete state classes:

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class Draft extends TeamStatus
{
    public static function status(): TeamStatus
    {
        return TeamStatus::DRAFT;
    }

    public function canBeViewed(): bool
    {
        return false; // Draft teams cannot be viewed by regular users
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class Published extends TeamStatus
{
    public static function status(): TeamStatus
    {
        return TeamStatus::PUBLISHED;
    }

    public function canBeViewed(): bool
    {
        return true; // Published teams can be viewed by all users
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class Archived extends TeamStatus
{
    public static function status(): TeamStatus
    {
        return TeamStatus::ARCHIVED;
    }

    public function canBeViewed(): bool
    {
        // Archived teams can only be viewed by admins
        return auth()->user() && auth()->user()->hasRole('admin');
    }
}
```

Finally, let's create a test for our state machine:

```php
<?php

namespace Tests\Unit;

use App\Models\Team;use App\Models\User;use App\States\Team\Archived;use App\States\Team\Draft;use App\States\Team\Published;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamStatusTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function new_teams_have_draft_state()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $this->assertInstanceOf(Draft::class, $team->status);
        $this->assertFalse($team->canBeViewed());
    }

    #[Test]
    public function draft_teams_can_be_published()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $team->status->transition(Published::class);
        $team->save();

        $this->assertInstanceOf(Published::class, $team->status);
        $this->assertTrue($team->canBeViewed());
    }

    #[Test]
    public function published_teams_can_be_archived()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $team->status->transition(Published::class);
        $team->save();

        $team->status->transition(Archived::class);
        $team->save();

        $this->assertInstanceOf(Archived::class, $team->status);

        // Non-admin cannot view archived teams
        $this->actingAs($user);
        $this->assertFalse($team->canBeViewed());

        // Admin can view archived teams
        $admin = User::factory()->create();
        $admin->assignRole('admin');
        $this->actingAs($admin);
        $this->assertTrue($team->canBeViewed());
    }

    #[Test]
    public function archived_teams_can_be_republished()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);

        $team->status->transition(Published::class);
        $team->save();

        $team->status->transition(Archived::class);
        $team->save();

        $team->status->transition(Published::class);
        $team->save();

        $this->assertInstanceOf(Published::class, $team->status);
        $this->assertTrue($team->canBeViewed());
    }
}
```
