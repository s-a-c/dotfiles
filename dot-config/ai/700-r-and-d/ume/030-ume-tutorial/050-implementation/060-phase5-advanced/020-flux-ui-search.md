# Implementing Search with Flux UI

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a global search feature using Livewire/Volt with Flux UI components, allowing users to search for team members, messages, and other content.

## Prerequisites

- Completed Phase 4 (Real-time Features)
- Laravel Scout installed and configured with Typesense
- Flux UI components installed
- Models configured for search

## Implementation

We'll create a Volt component that provides a global search interface with real-time results as the user types.

### Step 1: Configure Models for Search

First, let's configure our User model for search with Laravel Scout:

```php
// app/Models/User.php
namespace App\Models;

use Laravel\Scout\Searchable;
// ... other imports

class User extends Authenticatable
{
    use HasChildren, Searchable;
    // ... other traits
    
    /**
     * Get the indexable data array for the model.
     *
     * @return array
     */
    public function toSearchableArray()
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'given_name' => $this->given_name,
            'family_name' => $this->family_name,
            'other_names' => $this->other_names,
            'email' => $this->email,
            'type' => $this->type,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
    
    /**
     * Get the value used to index the model.
     *
     * @return mixed
     */
    public function getScoutKey()
    {
        return $this->id;
    }
    
    /**
     * Get the key name used to index the model.
     *
     * @return mixed
     */
    public function getScoutKeyName()
    {
        return 'id';
    }
}
```

Similarly, configure the Team and Message models for search.

### Step 2: Create the Typesense Schema

Create a command to set up the Typesense schema:

```bash
php artisan make:command SetupTypesenseSchema
```

Update the command:

```php
// app/Console/Commands/SetupTypesenseSchema.php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use Typesense\Client;

class SetupTypesenseSchema extends Command
{
    protected $signature = 'typesense:setup';
    protected $description = 'Set up Typesense schema for search';

    public function handle()
    {
        $client = new Client([
            'api_key' => config('scout.typesense.client-settings.api_key'),
            'nodes' => config('scout.typesense.client-settings.nodes'),
            'connection_timeout_seconds' => config('scout.typesense.client-settings.connection_timeout_seconds'),
        ]);

        // Create users collection
        try {
            $client->collections->create([
                'name' => 'users',
                'fields' => [
                    ['name' => 'id', 'type' => 'string'],
                    ['name' => 'name', 'type' => 'string'],
                    ['name' => 'given_name', 'type' => 'string'],
                    ['name' => 'family_name', 'type' => 'string'],
                    ['name' => 'other_names', 'type' => 'string', 'optional' => true],
                    ['name' => 'email', 'type' => 'string'],
                    ['name' => 'type', 'type' => 'string'],
                    ['name' => 'created_at', 'type' => 'int64'],
                    ['name' => 'updated_at', 'type' => 'int64'],
                ],
                'default_sorting_field' => 'created_at',
            ]);
            $this->info('Users collection created successfully.');
        } catch (\Exception $e) {
            $this->warn('Users collection already exists or error: ' . $e->getMessage());
        }

        // Create teams collection
        try {
            $client->collections->create([
                'name' => 'teams',
                'fields' => [
                    ['name' => 'id', 'type' => 'string'],
                    ['name' => 'name', 'type' => 'string'],
                    ['name' => 'description', 'type' => 'string', 'optional' => true],
                    ['name' => 'created_at', 'type' => 'int64'],
                    ['name' => 'updated_at', 'type' => 'int64'],
                ],
                'default_sorting_field' => 'created_at',
            ]);
            $this->info('Teams collection created successfully.');
        } catch (\Exception $e) {
            $this->warn('Teams collection already exists or error: ' . $e->getMessage());
        }

        // Create messages collection
        try {
            $client->collections->create([
                'name' => 'messages',
                'fields' => [
                    ['name' => 'id', 'type' => 'string'],
                    ['name' => 'content', 'type' => 'string'],
                    ['name' => 'team_id', 'type' => 'string'],
                    ['name' => 'user_id', 'type' => 'string'],
                    ['name' => 'created_at', 'type' => 'int64'],
                    ['name' => 'updated_at', 'type' => 'int64'],
                ],
                'default_sorting_field' => 'created_at',
            ]);
            $this->info('Messages collection created successfully.');
        } catch (\Exception $e) {
            $this->warn('Messages collection already exists or error: ' . $e->getMessage());
        }

        return Command::SUCCESS;
    }
}
```

Run the command to set up the schema:

```bash
php artisan typesense:setup
```

### Step 3: Import Data to Typesense

Import your existing data to Typesense:

```bash
php artisan scout:import "App\\Models\\User"
php artisan scout:import "App\\Models\\Team"
php artisan scout:import "App\\Models\\Message"
```

### Step 4: Create the Search Service

Create a service to handle search operations:

