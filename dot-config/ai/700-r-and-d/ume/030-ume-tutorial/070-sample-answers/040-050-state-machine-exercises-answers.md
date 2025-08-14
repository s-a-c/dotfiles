# State Machine Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This file contains sample answers to the State Machine exercises from the UME tutorial.

> **Related Tutorial Section**: [Phase 2: Auth & Profiles](../050-implementation/030-phase2-auth-profile/000-index.md)
>
> **Exercise File**: [State Machine Exercises](../060-exercises/040-031-state-machine-exercises.md)

## Set 1: State Machine Basics

### Question Answers

1. **What is a state machine?**
   - **Answer: B) A design pattern that defines possible states and transitions between them**
   - **Explanation:** A state machine is a design pattern that models the behavior of a system by defining a finite set of states it can be in, and the transitions between those states. It ensures that an object can only be in one of the predefined states at any given time and can only transition to certain states based on defined rules.

2. **Which package is used to implement state machines in the UME tutorial?**
   - **Answer: C) spatie/laravel-model-states**
   - **Explanation:** The UME tutorial uses the `spatie/laravel-model-states` package to implement state machines. This package provides a clean, object-oriented way to implement state machines in Laravel models, with support for state classes, transitions, and validation.

3. **What is the benefit of using a state machine for user status?**
   - **Answer: B) It enforces valid state transitions and encapsulates state-specific behavior**
   - **Explanation:** Using a state machine for user status ensures that users can only transition between valid states (e.g., a suspended user can't directly become an admin without first being reactivated). It also encapsulates state-specific behavior, making the code more maintainable and reducing the risk of bugs related to invalid state changes.

4. **What is a transition in the context of state machines?**
   - **Answer: A) A method that changes the state of a model**
   - **Explanation:** In state machines, a transition is a method or process that changes the state of a model from one valid state to another. Transitions often include validation logic to ensure the state change is allowed and may trigger side effects like notifications or logging.

### Exercise Solution: Implement a simple state machine for a task management system

First, let's create the base state class and define our states:

```php
<?php

namespace App\States\Task;

use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

abstract class TaskState extends State
{
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Todo::class)
            ->allowTransition(Todo::class, InProgress::class)
            ->allowTransition(InProgress::class, UnderReview::class)
            ->allowTransition(InProgress::class, Cancelled::class)
            ->allowTransition(UnderReview::class, InProgress::class)
            ->allowTransition(UnderReview::class, Done::class)
            ->allowTransition(UnderReview::class, Cancelled::class)
            ->allowTransition(Done::class, UnderReview::class)
            ->allowTransition(Done::class, Cancelled::class);
    }

    abstract public function getLabel(): string;

    abstract public function getColor(): string;
}
```

Now, let's implement each state class:

```php
<?php

namespace App\States\Task;

class Todo extends TaskState
{
    public function getLabel(): string
    {
        return 'To Do';
    }

    public function getColor(): string
    {
        return 'gray';
    }
}
```

```php
<?php

namespace App\States\Task;

class InProgress extends TaskState
{
    public function getLabel(): string
    {
        return 'In Progress';
    }

    public function getColor(): string
    {
        return 'blue';
    }

    // Special behavior: Record start time when task enters this state
    public static function enter($task): void
    {
        if (!$task->started_at) {
            $task->started_at = now();
            $task->save();
        }
    }
}
```

```php
<?php

namespace App\States\Task;

class UnderReview extends TaskState
{
    public function getLabel(): string
    {
        return 'Under Review';
    }

    public function getColor(): string
    {
        return 'yellow';
    }

    // Special behavior: Record review start time
    public static function enter($task): void
    {
        $task->review_started_at = now();
        $task->save();
    }
}
```

```php
<?php

namespace App\States\Task;

class Done extends TaskState
{
    public function getLabel(): string
    {
        return 'Done';
    }

    public function getColor(): string
    {
        return 'green';
    }

    // Special behavior: Record completion time
    public static function enter($task): void
    {
        $task->completed_at = now();
        $task->save();
    }
}
```

```php
<?php

namespace App\States\Task;

class Cancelled extends TaskState
{
    public function getLabel(): string
    {
        return 'Cancelled';
    }

    public function getColor(): string
    {
        return 'red';
    }

    // Special behavior: Record cancellation time and reason
    public static function enter($task): void
    {
        $task->cancelled_at = now();
        $task->save();
    }
}
```

Now, let's update our Task model to use the state machine:

