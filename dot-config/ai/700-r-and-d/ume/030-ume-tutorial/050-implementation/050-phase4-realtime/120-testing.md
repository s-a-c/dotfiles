# Testing in Phase 4: Real-time Features

This document outlines the testing approach for the Real-time Features phase of the UME tutorial. Comprehensive testing is essential to ensure that our real-time notifications, broadcasting, and event handling are working correctly.

## Test Files

The test files for this phase are located in the [120-testing](./120-testing/) directory:

1. [Presence Status Test](./120-testing/010-presence-status-test.md) - Tests for the presence status enum and service
2. [Presence Listeners Test](./120-testing/020-presence-listeners-test.md) - Tests for the login/logout presence listeners
3. [Presence Controller Test](./120-testing/030-presence-controller-test.md) - Tests for the presence controller
4. [Activity Logger Test](./120-testing/040-activity-logger-test.md) - Tests for the activity logging functionality

## How to Run the Tests

To run all the tests for the Real-time Features phase, use the following command:

```bash
php artisan test --filter=PresenceStatusTest,PresenceListenersTest,PresenceControllerTest,ActivityLoggerTest
```

To run a specific test, use the following command:

```bash
php artisan test --filter=PresenceStatusTest
```

## Testing Strategy

For the Real-time Features phase, we'll focus on:

1. **Event Tests**: Ensure that events are correctly dispatched and handled
2. **Notification Tests**: Verify that notifications are sent and received correctly
3. **Broadcasting Tests**: Test that events are correctly broadcast to the appropriate channels
4. **WebSocket Tests**: Verify that WebSocket connections work correctly
5. **Integration Tests**: Test how these components work together

## Event Tests

```php
<?php

namespace Tests\Unit\Events;

use App\Events\TeamMemberAdded;use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Event;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamEventTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function team_member_added_event_is_dispatched()
    {
        Event::fake();

        $team = Team::factory()->create();
        $user = User::factory()->create();

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        // Manually dispatch the event
        event(new TeamMemberAdded($team, $user));

        // Assert the event was dispatched
        Event::assertDispatched(TeamMemberAdded::class, function ($event) use ($team, $user) {
            return $event->team->id === $team->id && $event->user->id === $user->id;
        });
    }

    #[Test]
    public function team_member_added_event_contains_correct_data()
    {
        $team = Team::factory()->create(['name' => 'Test Team']);
        $user = User::factory()->create(['given_name' => 'John', 'family_name' => 'Doe']);

        $event = new TeamMemberAdded($team, $user);

        $this->assertEquals($team->id, $event->team->id);
        $this->assertEquals('Test Team', $event->team->name);
        $this->assertEquals($user->id, $event->user->id);
        $this->assertEquals('John Doe', $event->user->full_name);
    }

    #[Test]
    public function team_member_added_event_is_broadcastable()
    {
        $team = Team::factory()->create();
        $user = User::factory()->create();

        $event = new TeamMemberAdded($team, $user);

        // Check that the event implements the ShouldBroadcast interface
        $this->assertInstanceOf(\Illuminate\Contracts\Broadcasting\ShouldBroadcast::class, $event);

        // Check the broadcast channel
        $this->assertEquals('team.' . $team->id, $event->broadcastOn()->name);

        // Check the broadcast data
        $broadcastData = $event->broadcastWith();
        $this->assertArrayHasKey('team', $broadcastData);
        $this->assertArrayHasKey('user', $broadcastData);
        $this->assertEquals($team->id, $broadcastData['team']['id']);
        $this->assertEquals($user->id, $broadcastData['user']['id']);
    }
}
```

## Notification Tests

