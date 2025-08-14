# Team Invitation State Machine Exercises - Sample Answers (Part 4)

## Exercise 4: Implementing a State History Feature

**Implement a feature to track the history of state changes for team invitations.**

First, let's create a migration for the `team_invitation_state_history` table:

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
        Schema::create('team_invitation_state_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('team_invitation_id')->constrained()->cascadeOnDelete();
            $table->string('from_state');
            $table->string('to_state');
            $table->string('reason')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('changed_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('team_invitation_state_history');
    }
};
```

Next, let's create the `TeamInvitationStateHistory` model:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeamInvitationStateHistory extends Model
{
    use HasFactory;

    protected $table = 'team_invitation_state_history';

    protected $fillable = [
        'team_invitation_id',
        'from_state',
        'to_state',
        'reason',
        'notes',
        'changed_by_id',
    ];

    /**
     * Get the team invitation that owns the state history.
     */
    public function teamInvitation(): BelongsTo
    {
        return $this->belongsTo(TeamInvitation::class);
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

Now, let's add a relationship to the TeamInvitation model:

```php
/**
 * Get the state history for the invitation.
 */
public function stateHistory()
{
    return $this->hasMany(TeamInvitationStateHistory::class);
}
```

Next, let's modify each transition class to record state changes in the history model. Here's an example for the AcceptInvitationTransition:

```php
public function handle(TeamInvitation $invitation, Pending $currentState): Accepted
{
    // Check if the invitation is for this user
    if ($invitation->email !== $this->user->email) {
        throw new \Exception('This invitation is not for you.');
    }

    // Check if the invitation has expired
    if ($invitation->hasExpired()) {
        throw new \Exception('This invitation has expired.');
    }

    // Add the user to the team
    $invitation->team->users()->attach($this->user->id, [
        'role' => $invitation->role ?? 'member',
    ]);

    // Set the user's current team if they don't have one
    if (! $this->user->current_team_id) {
        $this->user->forceFill(['current_team_id' => $invitation->team_id])->save();
    }

    // Log the transition
    Log::info("Team invitation {$invitation->id} was accepted by User {$this->user->id}" . 
        ($this->notes ? " with notes: {$this->notes}" : ""));

    // Record the state change in history
    TeamInvitationStateHistory::create([
        'team_invitation_id' => $invitation->id,
        'from_state' => 'pending',
        'to_state' => 'accepted',
        'notes' => $this->notes,
        'changed_by_id' => $this->user->id,
    ]);

    // Record the action in activity log
    activity()
        ->performedOn($invitation)
        ->causedBy($this->user)
        ->withProperties([
            'notes' => $this->notes,
            'from_state' => 'pending',
            'to_state' => 'accepted',
            'team_id' => $invitation->team_id,
        ])
        ->log('team_invitation_accepted');

    return new Accepted($invitation);
}
```

You would need to make similar changes to all other transition classes.

Finally, let's create a simple view to display the state history:

```blade
<div class="bg-white rounded-lg shadow p-6">
    <h3 class="text-lg font-medium text-gray-900">Invitation State History</h3>
    
    @if($invitation->stateHistory->isEmpty())
        <p class="mt-4 text-sm text-gray-500">No state history available.</p>
    @else
        <div class="mt-4 overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">From State</th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">To State</th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Changed By</th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reason</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @foreach($invitation->stateHistory->sortByDesc('created_at') as $history)
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $history->created_at->format('Y-m-d H:i:s') }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ ucfirst($history->from_state) }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ ucfirst($history->to_state) }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $history->changedBy ? $history->changedBy->name : 'System' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $history->reason ?? 'N/A' }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @endif
</div>
```