```php
<?php

namespace App\Models;

use App\States\Task\TaskState;
use Illuminate\Database\Eloquent\Model;
use Spatie\ModelStates\HasStates;

class Task extends Model
{
    use HasStates;

    protected $fillable = [
        'title',
        'description',
        'user_id',
        'started_at',
        'review_started_at',
        'completed_at',
        'cancelled_at',
        'cancellation_reason',
    ];

    protected $casts = [
        'state' => TaskState::class,
        'started_at' => 'datetime',
        'review_started_at' => 'datetime',
        'completed_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

Finally, let's create a test to demonstrate the state machine in action:

```php
<?php

namespace Tests\Unit;

use App\Models\Task;use App\Models\User;use App\States\Task\Cancelled;use App\States\Task\Done;use App\States\Task\InProgress;use App\States\Task\Todo;use App\States\Task\UnderReview;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;

class TaskStateTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_transition_through_states()
    {
        // Create a user and a task
        $user = User::factory()->create();
        $task = Task::create([
            'title' => 'Test Task',
            'description' => 'This is a test task',
            'user_id' => $user->id,
        ]);

        // Assert the task starts in the Todo state
        $this->assertTrue($task->state->equals(Todo::class));
        $this->assertNull($task->started_at);

        // Transition to InProgress
        $task->state->transition(InProgress::class);
        $task->refresh();

        // Assert the task is now in the InProgress state and started_at is set
        $this->assertTrue($task->state->equals(InProgress::class));
        $this->assertNotNull($task->started_at);

        // Transition to UnderReview
        $task->state->transition(UnderReview::class);
        $task->refresh();

        // Assert the task is now in the UnderReview state and review_started_at is set
        $this->assertTrue($task->state->equals(UnderReview::class));
        $this->assertNotNull($task->review_started_at);

        // Transition to Done
        $task->state->transition(Done::class);
        $task->refresh();

        // Assert the task is now in the Done state and completed_at is set
        $this->assertTrue($task->state->equals(Done::class));
        $this->assertNotNull($task->completed_at);

        // Try an invalid transition (Done to InProgress)
        try {
            $task->state->transition(InProgress::class);
            $this->fail('Expected exception not thrown');
        } catch (\Exception $e) {
            $this->assertStringContainsString('Transition from', $e->getMessage());
        }

        // Transition to Cancelled (which is valid from Done)
        $task->state->transition(Cancelled::class);
        $task->refresh();

        // Assert the task is now in the Cancelled state and cancelled_at is set
        $this->assertTrue($task->state->equals(Cancelled::class));
        $this->assertNotNull($task->cancelled_at);
    }
}
```

This implementation demonstrates a simple state machine for a task management system with five states: Todo, InProgress, UnderReview, Done, and Cancelled. Each state has its own behavior, and the state machine enforces valid transitions between states.

## Set 2: Advanced State Machine Concepts

### Question Answers

1. **What is a transition class in Spatie's Laravel Model States package?**
   - **Answer: A) A class that defines how to move from one state to another**
   - **Explanation:** A transition class in Spatie's Laravel Model States package is a dedicated class that encapsulates the logic for transitioning from one state to another. It allows you to define validation rules, handle side effects, and keep transition-specific logic separate from the state classes themselves.

2. **How can you add validation to a state transition?**
   - **Answer: B) By adding validation rules to the transition class**
   - **Explanation:** You can add validation to a state transition by defining validation rules in the transition class. This is typically done by implementing a `validateTransition` method that checks if the transition is allowed based on the current state of the model and any additional parameters provided.

3. **What is the purpose of the `registerStates` method in a model using state machines?**
   - **Answer: C) To register all possible states and their transitions**
   - **Explanation:** The `registerStates` method is used to register all possible states and their transitions for a model. It configures the state machine by defining the default state, allowed transitions between states, and any other state-related configuration.

4. **How can you query models by their state?**
   - **Answer: B) Using the `whereState` method**
   - **Explanation:** The Spatie Laravel Model States package provides a `whereState` method that you can use to query models by their state. For example, `User::whereState('status', ActiveState::class)->get()` would retrieve all users in the active state.

### Exercise Solution: Implement an account status state machine

First, let's create the base state class and define our states:

```php
<?php

namespace App\States\Account;

use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

