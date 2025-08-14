# Presence Status Test

This test verifies the functionality of the `PresenceStatus` enum and the `PresenceService` class.

## What This Test Covers

- Enum cases and values
- Helper methods on the enum
- User model casting to enum
- Presence service functionality
- Event dispatching when status changes
- Broadcast channel configuration
- Data formatting for broadcasts

## Key Test Cases

1. **Enum Structure**: Verifies that the enum has the expected cases (online, offline, away)
2. **Helper Methods**: Tests the label and indicator class methods
3. **Model Casting**: Ensures the User model correctly casts the presence_status field to the enum
4. **Status Updates**: Tests that the PresenceService correctly updates user status
5. **Event Dispatching**: Verifies that events are dispatched when status changes
6. **Broadcast Channels**: Tests that events are broadcast to the correct channels
7. **Data Formatting**: Ensures the broadcast data is correctly formatted

## Running This Test

```bash
php artisan test --filter=PresenceStatusTest
```
