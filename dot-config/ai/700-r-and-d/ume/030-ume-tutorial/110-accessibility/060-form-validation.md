# Accessible Form Validation

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides best practices for implementing accessible form validation in your UME implementation, ensuring that all users can understand and correct form errors.

## Why Accessible Form Validation Matters

Accessible form validation is essential for ensuring that all users, including those with disabilities, can successfully complete forms. This includes:

- Clearly identifying errors
- Providing helpful error messages
- Offering suggestions for correction
- Ensuring errors are perceivable by all users, including screen reader users

Implementing accessible form validation is required for WCAG compliance (Success Criteria 3.3.1 Error Identification, 3.3.2 Labels or Instructions, and 3.3.3 Error Suggestion).

## Key Principles

### 1. Clear Error Identification

Errors should be clearly identified both visually and programmatically.

```html
<div class="form-group">
  <label for="email">Email Address</label>
  <input type="email" id="email" name="email" aria-describedby="email-error" aria-invalid="true">
  <div id="email-error" class="error-message" role="alert">
    Please enter a valid email address
  </div>
</div>
```

```css
.form-group {
  margin-bottom: 1rem;
}

input[aria-invalid="true"] {
  border-color: #dc2626; /* Red */
  background-image: url('error-icon.svg');
  background-repeat: no-repeat;
  background-position: right 0.5rem center;
  padding-right: 2.5rem;
}

.error-message {
  color: #dc2626; /* Red */
  font-size: 0.875rem;
  margin-top: 0.25rem;
}
```

### 2. Descriptive Error Messages

Error messages should be clear, specific, and helpful.

```html
<!-- Poor error message -->
<div id="password-error" class="error-message">Invalid password</div>

<!-- Good error message -->
<div id="password-error" class="error-message">
  Password must be at least 8 characters and include at least one uppercase letter, one lowercase letter, and one number
</div>
```

### 3. Error Summary

For forms with multiple fields, provide an error summary at the top of the form.

```html
<form>
  <div id="error-summary" class="error-summary" role="alert" aria-labelledby="error-heading" hidden>
    <h2 id="error-heading">Please correct the following errors:</h2>
    <ul id="error-list">
      <!-- Error list items will be added dynamically -->
    </ul>
  </div>
  
  <!-- Form fields -->
</form>
```

```javascript
function showErrorSummary(errors) {
  const errorSummary = document.getElementById('error-summary');
  const errorList = document.getElementById('error-list');
  
  // Clear previous errors
  errorList.innerHTML = '';
  
  // Add new errors
  for (const field in errors) {
    const errorItem = document.createElement('li');
    const errorLink = document.createElement('a');
    
    errorLink.href = `#${field}`;
    errorLink.textContent = errors[field];
    errorLink.addEventListener('click', (e) => {
      e.preventDefault();
      document.getElementById(field).focus();
    });
    
    errorItem.appendChild(errorLink);
    errorList.appendChild(errorItem);
  }
  
  // Show error summary
  errorSummary.hidden = false;
  
  // Focus the error summary
  errorSummary.focus();
}
```

### 4. Real-time Validation

Provide real-time validation feedback when appropriate, but avoid being too aggressive.

```javascript
const emailInput = document.getElementById('email');

// Validate on blur (when the user leaves the field)
emailInput.addEventListener('blur', () => {
  validateEmail(emailInput);
});

// Validate on input, but only if the field has already been blurred
let emailBlurred = false;
emailInput.addEventListener('blur', () => {
  emailBlurred = true;
});
emailInput.addEventListener('input', () => {
  if (emailBlurred) {
    validateEmail(emailInput);
  }
});

function validateEmail(input) {
  const email = input.value.trim();
  const emailError = document.getElementById('email-error');
  
  if (email === '') {
    input.setAttribute('aria-invalid', 'true');
    emailError.textContent = 'Email address is required';
    emailError.hidden = false;
  } else if (!isValidEmail(email)) {
    input.setAttribute('aria-invalid', 'true');
    emailError.textContent = 'Please enter a valid email address';
    emailError.hidden = false;
  } else {
    input.setAttribute('aria-invalid', 'false');
    emailError.hidden = true;
  }
}

