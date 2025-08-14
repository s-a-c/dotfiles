# Realtime Tests

This directory contains tests for the realtime functionality implemented in Phase 4.

## Contents

The tests in this directory verify the functionality of:

- [Presence Status Test](./010-presence-status-test.md) - Tests for the presence status enum and service
- [Presence Listeners Test](./020-presence-listeners-test.md) - Tests for the login/logout presence listeners
- [Presence Controller Test](./030-presence-controller-test.md) - Tests for the presence controller
- [Activity Logger Test](./040-activity-logger-test.md) - Tests for the activity logging functionality

## PHP Test Files

This directory also contains the actual PHP test files that implement the tests:

- `PresenceStatusTest.php` - Implementation of the presence status tests
- `PresenceListenersTest.php` - Implementation of the presence listeners tests
- `PresenceControllerTest.php` - Implementation of the presence controller tests
- `ActivityLoggerTest.php` - Implementation of the activity logger tests

## Running the Tests

To run all the tests in this directory, use the following command:

```bash
php artisan test --filter=PresenceStatusTest,PresenceListenersTest,PresenceControllerTest,ActivityLoggerTest
```

For more detailed information on testing real-time features, see the [main testing documentation](../120-testing.md).
