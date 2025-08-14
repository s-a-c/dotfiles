# Performance Implications

<link rel="stylesheet" href="../assets/css/styles.css">

Progressive enhancement has significant implications for the performance of your UME application. When implemented correctly, it can improve perceived performance and ensure your application works well across different devices and network conditions.

## Performance Benefits of Progressive Enhancement

### 1. Faster Initial Load

By focusing on core content first, progressive enhancement can improve initial load times:

- **HTML-first approach** delivers content quickly
- **Critical CSS** can be inlined for faster rendering
- **Non-essential JavaScript** can be deferred or loaded on demand
- **Core functionality** is available before all resources load

### 2. Better Perceived Performance

Progressive enhancement improves perceived performance by:

- **Showing content early**, even if all features aren't ready
- **Providing feedback** during loading and processing
- **Prioritizing visible content** over background functionality
- **Incrementally enhancing** the experience as resources become available

### 3. Resilience to Network Issues

Applications built with progressive enhancement are more resilient to network issues:

- **Core functionality works** even with partial resource loading
- **Offline capabilities** can be added as an enhancement
- **Reduced dependency** on large JavaScript libraries
- **Graceful handling** of failed resource loads

## Performance Considerations

### 1. Resource Loading Strategies

Optimize how resources are loaded:

```html
<!-- Critical CSS inlined in head -->
<style>
    /* Critical styles for above-the-fold content */
    body { font-family: system-ui, sans-serif; margin: 0; padding: 0; }
    .header { padding: 1rem; background: #f3f4f6; }
    .main-content { padding: 1rem; }
</style>

<!-- Non-critical CSS loaded asynchronously -->
<link rel="preload" href="/css/styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="/css/styles.css"></noscript>

<!-- Core functionality JavaScript -->
<script src="/js/core.js"></script>

<!-- Enhanced functionality loaded after page load -->
<script defer src="/js/enhanced.js"></script>

<!-- Non-essential functionality loaded on demand -->
<script>
    // Load feature when needed
    function loadFeature() {
        const script = document.createElement('script');
        script.src = '/js/feature.js';
        document.head.appendChild(script);
    }
    
    // Example: Load on user interaction
    document.getElementById('feature-button').addEventListener('click', loadFeature);
</script>
```

### 2. Progressive Loading Patterns

Implement progressive loading patterns:

```javascript
// Progressive loading with Intersection Observer
document.addEventListener('DOMContentLoaded', () => {
    // Check if IntersectionObserver is supported
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    const src = img.dataset.src;
                    
                    if (src) {
                        img.src = src;
                        img.removeAttribute('data-src');
                    }
                    
                    observer.unobserve(img);
                }
            });
        });
        
        // Observe all images with data-src attribute
        document.querySelectorAll('img[data-src]').forEach(img => {
            imageObserver.observe(img);
        });
    } else {
        // Fallback for browsers without IntersectionObserver
        document.querySelectorAll('img[data-src]').forEach(img => {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
        });
    }
});
```

### 3. Conditional Loading

Load resources conditionally based on device capabilities:

```javascript
// Conditional loading based on device capabilities
function loadAppropriateResources() {
    // Check device memory (if available)
    const deviceMemory = navigator.deviceMemory || 4; // Default to mid-range
    
    // Check connection type (if available)
    const connection = navigator.connection || navigator.mozConnection || 
                       navigator.webkitConnection;
    const connectionType = connection ? connection.effectiveType : '4g'; // Default to fast
    
    // Load appropriate resources
    if (deviceMemory <= 2 || ['slow-2g', '2g', '3g'].includes(connectionType)) {
        // Low-end device or slow connection
        loadLightweightResources();
    } else {
        // High-end device with good connection
        loadFullExperience();
    }
}

function loadLightweightResources() {
    // Load minimal CSS
    loadCSS('/css/minimal.css');
    
    // Load core JavaScript only
    loadScript('/js/core.js');
}

function loadFullExperience() {
    // Load complete CSS
    loadCSS('/css/styles.css');
    
    // Load all JavaScript
    loadScript('/js/core.js');
    loadScript('/js/enhanced.js');
    
    // Load high-quality images
    upgradeImages();
}
```

