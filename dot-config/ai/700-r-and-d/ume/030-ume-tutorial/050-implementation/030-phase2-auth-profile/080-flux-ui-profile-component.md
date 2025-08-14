# Implementing Profile UI with Flux UI Components

<link rel="stylesheet" href="../../assets/css/styles.css">

## Goal

Create a user profile edit form using Livewire/Volt with Flux UI components, implementing our enhanced user profile with split name components and avatar upload.

## Prerequisites

- Completed Phase 1 (Core Models & STI)
- Flux UI components installed
- User model with enhanced profile fields

## Implementation

We'll create a Volt component for editing the user profile, leveraging Flux UI components for a polished interface.

### Step 1: Create the Volt Component

Create a new file at `resources/views/livewire/profile/edit-profile.blade.php`:

```php
<?php

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Volt\Component;
use Livewire\WithFileUploads;

new class extends Component {
    use WithFileUploads;

    public User $user;
    public string $given_name = '';
    public string $family_name = '';
    public string $other_names = '';
    public string $email = '';
    public $avatar;

    public function mount(): void
    {
        $this->user = Auth::user();
        $this->given_name = $this->user->given_name;
        $this->family_name = $this->user->family_name;
        $this->other_names = $this->user->other_names ?? '';
        $this->email = $this->user->email;
    }

    public function updateProfile(): void
    {
        $validated = $this->validate([
            'given_name' => ['required', 'string', 'max:255'],
            'family_name' => ['required', 'string', 'max:255'],
            'other_names' => ['nullable', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email,' . $this->user->id],
            'avatar' => ['nullable', 'image', 'max:1024'],
        ]);

        $this->user->given_name = $this->given_name;
        $this->user->family_name = $this->family_name;
        $this->user->other_names = $this->other_names;
        $this->user->email = $this->email;
        
        if ($this->avatar) {
            $this->user->addMedia($this->avatar->getRealPath())
                ->usingName($this->avatar->getClientOriginalName())
                ->toMediaCollection('avatar');
        }

        $this->user->save();

        $this->dispatch('profile-updated', [
            'title' => 'Profile Updated',
            'message' => 'Your profile information has been updated successfully.',
            'type' => 'success',
        ]);
    }
}; ?>

<div>
    <x-flux-card>
        <x-flux-card-header>
            <h2 class="text-lg font-medium">Profile Information</h2>
            <p class="mt-1 text-sm text-gray-500">
                Update your account's profile information and email address.
            </p>
        </x-flux-card-header>
        
        <x-flux-card-body>
            <form wire:submit="updateProfile" class="space-y-6">
                <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <!-- Given Name -->
                    <x-flux-input
                        label="Given Name"
                        wire:model="given_name"
                        placeholder="Enter your given name"
                        required
                    />
                    
                    <!-- Family Name -->
                    <x-flux-input
                        label="Family Name"
                        wire:model="family_name"
                        placeholder="Enter your family name"
                        required
                    />
                </div>
                
                <!-- Other Names -->
                <x-flux-input
                    label="Other Names"
                    wire:model="other_names"
                    placeholder="Enter any middle names or titles (optional)"
                />
                
                <!-- Email -->
                <x-flux-input
                    type="email"
                    label="Email"
                    wire:model="email"
                    placeholder="Enter your email address"
                    required
                />
                
                <!-- Avatar Upload -->
                <div>
                    <x-flux-pro-file-upload
                        label="Profile Picture"
                        wire:model="avatar"
                        accept="image/*"
                        :preview="true"
                    />
                    
                    @if($user->getFirstMediaUrl('avatar'))
                        <div class="mt-2">
                            <p class="text-sm text-gray-500">Current Avatar:</p>
                            <img 
                                src="{{ $user->getFirstMediaUrl('avatar') }}" 
                                alt="Current avatar" 
                                class="mt-1 h-20 w-20 rounded-full object-cover"
                            >
                        </div>
                    @endif
                </div>
                
                <div class="flex items-center gap-4">
                    <x-flux-button type="submit">
                        Save
                    </x-flux-button>
                    
                    <x-flux-action-message on="profile-updated">
                        Saved.
                    </x-flux-action-message>
                </div>
            </form>
        </x-flux-card-body>
    </x-flux-card>
    
    <!-- Notification Toast -->
    <x-flux-pro-toast />
</div>
```

### Step 2: Add the Route

Add a route in `routes/web.php`:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    // Existing routes...
    
    Route::get('/profile/edit', Livewire\Volt\Volt::class)
        ->withComponent('profile.edit-profile')
        ->name('profile.edit');
});
```

### Step 3: Add a Link in the Navigation

Update your navigation menu to include a link to the profile edit page:

```php
<x-flux-nav-link :href="route('profile.edit')" :active="request()->routeIs('profile.edit')">
    Profile
</x-flux-nav-link>
```

## What This Does

- Creates a Volt component for editing the user profile
- Uses Flux UI components for the form inputs
- Implements avatar upload using Spatie Media Library
- Displays success notifications using Flux Pro Toast component

## Flux UI Components Used

### Basic Components

- **x-flux-card**: Container with styling for a card layout
- **x-flux-card-header**: Header section of the card
- **x-flux-card-body**: Body section of the card
- **x-flux-input**: Text input field with label and validation
- **x-flux-button**: Styled button with various states
- **x-flux-action-message**: Temporary message that appears after an action

### Pro Components

- **x-flux-pro-file-upload**: Advanced file upload with preview
- **x-flux-pro-toast**: Notification toast for success/error messages

## Verification

1. Visit `/profile/edit` in your browser
2. Fill out the form with valid information
3. Upload an image for the avatar
4. Submit the form
5. Verify that a success message appears
6. Check the database to ensure the user record was updated
7. Check the media library to ensure the avatar was uploaded

## Troubleshooting

### Issue: File upload not working

**Solution:** Ensure you have the `WithFileUploads` trait in your component and that the media library is properly configured.

### Issue: Validation errors not showing

**Solution:** Flux UI components automatically display validation errors. Ensure your validation rules are correct and that you're using the `wire:model` directive on your inputs.

### Issue: Toast notifications not appearing

**Solution:** Ensure you have the Flux Pro package installed and that you've included the `<x-flux-pro-toast />` component in your view.

## Next Steps

Now that we have implemented the profile edit form with Flux UI components, let's move on to implementing the Two-Factor Authentication UI.
