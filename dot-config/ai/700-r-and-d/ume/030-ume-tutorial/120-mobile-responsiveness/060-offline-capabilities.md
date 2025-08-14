# Offline Capabilities

<link rel="stylesheet" href="../assets/css/styles.css">

Mobile users often experience intermittent connectivity. Implementing offline capabilities in your UME application can significantly improve the user experience by allowing users to continue working even when their connection is unreliable or unavailable.

## Understanding Offline-First Design

Offline-first is an approach to web development that prioritizes making applications work without an internet connection:

1. **Core Principles**:
   - Assume the network is unreliable
   - Store data locally first, then sync with the server
   - Provide meaningful feedback about connection status
   - Gracefully handle reconnection

2. **Benefits**:
   - Better user experience in areas with poor connectivity
   - Faster perceived performance (local data access)
   - Reduced server load
   - Lower data usage

## Service Workers

Service workers are the foundation of offline capabilities:

### 1. Basic Service Worker Setup

```javascript
// public/service-worker.js
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open('ume-static-v1').then((cache) => {
            return cache.addAll([
                '/',
                '/offline',
                '/css/app.css',
                '/js/app.js',
                '/images/logo.png',
                '/images/offline.svg'
            ]);
        })
    );
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.filter((cacheName) => {
                    return cacheName.startsWith('ume-') && cacheName !== 'ume-static-v1';
                }).map((cacheName) => {
                    return caches.delete(cacheName);
                })
            );
        })
    );
});

self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request).then((response) => {
            return response || fetch(event.request).catch(() => {
                if (event.request.mode === 'navigate') {
                    return caches.match('/offline');
                }
            });
        })
    );
});
```

### 2. Register the Service Worker

```javascript
// resources/js/service-worker-registration.js
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js')
            .then((registration) => {
                console.log('ServiceWorker registered: ', registration);
            })
            .catch((error) => {
                console.log('ServiceWorker registration failed: ', error);
            });
    });
}
```

### 3. Create an Offline Page

```php
<!-- resources/views/offline.blade.php -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Offline - UME Application</title>
    <link rel="stylesheet" href="/css/app.css">
</head>
<body class="bg-gray-100">
    <div class="min-h-screen flex items-center justify-center">
        <div class="max-w-md w-full p-6 bg-white rounded-lg shadow-md">
            <div class="text-center">
                <img src="/images/offline.svg" alt="Offline" class="w-32 h-32 mx-auto">
                <h1 class="mt-4 text-xl font-bold text-gray-900">You're offline</h1>
                <p class="mt-2 text-gray-600">
                    It looks like you've lost your internet connection. 
                    Some features may be unavailable until you're back online.
                </p>
                <div class="mt-6">
                    <button id="retry-button" class="px-4 py-2 bg-indigo-600 text-white rounded-md">
                        Try Again
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        document.getElementById('retry-button').addEventListener('click', () => {
            window.location.reload();
        });
    </script>
</body>
</html>
```

## Offline Data Storage

### 1. IndexedDB for Complex Data

IndexedDB is a low-level API for client-side storage of significant amounts of structured data:

```javascript
// resources/js/indexeddb.js
const dbPromise = idb.openDB('ume-db', 1, {
    upgrade(db) {
        // Create object stores
        if (!db.objectStoreNames.contains('users')) {
            db.createObjectStore('users', { keyPath: 'id' });
        }
        if (!db.objectStoreNames.contains('teams')) {
            db.createObjectStore('teams', { keyPath: 'id' });
        }
        if (!db.objectStoreNames.contains('pendingActions')) {
            db.createObjectStore('pendingActions', { keyPath: 'id', autoIncrement: true });
        }
    }
});

// Helper functions for working with IndexedDB
export const idbHelpers = {
    // Get all items from a store
    async getAll(storeName) {
        const db = await dbPromise;
        return db.getAll(storeName);
    },
    
    // Get a single item by key
    async get(storeName, key) {
        const db = await dbPromise;
        return db.get(storeName, key);
    },
    
    // Add an item to a store
    async add(storeName, item) {
        const db = await dbPromise;
        return db.add(storeName, item);
    },
    
    // Put an item in a store (update or add)
    async put(storeName, item) {
        const db = await dbPromise;
        return db.put(storeName, item);
    },
    
    // Delete an item from a store
    async delete(storeName, key) {
        const db = await dbPromise;
        return db.delete(storeName, key);
    },
    
    // Clear all items from a store
    async clear(storeName) {
        const db = await dbPromise;
        return db.clear(storeName);
    },
    
    // Add a pending action to be processed when online
    async addPendingAction(action) {
        const db = await dbPromise;
        return db.add('pendingActions', {
            action: action.type,
            data: action.data,
            timestamp: new Date().toISOString()
        });
    },
    
    // Get all pending actions
    async getPendingActions() {
        const db = await dbPromise;
        return db.getAll('pendingActions');
    },
    
    // Delete a pending action
    async deletePendingAction(id) {
        const db = await dbPromise;
        return db.delete('pendingActions', id);
    }
};
```

