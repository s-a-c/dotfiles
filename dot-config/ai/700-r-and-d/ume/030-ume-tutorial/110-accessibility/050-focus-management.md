# Focus Management

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides best practices for managing focus in your UME implementation, including focus indicators and focus trapping.

## Why Focus Management Matters

Proper focus management is essential for keyboard accessibility and screen reader usability. It helps users understand where they are on the page and navigate efficiently without a mouse.

Focus management is particularly important for:

- Users who navigate with a keyboard
- Screen reader users
- Users with motor disabilities
- Power users who prefer keyboard shortcuts

## Key Principles

### 1. Visible Focus Indicators

All interactive elements must have a visible focus indicator when they receive keyboard focus. This helps users understand where they are on the page.

```css
/* Default browser focus styles are often insufficient */
:focus {
  outline: 3px solid #4f46e5; /* Indigo */
  outline-offset: 2px;
}

/* Ensure focus is only visible for keyboard users, not mouse users */
:focus:not(:focus-visible) {
  outline: none;
}

:focus-visible {
  outline: 3px solid #4f46e5; /* Indigo */
  outline-offset: 2px;
}

/* Custom focus styles for different elements */
button:focus-visible {
  outline: 3px solid #4f46e5; /* Indigo */
  outline-offset: 2px;
}

input:focus-visible, select:focus-visible, textarea:focus-visible {
  outline: none;
  border-color: #4f46e5; /* Indigo */
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.3); /* Indigo with opacity */
}

a:focus-visible {
  outline: 3px solid #4f46e5; /* Indigo */
  outline-offset: 2px;
  text-decoration: underline;
}
```

### 2. Logical Focus Order

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

### 3. Focus Management for Dynamic Content

When content changes dynamically, focus should be managed appropriately to ensure users don't lose their place.

```javascript
// Example: Opening a modal dialog
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  
  // Store the element that had focus before opening the modal
  modal.previouslyFocusedElement = document.activeElement;
  
  // Show the modal
  modal.hidden = false;
  
  // Set focus on the first focusable element in the modal
  const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
  if (focusableElements.length > 0) {
    focusableElements[0].focus();
  }
}

// Example: Closing a modal dialog
function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  
  // Hide the modal
  modal.hidden = true;
  
  // Restore focus to the element that had focus before the modal was opened
  if (modal.previouslyFocusedElement) {
    modal.previouslyFocusedElement.focus();
  }
}
```

### 4. Focus Trapping

In modal dialogs and other overlay components, focus should be trapped within the component until it is closed. This prevents users from accidentally interacting with content that is visually hidden behind the overlay.

```javascript
// Example: Trapping focus in a modal dialog
function trapFocus(modalId) {
  const modal = document.getElementById(modalId);
  const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
  
  if (focusableElements.length === 0) return;
  
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];
  
  // Handle Tab key to cycle through focusable elements
  modal.addEventListener('keydown', function(e) {
    if (e.key === 'Tab') {
      // Shift+Tab on first element should go to last element
      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      }
      // Tab on last element should go to first element
      else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
    // Escape key should close the modal
    else if (e.key === 'Escape') {
      closeModal(modalId);
    }
  });
}
```

### 5. Skip Links

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
  background: #4f46e5; /* Indigo */
  color: white;
  padding: 8px;
  z-index: 100;
  transition: top 0.2s;
}

.skip-link:focus {
  top: 0;
}
```

## Implementing Focus Management in UME Components

### Modal Dialogs

```html
<button id="open-modal-button" aria-haspopup="dialog">Open Modal</button>

<div id="modal" role="dialog" aria-labelledby="modal-title" aria-modal="true" hidden>
  <div class="modal-content">
    <header>
      <h2 id="modal-title">Modal Title</h2>
      <button id="close-modal-button" aria-label="Close modal">×</button>
    </header>
    
    <div class="modal-body">
      <!-- Modal content -->
      <p>This is the modal content.</p>
      <input type="text" placeholder="Enter some text">
      <button>Submit</button>
    </div>
    
    <footer>
      <button id="cancel-button">Cancel</button>
      <button id="confirm-button">Confirm</button>
    </footer>
  </div>
</div>

