# Mobile-Specific Features

<link rel="stylesheet" href="../assets/css/styles.css">

Mobile devices offer unique capabilities that can enhance your UME implementation. This section covers features that are specific to mobile devices and how to implement them.

## Understanding Mobile-Specific Features

Mobile devices have several capabilities that desktop computers typically don't have:

1. **Touch Input**: Multi-touch gestures, haptic feedback
2. **Sensors**: Geolocation, accelerometer, gyroscope, ambient light
3. **Native Integration**: Camera, microphone, contacts, calendar
4. **Mobile-Specific UI**: Bottom navigation, pull-to-refresh, swipe actions
5. **Platform Features**: Push notifications, home screen installation

## Implementing Mobile-Specific Features

### 1. Geolocation

Use the Geolocation API to access the user's location:

```javascript
// resources/js/geolocation.js
function getUserLocation() {
    if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
            // Success callback
            function(position) {
                const latitude = position.coords.latitude;
                const longitude = position.coords.longitude;
                
                // Send to server
                fetch('/api/update-location', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                    },
                    body: JSON.stringify({ latitude, longitude })
                });
            },
            // Error callback
            function(error) {
                console.error('Error getting location:', error.message);
            },
            // Options
            {
                enableHighAccuracy: true,
                timeout: 5000,
                maximumAge: 0
            }
        );
    } else {
        console.log('Geolocation is not supported by this browser');
    }
}
```

```php
<!-- In a Blade view -->
<div x-data="{ showNearbyTeams: false, nearbyTeams: [] }"
     x-init="
        if ('geolocation' in navigator) {
            showNearbyTeams = true;
        }
     ">
    
    <button x-show="showNearbyTeams"
            @click="
                navigator.geolocation.getCurrentPosition(position => {
                    fetch(`/api/nearby-teams?lat=${position.coords.latitude}&lng=${position.coords.longitude}`)
                        .then(response => response.json())
                        .then(data => {
                            nearbyTeams = data.teams;
                        });
                });
            "
            class="px-4 py-2 bg-indigo-600 text-white rounded-md">
        Find Nearby Teams
    </button>
    
    <div x-show="nearbyTeams.length > 0" class="mt-4">
        <h3 class="text-lg font-medium">Nearby Teams</h3>
        <ul class="mt-2 space-y-2">
            <template x-for="team in nearbyTeams" :key="team.id">
                <li class="p-2 border rounded-md">
                    <span x-text="team.name"></span>
                    <span x-text="team.distance + ' km away'" class="text-sm text-gray-500 ml-2"></span>
                </li>
            </template>
        </ul>
    </div>
</div>
```

### 2. Camera Access

Use the device camera for profile photos or document scanning:

```php
<!-- In a Blade view -->
<div x-data="{ 
        hasCamera: false, 
        cameraActive: false,
        photoTaken: false,
        photoData: null,
        
        initCamera() {
            if (!('mediaDevices' in navigator)) {
                return;
            }
            
            this.hasCamera = true;
        },
        
        async startCamera() {
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ video: true });
                this.cameraActive = true;
                
                const video = this.$refs.video;
                video.srcObject = stream;
                video.play();
            } catch (error) {
                console.error('Error accessing camera:', error);
                alert('Could not access camera. Please check permissions.');
            }
        },
        
        takePhoto() {
            const video = this.$refs.video;
            const canvas = this.$refs.canvas;
            const context = canvas.getContext('2d');
            
            // Set canvas dimensions to match video
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            
            // Draw video frame to canvas
            context.drawImage(video, 0, 0, canvas.width, canvas.height);
            
            // Get data URL
            this.photoData = canvas.toDataURL('image/jpeg');
            this.photoTaken = true;
            
            // Stop camera
            const stream = video.srcObject;
            const tracks = stream.getTracks();
            tracks.forEach(track => track.stop());
            this.cameraActive = false;
        },
        
        resetPhoto() {
            this.photoTaken = false;
            this.photoData = null;
        },
        
        async uploadPhoto() {
            if (!this.photoData) return;
            
            try {
                // Convert data URL to blob
                const response = await fetch(this.photoData);
                const blob = await response.blob();
                
                // Create form data
                const formData = new FormData();
                formData.append('avatar', blob, 'camera-photo.jpg');
                
                // Upload
                const uploadResponse = await fetch('/api/upload-avatar', {
                    method: 'POST',
                    headers: {
                        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                    },
                    body: formData
                });
                
                if (uploadResponse.ok) {
                    alert('Photo uploaded successfully!');
                    this.resetPhoto();
                } else {
                    alert('Failed to upload photo.');
                }
            } catch (error) {
                console.error('Error uploading photo:', error);
                alert('Error uploading photo.');
            }
        }
     }"
     x-init="initCamera">
    
    <div class="space-y-4">
        <div x-show="!cameraActive && !photoTaken">
            <button x-show="hasCamera" 
                    @click="startCamera" 
                    class="px-4 py-2 bg-indigo-600 text-white rounded-md">
                Take Photo
            </button>
            
            <p x-show="!hasCamera" class="text-sm text-gray-500">
                Camera access is not available on this device or browser.
            </p>
        </div>
        
        <div x-show="cameraActive" class="relative">
            <video x-ref="video" class="w-full rounded-md"></video>
            
            <button @click="takePhoto" 
                    class="absolute bottom-4 left-1/2 transform -translate-x-1/2 px-4 py-2 bg-white text-indigo-600 rounded-full shadow-md">
                <x-flux::icon name="camera" class="h-6 w-6" />
            </button>
        </div>
        
        <div x-show="photoTaken" class="space-y-4">
            <div class="relative">
                <img :src="photoData" class="w-full rounded-md">
                
                <div class="absolute bottom-4 left-0 right-0 flex justify-center space-x-4">
                    <button @click="resetPhoto" 
                            class="px-4 py-2 bg-white text-red-600 rounded-full shadow-md">
                        <x-flux::icon name="x" class="h-6 w-6" />
                    </button>
                    
                    <button @click="uploadPhoto" 
                            class="px-4 py-2 bg-white text-green-600 rounded-full shadow-md">
                        <x-flux::icon name="check" class="h-6 w-6" />
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <canvas x-ref="canvas" class="hidden"></canvas>
</div>
```

### 3. Push Notifications

Implement push notifications for real-time updates:

```php
// routes/web.php
Route::post('/enable-push-notifications', [NotificationController::class, 'enablePushNotifications'])
    ->middleware(['auth']);

// app/Http/Controllers/NotificationController.php
public function enablePushNotifications(Request $request)
{
    $request->validate([
        'endpoint' => 'required|url',
        'keys.p256dh' => 'required|string',
        'keys.auth' => 'required|string',
    ]);
    
    $subscription = PushSubscription::updateOrCreate(
        [
            'user_id' => $request->user()->id,
            'endpoint' => $request->endpoint,
        ],
        [
            'public_key' => $request->keys['p256dh'],
            'auth_token' => $request->keys['auth'],
        ]
    );
    
    return response()->json(['success' => true]);
}
```

```javascript
// resources/js/push-notifications.js
async function registerPushNotifications() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        console.log('Push notifications not supported');
        return;
    }
    
    try {
        // Register service worker
        const registration = await navigator.serviceWorker.register('/service-worker.js');
        
        // Request permission
        const permission = await Notification.requestPermission();
        if (permission !== 'granted') {
            console.log('Notification permission denied');
            return;
        }
        
        // Subscribe to push notifications
        const subscription = await registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: urlBase64ToUint8Array('YOUR_PUBLIC_VAPID_KEY')
        });
        
        // Send subscription to server
        await fetch('/enable-push-notifications', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify(subscription)
        });
        
        console.log('Push notification subscription successful');
    } catch (error) {
        console.error('Error registering push notifications:', error);
    }
}

// Helper function to convert base64 to Uint8Array
function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
        .replace(/-/g, '+')
        .replace(/_/g, '/');
    
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    
    for (let i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i);
    }
    
    return outputArray;
}
```

