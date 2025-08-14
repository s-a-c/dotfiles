# Testing Procedures for Progressive Enhancement

<link rel="stylesheet" href="../assets/css/styles.css">

Testing is crucial to ensure that your progressively enhanced UME application works for all users across different browsers, devices, and network conditions. This page covers comprehensive testing procedures for progressive enhancement.

## Testing Approach

A thorough testing approach for progressive enhancement includes:

1. **Layer Testing**: Testing each layer of enhancement independently
2. **Feature Testing**: Testing with specific features disabled
3. **Device Testing**: Testing across different devices and browsers
4. **Network Testing**: Testing under various network conditions
5. **Accessibility Testing**: Testing with assistive technologies
6. **User Testing**: Testing with real users

## Layer Testing

Test each layer of your application independently to ensure the core functionality works without enhancements.

### 1. HTML-Only Testing

Test your application with CSS and JavaScript disabled:

1. **Disable CSS**:
   - Chrome: DevTools > Settings > Preferences > Disable CSS
   - Firefox: DevTools > 3-dot menu > Disable > Disable CSS

2. **Disable JavaScript**:
   - Chrome: DevTools > Settings > Preferences > Disable JavaScript
   - Firefox: DevTools > 3-dot menu > Disable > Disable JavaScript

3. **Check for**:
   - Content is accessible and readable
   - Forms can be submitted
   - Links work correctly
   - Core functionality is available

### 2. CSS Testing

Test your application with CSS enabled but JavaScript disabled:

1. **Enable CSS, Disable JavaScript**

2. **Check for**:
   - Visual presentation is correct
   - Layout is appropriate
   - Responsive design works
   - No functionality depends solely on CSS

### 3. JavaScript Testing

Test your application with both CSS and JavaScript enabled:

1. **Enable CSS and JavaScript**

2. **Check for**:
   - Enhanced functionality works correctly
   - JavaScript doesn't break core functionality
   - Fallbacks work when JavaScript features fail

## Feature Testing

Test your application with specific features disabled to ensure graceful degradation.

### 1. Feature Disabling in DevTools

Use browser DevTools to disable specific features:

1. **Disable Local Storage**:
   - Chrome: DevTools > Application > Storage > Clear site data
   - Firefox: DevTools > Storage > Local Storage > Delete All

2. **Simulate Offline Mode**:
   - Chrome: DevTools > Network > Offline
   - Firefox: DevTools > Network > Offline

3. **Disable Cookies**:
   - Chrome: DevTools > Application > Cookies > Delete All
   - Firefox: DevTools > Storage > Cookies > Delete All

### 2. Feature Mocking

Create test utilities to mock feature availability:

```javascript
// Feature mocking utility
const featureMock = {
    disableFeature(featureName) {
        switch (featureName) {
            case 'localStorage':
                this._mockLocalStorage();
                break;
            case 'fetch':
                this._mockFetch();
                break;
            case 'IntersectionObserver':
                this._mockIntersectionObserver();
                break;
            // Add more features as needed
        }
    },
    
    _mockLocalStorage() {
        const originalLocalStorage = window.localStorage;
        
        // Replace with mock that throws errors
        Object.defineProperty(window, 'localStorage', {
            get: function() {
                throw new Error('localStorage is disabled');
            }
        });
        
        // Return function to restore original
        return () => {
            Object.defineProperty(window, 'localStorage', {
                get: function() {
                    return originalLocalStorage;
                }
            });
        };
    },
    
    _mockFetch() {
        const originalFetch = window.fetch;
        
        // Replace with mock that rejects
        window.fetch = () => Promise.reject(new Error('fetch is disabled'));
        
        // Return function to restore original
        return () => {
            window.fetch = originalFetch;
        };
    },
    
    _mockIntersectionObserver() {
        const originalIntersectionObserver = window.IntersectionObserver;
        
        // Remove IntersectionObserver
        delete window.IntersectionObserver;
        
        // Return function to restore original
        return () => {
            window.IntersectionObserver = originalIntersectionObserver;
        };
    }
};
```

### 3. Automated Feature Testing

Create automated tests that verify functionality with features disabled:

