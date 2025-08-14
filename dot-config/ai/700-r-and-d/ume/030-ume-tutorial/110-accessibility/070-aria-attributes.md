# ARIA Attributes Guide

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides a comprehensive overview of ARIA (Accessible Rich Internet Applications) attributes and how to use them in your UME implementation to enhance accessibility.

## What is ARIA?

ARIA (Accessible Rich Internet Applications) is a set of attributes that define ways to make web content and web applications more accessible to people with disabilities. These attributes supplement HTML to provide additional semantics and improve accessibility where standard HTML might be insufficient.

ARIA attributes do not change the functionality or appearance of an element for users without disabilities, but they provide additional information to assistive technologies like screen readers.

## When to Use ARIA

The first rule of ARIA is: **If you can use a native HTML element or attribute with the semantics and behavior you require, then do so.** Only use ARIA when native HTML cannot provide the semantics or behavior you need.

```html
<!-- Instead of this -->
<div role="button" tabindex="0" onclick="doSomething()">Click me</div>

<!-- Use this -->
<button onclick="doSomething()">Click me</button>
```

## Key ARIA Concepts

### 1. Roles

ARIA roles define what an element is or does. They help assistive technologies understand the purpose of an element.

```html
<div role="navigation">
  <!-- Navigation links -->
</div>

<div role="search">
  <!-- Search form -->
</div>

<div role="main">
  <!-- Main content -->
</div>
```

### 2. Properties

ARIA properties provide additional information about an element's state or characteristics. They are typically static and do not change.

```html
<button aria-haspopup="true" aria-controls="menu1">Menu</button>
<ul id="menu1" role="menu" aria-labelledby="menu-button">
  <!-- Menu items -->
</ul>
```

### 3. States

ARIA states describe the current condition of an element. Unlike properties, states can change as the user interacts with the element.

```html
<button aria-expanded="false" aria-controls="content1">Show more</button>
<div id="content1" hidden>
  <!-- Content that will be shown/hidden -->
</div>
```

## Common ARIA Attributes

### Labeling and Describing Elements

#### `aria-label`

Provides a label for an element when the visible text is not sufficient.

```html
<button aria-label="Close dialog">×</button>
```

#### `aria-labelledby`

References another element that serves as the label for the current element.

```html
<h2 id="section-heading">User Settings</h2>
<div role="region" aria-labelledby="section-heading">
  <!-- Content -->
</div>
```

#### `aria-describedby`

References another element that provides additional description for the current element.

```html
<input type="text" id="username" aria-describedby="username-help">
<div id="username-help">Username must be at least 5 characters</div>
```

### Structural Roles

#### `role="navigation"`

Identifies a major navigation block.

```html
<nav role="navigation">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</nav>
```

#### `role="main"`

Identifies the main content area.

```html
<main role="main">
  <!-- Main content -->
</main>
```

#### `role="complementary"`

Identifies content that is complementary to the main content.

```html
<aside role="complementary">
  <!-- Sidebar content -->
</aside>
```

#### `role="banner"`

Identifies the site banner or header.

```html
<header role="banner">
  <!-- Site header content -->
</header>
```

#### `role="contentinfo"`

Identifies information about the content, typically the footer.

```html
<footer role="contentinfo">
  <!-- Footer content -->
</footer>
```

### Interactive Element Roles

#### `role="button"`

Identifies an element as a button. Use a native `<button>` element when possible.

```html
<div role="button" tabindex="0" onclick="doSomething()" onkeydown="handleKeydown(event)">
  Click me
</div>
```

#### `role="tablist"`, `role="tab"`, and `role="tabpanel"`

Identifies elements in a tabbed interface.