function isValidEmail(email) {
  // Simple email validation regex
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

### 5. Accessible Error Announcements

Ensure that errors are announced to screen reader users.

```html
<div id="live-region" class="sr-only" aria-live="assertive" role="status"></div>
```

```javascript
function announceError(message) {
  const liveRegion = document.getElementById('live-region');
  liveRegion.textContent = message;
  
  // Clear the message after a short delay to allow it to be announced again
  setTimeout(() => {
    liveRegion.textContent = '';
  }, 3000);
}
```

### 6. Provide Suggestions

When possible, provide suggestions for correcting errors.

```html
<div class="form-group">
  <label for="username">Username</label>
  <input type="text" id="username" name="username" aria-describedby="username-error" aria-invalid="true">
  <div id="username-error" class="error-message" role="alert">
    Username "johndoe" is already taken. Try "johndoe123" or "john_doe" instead.
  </div>
</div>
```

## Implementing Accessible Form Validation in UME Components

### Registration Form

```html
<form id="registration-form" novalidate>
  <div id="error-summary" class="error-summary" role="alert" aria-labelledby="error-heading" hidden>
    <h2 id="error-heading">Please correct the following errors:</h2>
    <ul id="error-list"></ul>
  </div>
  
  <div class="form-group">
    <label for="name">Full Name</label>
    <input type="text" id="name" name="name" required aria-describedby="name-error name-description">
    <div id="name-description" class="field-description">Enter your full name as it appears on official documents</div>
    <div id="name-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="email">Email Address</label>
    <input type="email" id="email" name="email" required aria-describedby="email-error email-description">
    <div id="email-description" class="field-description">We'll send a verification link to this email</div>
    <div id="email-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="password">Password</label>
    <input type="password" id="password" name="password" required 
           aria-describedby="password-error password-requirements">
    <div id="password-requirements" class="field-description">
      Password must be at least 8 characters and include:
      <ul>
        <li id="req-length">At least 8 characters</li>
        <li id="req-uppercase">At least one uppercase letter</li>
        <li id="req-lowercase">At least one lowercase letter</li>
        <li id="req-number">At least one number</li>
      </ul>
    </div>
    <div id="password-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="confirm-password">Confirm Password</label>
    <input type="password" id="confirm-password" name="confirm_password" required 
           aria-describedby="confirm-password-error">
    <div id="confirm-password-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <input type="checkbox" id="terms" name="terms" required aria-describedby="terms-error">
    <label for="terms">I agree to the <a href="/terms">Terms of Service</a> and <a href="/privacy">Privacy Policy</a></label>
    <div id="terms-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <button type="submit">Register</button>
</form>

<div id="live-region" class="sr-only" aria-live="assertive" role="status"></div>

<script>
  const form = document.getElementById('registration-form');
  const nameInput = document.getElementById('name');
  const emailInput = document.getElementById('email');
  const passwordInput = document.getElementById('password');
  const confirmPasswordInput = document.getElementById('confirm-password');
  const termsCheckbox = document.getElementById('terms');
  
  // Track which fields have been interacted with
  const touchedFields = new Set();
  
  // Add blur event listeners to track field interaction
  [nameInput, emailInput, passwordInput, confirmPasswordInput, termsCheckbox].forEach(field => {
    field.addEventListener('blur', () => {
      touchedFields.add(field.id);
      validateField(field);
    });
    
    // For text inputs, also validate on input if already touched
    if (field.type !== 'checkbox') {
      field.addEventListener('input', () => {
        if (touchedFields.has(field.id)) {
          validateField(field);
        }
      });
    }
  });
  
  // Real-time password strength indicator
  passwordInput.addEventListener('input', updatePasswordStrength);
  
  function updatePasswordStrength() {
    const password = passwordInput.value;
    
    // Check requirements
    const hasLength = password.length >= 8;
    const hasUppercase = /[A-Z]/.test(password);
    const hasLowercase = /[a-z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    
    // Update requirement indicators
    document.getElementById('req-length').classList.toggle('met', hasLength);
    document.getElementById('req-uppercase').classList.toggle('met', hasUppercase);
    document.getElementById('req-lowercase').classList.toggle('met', hasLowercase);
    document.getElementById('req-number').classList.toggle('met', hasNumber);
  }
  
  // Form submission
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    
    // Mark all fields as touched
    [nameInput, emailInput, passwordInput, confirmPasswordInput, termsCheckbox].forEach(field => {
      touchedFields.add(field.id);
    });
    
    // Validate all fields
    const errors = {};
    
    if (!validateName(nameInput)) {
      errors.name = 'Please enter your full name';
    }
    
    if (!validateEmail(emailInput)) {
      errors.email = 'Please enter a valid email address';
    }
    
    if (!validatePassword(passwordInput)) {
      errors.password = 'Password does not meet the requirements';
    }
    
    if (!validateConfirmPassword(confirmPasswordInput, passwordInput)) {
      errors.confirm_password = 'Passwords do not match';
    }
    
    if (!termsCheckbox.checked) {
      errors.terms = 'You must agree to the Terms of Service and Privacy Policy';
    }
    
    // If there are errors, show them and prevent form submission
    if (Object.keys(errors).length > 0) {
      showErrorSummary(errors);
      return;
    }
    
    // If no errors, submit the form
    // In a real application, you would submit the form data to the server
    alert('Form submitted successfully!');
  });
  
  function validateField(field) {
    switch (field.id) {
      case 'name':
        return validateName(field);
      case 'email':
        return validateEmail(field);
      case 'password':
        return validatePassword(field);
      case 'confirm-password':
        return validateConfirmPassword(field, passwordInput);
      case 'terms':
        return validateTerms(field);
    }
  }
  
  function validateName(input) {
    const name = input.value.trim();
    const nameError = document.getElementById('name-error');
    
    if (name === '') {
      setInvalid(input, nameError, 'Full name is required');
      return false;
    }
    
    setValid(input, nameError);
    return true;
  }
  
  function validateEmail(input) {
    const email = input.value.trim();
    const emailError = document.getElementById('email-error');
    
    if (email === '') {
      setInvalid(input, emailError, 'Email address is required');
      return false;
    }
    
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setInvalid(input, emailError, 'Please enter a valid email address');
      return false;
    }
    
    setValid(input, emailError);
    return true;
  }
  
  function validatePassword(input) {
    const password = input.value;
    const passwordError = document.getElementById('password-error');
    
    if (password === '') {
      setInvalid(input, passwordError, 'Password is required');
      return false;
    }
    
    const hasLength = password.length >= 8;
    const hasUppercase = /[A-Z]/.test(password);
    const hasLowercase = /[a-z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    
    if (!hasLength || !hasUppercase || !hasLowercase || !hasNumber) {
      setInvalid(input, passwordError, 'Password must be at least 8 characters and include uppercase, lowercase, and numbers');
      return false;
    }
    
    setValid(input, passwordError);
    return true;
  }
  
  function validateConfirmPassword(input, passwordInput) {
    const confirmPassword = input.value;
    const password = passwordInput.value;
    const confirmPasswordError = document.getElementById('confirm-password-error');
    
    if (confirmPassword === '') {
      setInvalid(input, confirmPasswordError, 'Please confirm your password');
      return false;
    }
    
    if (confirmPassword !== password) {
      setInvalid(input, confirmPasswordError, 'Passwords do not match');
      return false;
    }
    
    setValid(input, confirmPasswordError);
    return true;
  }
  
  function validateTerms(input) {
    const termsError = document.getElementById('terms-error');
    
    if (!input.checked) {
      setInvalid(input, termsError, 'You must agree to the Terms of Service and Privacy Policy');
      return false;
    }
    
    setValid(input, termsError);
    return true;
  }
  
  function setInvalid(input, errorElement, message) {
    input.setAttribute('aria-invalid', 'true');
    errorElement.textContent = message;
    errorElement.hidden = false;
  }
  
  function setValid(input, errorElement) {
    input.setAttribute('aria-invalid', 'false');
    errorElement.hidden = true;
  }
  
  function showErrorSummary(errors) {
    const errorSummary = document.getElementById('error-summary');
    const errorList = document.getElementById('error-list');
    
    // Clear previous errors
    errorList.innerHTML = '';
    
    // Add new errors
    for (const field in errors) {
      const errorItem = document.createElement('li');
      const errorLink = document.createElement('a');
      
      // Convert field name to input ID
      const inputId = field.replace('_', '-');
      
      errorLink.href = `#${inputId}`;
      errorLink.textContent = errors[field];
      errorLink.addEventListener('click', (e) => {
        e.preventDefault();
        document.getElementById(inputId).focus();
      });
      
      errorItem.appendChild(errorLink);
      errorList.appendChild(errorItem);
    }
    
    // Show error summary
    errorSummary.hidden = false;
    
    // Focus the error summary
    errorSummary.focus();
    
    // Announce to screen readers
    announceError(`Form has ${Object.keys(errors).length} error${Object.keys(errors).length > 1 ? 's' : ''}`);
  }
  
  function announceError(message) {
    const liveRegion = document.getElementById('live-region');
    liveRegion.textContent = message;
    
    // Clear the message after a short delay to allow it to be announced again
    setTimeout(() => {
      liveRegion.textContent = '';
    }, 3000);
  }
