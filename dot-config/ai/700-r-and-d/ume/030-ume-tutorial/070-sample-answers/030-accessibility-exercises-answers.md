# Accessibility Exercises - Sample Answers

<link rel="stylesheet" href="../assets/css/styles.css">

This document provides sample answers to the accessibility exercises.

## Set 1: Understanding Accessibility Basics

### Questions

1. **What does WCAG stand for?**
   - A) Web Content Accessibility Guidelines ✓
   - B) Web Compliance Accessibility Guide
   - C) Website Content Access Guidelines
   - D) Web Content Access Governance

2. **Which of the following is NOT one of the four main principles of WCAG?**
   - A) Perceivable
   - B) Operable
   - C) Understandable
   - D) Scalable ✓

   *Explanation: The four main principles of WCAG are Perceivable, Operable, Understandable, and Robust (POUR).*

3. **What is the minimum contrast ratio required for normal text under WCAG AA standards?**
   - A) 3:1
   - B) 4.5:1 ✓
   - C) 7:1
   - D) 2:1

   *Explanation: WCAG 2.1 Level AA requires a contrast ratio of at least 4.5:1 for normal text and 3:1 for large text.*

4. **Which of the following is an example of making content perceivable?**
   - A) Ensuring all functionality is available from a keyboard
   - B) Providing text alternatives for non-text content ✓
   - C) Making web pages appear and operate in predictable ways
   - D) Maximizing compatibility with current and future user tools

   *Explanation: Providing text alternatives for non-text content (like images) helps users who cannot see the images perceive the content through other means, such as screen readers.*

5. **Why is it important to not rely solely on color to convey information?**
   - A) Colors can be distracting
   - B) Some users are color blind or have low vision ✓
   - C) Colors may render differently across devices
   - D) Colors increase page load time

   *Explanation: About 8% of men and 0.5% of women have some form of color blindness, and users with low vision may have difficulty distinguishing certain colors.*

### Practical Exercise: Evaluating Accessibility

The login form has several accessibility issues:

1. **Missing proper heading structure**: The form title is using a div with a class instead of a proper heading element like `<h1>` or `<h2>`.

2. **Missing form labels**: The form inputs don't have associated labels, making it difficult for screen reader users to understand what information is required.

3. **Placeholder text used instead of labels**: Placeholders disappear when users start typing, which can cause confusion, especially for users with cognitive disabilities.

4. **Checkbox without a proper label**: The checkbox doesn't have a properly associated label.

5. **Using a div as a button**: The "Sign In" button is a div with an onclick handler instead of a proper `<button>` element, making it inaccessible to keyboard users.

6. **Poor color contrast**: The "Forgot password?" link has a color (#999) that likely doesn't provide sufficient contrast against the background.

Here's an improved version of the login form:

```html
<form class="login-form">
  <h2>Login</h2>
  
  <div class="form-group">
    <label for="email">Email</label>
    <input type="email" id="email" name="email" class="form-control" required>
  </div>
  
  <div class="form-group">
    <label for="password">Password</label>
    <input type="password" id="password" name="password" class="form-control" required>
  </div>
  
  <div class="form-group">
    <input type="checkbox" id="remember" name="remember">
    <label for="remember">Remember me</label>
  </div>
  
  <div class="form-actions">
    <button type="submit" class="btn btn-primary">Sign In</button>
  </div>
  
  <div class="form-links">
    <a href="/password/reset">Forgot password?</a>
  </div>
</form>
```

## Set 2: Keyboard Accessibility

### Questions

1. **Why is keyboard accessibility important?**
   - A) It's faster than using a mouse
   - B) It's required by law in all countries
   - C) Many users with disabilities rely on keyboard navigation ✓
   - D) It reduces server load

   *Explanation: Many users with motor disabilities, visual impairments, or other conditions cannot use a mouse and rely on keyboard navigation.*

2. **Which of the following elements is NOT keyboard accessible by default?**
   - A) `<button>`
   - B) `<a href="...">`
   - C) `<div onclick="...">` ✓
   - D) `<input type="text">`

   *Explanation: A div with an onclick handler is not keyboard accessible by default because it cannot receive keyboard focus and does not respond to keyboard events like Enter or Space.*