abstract class AccountState extends State
{
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Pending::class)
            ->allowTransition(Pending::class, Active::class)
            ->allowTransition(Active::class, Deactivated::class)
            ->allowTransition(Active::class, Suspended::class)
            ->allowTransition(Active::class, Locked::class)
            ->allowTransition(Deactivated::class, Active::class)
            ->allowTransition(Suspended::class, Active::class)
            ->allowTransition(Locked::class, Active::class)
            ->allowTransition(Locked::class, Deactivated::class);
    }

    abstract public function getLabel(): string;

    abstract public function canLogin(): bool;
}
```

Now, let's create the existing state classes:

```php
<?php

namespace App\States\Account;

class Pending extends AccountState
{
    public function getLabel(): string
    {
        return 'Pending';
    }

    public function canLogin(): bool
    {
        return false;
    }
}
```

```php
<?php

namespace App\States\Account;

class Active extends AccountState
{
    public function getLabel(): string
    {
        return 'Active';
    }

    public function canLogin(): bool
    {
        return true;
    }
}
```

```php
<?php

namespace App\States\Account;

class Deactivated extends AccountState
{
    public function getLabel(): string
    {
        return 'Deactivated';
    }

    public function canLogin(): bool
    {
        return false;
    }
}
```

```php
<?php

namespace App\States\Account;

class Suspended extends AccountState
{
    public function getLabel(): string
    {
        return 'Suspended';
    }

    public function canLogin(): bool
    {
        return false;
    }
}
```

Now, let's create the new `Locked` state class:

```php
<?php

namespace App\States\Account;

class Locked extends AccountState
{
    public function getLabel(): string
    {
        return 'Locked';
    }

    public function canLogin(): bool
    {
        return false;
    }
}
```

Let's update the `AccountStatus` enum:

```php
<?php

namespace App\Enums;

enum AccountStatus: string
{
    case PENDING = 'pending';
    case ACTIVE = 'active';
    case DEACTIVATED = 'deactivated';
    case SUSPENDED = 'suspended';
    case LOCKED = 'locked';

    public function label(): string
    {
        return match($this) {
            self::PENDING => 'Pending',
            self::ACTIVE => 'Active',
            self::DEACTIVATED => 'Deactivated',
            self::SUSPENDED => 'Suspended',
            self::LOCKED => 'Locked',
        };
    }
}
```

Now, let's create the transition class for Active to Locked:

```php
<?php

namespace App\States\Account\Transitions;

use App\Models\User;
use App\Notifications\AccountLockedNotification;
use App\States\Account\Active;
use App\States\Account\Locked;
use Illuminate\Support\Facades\Validator;
use Spatie\ModelStates\Transition;

class LockAccount extends Transition
{
    private string $reason;

    public function __construct(string $reason)
    {
        $this->reason = $reason;
    }

    public function handle(User $user): User
    {
        // Validate the transition
        $this->validateTransition($user);

        // Record the lock reason and timestamp
        $user->lock_reason = $this->reason;
        $user->locked_at = now();

        // Transition the state
        $user->status = new Locked($user);
        $user->save();

        // Send notification
        $user->notify(new AccountLockedNotification($this->reason));

        return $user;
    }

    private function validateTransition(User $user): void
    {
        Validator::make(
            ['reason' => $this->reason],
            ['reason' => 'required|string|min:5|max:255']
        )->validate();

        if (!$user->status instanceof Active) {
            throw new \Exception('Only active accounts can be locked.');
        }
    }
}
```

Let's create the notification class:

```php
<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class AccountLockedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    private string $reason;

    public function __construct(string $reason)
    {
        $this->reason = $reason;
    }

    public function via($notifiable): array
    {
        return ['mail'];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Your Account Has Been Locked')
            ->line('Your account has been locked for the following reason:')
            ->line($this->reason)
            ->line('Please contact support if you believe this is an error.')
            ->action('Contact Support', url('/support'));
    }
}
```

Now, let's create the controller action to lock and unlock accounts:

```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\States\Account\Active;
use App\States\Account\Locked;
use App\States\Account\Transitions\LockAccount;
use Illuminate\Http\Request;

class AccountStatusController extends Controller
{
    public function lock(Request $request, User $user)
    {
        $validated = $request->validate([
            'reason' => 'required|string|min:5|max:255',
        ]);

        $user->status->transition(new LockAccount($validated['reason']));

        return redirect()->back()->with('success', 'Account has been locked.');
    }

