# Team Hierarchy State Integration (Part 2)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Adding Routes

Let's add routes for our team state transitions:

```php
// Team state transitions
Route::prefix('teams')->name('teams.')->middleware(['auth', 'verified'])->group(function () {
    Route::post('{team}/approve', [TeamController::class, 'approve'])->name('approve');
    Route::post('{team}/suspend', [TeamController::class, 'suspend'])->name('suspend');
    Route::post('{team}/reactivate', [TeamController::class, 'reactivate'])->name('reactivate');
    Route::post('{team}/archive', [TeamController::class, 'archive'])->name('archive');
    Route::post('{team}/restore', [TeamController::class, 'restore'])->name('restore');
});
```

## Creating Livewire Components

Let's create Livewire components to handle team state transitions in the UI. We'll start with a component to display the current team state and available actions:

```bash
php artisan make:livewire TeamStateManager
```

```php
<?php

namespace App\Livewire;

use App\Models\Team;
use App\States\Team\Active;
use App\States\Team\Archived;
use App\States\Team\Pending;
use App\States\Team\Suspended;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;

class TeamStateManager extends Component
{
    use AuthorizesRequests;

    public Team $team;
    public bool $showApproveModal = false;
    public bool $showSuspendModal = false;
    public bool $showReactivateModal = false;
    public bool $showArchiveModal = false;
    public bool $showRestoreModal = false;
    
    public string $reason = '';
    public string $notes = '';
    public bool $cascadeToChildren = false;

    public function mount(Team $team)
    {
        $this->team = $team;
    }

    public function approve()
    {
        $this->authorize('approve', $this->team);

        try {
            $this->team->hierarchy_state->transition(new \App\States\Team\Transitions\ApproveTeamTransition(
                auth()->user(),
                $this->notes
            ));
            $this->team->save();

            $this->showApproveModal = false;
            $this->reset(['notes']);
            $this->dispatch('team-state-updated');
            $this->dispatch('notify', [
                'type' => 'success',
                'message' => 'Team approved successfully.',
            ]);
        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Cannot approve the team in its current state.',
            ]);
        }
    }

    public function suspend()
    {
        $this->authorize('suspend', $this->team);

        $this->validate([
            'reason' => 'required|string|max:255',
        ]);

        try {
            $this->team->hierarchy_state->transition(new \App\States\Team\Transitions\SuspendTeamTransition(
                auth()->user(),
                $this->reason,
                $this->notes,
                $this->cascadeToChildren
            ));
            $this->team->save();

            $this->showSuspendModal = false;
            $this->reset(['reason', 'notes', 'cascadeToChildren']);
            $this->dispatch('team-state-updated');
            $this->dispatch('notify', [
                'type' => 'success',
                'message' => 'Team suspended successfully.',
            ]);
        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Cannot suspend the team in its current state.',
            ]);
        }
    }

    public function reactivate()
    {
        $this->authorize('reactivate', $this->team);

        try {
            $this->team->hierarchy_state->transition(new \App\States\Team\Transitions\ReactivateTeamTransition(
                auth()->user(),
                $this->notes,
                $this->cascadeToChildren
            ));
            $this->team->save();

            $this->showReactivateModal = false;
            $this->reset(['notes', 'cascadeToChildren']);
            $this->dispatch('team-state-updated');
            $this->dispatch('notify', [
                'type' => 'success',
                'message' => 'Team reactivated successfully.',
            ]);
        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Cannot reactivate the team in its current state.',
            ]);
        }
    }

    public function archive()
    {
        $this->authorize('archive', $this->team);

        try {
            $this->team->hierarchy_state->transition(new \App\States\Team\Transitions\ArchiveTeamTransition(
                auth()->user(),
                $this->reason,
                $this->notes,
                $this->cascadeToChildren
            ));
            $this->team->save();

            $this->showArchiveModal = false;
            $this->reset(['reason', 'notes', 'cascadeToChildren']);
            $this->dispatch('team-state-updated');
            $this->dispatch('notify', [
                'type' => 'success',
                'message' => 'Team archived successfully.',
            ]);
        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Cannot archive the team in its current state.',
            ]);
        }
    }

    public function restore()
    {
        $this->authorize('restore', $this->team);

        try {
            $this->team->hierarchy_state->transition(new \App\States\Team\Transitions\RestoreTeamTransition(
                auth()->user(),
                $this->notes,
                $this->cascadeToChildren
            ));
            $this->team->save();

            $this->showRestoreModal = false;
            $this->reset(['notes', 'cascadeToChildren']);
            $this->dispatch('team-state-updated');
            $this->dispatch('notify', [
                'type' => 'success',
                'message' => 'Team restored successfully.',
            ]);
        } catch (\Exception $e) {
            $this->dispatch('notify', [
                'type' => 'error',
                'message' => 'Cannot restore the team in its current state.',
            ]);
        }
    }

    public function render()
    {
        return view('livewire.team-state-manager', [
            'isPending' => $this->team->hierarchy_state instanceof Pending,
            'isActive' => $this->team->hierarchy_state instanceof Active,
            'isSuspended' => $this->team->hierarchy_state instanceof Suspended,
            'isArchived' => $this->team->hierarchy_state instanceof Archived,
            'canApprove' => auth()->user()->can('approve', $this->team),
            'canSuspend' => auth()->user()->can('suspend', $this->team),
            'canReactivate' => auth()->user()->can('reactivate', $this->team),
            'canArchive' => auth()->user()->can('archive', $this->team),
            'canRestore' => auth()->user()->can('restore', $this->team),
            'hasChildren' => $this->team->children()->count() > 0,
        ]);
    }
}
```
