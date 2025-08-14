# Keyboard Navigation

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides best practices for ensuring that all functionality in your UME implementation is accessible via keyboard, without requiring a mouse or other pointing device.

## Why Keyboard Navigation Matters

Many users rely on keyboard navigation instead of a mouse, including:

- People with motor disabilities who cannot use a mouse
- People using screen readers
- Power users who prefer keyboard shortcuts
- People with temporary injuries affecting mouse usage
- People using devices without a mouse or touchscreen

Ensuring keyboard accessibility is a fundamental aspect of web accessibility and is required for WCAG compliance (Success Criterion 2.1.1 Keyboard, Level A).

## Key Principles

### 1. Focus Visibility

All interactive elements must have a visible focus indicator when they receive keyboard focus. This helps users understand where they are on the page.

```css
/* Example of a custom focus style */
:focus {
  outline: 3px solid #4f46e5;
  outline-offset: 2px;
}

/* Ensure focus is only visible for keyboard users, not mouse users */
:focus:not(:focus-visible) {
  outline: none;
}

:focus-visible {
  outline: 3px solid #4f46e5;
  outline-offset: 2px;
}
```

### 2. Logical Tab Order

Interactive elements should receive focus in a logical order that follows the visual layout of the page. This typically means from top to bottom and left to right in left-to-right languages.

```html
<!-- Example of a form with a logical tab order -->
<form>
  <div>
    <label for="name">Name</label>
    <input id="name" type="text">
  </div>
  
  <div>
    <label for="email">Email</label>
    <input id="email" type="email">
  </div>
  
  <div>
    <label for="message">Message</label>
    <textarea id="message"></textarea>
  </div>
  
  <button type="submit">Submit</button>
</form>
```

### 3. Keyboard Traps

Ensure that keyboard focus can be moved away from any component using only the keyboard. Users should not get "trapped" in a specific element or section.

The only exception is for modal dialogs, where focus should be trapped within the dialog until it is closed.

```javascript
// Example of proper focus management for a modal dialog
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];
  
  // Set focus on first focusable element
  firstElement.focus();
  
  // Trap focus within modal
  modal.addEventListener('keydown', function(e) {
    if (e.key === 'Tab') {
      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
  });
}
```

### 4. Skip Links

Provide a "skip to main content" link at the beginning of the page to allow keyboard users to bypass repetitive navigation.

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  
  <header>
    <!-- Navigation and header content -->
  </header>
  
  <main id="main-content">
    <!-- Main content -->
  </main>
</body>
```

```css
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #4f46e5;
  color: white;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
```

## Implementing Keyboard Navigation in UME Components

### User Authentication Components

#### Login Form

```html
<form method="POST" action="/login">
    <div class="form-group">
        <label for="email">Email Address</label>
        <input type="email" id="email" name="email" required>
    </div>
    
    <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" required>
    </div>
    
    <div class="form-group">
        <input type="checkbox" id="remember" name="remember">
        <label for="remember">Remember me</label>
    </div>
    
    <button type="submit">Login</button>
    
    <div>
        <a href="/password/reset">Forgot your password?</a>
    </div>
</form>
```

#### Two-Factor Authentication

```html
<form method="POST" action="/two-factor-challenge">
    <div class="form-group">
        <label for="code">Authentication Code</label>
        <input type="text" id="code" name="code" inputmode="numeric" pattern="[0-9]*" autocomplete="one-time-code" required autofocus>
        <small>Enter the 6-digit code from your authenticator app</small>
    </div>
    
    <button type="submit">Verify</button>
    
    <div>
        <a href="/two-factor-challenge/recovery-code">Use a recovery code</a>
    </div>
</form>
```

### User Profile Components

#### Profile Form with Tabs

```html
<div role="tablist">
    <button id="tab-personal" role="tab" aria-selected="true" aria-controls="panel-personal">
        Personal Information
    </button>
    <button id="tab-account" role="tab" aria-selected="false" aria-controls="panel-account">
        Account Settings
    </button>
    <button id="tab-security" role="tab" aria-selected="false" aria-controls="panel-security">
        Security
    </button>
</div>

<div id="panel-personal" role="tabpanel" aria-labelledby="tab-personal">
    <form>
        <!-- Personal information fields -->
    </form>
