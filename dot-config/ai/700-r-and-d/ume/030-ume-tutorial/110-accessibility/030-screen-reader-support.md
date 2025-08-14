# Screen Reader Support

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides best practices for making your UME implementation compatible with screen readers and other assistive technologies.

## Understanding Screen Readers

Screen readers are assistive technologies that convert digital text into synthesized speech or braille output. They allow users with visual impairments to access and interact with digital content.

Popular screen readers include:

- **NVDA** (NonVisual Desktop Access) - Free, open-source screen reader for Windows
- **JAWS** (Job Access With Speech) - Commercial screen reader for Windows
- **VoiceOver** - Built-in screen reader for Apple products (macOS, iOS)
- **TalkBack** - Built-in screen reader for Android devices
- **Orca** - Screen reader for Linux/GNOME

## Key Principles for Screen Reader Support

### 1. Semantic HTML

Use semantic HTML elements to provide structure and meaning to your content. Screen readers use these semantics to navigate and understand the page.

```html
<!-- Poor semantics -->
<div class="header">
  <div class="title">Page Title</div>
</div>
<div class="nav">
  <div class="nav-item"><div class="link">Home</div></div>
  <div class="nav-item"><div class="link">About</div></div>
</div>
<div class="main">
  <div class="section">
    <div class="section-title">Section Title</div>
    <div class="content">Content goes here...</div>
  </div>
</div>

<!-- Good semantics -->
<header>
  <h1>Page Title</h1>
</header>
<nav>
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
  </ul>
</nav>
<main>
  <section>
    <h2>Section Title</h2>
    <p>Content goes here...</p>
  </section>
</main>
```

### 2. Proper Heading Structure

Use heading elements (`<h1>` through `<h6>`) to create a logical document outline. Screen reader users often navigate by headings.

```html
<!-- Poor heading structure -->
<div class="title">Page Title</div>
<div class="subtitle">Subtitle</div>
<div class="section-title">Section 1</div>
<div class="subsection-title">Subsection 1.1</div>

<!-- Good heading structure -->
<h1>Page Title</h1>
<h2>Subtitle</h2>
<h2>Section 1</h2>
<h3>Subsection 1.1</h3>
```

### 3. Text Alternatives for Non-Text Content

Provide text alternatives for all non-text content, such as images, icons, and charts.

```html
<!-- Poor implementation -->
<img src="profile.jpg">
<i class="fa fa-edit"></i>

<!-- Good implementation -->
<img src="profile.jpg" alt="User profile photo">
<i class="fa fa-edit" aria-hidden="true"></i><span class="sr-only">Edit</span>
```

### 4. ARIA Landmarks

Use ARIA landmark roles to identify regions of the page. This helps screen reader users navigate more efficiently.

```html
<header role="banner">
  <h1>Site Title</h1>
</header>

<nav role="navigation">
  <!-- Navigation links -->
</nav>

<main role="main">
  <!-- Main content -->
</main>

<aside role="complementary">
  <!-- Sidebar content -->
</aside>

<footer role="contentinfo">
  <!-- Footer content -->
</footer>
```

### 5. Descriptive Link Text

Use descriptive link text that makes sense out of context. Screen reader users often navigate by jumping from link to link.

```html
<!-- Poor link text -->
<a href="/profile">Click here</a> to view your profile.

<!-- Good link text -->
<a href="/profile">View your profile</a>
```

### 6. Form Labels and Instructions

Ensure all form controls have associated labels and provide clear instructions.

```html
<!-- Poor form implementation -->
<input type="text" name="username">
<input type="password" name="password">

<!-- Good form implementation -->
<div>
  <label for="username">Username</label>
  <input type="text" id="username" name="username" aria-describedby="username-help">
  <div id="username-help">Enter your username or email address</div>
</div>

<div>
  <label for="password">Password</label>
  <input type="password" id="password" name="password" aria-describedby="password-help">
  <div id="password-help">Password must be at least 8 characters</div>
</div>
```

### 7. Live Regions

Use ARIA live regions to announce dynamic content changes, such as form validation messages or notifications.

```html
<div class="notification" aria-live="polite" role="status">
  <!-- Dynamic content will be inserted here -->
</div>

<script>
  function showNotification(message) {
    const notification = document.querySelector('.notification');
    notification.textContent = message;
    
    // Clear the notification after 5 seconds
    setTimeout(() => {
      notification.textContent = '';
    }, 5000);
  }
</script>
```

## Implementing Screen Reader Support in UME Components

### User Authentication Components

#### Login Form

```html
<form method="POST" action="/login">
    <div class="form-group">
        <label for="email">Email Address</label>
        <input type="email" id="email" name="email" required aria-describedby="email-help">
        <div id="email-help">Enter the email address associated with your account</div>
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
    
    <div aria-live="assertive" role="alert" class="error-container">
        <!-- Error messages will be inserted here -->
    </div>
</form>
```

#### Form Validation Errors

