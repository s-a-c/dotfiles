### Practical Exercise Solution

Here's a sample implementation of basic offline capabilities for a UME application:

#### 1. Service Worker for Caching Essential Assets

```javascript
// public/service-worker.js
const CACHE_NAME = 'ume-cache-v1';
const STATIC_ASSETS = [
    '/',
    '/offline',
    '/css/app.css',
    '/js/app.js',
    '/images/logo.svg',
    '/images/placeholder-avatar.svg',
    '/images/offline.svg'
];

// Install event - cache static assets
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Caching static assets');
                return cache.addAll(STATIC_ASSETS);
            })
    );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.filter(cacheName => {
                    return cacheName.startsWith('ume-') && cacheName !== CACHE_NAME;
                }).map(cacheName => {
                    console.log('Deleting old cache:', cacheName);
                    return caches.delete(cacheName);
                })
            );
        })
    );
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', event => {
    // Skip non-GET requests and browser extensions
    if (event.request.method !== 'GET' || event.request.url.startsWith('chrome-extension')) {
        return;
    }
    
    // Skip cross-origin requests
    if (!event.request.url.startsWith(self.location.origin)) {
        return;
    }
    
    // Handle API requests differently
    if (event.request.url.includes('/api/')) {
        // For API requests, try network first, then fallback to offline response
        event.respondWith(
            fetch(event.request)
                .catch(() => {
                    // If it's a team members request, try to return cached data
                    if (event.request.url.includes('/api/team-members')) {
                        return caches.match('/api/team-members')
                            .then(response => {
                                return response || new Response(
                                    JSON.stringify({ 
                                        error: 'You are offline',
                                        cached: false
                                    }),
                                    { 
                                        headers: { 'Content-Type': 'application/json' } 
                                    }
                                );
                            });
                    }
                    
                    // For other API requests, return a generic offline response
                    return new Response(
                        JSON.stringify({ 
                            error: 'You are offline',
                            endpoint: event.request.url
                        }),
                        { 
                            headers: { 'Content-Type': 'application/json' } 
                        }
                    );
                })
        );
        return;
    }
    
    // For page navigations, use a network-first approach
    if (event.request.mode === 'navigate') {
        event.respondWith(
            fetch(event.request)
                .catch(() => {
                    return caches.match('/offline');
                })
        );
        return;
    }
    
    // For other requests, use a cache-first approach
    event.respondWith(
        caches.match(event.request)
            .then(cachedResponse => {
                // Return cached response if available
                if (cachedResponse) {
                    return cachedResponse;
                }
                
                // Otherwise fetch from network
                return fetch(event.request)
                    .then(response => {
                        // Cache successful responses
                        if (response.ok && response.status === 200) {
                            const responseToCache = response.clone();
                            caches.open(CACHE_NAME)
                                .then(cache => {
                                    cache.put(event.request, responseToCache);
                                });
                        }
                        return response;
                    })
                    .catch(() => {
                        // For image requests, return a placeholder
                        if (event.request.destination === 'image') {
                            return caches.match('/images/placeholder-avatar.svg');
                        }
                        
                        // For other requests, just propagate the error
                        throw new Error('Network error');
                    });
            })
    );
});

// Background sync for offline form submissions
self.addEventListener('sync', event => {
    if (event.tag === 'sync-pending-actions') {
        event.waitUntil(syncPendingActions());
    }
});

// Function to sync pending actions
async function syncPendingActions() {
    try {
        // Open IndexedDB
        const db = await openDatabase();
        
        // Get all pending actions
        const pendingActions = await getAllPendingActions(db);
        
        // Process each pending action
        for (const action of pendingActions) {
            try {
                // Attempt to sync the action
                const response = await fetch('/api/sync', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(action)
                });
                
                if (response.ok) {
                    // If successful, remove the action from the pending queue
                    await deletePendingAction(db, action.id);
                }
            } catch (error) {
                console.error('Failed to sync action:', action, error);
                // Will retry on next sync event
            }
        }
    } catch (error) {
        console.error('Error in syncPendingActions:', error);
    }
}

// IndexedDB helper functions
function openDatabase() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open('ume-offline-db', 1);
        
        request.onupgradeneeded = event => {
            const db = event.target.result;
            
            // Create object stores if they don't exist
            if (!db.objectStoreNames.contains('pendingActions')) {
                db.createObjectStore('pendingActions', { keyPath: 'id', autoIncrement: true });
            }
            
            if (!db.objectStoreNames.contains('teamMembers')) {
                db.createObjectStore('teamMembers', { keyPath: 'id' });
            }
        };
        
        request.onsuccess = event => {
            resolve(event.target.result);
        };
        
        request.onerror = event => {
            reject(event.target.error);
        };
    });
}

function getAllPendingActions(db) {
    return new Promise((resolve, reject) => {
        const transaction = db.transaction(['pendingActions'], 'readonly');
        const store = transaction.objectStore('pendingActions');
        const request = store.getAll();
        
        request.onsuccess = event => {
            resolve(event.target.result);
        };
        
        request.onerror = event => {
            reject(event.target.error);
        };
    });
}

function deletePendingAction(db, id) {
    return new Promise((resolve, reject) => {
        const transaction = db.transaction(['pendingActions'], 'readwrite');
        const store = transaction.objectStore('pendingActions');
        const request = store.delete(id);
        
        request.onsuccess = event => {
            resolve();
        };
        
        request.onerror = event => {
            reject(event.target.error);
        };
    });
}
```

