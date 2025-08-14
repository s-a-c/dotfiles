<?php

use App\Enums\PresenceStatus;
use App\Events\User\PresenceChanged;
use App\Http\Controllers\PresenceController;
use App\Models\User;
use App\Services\PresenceService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Event;
use Mockery;

test('presence controller updates user status', function () {
    Event::fake();

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::OFFLINE->value,
    ]);

    Auth::shouldReceive('user')->andReturn($user);

    $request = Request::create('/presence', 'PUT', [
        'status' => 'online',
    ]);

    $presenceService = new PresenceService();
    $controller = new PresenceController($presenceService);

    $response = $controller->update($request);
    $data = json_decode($response->getContent(), true);

    expect($data['success'])->toBeTrue()
        ->and($data['status'])->toBe('online')
        ->and($data['label'])->toBe('Online')
        ->and($user->presence_status)->toBe(PresenceStatus::ONLINE);

    Event::assertDispatched(PresenceChanged::class);
});

test('presence controller includes trigger parameter', function () {
    Event::fake();

    $user = User::factory()->create([
        'presence_status' => PresenceStatus::ONLINE->value,
    ]);

    Auth::shouldReceive('user')->andReturn($user);

    $request = Request::create('/presence', 'PUT', [
        'status' => 'away',
        'trigger' => 'inactivity',
    ]);

    $presenceService = new PresenceService();
    $controller = new PresenceController($presenceService);

    $controller->update($request);

    Event::assertDispatched(PresenceChanged::class, function ($event) use ($user) {
        return $event->user->id === $user->id && 
               $event->status === PresenceStatus::AWAY &&
               $event->trigger === 'inactivity';
    });
});

test('presence controller validates input', function () {
    $user = User::factory()->create();
    Auth::shouldReceive('user')->andReturn($user);

    // Invalid status
    $request = Request::create('/presence', 'PUT', [
        'status' => 'invalid-status',
    ]);

    $presenceService = Mockery::mock(PresenceService::class);
    $presenceService->shouldNotReceive('updatePresence');

    $controller = new PresenceController($presenceService);

    expect(fn() => $controller->update($request))->toThrow(
        \Illuminate\Validation\ValidationException::class
    );

    // Invalid trigger
    $request = Request::create('/presence', 'PUT', [
        'status' => 'online',
        'trigger' => 'invalid-trigger',
    ]);

    expect(fn() => $controller->update($request))->toThrow(
        \Illuminate\Validation\ValidationException::class
    );
});
