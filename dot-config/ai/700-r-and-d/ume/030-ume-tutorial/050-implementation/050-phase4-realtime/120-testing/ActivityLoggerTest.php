<?php

use App\Enums\PresenceStatus;
use App\Models\User;
use App\Services\ActivityLoggerService;
use Illuminate\Support\Facades\Auth;
use Spatie\Activitylog\Models\Activity;

test('activity logger service logs presence changes', function () {
    // Clear existing activity logs
    Activity::query()->delete();

    $user = User::factory()->create([
        'name' => 'Test User',
    ]);

    $logger = new ActivityLoggerService();
    $logger->logPresenceChange(
        user: $user,
        oldStatus: 'offline',
        newStatus: 'online',
        trigger: 'login',
        causer: $user
    );

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

test('activity logger service logs auth events', function () {
    // Clear existing activity logs
    Activity::query()->delete();

    $user = User::factory()->create();

    $logger = new ActivityLoggerService();
    $logger->logAuthEvent(
        user: $user,
        event: 'login',
        additionalProperties: [
            'ip_address' => '127.0.0.1',
            'user_agent' => 'Mozilla/5.0',
        ]
    );

    $activity = Activity::first();

    expect($activity)->not->toBeNull()
        ->and($activity->log_name)->toBe('authentication')
        ->and($activity->subject_id)->toBe($user->id)
        ->and($activity->causer_id)->toBe($user->id)
        ->and($activity->properties->toArray())->toHaveKeys(['event', 'ip_address', 'user_agent'])
        ->and($activity->properties->get('event'))->toBe('login')
        ->and($activity->properties->get('ip_address'))->toBe('127.0.0.1');
});

test('activity logger service logs profile updates', function () {
    // Clear existing activity logs
    Activity::query()->delete();

    $user = User::factory()->create();
    $admin = User::factory()->create(['type' => 'admin']);

    $logger = new ActivityLoggerService();
    $logger->logProfileUpdate(
        user: $user,
        changedAttributes: [
            'name' => [
                'old' => 'Old Name',
                'new' => 'New Name',
            ],
            'email' => [
                'old' => 'old@example.com',
                'new' => 'new@example.com',
            ],
        ],
        causer: $admin
    );

    $activity = Activity::first();

    expect($activity)->not->toBeNull()
        ->and($activity->log_name)->toBe('profile_updated')
        ->and($activity->subject_id)->toBe($user->id)
        ->and($activity->causer_id)->toBe($admin->id)
        ->and($activity->properties->toArray())->toHaveKey('changed_attributes')
        ->and($activity->properties->get('changed_attributes'))->toHaveKeys(['name', 'email']);
});

test('activity logger service logs team actions', function () {
    // Clear existing activity logs
    Activity::query()->delete();

    $user = User::factory()->create();
    $team = $user->ownedTeams()->create(['name' => 'Test Team']);

    $logger = new ActivityLoggerService();
    $logger->logTeamAction(
        team: $team,
        user: $user,
        action: 'created',
        additionalProperties: [
            'team_name' => 'Test Team',
        ]
    );

    $activity = Activity::first();

    expect($activity)->not->toBeNull()
        ->and($activity->log_name)->toBe('team_action')
        ->and($activity->subject_id)->toBe($team->id)
        ->and($activity->subject_type)->toBe(get_class($team))
        ->and($activity->causer_id)->toBe($user->id)
        ->and($activity->properties->toArray())->toHaveKeys(['action', 'team_name'])
        ->and($activity->properties->get('action'))->toBe('created')
        ->and($activity->properties->get('team_name'))->toBe('Test Team');
});