</script>

<style>
  .form-group {
    margin-bottom: 1.5rem;
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: bold;
  }
  
  input[type="text"],
  input[type="email"],
  input[type="password"] {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #d1d5db;
    border-radius: 0.25rem;
  }
  
  input[aria-invalid="true"] {
    border-color: #dc2626;
  }
  
  .field-description {
    margin-top: 0.25rem;
    font-size: 0.875rem;
    color: #6b7280;
  }
  
  .error-message {
    margin-top: 0.25rem;
    font-size: 0.875rem;
    color: #dc2626;
  }
  
  .error-summary {
    margin-bottom: 1.5rem;
    padding: 1rem;
    border: 1px solid #dc2626;
    border-radius: 0.25rem;
    background-color: #fee2e2;
  }
  
  .error-summary h2 {
    margin-top: 0;
    font-size: 1.25rem;
    color: #dc2626;
  }
  
  .error-summary ul {
    margin-bottom: 0;
  }
  
  .error-summary a {
    color: #dc2626;
    text-decoration: underline;
  }
  
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
  }
  
  #password-requirements ul {
    margin-top: 0.5rem;
    padding-left: 1.5rem;
    font-size: 0.875rem;
  }
  
  #password-requirements li {
    margin-bottom: 0.25rem;
  }
  
  #password-requirements li.met {
    color: #10b981;
  }
  
  #password-requirements li.met::before {
    content: "✓ ";
  }