### 2. LocalStorage for Simple Data

LocalStorage is simpler but limited to string data:

```javascript
// resources/js/local-storage.js
export const localStorageHelpers = {
    // Save user preferences
    savePreferences(preferences) {
        localStorage.setItem('ume-preferences', JSON.stringify(preferences));
    },
    
    // Get user preferences
    getPreferences() {
        const preferences = localStorage.getItem('ume-preferences');
        return preferences ? JSON.parse(preferences) : {};
    },
    
    // Save authentication token
    saveAuthToken(token) {
        localStorage.setItem('ume-auth-token', token);
    },
    
    // Get authentication token
    getAuthToken() {
        return localStorage.getItem('ume-auth-token');
    },
    
    // Clear authentication token
    clearAuthToken() {
        localStorage.removeItem('ume-auth-token');
    }
};
```

## Offline-First Data Synchronization

### 1. Background Sync with Service Workers

```javascript
// public/service-worker.js (additional code)
self.addEventListener('sync', (event) => {
    if (event.tag === 'sync-pending-actions') {
        event.waitUntil(syncPendingActions());
    }
});

async function syncPendingActions() {
    const db = await idb.openDB('ume-db', 1);
    const pendingActions = await db.getAll('pendingActions');
    
    for (const action of pendingActions) {
        try {
            const response = await fetch('/api/sync', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify(action)
            });
            
            if (response.ok) {
                await db.delete('pendingActions', action.id);
            }
        } catch (error) {
            console.error('Sync failed for action:', action, error);
            // Will retry on next sync event
        }
    }
}
```

### 2. Manual Synchronization

```javascript
// resources/js/sync-manager.js
import { idbHelpers } from './indexeddb';

export const SyncManager = {
    // Check if we're online
    isOnline() {
        return navigator.onLine;
    },
    
    // Register event listeners for online/offline events
    init() {
        window.addEventListener('online', this.handleOnline.bind(this));
        window.addEventListener('offline', this.handleOffline.bind(this));
        
        // Initial check
        if (this.isOnline()) {
            this.syncPendingActions();
        }
    },
    
    // Handle coming back online
    handleOnline() {
        document.body.classList.remove('offline-mode');
        document.dispatchEvent(new CustomEvent('ume:online'));
        
        this.syncPendingActions();
        
        // Register a background sync if supported
        if ('serviceWorker' in navigator && 'SyncManager' in window) {
            navigator.serviceWorker.ready.then((registration) => {
                registration.sync.register('sync-pending-actions');
            });
        }
    },
    
    // Handle going offline
    handleOffline() {
        document.body.classList.add('offline-mode');
        document.dispatchEvent(new CustomEvent('ume:offline'));
    },
    
    // Manually sync pending actions
    async syncPendingActions() {
        if (!this.isOnline()) {
            return;
        }
        
        const pendingActions = await idbHelpers.getPendingActions();
        
        for (const action of pendingActions) {
            try {
                const response = await fetch('/api/sync', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: JSON.stringify(action)
                });
                
                if (response.ok) {
                    await idbHelpers.deletePendingAction(action.id);
                }
            } catch (error) {
                console.error('Manual sync failed for action:', action, error);
            }
        }
    },
    
    // Add an action to be performed when online
    async addPendingAction(type, data) {
        await idbHelpers.addPendingAction({
            type,
            data,
            timestamp: new Date().toISOString()
        });
        
        // Try to sync immediately if we're online
        if (this.isOnline()) {
            this.syncPendingActions();
        }
    }
};
```

## Implementing Offline UI Components

### 1. Connection Status Indicator