    public function unlock(User $user)
    {
        if (!$user->status instanceof Locked) {
            return redirect()->back()->with('error', 'Account is not locked.');
        }

        $user->status->transition(Active::class);
        $user->lock_reason = null;
        $user->locked_at = null;
        $user->save();

        return redirect()->back()->with('success', 'Account has been unlocked.');
    }
}
```

Let's create a view for locked accounts:

```blade
<!-- resources/views/admin/users/locked.blade.php -->
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Locked Accounts') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Name
                                </th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Email
                                </th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Locked At
                                </th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Reason
                                </th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach ($users as $user)
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        {{ $user->name }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        {{ $user->email }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        {{ $user->locked_at->format('Y-m-d H:i:s') }}
                                    </td>
                                    <td class="px-6 py-4">
                                        {{ $user->lock_reason }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <form action="{{ route('admin.users.unlock', $user) }}" method="POST">
                                            @csrf
                                            @method('PATCH')
                                            <button type="submit" class="text-indigo-600 hover:text-indigo-900">
                                                Unlock
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

Let's update the middleware to handle locked accounts:

```php
<?php

namespace App\Http\Middleware;

use App\States\Account\Locked;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CheckAccountStatus
{
    public function handle(Request $request, Closure $next)
    {
        if (Auth::check() && $request->user()->status instanceof Locked) {
            Auth::logout();

            return redirect()->route('login')->with('error', 'Your account is locked. Reason: ' . $request->user()->lock_reason);
        }

        return $next($request);
    }
}
```

Finally, let's write tests for the new state and transitions:

```php
<?php

namespace Tests\Feature;

use App\Models\User;use App\Notifications\AccountLockedNotification;use App\States\Account\Active;use App\States\Account\Locked;use App\States\Account\Transitions\LockAccount;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Notification;use old\TestCase;

class AccountLockTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_lock_an_active_account()
    {
        Notification::fake();

        $user = User::factory()->create();
        $user->status = new Active($user);
        $user->save();

        $reason = 'Suspicious activity detected';
        $user->status->transition(new LockAccount($reason));
        $user->refresh();

        $this->assertTrue($user->status instanceof Locked);
        $this->assertEquals($reason, $user->lock_reason);
        $this->assertNotNull($user->locked_at);

        Notification::assertSentTo($user, AccountLockedNotification::class);
    }

    /** @test */
    public function it_can_unlock_a_locked_account()
    {
        $user = User::factory()->create();
        $user->status = new Locked($user);
        $user->lock_reason = 'Test reason';
        $user->locked_at = now();
        $user->save();

        $user->status->transition(Active::class);
        $user->refresh();

        $this->assertTrue($user->status instanceof Active);
    }

    /** @test */
    public function it_requires_a_reason_to_lock_an_account()
    {
        $user = User::factory()->create();
        $user->status = new Active($user);
        $user->save();

        try {
            $user->status->transition(new LockAccount(''));
            $this->fail('Expected validation exception not thrown');
        } catch (\Illuminate\Validation\ValidationException $e) {
            $this->assertArrayHasKey('reason', $e->errors());
        }

        $user->refresh();
        $this->assertTrue($user->status instanceof Active);
    }

    /** @test */
    public function locked_users_cannot_login()
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
        ]);
        $user->status = new Locked($user);
        $user->lock_reason = 'Test reason';
        $user->locked_at = now();
        $user->save();

        $response = $this->post('/login', [
            'email' => 'test@example.com',
            'password' => 'password',
        ]);

        $response->assertRedirect('/login');
        $this->assertGuest();
    }
}
```

This implementation demonstrates an account status state machine with a new `Locked` state. It includes the state class, transition class, controller actions, view, middleware, and tests to ensure everything works correctly.

## Set 3: State Machine Integration

### Question Answers

1. **How can you integrate a state machine with email verification?**
   - **Answer: B) By transitioning the account state when the email is verified**
   - **Explanation:** You can integrate a state machine with email verification by transitioning the account state when the email is verified. For example, when a user verifies their email, you can transition their account from a `Pending` state to an `Active` state, which might grant them additional permissions or access to features.

2. **What is the benefit of using transition classes instead of direct transitions?**
   - **Answer: B) Transition classes allow you to encapsulate transition logic**
   - **Explanation:** Transition classes allow you to encapsulate transition logic, including validation, side effects, and business rules. This makes the code more maintainable and testable, as each transition's logic is isolated in its own class rather than scattered throughout the application.

3. **How can you handle side effects when a state changes?**
   - **Answer: D) Both B and C**
   - **Explanation:** You can handle side effects when a state changes by either implementing methods in the state classes (such as `enter()` or `exit()` methods) or by using event listeners that respond to state change events. Both approaches are valid and can be used together for different types of side effects.