```php
<?php

namespace Tests\Unit\Notifications;

use App\Models\Team;use App\Models\User;use App\Notifications\TeamMemberAddedNotification;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Notifications\AnonymousNotifiable;use Illuminate\Support\Facades\Notification;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class TeamNotificationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function team_member_added_notification_is_sent()
    {
        Notification::fake();

        $team = Team::factory()->create();
        $user = User::factory()->create();
        $owner = User::factory()->create();

        // Set the owner
        $team->owner_id = $owner->id;
        $team->save();

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        // Send notification
        $owner->notify(new TeamMemberAddedNotification($team, $user));

        // Assert notification was sent
        Notification::assertSentTo(
            $owner,
            TeamMemberAddedNotification::class,
            function ($notification, $channels) use ($team, $user) {
                return $notification->team->id === $team->id &&
                       $notification->user->id === $user->id;
            }
        );
    }

    #[Test]
    public function team_member_added_notification_contains_correct_data()
    {
        $team = Team::factory()->create(['name' => 'Test Team']);
        $user = User::factory()->create(['given_name' => 'John', 'family_name' => 'Doe']);

        $notification = new TeamMemberAddedNotification($team, $user);

        // Check mail notification
        $mail = $notification->toMail(new AnonymousNotifiable());

        $this->assertStringContainsString('John Doe has joined Test Team', $mail->subject);
        $this->assertStringContainsString('John Doe', $mail->greeting);

        // Check database notification
        $array = $notification->toArray(new AnonymousNotifiable());

        $this->assertEquals('team_member_added', $array['type']);
        $this->assertEquals($team->id, $array['team_id']);
        $this->assertEquals($user->id, $array['user_id']);
        $this->assertEquals('John Doe has joined Test Team', $array['message']);
    }

    #[Test]
    public function team_member_added_notification_uses_correct_channels()
    {
        $team = Team::factory()->create();
        $user = User::factory()->create();

        $notification = new TeamMemberAddedNotification($team, $user);

        // Check that the notification uses the correct channels
        $channels = $notification->via(new AnonymousNotifiable());

        $this->assertContains('mail', $channels);
        $this->assertContains('database', $channels);
        $this->assertContains('broadcast', $channels);
    }

    #[Test]
    public function team_member_added_notification_is_broadcastable()
    {
        $team = Team::factory()->create(['name' => 'Test Team']);
        $user = User::factory()->create(['given_name' => 'John', 'family_name' => 'Doe']);

        $notification = new TeamMemberAddedNotification($team, $user);

        // Check broadcast data
        $broadcastData = $notification->toBroadcast(new AnonymousNotifiable())->data;

        $this->assertArrayHasKey('team', $broadcastData);
        $this->assertArrayHasKey('user', $broadcastData);
        $this->assertEquals($team->id, $broadcastData['team']['id']);
        $this->assertEquals('Test Team', $broadcastData['team']['name']);
        $this->assertEquals($user->id, $broadcastData['user']['id']);
        $this->assertEquals('John Doe', $broadcastData['user']['full_name']);
    }
}
```

## Broadcasting Tests

```php
<?php

namespace Tests\Feature\Broadcasting;

use App\Events\TeamMemberAdded;use App\Models\Team;use App\Models\User;use Illuminate\Broadcasting\Channel;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Broadcast;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class BroadcastingTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_authenticate_to_private_channel()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        // Mock the broadcast driver
        Broadcast::shouldReceive('auth')
            ->once()
            ->andReturn(['id' => $user->id]);

        // Attempt to authenticate to the private channel
        $response = $this->actingAs($user)->post('/broadcasting/auth', [
            'socket_id' => '1234.1234',
            'channel_name' => 'private-team.' . $team->id,
        ]);

        $response->assertStatus(200);
        $response->assertJson(['id' => $user->id]);
    }

    #[Test]
    public function user_cannot_authenticate_to_private_channel_for_team_they_do_not_belong_to()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();

        // User is not added to the team

        // Attempt to authenticate to the private channel
        $response = $this->actingAs($user)->post('/broadcasting/auth', [
            'socket_id' => '1234.1234',
            'channel_name' => 'private-team.' . $team->id,
        ]);

        $response->assertStatus(403);
    }

    #[Test]
    public function event_is_broadcast_on_correct_channel()
    {
        $team = Team::factory()->create();
        $user = User::factory()->create();

        $event = new TeamMemberAdded($team, $user);

        // Check that the event is broadcast on the correct channel
        $channel = $event->broadcastOn();

        $this->assertInstanceOf(Channel::class, $channel);
        $this->assertEquals('team.' . $team->id, $channel->name);
    }

    #[Test]
    public function event_has_correct_broadcast_name()
    {
        $team = Team::factory()->create();
        $user = User::factory()->create();

        $event = new TeamMemberAdded($team, $user);

        // Check that the event has the correct broadcast name
        $this->assertEquals('team.member.added', $event->broadcastAs());
    }
}
```