## Performance Measurement

### 1. Core Web Vitals

Measure Core Web Vitals to assess user experience:

- **Largest Contentful Paint (LCP)**: Measures loading performance
- **First Input Delay (FID)**: Measures interactivity
- **Cumulative Layout Shift (CLS)**: Measures visual stability

```javascript
// Report Core Web Vitals to your analytics
import {getLCP, getFID, getCLS} from 'web-vitals';

function sendToAnalytics({name, delta, id}) {
    // Send metrics to your analytics service
    console.log(`Metric: ${name} | Value: ${delta} | ID: ${id}`);
}

// Monitor Core Web Vitals
getLCP(sendToAnalytics);
getFID(sendToAnalytics);
getCLS(sendToAnalytics);
```

### 2. Performance Timeline

Use the Performance API to measure specific operations:

```javascript
// Measure performance of specific operations
function measureOperation(operationName, operation) {
    // Start measurement
    performance.mark(`${operationName}-start`);
    
    // Perform operation
    operation();
    
    // End measurement
    performance.mark(`${operationName}-end`);
    performance.measure(
        operationName,
        `${operationName}-start`,
        `${operationName}-end`
    );
    
    // Log results
    const measurements = performance.getEntriesByName(operationName);
    console.log(`${operationName} took ${measurements[0].duration.toFixed(2)}ms`);
}

// Example usage
measureOperation('data-processing', () => {
    // Process data
    const result = processLargeDataSet(data);
    updateUI(result);
});
```

### 3. Real User Monitoring (RUM)

Implement RUM to collect performance data from actual users:

```javascript
// Simple Real User Monitoring implementation
class PerformanceMonitor {
    constructor() {
        this.metrics = {
            pageLoad: 0,
            firstContentfulPaint: 0,
            timeToInteractive: 0,
            resourceLoadTimes: {},
            userTiming: {}
        };
        
        this.initializeMonitoring();
    }
    
    initializeMonitoring() {
        // Listen for load event
        window.addEventListener('load', () => {
            this.collectNavigationTiming();
            this.collectPaintTiming();
            this.collectResourceTiming();
            
            // Send metrics after a short delay to include post-load metrics
            setTimeout(() => this.sendMetrics(), 1000);
        });
        
        // Listen for user interactions
        this.monitorUserInteractions();
    }
    
    collectNavigationTiming() {
        const navigation = performance.getEntriesByType('navigation')[0];
        if (navigation) {
            this.metrics.pageLoad = navigation.loadEventEnd - navigation.startTime;
        }
    }
    
    collectPaintTiming() {
        const paintEntries = performance.getEntriesByType('paint');
        paintEntries.forEach(entry => {
            if (entry.name === 'first-contentful-paint') {
                this.metrics.firstContentfulPaint = entry.startTime;
            }
        });
    }
    
    collectResourceTiming() {
        const resources = performance.getEntriesByType('resource');
        resources.forEach(resource => {
            this.metrics.resourceLoadTimes[resource.name] = {
                duration: resource.duration,
                size: resource.transferSize,
                type: resource.initiatorType
            };
        });
    }
    
    monitorUserInteractions() {
        // Track time to first interaction
        let firstInteractionRecorded = false;
        
        const recordInteraction = () => {
            if (!firstInteractionRecorded) {
                firstInteractionRecorded = true;
                this.metrics.timeToInteractive = performance.now();
                
                // Send this important metric immediately
                this.sendMetric('timeToInteractive', this.metrics.timeToInteractive);
            }
        };
        
        // Listen for user interactions
        ['click', 'keydown', 'scroll', 'touchstart'].forEach(eventType => {
            window.addEventListener(eventType, recordInteraction, { once: true });
        });
    }
    
    // Record custom timing
    recordTiming(name, duration) {
        this.metrics.userTiming[name] = duration;
        
        // Send important metrics immediately
        if (name.includes('critical')) {
            this.sendMetric(name, duration);
        }
    }
    
    sendMetrics() {
        // Send metrics to analytics server
        const payload = {
            url: window.location.href,
            timestamp: new Date().toISOString(),
            metrics: this.metrics,
            userAgent: navigator.userAgent,
            connection: navigator.connection ? {
                effectiveType: navigator.connection.effectiveType,
                rtt: navigator.connection.rtt,
                downlink: navigator.connection.downlink
            } : null
        };
        
        // Send using Beacon API if available (doesn't block page unload)
        if (navigator.sendBeacon) {
            navigator.sendBeacon('/analytics/performance', JSON.stringify(payload));
        } else {
            // Fallback to fetch
            fetch('/analytics/performance', {
                method: 'POST',
                body: JSON.stringify(payload),
                keepalive: true
            }).catch(error => console.error('Error sending metrics:', error));
        }
    }
    
    sendMetric(name, value) {
        // Send a single metric immediately
        const payload = {
            url: window.location.href,
            timestamp: new Date().toISOString(),
            name: name,
            value: value
        };
        
        fetch('/analytics/metric', {
            method: 'POST',
            body: JSON.stringify(payload),
            keepalive: true
        }).catch(error => console.error('Error sending metric:', error));
    }
}

// Initialize performance monitoring
const performanceMonitor = new PerformanceMonitor();

// Record custom timing
function someImportantOperation() {
    const startTime = performance.now();
    
    // Perform operation
    // ...
    
    const duration = performance.now() - startTime;
    performanceMonitor.recordTiming('criticalOperation', duration);
}
```