```php
<!-- In a Blade view -->
<div x-data="{ 
        pushSupported: false,
        pushEnabled: false,
        
        init() {
            this.pushSupported = 'serviceWorker' in navigator && 'PushManager' in window;
            
            if (this.pushSupported) {
                this.checkPushEnabled();
            }
        },
        
        async checkPushEnabled() {
            const registration = await navigator.serviceWorker.ready;
            const subscription = await registration.pushManager.getSubscription();
            this.pushEnabled = !!subscription;
        },
        
        async togglePushNotifications() {
            if (this.pushEnabled) {
                // Unsubscribe
                const registration = await navigator.serviceWorker.ready;
                const subscription = await registration.pushManager.getSubscription();
                
                if (subscription) {
                    await subscription.unsubscribe();
                    
                    // Notify server
                    await fetch('/disable-push-notifications', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                        }
                    });
                }
                
                this.pushEnabled = false;
            } else {
                // Subscribe
                await registerPushNotifications();
                this.pushEnabled = true;
            }
        }
     }"
     x-init="init"
     class="mt-6">
    
    <h3 class="text-lg font-medium">Push Notifications</h3>
    
    <div x-show="!pushSupported" class="mt-2 text-sm text-gray-500">
        Push notifications are not supported in your browser.
    </div>
    
    <div x-show="pushSupported" class="mt-2">
        <button @click="togglePushNotifications" 
                class="px-4 py-2 rounded-md"
                :class="pushEnabled ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'">
            <span x-text="pushEnabled ? 'Disable Push Notifications' : 'Enable Push Notifications'"></span>
        </button>
        
        <p x-show="pushEnabled" class="mt-2 text-sm text-gray-500">
            You will receive notifications for team invitations, messages, and important updates.
        </p>
    </div>
</div>
```

### 4. Device Orientation

Use the device orientation for interactive features:

```javascript
// resources/js/orientation.js
function setupOrientationFeatures() {
    if ('DeviceOrientationEvent' in window) {
        // Check if permission is needed (iOS 13+)
        if (typeof DeviceOrientationEvent.requestPermission === 'function') {
            // iOS 13+ requires user interaction to request permission
            document.getElementById('enable-orientation').addEventListener('click', async () => {
                try {
                    const permission = await DeviceOrientationEvent.requestPermission();
                    if (permission === 'granted') {
                        window.addEventListener('deviceorientation', handleOrientation);
                    }
                } catch (error) {
                    console.error('Error requesting device orientation permission:', error);
                }
            });
        } else {
            // No permission needed
            window.addEventListener('deviceorientation', handleOrientation);
        }
    }
}

function handleOrientation(event) {
    const alpha = event.alpha; // Z-axis rotation [0, 360)
    const beta = event.beta;   // X-axis rotation [-180, 180]
    const gamma = event.gamma; // Y-axis rotation [-90, 90]
    
    // Use orientation data for interactive features
    // For example, rotate an element based on device orientation
    const element = document.getElementById('orientation-element');
    if (element) {
        element.style.transform = `rotateZ(${alpha}deg) rotateX(${beta}deg) rotateY(${gamma}deg)`;
    }
}
```