## WebSocket Tests

```php
<?php

namespace Tests\Feature\WebSockets;

use App\Events\TeamMemberAdded;use App\Models\Team;use App\Models\User;use Illuminate\Foundation\Testing\RefreshDatabase;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class WebSocketTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function websocket_server_is_running()
    {
        // This test checks if the WebSocket server is running
        // Note: This is a simplified test and may need to be adjusted based on your setup

        $response = $this->get('/laravel-websockets');

        // If the WebSocket server is running, the dashboard should be accessible
        $response->assertStatus(200);
    }

    #[Test]
    public function websocket_authentication_works()
    {
        $user = User::factory()->create();

        // Attempt to authenticate for WebSocket connection
        $response = $this->actingAs($user)->post('/broadcasting/auth', [
            'socket_id' => '1234.1234',
            'channel_name' => 'private-user.' . $user->id,
        ]);

        $response->assertStatus(200);
        $this->assertNotEmpty($response->getContent());
        $this->assertJson($response->getContent());
    }

    #[Test]
    public function presence_channel_authentication_includes_user_data()
    {
        $user = User::factory()->create([
            'given_name' => 'John',
            'family_name' => 'Doe',
        ]);
        $team = Team::factory()->create();

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        // Attempt to authenticate to the presence channel
        $response = $this->actingAs($user)->post('/broadcasting/auth', [
            'socket_id' => '1234.1234',
            'channel_name' => 'presence-team.' . $team->id,
        ]);

        $response->assertStatus(200);
        $responseData = json_decode($response->getContent(), true);

        $this->assertArrayHasKey('channel_data', $responseData);
        $channelData = json_decode($responseData['channel_data'], true);

        $this->assertEquals($user->id, $channelData['user_id']);
        $this->assertEquals('John Doe', $channelData['user_info']['name']);
    }
}
```

## Integration Tests

```php
<?php

namespace Tests\Feature;

use App\Events\TeamMemberAdded;use App\Models\Team;use App\Models\User;use App\Notifications\TeamMemberAddedNotification;use Illuminate\Foundation\Testing\RefreshDatabase;use Illuminate\Support\Facades\Event;use Illuminate\Support\Facades\Notification;use old\TestCase;use PHPUnit\Framework\Attributes\Test;

class RealTimeIntegrationTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function adding_team_member_dispatches_event_and_sends_notification()
    {
        Event::fake([TeamMemberAdded::class]);
        Notification::fake();

        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Add user to team through the controller
        $response = $this->actingAs($owner)->post("/teams/{$team->id}/members", [
            'email' => $user->email,
            'role' => 'member',
        ]);

        $response->assertRedirect();

        // Assert event was dispatched
        Event::assertDispatched(TeamMemberAdded::class, function ($event) use ($team, $user) {
            return $event->team->id === $team->id && $event->user->id === $user->id;
        });

        // Assert notification was sent
        Notification::assertSentTo(
            $owner,
            TeamMemberAddedNotification::class,
            function ($notification, $channels) use ($team, $user) {
                return $notification->team->id === $team->id &&
                       $notification->user->id === $user->id;
            }
        );
    }

    #[Test]
    public function real_time_notification_is_marked_as_read()
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $owner->id]);

        // Create a notification
        $notification = new TeamMemberAddedNotification($team, $user);
        $owner->notify($notification);

        // Check that the notification exists and is unread
        $this->assertCount(1, $owner->notifications);
        $this->assertNull($owner->notifications->first()->read_at);

        // Mark the notification as read
        $response = $this->actingAs($owner)->post("/notifications/{$owner->notifications->first()->id}/read");

        $response->assertStatus(200);

        // Check that the notification is now marked as read
        $owner->refresh();
        $this->assertNotNull($owner->notifications->first()->read_at);
    }

    #[Test]
    public function user_can_receive_real_time_updates()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create();

        // Add user to team
        $team->users()->attach($user->id, ['role' => 'member']);

        // Check that the user can authenticate to the team channel
        $response = $this->actingAs($user)->post('/broadcasting/auth', [
            'socket_id' => '1234.1234',
            'channel_name' => 'private-team.' . $team->id,
        ]);

        $response->assertStatus(200);

        // In a real application, we would test the actual WebSocket connection
        // and message reception, but that's beyond the scope of a simple test
    }

    #[Test]
    public function user_sees_notification_count_in_ui()
    {
        $user = User::factory()->create();
        $team = Team::factory()->create(['owner_id' => $user->id]);
        $member = User::factory()->create();

        // Create some notifications
        $notification1 = new TeamMemberAddedNotification($team, $member);
        $notification2 = new TeamMemberAddedNotification($team, User::factory()->create());

        $user->notify($notification1);
        $user->notify($notification2);

        // Visit the dashboard
        $response = $this->actingAs($user)->get('/dashboard');

        $response->assertStatus(200);
        $response->assertSee('2 unread notifications');

        // Mark one notification as read
        $this->actingAs($user)->post("/notifications/{$user->notifications->first()->id}/read");

        // Visit the dashboard again
        $response = $this->actingAs($user)->get('/dashboard');

        $response->assertStatus(200);
        $response->assertSee('1 unread notification');
    }
}
```

