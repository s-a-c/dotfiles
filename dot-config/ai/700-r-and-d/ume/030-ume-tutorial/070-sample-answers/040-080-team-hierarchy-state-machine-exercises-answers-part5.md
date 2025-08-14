# Team Hierarchy State Machine Exercises - Sample Answers (Part 5)

<link rel="stylesheet" href="../../assets/css/styles.css">

Now, let's create a Livewire component to display the state history:

```php
<?php

namespace App\Livewire;

use App\Models\Team;
use App\Models\TeamStateHistory;
use App\Models\User;
use Illuminate\Support\Carbon;
use Livewire\Component;
use Livewire\WithPagination;

class TeamStateHistoryViewer extends Component
{
    use WithPagination;

    public Team $team;
    public ?string $state = null;
    public ?string $userId = null;
    public ?string $fromDate = null;
    public ?string $toDate = null;
    public string $sortField = 'created_at';
    public string $sortDirection = 'desc';

    protected $queryString = [
        'state' => ['except' => ''],
        'userId' => ['except' => ''],
        'fromDate' => ['except' => ''],
        'toDate' => ['except' => ''],
        'sortField' => ['except' => 'created_at'],
        'sortDirection' => ['except' => 'desc'],
    ];

    public function mount(Team $team)
    {
        $this->team = $team;
    }

    public function updatingState()
    {
        $this->resetPage();
    }

    public function updatingUserId()
    {
        $this->resetPage();
    }

    public function updatingFromDate()
    {
        $this->resetPage();
    }

    public function updatingToDate()
    {
        $this->resetPage();
    }

    public function sortBy($field)
    {
        if ($this->sortField === $field) {
            $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            $this->sortField = $field;
            $this->sortDirection = 'asc';
        }
    }

    public function resetFilters()
    {
        $this->reset(['state', 'userId', 'fromDate', 'toDate']);
        $this->resetPage();
    }

    public function render()
    {
        $query = TeamStateHistory::where('team_id', $this->team->id);

        // Apply filters
        if ($this->state) {
            $query->where(function ($q) {
                $q->where('from_state', $this->state)
                  ->orWhere('to_state', $this->state);
            });
        }

        if ($this->userId) {
            $query->where('changed_by_id', $this->userId);
        }

        if ($this->fromDate) {
            $query->whereDate('created_at', '>=', Carbon::parse($this->fromDate));
        }

        if ($this->toDate) {
            $query->whereDate('created_at', '<=', Carbon::parse($this->toDate));
        }

        // Apply sorting
        $query->orderBy($this->sortField, $this->sortDirection);

        // Get history with pagination
        $history = $query->with('changedBy')->paginate(10);

        // Get users who have changed the state
        $users = User::whereIn('id', TeamStateHistory::where('team_id', $this->team->id)
            ->whereNotNull('changed_by_id')
            ->distinct()
            ->pluck('changed_by_id'))
            ->get();

        // Get all states used
        $states = TeamStateHistory::where('team_id', $this->team->id)
            ->select('from_state')
            ->distinct()
            ->pluck('from_state')
            ->merge(
                TeamStateHistory::where('team_id', $this->team->id)
                    ->select('to_state')
                    ->distinct()
                    ->pluck('to_state')
            )
            ->unique()
            ->values();

        return view('livewire.team-state-history-viewer', [
            'history' => $history,
            'users' => $users,
            'states' => $states,
            'canRevert' => auth()->user() && auth()->user()->hasRole('admin'),
        ]);
    }

    public function revert(TeamStateHistory $history)
    {
        // Check authorization
        if (! auth()->user() || ! auth()->user()->hasRole('admin')) {
            $this->addError('revert', 'Only administrators can revert team states.');
            return;
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
                $this->addError('revert', 'Cannot revert to unknown state: ' . $previousState);
                return;
            }

            // Create the transition instance
            $transition = match ($previousState) {
                'draft' => new \App\States\Team\Transitions\RevertToDraftTransition(
                    auth()->user(),
                    'Reverted to previous state',
                    false
                ),
                'active' => new \App\States\Team\Transitions\ReactivateTeamTransition(
                    auth()->user(),
                    'Reverted to previous state',
                    false
                ),
                'on_hold' => new \App\States\Team\Transitions\PauseTeamTransition(
                    auth()->user(),
                    'Reverted to previous state',
                    null,
                    false
                ),
                'discontinued' => new \App\States\Team\Transitions\DiscontinueTeamTransition(
                    auth()->user(),
                    'Reverted to previous state',
                    null,
                    false
                ),
            };

            // Perform the transition
            $this->team->status->transition($transition);
            $this->team->save();

            $this->dispatch('notify', [
                'type' => 'success',
                'message' => 'Team state reverted successfully.',
            ]);
        } catch (\Exception $e) {
            $this->addError('revert', 'Cannot revert to the previous state: ' . $e->getMessage());
        }
    }
}
```