3. **What attribute can be used to make a non-interactive element focusable?**
   - A) `focus="true"`
   - B) `tabindex="0"` ✓
   - C) `keyboard="accessible"`
   - D) `interactive="true"`

   *Explanation: Adding `tabindex="0"` to an element makes it focusable in the natural tab order of the page.*

4. **What is a keyboard trap?**
   - A) A security feature that prevents keyboard input
   - B) A situation where keyboard focus cannot move away from an element ✓
   - C) A special key combination that triggers an action
   - D) A feature that restricts certain keyboard shortcuts

   *Explanation: A keyboard trap occurs when a user can navigate to an element using the keyboard but cannot move away from it using only the keyboard, effectively "trapping" them.*

5. **What is the purpose of a skip link?**
   - A) To skip the current page and go to the next page
   - B) To allow keyboard users to bypass repetitive navigation ✓
   - C) To skip form validation
   - D) To skip loading certain resources for faster page loads

   *Explanation: Skip links allow keyboard users to bypass repetitive navigation menus and jump directly to the main content, improving the user experience for keyboard-only users.*

### Practical Exercise: Implementing Keyboard Accessibility

Here's an improved version of the dropdown menu with keyboard accessibility:

```html
<div class="dropdown">
  <button class="dropdown-toggle" aria-haspopup="true" aria-expanded="false" onclick="toggleDropdown()">
    User Menu <i class="fa fa-caret-down" aria-hidden="true"></i>
  </button>
  <ul class="dropdown-menu" role="menu" aria-labelledby="dropdown-toggle" style="display: none;">
    <li role="none">
      <a href="/profile" role="menuitem" class="dropdown-item">Profile</a>
    </li>
    <li role="none">
      <a href="/settings" role="menuitem" class="dropdown-item">Settings</a>
    </li>
    <li role="none">
      <a href="/logout" role="menuitem" class="dropdown-item">Logout</a>
    </li>
  </ul>
</div>

<script>
  const dropdownToggle = document.querySelector('.dropdown-toggle');
  const dropdownMenu = document.querySelector('.dropdown-menu');
  const menuItems = dropdownMenu.querySelectorAll('[role="menuitem"]');
  
  function toggleDropdown() {
    const expanded = dropdownToggle.getAttribute('aria-expanded') === 'true';
    dropdownToggle.setAttribute('aria-expanded', !expanded);
    dropdownMenu.style.display = expanded ? 'none' : 'block';
    
    // If opening the dropdown, focus the first menu item
    if (!expanded) {
      menuItems[0].focus();
    }
  }
  
  // Add keyboard navigation for the dropdown
  dropdownMenu.addEventListener('keydown', function(e) {
    const currentIndex = Array.from(menuItems).indexOf(document.activeElement);
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        // Move to next item, or first item if at the end
        const nextIndex = (currentIndex + 1) % menuItems.length;
        menuItems[nextIndex].focus();
        break;
      case 'ArrowUp':
        e.preventDefault();
        // Move to previous item, or last item if at the beginning
        const prevIndex = (currentIndex - 1 + menuItems.length) % menuItems.length;
        menuItems[prevIndex].focus();
        break;
      case 'Escape':
        e.preventDefault();
        // Close dropdown and return focus to toggle button
        dropdownToggle.setAttribute('aria-expanded', 'false');
        dropdownMenu.style.display = 'none';
        dropdownToggle.focus();
        break;
      case 'Tab':
        // Close dropdown when tabbing out
        dropdownToggle.setAttribute('aria-expanded', 'false');
        dropdownMenu.style.display = 'none';
        break;
    }
  });
  
  // Close dropdown when clicking outside
  document.addEventListener('click', function(e) {
    if (!dropdownToggle.contains(e.target) && !dropdownMenu.contains(e.target)) {
      dropdownToggle.setAttribute('aria-expanded', 'false');
      dropdownMenu.style.display = 'none';
    }
  });
</script>
```