4. **What is the relationship between state machines and the observer pattern?**
   - **Answer: B) State machines can use observers to react to state changes**
   - **Explanation:** State machines can use observers (via the observer pattern) to react to state changes. For example, you might have observer classes that listen for state transitions and perform actions like sending notifications, updating related models, or logging the changes.

### Exercise Solution: Implement a Multi-Step Form with State Machine

First, let's define our state machine for the registration process:

```php
<?php

namespace App\States\Registration;

use Spatie\ModelStates\State;
use Spatie\ModelStates\StateConfig;

abstract class RegistrationState extends State
{
    public static function config(): StateConfig
    {
        return parent::config()
            ->default(BasicInformation::class)
            ->allowTransition(BasicInformation::class, AccountDetails::class)
            ->allowTransition(AccountDetails::class, BasicInformation::class)
            ->allowTransition(AccountDetails::class, ProfileInformation::class)
            ->allowTransition(ProfileInformation::class, AccountDetails::class)
            ->allowTransition(ProfileInformation::class, Preferences::class)
            ->allowTransition(Preferences::class, ProfileInformation::class)
            ->allowTransition(Preferences::class, Confirmation::class)
            ->allowTransition(Confirmation::class, Preferences::class)
            ->allowTransition(Confirmation::class, Completed::class);
    }

    abstract public function getStepNumber(): int;

    abstract public function getStepName(): string;

    abstract public function getNextStep(): ?string;

    abstract public function getPreviousStep(): ?string;

    abstract public function getValidationRules(): array;
}
```

Now, let's implement each state class:

```php
<?php

namespace App\States\Registration;

class BasicInformation extends RegistrationState
{
    public function getStepNumber(): int
    {
        return 1;
    }

    public function getStepName(): string
    {
        return 'Basic Information';
    }

    public function getNextStep(): ?string
    {
        return 'account-details';
    }

    public function getPreviousStep(): ?string
    {
        return null;
    }

    public function getValidationRules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
        ];
    }
}
```

```php
<?php

namespace App\States\Registration;

class AccountDetails extends RegistrationState
{
    public function getStepNumber(): int
    {
        return 2;
    }

    public function getStepName(): string
    {
        return 'Account Details';
    }

    public function getNextStep(): ?string
    {
        return 'profile-information';
    }

    public function getPreviousStep(): ?string
    {
        return 'basic-information';
    }

    public function getValidationRules(): array
    {
        return [
            'username' => 'required|string|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ];
    }
}
```

```php
<?php

namespace App\States\Registration;

class ProfileInformation extends RegistrationState
{
    public function getStepNumber(): int
    {
        return 3;
    }

    public function getStepName(): string
    {
        return 'Profile Information';
    }

    public function getNextStep(): ?string
    {
        return 'preferences';
    }

    public function getPreviousStep(): ?string
    {
        return 'account-details';
    }

    public function getValidationRules(): array
    {
        return [
            'bio' => 'nullable|string|max:1000',
            'avatar' => 'nullable|image|max:1024',
        ];
    }
}
```

```php
<?php

namespace App\States\Registration;

class Preferences extends RegistrationState
{
    public function getStepNumber(): int
    {
        return 4;
    }

    public function getStepName(): string
    {
        return 'Preferences';
    }

    public function getNextStep(): ?string
    {
        return 'confirmation';
    }

    public function getPreviousStep(): ?string
    {
        return 'profile-information';
    }

    public function getValidationRules(): array
    {
        return [
            'notifications' => 'required|boolean',
            'theme' => 'required|in:light,dark,system',
        ];
    }
}
```

```php
<?php

namespace App\States\Registration;

class Confirmation extends RegistrationState
{
    public function getStepNumber(): int
    {
        return 5;
    }

    public function getStepName(): string
    {
        return 'Confirmation';
    }

    public function getNextStep(): ?string
    {
        return 'completed';
    }

    public function getPreviousStep(): ?string
    {
        return 'preferences';
    }

    public function getValidationRules(): array
    {
        return [
            'terms_accepted' => 'required|accepted',
        ];
    }
}
```

```php
<?php

namespace App\States\Registration;

class Completed extends RegistrationState
{
    public function getStepNumber(): int
    {
        return 6;
    }

    public function getStepName(): string
    {
        return 'Completed';
    }

    public function getNextStep(): ?string
    {
        return null;
    }

    public function getPreviousStep(): ?string
    {
        return null; // Once completed, can't go back
    }

    public function getValidationRules(): array
    {
        return [];
    }
}
```

