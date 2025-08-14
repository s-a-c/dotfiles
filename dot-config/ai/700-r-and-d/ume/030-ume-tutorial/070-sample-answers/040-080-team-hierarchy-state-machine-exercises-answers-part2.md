# Team Hierarchy State Machine Exercises - Sample Answers (Part 2)

<link rel="stylesheet" href="../../assets/css/styles.css">

## Set 2: Advanced State Machine Concepts

### Question Answers

1. **What is a transition class in the context of our team hierarchy state machine?**
   - **Answer: A) A class that defines how to move from one state to another**
   - **Explanation:** Transition classes encapsulate the logic for moving from one state to another, including validation, side effects, and logging.

2. **Which of the following is a valid transition in our team hierarchy state machine?**
   - **Answer: C) Active → Archived**
   - **Explanation:** In our implementation, active teams can be archived, but pending teams cannot be suspended directly, archived teams cannot be suspended, and suspended teams cannot become pending.

3. **What happens when you try to make an invalid state transition?**
   - **Answer: C) A `TransitionNotFound` exception is thrown**
   - **Explanation:** The Spatie Laravel Model States package throws a `TransitionNotFound` exception when you attempt to make a transition that is not allowed.

4. **Which feature allows state transitions to affect child teams?**
   - **Answer: B) Cascading transitions**
   - **Explanation:** Cascading transitions allow a state change in a parent team to propagate to its child teams.

### Exercise Answer

Here's an implementation of a team status state machine with cascading transitions:

First, let's create an enum for the states:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum TeamStatus: string
{
    case DRAFT = 'draft';
    case ACTIVE = 'active';
    case ON_HOLD = 'on_hold';
    case DISCONTINUED = 'discontinued';

    public function getLabel(): string
    {
        return match($this) {
            self::DRAFT => 'Draft',
            self::ACTIVE => 'Active',
            self::ON_HOLD => 'On Hold',
            self::DISCONTINUED => 'Discontinued',
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

abstract class TeamState extends State
{
    abstract public static function status(): TeamStatus;

    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Draft::class)
            ->allowTransition(Draft::class, Active::class, Transitions\PublishTeamTransition::class)
            ->allowTransition(Active::class, OnHold::class, Transitions\PauseTeamTransition::class)
            ->allowTransition(OnHold::class, Active::class, Transitions\ResumeTeamTransition::class)
            ->allowTransition(Active::class, Discontinued::class, Transitions\DiscontinueTeamTransition::class)
            ->allowTransition(OnHold::class, Discontinued::class, Transitions\DiscontinueTeamTransition::class);
    }
}
```

Now, let's create the concrete state classes:

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class Draft extends TeamState
{
    public static function status(): TeamStatus
    {
        return TeamStatus::DRAFT;
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class Active extends TeamState
{
    public static function status(): TeamStatus
    {
        return TeamStatus::ACTIVE;
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class OnHold extends TeamState
{
    public static function status(): TeamStatus
    {
        return TeamStatus::ON_HOLD;
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team;

use App\Enums\TeamStatus;

class Discontinued extends TeamState
{
    public static function status(): TeamStatus
    {
        return TeamStatus::DISCONTINUED;
    }
}
```

Now, let's create the transition classes:

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\Draft;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

class PublishTeamTransition extends Transition
{
    public function __construct(
        private ?User $publishedBy = null,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    public function handle(Team $team, Draft $currentState): Active
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was published by " . 
            ($this->publishedBy ? "User {$this->publishedBy->id}" : "system") . 
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the action in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->publishedBy ?? auth()->user())
            ->withProperties([
                'notes' => $this->notes,
                'from_state' => 'draft',
                'to_state' => 'active',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_published');

        // Cascade to children if requested
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if ($childTeam->status instanceof Draft) {
                    $childTeam->status->transition(new self(
                        $this->publishedBy,
                        "Parent team {$team->name} was published",
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        return new Active($team);
    }
}
```

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\User;
use App\States\Team\Active;
use App\States\Team\OnHold;
use Illuminate\Support\Facades\Log;
use Spatie\ModelStates\Transition;

class PauseTeamTransition extends Transition
{
    public function __construct(
        private ?User $pausedBy = null,
        private string $reason,
        private ?string $notes = null,
        private bool $cascadeToChildren = false
    ) {}

    public function handle(Team $team, Active $currentState): OnHold
    {
        // Log the transition
        Log::info("Team {$team->id} ({$team->name}) was paused by " . 
            ($this->pausedBy ? "User {$this->pausedBy->id}" : "system") . 
            " for reason: {$this->reason}" .
            ($this->notes ? " with notes: {$this->notes}" : ""));

        // Record the action in activity log
        activity()
            ->performedOn($team)
            ->causedBy($this->pausedBy ?? auth()->user())
            ->withProperties([
                'reason' => $this->reason,
                'notes' => $this->notes,
                'from_state' => 'active',
                'to_state' => 'on_hold',
                'cascade_to_children' => $this->cascadeToChildren,
            ])
            ->log('team_paused');

        // Cascade to children if requested
        if ($this->cascadeToChildren && $team->children()->count() > 0) {
            foreach ($team->children as $childTeam) {
                if ($childTeam->status instanceof Active) {
                    $childTeam->status->transition(new self(
                        $this->pausedBy,
                        "Parent team {$team->name} was paused: {$this->reason}",
                        $this->notes,
                        true // Continue cascading
                    ));
                    $childTeam->save();
                }
            }
        }

        return new OnHold($team);
    }
}
```
