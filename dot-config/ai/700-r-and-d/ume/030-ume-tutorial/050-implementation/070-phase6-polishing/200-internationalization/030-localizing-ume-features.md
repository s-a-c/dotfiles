# Localizing UME Features

<link rel="stylesheet" href="../../../../assets/css/styles.css">

## Goal

Learn how to localize specific features of the UME application to provide a seamless experience for users in different languages and regions.

## Prerequisites

- Completed the [Setting Up Internationalization](./010-setting-up-i18n.md) guide
- Completed the [Translation Management](./020-translation-management.md) guide
- Basic understanding of Laravel's translation system

## Implementation Steps

### Step 1: Localize User Authentication

First, let's localize the authentication features of the UME application:

#### Create Authentication Translation Files

Create a file for authentication translations in each language:

**resources/lang/en/auth.php**:
```php
<?php

return [
    'login' => [
        'title' => 'Log in to your account',
        'email' => 'Email address',
        'password' => 'Password',
        'remember' => 'Remember me',
        'forgot' => 'Forgot your password?',
        'button' => 'Log in',
        'no_account' => 'Don\'t have an account?',
        'register' => 'Register',
    ],
    'register' => [
        'title' => 'Create a new account',
        'name' => 'Name',
        'email' => 'Email address',
        'password' => 'Password',
        'confirm_password' => 'Confirm password',
        'button' => 'Register',
        'have_account' => 'Already have an account?',
        'login' => 'Log in',
    ],
    'forgot_password' => [
        'title' => 'Forgot your password?',
        'description' => 'No problem. Just let us know your email address and we will email you a password reset link that will allow you to choose a new one.',
        'email' => 'Email address',
        'button' => 'Email Password Reset Link',
    ],
    'reset_password' => [
        'title' => 'Reset password',
        'email' => 'Email address',
        'password' => 'Password',
        'confirm_password' => 'Confirm password',
        'button' => 'Reset Password',
    ],
    'verify_email' => [
        'title' => 'Verify your email address',
        'description' => 'Thanks for signing up! Before getting started, could you verify your email address by clicking on the link we just emailed to you? If you didn\'t receive the email, we will gladly send you another.',
        'verification_sent' => 'A new verification link has been sent to your email address.',
        'resend' => 'Resend Verification Email',
        'logout' => 'Log Out',
    ],
    'two_factor' => [
        'title' => 'Two-factor authentication',
        'description' => 'Please confirm access to your account by entering the authentication code provided by your authenticator application.',
        'code' => 'Code',
        'recovery_code' => 'Recovery Code',
        'button' => 'Confirm',
        'use_recovery' => 'Use a recovery code',
        'use_authentication' => 'Use an authentication code',
    ],
    'failed' => 'These credentials do not match our records.',
    'password' => 'The provided password is incorrect.',
    'throttle' => 'Too many login attempts. Please try again in :seconds seconds.',
];
```

Create similar files for other languages (es, fr, ar).

#### Update Authentication Views

Update the authentication views to use the translation keys:

**Login View**:
```php
<x-guest-layout>
    <x-auth-card>
        <x-slot name="logo">
            <a href="/">
                <x-application-logo class="h-20 w-20 fill-current text-gray-500" />
            </a>
        </x-slot>

        <!-- Session Status -->
        <x-auth-session-status class="mb-4" :status="session('status')" />

        <!-- Validation Errors -->
        <x-auth-validation-errors class="mb-4" :errors="$errors" />

        <form method="POST" action="{{ route('login') }}">
            @csrf

            <h1 class="mb-6 text-2xl font-bold text-center">{{ __('auth.login.title') }}</h1>

            <!-- Email Address -->
            <div>
                <x-label for="email" :value="__('auth.login.email')" />
                <x-input id="email" class="block mt-1 w-full" type="email" name="email" :value="old('email')" required autofocus />
            </div>

            <!-- Password -->
            <div class="mt-4">
                <x-label for="password" :value="__('auth.login.password')" />
                <x-input id="password" class="block mt-1 w-full" type="password" name="password" required autocomplete="current-password" />
            </div>

            <!-- Remember Me -->
            <div class="block mt-4">
                <label for="remember_me" class="inline-flex items-center">
                    <input id="remember_me" type="checkbox" class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50" name="remember">
                    <span class="ml-2 text-sm text-gray-600">{{ __('auth.login.remember') }}</span>
                </label>
            </div>

            <div class="flex items-center justify-end mt-4">
                @if (Route::has('password.request'))
                    <a class="underline text-sm text-gray-600 hover:text-gray-900" href="{{ route('password.request') }}">
                        {{ __('auth.login.forgot') }}
                    </a>
                @endif

                <x-button class="ml-3">
                    {{ __('auth.login.button') }}
                </x-button>
            </div>

            <div class="mt-6 text-center">
                <p class="text-sm text-gray-600">
                    {{ __('auth.login.no_account') }}
                    <a href="{{ route('register') }}" class="text-indigo-600 hover:text-indigo-900">
                        {{ __('auth.login.register') }}
                    </a>
                </p>
            </div>
        </form>
    </x-auth-card>
</x-guest-layout>
```

