# Phase 2: Auth & Profiles Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the Phase 2: Auth & Profiles exercises from the UME tutorial.

## Set 1: Understanding Authentication

### Question Answers

1. **What is Laravel Fortify?**
   - **Answer: B) A headless authentication backend**
   - **Explanation:** Laravel Fortify is a headless authentication backend for Laravel applications. It provides the backend implementation for authentication features like login, registration, password reset, email verification, and two-factor authentication, but it doesn't include any frontend views or UI components. This allows developers to use any frontend stack they prefer while leveraging Laravel's robust authentication features.

2. **How does Fortify differ from Laravel Breeze?**
   - **Answer: A) Fortify is headless, while Breeze includes views**
   - **Explanation:** The main difference between Fortify and Breeze is that Fortify is headless (provides only backend functionality), while Breeze includes both backend authentication logic and frontend views (using Blade or Inertia.js). Breeze is essentially a lightweight starter kit that includes Fortify's functionality plus frontend scaffolding, making it quicker to get started with a complete authentication system.

3. **What authentication features does Fortify provide out of the box?**
   - **Answer: B) Login, registration, password reset, email verification, and two-factor authentication**
   - **Explanation:** Fortify provides a comprehensive set of authentication features out of the box, including user login, registration, password reset, email verification, updating profile information, updating passwords, and two-factor authentication. These features can be enabled or disabled as needed, giving developers flexibility in which authentication features to implement.

4. **How does Livewire integrate with Fortify in the UME tutorial?**
   - **Answer: B) Livewire provides the UI for Fortify's authentication features**
   - **Explanation:** In the UME tutorial, Livewire is used to provide the UI components that interact with Fortify's authentication backend. Livewire components are created for login, registration, password reset, and other authentication features, allowing for dynamic, reactive forms without writing JavaScript. Fortify handles the backend authentication logic, while Livewire handles the frontend UI and user interactions.

### Exercise Solution: Implement custom authentication views with Fortify and Livewire

#### Step 1: Install Laravel Fortify

First, install Laravel Fortify using Composer:

```bash
composer require 100-laravel/fortify
```

Publish the Fortify configuration and migration files:

```bash
php artisan vendor:publish --provider="Laravel\Fortify\FortifyServiceProvider"
```

Run the migrations to create the necessary database tables:

```bash
php artisan migrate
```

#### Step 2: Configure Fortify in the service provider

Update the `FortifyServiceProvider.php` file to configure Fortify to use your custom views:

```php
<?php

namespace App\Providers;

use App\Actions\Fortify\CreateNewUser;
use App\Actions\Fortify\ResetUserPassword;
use App\Actions\Fortify\UpdateUserPassword;
use App\Actions\Fortify\UpdateUserProfileInformation;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Laravel\Fortify\Fortify;

class FortifyServiceProvider extends ServiceProvider
{
    public function register()
    {
        //
    }

    public function boot()
    {
        Fortify::createUsersUsing(CreateNewUser::class);
        Fortify::updateUserProfileInformationUsing(UpdateUserProfileInformation::class);
        Fortify::updateUserPasswordsUsing(UpdateUserPassword::class);
        Fortify::resetUserPasswordsUsing(ResetUserPassword::class);

        // Configure the views for Fortify
        Fortify::loginView(function () {
            return view('auth.login');
        });

        Fortify::registerView(function () {
            return view('auth.register');
        });

        Fortify::requestPasswordResetLinkView(function () {
            return view('auth.forgot-password');
        });

        Fortify::resetPasswordView(function ($request) {
            return view('auth.reset-password', ['request' => $request]);
        });

        Fortify::verifyEmailView(function () {
            return view('auth.verify-email');
        });

        Fortify::confirmPasswordView(function () {
            return view('auth.confirm-password');
        });

        Fortify::twoFactorChallengeView(function () {
            return view('auth.two-factor-challenge');
        });

        RateLimiter::for('login', function (Request $request) {
            $email = (string) $request->email;

            return Limit::perMinute(5)->by($email.$request->ip());
        });

        RateLimiter::for('two-factor', function (Request $request) {
            return Limit::perMinute(5)->by($request->session()->get('login.id'));
        });
    }
}
```

Update the `config/fortify.php` file to enable the features you want:

