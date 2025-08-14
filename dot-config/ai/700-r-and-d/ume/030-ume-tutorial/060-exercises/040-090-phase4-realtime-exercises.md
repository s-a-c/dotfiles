# Phase 4: Real-time Features Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of real-time features in the UME tutorial. Each set contains questions and a practical exercise.

## Set 1: Understanding Laravel Broadcasting

### Questions

1. **What is Laravel Echo?**
   - A) A JavaScript library for receiving broadcast events
   - B) A PHP package for sending broadcast events
   - C) A database driver for real-time data
   - D) A testing framework for real-time applications

2. **Which broadcasting driver is recommended for production in the UME tutorial?**
   - A) log
   - B) pusher
   - C) redis
   - D) reverb

3. **What is the purpose of the `BroadcastServiceProvider` in Laravel?**
   - A) To register broadcasting routes
   - B) To configure broadcasting drivers
   - C) To handle authentication for private channels
   - D) To manage WebSocket connections

4. **How are private channels authenticated in Laravel?**
   - A) Using API tokens
   - B) Using a route that returns true/false based on the user's authorization
   - C) Using a separate authentication server
   - D) Private channels are not authenticated

### Exercise

**Implement a basic broadcasting setup.**

Set up a basic broadcasting system in a Laravel application:

1. Configure a broadcasting driver (Reverb or Pusher)
2. Install and configure Laravel Echo and a WebSocket client
3. Create a broadcast event
4. Implement a listener for the event
5. Create a Livewire component that listens for the event
6. Trigger the event from a controller action
7. Test the broadcasting system

Include code snippets for each step and explain your implementation choices.

## Set 2: Real-time Notifications and Presence

### Questions

1. **What is a presence channel in Laravel broadcasting?**
   - A) A channel that shows which users are online
   - B) A channel that requires authentication
   - C) A channel that sends notifications
   - D) A channel that logs user activity

2. **How can you determine which users are currently online in a presence channel?**
   - A) By querying the database
   - B) By using the `here()` method on the channel
   - C) By using a third-party service
   - D) It's not possible to determine which users are online

3. **What is the difference between a notification and a broadcast event?**
   - A) They are the same thing
   - B) Notifications are for emails, broadcast events are for real-time
   - C) Notifications can use multiple channels (mail, database, broadcast), while broadcast events are only for real-time
   - D) Broadcast events are deprecated in favor of notifications

4. **How can you broadcast a notification in Laravel?**
   - A) By implementing the `ShouldBroadcast` interface on the notification
   - B) By using the `broadcast()` method
   - C) By creating a separate broadcast event
   - D) Notifications cannot be broadcasted

### Exercise

**Implement a real-time notification system with presence indicators.**

Create a real-time notification system with the following features:

1. Set up presence channels for teams
2. Implement online/offline indicators for team members
3. Create a notification system for:
   - New team members
   - New messages
   - Task assignments
   - Mentions
4. Create a notification center UI that:
   - Shows unread notifications
   - Allows marking notifications as read
   - Groups notifications by type
   - Updates in real-time
5. Implement notification preferences
6. Add tests for the notification system

Include code snippets for each step and explain your implementation choices.

## Set 3: User Presence State Machine

### Questions

1. **What is the primary purpose of the User Presence State Machine in the UME application?**
   - A) To track user login history
   - B) To show which users are currently online, offline, or away
   - C) To manage user account states like active, suspended, or deleted
   - D) To control user permissions based on their status

2. **Which package is recommended for implementing the User Presence State Machine?**
   - A) `spatie/laravel-model-states`
   - B) `spatie/laravel-model-status`
   - C) A simple Enum-casted column is sufficient
   - D) Both B and C are valid approaches depending on requirements

3. **How are presence status changes typically triggered in the UME application?**
   - A) Only through manual user actions
   - B) Only through automatic system events
   - C) Through a combination of login/logout events, user inactivity, and manual user actions
   - D) Through database triggers

4. **What is the recommended way to broadcast presence status changes?**
   - A) Using a dedicated `PresenceChanged` event that implements `ShouldBroadcast`
   - B) Using Laravel's built-in presence channels
   - C) Using a polling mechanism
   - D) Using server-sent events (SSE)

### Exercise

**Extend the User Presence State Machine.**

Extend the User Presence State Machine with the following features:

1. Add a new presence status: "Do Not Disturb" (DND)
2. Implement a timeout system that automatically changes a user's status to "Away" after 10 minutes of inactivity
3. Create a user preference setting that allows users to:
   - Choose their default status when logging in
   - Enable/disable automatic "Away" status
   - Set a custom timeout period for the "Away" status
4. Add a status message feature that allows users to set a custom message for each status
5. Implement a "Last Seen" feature that shows when a user was last active
6. Create a dashboard widget that shows the status of all team members
7. Add comprehensive logging for all status changes

Include code snippets for each step and explain your implementation choices.

## Set 4: Activity Logging

### Questions

1. **What package is used for activity logging in the UME application?**
   - A) `laravel/activitylog`
   - B) `spatie/laravel-activitylog`
   - C) `monolog/monolog`
   - D) Laravel's built-in logging system

2. **What information should be logged when a user's presence status changes?**
   - A) Only the new status
   - B) The old status, new status, and timestamp
   - C) The old status, new status, timestamp, trigger, and causer
   - D) Just the user ID and timestamp

3. **How can you associate an activity log entry with both the subject and causer?**
   - A) By using the `on()` and `by()` methods
   - B) By using the `performedOn()` and `causedBy()` methods
   - C) By using the `subject()` and `causer()` methods
   - D) This is not possible with the activity log package

4. **What is the benefit of implementing the `ShouldQueue` interface on activity log listeners?**
   - A) It allows logging to be processed in the background
   - B) It prevents logging from happening
   - C) It makes logging synchronous
   - D) It allows multiple log entries to be batched together

### Exercise

**Implement advanced activity logging.**

Implement an advanced activity logging system with the following features:

1. Create a custom activity logger service that:
   - Logs user presence changes
   - Logs user authentication events (login, logout, failed attempts)
   - Logs user profile updates
   - Logs team-related actions (joining, leaving, role changes)
2. Implement a dashboard for administrators to view and filter activity logs
3. Create a user activity timeline that shows a chronological view of a user's activities
4. Implement an export feature that allows exporting activity logs to CSV or PDF
5. Add a purge mechanism that automatically deletes old activity logs
6. Implement a notification system that alerts administrators of suspicious activities
7. Add tests for the activity logging system

Include code snippets for each step and explain your implementation choices.

## Additional Resources

- [Laravel Broadcasting Documentation](https://laravel.com/docs/broadcasting)
- [Laravel Echo Documentation](https://laravel.com/docs/broadcasting#client-side-installation)
- [Laravel Reverb Documentation](https://laravel.com/docs/reverb)
- [Laravel Notifications Documentation](https://laravel.com/docs/notifications)
- [Spatie Activity Log Documentation](https://spatie.be/docs/laravel-activitylog)