```php
<!-- resources/views/components/connection-status.blade.php -->
<div x-data="{ online: navigator.onLine }"
     x-init="
        window.addEventListener('online', () => online = true);
        window.addEventListener('offline', () => online = false);
     "
     :class="online ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'"
     class="px-4 py-2 rounded-md flex items-center text-sm"
     x-show="!online || $store.pendingActions.count > 0">
    
    <span x-show="online" class="flex items-center">
        <x-flux::icon name="cloud-upload" class="h-4 w-4 mr-1" />
        <span x-text="$store.pendingActions.count + ' items pending sync'"></span>
    </span>
    
    <span x-show="!online" class="flex items-center">
        <x-flux::icon name="wifi-off" class="h-4 w-4 mr-1" />
        <span>You're offline. Changes will be saved when you reconnect.</span>
    </span>
</div>

<script>
    document.addEventListener('alpine:init', () => {
        Alpine.store('pendingActions', {
            count: 0,
            
            init() {
                this.updateCount();
                
                // Update count when online/offline events occur
                document.addEventListener('ume:online', () => this.updateCount());
                document.addEventListener('ume:offline', () => this.updateCount());
                
                // Update count periodically
                setInterval(() => this.updateCount(), 30000);
            },
            
            async updateCount() {
                const pendingActions = await idbHelpers.getPendingActions();
                this.count = pendingActions.length;
            }
        });
    });
</script>
```

### 2. Offline-Aware Forms

```php
<!-- resources/views/components/offline-form.blade.php -->
<form x-data="{ 
        submitting: false,
        offline: !navigator.onLine,
        init() {
            window.addEventListener('online', () => this.offline = false);
            window.addEventListener('offline', () => this.offline = true);
        }
     }"
     @submit.prevent="submitForm">
    
    {{ $slot }}
    
    <div class="mt-4 flex justify-between items-center">
        <x-flux::button type="submit" :disabled="submitting">
            <span x-show="!submitting">Save</span>
            <span x-show="submitting && !offline">Saving...</span>
            <span x-show="submitting && offline">Saving Offline...</span>
        </x-flux::button>
        
        <span x-show="offline" class="text-sm text-red-600 flex items-center">
            <x-flux::icon name="wifi-off" class="h-4 w-4 mr-1" />
            You're offline. Changes will sync when you reconnect.
        </span>
    </div>
</form>

<script>
    function submitForm() {
        this.submitting = true;
        
        const formData = new FormData(this.$el);
        const data = Object.fromEntries(formData.entries());
        
        if (this.offline) {
            // Save to IndexedDB for later sync
            SyncManager.addPendingAction('updateProfile', data)
                .then(() => {
                    this.submitting = false;
                    // Show success message
                    Alpine.store('notifications').add({
                        type: 'success',
                        message: 'Changes saved offline. Will sync when you reconnect.'
                    });
                })
                .catch((error) => {
                    this.submitting = false;
                    console.error('Failed to save offline:', error);
                    // Show error message
                    Alpine.store('notifications').add({
                        type: 'error',
                        message: 'Failed to save changes offline.'
                    });
                });
        } else {
            // Normal form submission
            fetch('/api/profile', {
                method: 'POST',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                },
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                this.submitting = false;
                // Show success message
                Alpine.store('notifications').add({
                    type: 'success',
                    message: 'Profile updated successfully.'
                });
            })
            .catch(error => {
                this.submitting = false;
                console.error('Error:', error);
                // Show error message
                Alpine.store('notifications').add({
                    type: 'error',
                    message: 'Failed to update profile.'
                });
            });
        }
    }
</script>
```

### 3. Offline Data Display

```php
<!-- resources/views/components/team-list.blade.php -->
<div x-data="{ 
        teams: [],
        loading: true,
        offline: !navigator.onLine,
        
        init() {
            this.loadTeams();
            
            window.addEventListener('online', () => {
                this.offline = false;
                this.loadTeams();
            });
            
            window.addEventListener('offline', () => {
                this.offline = true;
                this.loadOfflineTeams();
            });
        },
        
        async loadTeams() {
            this.loading = true;
            
            try {
                if (this.offline) {
                    await this.loadOfflineTeams();
                    return;
                }
                
                const response = await fetch('/api/teams');
                const data = await response.json();
                
                this.teams = data.teams;
                
                // Cache the teams for offline use
                await idbHelpers.clear('teams');
                for (const team of this.teams) {
                    await idbHelpers.put('teams', team);
                }
            } catch (error) {
                console.error('Error loading teams:', error);
                await this.loadOfflineTeams();
            } finally {
                this.loading = false;
            }
        },
        
        async loadOfflineTeams() {
            this.teams = await idbHelpers.getAll('teams');
        }
     }">
    
    <div x-show="offline" class="mb-4 p-2 bg-yellow-100 text-yellow-800 rounded-md text-sm">
        <p class="flex items-center">
            <x-flux::icon name="exclamation-circle" class="h-4 w-4 mr-1" />
            You're viewing offline data. Some information may not be up to date.
        </p>
    </div>
    
    <div x-show="loading" class="p-4 text-center">
        <x-flux::spinner class="h-8 w-8 text-indigo-600" />
    </div>
    
    <div x-show="!loading" class="space-y-4">
        <template x-for="team in teams" :key="team.id">
            <div class="p-4 border rounded-md">
                <h3 x-text="team.name" class="text-lg font-medium"></h3>
                <p x-text="'Members: ' + team.member_count" class="text-sm text-gray-600"></p>
            </div>
        </template>
        
        <div x-show="!loading && teams.length === 0" class="p-4 text-center text-gray-500">
            No teams found.
        </div>
    </div>
</div>
```