```php
<!-- In a Blade view -->
<div x-data="{ 
        orientationSupported: false,
        orientationEnabled: false,
        
        init() {
            this.orientationSupported = 'DeviceOrientationEvent' in window;
        },
        
        async enableOrientation() {
            if (typeof DeviceOrientationEvent.requestPermission === 'function') {
                try {
                    const permission = await DeviceOrientationEvent.requestPermission();
                    this.orientationEnabled = permission === 'granted';
                } catch (error) {
                    console.error('Error requesting orientation permission:', error);
                }
            } else {
                this.orientationEnabled = true;
                window.addEventListener('deviceorientation', this.handleOrientation);
            }
        },
        
        handleOrientation(event) {
            // Implementation here
        }
     }"
     x-init="init"
     class="mt-6">
    
    <h3 class="text-lg font-medium">Interactive Orientation Features</h3>
    
    <div x-show="!orientationSupported" class="mt-2 text-sm text-gray-500">
        Device orientation is not supported in your browser.
    </div>
    
    <div x-show="orientationSupported && !orientationEnabled" class="mt-2">
        <button @click="enableOrientation" 
                class="px-4 py-2 bg-indigo-600 text-white rounded-md">
            Enable Orientation Features
        </button>
    </div>
    
    <div x-show="orientationEnabled" class="mt-4">
        <div id="orientation-element" class="w-32 h-32 bg-indigo-500 rounded-md mx-auto">
            <!-- This element will rotate based on device orientation -->
        </div>
    </div>
</div>
```

### 5. Mobile-Specific UI Patterns

#### Bottom Navigation

```php
<!-- resources/views/components/mobile-bottom-nav.blade.php -->
<div class="fixed bottom-0 inset-x-0 bg-white border-t md:hidden">
    <div class="flex justify-around">
        <a href="{{ route('dashboard') }}" class="flex flex-col items-center py-2 {{ request()->routeIs('dashboard') ? 'text-indigo-600' : 'text-gray-500' }}">
            <x-flux::icon name="home" class="h-6 w-6" />
            <span class="text-xs mt-1">Home</span>
        </a>
        
        <a href="{{ route('teams.index') }}" class="flex flex-col items-center py-2 {{ request()->routeIs('teams.*') ? 'text-indigo-600' : 'text-gray-500' }}">
            <x-flux::icon name="users" class="h-6 w-6" />
            <span class="text-xs mt-1">Teams</span>
        </a>
        
        <a href="{{ route('messages') }}" class="flex flex-col items-center py-2 {{ request()->routeIs('messages') ? 'text-indigo-600' : 'text-gray-500' }}">
            <x-flux::icon name="chat" class="h-6 w-6" />
            <span class="text-xs mt-1">Messages</span>
        </a>
        
        <a href="{{ route('profile.show') }}" class="flex flex-col items-center py-2 {{ request()->routeIs('profile.*') ? 'text-indigo-600' : 'text-gray-500' }}">
            <x-flux::icon name="user" class="h-6 w-6" />
            <span class="text-xs mt-1">Profile</span>
        </a>
    </div>
</div>

<!-- Add padding to main content to prevent overlap -->
<div class="pb-16 md:pb-0">
    {{ $slot }}
</div>
```

#### Pull-to-Refresh