</style>
```

### Login Form with Server-Side Validation

```html
<form id="login-form" method="POST" action="/login">
  <div id="error-summary" class="error-summary" role="alert" aria-labelledby="error-heading" hidden>
    <h2 id="error-heading">Please correct the following errors:</h2>
    <ul id="error-list"></ul>
  </div>
  
  <div class="form-group">
    <label for="email">Email Address</label>
    <input type="email" id="email" name="email" required aria-describedby="email-error">
    <div id="email-error" class="error-message" role="alert" hidden></div>
  </div>
  
  <div class="form-group">
    <label for="password">Password</label>
    <input type="password" id="password" name="password" required aria-describedby="password-error">
    <div id="password-error" class="error-message" role="alert" hidden></div>
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

<div id="live-region" class="sr-only" aria-live="assertive" role="status"></div>

<script>
  // Check for server-side validation errors
  document.addEventListener('DOMContentLoaded', () => {
    // In a real application, you would get these errors from the server
    // This is just an example of how to handle server-side validation errors
    const serverErrors = {
      email: 'These credentials do not match our records.',
      password: ''
    };
    
    if (Object.values(serverErrors).some(error => error !== '')) {
      const errors = {};
      
      for (const field in serverErrors) {
        if (serverErrors[field] !== '') {
          errors[field] = serverErrors[field];
          
          const input = document.getElementById(field);
          const errorElement = document.getElementById(`${field}-error`);
          
          input.setAttribute('aria-invalid', 'true');
          errorElement.textContent = serverErrors[field];
          errorElement.hidden = false;
        }
      }
      
      if (Object.keys(errors).length > 0) {
        showErrorSummary(errors);
      }
    }
  });
  
  // Client-side validation
  const form = document.getElementById('login-form');
  const emailInput = document.getElementById('email');
  const passwordInput = document.getElementById('password');
  
  form.addEventListener('submit', (e) => {
    // Prevent form submission for this example
    // In a real application, you would only prevent submission if there are errors
    e.preventDefault();
    
    const errors = {};
    
    if (!validateEmail(emailInput)) {
      errors.email = 'Please enter a valid email address';
    }
    
    if (!validatePassword(passwordInput)) {
      errors.password = 'Password is required';
    }
    
    if (Object.keys(errors).length > 0) {
      showErrorSummary(errors);
      return;
    }
    
    // If no errors, submit the form
    // In a real application, you would submit the form to the server
    alert('Form submitted successfully!');
  });
  
  function validateEmail(input) {
    const email = input.value.trim();
    const emailError = document.getElementById('email-error');
    
    if (email === '') {
      input.setAttribute('aria-invalid', 'true');
      emailError.textContent = 'Email address is required';
      emailError.hidden = false;
      return false;
    }
    
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      input.setAttribute('aria-invalid', 'true');
      emailError.textContent = 'Please enter a valid email address';
      emailError.hidden = false;
      return false;
    }
    
    input.setAttribute('aria-invalid', 'false');
    emailError.hidden = true;
    return true;
  }
  
  function validatePassword(input) {
    const password = input.value;
    const passwordError = document.getElementById('password-error');
    
    if (password === '') {
      input.setAttribute('aria-invalid', 'true');
      passwordError.textContent = 'Password is required';
      passwordError.hidden = false;
      return false;
    }
    
    input.setAttribute('aria-invalid', 'false');
    passwordError.hidden = true;
    return true;
  }
  
  function showErrorSummary(errors) {
    const errorSummary = document.getElementById('error-summary');
    const errorList = document.getElementById('error-list');
    
    // Clear previous errors
    errorList.innerHTML = '';
    
    // Add new errors
    for (const field in errors) {
      const errorItem = document.createElement('li');
      const errorLink = document.createElement('a');
      
      errorLink.href = `#${field}`;
      errorLink.textContent = errors[field];
      errorLink.addEventListener('click', (e) => {
        e.preventDefault();
        document.getElementById(field).focus();
      });
      
      errorItem.appendChild(errorLink);
      errorList.appendChild(errorItem);
    }
    
    // Show error summary
    errorSummary.hidden = false;
    
    // Focus the error summary
    errorSummary.focus();
    
    // Announce to screen readers
    announceError(`Form has ${Object.keys(errors).length} error${Object.keys(errors).length > 1 ? 's' : ''}`);
  }
  
  function announceError(message) {
    const liveRegion = document.getElementById('live-region');
    liveRegion.textContent = message;
    
    // Clear the message after a short delay to allow it to be announced again
    setTimeout(() => {
      liveRegion.textContent = '';
    }, 3000);
  }