```html
<div role="tablist" aria-label="User Settings">
  <button id="tab1" role="tab" aria-selected="true" aria-controls="panel1">
    Profile
  </button>
  <button id="tab2" role="tab" aria-selected="false" aria-controls="panel2">
    Preferences
  </button>
</div>

<div id="panel1" role="tabpanel" aria-labelledby="tab1">
  <!-- Profile content -->
</div>

<div id="panel2" role="tabpanel" aria-labelledby="tab2" hidden>
  <!-- Preferences content -->
</div>
```

#### `role="menu"`, `role="menuitem"`, `role="menubar"`

Identifies elements in a menu.

```html
<div role="menubar">
  <div role="menuitem" tabindex="0">File</div>
  <div role="menuitem" tabindex="-1">Edit</div>
  <div role="menuitem" tabindex="-1">View</div>
</div>
```

### State and Property Attributes

#### `aria-expanded`

Indicates whether a collapsible element is expanded or collapsed.

```html
<button aria-expanded="false" aria-controls="content1">Show more</button>
<div id="content1" hidden>
  <!-- Content that will be shown/hidden -->
</div>
```

#### `aria-hidden`

Hides an element from assistive technologies.

```html
<div aria-hidden="true">
  <!-- This content will be hidden from screen readers -->
</div>
```

#### `aria-disabled`

Indicates that an element is disabled.

```html
<button aria-disabled="true">Submit</button>
```

#### `aria-invalid`

Indicates that the value of an input is invalid.

```html
<input type="email" aria-invalid="true" aria-describedby="email-error">
<div id="email-error">Please enter a valid email address</div>
```

#### `aria-required`

Indicates that an input is required.

```html
<input type="text" aria-required="true">
```

### Live Region Attributes

#### `aria-live`

Indicates that an element will be updated dynamically.

```html
<div aria-live="polite">
  <!-- Content that will be updated dynamically -->
</div>
```

Values for `aria-live`:
- `off`: Updates are not announced (default)
- `polite`: Updates are announced when the user is idle
- `assertive`: Updates are announced immediately

#### `aria-atomic`

Indicates whether the entire region should be announced when it changes.

```html
<div aria-live="polite" aria-atomic="true">
  <!-- When this content changes, the entire content will be announced -->
</div>
```

#### `role="status"`

A live region with `aria-live="polite"` and `aria-atomic="true"`.

```html
<div role="status">
  <!-- Status messages -->
</div>
```

#### `role="alert"`

A live region with `aria-live="assertive"` and `aria-atomic="true"`.

```html
<div role="alert">
  <!-- Alert messages -->
</div>
```

## Implementing ARIA in UME Components

### Modal Dialog

```html
<button id="open-modal" aria-haspopup="dialog">Open Modal</button>

<div id="modal" role="dialog" aria-labelledby="modal-title" aria-describedby="modal-description" aria-modal="true" hidden>
  <div role="document">
    <header>
      <h2 id="modal-title">Modal Title</h2>
      <button id="close-modal" aria-label="Close modal">×</button>
    </header>
    
    <div id="modal-description" class="sr-only">
      This dialog allows you to configure your settings.
    </div>
    
    <div class="modal-content">
      <!-- Modal content -->
    </div>
    
    <footer>
      <button id="cancel">Cancel</button>
      <button id="save">Save</button>
    </footer>
  </div>
</div>
```

### Tabs