Key improvements:
1. Replaced the div with a proper `<button>` element for the dropdown toggle
2. Added ARIA attributes (`aria-haspopup`, `aria-expanded`) to indicate the button controls a popup menu
3. Changed the dropdown menu from a div to a semantic `<ul>` list with proper ARIA roles
4. Added keyboard navigation for the dropdown menu (arrow keys, Escape)
5. Added focus management to focus the first menu item when opening the dropdown
6. Used proper `<a>` elements for the menu items instead of divs with onclick handlers
7. Added event listener to close the dropdown when clicking outside

## Set 3: Screen Reader Accessibility

### Questions

1. **Which of the following is NOT a commonly used screen reader?**
   - A) NVDA
   - B) JAWS
   - C) VoiceOver
   - D) ChromeSpeak ✓

   *Explanation: ChromeSpeak is not a real screen reader. The commonly used screen readers are NVDA (Windows), JAWS (Windows), VoiceOver (macOS/iOS), and TalkBack (Android).*

2. **What is the purpose of the `alt` attribute on an image?**
   - A) To provide alternative text for screen readers ✓
   - B) To specify an alternative image if the primary image fails to load
   - C) To add keywords for search engine optimization
   - D) To provide a caption for the image

   *Explanation: The `alt` attribute provides a text alternative for images, which is read by screen readers to describe the image to users who cannot see it.*

3. **What should be the value of the `alt` attribute for decorative images?**
   - A) "Decorative image"
   - B) A brief description of the image
   - C) An empty string (`alt=""`) ✓
   - D) The filename of the image

   *Explanation: Decorative images that don't convey meaningful content should have an empty alt attribute (`alt=""`) to indicate to screen readers that they should be ignored.*

4. **Which HTML element is best for creating a landmark that identifies the main content area?**
   - A) `<div id="main">`
   - B) `<section class="main">`
   - C) `<main>` ✓
   - D) `<content>`

   *Explanation: The `<main>` element is specifically designed to identify the main content area of a page and is automatically recognized as a landmark by assistive technologies.*

5. **What is an ARIA live region used for?**
   - A) To indicate that an element is currently being viewed
   - B) To announce dynamic content changes to screen reader users ✓
   - C) To mark content that is updated frequently
   - D) To highlight important content

   *Explanation: ARIA live regions are used to announce dynamic content changes to screen reader users, such as notifications, alerts, or other content that updates without a page reload.*

### Practical Exercise: Improving Screen Reader Accessibility

Here's an improved version of the notification component with better screen reader accessibility:

```html
<div class="notification" role="status" aria-live="polite" hidden>
  <div class="notification-icon" aria-hidden="true">
    <i class="fa fa-check-circle"></i>
  </div>
  <div class="notification-content">
    Your changes have been saved successfully.
  </div>
  <button class="notification-close" aria-label="Close notification" onclick="closeNotification()">
    <i class="fa fa-times" aria-hidden="true"></i>
  </button>
</div>

<script>
  function closeNotification() {
    document.querySelector('.notification').hidden = true;
  }
  
  function showNotification(message) {
    const notification = document.querySelector('.notification');
    notification.querySelector('.notification-content').textContent = message;
    notification.hidden = false;
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      notification.hidden = true;
    }, 5000);
  }
</script>
```

Key improvements:
1. Added `role="status"` and `aria-live="polite"` to announce the notification to screen readers
2. Used the `hidden` attribute instead of `display: none` for better semantics
3. Added `aria-hidden="true"` to the icon to prevent it from being announced by screen readers
4. Changed the close button from a div to a proper `<button>` element
5. Added `aria-label="Close notification"` to the close button to provide a clear description for screen readers
6. Added `aria-hidden="true"` to the close icon to prevent it from being announced by screen readers

## Set 4: Form Accessibility

### Questions

1. **What is the best way to associate a label with a form control?**
   - A) Place the label text next to the form control
   - B) Use the `label` attribute on the form control
   - C) Use the `<label>` element with a `for` attribute that matches the form control's `id` ✓
   - D) Use the `aria-labelledby` attribute on the form control

   *Explanation: Using a `<label>` element with a `for` attribute that matches the form control's `id` is the most robust way to associate a label with a form control, as it provides both visual and programmatic association.*

2. **How should required form fields be indicated to users?**
   - A) Only with a red asterisk (*)
   - B) With the `required` attribute and a visual indicator with explanatory text ✓
   - C) By making the field border red
   - D) By adding "(required)" to the placeholder text

   *Explanation: Required fields should be indicated with the `required` attribute for programmatic association and a visual indicator (like an asterisk) with explanatory text that explains what the indicator means.*

