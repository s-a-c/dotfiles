# Accessibility Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises are designed to test your understanding of accessibility principles and practices in the context of UME implementations. Each set contains questions and a practical exercise.

## Set 1: Understanding Accessibility Basics

### Questions

1. **What does WCAG stand for?**
   - A) Web Content Accessibility Guidelines
   - B) Web Compliance Accessibility Guide
   - C) Website Content Access Guidelines
   - D) Web Content Access Governance

2. **Which of the following is NOT one of the four main principles of WCAG?**
   - A) Perceivable
   - B) Operable
   - C) Understandable
   - D) Scalable

3. **What is the minimum contrast ratio required for normal text under WCAG AA standards?**
   - A) 3:1
   - B) 4.5:1
   - C) 7:1
   - D) 2:1

4. **Which of the following is an example of making content perceivable?**
   - A) Ensuring all functionality is available from a keyboard
   - B) Providing text alternatives for non-text content
   - C) Making web pages appear and operate in predictable ways
   - D) Maximizing compatibility with current and future user tools

5. **Why is it important to not rely solely on color to convey information?**
   - A) Colors can be distracting
   - B) Some users are color blind or have low vision
   - C) Colors may render differently across devices
   - D) Colors increase page load time

### Practical Exercise: Evaluating Accessibility

Evaluate the accessibility of the following login form code and identify at least three accessibility issues:

```html
<div class="login-form">
  <div class="form-title">Login</div>
  <div class="form-group">
    <input type="text" placeholder="Email" class="form-control">
  </div>
  <div class="form-group">
    <input type="password" placeholder="Password" class="form-control">
  </div>
  <div class="form-group">
    <input type="checkbox"> Remember me
  </div>
  <div class="form-actions">
    <div class="btn btn-primary" onclick="login()">Sign In</div>
  </div>
  <div class="form-links">
    <a href="#" style="color: #999;">Forgot password?</a>
  </div>
</div>
```

## Set 2: Keyboard Accessibility

### Questions

1. **Why is keyboard accessibility important?**
   - A) It's faster than using a mouse
   - B) It's required by law in all countries
   - C) Many users with disabilities rely on keyboard navigation
   - D) It reduces server load

2. **Which of the following elements is NOT keyboard accessible by default?**
   - A) `<button>`
   - B) `<a href="...">`
   - C) `<div onclick="...">`
   - D) `<input type="text">`

3. **What attribute can be used to make a non-interactive element focusable?**
   - A) `focus="true"`
   - B) `tabindex="0"`
   - C) `keyboard="accessible"`
   - D) `interactive="true"`

4. **What is a keyboard trap?**
   - A) A security feature that prevents keyboard input
   - B) A situation where keyboard focus cannot move away from an element
   - C) A special key combination that triggers an action
   - D) A feature that restricts certain keyboard shortcuts

5. **What is the purpose of a skip link?**
   - A) To skip the current page and go to the next page
   - B) To allow keyboard users to bypass repetitive navigation
   - C) To skip form validation
   - D) To skip loading certain resources for faster page loads

### Practical Exercise: Implementing Keyboard Accessibility

Improve the keyboard accessibility of the following dropdown menu:

```html
<div class="dropdown">
  <div class="dropdown-toggle" onclick="toggleDropdown()">
    User Menu <i class="fa fa-caret-down"></i>
  </div>
  <div class="dropdown-menu" style="display: none;">
    <div class="dropdown-item" onclick="goToProfile()">Profile</div>
    <div class="dropdown-item" onclick="goToSettings()">Settings</div>
    <div class="dropdown-item" onclick="logout()">Logout</div>
  </div>
</div>

<script>
  function toggleDropdown() {
    const menu = document.querySelector('.dropdown-menu');
    menu.style.display = menu.style.display === 'none' ? 'block' : 'none';
  }
  
  function goToProfile() {
    window.location.href = '/profile';
  }
  
  function goToSettings() {
    window.location.href = '/settings';
  }
  
  function logout() {
    // Logout logic
    alert('Logged out');
  }
</script>
```