```php
<!-- In a Blade view -->
<div x-data="{ 
        refreshing: false,
        startY: 0,
        currentY: 0,
        threshold: 80,
        
        init() {
            this.$el.addEventListener('touchstart', this.touchStart.bind(this), { passive: true });
            this.$el.addEventListener('touchmove', this.touchMove.bind(this), { passive: true });
            this.$el.addEventListener('touchend', this.touchEnd.bind(this), { passive: true });
        },
        
        touchStart(event) {
            // Only enable pull-to-refresh when at the top of the page
            if (window.scrollY === 0) {
                this.startY = event.touches[0].clientY;
            }
        },
        
        touchMove(event) {
            if (this.startY > 0) {
                this.currentY = event.touches[0].clientY;
            }
        },
        
        touchEnd() {
            if (this.startY > 0 && this.currentY > 0 && this.currentY - this.startY > this.threshold) {
                this.refresh();
            }
            
            this.startY = 0;
            this.currentY = 0;
        },
        
        async refresh() {
            if (this.refreshing) return;
            
            this.refreshing = true;
            
            try {
                // Fetch new data
                const response = await fetch('/api/teams', {
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                });
                
                const data = await response.json();
                
                // Update the UI with new data
                this.$dispatch('teams-updated', data.teams);
            } catch (error) {
                console.error('Error refreshing data:', error);
            } finally {
                this.refreshing = false;
            }
        }
     }"
     class="relative min-h-screen">
    
    <!-- Pull-to-refresh indicator -->
    <div x-show="currentY - startY > 0" 
         :style="`height: ${Math.min(currentY - startY, threshold)}px`"
         class="flex items-center justify-center overflow-hidden transition-all duration-200">
        <div class="text-center">
            <x-flux::icon name="arrow-path" class="h-6 w-6 mx-auto" :class="currentY - startY > threshold ? 'text-indigo-600' : 'text-gray-400'" />
            <span x-show="currentY - startY > threshold" class="text-sm text-indigo-600">Release to refresh</span>
            <span x-show="currentY - startY <= threshold" class="text-sm text-gray-400">Pull down to refresh</span>
        </div>
    </div>
    
    <!-- Loading indicator -->
    <div x-show="refreshing" class="absolute top-0 left-0 right-0 flex justify-center p-4 bg-white">
        <x-flux::spinner class="h-6 w-6 text-indigo-600" />
    </div>
    
    <!-- Content -->
    <div>
        <!-- Your content here -->
    </div>
</div>
```

#### Swipe Actions

```php
<!-- In a Blade view -->
<div x-data="{ 
        items: [],
        swipeState: {},
        
        init() {
            // Initialize with some data
            this.items = [
                { id: 1, name: 'Team Alpha' },
                { id: 2, name: 'Team Beta' },
                { id: 3, name: 'Team Gamma' }
            ];
            
            // Initialize swipe state for each item
            this.items.forEach(item => {
                this.swipeState[item.id] = {
                    startX: 0,
                    currentX: 0,
                    open: false
                };
            });
        },
        
        touchStart(id, event) {
            this.swipeState[id].startX = event.touches[0].clientX;
        },
        
        touchMove(id, event) {
            this.swipeState[id].currentX = event.touches[0].clientX;
        },
        
        touchEnd(id) {
            const state = this.swipeState[id];
            const diff = state.startX - state.currentX;
            
            // If swiped left more than 50px, open actions
            if (diff > 50) {
                state.open = true;
            }
            // If swiped right more than 50px, close actions
            else if (diff < -50) {
                state.open = false;
            }
            
            state.startX = 0;
            state.currentX = 0;
        },
        
        deleteItem(id) {
            this.items = this.items.filter(item => item.id !== id);
            delete this.swipeState[id];
        }
     }"
     class="space-y-4">
    
    <template x-for="item in items" :key="item.id">
        <div class="relative overflow-hidden rounded-md border">
            <!-- Item content -->
            <div class="bg-white p-4"
                 @touchstart="touchStart(item.id, $event)"
                 @touchmove="touchMove(item.id, $event)"
                 @touchend="touchEnd(item.id)"
                 :style="swipeState[item.id].open ? 'transform: translateX(-100px);' : ''"
                 class="transition-transform duration-200">
                <h3 x-text="item.name" class="font-medium"></h3>
            </div>
            
            <!-- Swipe actions -->
            <div class="absolute inset-y-0 right-0 flex">
                <button @click="deleteItem(item.id)" 
                        class="w-[100px] bg-red-500 text-white flex items-center justify-center">
                    <x-flux::icon name="trash" class="h-5 w-5" />
                </button>
            </div>
        </div>
    </template>
</div>
```

## Progressive Web App (PWA) Features

### 1. Web App Manifest

Create a manifest file to enable home screen installation:

```json
// public/manifest.json
{
    "name": "UME Application",
    "short_name": "UME",
    "description": "User Model Enhancements Application",
    "start_url": "/",
    "display": "standalone",
    "background_color": "#ffffff",
    "theme_color": "#4f46e5",
    "icons": [
        {
            "src": "/icons/icon-192x192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "/icons/icon-512x512.png",
            "sizes": "512x512",
            "type": "image/png"
        }
    ]
}
```