<script>
  const modal = document.getElementById('modal');
  const openButton = document.getElementById('open-modal-button');
  const closeButton = document.getElementById('close-modal-button');
  const cancelButton = document.getElementById('cancel-button');
  const confirmButton = document.getElementById('confirm-button');
  
  // Store the element that had focus before opening the modal
  let previouslyFocusedElement;
  
  function openModal() {
    // Store the currently focused element
    previouslyFocusedElement = document.activeElement;
    
    // Show the modal
    modal.hidden = false;
    
    // Set focus on the first focusable element in the modal
    const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    if (focusableElements.length > 0) {
      focusableElements[0].focus();
    }
    
    // Trap focus within the modal
    trapFocus();
  }
  
  function closeModal() {
    // Hide the modal
    modal.hidden = true;
    
    // Restore focus to the element that had focus before the modal was opened
    if (previouslyFocusedElement) {
      previouslyFocusedElement.focus();
    }
  }
  
  function trapFocus() {
    const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    
    if (focusableElements.length === 0) return;
    
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];
    
    // Handle Tab key to cycle through focusable elements
    modal.addEventListener('keydown', function(e) {
      if (e.key === 'Tab') {
        // Shift+Tab on first element should go to last element
        if (e.shiftKey && document.activeElement === firstElement) {
          e.preventDefault();
          lastElement.focus();
        }
        // Tab on last element should go to first element
        else if (!e.shiftKey && document.activeElement === lastElement) {
          e.preventDefault();
          firstElement.focus();
        }
      }
      // Escape key should close the modal
      else if (e.key === 'Escape') {
        closeModal();
      }
    });
  }
  
  openButton.addEventListener('click', openModal);
  closeButton.addEventListener('click', closeModal);
  cancelButton.addEventListener('click', closeModal);
  confirmButton.addEventListener('click', () => {
    // Handle confirmation
    closeModal();
  });
</script>
```

### Tabs

```html
<div class="tabs" role="tablist" aria-label="User Profile">
  <button id="tab-personal" role="tab" aria-selected="true" aria-controls="panel-personal" tabindex="0">
    Personal Information
  </button>
  <button id="tab-account" role="tab" aria-selected="false" aria-controls="panel-account" tabindex="-1">
    Account Settings
  </button>
  <button id="tab-security" role="tab" aria-selected="false" aria-controls="panel-security" tabindex="-1">
    Security
  </button>
</div>

<div id="panel-personal" role="tabpanel" aria-labelledby="tab-personal" tabindex="0">
  <!-- Personal information content -->
</div>

<div id="panel-account" role="tabpanel" aria-labelledby="tab-account" tabindex="0" hidden>
  <!-- Account settings content -->
</div>

<div id="panel-security" role="tabpanel" aria-labelledby="tab-security" tabindex="0" hidden>
  <!-- Security content -->
</div>

<script>
  const tabs = document.querySelectorAll('[role="tab"]');
  const tabPanels = document.querySelectorAll('[role="tabpanel"]');
  
  // Add click event to tabs
  tabs.forEach(tab => {
    tab.addEventListener('click', changeTabs);
  });
  
  // Add keyboard navigation
  tabs.forEach(tab => {
    tab.addEventListener('keydown', e => {
      const tabsArray = Array.from(tabs);
      const index = tabsArray.indexOf(tab);
      
      // Handle arrow keys
      switch (e.key) {
        case 'ArrowRight':
          e.preventDefault();
          // Move to next tab, or first tab if at the end
          const nextTab = tabsArray[(index + 1) % tabsArray.length];
          activateTab(nextTab);
          break;
        case 'ArrowLeft':
          e.preventDefault();
          // Move to previous tab, or last tab if at the beginning
          const prevTab = tabsArray[(index - 1 + tabsArray.length) % tabsArray.length];
          activateTab(prevTab);
          break;
        case 'Home':
          e.preventDefault();
          // Move to first tab
          activateTab(tabsArray[0]);
          break;
        case 'End':
          e.preventDefault();
          // Move to last tab
          activateTab(tabsArray[tabsArray.length - 1]);
          break;
      }
    });
  });
  
  function changeTabs(e) {
    const tab = e.target;
    activateTab(tab);
  }
  
  function activateTab(tab) {
    // Deactivate all tabs
    tabs.forEach(t => {
      t.setAttribute('aria-selected', 'false');
      t.setAttribute('tabindex', '-1');
    });
    
    // Hide all tab panels
    tabPanels.forEach(panel => {
      panel.hidden = true;
    });
    
    // Activate the selected tab
    tab.setAttribute('aria-selected', 'true');
    tab.setAttribute('tabindex', '0');
    tab.focus();
    
    // Show the associated panel
    const panelId = tab.getAttribute('aria-controls');
    const panel = document.getElementById(panelId);
    panel.hidden = false;
  }