## Running the Tests

To run the tests for the Real-time Features phase, use the following command:

```bash
php artisan test --filter=TeamEventTest,TeamNotificationTest,BroadcastingTest,WebSocketTest,RealTimeIntegrationTest
```

Or run all tests with:

```bash
php artisan test
```

## Test Coverage

To ensure comprehensive test coverage for the Real-time Features phase, make sure your tests cover:

1. Event dispatching and handling
2. Notification sending and receiving
3. Broadcasting to channels
4. WebSocket connections and authentication
5. Integration between these components

## Best Practices

1. **Use PHP Attributes**: Always use PHP 8 attributes (`#[Test]`) instead of PHPDoc annotations (`/** @test */`).
2. **Fake Events and Notifications**: Use `Event::fake()` and `Notification::fake()` to test event dispatching and notification sending without actually sending them.
3. **Test Channel Authentication**: Verify that users can only authenticate to channels they have access to.
4. **Test Broadcast Data**: Ensure that the data being broadcast is correct and contains all necessary information.
5. **Test Real-time UI Updates**: Verify that the UI correctly updates when real-time events occur.
6. **Use Integration Tests**: Test how events, notifications, and broadcasting work together in real-world scenarios.
7. **Mock External Services**: Use mocks for external services like Pusher to avoid making actual API calls during tests.

By following these guidelines, you'll ensure that your Real-time Features phase is thoroughly tested and ready for the next phases of the UME tutorial.

## Writing Your Own Tests

When writing your own tests for real-time features, consider the following:

1. **Test Each Component Separately**: Start by testing individual components (enums, services, controllers) before testing their integration.

2. **Mock External Services**: Use mocks for external services like Pusher or Redis to avoid making actual API calls during tests.

3. **Test Event Broadcasting**: Verify that events are broadcast to the correct channels with the correct data.

4. **Test Channel Authorization**: Ensure that users can only access channels they have permission to access.

5. **Test Real-time UI Updates**: Verify that the UI correctly updates when real-time events occur.

6. **Test Error Handling**: Ensure that your application handles connection failures and other errors gracefully.

7. **Test Performance**: Verify that your real-time features perform well under load.

## Troubleshooting Common Issues

### WebSocket Connection Issues

If you're having trouble with WebSocket connections:

1. Ensure the WebSocket server is running: `php artisan reverb:start`
2. Check that your `.env` file has the correct configuration for Reverb or Pusher
3. Verify that your frontend is correctly configured to connect to the WebSocket server

### Event Broadcasting Issues

If events aren't being broadcast:

1. Ensure the event implements the `ShouldBroadcast` interface
2. Check that the `broadcastOn` method returns the correct channel
3. Verify that the event is being dispatched

### Channel Authorization Issues

If users can't connect to channels:

1. Check the channel authorization routes in `routes/channels.php`
2. Ensure the user has permission to access the channel
3. Verify that the channel name format is correct