```html
<div role="tablist" aria-label="User Settings">
  <button id="tab1" role="tab" aria-selected="true" aria-controls="panel1" tabindex="0">
    Profile
  </button>
  <button id="tab2" role="tab" aria-selected="false" aria-controls="panel2" tabindex="-1">
    Preferences
  </button>
  <button id="tab3" role="tab" aria-selected="false" aria-controls="panel3" tabindex="-1">
    Security
  </button>
</div>

<div id="panel1" role="tabpanel" aria-labelledby="tab1" tabindex="0">
  <!-- Profile content -->
</div>

<div id="panel2" role="tabpanel" aria-labelledby="tab2" tabindex="0" hidden>
  <!-- Preferences content -->
</div>

<div id="panel3" role="tabpanel" aria-labelledby="tab3" tabindex="0" hidden>
  <!-- Security content -->
</div>

<script>
  const tabs = document.querySelectorAll('[role="tab"]');
  const panels = document.querySelectorAll('[role="tabpanel"]');
  
  tabs.forEach(tab => {
    tab.addEventListener('click', changeTabs);
    tab.addEventListener('keydown', handleTabKeydown);
  });
  
  function changeTabs(e) {
    const selectedTab = e.currentTarget;
    const selectedPanel = document.getElementById(selectedTab.getAttribute('aria-controls'));
    
    // Hide all panels
    panels.forEach(panel => {
      panel.hidden = true;
    });
    
    // Deselect all tabs
    tabs.forEach(tab => {
      tab.setAttribute('aria-selected', 'false');
      tab.tabIndex = -1;
    });
    
    // Select the clicked tab
    selectedTab.setAttribute('aria-selected', 'true');
    selectedTab.tabIndex = 0;
    
    // Show the selected panel
    selectedPanel.hidden = false;
  }
  
  function handleTabKeydown(e) {
    const tabsArray = Array.from(tabs);
    const index = tabsArray.indexOf(e.currentTarget);
    
    // Handle arrow keys
    switch (e.key) {
      case 'ArrowRight':
        e.preventDefault();
        const nextTab = tabsArray[(index + 1) % tabsArray.length];
        nextTab.focus();
        nextTab.click();
        break;
      case 'ArrowLeft':
        e.preventDefault();
        const prevTab = tabsArray[(index - 1 + tabsArray.length) % tabsArray.length];
        prevTab.focus();
        prevTab.click();
        break;
      case 'Home':
        e.preventDefault();
        tabsArray[0].focus();
        tabsArray[0].click();
        break;
      case 'End':
        e.preventDefault();
        tabsArray[tabsArray.length - 1].focus();
        tabsArray[tabsArray.length - 1].click();
        break;
    }
  }
</script>
```

### Accordion

```html
<div class="accordion">
  <h3>
    <button id="accordion1-trigger" aria-expanded="false" aria-controls="accordion1-panel">
      Section 1
    </button>
  </h3>
  <div id="accordion1-panel" role="region" aria-labelledby="accordion1-trigger" hidden>
    <!-- Section 1 content -->
  </div>
  
  <h3>
    <button id="accordion2-trigger" aria-expanded="false" aria-controls="accordion2-panel">
      Section 2
    </button>
  </h3>
  <div id="accordion2-panel" role="region" aria-labelledby="accordion2-trigger" hidden>
    <!-- Section 2 content -->
  </div>
  
  <h3>
    <button id="accordion3-trigger" aria-expanded="false" aria-controls="accordion3-panel">
      Section 3
    </button>
  </h3>
  <div id="accordion3-panel" role="region" aria-labelledby="accordion3-trigger" hidden>
    <!-- Section 3 content -->
  </div>
</div>

<script>
  const accordionTriggers = document.querySelectorAll('.accordion button');
  
  accordionTriggers.forEach(trigger => {
    trigger.addEventListener('click', toggleAccordion);
  });
  
  function toggleAccordion(e) {
    const trigger = e.currentTarget;
    const expanded = trigger.getAttribute('aria-expanded') === 'true';
    const panelId = trigger.getAttribute('aria-controls');
    const panel = document.getElementById(panelId);
    
    trigger.setAttribute('aria-expanded', !expanded);
    panel.hidden = expanded;
  }
</script>
```

### Form with Validation

