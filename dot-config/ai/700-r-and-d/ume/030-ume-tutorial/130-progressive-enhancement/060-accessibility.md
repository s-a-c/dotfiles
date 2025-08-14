# Accessibility Considerations

<link rel="stylesheet" href="../assets/css/styles.css">

Accessibility is a crucial aspect of progressive enhancement, ensuring that your UME application is usable by everyone, including people with disabilities. This page covers key accessibility considerations and how they relate to progressive enhancement.

## Why Accessibility Matters

Accessibility ensures that your application:

1. **Is usable by everyone**: Including people with visual, auditory, motor, or cognitive disabilities
2. **Complies with legal requirements**: Many jurisdictions require digital accessibility
3. **Reaches a wider audience**: Approximately 15-20% of the population has some form of disability
4. **Improves SEO**: Many accessibility practices also improve search engine optimization
5. **Enhances usability for all users**: Accessible design often leads to better UX for everyone

## The Connection Between Progressive Enhancement and Accessibility

Progressive enhancement and accessibility share common principles:

1. **Content First**: Both prioritize core content and functionality
2. **Semantic HTML**: Both rely on proper HTML structure and semantics
3. **Separation of Concerns**: Both separate structure, presentation, and behavior
4. **Device Independence**: Both ensure functionality across different input methods
5. **Graceful Degradation**: Both provide fallbacks when features aren't available

## Key Accessibility Considerations

### 1. Semantic HTML

Use HTML elements according to their intended purpose:

```html
<!-- Poor accessibility -->
<div class="button" onclick="submitForm()">Submit</div>

<!-- Good accessibility -->
<button type="submit">Submit</button>

<!-- Poor accessibility -->
<div class="heading">User Profile</div>

<!-- Good accessibility -->
<h1>User Profile</h1>
```

### 2. Keyboard Navigation

Ensure all interactive elements are keyboard accessible:

```html
<!-- Poor keyboard accessibility -->
<div class="card" onclick="openDetails()">
    <div class="card-title">Team Alpha</div>
    <div class="card-body">A high-performing team focused on UX design.</div>
</div>

<!-- Good keyboard accessibility -->
<div class="card">
    <h3 class="card-title">Team Alpha</h3>
    <p class="card-body">A high-performing team focused on UX design.</p>
    <a href="/teams/alpha" class="card-link">View Team Details</a>
</div>
```

```javascript
// Ensure custom components are keyboard accessible
class TabPanel {
    constructor(element) {
        this.element = element;
        this.tabs = Array.from(element.querySelectorAll('[role="tab"]'));
        this.panels = Array.from(element.querySelectorAll('[role="tabpanel"]'));
        
        this.bindEvents();
    }
    
    bindEvents() {
        this.tabs.forEach(tab => {
            // Mouse events
            tab.addEventListener('click', () => this.activateTab(tab));
            
            // Keyboard events
            tab.addEventListener('keydown', (e) => {
                switch (e.key) {
                    case 'ArrowLeft':
                        this.activatePreviousTab();
                        e.preventDefault();
                        break;
                    case 'ArrowRight':
                        this.activateNextTab();
                        e.preventDefault();
                        break;
                    case 'Home':
                        this.activateFirstTab();
                        e.preventDefault();
                        break;
                    case 'End':
                        this.activateLastTab();
                        e.preventDefault();
                        break;
                }
            });
        });
    }
    
    // Implementation methods...
}
```

### 3. ARIA Attributes

Use ARIA (Accessible Rich Internet Applications) attributes when necessary:

```html
<!-- Simple ARIA example -->
<button aria-expanded="false" aria-controls="menu-content">
    Menu
    <span aria-hidden="true">▼</span>
</button>
<div id="menu-content" hidden>
    <!-- Menu content -->
</div>

<!-- Live regions for dynamic content -->
<div aria-live="polite" class="notification-area">
    <!-- Notifications will be announced by screen readers when added -->
</div>
```

### 4. Focus Management

Manage focus properly, especially in dynamic applications:

```javascript
// Focus management in a modal dialog
class AccessibleModal {
    constructor(trigger, modalId) {
        this.trigger = trigger;
        this.modal = document.getElementById(modalId);
        this.closeButton = this.modal.querySelector('.close-button');
        this.focusableElements = this.modal.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        this.firstFocusable = this.focusableElements[0];
        this.lastFocusable = this.focusableElements[this.focusableElements.length - 1];
        
        this.bindEvents();
    }
    
    bindEvents() {
        this.trigger.addEventListener('click', () => this.openModal());
        this.closeButton.addEventListener('click', () => this.closeModal());
        this.modal.addEventListener('keydown', (e) => this.handleKeyDown(e));
    }
    
    openModal() {
        this.modal.classList.add('active');
        this.modal.setAttribute('aria-hidden', 'false');
        
        // Save current focus and move to first focusable element
        this.previouslyFocused = document.activeElement;
        this.firstFocusable.focus();
        
        // Trap focus within modal
        document.body.addEventListener('focus', this.trapFocus, true);
    }
    
    closeModal() {
        this.modal.classList.remove('active');
        this.modal.setAttribute('aria-hidden', 'true');
        
        // Restore focus to trigger
        this.previouslyFocused.focus();
        
        // Remove focus trap
        document.body.removeEventListener('focus', this.trapFocus, true);
    }
    
    trapFocus(e) {
        if (!this.modal.contains(e.target)) {
            this.firstFocusable.focus();
        }
    }
    
    handleKeyDown(e) {
        if (e.key === 'Escape') {
            this.closeModal();
        }
        
        if (e.key === 'Tab') {
            // Trap focus in modal
            if (e.shiftKey && document.activeElement === this.firstFocusable) {
                e.preventDefault();
                this.lastFocusable.focus();
            } else if (!e.shiftKey && document.activeElement === this.lastFocusable) {
                e.preventDefault();
                this.firstFocusable.focus();
            }
        }
    }
}
```