And the corresponding view:

```html
<!-- resources/views/livewire/team-state-history-viewer.blade.php -->
<div>
    <!-- Filters -->
    <div class="mb-6 bg-white p-4 rounded-lg shadow">
        <h3 class="text-lg font-semibold mb-4">Filters</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
                <x-label for="state" value="State" />
                <select id="state" wire:model.live="state" class="w-full border-gray-300 rounded-md shadow-sm">
                    <option value="">All States</option>
                    @foreach ($states as $stateOption)
                        <option value="{{ $stateOption }}">{{ ucfirst($stateOption) }}</option>
                    @endforeach
                </select>
            </div>
            
            <div>
                <x-label for="userId" value="Changed By" />
                <select id="userId" wire:model.live="userId" class="w-full border-gray-300 rounded-md shadow-sm">
                    <option value="">All Users</option>
                    @foreach ($users as $user)
                        <option value="{{ $user->id }}">{{ $user->name }}</option>
                    @endforeach
                </select>
            </div>
            
            <div>
                <x-label for="fromDate" value="From Date" />
                <x-input id="fromDate" type="date" wire:model.live="fromDate" class="w-full" />
            </div>
            
            <div>
                <x-label for="toDate" value="To Date" />
                <x-input id="toDate" type="date" wire:model.live="toDate" class="w-full" />
            </div>
        </div>
        
        <div class="mt-4 flex justify-end">
            <x-button wire:click="resetFilters" class="bg-gray-500 hover:bg-gray-600">
                Reset Filters
            </x-button>
            
            <a href="{{ route('teams.state-history.export', $team) }}" class="ml-2 inline-flex items-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-500 active:bg-green-700 focus:outline-none focus:border-green-700 focus:ring focus:ring-green-300 disabled:opacity-25 transition">
                Export CSV
            </a>
        </div>
    </div>
    
    <!-- Error Messages -->
    @error('revert')
        <div class="mb-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {{ $message }}
        </div>
    @enderror
    
    <!-- History Table -->
    <div class="overflow-x-auto bg-white rounded-lg shadow">
        <table class="min-w-full divide-y divide-gray-200">
            <thead>
                <tr>
                    <th wire:click="sortBy('created_at')" class="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer">
                        Date
                        @if ($sortField === 'created_at')
                            <span class="ml-1">
                                @if ($sortDirection === 'asc')
                                    &#8593;
                                @else
                                    &#8595;
                                @endif
                            </span>
                        @endif
                    </th>
                    <th wire:click="sortBy('from_state')" class="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer">
                        From State
                        @if ($sortField === 'from_state')
                            <span class="ml-1">
                                @if ($sortDirection === 'asc')
                                    &#8593;
                                @else
                                    &#8595;
                                @endif
                            </span>
                        @endif
                    </th>
                    <th wire:click="sortBy('to_state')" class="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer">
                        To State
                        @if ($sortField === 'to_state')
                            <span class="ml-1">
                                @if ($sortDirection === 'asc')
                                    &#8593;
                                @else
                                    &#8595;
                                @endif
                            </span>
                        @endif
                    </th>
                    <th class="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Reason
                    </th>
                    <th wire:click="sortBy('changed_by_id')" class="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer">
                        Changed By
                        @if ($sortField === 'changed_by_id')
                            <span class="ml-1">
                                @if ($sortDirection === 'asc')
                                    &#8593;
                                @else
                                    &#8595;
                                @endif
                            </span>
                        @endif
                    </th>
                    @if ($canRevert)
                        <th class="px-6 py-3 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Actions
                        </th>
                    @endif
                </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
                @forelse ($history as $record)
                    <tr>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {{ $record->created_at->format('Y-m-d H:i:s') }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                                @if ($record->from_state === 'draft') bg-gray-100 text-gray-800
                                @elseif ($record->from_state === 'active') bg-green-100 text-green-800
                                @elseif ($record->from_state === 'on_hold') bg-yellow-100 text-yellow-800
                                @elseif ($record->from_state === 'discontinued') bg-red-100 text-red-800
                                @endif">
                                {{ ucfirst($record->from_state) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                                @if ($record->to_state === 'draft') bg-gray-100 text-gray-800
                                @elseif ($record->to_state === 'active') bg-green-100 text-green-800
                                @elseif ($record->to_state === 'on_hold') bg-yellow-100 text-yellow-800
                                @elseif ($record->to_state === 'discontinued') bg-red-100 text-red-800
                                @endif">
                                {{ ucfirst($record->to_state) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-500">
                            {{ $record->reason ?? 'No reason provided' }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {{ $record->changedBy ? $record->changedBy->name : 'System' }}
                        </td>
                        @if ($canRevert)
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button wire:click="revert({{ $record->id }})" class="text-indigo-600 hover:text-indigo-900">
                                    Revert to {{ ucfirst($record->from_state) }}
                                </button>
                            </td>
                        @endif
                    </tr>
                @empty
                    <tr>
                        <td colspan="{{ $canRevert ? 6 : 5 }}" class="px-6 py-4 text-center text-gray-500">
                            No state history found.
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    
    <!-- Pagination -->
    <div class="mt-4">
        {{ $history->links() }}
    </div>
</div>
```