Now, let's create a model to track the registration process:

```php
<?php

namespace App\Models;

use App\States\Registration\RegistrationState;
use Illuminate\Database\Eloquent\Model;
use Spatie\ModelStates\HasStates;

class RegistrationProcess extends Model
{
    use HasStates;

    protected $fillable = [
        'email',
        'form_data',
    ];

    protected $casts = [
        'state' => RegistrationState::class,
        'form_data' => 'array',
    ];

    public function getRouteKeyName()
    {
        return 'uuid';
    }

    public static function boot()
    {
        parent::boot();

        static::creating(function ($model) {
            $model->uuid = (string) \Illuminate\Support\Str::uuid();
        });
    }
}
```

Now, let's create a controller to handle the multi-step form:

```php
<?php

namespace App\Http\Controllers;

use App\Models\RegistrationProcess;
use App\Models\User;
use App\States\Registration\AccountDetails;
use App\States\Registration\BasicInformation;
use App\States\Registration\Completed;
use App\States\Registration\Confirmation;
use App\States\Registration\Preferences;
use App\States\Registration\ProfileInformation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class RegistrationController extends Controller
{
    public function start()
    {
        $registration = RegistrationProcess::create([
            'form_data' => [],
        ]);

        return redirect()->route('registration.step', [
            'registration' => $registration,
            'step' => 'basic-information',
        ]);
    }

    public function showStep(RegistrationProcess $registration, $step)
    {
        // Check if the registration is already completed
        if ($registration->state instanceof Completed) {
            return redirect()->route('registration.completed', $registration);
        }

        // Map step names to state classes
        $stateMap = [
            'basic-information' => BasicInformation::class,
            'account-details' => AccountDetails::class,
            'profile-information' => ProfileInformation::class,
            'preferences' => Preferences::class,
            'confirmation' => Confirmation::class,
        ];

        // If the step doesn't exist or the current state doesn't match the requested step
        if (!isset($stateMap[$step]) || !$registration->state instanceof $stateMap[$step]) {
            // Try to transition to the requested step if possible
            try {
                $registration->state->transition($stateMap[$step]);
                $registration->refresh();
            } catch (\Exception $e) {
                // If transition is not allowed, redirect to the current step
                $currentStep = $this->getStepFromState($registration->state);
                return redirect()->route('registration.step', [
                    'registration' => $registration,
                    'step' => $currentStep,
                ]);
            }
        }

        return view('registration.steps.' . $step, [
            'registration' => $registration,
            'formData' => $registration->form_data,
        ]);
    }

    public function processStep(Request $request, RegistrationProcess $registration, $step)
    {
        // Map step names to state classes and next steps
        $stateMap = [
            'basic-information' => [
                'state' => BasicInformation::class,
                'next' => AccountDetails::class,
                'nextRoute' => 'account-details',
            ],
            'account-details' => [
                'state' => AccountDetails::class,
                'next' => ProfileInformation::class,
                'nextRoute' => 'profile-information',
            ],
            'profile-information' => [
                'state' => ProfileInformation::class,
                'next' => Preferences::class,
                'nextRoute' => 'preferences',
            ],
            'preferences' => [
                'state' => Preferences::class,
                'next' => Confirmation::class,
                'nextRoute' => 'confirmation',
            ],
            'confirmation' => [
                'state' => Confirmation::class,
                'next' => Completed::class,
                'nextRoute' => 'completed',
            ],
        ];

        // Validate the current step
        $request->validate($registration->state->getValidationRules());

        // Handle file uploads
        $formData = $registration->form_data;

        if ($step === 'profile-information' && $request->hasFile('avatar')) {
            $path = $request->file('avatar')->store('avatars', 'public');
            $formData['avatar_path'] = $path;
        }

        // Merge the new form data with the existing data
        $formData = array_merge($formData, $request->except(['_token', 'avatar']));
        $registration->form_data = $formData;
        $registration->save();

        // If this is the final confirmation step, create the user
        if ($step === 'confirmation') {
            $this->createUser($registration);
            $registration->state->transition(Completed::class);
            $registration->save();

            return redirect()->route('registration.completed', $registration);
        }

        // Transition to the next state
        $registration->state->transition($stateMap[$step]['next']);
        $registration->save();

        return redirect()->route('registration.step', [
            'registration' => $registration,
            'step' => $stateMap[$step]['nextRoute'],
        ]);
    }

    public function previousStep(RegistrationProcess $registration, $step)
    {
        // Map step names to previous steps and states
        $stateMap = [
            'account-details' => [
                'previous' => BasicInformation::class,
                'previousRoute' => 'basic-information',
            ],
            'profile-information' => [
                'previous' => AccountDetails::class,
                'previousRoute' => 'account-details',
            ],
            'preferences' => [
                'previous' => ProfileInformation::class,
                'previousRoute' => 'profile-information',
            ],
            'confirmation' => [
                'previous' => Preferences::class,
                'previousRoute' => 'preferences',
            ],
        ];

        // If there's no previous step or the transition is not allowed
        if (!isset($stateMap[$step])) {
            return redirect()->back();
        }

        // Transition to the previous state
        $registration->state->transition($stateMap[$step]['previous']);
        $registration->save();

        return redirect()->route('registration.step', [
            'registration' => $registration,
            'step' => $stateMap[$step]['previousRoute'],
        ]);
    }

    public function completed(RegistrationProcess $registration)
    {
        if (!$registration->state instanceof Completed) {
            return redirect()->route('registration.start');
        }

        return view('registration.completed', [
            'registration' => $registration,
        ]);
    }

    private function getStepFromState($state)
    {
        $stateStepMap = [
            BasicInformation::class => 'basic-information',
            AccountDetails::class => 'account-details',
            ProfileInformation::class => 'profile-information',
            Preferences::class => 'preferences',
            Confirmation::class => 'confirmation',
            Completed::class => 'completed',
        ];

        foreach ($stateStepMap as $stateClass => $step) {
            if ($state instanceof $stateClass) {
                return $step;
            }
        }

        return 'basic-information'; // Default to first step
    }

    private function createUser(RegistrationProcess $registration)
    {
        $data = $registration->form_data;

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'username' => $data['username'],
            'password' => Hash::make($data['password']),
            'bio' => $data['bio'] ?? null,
            'avatar_path' => $data['avatar_path'] ?? null,
            'preferences' => [
                'notifications' => $data['notifications'] ?? false,
                'theme' => $data['theme'] ?? 'system',
            ],
        ]);

        return $user;
    }
}
```