### 5. Color and Contrast

Ensure sufficient color contrast and don't rely solely on color to convey information:

```css
/* Good contrast */
.button-primary {
    background-color: #2563eb; /* Blue */
    color: #ffffff; /* White */
    /* Contrast ratio: 4.5:1 (meets WCAG AA) */
}

/* Poor contrast */
.button-secondary {
    background-color: #e5e7eb; /* Light gray */
    color: #9ca3af; /* Medium gray */
    /* Contrast ratio: 1.5:1 (fails WCAG AA) */
}

/* Don't rely solely on color */
.status-indicator {
    padding: 4px 8px;
    border-radius: 4px;
}

.status-success {
    background-color: #10b981; /* Green */
    color: #ffffff;
}
.status-success::before {
    content: "✓ "; /* Add icon for non-color indication */
}

.status-error {
    background-color: #ef4444; /* Red */
    color: #ffffff;
}
.status-error::before {
    content: "✗ "; /* Add icon for non-color indication */
}
```

### 6. Text Alternatives

Provide text alternatives for non-text content:

```html
<!-- Images need alt text -->
<img src="team-photo.jpg" alt="Team Alpha members at the annual retreat">

<!-- Decorative images should have empty alt text -->
<img src="decorative-divider.png" alt="">

<!-- Complex images need extended descriptions -->
<figure>
    <img src="user-growth-chart.png" alt="Chart showing user growth from January to December">
    <figcaption>
        User growth increased by 25% in Q1, plateaued in Q2, and saw a 40% increase in Q3-Q4.
    </figcaption>
</figure>

<!-- Icon buttons need accessible names -->
<button aria-label="Close dialog">
    <svg class="icon" aria-hidden="true"><!-- X icon --></svg>
</button>
```

### 7. Progressive Enhancement for Accessibility

Apply progressive enhancement principles to accessibility:

```html
<!-- Base accessible experience -->
<div class="team-list">
    <h2>Your Teams</h2>
    <ul>
        <li>
            <h3>Team Alpha</h3>
            <p>5 members</p>
            <a href="/teams/alpha">View Team</a>
        </li>
        <!-- More teams... -->
    </ul>
</div>

<!-- Enhanced with JavaScript -->
<script>
    document.addEventListener('DOMContentLoaded', () => {
        // Only enhance if browser supports required features
        if ('fetch' in window && 'IntersectionObserver' in window) {
            enhanceTeamList();
        }
    });
    
    function enhanceTeamList() {
        const teamList = document.querySelector('.team-list');
        
        // Add search functionality
        const searchInput = document.createElement('input');
        searchInput.type = 'search';
        searchInput.placeholder = 'Search teams...';
        searchInput.setAttribute('aria-label', 'Search teams');
        
        // Ensure the enhancement maintains accessibility
        searchInput.addEventListener('input', () => {
            const searchTerm = searchInput.value.toLowerCase();
            const teams = teamList.querySelectorAll('li');
            
            teams.forEach(team => {
                const teamName = team.querySelector('h3').textContent.toLowerCase();
                const isVisible = teamName.includes(searchTerm);
                
                team.style.display = isVisible ? 'block' : 'none';
                
                // Maintain accessibility with ARIA
                team.setAttribute('aria-hidden', isVisible ? 'false' : 'true');
            });
            
            // Announce results to screen readers
            const visibleCount = Array.from(teams).filter(t => t.style.display !== 'none').length;
            announceToScreenReader(`Showing ${visibleCount} teams matching "${searchTerm}"`);
        });
        
        teamList.insertBefore(searchInput, teamList.firstChild);
    }
    
    function announceToScreenReader(message) {
        const announcer = document.getElementById('sr-announcer') || createAnnouncer();
        announcer.textContent = message;
    }
    
    function createAnnouncer() {
        const announcer = document.createElement('div');
        announcer.id = 'sr-announcer';
        announcer.setAttribute('aria-live', 'polite');
        announcer.setAttribute('aria-atomic', 'true');
        announcer.classList.add('sr-only'); // Visually hidden
        document.body.appendChild(announcer);
        return announcer;
    }
</script>
```

## Accessibility Testing

### 1. Automated Testing

Use automated tools to catch common issues:

```javascript
// Example using axe-core for automated accessibility testing
import { axe } from 'axe-core';

describe('Team Management UI', () => {
    it('should not have accessibility violations', async () => {
        // Render the component
        render(<TeamManagement />);
        
        // Run axe
        const results = await axe(document.body);
        
        // Assert no violations
        expect(results.violations).toHaveLength(0);
    });
});
```

### 2. Manual Testing

Perform manual testing with assistive technologies:

- Test with screen readers (NVDA, JAWS, VoiceOver)
- Test with keyboard navigation only
- Test with screen magnification
- Test with speech recognition software
- Test with high contrast mode

### 3. User Testing

Include people with disabilities in your user testing:

- Recruit participants with various disabilities
- Observe how they use your application
- Gather feedback on accessibility barriers
- Implement improvements based on feedback

## Accessibility and Progressive Enhancement in UME Features

### User Authentication

```html
<!-- Accessible and progressively enhanced login form -->
<form action="/login" method="POST">
    <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" required 
               autocomplete="email" aria-describedby="email-hint">
        <p id="email-hint" class="form-hint">Enter the email address associated with your account</p>
    </div>
    
    <div class="form-group">
        <label for="password">Password</label>
        <div class="password-input-wrapper">
            <input type="password" id="password" name="password" required 
                   autocomplete="current-password" aria-describedby="password-hint">
            <button type="button" class="toggle-password" aria-label="Show password"
                    aria-pressed="false">
                <svg class="icon" aria-hidden="true"><!-- Eye icon --></svg>
            </button>
        </div>
        <p id="password-hint" class="form-hint">Your password must be at least 8 characters</p>
    </div>
    
    <div class="form-group">
        <div class="checkbox-wrapper">
            <input type="checkbox" id="remember" name="remember">
            <label for="remember">Remember me</label>
        </div>
    </div>
    
    <div class="form-actions">
        <button type="submit">Log In</button>
        <a href="/password/reset">Forgot Password?</a>
    </div>
</form>

<script>
    document.addEventListener('DOMContentLoaded', () => {
        const form = document.querySelector('form');
        const togglePasswordButton = document.querySelector('.toggle-password');
        
        // Only enhance if JavaScript is available
        if (togglePasswordButton) {
            const passwordInput = document.getElementById('password');
            
            togglePasswordButton.addEventListener('click', () => {
                const isVisible = passwordInput.type === 'text';
                passwordInput.type = isVisible ? 'password' : 'text';
                togglePasswordButton.setAttribute('aria-pressed', !isVisible);
                togglePasswordButton.setAttribute('aria-label', 
                    isVisible ? 'Show password' : 'Hide password');
            });
        }
        
        // Enhanced form submission if fetch is available
        if ('fetch' in window) {
            form.addEventListener('submit', async (e) => {
                e.preventDefault();
                
                try {
                    const formData = new FormData(form);
                    const response = await fetch(form.action, {
                        method: 'POST',
                        body: formData,
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest'
                        }
                    });
                    
                    if (response.ok) {
                        window.location.href = '/dashboard';
                    } else {
                        const data = await response.json();
                        showAccessibleErrors(data.errors);
                    }
                } catch (error) {
                    console.error('Error:', error);
                    // Fall back to traditional form submission
                    form.submit();
                }
            });
        }
        
        function showAccessibleErrors(errors) {
            // Remove existing error messages
            const existingErrors = form.querySelectorAll('.error-message');
            existingErrors.forEach(el => el.remove());
            
            // Add new error messages
            for (const [field, messages] of Object.entries(errors)) {
                const input = document.getElementById(field);
                if (input) {
                    const errorId = `${field}-error`;
                    const errorMessage = document.createElement('p');
                    errorMessage.id = errorId;
                    errorMessage.className = 'error-message';
                    errorMessage.textContent = messages[0];
                    
                    // Make error accessible to screen readers
                    input.setAttribute('aria-invalid', 'true');
                    input.setAttribute('aria-describedby', 
                        `${input.getAttribute('aria-describedby') || ''} ${errorId}`.trim());
                    
                    // Insert error after input
                    input.parentNode.insertBefore(errorMessage, input.nextSibling);
                    
                    // Focus the first field with an error
                    if (field === Object.keys(errors)[0]) {
                        input.focus();
                    }
                }
            }
            
            // Announce errors to screen readers
            const errorCount = Object.keys(errors).length;
            const message = `Form submission failed with ${errorCount} ${
                errorCount === 1 ? 'error' : 'errors'
            }. Please correct the highlighted fields.`;
            
            announceToScreenReader(message);
        }
        
        function announceToScreenReader(message) {
            const announcer = document.getElementById('sr-announcer') || createAnnouncer();
            announcer.textContent = message;
        }
        
        function createAnnouncer() {
            const announcer = document.createElement('div');
            announcer.id = 'sr-announcer';
            announcer.setAttribute('aria-live', 'assertive');
            announcer.setAttribute('aria-atomic', 'true');
            announcer.classList.add('sr-only');
            document.body.appendChild(announcer);
            return announcer;
        }
    });
</script>
```

## Next Steps

Continue to [Testing Procedures](./070-testing.md) to learn how to test progressive enhancement in your UME application.