```javascript
function showValidationErrors(errors) {
  const errorContainer = document.querySelector('.error-container');
  
  // Clear previous errors
  errorContainer.innerHTML = '';
  
  if (Object.keys(errors).length > 0) {
    const errorList = document.createElement('ul');
    
    for (const field in errors) {
      const errorItem = document.createElement('li');
      errorItem.textContent = errors[field];
      errorList.appendChild(errorItem);
      
      // Also add aria-invalid to the field
      const fieldElement = document.getElementById(field);
      if (fieldElement) {
        fieldElement.setAttribute('aria-invalid', 'true');
        fieldElement.setAttribute('aria-describedby', `${field}-error`);
        
        // Add error message next to the field
        const fieldError = document.createElement('div');
        fieldError.id = `${field}-error`;
        fieldError.className = 'field-error';
        fieldError.textContent = errors[field];
        
        fieldElement.parentNode.appendChild(fieldError);
      }
    }
    
    errorContainer.appendChild(errorList);
  }
}
```

### User Profile Components

#### Profile Form with Tabs

```html
<div role="tablist" aria-label="Profile Settings">
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

### Team Management Components

#### Team Member List

```html
<section aria-labelledby="team-members-heading">
  <h2 id="team-members-heading">Team Members</h2>
  
  <table aria-label="Team members and their roles">
    <caption class="sr-only">Team Members</caption>
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
</section>
```

#### Team Invitation Modal

```html
<button id="invite-button" aria-haspopup="dialog">Invite Team Member</button>

<div id="invite-modal" role="dialog" aria-labelledby="modal-title" aria-describedby="modal-description" aria-modal="true" hidden>
  <div role="document">
    <header>
      <h2 id="modal-title">Invite Team Member</h2>
      <button aria-label="Close dialog" id="close-modal">×</button>
    </header>
    
    <div id="modal-description" class="sr-only">
      This dialog allows you to invite a new member to your team by entering their email address and selecting a role.
    </div>
    
    <form>
      <div class="form-group">
        <label for="invite-email">Email Address</label>
        <input type="email" id="invite-email" name="email" required>
      </div>
      
      <div class="form-group">
        <label for="invite-role">Role</label>
        <select id="invite-role" name="role">
          <option value="member">Member</option>
          <option value="admin">Admin</option>
        </select>
      </div>
      
      <div class="form-actions">
        <button type="button" id="cancel-invite">Cancel</button>
        <button type="submit">Send Invitation</button>
      </div>
    </form>
  </div>
</div>

<script>
  // Modal focus management
  const modal = document.getElementById('invite-modal');
  const openButton = document.getElementById('invite-button');
  const closeButton = document.getElementById('close-modal');
  const cancelButton = document.getElementById('cancel-invite');
  
  // Store the element that had focus before the modal was opened
  let previouslyFocusedElement;
  
  openButton.addEventListener('click', () => {
    // Store the currently focused element
    previouslyFocusedElement = document.activeElement;
    
    // Show the modal
    modal.hidden = false;
    
    // Focus the first focusable element in the modal
    const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    focusableElements[0].focus();
  });
  
  function closeModal() {
    // Hide the modal
    modal.hidden = true;
    
    // Restore focus to the element that had focus before the modal was opened
    if (previouslyFocusedElement) {
      previouslyFocusedElement.focus();
    }
  }
  
  closeButton.addEventListener('click', closeModal);
  cancelButton.addEventListener('click', closeModal);
</script>
```

## Testing Screen Reader Support

To test screen reader support in your UME implementation:

1. **Use a screen reader** to navigate through your application. Common screen readers include:
   - NVDA (Windows)
   - VoiceOver (macOS)
   - JAWS (Windows)
   - TalkBack (Android)

2. **Test common user flows** with the screen reader, such as:
   - User registration and login
   - Profile management
   - Team creation and management
   - Permission assignment

3. **Verify that all content is accessible** and properly announced by the screen reader.

4. **Check for proper focus management** when navigating with the keyboard.

For more detailed testing procedures, refer to the [Accessibility Testing](./080-testing-procedures.md) section.

## Common Screen Reader Issues and Solutions

| Issue | Solution |
|-------|----------|
| Missing alternative text | Add `alt` attributes to all images and meaningful icons |
| Improper heading structure | Use proper heading levels (`<h1>` through `<h6>`) in a logical hierarchy |
| Unlabeled form controls | Ensure all form controls have associated labels |
| Inaccessible custom controls | Use appropriate ARIA roles and attributes for custom controls |
| Dynamic content not announced | Use ARIA live regions for dynamic content changes |
| Complex widgets not accessible | Follow WAI-ARIA Authoring Practices for complex widgets |

## Additional Resources

- [WebAIM: Screen Reader User Survey](https://webaim.org/projects/screenreadersurvey9/)
- [The A11Y Project: Screen Reader Basics](https://www.a11yproject.com/posts/getting-started-with-nvda/)
- [MDN: ARIA](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