```php
// app/Services/SearchService.php
namespace App\Services;

use App\Models\Message;
use App\Models\Team;
use App\Models\User;
use Illuminate\Support\Collection;

class SearchService
{
    public function search(string $query, ?int $teamId = null): array
    {
        $users = $this->searchUsers($query, $teamId);
        $teams = $this->searchTeams($query);
        $messages = $this->searchMessages($query, $teamId);

        return [
            'users' => $users,
            'teams' => $teams,
            'messages' => $messages,
        ];
    }

    protected function searchUsers(string $query, ?int $teamId = null): Collection
    {
        $users = User::search($query)
            ->take(5)
            ->get();

        if ($teamId) {
            $teamUserIds = Team::find($teamId)->users()->pluck('users.id')->toArray();
            $users = $users->filter(function ($user) use ($teamUserIds) {
                return in_array($user->id, $teamUserIds);
            });
        }

        return $users->map(function ($user) {
            return [
                'id' => $user->id,
                'name' => $user->name,
                'given_name' => $user->given_name,
                'family_name' => $user->family_name,
                'email' => $user->email,
                'type' => $user->type,
                'avatar' => $user->getFirstMediaUrl('avatar'),
                'url' => route('users.show', $user),
            ];
        });
    }

    protected function searchTeams(string $query): Collection
    {
        $teams = Team::search($query)
            ->take(5)
            ->get();

        return $teams->map(function ($team) {
            return [
                'id' => $team->id,
                'name' => $team->name,
                'description' => $team->description,
                'url' => route('teams.show', $team),
            ];
        });
    }

    protected function searchMessages(string $query, ?int $teamId = null): Collection
    {
        $messagesQuery = Message::search($query);
        
        if ($teamId) {
            $messagesQuery->where('team_id', $teamId);
        }

        $messages = $messagesQuery->take(5)->get();

        return $messages->map(function ($message) {
            return [
                'id' => $message->id,
                'content' => $message->content,
                'team_id' => $message->team_id,
                'team_name' => $message->team->name,
                'user_id' => $message->user_id,
                'user_name' => $message->user->name,
                'created_at' => $message->created_at->diffForHumans(),
                'url' => route('teams.chat', $message->team_id) . '?message=' . $message->id,
            ];
        });
    }
}
```

### Step 5: Create the Volt Component

Create a new file at `resources/views/livewire/search/global-search.blade.php`:

```php
<?php

use App\Services\SearchService;
use Livewire\Volt\Component;

new class extends Component {
    public string $query = '';
    public array $results = [];
    public bool $showResults = false;
    
    public function mount(): void
    {
        $this->results = [
            'users' => [],
            'teams' => [],
            'messages' => [],
        ];
    }
    
    public function updatedQuery(): void
    {
        if (strlen($this->query) < 2) {
            $this->results = [
                'users' => [],
                'teams' => [],
                'messages' => [],
            ];
            $this->showResults = false;
            return;
        }
        
        $searchService = app(SearchService::class);
        $this->results = $searchService->search($this->query, auth()->user()->currentTeam?->id);
        $this->showResults = true;
    }
    
    public function clearSearch(): void
    {
        $this->query = '';
        $this->results = [
            'users' => [],
            'teams' => [],
            'messages' => [],
        ];
        $this->showResults = false;
    }
    
    public function hasResults(): bool
    {
        return count($this->results['users']) > 0 || 
               count($this->results['teams']) > 0 || 
               count($this->results['messages']) > 0;
    }
}; ?>

<div class="relative" x-data="{ open: @entangle('showResults') }">
    <x-flux-input 
        wire:model.live.debounce.300ms="query" 
        placeholder="Search..." 
        class="w-full"
        leading-icon="search"
        trailing-icon="x"
        trailing-icon-click="clearSearch"
        @focus="open = true"
        @click.away="open = false"
    />
    
    <div 
        x-show="open" 
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 transform scale-95"
        x-transition:enter-end="opacity-100 transform scale-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100 transform scale-100"
        x-transition:leave-end="opacity-0 transform scale-95"
        class="absolute z-50 mt-2 w-full bg-white rounded-md shadow-lg"
        style="display: none;"
    >
        <div class="max-h-96 overflow-y-auto p-4 divide-y divide-gray-200">
            @if (!$this->hasResults() && strlen($query) >= 2)
                <div class="py-4 text-center text-gray-500">
                    No results found for "{{ $query }}"
                </div>
            @endif
            
            @if (count($results['users']) > 0)
                <div class="py-4">
                    <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                        Users
                    </h3>
                    <ul class="space-y-2">
                        @foreach ($results['users'] as $user)
                            <li>
                                <a href="{{ $user['url'] }}" class="flex items-center p-2 hover:bg-gray-100 rounded-md">
                                    @if ($user['avatar'])
                                        <img 
                                            src="{{ $user['avatar'] }}" 
                                            alt="{{ $user['name'] }}" 
                                            class="h-8 w-8 rounded-full object-cover"
                                        >
                                    @else
                                        <x-flux-avatar 
                                            :name="$user['name']" 
                                            class="h-8 w-8"
                                        />
                                    @endif
                                    
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">
                                            {{ $user['given_name'] }} {{ $user['family_name'] }}
                                        </p>
                                        <p class="text-xs text-gray-500">
                                            {{ $user['email'] }}
                                        </p>
                                    </div>
                                    
                                    <x-flux-badge class="ml-auto">
                                        {{ ucfirst($user['type']) }}
                                    </x-flux-badge>
                                </a>
                            </li>
                        @endforeach
                    </ul>
                </div>
            @endif
            
            @if (count($results['teams']) > 0)
                <div class="py-4">
                    <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                        Teams
                    </h3>
                    <ul class="space-y-2">
                        @foreach ($results['teams'] as $team)
                            <li>
                                <a href="{{ $team['url'] }}" class="flex items-center p-2 hover:bg-gray-100 rounded-md">
                                    <x-flux-icon name="users" class="h-8 w-8 text-gray-400" />
                                    
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">
                                            {{ $team['name'] }}
                                        </p>
                                        @if ($team['description'])
                                            <p class="text-xs text-gray-500">
                                                {{ Str::limit($team['description'], 50) }}
                                            </p>
                                        @endif
                                    </div>
                                </a>
                            </li>
                        @endforeach
                    </ul>
                </div>
            @endif
            
            @if (count($results['messages']) > 0)
                <div class="py-4">
                    <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                        Messages
                    </h3>
                    <ul class="space-y-2">
                        @foreach ($results['messages'] as $message)
                            <li>
                                <a href="{{ $message['url'] }}" class="flex items-center p-2 hover:bg-gray-100 rounded-md">
                                    <x-flux-icon name="chat-bubble-left-right" class="h-8 w-8 text-gray-400" />
                                    
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">
                                            {{ Str::limit($message['content'], 50) }}
                                        </p>
                                        <p class="text-xs text-gray-500">
                                            {{ $message['user_name'] }} in {{ $message['team_name'] }} • {{ $message['created_at'] }}
                                        </p>
                                    </div>
                                </a>
                            </li>
                        @endforeach
                    </ul>
                </div>
            @endif
        </div>
    </div>
</div>
```

