# Performance Considerations for Mobile

<link rel="stylesheet" href="../assets/css/styles.css">

Mobile devices often have slower processors, less memory, limited bandwidth, and battery constraints. This section covers performance optimization techniques for mobile devices in your UME implementation.

## Understanding Mobile Performance Constraints

Mobile devices face several performance challenges:

1. **Network Limitations**:
   - Slower connection speeds (3G, 4G)
   - Higher latency
   - Data usage concerns
   - Intermittent connectivity

2. **Hardware Limitations**:
   - Less processing power
   - Limited RAM
   - Battery constraints
   - Thermal throttling

3. **Browser Limitations**:
   - Smaller JavaScript engines
   - Less caching capability
   - Stricter resource limits

## Key Performance Metrics

Focus on these metrics when optimizing for mobile:

1. **Time to First Byte (TTFB)**: How quickly the server responds
2. **First Contentful Paint (FCP)**: When the first content appears
3. **Largest Contentful Paint (LCP)**: When the largest content element appears
4. **Time to Interactive (TTI)**: When the page becomes fully interactive
5. **Total Blocking Time (TBT)**: Time when the main thread is blocked
6. **Cumulative Layout Shift (CLS)**: Visual stability of the page

## Network Optimization

### 1. Minimize Request Size

Reduce the amount of data sent over the network:

- **Compress Assets**: Use Gzip or Brotli compression
  ```php
  // In your .htaccess file
  <IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
  </IfModule>
  ```

- **Optimize Images**: Use WebP format and appropriate sizes
  ```php
  // Using Laravel's image manipulation library
  $image = Image::make($request->file('avatar'))
      ->fit(300, 300)
      ->encode('webp', 80);
  ```

- **Lazy Load Non-Critical Resources**:
  ```html
  <img src="placeholder.jpg" 
       data-src="actual-image.jpg" 
       class="lazyload" 
       alt="Lazy loaded image">
  ```

### 2. Reduce API Payload Size

Optimize API responses for mobile:

- **Use Pagination**: Limit the number of records returned
  ```php
  // In your controller
  public function index()
  {
      return User::paginate(10);
  }
  ```

- **Implement Resource Transformations**: Return only necessary fields
  ```php
  // UserResource.php
  public function toArray($request)
  {
      // Check if this is a mobile request
      $isMobile = $request->header('X-Device-Type') === 'mobile';
      
      $resource = [
          'id' => $this->id,
          'name' => $this->name,
          'email' => $this->email,
      ];
      
      // Include additional fields only for desktop
      if (!$isMobile) {
          $resource['created_at'] = $this->created_at;
          $resource['updated_at'] = $this->updated_at;
          $resource['additional_data'] = $this->additional_data;
      }
      
      return $resource;
  }
  ```

- **Use GraphQL for Flexible Data Fetching**:
  ```php
  // Using Lighthouse PHP
  // schema.graphql
  type User {
      id: ID!
      name: String!
      email: String!
      profile: Profile @include(if: $includeProfile)
      teams: [Team!] @include(if: $includeTeams)
  }
  ```

### 3. Implement Caching

Use caching to reduce network requests:

- **HTTP Caching**: Set appropriate cache headers
  ```php
  // In your controller
  public function show(User $user)
  {
      return response($user)
          ->header('Cache-Control', 'public, max-age=3600');
  }
  ```

- **Service Worker Caching**: Cache assets and API responses
  ```javascript
  // public/service-worker.js
  self.addEventListener('install', (event) => {
      event.waitUntil(
          caches.open('v1').then((cache) => {
              return cache.addAll([
                  '/',
                  '/css/app.css',
                  '/js/app.js',
                  '/images/logo.png'
              ]);
          })
      );
  });
  
  self.addEventListener('fetch', (event) => {
      event.respondWith(
          caches.match(event.request).then((response) => {
              return response || fetch(event.request);
          })
      );
  });
  ```

- **Local Storage for User Data**: Store non-sensitive user preferences
  ```javascript
  // Save user preferences
  localStorage.setItem('theme', 'dark');
  
  // Retrieve user preferences
  const theme = localStorage.getItem('theme');
  ```

## JavaScript Optimization

### 1. Code Splitting

Split your JavaScript into smaller chunks:

- **Route-Based Code Splitting**: Load JavaScript only for the current route
  ```javascript
  // Using Laravel Vite
  // vite.config.js
  export default defineConfig({
      build: {
          rollupOptions: {
              output: {
                  manualChunks: {
                      'vendor': ['alpinejs', 'axios'],
                      'dashboard': ['./resources/js/dashboard.js'],
                      'profile': ['./resources/js/profile.js'],
                      'teams': ['./resources/js/teams.js']
                  }
              }
          }
      }
  });
  ```

- **Component-Based Code Splitting**: Load components on demand
  ```javascript
  // Using dynamic imports
  document.getElementById('load-chart').addEventListener('click', async () => {
      const { renderChart } = await import('./chart.js');
      renderChart(document.getElementById('chart-container'));
  });
  ```

### 2. Defer Non-Critical JavaScript

Delay loading non-essential JavaScript:

```html
<script src="/js/critical.js"></script>
<script src="/js/non-critical.js" defer></script>
```

### 3. Optimize Event Listeners