```html
<form>
  <div class="form-group">
    <label for="name">Name</label>
    <input type="text" id="name" name="name" aria-required="true" aria-describedby="name-error">
    <div id="name-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="email">Email</label>
    <input type="email" id="email" name="email" aria-required="true" aria-describedby="email-error">
    <div id="email-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <button type="submit">Submit</button>
</form>

<script>
  const form = document.querySelector('form');
  const nameInput = document.getElementById('name');
  const emailInput = document.getElementById('email');
  
  form.addEventListener('submit', validateForm);
  
  function validateForm(e) {
    let valid = true;
    
    // Validate name
    if (nameInput.value.trim() === '') {
      showError(nameInput, 'name-error', 'Name is required');
      valid = false;
    } else {
      hideError(nameInput, 'name-error');
    }
    
    // Validate email
    if (emailInput.value.trim() === '') {
      showError(emailInput, 'email-error', 'Email is required');
      valid = false;
    } else if (!isValidEmail(emailInput.value)) {
      showError(emailInput, 'email-error', 'Please enter a valid email address');
      valid = false;
    } else {
      hideError(emailInput, 'email-error');
    }
    
    if (!valid) {
      e.preventDefault();
    }
  }
  
  function showError(input, errorId, message) {
    const errorElement = document.getElementById(errorId);
    input.setAttribute('aria-invalid', 'true');
    errorElement.textContent = message;
    errorElement.hidden = false;
  }
  
  function hideError(input, errorId) {
    const errorElement = document.getElementById(errorId);
    input.setAttribute('aria-invalid', 'false');
    errorElement.hidden = true;
  }
  
  function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
</script>
```

### Notifications

```html
<div id="notification-area" role="status" aria-live="polite"></div>

<button onclick="showNotification('Your changes have been saved.')">Save</button>

<script>
  function showNotification(message) {
    const notificationArea = document.getElementById('notification-area');
    notificationArea.textContent = message;
    
    // Clear the notification after 5 seconds
    setTimeout(() => {
      notificationArea.textContent = '';
    }, 5000);
  }
</script>
```

## ARIA Best Practices

### 1. Use ARIA Sparingly

Only use ARIA when necessary. If a native HTML element or attribute provides the semantics you need, use that instead.

### 2. Ensure ARIA Attributes are Accurate

Ensure that ARIA attributes accurately reflect the state and purpose of elements. Incorrect ARIA can be worse than no ARIA.

### 3. Keep ARIA Attributes Updated

When the state of an element changes, update the relevant ARIA attributes to reflect the new state.

```javascript
function toggleMenu() {
  const menuButton = document.getElementById('menu-button');
  const menu = document.getElementById('menu');
  const expanded = menuButton.getAttribute('aria-expanded') === 'true';
  
  menuButton.setAttribute('aria-expanded', !expanded);
  menu.hidden = expanded;
}
```

### 4. Test with Assistive Technologies

Test your ARIA implementation with screen readers and other assistive technologies to ensure it works as expected.

### 5. Follow WAI-ARIA Authoring Practices

The [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/) provide detailed guidance on implementing ARIA for various UI patterns.

## Testing ARIA Implementation

To test your ARIA implementation:

1. **Use screen readers** to navigate through your application and ensure that all elements are properly announced.

2. **Check ARIA validity** using tools like [ARC Toolkit](https://www.paciellogroup.com/toolkit/) or [axe DevTools](https://www.deque.com/axe/).

3. **Test keyboard navigation** to ensure that all interactive elements are accessible via keyboard.

4. **Verify dynamic updates** to ensure that changes to content are properly announced to screen reader users.

For more detailed testing procedures, refer to the [Accessibility Testing](./080-testing-procedures.md) section.

## Common ARIA Issues and Solutions

| Issue | Solution |
|-------|----------|
| Redundant ARIA | Remove unnecessary ARIA attributes |
| Incorrect ARIA roles | Use the appropriate role for each element |
| Missing required attributes | Add required attributes for each role |
| Inconsistent states | Keep ARIA states updated when element states change |
| Overriding native semantics | Use native HTML elements when possible |

## Additional Resources

- [WAI-ARIA Overview](https://www.w3.org/WAI/standards-guidelines/aria/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [MDN: ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA)
- [WebAIM: ARIA](https://webaim.org/techniques/aria/)
