# Team Hierarchy State Machine Exercises - Sample Answers (Part 4)

<link rel="stylesheet" href="../../assets/css/styles.css">

## Set 3: State Machine Integration

### Question Answers

1. **How can you query teams by their state?**
   - **Answer: B) Using the `whereState()` method**
   - **Explanation:** The Spatie Laravel Model States package provides a `whereState()` query scope that allows you to filter models by their state.

2. **Which of the following is NOT a benefit of using a state machine for team hierarchies?**
   - **Answer: C) Improved database performance**
   - **Explanation:** While state machines provide many benefits like enforced workflows, validation, and business logic encapsulation, they don't inherently improve database performance.

3. **How can you visualize the current state of a team in the UI?**
   - **Answer: D) All of the above**
   - **Explanation:** You can visualize the state using the state's `tailwindClasses()` method, by manually checking the state and applying classes, or by using a dedicated visualization component.

4. **What is the purpose of the `TeamStateFilter` component?**
   - **Answer: A) To filter teams by their state in the UI**
   - **Explanation:** The `TeamStateFilter` component allows users to filter teams by their state in the user interface.

### Exercise Answer

Here's an implementation of a team state history and audit log:

First, let's create the `TeamStateHistory` model:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeamStateHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'team_id',
        'from_state',
        'to_state',
        'reason',
        'changed_by_id',
    ];

    /**
     * Get the team that owns the state history.
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * Get the user who changed the state.
     */
    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by_id');
    }
}
```

Next, let's create a migration for the `team_state_histories` table:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('team_state_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->string('from_state');
            $table->string('to_state');
            $table->text('reason')->nullable();
            $table->foreignId('changed_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('team_state_histories');
    }
};
```

Now, let's modify our transition classes to record state changes in the history table. Here's an example with the `PauseTeamTransition` class:

```php
<?php

declare(strict_types=1);

namespace App\States\Team\Transitions;

use App\Models\Team;
use App\Models\TeamStateHistory;
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

        // Record the state change in history
        TeamStateHistory::create([
            'team_id' => $team->id,
            'from_state' => 'active',
            'to_state' => 'on_hold',
            'reason' => $this->reason . ($this->notes ? " - {$this->notes}" : ""),
            'changed_by_id' => $this->pausedBy?->id,
        ]);

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

Now, let's create a controller to view the state history:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Team;
use App\Models\TeamStateHistory;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\Response;

class TeamStateHistoryController extends Controller
{
    /**
     * Display the state history for a team.
     */
    public function index(Request $request, Team $team)
    {
        // Check authorization
        if (! (Gate::allows('admin') || $request->user()->id === $team->owner_id)) {
            abort(403, 'You are not authorized to view this team\'s state history.');
        }

        return view('teams.state-history', [
            'team' => $team,
        ]);
    }

    /**
     * Export the state history to CSV.
     */
    public function export(Request $request, Team $team)
    {
        // Check authorization
        if (! (Gate::allows('admin') || $request->user()->id === $team->owner_id)) {
            abort(403, 'You are not authorized to export this team\'s state history.');
        }

        $query = TeamStateHistory::where('team_id', $team->id);

        // Apply filters if provided
        if ($request->has('from_date')) {
            $query->whereDate('created_at', '>=', $request->input('from_date'));
        }

        if ($request->has('to_date')) {
            $query->whereDate('created_at', '<=', $request->input('to_date'));
        }

        if ($request->has('state')) {
            $query->where(function ($q) use ($request) {
                $q->where('from_state', $request->input('state'))
                  ->orWhere('to_state', $request->input('state'));
            });
        }

        if ($request->has('user_id')) {
            $query->where('changed_by_id', $request->input('user_id'));
        }

        $history = $query->orderBy('created_at', 'desc')->get();

        // Generate CSV
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="team_' . $team->id . '_state_history.csv"',
        ];

        $callback = function () use ($history) {
            $file = fopen('php://output', 'w');
            fputcsv($file, ['Date', 'From State', 'To State', 'Reason', 'Changed By']);

            foreach ($history as $record) {
                fputcsv($file, [
                    $record->created_at->format('Y-m-d H:i:s'),
                    $record->from_state,
                    $record->to_state,
                    $record->reason,
                    $record->changedBy ? $record->changedBy->name : 'System',
                ]);
            }

            fclose($file);
        };

        return response()->stream($callback, Response::HTTP_OK, $headers);
    }

    /**
     * Revert to a previous state.
     */
    public function revert(Request $request, Team $team, TeamStateHistory $history)
    {
        // Check authorization
        if (! Gate::allows('admin')) {
            abort(403, 'Only administrators can revert team states.');
        }

        // Get the previous state
        $previousState = $history->from_state;

        // Check if the transition is valid
        try {
            // Determine the transition class based on the target state
            $transitionClass = match ($previousState) {
                'draft' => \App\States\Team\Transitions\RevertToDraftTransition::class,
                'active' => \App\States\Team\Transitions\ReactivateTeamTransition::class,
                'on_hold' => \App\States\Team\Transitions\PauseTeamTransition::class,
                'discontinued' => \App\States\Team\Transitions\DiscontinueTeamTransition::class,
                default => null,
            };

            if (!$transitionClass) {
                return back()->with('error', 'Cannot revert to unknown state: ' . $previousState);
            }

            // Create the transition instance
            $transition = match ($previousState) {
                'draft' => new \App\States\Team\Transitions\RevertToDraftTransition(
                    $request->user(),
                    'Reverted to previous state',
                    false
                ),
                'active' => new \App\States\Team\Transitions\ReactivateTeamTransition(
                    $request->user(),
                    'Reverted to previous state',
                    false
                ),
                'on_hold' => new \App\States\Team\Transitions\PauseTeamTransition(
                    $request->user(),
                    'Reverted to previous state',
                    null,
                    false
                ),
                'discontinued' => new \App\States\Team\Transitions\DiscontinueTeamTransition(
                    $request->user(),
                    'Reverted to previous state',
                    null,
                    false
                ),
            };

            // Perform the transition
            $team->status->transition($transition);
            $team->save();

            return back()->with('success', 'Team state reverted successfully.');
        } catch (\Exception $e) {
            return back()->with('error', 'Cannot revert to the previous state: ' . $e->getMessage());
        }
    }
}
```
