# Team Hierarchy State Integration (Part 3)

<link rel="stylesheet" href="../../../assets/css/styles.css">

## Creating the Livewire Component View

Now, let's create the view for our TeamStateManager component:

```html
<!-- resources/views/livewire/team-state-manager.blade.php -->
<div>
    <!-- Team State Badge -->
    <div class="mb-4">
        <span class="px-3 py-1 text-sm rounded-full {{ $team->hierarchy_state->tailwindClasses() }}">
            <i class="fas fa-{{ $team->hierarchy_state->icon() }} mr-1"></i>
            {{ $team->hierarchy_state->label() }}
        </span>
    </div>

    <!-- State Actions -->
    <div class="flex flex-wrap gap-2 mt-4">
        @if ($canApprove)
            <button wire:click="$set('showApproveModal', true)" class="btn btn-primary btn-sm">
                <i class="fas fa-check-circle mr-1"></i> Approve
            </button>
        @endif

        @if ($canSuspend)
            <button wire:click="$set('showSuspendModal', true)" class="btn btn-warning btn-sm">
                <i class="fas fa-ban mr-1"></i> Suspend
            </button>
        @endif

        @if ($canReactivate)
            <button wire:click="$set('showReactivateModal', true)" class="btn btn-success btn-sm">
                <i class="fas fa-play-circle mr-1"></i> Reactivate
            </button>
        @endif

        @if ($canArchive)
            <button wire:click="$set('showArchiveModal', true)" class="btn btn-danger btn-sm">
                <i class="fas fa-archive mr-1"></i> Archive
            </button>
        @endif

        @if ($canRestore)
            <button wire:click="$set('showRestoreModal', true)" class="btn btn-info btn-sm">
                <i class="fas fa-box-open mr-1"></i> Restore
            </button>
        @endif
    </div>

    <!-- Approve Modal -->
    <x-modal wire:model="showApproveModal">
        <x-slot name="title">Approve Team</x-slot>
        <x-slot name="content">
            <p class="mb-4">Are you sure you want to approve the team "{{ $team->name }}"?</p>
            
            <div class="mb-4">
                <x-label for="notes" value="Notes (Optional)" />
                <x-textarea id="notes" wire:model="notes" class="w-full" rows="3" />
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-secondary-button wire:click="$set('showApproveModal', false)">Cancel</x-secondary-button>
            <x-button wire:click="approve" class="ml-2">Approve Team</x-button>
        </x-slot>
    </x-modal>

    <!-- Suspend Modal -->
    <x-modal wire:model="showSuspendModal">
        <x-slot name="title">Suspend Team</x-slot>
        <x-slot name="content">
            <p class="mb-4">Are you sure you want to suspend the team "{{ $team->name }}"?</p>
            
            <div class="mb-4">
                <x-label for="reason" value="Reason" />
                <x-input id="reason" type="text" wire:model="reason" class="w-full" required />
                @error('reason') <span class="text-red-500 text-sm">{{ $message }}</span> @enderror
            </div>
            
            <div class="mb-4">
                <x-label for="notes" value="Additional Notes (Optional)" />
                <x-textarea id="notes" wire:model="notes" class="w-full" rows="3" />
            </div>
            
            @if ($hasChildren)
                <div class="mb-4">
                    <label class="flex items-center">
                        <x-checkbox wire:model="cascadeToChildren" />
                        <span class="ml-2">Also suspend all child teams</span>
                    </label>
                </div>
            @endif
        </x-slot>
        <x-slot name="footer">
            <x-secondary-button wire:click="$set('showSuspendModal', false)">Cancel</x-secondary-button>
            <x-danger-button wire:click="suspend" class="ml-2">Suspend Team</x-danger-button>
        </x-slot>
    </x-modal>

    <!-- Reactivate Modal -->
    <x-modal wire:model="showReactivateModal">
        <x-slot name="title">Reactivate Team</x-slot>
        <x-slot name="content">
            <p class="mb-4">Are you sure you want to reactivate the team "{{ $team->name }}"?</p>
            
            <div class="mb-4">
                <x-label for="notes" value="Notes (Optional)" />
                <x-textarea id="notes" wire:model="notes" class="w-full" rows="3" />
            </div>
            
            @if ($hasChildren)
                <div class="mb-4">
                    <label class="flex items-center">
                        <x-checkbox wire:model="cascadeToChildren" />
                        <span class="ml-2">Also reactivate all suspended child teams</span>
                    </label>
                </div>
            @endif
        </x-slot>
        <x-slot name="footer">
            <x-secondary-button wire:click="$set('showReactivateModal', false)">Cancel</x-secondary-button>
            <x-button wire:click="reactivate" class="ml-2">Reactivate Team</x-button>
        </x-slot>
    </x-modal>

    <!-- Archive Modal -->
    <x-modal wire:model="showArchiveModal">
        <x-slot name="title">Archive Team</x-slot>
        <x-slot name="content">
            <p class="mb-4">Are you sure you want to archive the team "{{ $team->name }}"?</p>
            
            <div class="mb-4">
                <x-label for="reason" value="Reason (Optional)" />
                <x-input id="reason" type="text" wire:model="reason" class="w-full" />
            </div>
            
            <div class="mb-4">
                <x-label for="notes" value="Additional Notes (Optional)" />
                <x-textarea id="notes" wire:model="notes" class="w-full" rows="3" />
            </div>
            
            @if ($hasChildren)
                <div class="mb-4">
                    <label class="flex items-center">
                        <x-checkbox wire:model="cascadeToChildren" />
                        <span class="ml-2">Also archive all child teams</span>
                    </label>
                </div>
            @endif
        </x-slot>
        <x-slot name="footer">
            <x-secondary-button wire:click="$set('showArchiveModal', false)">Cancel</x-secondary-button>
            <x-danger-button wire:click="archive" class="ml-2">Archive Team</x-danger-button>
        </x-slot>
    </x-modal>

    <!-- Restore Modal -->
    <x-modal wire:model="showRestoreModal">
        <x-slot name="title">Restore Team</x-slot>
        <x-slot name="content">
            <p class="mb-4">Are you sure you want to restore the team "{{ $team->name }}"?</p>
            
            <div class="mb-4">
                <x-label for="notes" value="Notes (Optional)" />
                <x-textarea id="notes" wire:model="notes" class="w-full" rows="3" />
            </div>
            
            @if ($hasChildren)
                <div class="mb-4">
                    <label class="flex items-center">
                        <x-checkbox wire:model="cascadeToChildren" />
                        <span class="ml-2">Also restore all archived child teams</span>
                    </label>
                </div>
            @endif
        </x-slot>
        <x-slot name="footer">
            <x-secondary-button wire:click="$set('showRestoreModal', false)">Cancel</x-secondary-button>
            <x-button wire:click="restore" class="ml-2">Restore Team</x-button>
        </x-slot>
    </x-modal>
</div>
```

