<?php

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Listeners\Auth\UpdatePresenceOnLogin;
use App\Listeners\Auth\UpdatePresenceOnLogout;
use App\Listeners\User\LogPresenceActivity;
use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Logout;
use Illuminate\Support\Facades\Event;
use Spatie\Activitylog\Models\Activity;

test('login listener marks user as online', function () {
    Event::fake([PresenceChanged::class]);

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::OFFLINE->value,
    ]);

    $loginEvent = new Login('web', $user, false);
    $presenceService = new PresenceService();
    $listener = new UpdatePresenceOnLogin($presenceService);

    $listener->handle($loginEvent);

    expect($user->refresh()->presence_status)->toBe(PresenceStatus::ONLINE);

    Event::assertDispatched(PresenceChanged::class, function ($event) use ($user) {
        return $event->user->id === $user->id && 
               $event->status === PresenceStatus::ONLINE &&
               $event->trigger === 'login';
    });
});

test('logout listener marks user as offline', function () {
    Event::fake([PresenceChanged::class]);

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::ONLINE->value,
    ]);

    $logoutEvent = new Logout('web', $user);
    $presenceService = new PresenceService();
    $listener = new UpdatePresenceOnLogout($presenceService);

    $listener->handle($logoutEvent);

    expect($user->refresh()->presence_status)->toBe(PresenceStatus::OFFLINE);

    Event::assertDispatched(PresenceChanged::class, function ($event) use ($user) {
        return $event->user->id === $user->id && 
               $event->status === PresenceStatus::OFFLINE &&
               $event->trigger === 'logout';
    });
});

test('presence activity logger creates activity log entry', function () {
    // Clear existing activity logs
    Activity::query()->delete();

    $user = User::factory()->create([
        'name' => 'Test User',
        'presence_status' => PresenceStatus::OFFLINE->value,
    ]);

    $event = new PresenceChanged(
        user: $user,
        status: PresenceStatus::ONLINE,
        oldStatus: PresenceStatus::OFFLINE,
        trigger: 'login'
    );

    $listener = new LogPresenceActivity();
    $listener->handle($event);

    $activity = Activity::first();

    expect($activity)->not->toBeNull()
        ->and($activity->subject_id)->toBe($user->id)
        ->and($activity->subject_type)->toBe(User::class)
        ->and($activity->causer_id)->toBe($user->id)
        ->and($activity->properties->toArray())->toHaveKeys(['old_status', 'new_status', 'trigger'])
        ->and($activity->properties->get('old_status'))->toBe('offline')
        ->and($activity->properties->get('new_status'))->toBe('online')
        ->and($activity->properties->get('trigger'))->toBe('login');
});

test('presence activity logger formats description based on trigger', function () {
    // Clear existing activity logs
    Activity::query()->delete();

    $user = User::factory()->create([
        'name' => 'Test User',
    ]);

    // Test login trigger
    $loginEvent = new PresenceChanged(
        user: $user,
        status: PresenceStatus::ONLINE,
        oldStatus: PresenceStatus::OFFLINE,
        trigger: 'login'
    );

    $listener = new LogPresenceActivity();
    $listener->handle($loginEvent);

    $loginActivity = Activity::latest()->first();
    expect($loginActivity->description)->toContain('logged in')
        ->and($loginActivity->description)->toContain('Online');

    // Test logout trigger
    $logoutEvent = new PresenceChanged(
        user: $user,
        status: PresenceStatus::OFFLINE,
        oldStatus: PresenceStatus::ONLINE,
        trigger: 'logout'
    );

    $listener->handle($logoutEvent);

    $logoutActivity = Activity::latest()->first();
    expect($logoutActivity->description)->toContain('logged out')
        ->and($logoutActivity->description)->toContain('Offline');

    // Test inactivity trigger
    $inactivityEvent = new PresenceChanged(
        user: $user,
        status: PresenceStatus::AWAY,
        oldStatus: PresenceStatus::ONLINE,
        trigger: 'inactivity'
    );

    $listener->handle($inactivityEvent);

    $inactivityActivity = Activity::latest()->first();
    expect($inactivityActivity->description)->toContain('went Away due to inactivity');

    // Test manual trigger
    $manualEvent = new PresenceChanged(
        user: $user,
        status: PresenceStatus::AWAY,
        oldStatus: PresenceStatus::ONLINE,
        trigger: 'manual'
    );

    $listener->handle($manualEvent);

    $manualActivity = Activity::latest()->first();
    expect($manualActivity->description)->toContain('manually changed status to Away');
});
