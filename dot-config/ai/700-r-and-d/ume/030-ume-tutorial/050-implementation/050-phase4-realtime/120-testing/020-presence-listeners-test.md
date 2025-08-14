# Presence Listeners Test

This test verifies the functionality of the login and logout presence listeners.

## What This Test Covers

- Login event listener
- Logout event listener
- Presence activity logging
- Event dispatching

## Key Test Cases

1. **Login Listener**: Tests that the login listener marks users as online
2. **Logout Listener**: Tests that the logout listener marks users as offline
3. **Event Dispatching**: Verifies that events are dispatched with the correct data
4. **Trigger Parameter**: Tests that the trigger parameter is correctly set
5. **Activity Logging**: Ensures that activity is logged with the correct description

## Running This Test

```bash
php artisan test --filter=PresenceListenersTest
```
