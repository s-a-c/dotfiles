# Team Hierarchy State Integration (Part 4)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Filtering Teams by State

Let's create a component to filter teams by their state:

```php
<?php

namespace App\Livewire;

use App\Models\Team;
use Livewire\Component;
use Livewire\WithPagination;

class TeamStateFilter extends Component
{
    use WithPagination;

    public string $state = 'active';
    public string $search = '';
    
    protected $queryString = [
        'state' => ['except' => 'active'],
        'search' => ['except' => ''],
    ];

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function updatingState()
    {
        $this->resetPage();
    }

    public function render()
    {
        $query = Team::query();
        
        // Filter by state
        if ($this->state === 'pending') {
            $query->whereState('hierarchy_state', \App\States\Team\Pending::class);
        } elseif ($this->state === 'active') {
            $query->whereState('hierarchy_state', \App\States\Team\Active::class);
        } elseif ($this->state === 'suspended') {
            $query->whereState('hierarchy_state', \App\States\Team\Suspended::class);
        } elseif ($this->state === 'archived') {
            $query->whereState('hierarchy_state', \App\States\Team\Archived::class);
        }
        
        // Search
        if (!empty($this->search)) {
            $query->where(function ($q) {
                $q->where('name', 'like', '%' . $this->search . '%')
                  ->orWhere('description', 'like', '%' . $this->search . '%');
            });
        }
        
        $teams = $query->with('owner')->paginate(10);
        
        return view('livewire.team-state-filter', [
            'teams' => $teams,
            'pendingCount' => Team::whereState('hierarchy_state', \App\States\Team\Pending::class)->count(),
            'activeCount' => Team::whereState('hierarchy_state', \App\States\Team\Active::class)->count(),
            'suspendedCount' => Team::whereState('hierarchy_state', \App\States\Team\Suspended::class)->count(),
            'archivedCount' => Team::whereState('hierarchy_state', \App\States\Team\Archived::class)->count(),
        ]);
    }
}
```

And the corresponding view:

```html
<!-- resources/views/livewire/team-state-filter.blade.php -->
<div>
    <!-- Search and Filter Controls -->
    <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div class="flex-1">
            <x-input type="text" wire:model.live.debounce.300ms="search" placeholder="Search teams..." class="w-full" />
        </div>
        
        <div class="flex flex-wrap gap-2">
            <button wire:click="$set('state', 'pending')" class="px-3 py-1 text-sm rounded-full {{ $state === 'pending' ? 'bg-yellow-100 text-yellow-800 border-yellow-200' : 'bg-gray-100 text-gray-600' }}">
                Pending ({{ $pendingCount }})
            </button>
            <button wire:click="$set('state', 'active')" class="px-3 py-1 text-sm rounded-full {{ $state === 'active' ? 'bg-green-100 text-green-800 border-green-200' : 'bg-gray-100 text-gray-600' }}">
                Active ({{ $activeCount }})
            </button>
            <button wire:click="$set('state', 'suspended')" class="px-3 py-1 text-sm rounded-full {{ $state === 'suspended' ? 'bg-red-100 text-red-800 border-red-200' : 'bg-gray-100 text-gray-600' }}">
                Suspended ({{ $suspendedCount }})
            </button>
            <button wire:click="$set('state', 'archived')" class="px-3 py-1 text-sm rounded-full {{ $state === 'archived' ? 'bg-gray-100 text-gray-800 border-gray-200' : 'bg-gray-100 text-gray-600' }}">
                Archived ({{ $archivedCount }})
            </button>
        </div>
    </div>

    <!-- Teams Table -->
    <div class="overflow-x-auto">
        <table class="min-w-full bg-white border border-gray-200">
            <thead>
                <tr>
                    <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Team
                    </th>
                    <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Owner
                    </th>
                    <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        State
                    </th>
                    <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Members
                    </th>
                    <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Actions
                    </th>
                </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
                @forelse ($teams as $team)
                    <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="flex items-center">
                                <div>
                                    <div class="text-sm font-medium text-gray-900">
                                        <a href="{{ route('teams.show', $team) }}" class="hover:underline">
                                            {{ $team->name }}
                                        </a>
                                    </div>
                                    @if ($team->description)
                                        <div class="text-sm text-gray-500 truncate max-w-xs">
                                            {{ $team->description }}
                                        </div>
                                    @endif
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="text-sm text-gray-900">{{ $team->owner->name }}</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $team->hierarchy_state->tailwindClasses() }}">
                                {{ $team->hierarchy_state->label() }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {{ $team->users()->count() }} members
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                            <a href="{{ route('teams.show', $team) }}" class="text-indigo-600 hover:text-indigo-900 mr-3">
                                View
                            </a>
                            @if ($team->children()->count() > 0)
                                <a href="{{ route('teams.hierarchy', $team) }}" class="text-blue-600 hover:text-blue-900">
                                    Hierarchy
                                </a>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                            No teams found.
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    <div class="mt-4">
        {{ $teams->links() }}
    </div>
</div>
```