</script>
```

### Dropdown Menus

```html
<div class="dropdown">
  <button id="dropdown-button" aria-haspopup="true" aria-expanded="false">
    User Menu
  </button>
  
  <ul id="dropdown-menu" role="menu" aria-labelledby="dropdown-button" hidden>
    <li role="none">
      <a href="/profile" role="menuitem">Profile</a>
    </li>
    <li role="none">
      <a href="/settings" role="menuitem">Settings</a>
    </li>
    <li role="none">
      <a href="/logout" role="menuitem">Logout</a>
    </li>
  </ul>
</div>

<script>
  const dropdownButton = document.getElementById('dropdown-button');
  const dropdownMenu = document.getElementById('dropdown-menu');
  const menuItems = dropdownMenu.querySelectorAll('[role="menuitem"]');
  
  // Toggle dropdown
  dropdownButton.addEventListener('click', () => {
    const expanded = dropdownButton.getAttribute('aria-expanded') === 'true';
    dropdownButton.setAttribute('aria-expanded', !expanded);
    dropdownMenu.hidden = expanded;
    
    // If opening the dropdown, focus the first menu item
    if (!expanded) {
      menuItems[0].focus();
    }
  });
  
  // Handle keyboard navigation
  dropdownMenu.addEventListener('keydown', e => {
    const menuItemsArray = Array.from(menuItems);
    const index = menuItemsArray.indexOf(document.activeElement);
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        // Move to next item, or first item if at the end
        const nextItem = menuItemsArray[(index + 1) % menuItemsArray.length];
        nextItem.focus();
        break;
      case 'ArrowUp':
        e.preventDefault();
        // Move to previous item, or last item if at the beginning
        const prevItem = menuItemsArray[(index - 1 + menuItemsArray.length) % menuItemsArray.length];
        prevItem.focus();
        break;
      case 'Home':
        e.preventDefault();
        // Move to first item
        menuItemsArray[0].focus();
        break;
      case 'End':
        e.preventDefault();
        // Move to last item
        menuItemsArray[menuItemsArray.length - 1].focus();
        break;
      case 'Escape':
        e.preventDefault();
        // Close dropdown and restore focus to button
        dropdownButton.setAttribute('aria-expanded', 'false');
        dropdownMenu.hidden = true;
        dropdownButton.focus();
        break;
      case 'Tab':
        // Close dropdown when tabbing out
        dropdownButton.setAttribute('aria-expanded', 'false');
        dropdownMenu.hidden = true;
        break;
    }
  });
  
  // Close dropdown when clicking outside
  document.addEventListener('click', e => {
    if (!dropdownButton.contains(e.target) && !dropdownMenu.contains(e.target)) {
      dropdownButton.setAttribute('aria-expanded', 'false');
      dropdownMenu.hidden = true;
    }
  });
</script>
```

## Testing Focus Management

To test focus management in your UME implementation:

1. **Navigate with keyboard only** (using Tab, Shift+Tab, arrow keys, Enter, and Escape) to ensure all interactive elements are accessible.

2. **Check focus visibility** to ensure all interactive elements have a visible focus indicator.

3. **Test focus order** to ensure elements receive focus in a logical order.

4. **Test focus trapping** in modal dialogs and other overlay components.

5. **Test focus restoration** when closing dialogs and other temporary UI elements.

6. **Test skip links** to ensure they work correctly.

For more detailed testing procedures, refer to the [Accessibility Testing](./080-testing-procedures.md) section.

## Common Focus Management Issues and Solutions

| Issue | Solution |
|-------|----------|
| Invisible focus indicators | Add clear, high-contrast focus styles |
| Illogical focus order | Ensure elements receive focus in a logical order |
| Focus not restored after dialog closes | Store and restore focus when opening/closing dialogs |
| Focus not trapped in modal dialogs | Implement focus trapping for modal dialogs |
| Focus lost after dynamic content changes | Manage focus explicitly when content changes |
| Skip links not working | Ensure skip links are properly implemented and visible on focus |

## Additional Resources

- [WebAIM: Keyboard Accessibility](https://webaim.org/techniques/keyboard/)
- [MDN: Focus Management](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Focus_management)
- [W3C: Managing Focus](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/#managingfocus)
- [Inclusive Components: Modal Dialogs](https://inclusive-components.design/a-modal-dialog/)
