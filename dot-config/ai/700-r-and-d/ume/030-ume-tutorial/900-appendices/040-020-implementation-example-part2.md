# Implementation Example: User Preferences System (Part 2)

<link rel="stylesheet" href="../assets/css/styles.css">

## 3. MVP Implementation (Continued)

### 3.5 Update User Model

```php
<?php

namespace App\Models;

use App\Settings\UserPreferences;
use App\Services\UserPreferencesService;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;
    
    // ... existing code ...
    
    /**
     * Get the user's preferences.
     *
     * @return UserPreferences
     */
    public function preferences(): UserPreferences
    {
        return app(UserPreferencesService::class)->getPreferences($this);
    }
    
    /**
     * Update the user's preferences.
     *
     * @param array $preferences
     * @return UserPreferences
     */
    public function updatePreferences(array $preferences): UserPreferences
    {
        return app(UserPreferencesService::class)->updatePreferences($this, $preferences);
    }
    
    /**
     * Reset the user's preferences to default values.
     *
     * @return UserPreferences
     */
    public function resetPreferences(): UserPreferences
    {
        return app(UserPreferencesService::class)->resetPreferences($this);
    }
}
```

### 3.6 Create Livewire Component for User Preferences

```php
<?php

namespace App\Livewire;

use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class UserPreferencesManager extends Component
{
    public string $theme;
    public string $language;
    public array $notificationChannels;
    public array $enabledBetaFeatures;
    public array $availableLanguages;
    public array $availableThemes;
    public array $availableNotificationTypes;
    public array $availableChannels;
    public array $availableBetaFeatures;
    
    public function mount()
    {
        $user = Auth::user();
        $preferences = $user->preferences();
        
        $this->theme = $preferences->theme;
        $this->language = $preferences->language;
        $this->notificationChannels = $preferences->notificationChannels;
        $this->enabledBetaFeatures = $preferences->enabledBetaFeatures;
        
        // Define available options
        $this->availableThemes = [
            'light' => 'Light Mode',
            'dark' => 'Dark Mode',
            'system' => 'System Default',
        ];
        
        $this->availableLanguages = [
            'en' => 'English',
            'es' => 'Spanish',
            'fr' => 'French',
            // Add more languages as needed
        ];
        
        $this->availableNotificationTypes = [
            'account' => 'Account Notifications',
            'team' => 'Team Notifications',
            'system' => 'System Notifications',
        ];
        
        $this->availableChannels = [
            'email' => 'Email',
            'database' => 'In-App',
            'sms' => 'SMS',
        ];
        
        $this->availableBetaFeatures = [
            'advanced-search' => 'Advanced Search',
            'ai-suggestions' => 'AI Suggestions',
            'new-dashboard' => 'New Dashboard Layout',
        ];
    }
    
    public function updatePreferences()
    {
        $user = Auth::user();
        
        $user->updatePreferences([
            'theme' => $this->theme,
            'language' => $this->language,
            'notificationChannels' => $this->notificationChannels,
            'enabledBetaFeatures' => $this->enabledBetaFeatures,
        ]);
        
        $this->dispatch('preferences-updated');
        
        session()->flash('message', 'Preferences updated successfully.');
    }
    
    public function resetPreferences()
    {
        $user = Auth::user();
        $preferences = $user->resetPreferences();
        
        $this->theme = $preferences->theme;
        $this->language = $preferences->language;
        $this->notificationChannels = $preferences->notificationChannels;
        $this->enabledBetaFeatures = $preferences->enabledBetaFeatures;
        
        $this->dispatch('preferences-updated');
        
        session()->flash('message', 'Preferences reset to defaults.');
    }
    
    public function toggleBetaFeature($feature)
    {
        if (in_array($feature, $this->enabledBetaFeatures)) {
            $this->enabledBetaFeatures = array_diff($this->enabledBetaFeatures, [$feature]);
        } else {
            $this->enabledBetaFeatures[] = $feature;
        }
    }
    
    public function toggleNotificationChannel($type, $channel)
    {
        if (in_array($channel, $this->notificationChannels[$type])) {
            $this->notificationChannels[$type] = array_diff($this->notificationChannels[$type], [$channel]);
        } else {
            $this->notificationChannels[$type][] = $channel;
        }
    }
    
    public function render()
    {
        return view('livewire.user-preferences-manager');
    }
}
```

### 3.7 Create Blade View for User Preferences

```blade
<div>
    <x-flux-card>
        <x-slot name="header">
            <h2 class="text-lg font-medium">{{ __('User Preferences') }}</h2>
            <p class="mt-1 text-sm text-gray-500">
                {{ __('Customize your application experience with these settings.') }}
            </p>
        </x-slot>

        <x-flux-form wire:submit="updatePreferences">
            <!-- Theme Preferences -->
            <div class="mb-6">
                <x-flux-label for="theme" value="{{ __('Theme') }}" />
                <x-flux-select id="theme" wire:model="theme" class="mt-1 block w-full">
                    @foreach($availableThemes as $value => $label)
                        <option value="{{ $value }}">{{ $label }}</option>
                    @endforeach
                </x-flux-select>
            </div>

            <!-- Language Preferences -->
            <div class="mb-6">
                <x-flux-label for="language" value="{{ __('Language') }}" />
                <x-flux-select id="language" wire:model="language" class="mt-1 block w-full">
                    @foreach($availableLanguages as $value => $label)
                        <option value="{{ $value }}">{{ $label }}</option>
                    @endforeach
                </x-flux-select>
            </div>

            <!-- Notification Preferences -->
            <div class="mb-6">
                <x-flux-label value="{{ __('Notification Preferences') }}" />
                <div class="mt-2 space-y-4">
                    @foreach($availableNotificationTypes as $type => $typeLabel)
                        <div>
                            <h4 class="font-medium text-sm">{{ $typeLabel }}</h4>
                            <div class="mt-2 flex flex-wrap gap-2">
                                @foreach($availableChannels as $channel => $channelLabel)
                                    <x-flux-checkbox-card 
                                        :checked="in_array($channel, $notificationChannels[$type])"
                                        wire:click="toggleNotificationChannel('{{ $type }}', '{{ $channel }}')"
                                    >
                                        {{ $channelLabel }}
                                    </x-flux-checkbox-card>
                                @endforeach
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            <!-- Beta Features -->
            <div class="mb-6">
                <x-flux-label value="{{ __('Beta Features') }}" />
                <p class="mt-1 text-sm text-gray-500">
                    {{ __('Opt in to try new features before they are officially released.') }}
                </p>
                <div class="mt-2 space-y-2">
                    @foreach($availableBetaFeatures as $feature => $featureLabel)
                        <x-flux-checkbox-card 
                            :checked="in_array($feature, $enabledBetaFeatures)"
                            wire:click="toggleBetaFeature('{{ $feature }}')"
                        >
                            {{ $featureLabel }}
                        </x-flux-checkbox-card>
                    @endforeach
                </div>
            </div>

            <div class="flex items-center justify-between">
                <x-flux-button type="submit">
                    {{ __('Save Preferences') }}
                </x-flux-button>

                <x-flux-button type="button" variant="secondary" wire:click="resetPreferences">
                    {{ __('Reset to Defaults') }}
                </x-flux-button>
            </div>
        </x-flux-form>
    </x-flux-card>

    <!-- Flash Message -->
    @if (session()->has('message'))
        <div class="mt-4">
            <x-flux-alert type="success" dismissible>
                {{ session('message') }}
            </x-flux-alert>
        </div>
    @endif
</div>
```