Minimize the impact of event listeners:

- **Use Event Delegation**: Attach listeners to parent elements
  ```javascript
  // Instead of attaching to each button
  document.querySelector('.team-list').addEventListener('click', (event) => {
      if (event.target.matches('.team-button')) {
          // Handle button click
      }
  });
  ```

- **Throttle or Debounce Events**: Limit the frequency of event handling
  ```javascript
  // Debounce search input
  const debounce = (fn, delay) => {
      let timeoutId;
      return (...args) => {
          clearTimeout(timeoutId);
          timeoutId = setTimeout(() => fn(...args), delay);
      };
  };
  
  const handleSearch = debounce((event) => {
      // Perform search
  }, 300);
  
  document.querySelector('.search-input').addEventListener('input', handleSearch);
  ```

## CSS Optimization

### 1. Minimize CSS

Reduce the size of your CSS:

- **Remove Unused CSS**: Use PurgeCSS to eliminate unused styles
  ```javascript
  // tailwind.config.js
  module.exports = {
      content: [
          './resources/**/*.blade.php',
          './resources/**/*.js',
          './resources/**/*.vue',
      ],
      // ...
  };
  ```

- **Inline Critical CSS**: Include critical styles directly in the HTML
  ```html
  <head>
      <style>
          /* Critical CSS here */
          body { margin: 0; font-family: sans-serif; }
          .header { height: 60px; background: #fff; }
      </style>
      <link rel="stylesheet" href="/css/app.css" media="print" onload="this.media='all'">
  </head>
  ```

### 2. Optimize Animations

Make animations more efficient:

- **Use `transform` and `opacity`**: These properties are more performant
  ```css
  /* Instead of */
  .button:active {
      margin-top: 2px;
  }
  
  /* Use */
  .button:active {
      transform: translateY(2px);
  }
  ```

- **Reduce Animation Complexity**: Simplify animations on mobile
  ```css
  @media (max-width: 768px) {
      .animated-element {
          animation-duration: 0.2s;
          /* Simplify or disable complex animations */
      }
  }
  ```

## Backend Optimization

### 1. Optimize Database Queries

Reduce database load:

- **Eager Loading Relationships**: Prevent N+1 query problems
  ```php
  // Instead of
  $teams = Team::all();
  foreach ($teams as $team) {
      echo $team->owner->name; // This causes N+1 queries
  }
  
  // Use
  $teams = Team::with('owner')->get();
  foreach ($teams as $team) {
      echo $team->owner->name; // No additional queries
  }
  ```

- **Use Query Caching**: Cache frequently accessed data
  ```php
  // Using Laravel's cache
  $users = Cache::remember('users', 3600, function () {
      return User::all();
  });
  ```

### 2. Implement API Rate Limiting

Protect your API from excessive requests:

```php
// In RouteServiceProvider.php
Route::middleware(['api', 'throttle:60,1'])
    ->prefix('api')
    ->group(base_path('routes/api.php'));
```

## Battery Optimization

### 1. Reduce CPU Usage

Minimize processing that drains battery:

- **Optimize JavaScript Execution**: Avoid long-running scripts
- **Reduce DOM Manipulations**: Batch DOM updates
- **Use RequestAnimationFrame**: For smooth animations
  ```javascript
  function animate() {
      // Update animation
      requestAnimationFrame(animate);
  }
  requestAnimationFrame(animate);
  ```

### 2. Minimize Network Activity

Reduce background network requests:

- **Batch API Requests**: Combine multiple requests into one
- **Implement Polling Limits**: Reduce frequency of real-time updates on mobile
  ```javascript
  // Adjust polling frequency based on device
  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
  const pollingInterval = isMobile ? 30000 : 5000; // 30s for mobile, 5s for desktop
  
  setInterval(() => {
      // Poll for updates
  }, pollingInterval);
  ```

## Testing Mobile Performance

### 1. Use Chrome DevTools

- **Lighthouse**: Run mobile performance audits
- **Performance Panel**: Analyze JavaScript execution
- **Network Panel**: Simulate slow connections

### 2. Real Device Testing

- Test on actual mobile devices, not just emulators
- Test on both high-end and low-end devices
- Test on different network conditions (WiFi, 4G, 3G)

### 3. Performance Monitoring

- Implement Real User Monitoring (RUM)
- Track key performance metrics
- Set up alerts for performance regressions

```php
// Using Laravel Telescope for local development
// config/telescope.php
'performance' => [
    'enabled' => true,
    'slow_threshold' => 100, // 100ms
],
```

## Mobile Performance Checklist

Use this checklist to ensure your UME implementation is optimized for mobile:

- [ ] Images are properly sized and compressed
- [ ] CSS and JavaScript are minified
- [ ] Critical CSS is inlined
- [ ] Non-critical resources are lazy loaded
- [ ] API responses are optimized for mobile
- [ ] Caching is implemented for assets and API responses
- [ ] JavaScript is code-split and deferred when possible
- [ ] Animations are optimized for performance
- [ ] Database queries are optimized
- [ ] Battery usage is minimized
- [ ] Performance is tested on actual mobile devices

## Next Steps

Continue to [Offline Capabilities](./060-offline-capabilities.md) to learn how to implement offline functionality in your UME application.