```html
<!-- In your layout file -->
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#4f46e5">
<link rel="apple-touch-icon" href="/icons/icon-192x192.png">
```

### 2. Install Prompt

Show a prompt to install the app:

```php
<!-- In a Blade view -->
<div x-data="{ 
        showInstallPrompt: false,
        deferredPrompt: null,
        
        init() {
            window.addEventListener('beforeinstallprompt', (event) => {
                // Prevent the default prompt
                event.preventDefault();
                
                // Store the event for later use
                this.deferredPrompt = event;
                
                // Show our custom install button
                this.showInstallPrompt = true;
            });
        },
        
        async installApp() {
            if (!this.deferredPrompt) return;
            
            // Show the installation prompt
            this.deferredPrompt.prompt();
            
            // Wait for the user's choice
            const choiceResult = await this.deferredPrompt.userChoice;
            
            // Reset the deferred prompt
            this.deferredPrompt = null;
            this.showInstallPrompt = false;
            
            // Log the result
            if (choiceResult.outcome === 'accepted') {
                console.log('User accepted the install prompt');
            } else {
                console.log('User dismissed the install prompt');
            }
        }
     }"
     x-init="init"
     x-show="showInstallPrompt"
     class="fixed bottom-16 inset-x-0 p-4 bg-white border-t shadow-lg md:bottom-0">
    
    <div class="flex items-center justify-between">
        <div>
            <h3 class="font-medium">Install UME App</h3>
            <p class="text-sm text-gray-500">Add to your home screen for quick access</p>
        </div>
        
        <div class="flex space-x-2">
            <button @click="showInstallPrompt = false" 
                    class="px-3 py-1 border rounded-md text-gray-700">
                Not Now
            </button>
            
            <button @click="installApp" 
                    class="px-3 py-1 bg-indigo-600 text-white rounded-md">
                Install
            </button>
        </div>
    </div>
</div>
```

## Testing Mobile-Specific Features

### 1. Device Testing

- Test on actual mobile devices, not just emulators
- Test on different operating systems (iOS, Android)
- Test on different browsers (Safari, Chrome, Firefox)

### 2. Feature Detection

Always use feature detection before using mobile-specific features:

```javascript
// Check for geolocation support
if ('geolocation' in navigator) {
    // Geolocation is supported
}

// Check for camera support
if ('mediaDevices' in navigator && 'getUserMedia' in navigator.mediaDevices) {
    // Camera is supported
}

// Check for push notification support
if ('serviceWorker' in navigator && 'PushManager' in window) {
    // Push notifications are supported
}

// Check for device orientation support
if ('DeviceOrientationEvent' in window) {
    // Device orientation is supported
}
```

### 3. Graceful Degradation

Provide fallbacks for devices that don't support specific features:

```php
<!-- In a Blade view -->
<div x-data="{ hasCamera: 'mediaDevices' in navigator }">
    <div x-show="hasCamera">
        <!-- Camera-based avatar upload -->
    </div>
    
    <div x-show="!hasCamera">
        <!-- Traditional file upload -->
        <x-flux::input-group type="file" label="Upload Avatar" wire:model="avatar" />
    </div>
</div>
```

## Best Practices for Mobile-Specific Features

1. **Use Feature Detection**: Always check if a feature is supported before using it
2. **Provide Fallbacks**: Offer alternatives for devices that don't support specific features
3. **Request Permissions Thoughtfully**: Only request permissions when necessary and explain why
4. **Optimize for Battery Life**: Mobile-specific features can drain battery quickly
5. **Test on Real Devices**: Emulators don't always accurately represent mobile behavior

## Next Steps

Continue to [Device Testing Matrix](./090-device-testing-matrix.md) to learn how to test your UME implementation across different devices.