## Performance Optimization Techniques

### 1. Code Splitting

Split your JavaScript code to load only what's needed:

```javascript
// Modern approach with dynamic imports
document.getElementById('team-button').addEventListener('click', async () => {
    try {
        // Load team management module on demand
        const { TeamManager } = await import('./team-manager.js');
        
        // Initialize with loaded module
        const teamManager = new TeamManager();
        teamManager.initialize();
    } catch (error) {
        console.error('Failed to load team management:', error);
        
        // Fallback to basic functionality
        window.location.href = '/teams';
    }
});
```

### 2. Critical CSS

Inline critical CSS and load the rest asynchronously:

```html
<head>
    <!-- Inline critical CSS -->
    <style>
        /* Critical styles for above-the-fold content */
        body { font-family: system-ui, sans-serif; margin: 0; padding: 0; }
        .header { padding: 1rem; background: #f3f4f6; }
        .hero { height: 50vh; display: flex; align-items: center; justify-content: center; }
        .hero h1 { font-size: 2.5rem; color: #1f2937; }
    </style>
    
    <!-- Load non-critical CSS asynchronously -->
    <link rel="preload" href="/css/styles.css" as="style" 
          onload="this.onload=null;this.rel='stylesheet'">
    <noscript><link rel="stylesheet" href="/css/styles.css"></noscript>
</head>
```

### 3. Lazy Loading

Implement lazy loading for images and other content:

```html
<!-- Lazy loading images -->
<img src="placeholder.jpg" 
     data-src="actual-image.jpg" 
     alt="Description" 
     loading="lazy" 
     class="lazy-image">

<!-- Lazy loading with JavaScript fallback -->
<script>
    document.addEventListener('DOMContentLoaded', () => {
        // Check if native lazy loading is supported
        if ('loading' in HTMLImageElement.prototype) {
            // Use native lazy loading
            document.querySelectorAll('img.lazy-image').forEach(img => {
                img.src = img.dataset.src;
            });
        } else {
            // Use IntersectionObserver as fallback
            if ('IntersectionObserver' in window) {
                const imageObserver = new IntersectionObserver((entries, observer) => {
                    entries.forEach(entry => {
                        if (entry.isIntersecting) {
                            const img = entry.target;
                            img.src = img.dataset.src;
                            img.classList.remove('lazy-image');
                            observer.unobserve(img);
                        }
                    });
                });
                
                document.querySelectorAll('img.lazy-image').forEach(img => {
                    imageObserver.observe(img);
                });
            } else {
                // Fallback for older browsers
                // Load all images immediately
                document.querySelectorAll('img.lazy-image').forEach(img => {
                    img.src = img.dataset.src;
                });
            }
        }
    });
</script>
```

