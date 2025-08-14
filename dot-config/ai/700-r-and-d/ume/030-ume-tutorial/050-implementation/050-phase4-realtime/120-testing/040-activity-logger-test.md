# Activity Logger Test

This test verifies the functionality of the Activity Logger Service, which logs user presence changes and other activities.

## What This Test Covers

- Activity logging for presence changes
- Context-specific logging
- Log formatting
- Log retrieval

## Key Test Cases

1. **Presence Change Logging**: Tests that presence changes are logged
2. **Context-Specific Descriptions**: Verifies that log descriptions are formatted based on the trigger
3. **Log Data**: Ensures that logs contain the correct data
4. **Log Retrieval**: Tests that logs can be retrieved for specific users and teams

## Running This Test

```bash
php artisan test --filter=ActivityLoggerTest
```