3. **What is the purpose of the `aria-describedby` attribute on a form field?**
   - A) To provide a description of the form field to screen readers
   - B) To specify which element describes the form field's purpose or requirements ✓
   - C) To link the form field to its label
   - D) To provide a tooltip when the user hovers over the field

   *Explanation: The `aria-describedby` attribute specifies the ID of an element that provides additional description for the form field, such as validation requirements or error messages.*

4. **How should form validation errors be communicated to users?**
   - A) Only with red text
   - B) With a visual indicator, descriptive text, and programmatic association with the form field ✓
   - C) By disabling the submit button until all errors are fixed
   - D) By showing a modal dialog with all errors

   *Explanation: Form validation errors should be communicated with a visual indicator (like a red border), descriptive error text, and programmatic association with the form field (using `aria-describedby` or `aria-errormessage`).*

5. **What is the purpose of the `autocomplete` attribute on form fields?**
   - A) To automatically complete the form field with default values
   - B) To suggest values as the user types
   - C) To help browsers fill in form fields with the user's previously entered information ✓
   - D) To validate the form field as the user types

   *Explanation: The `autocomplete` attribute helps browsers fill in form fields with the user's previously entered information, making it easier for users to complete forms, especially those with cognitive or motor disabilities.*

### Practical Exercise: Creating an Accessible Form

Here's an improved version of the registration form with better accessibility:

```html
<form class="registration-form">
  <h2>Create an Account</h2>
  
  <div class="form-group">
    <label for="full-name">Full Name</label>
    <input type="text" id="full-name" name="full-name" class="form-control" required aria-describedby="full-name-error">
    <div id="full-name-error" class="form-error" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="email">Email Address</label>
    <input type="email" id="email" name="email" class="form-control" required aria-describedby="email-error">
    <div id="email-error" class="form-error" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="password">Password</label>
    <input type="password" id="password" name="password" class="form-control" required aria-describedby="password-hint password-error">
    <div id="password-hint" class="form-hint">Password must be at least 8 characters</div>
    <div id="password-error" class="form-error" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="confirm-password">Confirm Password</label>
    <input type="password" id="confirm-password" name="confirm-password" class="form-control" required aria-describedby="confirm-password-error">
    <div id="confirm-password-error" class="form-error" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <input type="checkbox" id="terms" name="terms" required aria-describedby="terms-error">
    <label for="terms">I agree to the <a href="/terms">Terms of Service</a></label>
    <div id="terms-error" class="form-error" role="alert" hidden></div>
  </div>
  
  <div class="form-actions">
    <button type="submit" class="btn btn-primary">Register</button>
  </div>
  
  <div id="form-errors-summary" class="form-errors-summary" role="alert" hidden></div>
</form>

<script>
  const form = document.querySelector('form');
  const fullNameInput = document.getElementById('full-name');
  const emailInput = document.getElementById('email');
  const passwordInput = document.getElementById('password');
  const confirmPasswordInput = document.getElementById('confirm-password');
  const termsCheckbox = document.getElementById('terms');
  const formErrorsSummary = document.getElementById('form-errors-summary');
  
  form.addEventListener('submit', function(e) {
    e.preventDefault();
    
    // Reset previous errors
    clearErrors();
    
    // Validate form
    let errors = {};
    
    if (!fullNameInput.value.trim()) {
      errors.fullName = 'Name is required';
      showError('full-name', 'Name is required');
    }
    
    if (!emailInput.value.trim()) {
      errors.email = 'Email is required';
      showError('email', 'Email is required');
    } else if (!isValidEmail(emailInput.value)) {
      errors.email = 'Please enter a valid email address';
      showError('email', 'Please enter a valid email address');
    }
    
    if (!passwordInput.value) {
      errors.password = 'Password is required';
      showError('password', 'Password is required');
    } else if (passwordInput.value.length < 8) {
      errors.password = 'Password must be at least 8 characters';
      showError('password', 'Password must be at least 8 characters');
    }
    
    if (passwordInput.value !== confirmPasswordInput.value) {
      errors.confirmPassword = 'Passwords do not match';
      showError('confirm-password', 'Passwords do not match');
    }
    
    if (!termsCheckbox.checked) {
      errors.terms = 'You must agree to the Terms of Service';
      showError('terms', 'You must agree to the Terms of Service');
    }
    
    // If there are errors, show summary and return
    if (Object.keys(errors).length > 0) {
      showErrorSummary(errors);
      return;
    }
    
    // Submit form
    alert('Registration successful!');
  });
  
  function showError(fieldId, message) {
    const field = document.getElementById(fieldId);
    const errorElement = document.getElementById(`${fieldId}-error`);
    
    field.setAttribute('aria-invalid', 'true');
    errorElement.textContent = message;
    errorElement.hidden = false;
  }
  
  function clearErrors() {
    const errorElements = document.querySelectorAll('.form-error');
    const formFields = document.querySelectorAll('input');
    
    errorElements.forEach(element => {
      element.textContent = '';
      element.hidden = true;
    });
    
    formFields.forEach(field => {
      field.setAttribute('aria-invalid', 'false');
    });
    
    formErrorsSummary.textContent = '';
    formErrorsSummary.hidden = true;
  }
  
  function showErrorSummary(errors) {
    const errorsList = document.createElement('ul');
    
    for (const field in errors) {
      const errorItem = document.createElement('li');
      errorItem.textContent = errors[field];
      errorsList.appendChild(errorItem);
    }
    
    formErrorsSummary.innerHTML = '<h3>Please fix the following errors:</h3>';
    formErrorsSummary.appendChild(errorsList);
    formErrorsSummary.hidden = false;
    formErrorsSummary.focus();
  }
  
  function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
</script>

<style>
  .form-error {
    color: #dc2626;
    font-size: 0.875rem;
    margin-top: 0.25rem;
  }
  
  input[aria-invalid="true"] {
    border-color: #dc2626;
  }
  
  .form-errors-summary {
    margin-top: 1rem;
    padding: 1rem;
    border: 1px solid #dc2626;
    background-color: #fee2e2;
    border-radius: 0.25rem;
  }
  
  .form-errors-summary h3 {
    margin-top: 0;
    font-size: 1rem;
    color: #dc2626;
  }
  
  .form-errors-summary ul {
    margin-bottom: 0;
  }
</style>
```