## Displaying Team State in the Team Hierarchy

Let's update our team hierarchy view to display the state of each team:

```html
<!-- resources/views/teams/hierarchy.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Team Hierarchy') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">{{ $team->name }}</h3>
                    
                    <!-- Team State Manager -->
                    <livewire:team-state-manager :team="$team" />
                    
                    <!-- Team Hierarchy Tree -->
                    <div class="mt-6">
                        <h4 class="text-md font-semibold mb-2">Child Teams</h4>
                        
                        @if ($team->children->count() > 0)
                            <ul class="pl-6 border-l-2 border-gray-200">
                                @foreach ($team->children as $childTeam)
                                    <li class="mb-4">
                                        <div class="flex items-center">
                                            <a href="{{ route('teams.show', $childTeam) }}" class="text-blue-600 hover:underline">
                                                {{ $childTeam->name }}
                                            </a>
                                            <span class="ml-2 px-2 py-0.5 text-xs rounded-full {{ $childTeam->hierarchy_state->tailwindClasses() }}">
                                                {{ $childTeam->hierarchy_state->label() }}
                                            </span>
                                        </div>
                                        
                                        @if ($childTeam->children->count() > 0)
                                            <ul class="pl-6 mt-2 border-l-2 border-gray-100">
                                                @foreach ($childTeam->children as $grandchildTeam)
                                                    <li class="mb-2">
                                                        <div class="flex items-center">
                                                            <a href="{{ route('teams.show', $grandchildTeam) }}" class="text-blue-600 hover:underline">
                                                                {{ $grandchildTeam->name }}
                                                            </a>
                                                            <span class="ml-2 px-2 py-0.5 text-xs rounded-full {{ $grandchildTeam->hierarchy_state->tailwindClasses() }}">
                                                                {{ $grandchildTeam->hierarchy_state->label() }}
                                                            </span>
                                                        </div>
                                                    </li>
                                                @endforeach
                                            </ul>
                                        @endif
                                    </li>
                                @endforeach
                            </ul>
                        @else
                            <p class="text-gray-500">No child teams found.</p>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```