### Step 2: Localize User Profiles

Next, let's localize the user profile features:

#### Create Profile Translation Files

Create a file for profile translations in each language:

**resources/lang/en/profile.php**:
```php
<?php

return [
    'title' => 'User Profile',
    'personal_info' => [
        'title' => 'Personal Information',
        'name' => 'Name',
        'email' => 'Email Address',
        'phone' => 'Phone Number',
        'address' => 'Address',
        'bio' => 'Bio',
    ],
    'security' => [
        'title' => 'Security',
        'password' => 'Password',
        'current_password' => 'Current Password',
        'new_password' => 'New Password',
        'confirm_password' => 'Confirm Password',
        'two_factor' => 'Two-Factor Authentication',
        'enable_two_factor' => 'Enable Two-Factor Authentication',
        'disable_two_factor' => 'Disable Two-Factor Authentication',
    ],
    'preferences' => [
        'title' => 'Preferences',
        'language' => 'Language',
        'notifications' => 'Notifications',
        'email_notifications' => 'Email Notifications',
        'push_notifications' => 'Push Notifications',
        'theme' => 'Theme',
        'light' => 'Light',
        'dark' => 'Dark',
        'system' => 'System',
    ],
    'actions' => [
        'save' => 'Save Changes',
        'cancel' => 'Cancel',
        'delete_account' => 'Delete Account',
    ],
    'messages' => [
        'profile_updated' => 'Profile updated successfully.',
        'password_updated' => 'Password updated successfully.',
        'preferences_updated' => 'Preferences updated successfully.',
    ],
];
```

Create similar files for other languages (es, fr, ar).

#### Update Profile Views

Update the profile views to use the translation keys:

**Profile View**:
```php
<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold leading-tight text-gray-800">
            {{ __('profile.title') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="overflow-hidden bg-white shadow-xl sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-medium text-gray-900">
                        {{ __('profile.personal_info.title') }}
                    </h3>

                    <form action="{{ route('profile.update') }}" method="POST" class="mt-6 space-y-6">
                        @csrf
                        @method('PUT')

                        <div>
                            <x-label for="name" :value="__('profile.personal_info.name')" />
                            <x-input id="name" name="name" type="text" class="mt-1 block w-full" :value="old('name', $user->name)" required autofocus />
                            <x-input-error class="mt-2" :messages="$errors->get('name')" />
                        </div>

                        <div>
                            <x-label for="email" :value="__('profile.personal_info.email')" />
                            <x-input id="email" name="email" type="email" class="mt-1 block w-full" :value="old('email', $user->email)" required />
                            <x-input-error class="mt-2" :messages="$errors->get('email')" />
                        </div>

                        <div>
                            <x-label for="phone" :value="__('profile.personal_info.phone')" />
                            <x-input id="phone" name="phone" type="text" class="mt-1 block w-full" :value="old('phone', $user->phone)" />
                            <x-input-error class="mt-2" :messages="$errors->get('phone')" />
                        </div>

                        <div>
                            <x-label for="bio" :value="__('profile.personal_info.bio')" />
                            <x-textarea id="bio" name="bio" class="mt-1 block w-full" :value="old('bio', $user->bio)" />
                            <x-input-error class="mt-2" :messages="$errors->get('bio')" />
                        </div>

                        <div class="flex items-center gap-4">
                            <x-button>{{ __('profile.actions.save') }}</x-button>

                            @if (session('status') === 'profile-updated')
                                <p
                                    x-data="{ show: true }"
                                    x-show="show"
                                    x-transition
                                    x-init="setTimeout(() => show = false, 2000)"
                                    class="text-sm text-gray-600"
                                >{{ __('profile.messages.profile_updated') }}</p>
                            @endif
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

### Step 3: Localize Teams and Permissions

Next, let's localize the teams and permissions features:

#### Create Teams Translation Files

Create a file for teams translations in each language:

**resources/lang/en/teams.php**:
```php
<?php