</div>

<div id="panel-account" role="tabpanel" aria-labelledby="tab-account" hidden>
    <form>
        <!-- Account settings fields -->
    </form>
</div>

<div id="panel-security" role="tabpanel" aria-labelledby="tab-security" hidden>
    <form>
        <!-- Security settings fields -->
    </form>
</div>
```

```javascript
// JavaScript for keyboard navigation in tabs
document.querySelectorAll('[role="tab"]').forEach(tab => {
  tab.addEventListener('click', switchTab);
  tab.addEventListener('keydown', handleTabKeydown);
});

function switchTab(e) {
  const selectedTab = e.currentTarget;
  const tabs = Array.from(selectedTab.parentNode.children);
  
  // Hide all panels
  tabs.forEach(tab => {
    const panel = document.getElementById(tab.getAttribute('aria-controls'));
    panel.hidden = true;
    tab.setAttribute('aria-selected', 'false');
    tab.tabIndex = -1;
  });
  
  // Show selected panel
  const panel = document.getElementById(selectedTab.getAttribute('aria-controls'));
  panel.hidden = false;
  selectedTab.setAttribute('aria-selected', 'true');
  selectedTab.tabIndex = 0;
}

function handleTabKeydown(e) {
  const tabs = Array.from(e.currentTarget.parentNode.children);
  const index = tabs.indexOf(e.currentTarget);
  
  switch (e.key) {
    case 'ArrowRight':
      e.preventDefault();
      const nextTab = tabs[(index + 1) % tabs.length];
      nextTab.focus();
      nextTab.click();
      break;
    case 'ArrowLeft':
      e.preventDefault();
      const prevTab = tabs[(index - 1 + tabs.length) % tabs.length];
      prevTab.focus();
      prevTab.click();
      break;
    case 'Home':
      e.preventDefault();
      tabs[0].focus();
      tabs[0].click();
      break;
    case 'End':
      e.preventDefault();
      tabs[tabs.length - 1].focus();
      tabs[tabs.length - 1].click();
      break;
  }
}
```

### Team Management Components

#### Team Member List with Actions

```html
<table>
  <caption>Team Members</caption>
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">Role</th>
      <th scope="col">Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>John Doe</td>
      <td>Admin</td>
      <td>
        <button aria-label="Edit John Doe">Edit</button>
        <button aria-label="Remove John Doe from team">Remove</button>
      </td>
    </tr>
    <tr>
      <td>Jane Smith</td>
      <td>Member</td>
      <td>
        <button aria-label="Edit Jane Smith">Edit</button>
        <button aria-label="Remove Jane Smith from team">Remove</button>
      </td>
    </tr>
  </tbody>
</table>
```

## Testing Keyboard Navigation

To test keyboard navigation in your UME implementation:

1. **Tab through the entire page** to ensure all interactive elements are focusable and receive focus in a logical order.
2. **Check focus visibility** to ensure all interactive elements have a visible focus indicator.
3. **Test all functionality** using only the keyboard, including:
   - Form submission
   - Button activation
   - Link navigation
   - Modal dialogs
   - Dropdown menus
   - Tabs and accordions
4. **Verify that there are no keyboard traps** where focus cannot be moved away from an element using only the keyboard.

For more detailed testing procedures, refer to the [Accessibility Testing](./080-testing-procedures.md) section.

## Common Keyboard Navigation Issues and Solutions

| Issue | Solution |
|-------|----------|
| No visible focus indicator | Add a clear focus style to all interactive elements |
| Illogical tab order | Ensure elements receive focus in a logical order, matching the visual layout |
| Custom controls not keyboard accessible | Ensure all custom controls can be operated with keyboard alone |
| Keyboard traps | Ensure users can navigate away from all elements using keyboard alone |
| Hidden content not accessible | Ensure hidden content is either not in the tab order or is accessible when revealed |

## Additional Resources

- [WebAIM: Keyboard Accessibility](https://webaim.org/techniques/keyboard/)
- [MDN: Keyboard-navigable JavaScript widgets](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Keyboard-navigable_JavaScript_widgets)
- [W3C: Keyboard Accessible](https://www.w3.org/WAI/WCAG21/Understanding/keyboard.html)