#### 2. Offline Page

```php
<!-- resources/views/offline.blade.php -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>You're Offline - UME Application</title>
    <link rel="stylesheet" href="/css/app.css">
</head>
<body class="bg-gray-100">
    <div class="min-h-screen flex items-center justify-center p-4">
        <div class="max-w-md w-full bg-white rounded-lg shadow-md overflow-hidden">
            <div class="p-6">
                <div class="flex justify-center">
                    <img src="/images/offline.svg" alt="Offline" class="h-32 w-32">
                </div>
                
                <h1 class="mt-6 text-xl font-bold text-center text-gray-900">You're Offline</h1>
                
                <p class="mt-2 text-center text-gray-600">
                    It looks like you've lost your internet connection. Some features may be unavailable until you're back online.
                </p>
                
                <div class="mt-6">
                    <div class="space-y-4">
                        <div class="bg-yellow-50 p-4 rounded-md">
                            <div class="flex">
                                <div class="flex-shrink-0">
                                    <svg class="h-5 w-5 text-yellow-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                                    </svg>
                                </div>
                                <div class="ml-3">
                                    <h3 class="text-sm font-medium text-yellow-800">Offline Mode</h3>
                                    <div class="mt-2 text-sm text-yellow-700">
                                        <p>
                                            You can still access previously loaded content and make changes. Your changes will be saved locally and synchronized when you're back online.
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <button id="retry-button" class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            Try Again
                        </button>
                        
                        <button id="home-button" class="w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            Go to Homepage
                        </button>
                    </div>
                </div>
            </div>
            
            <div class="px-6 py-4 bg-gray-50 border-t border-gray-200">
                <div class="text-xs text-gray-500">
                    <p>
                        Some features may be limited while offline. Your data will be synchronized when you reconnect.
                    </p>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        document.getElementById('retry-button').addEventListener('click', () => {
            window.location.reload();
        });
        
        document.getElementById('home-button').addEventListener('click', () => {
            window.location.href = '/';
        });
    </script>
</body>
</html>
```

#### 3. Local Storage for Team Member Data

```javascript
// resources/js/offline-storage.js
class OfflineStorage {
    constructor() {
        this.dbName = 'ume-offline-db';
        this.dbVersion = 1;
        this.db = null;
        
        // Initialize the database
        this.initDatabase();
    }
    
    async initDatabase() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.dbVersion);
            
            request.onupgradeneeded = event => {
                const db = event.target.result;
                
                // Create object stores if they don't exist
                if (!db.objectStoreNames.contains('teamMembers')) {
                    const teamMembersStore = db.createObjectStore('teamMembers', { keyPath: 'id' });
                    teamMembersStore.createIndex('team_id', 'team_id', { unique: false });
                }
                
                if (!db.objectStoreNames.contains('pendingActions')) {
                    db.createObjectStore('pendingActions', { keyPath: 'id', autoIncrement: true });
                }
            };
            
            request.onsuccess = event => {
                this.db = event.target.result;
                console.log('IndexedDB initialized successfully');
                resolve();
            };
            
            request.onerror = event => {
                console.error('Error initializing IndexedDB:', event.target.error);
                reject(event.target.error);
            };
        });
    }
    
    async getDatabase() {
        if (this.db) return this.db;
        
        await this.initDatabase();
        return this.db;
    }
    
    async saveTeamMembers(teamMembers) {
        const db = await this.getDatabase();
        const transaction = db.transaction(['teamMembers'], 'readwrite');
        const store = transaction.objectStore('teamMembers');
        
        // Store each team member
        for (const member of teamMembers) {
            store.put(member);
        }
        
        return new Promise((resolve, reject) => {
            transaction.oncomplete = () => {
                resolve();
            };
            
            transaction.onerror = event => {
                reject(event.target.error);
            };
        });
    }
    
    async getTeamMembers(teamId = null) {
        const db = await this.getDatabase();
        const transaction = db.transaction(['teamMembers'], 'readonly');
        const store = transaction.objectStore('teamMembers');
        
        return new Promise((resolve, reject) => {
            let request;
            
            if (teamId) {
                // Get team members for a specific team
                const index = store.index('team_id');
                request = index.getAll(teamId);
            } else {
                // Get all team members
                request = store.getAll();
            }
            
            request.onsuccess = event => {
                resolve(event.target.result);
            };
            
            request.onerror = event => {
                reject(event.target.error);
            };
        });
    }
    
    async addPendingAction(action) {
        const db = await this.getDatabase();
        const transaction = db.transaction(['pendingActions'], 'readwrite');
        const store = transaction.objectStore('pendingActions');
        
        return new Promise((resolve, reject) => {
            const request = store.add({
                type: action.type,
                data: action.data,
                timestamp: new Date().toISOString()
            });
            
            request.onsuccess = event => {
                resolve(event.target.result); // Returns the ID of the new record
            };
            
            request.onerror = event => {
                reject(event.target.error);
            };
        });
    }
    
    async getPendingActions() {
        const db = await this.getDatabase();
        const transaction = db.transaction(['pendingActions'], 'readonly');
        const store = transaction.objectStore('pendingActions');
        
        return new Promise((resolve, reject) => {
            const request = store.getAll();
            
            request.onsuccess = event => {
                resolve(event.target.result);
            };
            
            request.onerror = event => {
                reject(event.target.error);
            };
        });
    }
    
    async deletePendingAction(id) {
        const db = await this.getDatabase();
        const transaction = db.transaction(['pendingActions'], 'readwrite');
        const store = transaction.objectStore('pendingActions');
        
        return new Promise((resolve, reject) => {
            const request = store.delete(id);
            
            request.onsuccess = event => {
                resolve();
            };
            
            request.onerror = event => {
                reject(event.target.error);
            };
        });
    }
}

// Create a singleton instance
const offlineStorage = new OfflineStorage();

export default offlineStorage;
```