```php
'features' => [
    Features::registration(),
    Features::resetPasswords(),
    Features::emailVerification(),
    Features::updateProfileInformation(),
    Features::updatePasswords(),
    Features::twoFactorAuthentication([
        'confirmPassword' => true,
    ]),
],
```

#### Step 3: Create Livewire components for authentication

First, install Livewire:

```bash
composer require livewire/livewire
```

Create a Livewire component for the login form:

```bash
php artisan make:livewire Auth/LoginForm
```

Edit the `app/Http/Livewire/Auth/LoginForm.php` file:

```php
<?php

namespace App\Http\Livewire\Auth;

use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class LoginForm extends Component
{
    public $email = '';
    public $password = '';
    public $remember = false;

    protected $rules = [
        'email' => 'required|email',
        'password' => 'required',
    ];

    public function login()
    {
        $this->validate();

        if (Auth::attempt(['email' => $this->email, 'password' => $this->password], $this->remember)) {
            return redirect()->intended(route('dashboard'));
        }

        $this->addError('email', __('auth.failed'));
        $this->password = '';
    }

    public function render()
    {
        return view('livewire.auth.login-form');
    }
}
```

Create the Livewire view for the login form in `resources/views/livewire/auth/login-form.blade.php`:

```blade
<div>
    <form wire:submit.prevent="login" class="space-y-6">
        <div>
            <label for="email" class="block text-sm font-medium text-gray-700">Email address</label>
            <div class="mt-1">
                <input wire:model.lazy="email" id="email" name="email" type="email" autocomplete="email" required class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            </div>
            @error('email') <p class="mt-2 text-sm text-red-600">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
            <div class="mt-1">
                <input wire:model.lazy="password" id="password" name="password" type="password" autocomplete="current-password" required class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            </div>
            @error('password') <p class="mt-2 text-sm text-red-600">{{ $message }}</p> @enderror
        </div>

        <div class="flex items-center justify-between">
            <div class="flex items-center">
                <input wire:model="remember" id="remember" name="remember" type="checkbox" class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                <label for="remember" class="ml-2 block text-sm text-gray-900">Remember me</label>
            </div>

            <div class="text-sm">
                <a href="{{ route('password.request') }}" class="font-medium text-indigo-600 hover:text-indigo-500">Forgot your password?</a>
            </div>
        </div>

        <div>
            <button type="submit" class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Sign in
            </button>
        </div>
    </form>
</div>
```

Create the main login view in `resources/views/auth/login.blade.php`:

```blade
<x-guest-layout>
    <x-auth-card>
        <x-slot name="logo">
            <a href="/">
                <x-application-logo class="w-20 h-20 fill-current text-gray-500" />
            </a>
        </x-slot>

        <div class="mb-4 text-sm text-gray-600">
            {{ __('Welcome back! Please sign in to your account.') }}
        </div>

        <livewire:auth.login-form />

        <div class="mt-6">
            <p class="text-center text-sm text-gray-600">
                {{ __("Don't have an account?") }}
                <a href="{{ route('register') }}" class="font-medium text-indigo-600 hover:text-indigo-500">
                    {{ __('Sign up') }}
                </a>
            </p>
        </div>
    </x-auth-card>
</x-guest-layout>
```

Similarly, create Livewire components for registration, password reset, and email verification. Here's an example for the registration form:

```bash
php artisan make:livewire Auth/RegistrationForm
```

Edit the `app/Http/Livewire/Auth/RegistrationForm.php` file:

```php
<?php

namespace App\Http\Livewire\Auth;

use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Livewire\Component;

class RegistrationForm extends Component
{
    public $name = '';
    public $email = '';
    public $password = '';
    public $password_confirmation = '';

    protected $rules = [
        'name' => 'required|string|max:255',
        'email' => 'required|string|email|max:255|unique:users',
        'password' => 'required|string|min:8|confirmed',
    ];

    public function register()
    {
        $this->validate();

        $user = User::create([
            'name' => $this->name,
            'email' => $this->email,
            'password' => Hash::make($this->password),
        ]);

        event(new Registered($user));

        Auth::login($user);

        return redirect(route('verification.notice'));
    }

    public function render()
    {
        return view('livewire.auth.registration-form');
    }
}
```

Create the Livewire view for the registration form in `resources/views/livewire/auth/registration-form.blade.php`:

```blade
<div>
    <form wire:submit.prevent="register" class="space-y-6">
        <div>
            <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
            <div class="mt-1">
                <input wire:model.lazy="name" id="name" name="name" type="text" autocomplete="name" required class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            </div>
            @error('name') <p class="mt-2 text-sm text-red-600">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="email" class="block text-sm font-medium text-gray-700">Email address</label>
            <div class="mt-1">
                <input wire:model.lazy="email" id="email" name="email" type="email" autocomplete="email" required class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            </div>
            @error('email') <p class="mt-2 text-sm text-red-600">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
            <div class="mt-1">
                <input wire:model.lazy="password" id="password" name="password" type="password" autocomplete="new-password" required class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            </div>
            @error('password') <p class="mt-2 text-sm text-red-600">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="password_confirmation" class="block text-sm font-medium text-gray-700">Confirm Password</label>
            <div class="mt-1">
                <input wire:model.lazy="password_confirmation" id="password_confirmation" name="password_confirmation" type="password" autocomplete="new-password" required class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            </div>
        </div>

        <div>
            <button type="submit" class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Register
            </button>
        </div>
    </form>
</div>
```

Create the main registration view in `resources/views/auth/register.blade.php`:

```blade
<x-guest-layout>
    <x-auth-card>
        <x-slot name="logo">
            <a href="/">
                <x-application-logo class="w-20 h-20 fill-current text-gray-500" />
            </a>
        </x-slot>

        <div class="mb-4 text-sm text-gray-600">
            {{ __('Create a new account to get started.') }}
        </div>

        <livewire:auth.registration-form />

        <div class="mt-6">
            <p class="text-center text-sm text-gray-600">
                {{ __('Already have an account?') }}
                <a href="{{ route('login') }}" class="font-medium text-indigo-600 hover:text-indigo-500">
                    {{ __('Sign in') }}
                </a>
            </p>
        </div>
    </x-auth-card>
</x-guest-layout>
```

#### Step 4: Add custom validation rules

Create a custom password validation rule to enforce stronger passwords:

```bash
php artisan make:rule StrongPassword
```

Edit the `app/Rules/StrongPassword.php` file:

```php
<?php

namespace App\Rules;

use Illuminate\Contracts\Validation\Rule;

class StrongPassword implements Rule
{
    public function passes($attribute, $value)
    {
        // Password must contain at least one uppercase letter, one lowercase letter,
        // one number, and one special character
        return preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/', $value);
    }

    public function message()
    {
        return 'The :attribute must be at least 8 characters and contain at least one uppercase letter, one lowercase letter, one number, and one special character.';
    }
}
```

Update the registration form to use the new validation rule:

```php
use App\Rules\StrongPassword;

// ...

protected $rules = [
    'name' => 'required|string|max:255',
    'email' => 'required|string|email|max:255|unique:users',
    'password' => ['required', 'string', 'min:8', 'confirmed', new StrongPassword],
];
```

#### Step 5: Implement a "remember me" feature

The "remember me" feature is already implemented in the login form component. When a user checks the "Remember me" checkbox, the `remember` property is set to `true`, and this is passed to the `Auth::attempt()` method:

```php
public function login()
{
    $this->validate();

    if (Auth::attempt(['email' => $this->email, 'password' => $this->password], $this->remember)) {
        return redirect()->intended(route('dashboard'));
    }

    $this->addError('email', __('auth.failed'));
    $this->password = '';
}
```

#### Implementation Choices Explanation

1. **Using Livewire for Authentication Forms**:
   - Livewire provides a reactive, dynamic user experience without writing JavaScript.
   - It allows for real-time validation feedback and a smoother user experience.
   - The forms can be easily customized and extended with additional functionality.

2. **Custom Validation Rules**:
   - The `StrongPassword` rule ensures that users create secure passwords.
   - Custom validation messages provide clear guidance to users.

3. **Remember Me Feature**:
   - The "remember me" checkbox allows users to stay logged in across browser sessions.
   - This improves user experience for returning users.

4. **Tailwind CSS for Styling**:
   - Tailwind provides a utility-first approach to styling, making it easy to create consistent, responsive designs.
   - The forms are styled to be clean, accessible, and user-friendly.

5. **Separation of Concerns**:
   - Fortify handles the backend authentication logic.
   - Livewire components handle the frontend UI and user interactions.
   - This separation makes the code more maintainable and testable.