## Performance Patterns for UME Features

### 1. User Authentication

Optimize authentication performance:

```javascript
class AuthService {
    constructor() {
        this.authState = this.getInitialAuthState();
        this.authListeners = [];
        
        // Check for stored credentials on startup
        this.checkStoredCredentials();
    }
    
    getInitialAuthState() {
        // Start with a loading state
        return { status: 'loading', user: null };
    }
    
    async checkStoredCredentials() {
        try {
            // Check for stored token
            const token = this.getStoredToken();
            
            if (token) {
                // Show content with loading state
                this.updateAuthState({ status: 'loading', user: null });
                
                // Verify token in background
                const user = await this.verifyToken(token);
                
                // Update with authenticated state
                this.updateAuthState({ status: 'authenticated', user });
            } else {
                // No stored credentials
                this.updateAuthState({ status: 'unauthenticated', user: null });
            }
        } catch (error) {
            console.error('Auth error:', error);
            
            // Authentication failed
            this.updateAuthState({ status: 'unauthenticated', user: null });
            this.clearStoredToken();
        }
    }
    
    getStoredToken() {
        // Try localStorage first
        if (window.localStorage) {
            try {
                return localStorage.getItem('auth_token');
            } catch (e) {
                // localStorage might be disabled
            }
        }
        
        // Fall back to cookies
        return this.getTokenFromCookie();
    }
    
    // Other methods...
}
```

### 2. Team Management

Optimize team management performance:

```javascript
class TeamManager {
    constructor() {
        this.teams = [];
        this.loadingState = 'initial';
        this.useRealtime = 'WebSocket' in window;
    }
    
    async initialize() {
        // Start with cached data if available
        this.loadCachedTeams();
        
        // Then load fresh data
        await this.loadTeams();
        
        // Set up real-time updates if supported
        if (this.useRealtime) {
            this.setupRealtimeUpdates();
        } else {
            // Fall back to polling
            this.setupPolling();
        }
    }
    
    loadCachedTeams() {
        try {
            const cachedData = localStorage.getItem('teams_cache');
            if (cachedData) {
                const { teams, timestamp } = JSON.parse(cachedData);
                
                // Only use cache if it's recent (less than 5 minutes old)
                const fiveMinutesAgo = Date.now() - (5 * 60 * 1000);
                if (timestamp > fiveMinutesAgo) {
                    this.teams = teams;
                    this.loadingState = 'cached';
                    this.renderTeams();
                }
            }
        } catch (e) {
            console.error('Error loading cached teams:', e);
        }
    }
    
    async loadTeams() {
        try {
            this.loadingState = 'loading';
            
            // Show loading UI if we don't have cached data
            if (this.teams.length === 0) {
                this.renderLoadingState();
            }
            
            // Fetch teams from API
            const response = await fetch('/api/teams');
            const teams = await response.json();
            
            this.teams = teams;
            this.loadingState = 'loaded';
            
            // Update UI
            this.renderTeams();
            
            // Cache the result
            this.cacheTeams();
        } catch (error) {
            console.error('Error loading teams:', error);
            this.loadingState = 'error';
            
            // Show error UI only if we don't have cached data
            if (this.teams.length === 0) {
                this.renderErrorState();
            } else {
                // Show warning that we're using cached data
                this.showCachedDataWarning();
            }
        }
    }
    
    cacheTeams() {
        try {
            localStorage.setItem('teams_cache', JSON.stringify({
                teams: this.teams,
                timestamp: Date.now()
            }));
        } catch (e) {
            console.error('Error caching teams:', e);
        }
    }
    
    // Other methods...
}
```

## Next Steps

Continue to [UME Examples](./090-examples.md) to see examples of progressively enhanced UME features.