## Visualizing Team Hierarchy with State Information

Let's create a component to visualize the team hierarchy with state information:

```php
<?php

namespace App\Livewire;

use App\Models\Team;
use Livewire\Component;

class TeamHierarchyVisualization extends Component
{
    public Team $rootTeam;
    public bool $showArchived = false;
    
    public function mount(Team $team)
    {
        $this->rootTeam = $team;
    }
    
    public function toggleShowArchived()
    {
        $this->showArchived = !$this->showArchived;
    }
    
    public function render()
    {
        // Get all descendants with their state
        $descendants = $this->getDescendantsWithState($this->rootTeam);
        
        return view('livewire.team-hierarchy-visualization', [
            'descendants' => $descendants,
        ]);
    }
    
    private function getDescendantsWithState(Team $team)
    {
        $query = $team->children();
        
        // Filter out archived teams if not showing them
        if (!$this->showArchived) {
            $query->whereState('hierarchy_state', '!=', \App\States\Team\Archived::class);
        }
        
        $children = $query->get();
        
        $result = [];
        foreach ($children as $child) {
            $childData = [
                'team' => $child,
                'children' => $this->getDescendantsWithState($child),
            ];
            
            $result[] = $childData;
        }
        
        return $result;
    }
}
```

And the corresponding view:

```html
<!-- resources/views/livewire/team-hierarchy-visualization.blade.php -->
<div>
    <div class="mb-4 flex justify-between items-center">
        <h3 class="text-lg font-semibold">Team Hierarchy</h3>
        
        <div>
            <label class="flex items-center">
                <x-checkbox wire:model.live="showArchived" />
                <span class="ml-2 text-sm text-gray-600">Show archived teams</span>
            </label>
        </div>
    </div>
    
    <div class="p-4 bg-gray-50 rounded-lg">
        <!-- Root Team -->
        <div class="mb-4">
            <div class="flex items-center">
                <span class="font-semibold">{{ $rootTeam->name }}</span>
                <span class="ml-2 px-2 py-0.5 text-xs rounded-full {{ $rootTeam->hierarchy_state->tailwindClasses() }}">
                    {{ $rootTeam->hierarchy_state->label() }}
                </span>
            </div>
        </div>
        
        <!-- Descendants -->
        <div class="pl-6 border-l-2 border-gray-300">
            @include('livewire.partials.team-hierarchy-branch', ['descendants' => $descendants])
        </div>
    </div>
</div>
```

And the partial view for rendering branches:

```html
<!-- resources/views/livewire/partials/team-hierarchy-branch.blade.php -->
@foreach ($descendants as $descendant)
    <div class="mb-4">
        <div class="flex items-center">
            <a href="{{ route('teams.show', $descendant['team']) }}" class="text-blue-600 hover:underline">
                {{ $descendant['team']->name }}
            </a>
            <span class="ml-2 px-2 py-0.5 text-xs rounded-full {{ $descendant['team']->hierarchy_state->tailwindClasses() }}">
                {{ $descendant['team']->hierarchy_state->label() }}
            </span>
        </div>
        
        @if (count($descendant['children']) > 0)
            <div class="pl-6 mt-2 border-l-2 border-gray-200">
                @include('livewire.partials.team-hierarchy-branch', ['descendants' => $descendant['children']])
            </div>
        @endif
    </div>
@endforeach
```

## Next Steps

Now that we've integrated the team hierarchy state machine with our application, let's move on to testing our implementation in the next section.

## Additional Resources

- [Laravel Livewire Documentation](https://laravel-livewire.com/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Laravel Blade Documentation](https://laravel.com/docs/12.x/blade)