Finally, let's write a test for the history tracking and viewing functionality:

```php
<?php

namespace Tests\Feature;

use App\Livewire\TeamStateHistoryViewer;use App\Models\Team;use App\Models\TeamStateHistory;use App\Models\User;use App\States\Team\Transitions\DiscontinueTeamTransition;use App\States\Team\Transitions\PauseTeamTransition;use App\States\Team\Transitions\PublishTeamTransition;use App\States\Team\Transitions\ResumeTeamTransition;use Illuminate\Foundation\Testing\RefreshDatabase;use Livewire\Livewire;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamStateHistoryTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function state_changes_are_recorded_in_history()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // Initial state is 'draft'
        $this->assertEquals(0, TeamStateHistory::count());
        
        // Publish the team
        $team->status->transition(new PublishTeamTransition($user, 'Initial publication'));
        $team->save();
        
        $this->assertEquals(1, TeamStateHistory::count());
        $history = TeamStateHistory::first();
        $this->assertEquals('draft', $history->from_state);
        $this->assertEquals('active', $history->to_state);
        $this->assertEquals('Initial publication', $history->reason);
        $this->assertEquals($user->id, $history->changed_by_id);
        
        // Pause the team
        $team->status->transition(new PauseTeamTransition($user, 'Maintenance', 'Scheduled maintenance'));
        $team->save();
        
        $this->assertEquals(2, TeamStateHistory::count());
        $history = TeamStateHistory::latest()->first();
        $this->assertEquals('active', $history->from_state);
        $this->assertEquals('on_hold', $history->to_state);
        $this->assertEquals('Maintenance - Scheduled maintenance', $history->reason);
        
        // Resume the team
        $team->status->transition(new ResumeTeamTransition($user, 'Maintenance complete'));
        $team->save();
        
        $this->assertEquals(3, TeamStateHistory::count());
        $history = TeamStateHistory::latest()->first();
        $this->assertEquals('on_hold', $history->from_state);
        $this->assertEquals('active', $history->to_state);
        
        // Discontinue the team
        $team->status->transition(new DiscontinueTeamTransition($user, 'No longer needed'));
        $team->save();
        
        $this->assertEquals(4, TeamStateHistory::count());
        $history = TeamStateHistory::latest()->first();
        $this->assertEquals('active', $history->from_state);
        $this->assertEquals('discontinued', $history->to_state);
    }

    #[Test]
    public function team_owner_can_view_state_history()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        
        // Create some state history
        $team->status->transition(new PublishTeamTransition($user, 'Initial publication'));
        $team->save();
        
        $team->status->transition(new PauseTeamTransition($user, 'Maintenance'));
        $team->save();
        
        $response = $this->actingAs($user)->get(route('teams.state-history.index', $team));
        
        $response->assertStatus(200);
        $response->assertSee('State History');
        $response->assertSee('Initial publication');
        $response->assertSee('Maintenance');
    }

    #[Test]
    public function admin_can_revert_team_state()
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');
        
        $team = Team::factory()->create(['owner_id' => $admin->id]);
        
        // Publish the team
        $team->status->transition(new PublishTeamTransition($admin, 'Initial publication'));
        $team->save();
        
        // Pause the team
        $team->status->transition(new PauseTeamTransition($admin, 'Maintenance'));
        $team->save();
        
        $history = TeamStateHistory::first(); // Get the first transition (draft -> active)
        
        Livewire::actingAs($admin)
            ->test(TeamStateHistoryViewer::class, ['team' => $team])
            ->call('revert', $history->id)
            ->assertDispatched('notify');
        
        $team->refresh();
        $this->assertEquals('active', $team->status::status()->value);
        
        // Check that a new history record was created
        $this->assertEquals(3, TeamStateHistory::count());
        $latestHistory = TeamStateHistory::latest()->first();
        $this->assertEquals('on_hold', $latestHistory->from_state);
        $this->assertEquals('active', $latestHistory->to_state);
        $this->assertEquals('Reverted to previous state', $latestHistory->reason);
    }

    #[Test]
    public function non_admin_cannot_revert_team_state()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        
        $team = Team::factory()->create(['owner_id' => $owner->id]);
        
        // Publish the team
        $team->status->transition(new PublishTeamTransition($owner, 'Initial publication'));
        $team->save();
        
        $history = TeamStateHistory::first();
        
        Livewire::actingAs($user)
            ->test(TeamStateHistoryViewer::class, ['team' => $team])
            ->call('revert', $history->id)
            ->assertHasErrors('revert');
        
        $team->refresh();
        $this->assertEquals('active', $team->status::status()->value);
    }
}
```