## Set 3: Screen Reader Accessibility

### Questions

1. **Which of the following is NOT a commonly used screen reader?**
   - A) NVDA
   - B) JAWS
   - C) VoiceOver
   - D) ChromeSpeak

2. **What is the purpose of the `alt` attribute on an image?**
   - A) To provide alternative text for screen readers
   - B) To specify an alternative image if the primary image fails to load
   - C) To add keywords for search engine optimization
   - D) To provide a caption for the image

3. **What should be the value of the `alt` attribute for decorative images?**
   - A) "Decorative image"
   - B) A brief description of the image
   - C) An empty string (`alt=""`)
   - D) The filename of the image

4. **Which HTML element is best for creating a landmark that identifies the main content area?**
   - A) `<div id="main">`
   - B) `<section class="main">`
   - C) `<main>`
   - D) `<content>`

5. **What is an ARIA live region used for?**
   - A) To indicate that an element is currently being viewed
   - B) To announce dynamic content changes to screen reader users
   - C) To mark content that is updated frequently
   - D) To highlight important content

### Practical Exercise: Improving Screen Reader Accessibility

Improve the screen reader accessibility of the following notification component:

```html
<div class="notification">
  <div class="notification-icon">
    <i class="fa fa-check-circle"></i>
  </div>
  <div class="notification-content">
    Your changes have been saved successfully.
  </div>
  <div class="notification-close" onclick="closeNotification()">
    <i class="fa fa-times"></i>
  </div>
</div>

<script>
  function closeNotification() {
    document.querySelector('.notification').style.display = 'none';
  }
  
  function showNotification(message) {
    const notification = document.querySelector('.notification');
    notification.querySelector('.notification-content').textContent = message;
    notification.style.display = 'flex';
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      notification.style.display = 'none';
    }, 5000);
  }
</script>
```

## Set 4: Form Accessibility

### Questions

1. **What is the best way to associate a label with a form control?**
   - A) Place the label text next to the form control
   - B) Use the `label` attribute on the form control
   - C) Use the `<label>` element with a `for` attribute that matches the form control's `id`
   - D) Use the `aria-labelledby` attribute on the form control

2. **How should required form fields be indicated to users?**
   - A) Only with a red asterisk (*)
   - B) With the `required` attribute and a visual indicator with explanatory text
   - C) By making the field border red
   - D) By adding "(required)" to the placeholder text

3. **What is the purpose of the `aria-describedby` attribute on a form field?**
   - A) To provide a description of the form field to screen readers
   - B) To specify which element describes the form field's purpose or requirements
   - C) To link the form field to its label
   - D) To provide a tooltip when the user hovers over the field

4. **How should form validation errors be communicated to users?**
   - A) Only with red text
   - B) With a visual indicator, descriptive text, and programmatic association with the form field
   - C) By disabling the submit button until all errors are fixed
   - D) By showing a modal dialog with all errors

5. **What is the purpose of the `autocomplete` attribute on form fields?**
   - A) To automatically complete the form field with default values
   - B) To suggest values as the user types
   - C) To help browsers fill in form fields with the user's previously entered information
   - D) To validate the form field as the user types

### Practical Exercise: Creating an Accessible Form

Improve the accessibility of the following registration form:

```html
<div class="registration-form">
  <div class="form-title">Create an Account</div>
  
  <div class="form-group">
    <input type="text" placeholder="Full Name" class="form-control">
  </div>
  
  <div class="form-group">
    <input type="email" placeholder="Email Address" class="form-control">
  </div>
  
  <div class="form-group">
    <input type="password" placeholder="Password" class="form-control">
    <div class="form-hint">Password must be at least 8 characters</div>
  </div>
  
  <div class="form-group">
    <input type="password" placeholder="Confirm Password" class="form-control">
  </div>
  
  <div class="form-group">
    <input type="checkbox"> I agree to the Terms of Service
  </div>
  
  <div class="form-actions">
    <div class="btn btn-primary" onclick="register()">Register</div>
  </div>
</div>

<script>
  function register() {
    // Registration logic
    const name = document.querySelector('input[type="text"]').value;
    const email = document.querySelector('input[type="email"]').value;
    const password = document.querySelector('input[type="password"]').value;
    const confirmPassword = document.querySelectorAll('input[type="password"]')[1].value;
    const agreeToTerms = document.querySelector('input[type="checkbox"]').checked;
    
    // Validation
    let errors = [];
    
    if (!name) {
      errors.push('Name is required');
    }
    
    if (!email) {
      errors.push('Email is required');
    }
    
    if (!password) {
      errors.push('Password is required');
    } else if (password.length < 8) {
      errors.push('Password must be at least 8 characters');
    }
    
    if (password !== confirmPassword) {
      errors.push('Passwords do not match');
    }
    
    if (!agreeToTerms) {
      errors.push('You must agree to the Terms of Service');
    }
    
    if (errors.length > 0) {
      alert('Please fix the following errors:\n' + errors.join('\n'));
      return;
    }
    
    // Submit form
    alert('Registration successful!');
  }
</script>
```

## Set 5: ARIA Attributes

### Questions

1. **What does ARIA stand for?**
   - A) Accessible Rich Internet Applications
   - B) Advanced Responsive Interface Attributes
   - C) Automated Rendering of Interactive Assets
   - D) Accessible Rendering of Internet Applications

2. **What is the first rule of ARIA use?**
   - A) Always use ARIA attributes for better accessibility
   - B) Don't use ARIA if a native HTML element or attribute provides the functionality
   - C) Use ARIA only for interactive elements
   - D) ARIA should only be used for complex widgets

3. **Which ARIA attribute indicates that an element has a popup menu?**
   - A) `aria-popup="true"`
   - B) `aria-haspopup="true"`
   - C) `aria-controls="menu"`
   - D) `aria-expanded="true"`

4. **What is the purpose of the `role` attribute?**
   - A) To define the visual appearance of an element
   - B) To define what an element is or does
   - C) To define the behavior of an element
   - D) To define the importance of an element

5. **Which of the following is NOT a valid ARIA landmark role?**
   - A) `navigation`
   - B) `main`
   - C) `header`
   - D) `content`

### Practical Exercise: Implementing ARIA Attributes

Improve the accessibility of the following accordion component by adding appropriate ARIA attributes:

```html
<div class="accordion">
  <div class="accordion-item">
    <div class="accordion-header" onclick="toggleAccordion(0)">
      Section 1
    </div>
    <div class="accordion-content" style="display: none;">
      <p>This is the content for section 1.</p>
    </div>
  </div>
  
  <div class="accordion-item">
    <div class="accordion-header" onclick="toggleAccordion(1)">
      Section 2
    </div>
    <div class="accordion-content" style="display: none;">
      <p>This is the content for section 2.</p>
    </div>
  </div>
  
  <div class="accordion-item">
    <div class="accordion-header" onclick="toggleAccordion(2)">
      Section 3
    </div>
    <div class="accordion-content" style="display: none;">
      <p>This is the content for section 3.</p>
    </div>
  </div>
</div>

<script>
  function toggleAccordion(index) {
    const accordionItems = document.querySelectorAll('.accordion-item');
    const content = accordionItems[index].querySelector('.accordion-content');
    
    content.style.display = content.style.display === 'none' ? 'block' : 'none';
  }
</script>
```

## Additional Resources

- [WebAIM: Web Accessibility In Mind](https://webaim.org/)
- [MDN Web Docs: Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [The A11Y Project](https://www.a11yproject.com/)
- [W3C Web Accessibility Initiative (WAI)](https://www.w3.org/WAI/)