### Step 6: Add the Component to the Layout

Add the search component to your application layout:

```php
<!-- resources/views/components/layouts/app.blade.php -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex justify-between h-16">
        <div class="flex">
            <!-- Logo -->
            <div class="shrink-0 flex items-center">
                <a href="{{ route('dashboard') }}">
                    <x-application-logo class="block h-9 w-auto fill-current text-gray-800" />
                </a>
            </div>

            <!-- Navigation Links -->
            <div class="hidden space-x-8 sm:-my-px sm:ml-10 sm:flex">
                <x-nav-link :href="route('dashboard')" :active="request()->routeIs('dashboard')">
                    {{ __('Dashboard') }}
                </x-nav-link>
                <!-- Other navigation links -->
            </div>
        </div>

        <!-- Search -->
        <div class="hidden sm:flex sm:items-center sm:ml-6 w-1/3">
            <livewire:search.global-search />
        </div>

        <!-- Settings Dropdown -->
        <div class="hidden sm:flex sm:items-center sm:ml-6">
            <!-- User dropdown menu -->
        </div>
    </div>
</div>
```

## Flux UI Components Used

### Basic Components

- **x-flux-input**: Text input field for search with icons
- **x-flux-avatar**: User avatar with initials fallback
- **x-flux-badge**: User type badge
- **x-flux-icon**: Icons for search results

## What This Does

- Creates a global search component that searches users, teams, and messages
- Uses Laravel Scout with Typesense for fast, typo-tolerant search
- Updates search results in real-time as the user types
- Displays results in a dropdown with different sections
- Uses Flux UI components for a polished interface

## Verification

1. Ensure Typesense is running
2. Import your data to Typesense using the Scout commands
3. Add the search component to your layout
4. Try searching for users, teams, and messages
5. Verify that results appear as you type
6. Click on a result to navigate to the corresponding page

## Troubleshooting

### Issue: No search results appearing

**Solution:** Ensure Typesense is running and that you've imported your data using the Scout commands. Check the Typesense logs for any errors.

### Issue: Search results not updating in real-time

**Solution:** Ensure you're using the `wire:model.live.debounce.300ms` directive on the search input to debounce the input and update the results in real-time.

### Issue: Incorrect search results

**Solution:** Verify your model's `toSearchableArray` method to ensure it's returning the correct data for indexing.

## Next Steps

Now that we have implemented the search feature with Flux UI components, let's move on to implementing the user settings feature.
