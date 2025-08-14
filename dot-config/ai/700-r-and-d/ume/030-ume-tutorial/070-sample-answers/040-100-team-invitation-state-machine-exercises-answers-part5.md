# Team Invitation State Machine Exercises - Sample Answers (Part 5)

## Exercise 5: Creating a Dashboard for Team Invitation Management

**Create a Livewire component for a team invitation management dashboard.**

First, let's create the Livewire component:

```php
<?php

namespace App\Http\Livewire\Teams;

use App\Enums\TeamInvitationStatus;
use App\Models\Team;
use App\Models\TeamInvitation;
use App\States\TeamInvitation\Accepted;
use App\States\TeamInvitation\Expired;
use App\States\TeamInvitation\Pending;
use App\States\TeamInvitation\Rejected;
use App\States\TeamInvitation\Revoked;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Livewire\Component;
use Livewire\WithPagination;

class InvitationDashboard extends Component
{
    use AuthorizesRequests, WithPagination;

    public Team $team;
    public $selectedState = 'all';
    public $search = '';
    public $perPage = 10;

    protected $queryString = [
        'selectedState' => ['except' => 'all'],
        'search' => ['except' => ''],
        'perPage' => ['except' => 10],
    ];

    protected $listeners = [
        'invitationSent' => '$refresh',
        'invitationRevoked' => '$refresh',
        'invitationResent' => '$refresh',
    ];

    public function mount(Team $team)
    {
        $this->team = $team;
    }

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function updatingSelectedState()
    {
        $this->resetPage();
    }

    public function getInvitationsProperty()
    {
        $this->authorize('viewAny', [TeamInvitation::class, $this->team]);

        $query = TeamInvitation::query()
            ->where('team_id', $this->team->id);

        // Filter by state
        if ($this->selectedState !== 'all') {
            $stateClass = match ($this->selectedState) {
                'pending' => Pending::class,
                'accepted' => Accepted::class,
                'rejected' => Rejected::class,
                'expired' => Expired::class,
                'revoked' => Revoked::class,
                default => null,
            };

            if ($stateClass) {
                $query->whereState('state', $stateClass);
            }
        }

        // Search by email
        if ($this->search) {
            $query->where('email', 'like', '%' . $this->search . '%');
        }

        return $query->orderBy('created_at', 'desc')
            ->paginate($this->perPage);
    }

    public function revoke(TeamInvitation $invitation, $reason = null)
    {
        $this->authorize('revoke', [$this->team, $invitation]);

        try {
            $invitation->revoke(auth()->user(), $reason);
            $this->emit('invitationRevoked');
        } catch (\Exception $e) {
            $this->addError('revoke', $e->getMessage());
        }
    }

    public function resend(TeamInvitation $invitation)
    {
        $this->authorize('resend', [$this->team, $invitation]);

        try {
            app(TeamInvitationController::class)->resend($this->team, $invitation);
            $this->emit('invitationResent');
        } catch (\Exception $e) {
            $this->addError('resend', $e->getMessage());
        }
    }

    public function render()
    {
        return view('livewire.teams.invitation-dashboard', [
            'invitations' => $this->invitations,
            'states' => [
                'all' => 'All',
                'pending' => 'Pending',
                'accepted' => 'Accepted',
                'rejected' => 'Rejected',
                'expired' => 'Expired',
                'revoked' => 'Revoked',
            ],
        ]);
    }
}
```

Now, let's create the view for the component:

```blade
<div>
    <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-medium text-gray-900">Team Invitation Management</h3>
        
        <div class="mt-4 flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2">
            <div class="flex-1">
                <label for="search" class="sr-only">Search</label>
                <input type="text" id="search" wire:model.debounce.300ms="search" placeholder="Search by email" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
            </div>
            
            <div>
                <label for="state" class="sr-only">State</label>
                <select id="state" wire:model="selectedState" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                    @foreach($states as $value => $label)
                        <option value="{{ $value }}">{{ $label }}</option>
                    @endforeach
                </select>
            </div>
            
            <div>
                <label for="perPage" class="sr-only">Per Page</label>
                <select id="perPage" wire:model="perPage" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
                    <option value="10">10 per page</option>
                    <option value="25">25 per page</option>
                    <option value="50">50 per page</option>
                    <option value="100">100 per page</option>
                </select>
            </div>
        </div>
        
        @if($invitations->isEmpty())
            <p class="mt-4 text-sm text-gray-500">No invitations found.</p>
        @else
            <div class="mt-4 overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">State</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expires</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @foreach($invitations as $invitation)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $invitation->email }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ ucfirst($invitation->role) }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm">
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $invitation->state->tailwindClasses() }}">
                                        {{ $invitation->state->label() }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $invitation->created_at->format('Y-m-d H:i') }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    @if($invitation->isPending())
                                        @if($invitation->hasExpired())
                                            <span class="text-red-500">Expired</span>
                                        @else
                                            {{ $invitation->expires_at->format('Y-m-d H:i') }}
                                            <span class="text-gray-400">({{ $invitation->expires_at->diffForHumans() }})</span>
                                        @endif
                                    @else
                                        N/A
                                    @endif
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    @if($invitation->isPending())
                                        @can('resend', [$team, $invitation])
                                            <button wire:click="resend({{ $invitation->id }})" class="text-indigo-600 hover:text-indigo-900 mr-3">Resend</button>
                                        @endcan
                                        
                                        @can('revoke', [$team, $invitation])
                                            <button wire:click="revoke({{ $invitation->id }})" class="text-red-600 hover:text-red-900">Revoke</button>
                                        @endcan
                                    @else
                                        <span class="text-gray-400">No actions available</span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            
            <div class="mt-4">
                {{ $invitations->links() }}
            </div>
        @endif
        
        @error('revoke') <div class="mt-4 text-red-500 text-sm">{{ $message }}</div> @enderror
        @error('resend') <div class="mt-4 text-red-500 text-sm">{{ $message }}</div> @enderror
    </div>
</div>
```
