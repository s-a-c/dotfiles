# Feature Detection

<link rel="stylesheet" href="../assets/css/styles.css">

Feature detection is a key component of progressive enhancement that allows your UME application to determine which browser features are available and provide appropriate experiences based on those capabilities.

## Understanding Feature Detection

Feature detection involves testing whether a browser supports a specific feature before using it. This approach is more reliable than browser detection (checking which browser the user is using) because:

1. Browser detection can be spoofed or inaccurate
2. Browser versions don't consistently support the same features
3. New browser versions may add support for features
4. Different browsers may implement features differently

## Basic Feature Detection Techniques

### 1. Object and Property Checks

The simplest form of feature detection is checking if an object or property exists:

```javascript
// Check if the Fetch API is available
if ('fetch' in window) {
    // Use fetch
} else {
    // Use XMLHttpRequest as fallback
}

// Check if localStorage is available
if (typeof window.localStorage !== 'undefined') {
    // Use localStorage
} else {
    // Use cookies or other fallback
}
```

### 2. Method Checks

Check if a specific method is available:

```javascript
// Check if Array.prototype.includes is available
if (Array.prototype.includes) {
    const result = [1, 2, 3].includes(2);
} else {
    // Use indexOf as fallback
    const result = [1, 2, 3].indexOf(2) !== -1;
}
```

### 3. Feature Testing

Sometimes you need to test if a feature works as expected, not just if it exists:

```javascript
// Test if CSS Grid is supported
function isGridSupported() {
    const el = document.createElement('div');
    return typeof el.style.grid !== 'undefined';
}

// More thorough test for localStorage
function isLocalStorageAvailable() {
    try {
        const test = 'test';
        localStorage.setItem(test, test);
        localStorage.removeItem(test);
        return true;
    } catch (e) {
        return false;
    }
}
```

## Advanced Feature Detection

### Using Feature Detection Libraries

For comprehensive feature detection, consider using libraries like Modernizr:

```javascript
// With Modernizr
if (Modernizr.flexbox) {
    // Use flexbox layout
} else {
    // Use fallback layout
}

if (Modernizr.websockets) {
    // Use WebSockets for real-time features
} else {
    // Use long polling as fallback
}
```

### CSS Feature Detection with @supports

CSS provides the `@supports` rule for feature detection:

```css
/* Basic support check */
@supports (display: grid) {
    .container {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: 20px;
    }
}

/* Fallback for browsers without grid support */
@supports not (display: grid) {
    .container {
        display: flex;
        flex-wrap: wrap;
    }
    
    .item {
        width: calc(33% - 20px);
        margin: 10px;
    }
}

/* Combining multiple checks */
@supports (display: flex) and (position: sticky) {
    .advanced-layout {
        /* Styles that require both flexbox and sticky positioning */
    }
}
```

## Feature Detection in UME Applications

### Common Features to Detect in UME

1. **Modern JavaScript APIs**:
   - Fetch API for AJAX requests
   - Promise and async/await for asynchronous code
   - IntersectionObserver for lazy loading
   - Web Components for custom elements

2. **Storage APIs**:
   - localStorage/sessionStorage for client-side storage
   - IndexedDB for more complex data storage

3. **Real-time Features**:
   - WebSockets for real-time communication
   - Server-Sent Events for server-to-client updates

4. **Modern CSS Features**:
   - CSS Grid and Flexbox for layouts
   - CSS Variables for theming
   - CSS Animations and Transitions

### Implementation Example

Here's how to implement feature detection for a UME chat feature:

```javascript
class ChatFeature {
    constructor() {
        this.supportsWebSockets = 'WebSocket' in window;
        this.supportsLocalStorage = this.checkLocalStorage();
        this.supportsNotifications = 'Notification' in window;
        
        this.initialize();
    }
    
    checkLocalStorage() {
        try {
            const test = 'test';
            localStorage.setItem(test, test);
            localStorage.removeItem(test);
            return true;
        } catch (e) {
            return false;
        }
    }
    
    initialize() {
        // Base functionality - works for everyone
        this.setupBasicChat();
        
        // Enhanced functionality - only for supported browsers
        if (this.supportsWebSockets) {
            this.setupRealtimeChat();
        } else {
            this.setupPollingChat();
        }
        
        if (this.supportsLocalStorage) {
            this.setupOfflineSupport();
        }
        
        if (this.supportsNotifications) {
            this.setupNotifications();
        }
    }
    
    // Implementation methods...
}
```

## Feature Detection Best Practices

1. **Test for Specific Features**: Test for the exact features you need, not broad categories
2. **Provide Meaningful Fallbacks**: Ensure users without certain features still get a good experience
3. **Cache Detection Results**: Don't repeatedly test for the same feature
4. **Test Thoroughly**: Some features may exist but be buggy in certain browsers
5. **Consider Polyfills**: For critical features, consider using polyfills to add support

## Next Steps

Continue to [Fallback Strategies](./030-fallback-strategies.md) to learn how to provide alternatives when modern features aren't available.
