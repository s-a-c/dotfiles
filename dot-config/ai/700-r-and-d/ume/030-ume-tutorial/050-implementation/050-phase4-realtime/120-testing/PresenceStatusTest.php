<?php

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Support\Facades\Event;

test('presence status enum has expected cases', function () {
    expect(PresenceStatus::cases())->toHaveCount(3)
        ->and(PresenceStatus::ONLINE->value)->toBe('online')
        ->and(PresenceStatus::OFFLINE->value)->toBe('offline')
        ->and(PresenceStatus::AWAY->value)->toBe('away');
});

test('presence status enum has helper methods', function () {
    expect(PresenceStatus::ONLINE->label())->toBe('Online')
        ->and(PresenceStatus::OFFLINE->label())->toBe('Offline')
        ->and(PresenceStatus::AWAY->label())->toBe('Away')
        ->and(PresenceStatus::ONLINE->indicatorClass())->toBe('bg-green-500')
        ->and(PresenceStatus::OFFLINE->indicatorClass())->toBe('bg-gray-400')
        ->and(PresenceStatus::AWAY->indicatorClass())->toBe('bg-yellow-500');
});

test('user model casts presence_status to enum', function () {
    $user = User::factory()->create([
        'presence_status' => PresenceStatus::ONLINE->value,
    ]);

    expect($user->presence_status)->toBeInstanceOf(PresenceStatus::class)
        ->and($user->presence_status)->toBe(PresenceStatus::ONLINE);
});

test('user model has presence helper methods', function () {
    $user = User::factory()->create([
        'presence_status' => PresenceStatus::ONLINE->value,
    ]);

    expect($user->isOnline())->toBeTrue()
        ->and($user->isOffline())->toBeFalse()
        ->and($user->isAway())->toBeFalse();

    $user->presence_status = PresenceStatus::OFFLINE;
    $user->save();

    expect($user->isOnline())->toBeFalse()
        ->and($user->isOffline())->toBeTrue()
        ->and($user->isAway())->toBeFalse();
});

test('presence service updates user status', function () {
    Event::fake();

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::OFFLINE->value,
    ]);

    $service = new PresenceService();
    $result = $service->markOnline($user);

    expect($result)->toBeTrue()
        ->and($user->presence_status)->toBe(PresenceStatus::ONLINE)
        ->and($user->last_seen_at)->not->toBeNull();

    Event::assertDispatched(PresenceChanged::class, function ($event) use ($user) {
        return $event->user->id === $user->id && 
               $event->status === PresenceStatus::ONLINE;
    });
});

test('presence service does not update if status is unchanged', function () {
    Event::fake();

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::ONLINE->value,
        'last_seen_at' => now(),
    ]);

    $service = new PresenceService();
    $result = $service->markOnline($user);

    expect($result)->toBeFalse();

    Event::assertNotDispatched(PresenceChanged::class);
});

test('presence service includes old status and trigger in event', function () {
    Event::fake();

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::ONLINE->value,
    ]);

    $service = new PresenceService();
    $service->markAway($user, 'inactivity');

    Event::assertDispatched(PresenceChanged::class, function ($event) use ($user) {
        return $event->user->id === $user->id && 
               $event->status === PresenceStatus::AWAY &&
               $event->oldStatus === PresenceStatus::ONLINE &&
               $event->trigger === 'inactivity';
    });
});

test('presence changed event broadcasts to correct channels', function () {
    $user = User::factory()->create();
    $team = $user->ownedTeams()->create(['name' => 'Test Team']);

    $event = new PresenceChanged(
        user: $user,
        status: PresenceStatus::ONLINE
    );

    $channels = $event->broadcastOn();
    
    // Convert channels to array for easier testing
    $channelNames = collect($channels)->map(fn($channel) => $channel->name)->all();

    expect($channelNames)->toContain('private-user.' . $user->id)
        ->and($channelNames)->toContain('presence-team.' . $team->id);
});

test('presence changed event formats data correctly', function () {
    $user = User::factory()->create([
        'name' => 'Test User',
        'last_seen_at' => now(),
    ]);

    $event = new PresenceChanged(
        user: $user,
        status: PresenceStatus::ONLINE
    );

    $data = $event->broadcastWith();

    expect($data)->toHaveKeys(['user_id', 'name', 'status', 'last_seen_at'])
        ->and($data['user_id'])->toBe($user->id)
        ->and($data['name'])->toBe('Test User')
        ->and($data['status'])->toBe('online');
});