#### 4. Sync Mechanism for Offline Changes

```javascript
// resources/js/offline-sync.js
import offlineStorage from './offline-storage';

class OfflineSync {
    constructor() {
        this.isOnline = navigator.onLine;
        this.syncInProgress = false;
        
        // Set up event listeners for online/offline events
        window.addEventListener('online', this.handleOnline.bind(this));
        window.addEventListener('offline', this.handleOffline.bind(this));
        
        // Initial check
        if (this.isOnline) {
            this.syncPendingActions();
        }
    }
    
    handleOnline() {
        console.log('Device is now online');
        this.isOnline = true;
        
        // Dispatch custom event
        window.dispatchEvent(new CustomEvent('ume:online'));
        
        // Sync pending actions
        this.syncPendingActions();
        
        // Register background sync if supported
        if ('serviceWorker' in navigator && 'SyncManager' in window) {
            navigator.serviceWorker.ready.then(registration => {
                registration.sync.register('sync-pending-actions')
                    .catch(error => {
                        console.error('Background sync registration failed:', error);
                    });
            });
        }
    }
    
    handleOffline() {
        console.log('Device is now offline');
        this.isOnline = false;
        
        // Dispatch custom event
        window.dispatchEvent(new CustomEvent('ume:offline'));
    }
    
    async syncPendingActions() {
        if (!this.isOnline || this.syncInProgress) {
            return;
        }
        
        this.syncInProgress = true;
        
        try {
            // Get all pending actions
            const pendingActions = await offlineStorage.getPendingActions();
            
            if (pendingActions.length === 0) {
                console.log('No pending actions to sync');
                this.syncInProgress = false;
                return;
            }
            
            console.log(`Syncing ${pendingActions.length} pending actions`);
            
            // Process each pending action
            for (const action of pendingActions) {
                try {
                    // Attempt to sync the action
                    const response = await fetch('/api/sync', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                        },
                        body: JSON.stringify(action)
                    });
                    
                    if (response.ok) {
                        // If successful, remove the action from the pending queue
                        await offlineStorage.deletePendingAction(action.id);
                        console.log(`Successfully synced action ${action.id}`);
                        
                        // Dispatch event for UI updates
                        window.dispatchEvent(new CustomEvent('ume:action-synced', {
                            detail: { action }
                        }));
                    } else {
                        console.error(`Failed to sync action ${action.id}:`, await response.text());
                    }
                } catch (error) {
                    console.error(`Error syncing action ${action.id}:`, error);
                }
            }
            
            // Dispatch event when all syncing is complete
            window.dispatchEvent(new CustomEvent('ume:sync-complete'));
        } catch (error) {
            console.error('Error in syncPendingActions:', error);
        } finally {
            this.syncInProgress = false;
        }
    }
    
    async addPendingAction(type, data) {
        // Add the action to the pending queue
        const actionId = await offlineStorage.addPendingAction({
            type,
            data
        });
        
        console.log(`Added pending action ${actionId} of type ${type}`);
        
        // Dispatch event for UI updates
        window.dispatchEvent(new CustomEvent('ume:action-pending', {
            detail: { type, data, id: actionId }
        }));
        
        // Try to sync immediately if online
        if (this.isOnline) {
            this.syncPendingActions();
        }
        
        return actionId;
    }
}

// Create a singleton instance
const offlineSync = new OfflineSync();

export default offlineSync;
```

This implementation provides basic offline capabilities for a UME application:

1. A service worker caches essential assets for offline use
2. An offline page is shown when the user is offline
3. Team member data is stored locally using IndexedDB
4. A sync mechanism handles changes made offline and syncs them when the connection is restored

## Exercise 6: Responsive Images

### Multiple Choice Answers

1. Which HTML attribute is used to provide different image sources for different screen sizes?
   - **B) `srcset`**

2. What is the primary benefit of using WebP images?
   - **B) Smaller file size with similar quality**

3. Which approach is best for responsive background images?
   - **B) Use media queries to load different images**
