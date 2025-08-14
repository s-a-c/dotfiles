# Fallback Strategies

<link rel="stylesheet" href="../assets/css/styles.css">

Fallback strategies are essential for progressive enhancement, ensuring that your UME application remains functional even when certain features aren't available. This page covers various approaches to implementing effective fallbacks.

## Why Fallbacks Matter

Fallbacks ensure that:

1. Users with older browsers can still use your application
2. Your application remains functional when network conditions are poor
3. Features degrade gracefully when technologies fail
4. Core functionality is always accessible

## JavaScript Fallback Strategies

### 1. API Fallbacks

For modern JavaScript APIs, provide alternative implementations:

```javascript
// Fetch API with XMLHttpRequest fallback
function fetchData(url) {
    return new Promise((resolve, reject) => {
        if ('fetch' in window) {
            fetch(url)
                .then(response => response.json())
                .then(resolve)
                .catch(reject);
        } else {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', url);
            xhr.onload = () => {
                if (xhr.status === 200) {
                    try {
                        resolve(JSON.parse(xhr.responseText));
                    } catch (e) {
                        reject(new Error('Invalid JSON'));
                    }
                } else {
                    reject(new Error(`HTTP error ${xhr.status}`));
                }
            };
            xhr.onerror = () => reject(new Error('Network error'));
            xhr.send();
        }
    });
}
```

### 2. Polyfills

Polyfills add missing functionality to older browsers:

```javascript
// Polyfill for Array.from
if (!Array.from) {
    Array.from = function(arrayLike) {
        return [].slice.call(arrayLike);
    };
}

// Using a polyfill service
// Add this to your HTML head
<script src="https://polyfill.io/v3/polyfill.min.js?features=Array.from,Promise,fetch"></script>
```

### 3. Functional Fallbacks

Provide alternative functionality when a feature isn't available:

```javascript
// Real-time updates with WebSockets or polling fallback
class UpdateService {
    constructor() {
        this.useWebSockets = 'WebSocket' in window;
        this.initialize();
    }
    
    initialize() {
        if (this.useWebSockets) {
            this.initializeWebSockets();
        } else {
            this.initializePolling();
        }
    }
    
    initializeWebSockets() {
        this.socket = new WebSocket('wss://api.example.com/updates');
        this.socket.onmessage = (event) => {
            this.handleUpdate(JSON.parse(event.data));
        };
    }
    
    initializePolling() {
        // Poll every 30 seconds
        this.pollInterval = setInterval(() => {
            fetchData('https://api.example.com/updates')
                .then(data => this.handleUpdate(data));
        }, 30000);
    }
    
    handleUpdate(data) {
        // Common update handling logic
    }
}
```

## CSS Fallback Strategies

### 1. Multiple Property Declarations

Browsers ignore CSS properties they don't understand, so you can provide fallbacks by listing properties in order of preference:

```css
.container {
    /* Fallback for older browsers */
    display: block;
    
    /* Modern browsers will use this instead */
    display: flex;
}

.gradient-background {
    /* Solid color fallback */
    background-color: #3490dc;
    
    /* Gradient for browsers that support it */
    background-image: linear-gradient(to right, #3490dc, #6574cd);
}
```

### 2. Feature Queries with @supports

Use `@supports` to provide alternative styles:

```css
/* Base styles for all browsers */
.grid-container {
    display: block;
}

.grid-item {
    margin-bottom: 20px;
}

/* Enhanced styles for browsers with Grid support */
@supports (display: grid) {
    .grid-container {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
        gap: 20px;
    }
    
    .grid-item {
        margin-bottom: 0; /* Reset margin since we're using gap */
    }
}
```

### 3. Media Queries for Capabilities

Use media queries to target specific device capabilities:

```css
/* Base styles for all devices */
.video-container video {
    display: none;
}

.video-container .fallback-image {
    display: block;
}

/* Only show video on devices that likely support it */
@media (min-width: 768px) {
    .video-container video {
        display: block;
    }
    
    .video-container .fallback-image {
        display: none;
    }
}
```

## HTML Fallback Strategies

### 1. The `<noscript>` Tag

Provide alternative content when JavaScript is disabled:

```html
<div id="app">
    <!-- JavaScript-powered app will be rendered here -->
</div>

<noscript>
    <div class="error-message">
        <h2>JavaScript Required</h2>
        <p>This application requires JavaScript to function. Please enable JavaScript in your browser settings.</p>
        <!-- Provide alternative links or functionality -->
        <a href="/basic-version">Use Basic Version</a>
    </div>
</noscript>
```

### 2. Progressive Loading

Structure your HTML to load and display core content first:

```html
<!-- Core content loads first -->
<main>
    <h1>User Profile</h1>
    <div class="user-info">
        <!-- Essential user information -->
    </div>
</main>

<!-- Enhanced features load later -->
<script defer src="enhanced-features.js"></script>
```

### 3. Fallback Content for Media

Provide alternatives for media content:

```html
<!-- Video with fallbacks -->
<video controls>
    <source src="video.webm" type="video/webm">
    <source src="video.mp4" type="video/mp4">
    <!-- Fallback for browsers without video support -->
    <img src="video-poster.jpg" alt="Video thumbnail">
    <p>Your browser doesn't support HTML5 video. <a href="video.mp4">Download the video</a> instead.</p>
</video>

<!-- Image with fallback text -->
<img src="chart.svg" alt="Chart showing user growth over time" 
     onerror="this.onerror=null; this.src='chart.png';">
```

## Server-Side Fallback Strategies

### 1. Progressive Server Rendering

Render the core application on the server, then enhance it with JavaScript:

```php
// In your Laravel controller
public function showUserProfile(User $user)
{
    // Always render the basic HTML version
    return view('user.profile', ['user' => $user]);
    
    // JavaScript will enhance this with dynamic features
}
```

### 2. Feature Detection on the Server

Use headers or other signals to detect capabilities:

```php
public function showDashboard(Request $request)
{
    $userAgent = $request->header('User-Agent');
    $isModernBrowser = $this->detectModernBrowser($userAgent);
    
    return view('dashboard', [
        'enhancedFeatures' => $isModernBrowser,
    ]);
}
```

### 3. Content Negotiation

Serve different content based on what the client can accept:

```php
public function getUserData(Request $request, User $user)
{
    // Check what format the client prefers
    $format = $request->prefers(['json', 'html']);
    
    if ($format === 'json') {
        // Client supports JSON, return API response
        return response()->json($user->toArray());
    } else {
        // Client prefers HTML, return rendered view
        return view('user.data', ['user' => $user]);
    }
}
```

## Real-World UME Examples

### User Profile Editing

```javascript
class ProfileEditor {
    constructor(formElement) {
        this.form = formElement;
        this.setupBasicForm();
        
        // Enhanced features
        if (this.supportsFormValidation()) {
            this.setupClientValidation();
        }
        
        if (this.supportsAjax()) {
            this.setupAjaxSubmission();
        }
        
        if (this.supportsLocalStorage()) {
            this.setupAutoSave();
        }
    }
    
    // Feature detection methods
    supportsFormValidation() {
        return 'reportValidity' in HTMLFormElement.prototype;
    }
    
    supportsAjax() {
        return 'fetch' in window || 'XMLHttpRequest' in window;
    }
    
    supportsLocalStorage() {
        try {
            localStorage.setItem('test', 'test');
            localStorage.removeItem('test');
            return true;
        } catch (e) {
            return false;
        }
    }
    
    // Implementation methods...
}
```

### Team Management Interface

```javascript
// Team management with appropriate fallbacks
document.addEventListener('DOMContentLoaded', () => {
    const teamApp = {
        init() {
            // Core functionality - works for everyone
            this.setupBasicTeamManagement();
            
            // Enhanced features with fallbacks
            if ('IntersectionObserver' in window) {
                this.setupLazyLoading();
            } else {
                this.loadAllMembersImmediately();
            }
            
            if ('WebSocket' in window) {
                this.setupRealtimeUpdates();
            } else {
                this.setupPollingUpdates();
            }
            
            if (CSS.supports('display', 'grid')) {
                document.body.classList.add('grid-layout');
            } else {
                document.body.classList.add('flex-layout');
            }
        },
        
        // Implementation methods...
    };
    
    teamApp.init();
});
```

## Next Steps

Continue to [Graceful Degradation](./040-graceful-degradation.md) to learn how to ensure your application degrades gracefully when features aren't supported.
