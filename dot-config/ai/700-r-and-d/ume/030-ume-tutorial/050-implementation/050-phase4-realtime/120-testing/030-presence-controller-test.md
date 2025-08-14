# Presence Controller Test

This test verifies the functionality of the Presence Controller, which handles manual status updates from users.

## What This Test Covers

- Status update endpoint
- Input validation
- Event dispatching
- Response formatting

## Key Test Cases

1. **Status Update**: Tests that the controller updates user status
2. **Trigger Parameter**: Verifies that the trigger parameter is correctly passed to the event
3. **Input Validation**: Tests that invalid input is rejected
4. **Response Format**: Ensures the response contains the expected data

## Running This Test

```bash
php artisan test --filter=PresenceControllerTest
```