## Server-Side Considerations

### 1. Handling Offline Sync Requests

```php
// routes/api.php
Route::post('/sync', [SyncController::class, 'handleSync'])
    ->middleware(['auth:sanctum']);

// app/Http/Controllers/SyncController.php
public function handleSync(Request $request)
{
    $action = $request->all();
    
    try {
        switch ($action['action']) {
            case 'updateProfile':
                return $this->handleProfileUpdate($request->user(), $action['data']);
            
            case 'createTeam':
                return $this->handleTeamCreation($request->user(), $action['data']);
            
            case 'updateTeamMember':
                return $this->handleTeamMemberUpdate($request->user(), $action['data']);
            
            default:
                return response()->json(['error' => 'Unknown action type'], 400);
        }
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
}

private function handleProfileUpdate(User $user, array $data)
{
    // Validate data
    $validator = Validator::make($data, [
        'name' => 'required|string|max:255',
        'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
        // Other validation rules
    ]);
    
    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }
    
    // Update user
    $user->update($validator->validated());
    
    return response()->json(['message' => 'Profile updated successfully']);
}

// Other handler methods...
```

### 2. Conflict Resolution

```php
// app/Http/Controllers/SyncController.php
private function handleTeamUpdate(User $user, array $data)
{
    $team = Team::find($data['id']);
    
    if (!$team) {
        return response()->json(['error' => 'Team not found'], 404);
    }
    
    if (!$user->can('update', $team)) {
        return response()->json(['error' => 'Unauthorized'], 403);
    }
    
    // Check for conflicts
    if (isset($data['updated_at']) && $team->updated_at->gt(Carbon::parse($data['updated_at']))) {
        // The server version is newer than the client version
        return response()->json([
            'conflict' => true,
            'server_version' => $team,
            'client_version' => $data
        ], 409);
    }
    
    // Update team
    $team->update([
        'name' => $data['name'],
        'description' => $data['description'],
        // Other fields
    ]);
    
    return response()->json([
        'message' => 'Team updated successfully',
        'team' => $team
    ]);
}
```

## Testing Offline Capabilities

### 1. Manual Testing

- Use browser DevTools to simulate offline mode
- Test on actual devices with airplane mode
- Test with slow or intermittent connections

### 2. Automated Testing

```javascript
// tests/Browser/OfflineTest.php
public function testOfflineFormSubmission()
{
    $this->browse(function (Browser $browser) {
        $browser->visit('/profile')
                ->assertSee('Profile Information')
                // Simulate going offline
                ->driver->executeScript('window.dispatchEvent(new Event("offline"))');
        
        $browser->assertSee('You\'re offline')
                ->type('name', 'Offline Test User')
                ->press('Save')
                ->waitForText('Changes saved offline')
                ->assertSee('Will sync when you reconnect');
        
        // Simulate coming back online
        $browser->driver->executeScript('window.dispatchEvent(new Event("online"))');
        
        $browser->waitForText('Profile updated successfully')
                ->assertSee('Profile updated successfully');
    });
}
```

## Best Practices for Offline-First Design

1. **Prioritize Core Functionality**: Identify which features must work offline
2. **Provide Clear Feedback**: Always inform users about their connection status
3. **Design for Sync Conflicts**: Have a strategy for handling conflicting changes
4. **Progressive Enhancement**: Start with a basic experience that works offline, then enhance it when online
5. **Test Thoroughly**: Test on real devices with various connection scenarios

## Next Steps

Continue to [Responsive Images](./070-responsive-images.md) to learn how to optimize images for different devices and screen sizes.