Key improvements:
1. Added proper form element with submit event listener
2. Added proper labels for all form fields
3. Added `required` attribute to required fields
4. Added `aria-describedby` to associate form fields with their error messages
5. Added `role="alert"` to error messages to announce them to screen readers
6. Added `aria-invalid` attribute to indicate invalid form fields
7. Added error summary for screen reader users
8. Used proper button element for the submit button
9. Added focus management to focus the error summary when errors occur
10. Added visual styling for error states

## Set 5: ARIA Attributes

### Questions

1. **What does ARIA stand for?**
   - A) Accessible Rich Internet Applications ✓
   - B) Advanced Responsive Interface Attributes
   - C) Automated Rendering of Interactive Assets
   - D) Accessible Rendering of Internet Applications

   *Explanation: ARIA stands for Accessible Rich Internet Applications, which is a set of attributes that define ways to make web content and web applications more accessible to people with disabilities.*

2. **What is the first rule of ARIA use?**
   - A) Always use ARIA attributes for better accessibility
   - B) Don't use ARIA if a native HTML element or attribute provides the functionality ✓
   - C) Use ARIA only for interactive elements
   - D) ARIA should only be used for complex widgets

   *Explanation: The first rule of ARIA use is: "If you can use a native HTML element or attribute with the semantics and behavior you require, then do so." Only use ARIA when native HTML cannot provide the semantics or behavior you need.*

3. **Which ARIA attribute indicates that an element has a popup menu?**
   - A) `aria-popup="true"`
   - B) `aria-haspopup="true"` ✓
   - C) `aria-controls="menu"`
   - D) `aria-expanded="true"`

   *Explanation: The `aria-haspopup="true"` attribute indicates that the element has a popup menu, such as a dropdown menu or dialog.*