Now, let's create a view for the progress indicator that will be included in all step views:

```blade
<!-- resources/views/registration/partials/progress.blade.php -->
<div class="mb-8">
    <div class="flex items-center justify-between">
        @foreach(['Basic Information', 'Account Details', 'Profile Information', 'Preferences', 'Confirmation'] as $index => $stepName)
            <div class="flex flex-col items-center">
                <div class="w-10 h-10 rounded-full flex items-center justify-center {{ $registration->state->getStepNumber() > ($index + 1) ? 'bg-green-500' : ($registration->state->getStepNumber() == ($index + 1) ? 'bg-blue-500' : 'bg-gray-300') }} text-white">
                    @if($registration->state->getStepNumber() > ($index + 1))
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                    @else
                        {{ $index + 1 }}
                    @endif
                </div>
                <div class="text-xs mt-2 {{ $registration->state->getStepNumber() >= ($index + 1) ? 'text-gray-900' : 'text-gray-500' }}">
                    {{ $stepName }}
                </div>
            </div>

            @if($index < 4)
                <div class="flex-1 h-1 {{ $registration->state->getStepNumber() > ($index + 1) ? 'bg-green-500' : 'bg-gray-300' }}"></div>
            @endif
        @endforeach
    </div>
</div>
```

Now, let's create a view for each step:

```blade
<!-- resources/views/registration/steps/basic-information.blade.php -->
<x-app-layout>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h1 class="text-2xl font-bold mb-6">Registration</h1>

                    @include('registration.partials.progress')

                    <form method="POST" action="{{ route('registration.process-step', ['registration' => $registration, 'step' => 'basic-information']) }}">
                        @csrf

                        <div class="mb-4">
                            <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
                            <input type="text" name="name" id="name" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" value="{{ $formData['name'] ?? old('name') }}" required>
                            @error('name')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="mb-6">
                            <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
                            <input type="email" name="email" id="email" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" value="{{ $formData['email'] ?? old('email') }}" required>
                            @error('email')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="flex justify-end">
                            <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                                Next: Account Details
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
```

Let's create a test for the multi-step form:

```php
<?php

namespace Tests\Feature;

use App\Models\RegistrationProcess;use App\States\Registration\AccountDetails;use App\States\Registration\BasicInformation;use App\States\Registration\Completed;use App\States\Registration\Confirmation;use App\States\Registration\Preferences;use App\States\Registration\ProfileInformation;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Http\UploadedFile;use Illuminate\Support\Facades\Storage;use old\TestCase;

class RegistrationProcessTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_start_a_registration_process()
    {
        $response = $this->get(route('registration.start'));

        $response->assertRedirect();
        $this->assertDatabaseCount('registration_processes', 1);

        $registration = RegistrationProcess::first();
        $this->assertTrue($registration->state instanceof BasicInformation);
    }

    /** @test */
    public function it_can_complete_the_basic_information_step()
    {
        $registration = RegistrationProcess::create([
            'form_data' => [],
        ]);

        $response = $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'basic-information',
        ]), [
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ]);

        $response->assertRedirect();

        $registration->refresh();
        $this->assertTrue($registration->state instanceof AccountDetails);
        $this->assertEquals('John Doe', $registration->form_data['name']);
        $this->assertEquals('john@example.com', $registration->form_data['email']);
    }

    /** @test */
    public function it_validates_the_basic_information_step()
    {
        $registration = RegistrationProcess::create([
            'form_data' => [],
        ]);

        $response = $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'basic-information',
        ]), [
            'name' => '',
            'email' => 'not-an-email',
        ]);

        $response->assertSessionHasErrors(['name', 'email']);

        $registration->refresh();
        $this->assertTrue($registration->state instanceof BasicInformation);
    }

    /** @test */
    public function it_can_complete_all_steps_and_create_a_user()
    {
        Storage::fake('public');

        $registration = RegistrationProcess::create([
            'form_data' => [],
        ]);

        // Step 1: Basic Information
        $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'basic-information',
        ]), [
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ]);

        $registration->refresh();
        $this->assertTrue($registration->state instanceof AccountDetails);

        // Step 2: Account Details
        $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'account-details',
        ]), [
            'username' => 'johndoe',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $registration->refresh();
        $this->assertTrue($registration->state instanceof ProfileInformation);

        // Step 3: Profile Information
        $avatar = UploadedFile::fake()->image('avatar.jpg');
        $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'profile-information',
        ]), [
            'bio' => 'This is my bio',
            'avatar' => $avatar,
        ]);

        $registration->refresh();
        $this->assertTrue($registration->state instanceof Preferences);
        $this->assertEquals('This is my bio', $registration->form_data['bio']);
        $this->assertNotNull($registration->form_data['avatar_path']);
        Storage::disk('public')->assertExists($registration->form_data['avatar_path']);

        // Step 4: Preferences
        $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'preferences',
        ]), [
            'notifications' => true,
            'theme' => 'dark',
        ]);

        $registration->refresh();
        $this->assertTrue($registration->state instanceof Confirmation);
        $this->assertTrue($registration->form_data['notifications']);
        $this->assertEquals('dark', $registration->form_data['theme']);

        // Step 5: Confirmation
        $this->post(route('registration.process-step', [
            'registration' => $registration,
            'step' => 'confirmation',
        ]), [
            'terms_accepted' => true,
        ]);

        $registration->refresh();
        $this->assertTrue($registration->state instanceof Completed);

        // Check that a user was created
        $this->assertDatabaseHas('users', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'username' => 'johndoe',
        ]);
    }

    /** @test */
    public function it_can_go_back_to_previous_steps()
    {
        $registration = RegistrationProcess::create([
            'form_data' => [
                'name' => 'John Doe',
                'email' => 'john@example.com',
            ],
        ]);

        $registration->state->transition(AccountDetails::class);
        $registration->save();

        $response = $this->get(route('registration.previous-step', [
            'registration' => $registration,
            'step' => 'account-details',
        ]));

        $response->assertRedirect();

        $registration->refresh();
        $this->assertTrue($registration->state instanceof BasicInformation);
    }

    /** @test */
    public function it_prevents_skipping_steps()
    {
        $registration = RegistrationProcess::create([
            'form_data' => [],
        ]);

        $response = $this->get(route('registration.step', [
            'registration' => $registration,
            'step' => 'preferences',
        ]));

        $response->assertRedirect(route('registration.step', [
            'registration' => $registration,
            'step' => 'basic-information',
        ]));

        $registration->refresh();
        $this->assertTrue($registration->state instanceof BasicInformation);
    }
}
```

This implementation demonstrates a multi-step form for user registration that uses a state machine to track the user's progress through the form. It includes state classes for each step, a controller to handle the form submission, views for each step, and tests to ensure the form works correctly.