</script>
```

## Testing Form Validation Accessibility

To test form validation accessibility in your UME implementation:

1. **Test with keyboard only** to ensure all form controls and error messages are accessible.

2. **Test with screen readers** to ensure error messages are properly announced.

3. **Test with different browsers and assistive technologies** to ensure compatibility.

4. **Test with different form inputs** to ensure all validation scenarios are handled correctly.

5. **Test with high contrast mode** to ensure error messages are visible.

For more detailed testing procedures, refer to the [Accessibility Testing](./080-testing-procedures.md) section.

## Common Form Validation Issues and Solutions

| Issue | Solution |
|-------|----------|
| Error messages not associated with form controls | Use `aria-describedby` to associate error messages with form controls |
| Error messages not announced to screen readers | Use `role="alert"` or live regions to announce error messages |
| Error messages not visible | Use clear visual indicators (color, icons, etc.) for error messages |
| Form controls not marked as invalid | Use `aria-invalid="true"` to mark invalid form controls |
| Error messages not helpful | Provide clear, specific error messages with suggestions for correction |
| Error messages not perceivable by all users | Ensure error messages are perceivable by all users, including those with visual impairments |

## Additional Resources

- [WebAIM: Accessible Forms](https://webaim.org/techniques/forms/)
- [MDN: Form Validation](https://developer.mozilla.org/en-US/docs/Learn/Forms/Form_validation)
- [W3C: Form Validation](https://www.w3.org/WAI/tutorials/forms/validation/)
- [Inclusive Components: A Todo List](https://inclusive-components.design/a-todo-list/)