return [
    'title' => 'Teams',
    'create' => [
        'title' => 'Create Team',
        'name' => 'Team Name',
        'description' => 'Team Description',
        'button' => 'Create',
    ],
    'edit' => [
        'title' => 'Edit Team',
        'name' => 'Team Name',
        'description' => 'Team Description',
        'button' => 'Update',
    ],
    'show' => [
        'title' => 'Team Details',
        'members' => 'Team Members',
        'roles' => 'Team Roles',
        'permissions' => 'Team Permissions',
    ],
    'members' => [
        'title' => 'Team Members',
        'add' => 'Add Member',
        'email' => 'Email Address',
        'role' => 'Role',
        'add_button' => 'Add',
        'remove' => 'Remove',
        'leave' => 'Leave Team',
    ],
    'roles' => [
        'title' => 'Team Roles',
        'add' => 'Add Role',
        'name' => 'Role Name',
        'description' => 'Role Description',
        'permissions' => 'Permissions',
        'add_button' => 'Add',
        'edit' => 'Edit',
        'delete' => 'Delete',
    ],
    'permissions' => [
        'title' => 'Team Permissions',
        'add' => 'Add Permission',
        'name' => 'Permission Name',
        'description' => 'Permission Description',
        'add_button' => 'Add',
        'edit' => 'Edit',
        'delete' => 'Delete',
    ],
    'messages' => [
        'team_created' => 'Team created successfully.',
        'team_updated' => 'Team updated successfully.',
        'team_deleted' => 'Team deleted successfully.',
        'member_added' => 'Member added successfully.',
        'member_removed' => 'Member removed successfully.',
        'role_added' => 'Role added successfully.',
        'role_updated' => 'Role updated successfully.',
        'role_deleted' => 'Role deleted successfully.',
        'permission_added' => 'Permission added successfully.',
        'permission_updated' => 'Permission updated successfully.',
        'permission_deleted' => 'Permission deleted successfully.',
    ],
];
```

Create similar files for other languages (es, fr, ar).

#### Update Teams Views

Update the teams views to use the translation keys:

**Teams Index View**:
```php
<x-app-layout>
    <x-slot name="header">
        <h2 class="text-xl font-semibold leading-tight text-gray-800">
            {{ __('teams.title') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
            <div class="mb-6 flex justify-end">
                <a href="{{ route('teams.create') }}" class="inline-flex items-center px-4 py-2 bg-indigo-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-indigo-700 focus:bg-indigo-700 active:bg-indigo-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150">
                    {{ __('teams.create.title') }}
                </a>
            </div>

            <div class="overflow-hidden bg-white shadow-xl sm:rounded-lg">
                <div class="p-6">
                    @if ($teams->isEmpty())
                        <p class="text-gray-500">{{ __('No teams found.') }}</p>
                    @else
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        {{ __('teams.create.name') }}
                                    </th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        {{ __('teams.create.description') }}
                                    </th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        {{ __('teams.members.title') }}
                                    </th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        {{ __('Actions') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                @foreach ($teams as $team)
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm font-medium text-gray-900">
                                                {{ $team->name }}
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-500">
                                                {{ $team->description }}
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-500">
                                                {{ $team->members_count }}
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                            <a href="{{ route('teams.show', $team) }}" class="text-indigo-600 hover:text-indigo-900">
                                                {{ __('View') }}
                                            </a>
                                            <a href="{{ route('teams.edit', $team) }}" class="ml-4 text-indigo-600 hover:text-indigo-900">
                                                {{ __('Edit') }}
                                            </a>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

### Step 4: Localize Notifications

Next, let's localize the notifications features:

#### Create Notifications Translation Files

Create a file for notifications translations in each language:

**resources/lang/en/notifications.php**:
```php
<?php

return [
    'title' => 'Notifications',
    'mark_all_read' => 'Mark all as read',
    'no_notifications' => 'No notifications.',
    'types' => [
        'team_invitation' => [
            'title' => 'Team Invitation',
            'body' => 'You have been invited to join the team :team.',
            'accept' => 'Accept',
            'reject' => 'Reject',
        ],
        'team_member_added' => [
            'title' => 'Team Member Added',
            'body' => ':user has joined the team :team.',
        ],
        'team_member_removed' => [
            'title' => 'Team Member Removed',
            'body' => ':user has left the team :team.',
        ],
        'role_assigned' => [
            'title' => 'Role Assigned',
            'body' => 'You have been assigned the role :role in the team :team.',
        ],
        'role_removed' => [
            'title' => 'Role Removed',
            'body' => 'Your role :role has been removed from the team :team.',
        ],
        'permission_granted' => [
            'title' => 'Permission Granted',
            'body' => 'You have been granted the permission :permission in the team :team.',
        ],
        'permission_revoked' => [
            'title' => 'Permission Revoked',
            'body' => 'Your permission :permission has been revoked from the team :team.',
        ],
    ],
    'settings' => [
        'title' => 'Notification Settings',
        'email' => [
            'title' => 'Email Notifications',
            'team_invitation' => 'Team invitations',
            'team_member_added' => 'Team member added',
            'team_member_removed' => 'Team member removed',
            'role_assigned' => 'Role assigned',
            'role_removed' => 'Role removed',
            'permission_granted' => 'Permission granted',
            'permission_revoked' => 'Permission revoked',
        ],
        'push' => [
            'title' => 'Push Notifications',
            'team_invitation' => 'Team invitations',
            'team_member_added' => 'Team member added',
            'team_member_removed' => 'Team member removed',
            'role_assigned' => 'Role assigned',
            'role_removed' => 'Role removed',
            'permission_granted' => 'Permission granted',
            'permission_revoked' => 'Permission revoked',
        ],
        'save' => 'Save Settings',
    ],
];
```

Create similar files for other languages (es, fr, ar).

#### Update Notification Classes

Update the notification classes to use the translation keys:

**TeamInvitationNotification.php**:
```php
<?php

namespace App\Notifications;

use App\Models\Team;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TeamInvitationNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $team;
    protected $invitedBy;

    public function __construct(Team $team, $invitedBy)
    {
        $this->team = $team;
        $this->invitedBy = $invitedBy;
    }

    public function via($notifiable)
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable)
    {
        $locale = $notifiable->locale ?? app()->getLocale();
        
        return (new MailMessage)
            ->subject(__('notifications.types.team_invitation.title', [], $locale))
            ->line(__('notifications.types.team_invitation.body', ['team' => $this->team->name], $locale))
            ->action(__('notifications.types.team_invitation.accept', [], $locale), url('/team-invitations/' . $this->team->id))
            ->line(__('Thank you for using our application!', [], $locale));
    }

    public function toArray($notifiable)
    {
        return [
            'team_id' => $this->team->id,
            'team_name' => $this->team->name,
            'invited_by' => $this->invitedBy->name,
        ];
    }
}
```

### Step 5: Localize Emails

Finally, let's localize the email templates:

#### Create Email Translation Files

Create a file for email translations in each language:

**resources/lang/en/emails.php**:
```php
<?php

return [
    'greeting' => 'Hello!',
    'salutation' => 'Regards,',
    'team' => 'The :app Team',
    'footer' => 'If you\'re having trouble clicking the ":actionText" button, copy and paste the URL below into your web browser:',
    'custom' => [
        'subject' => 'Welcome to :app',
        'line1' => 'Thank you for registering with :app!',
        'line2' => 'To get started, please verify your email address by clicking the button below:',
        'action' => 'Verify Email Address',
        'line3' => 'If you did not create an account, no further action is required.',
    ],
    'verify_email' => [
        'subject' => 'Verify Email Address',
        'line1' => 'Please click the button below to verify your email address.',
        'action' => 'Verify Email Address',
        'line2' => 'If you did not create an account, no further action is required.',
    ],
    'reset_password' => [
        'subject' => 'Reset Password Notification',
        'line1' => 'You are receiving this email because we received a password reset request for your account.',
        'action' => 'Reset Password',
        'line2' => 'This password reset link will expire in :count minutes.',
        'line3' => 'If you did not request a password reset, no further action is required.',
    ],
    'team_invitation' => [
        'subject' => 'Team Invitation',
        'line1' => 'You have been invited to join the team :team by :user.',
        'action' => 'Accept Invitation',
        'line2' => 'If you do not wish to join this team, no further action is required.',
    ],
];
```

Create similar files for other languages (es, fr, ar).

#### Update Email Templates

Update the email templates to use the translation keys:

**resources/views/emails/team-invitation.blade.php**:
```php
@component('mail::message')
# {{ __('emails.team_invitation.subject') }}

{{ __('emails.team_invitation.line1', ['team' => $team->name, 'user' => $invitedBy->name]) }}

@component('mail::button', ['url' => $acceptUrl])
{{ __('emails.team_invitation.action') }}
@endcomponent

{{ __('emails.team_invitation.line2') }}

{{ __('emails.salutation') }}<br>
{{ __('emails.team', ['app' => config('app.name')]) }}

@slot('footer')
@component('mail::footer')
{{ __('emails.footer', ['actionText' => __('emails.team_invitation.action')]) }}<br>
{{ $acceptUrl }}
@endcomponent
@endslot
@endcomponent
```

## Verification

To verify that your UME features are properly localized:

1. Test each feature in different languages
2. Check that all user-facing text is translated
3. Verify that dates, times, and numbers are formatted correctly
4. Test with right-to-left languages if supported
5. Check that emails are sent in the user's preferred language

## Troubleshooting

### Missing Translations

If translations are missing:

1. Use the `ScanMissingTranslations` command to find missing translations
2. Add the missing translations to the appropriate language files
3. Verify that the translation keys are used correctly in the views

### Incorrect Formatting

If dates, times, or numbers are not formatted correctly:

1. Check that the locale is set correctly
2. Use Laravel's localization helpers for formatting
3. Test with different locales to ensure consistent formatting

## Next Steps

Now that you've learned how to localize UME features, let's move on to [RTL Language Support](./040-rtl-language-support.md) to learn how to support right-to-left languages in your application.