```javascript
// Jest test example
describe('User Profile Component', () => {
    it('works without localStorage', () => {
        // Mock localStorage to be unavailable
        const restoreLocalStorage = featureMock.disableFeature('localStorage');
        
        // Render component
        render(<UserProfile userId="123" />);
        
        // Verify core functionality works
        expect(screen.getByText('User Profile')).toBeInTheDocument();
        expect(screen.getByLabelText('Name')).toBeInTheDocument();
        
        // Verify form submission works
        fireEvent.change(screen.getByLabelText('Name'), { target: { value: 'John Doe' } });
        fireEvent.click(screen.getByText('Save'));
        
        // Verify API call was made despite localStorage being unavailable
        expect(mockApiCall).toHaveBeenCalledWith(expect.objectContaining({
            name: 'John Doe'
        }));
        
        // Restore localStorage
        restoreLocalStorage();
    });
});
```

## Device Testing

Test your application across different devices and browsers to ensure consistent functionality.

### 1. Browser Testing Matrix

Create a testing matrix covering different browsers and versions:

| Browser | Versions | Features to Test |
|---------|----------|-----------------|
| Chrome | Latest, Latest-1 | All features |
| Firefox | Latest, Latest-1 | All features |
| Safari | Latest, Latest-1 | All features |
| Edge | Latest | All features |
| IE 11 | 11 | Core functionality |
| Mobile Chrome | Latest | All features |
| Mobile Safari | Latest | All features |

### 2. Device Testing

Test on different physical devices or emulators:

1. **Desktop**: Various screen sizes and resolutions
2. **Tablets**: iPad, Android tablets
3. **Smartphones**: iPhone, Android phones
4. **Older Devices**: Devices with limited capabilities

### 3. Responsive Testing

Test responsive design across different viewport sizes:

1. **Use Browser DevTools**:
   - Chrome: DevTools > Toggle Device Toolbar
   - Firefox: DevTools > Responsive Design Mode

2. **Test Common Breakpoints**:
   - Mobile: 320px - 480px
   - Tablet: 768px - 1024px
   - Desktop: 1024px+

## Network Testing

Test your application under various network conditions to ensure it works with limited connectivity.

### 1. Network Throttling

Use browser DevTools to simulate different network conditions:

1. **Chrome**:
   - DevTools > Network > Throttling dropdown
   - Options: Slow 3G, Fast 3G, Offline

2. **Firefox**:
   - DevTools > Network > Throttling dropdown
   - Options: GPRS, Regular 2G, Good 2G, Regular 3G, Good 3G, Regular 4G, DSL, WiFi

### 2. Offline Testing

Test your application in offline mode:

1. **Enable Offline Mode**:
   - Chrome: DevTools > Network > Offline
   - Firefox: DevTools > Network > Offline

2. **Check for**:
   - Appropriate offline messages
   - Cached content is available
   - Offline functionality works
   - Data is saved for later synchronization

### 3. Intermittent Connectivity Testing

Test how your application handles intermittent connectivity:

1. **Toggle Offline/Online**:
   - Switch between offline and online modes
   - Check how the application recovers

2. **Check for**:
   - Reconnection handling
   - Data synchronization
   - User notifications about connectivity

## Automated Testing for Progressive Enhancement

Create automated tests that verify progressive enhancement principles.

### 1. Unit Tests for Feature Detection

Test your feature detection logic:

```javascript
// Jest test example
describe('Feature Detection', () => {
    it('correctly detects localStorage support', () => {
        // Mock localStorage to be available
        expect(features.supportsLocalStorage()).toBe(true);
        
        // Mock localStorage to be unavailable
        const originalLocalStorage = window.localStorage;
        Object.defineProperty(window, 'localStorage', {
            get: function() {
                throw new Error('localStorage is disabled');
            }
        });
        
        expect(features.supportsLocalStorage()).toBe(false);
        
        // Restore original
        Object.defineProperty(window, 'localStorage', {
            get: function() {
                return originalLocalStorage;
            }
        });
    });
});
```

### 2. Integration Tests for Fallbacks

Test that fallbacks work correctly:

```javascript
// Jest test example
describe('Data Storage Service', () => {
    it('uses localStorage when available', () => {
        // Mock localStorage
        const setItemSpy = jest.spyOn(Storage.prototype, 'setItem');
        
        // Use service
        const dataService = new DataStorageService();
        dataService.saveData('test', { name: 'John' });
        
        // Verify localStorage was used
        expect(setItemSpy).toHaveBeenCalledWith('test', JSON.stringify({ name: 'John' }));
        
        // Clean up
        setItemSpy.mockRestore();
    });
    
    it('falls back to cookies when localStorage is unavailable', () => {
        // Mock localStorage to be unavailable
        const originalLocalStorage = window.localStorage;
        Object.defineProperty(window, 'localStorage', {
            get: function() {
                throw new Error('localStorage is disabled');
            }
        });
        
        // Mock document.cookie
        const originalCookie = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie');
        let cookieValue = '';
        Object.defineProperty(document, 'cookie', {
            get: function() {
                return cookieValue;
            },
            set: function(value) {
                cookieValue = value;
            }
        });
        
        // Use service
        const dataService = new DataStorageService();
        dataService.saveData('test', { name: 'John' });
        
        // Verify cookie was set
        expect(document.cookie).toContain('test=');
        expect(document.cookie).toContain(encodeURIComponent(JSON.stringify({ name: 'John' })));
        
        // Clean up
        Object.defineProperty(window, 'localStorage', {
            get: function() {
                return originalLocalStorage;
            }
        });
        Object.defineProperty(Document.prototype, 'cookie', originalCookie);
    });
});
```

### 3. End-to-End Tests

Use end-to-end testing tools to verify the complete user experience:

```javascript
// Cypress test example
describe('User Profile', () => {
    it('works with JavaScript enabled', () => {
        cy.visit('/user/profile');
        
        // Fill form with JavaScript enhancements
        cy.get('#name').type('John Doe');
        cy.get('#email').type('john@example.com');
        
        // Submit form
        cy.get('button[type="submit"]').click();
        
        // Verify success message appears without page reload
        cy.get('.success-message').should('be.visible');
        cy.get('.success-message').should('contain', 'Profile updated successfully');
    });
    
    it('works with JavaScript disabled', () => {
        // Visit with JavaScript disabled (Cypress config)
        cy.visit('/user/profile', {
            onBeforeLoad(win) {
                // Disable JavaScript
                win.eval = null;
            }
        });
        
        // Fill form without JavaScript
        cy.get('#name').type('John Doe');
        cy.get('#email').type('john@example.com');
        
        // Submit form
        cy.get('form').submit();
        
        // Verify redirect to success page
        cy.url().should('include', '/user/profile/success');
        cy.get('h1').should('contain', 'Profile Updated');
    });
});
```

## Manual Testing Checklist

Use this checklist for manual testing of progressive enhancement:

### Basic Functionality

- [ ] Core content is accessible with JavaScript disabled
- [ ] Forms submit correctly with JavaScript disabled
- [ ] Links work correctly with JavaScript disabled
- [ ] Navigation works with JavaScript disabled

### Enhanced Functionality

- [ ] JavaScript enhancements work correctly when available
- [ ] Enhanced features degrade gracefully when not supported
- [ ] No functionality breaks when specific features are unavailable

### Accessibility

- [ ] Content is accessible with screen readers
- [ ] Keyboard navigation works correctly
- [ ] Focus management works correctly
- [ ] ARIA attributes are used appropriately

### Responsive Design

- [ ] Layout adapts to different screen sizes
- [ ] Touch targets are appropriately sized on mobile
- [ ] Content is readable on all devices
- [ ] No horizontal scrolling on mobile

### Network Conditions

- [ ] Application works under slow network conditions
- [ ] Application provides feedback during loading
- [ ] Critical functionality works offline
- [ ] Application recovers gracefully from network interruptions

## Testing UME Features

### User Authentication

Test progressive enhancement in authentication:

1. **Core Functionality**:
   - Form submission works without JavaScript
   - Validation errors are displayed server-side
   - Successful login redirects to appropriate page

2. **Enhanced Functionality**:
   - Client-side validation provides immediate feedback
   - AJAX submission prevents page reload
   - Remember me functionality works with localStorage
   - Social login options are available

3. **Fallbacks**:
   - Authentication works when cookies are the only available storage
   - Form works when client-side validation is unavailable

### Team Management

Test progressive enhancement in team management:

1. **Core Functionality**:
   - Teams can be created and managed without JavaScript
   - Team members can be added and removed
   - Team settings can be updated

2. **Enhanced Functionality**:
   - Real-time updates show team changes
   - Drag-and-drop interface for organizing teams
   - Inline editing of team details

3. **Fallbacks**:
   - Team management works with traditional page loads
   - Changes are reflected after page refresh when real-time updates aren't available

## Next Steps

Continue to [Performance Implications](./080-performance.md) to learn about the performance considerations of progressive enhancement in your UME application.