4. **What is the purpose of the `role` attribute?**
   - A) To define the visual appearance of an element
   - B) To define what an element is or does ✓
   - C) To define the behavior of an element
   - D) To define the importance of an element

   *Explanation: The `role` attribute defines what an element is or does, helping assistive technologies understand the purpose of an element when the HTML semantics are not sufficient.*

5. **Which of the following is NOT a valid ARIA landmark role?**
   - A) `navigation`
   - B) `main`
   - C) `header`
   - D) `content` ✓

   *Explanation: `content` is not a valid ARIA landmark role. The valid landmark roles include `banner`, `complementary`, `contentinfo`, `form`, `main`, `navigation`, `region`, and `search`.*

### Practical Exercise: Implementing ARIA Attributes

Here's an improved version of the accordion component with appropriate ARIA attributes:

```html
<div class="accordion">
  <div class="accordion-item">
    <h3>
      <button class="accordion-header" id="accordion1-header" aria-expanded="false" aria-controls="accordion1-panel" onclick="toggleAccordion(0)">
        Section 1
      </button>
    </h3>
    <div id="accordion1-panel" class="accordion-content" role="region" aria-labelledby="accordion1-header" hidden>
      <p>This is the content for section 1.</p>
    </div>
  </div>
  
  <div class="accordion-item">
    <h3>
      <button class="accordion-header" id="accordion2-header" aria-expanded="false" aria-controls="accordion2-panel" onclick="toggleAccordion(1)">
        Section 2
      </button>
    </h3>
    <div id="accordion2-panel" class="accordion-content" role="region" aria-labelledby="accordion2-header" hidden>
      <p>This is the content for section 2.</p>
    </div>
  </div>
  
  <div class="accordion-item">
    <h3>
      <button class="accordion-header" id="accordion3-header" aria-expanded="false" aria-controls="accordion3-panel" onclick="toggleAccordion(2)">
        Section 3
      </button>
    </h3>
    <div id="accordion3-panel" class="accordion-content" role="region" aria-labelledby="accordion3-header" hidden>
      <p>This is the content for section 3.</p>
    </div>
  </div>
</div>

<script>
  function toggleAccordion(index) {
    const accordionItems = document.querySelectorAll('.accordion-item');
    const header = accordionItems[index].querySelector('.accordion-header');
    const content = accordionItems[index].querySelector('.accordion-content');
    const expanded = header.getAttribute('aria-expanded') === 'true';
    
    // Toggle expanded state
    header.setAttribute('aria-expanded', !expanded);
    content.hidden = expanded;
  }
  
  // Add keyboard support
  document.querySelectorAll('.accordion-header').forEach(header => {
    header.addEventListener('keydown', function(e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.click();
      }
    });
  });
</script>

<style>
  .accordion-item {
    margin-bottom: 0.5rem;
  }
  
  .accordion-header {
    width: 100%;
    text-align: left;
    padding: 0.75rem;
    background-color: #f3f4f6;
    border: none;
    border-radius: 0.25rem;
    font-size: 1rem;
    font-weight: bold;
    cursor: pointer;
  }
  
  .accordion-header:hover {
    background-color: #e5e7eb;
  }
  
  .accordion-header:focus {
    outline: 2px solid #4f46e5;
    outline-offset: 2px;
  }
  
  .accordion-content {
    padding: 1rem;
    border: 1px solid #e5e7eb;
    border-top: none;
    border-radius: 0 0 0.25rem 0.25rem;
  }
  
  /* Add visual indicator for expanded state */
  .accordion-header::after {
    content: '+';
    float: right;
  }
  
  .accordion-header[aria-expanded="true"]::after {
    content: '-';
  }
</style>
```

Key improvements:
1. Used proper heading elements (`<h3>`) for accordion headers
2. Used proper button elements for accordion triggers
3. Added `aria-expanded` attribute to indicate the expanded/collapsed state
4. Added `aria-controls` to associate the button with the panel it controls
5. Added `id` attributes to the headers and panels
6. Added `role="region"` to the panels
7. Added `aria-labelledby` to associate the panels with their headers
8. Used the `hidden` attribute instead of `display: none`
9. Added keyboard support for Enter and Space keys
10. Added visual indicator for the expanded state
11. Added focus styles for keyboard users
