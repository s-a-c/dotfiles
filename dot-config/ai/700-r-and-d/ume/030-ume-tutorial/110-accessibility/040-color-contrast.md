# Color Contrast Requirements

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides guidelines for ensuring sufficient color contrast in your UME implementation to accommodate users with visual impairments, including color blindness and low vision.

## Why Color Contrast Matters

Sufficient color contrast between text and its background is essential for readability, especially for users with:

- Low vision
- Color blindness
- Age-related vision changes
- Situational limitations (e.g., bright sunlight on screens)

Meeting color contrast requirements is a fundamental aspect of web accessibility and is required for WCAG compliance (Success Criterion 1.4.3 Contrast, Level AA).

## WCAG Contrast Requirements

The Web Content Accessibility Guidelines (WCAG) define specific contrast ratios for text and visual elements:

### Text Contrast (WCAG 2.1, Success Criterion 1.4.3, Level AA)

- **Normal Text** (less than 18pt or 14pt bold): Minimum contrast ratio of **4.5:1**
- **Large Text** (at least 18pt or 14pt bold): Minimum contrast ratio of **3:1**

### Non-Text Contrast (WCAG 2.1, Success Criterion 1.4.11, Level AA)

- **UI Components**: Minimum contrast ratio of **3:1** for the boundaries of active user interface components
- **Graphical Objects**: Minimum contrast ratio of **3:1** for parts of graphics required to understand the content

## Implementing Proper Color Contrast

### 1. Choose Accessible Color Combinations

When designing your UME implementation, choose color combinations that meet the required contrast ratios.

```css
/* Example of accessible color combinations */

/* Good contrast for normal text (ratio: 7:1) */
.good-contrast {
  color: #333333; /* Dark gray text */
  background-color: #ffffff; /* White background */
}

/* Poor contrast for normal text (ratio: 2.5:1) */
.poor-contrast {
  color: #999999; /* Light gray text */
  background-color: #ffffff; /* White background */
}

/* Good contrast for large text (ratio: 3.5:1) */
.good-large-text {
  color: #767676; /* Medium gray text */
  background-color: #ffffff; /* White background */
  font-size: 24px; /* Large text */
}
```

### 2. Test Color Contrast

Use color contrast checking tools to verify that your color combinations meet the required contrast ratios:

- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Contrast Ratio](https://contrast-ratio.com/)
- [Colour Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/)

### 3. Don't Rely on Color Alone

Ensure that color is not the only means of conveying information. Always provide additional cues, such as text labels, patterns, or icons.

```html
<!-- Poor implementation (relies on color alone) -->
<div class="status-indicator status-success"></div> Order Status

<!-- Good implementation (uses color and text) -->
<div class="status-indicator status-success">
  <span class="status-icon" aria-hidden="true">✓</span>
  <span class="status-text">Success</span>
</div> Order Status
```

```css
.status-indicator {
  display: inline-flex;
  align-items: center;
  padding: 4px 8px;
  border-radius: 4px;
}

.status-success {
  background-color: #d1fae5; /* Light green background */
  color: #065f46; /* Dark green text */
}

.status-warning {
  background-color: #fef3c7; /* Light yellow background */
  color: #92400e; /* Dark orange text */
}

.status-error {
  background-color: #fee2e2; /* Light red background */
  color: #7f1d1d; /* Dark red text */
}
```

### 4. Support High Contrast Mode

Ensure your UME implementation works well with high contrast modes in operating systems and browsers.

```css
/* Support for Windows High Contrast Mode */
@media (forced-colors: active) {
  .button {
    /* Use system colors in high contrast mode */
    background-color: ButtonFace;
    color: ButtonText;
    border-color: ButtonText;
  }
  
  .button:hover {
    background-color: Highlight;
    color: HighlightText;
  }
}
```

## Color Contrast in UME Components

### Text Elements

```css
/* Base text styles with good contrast */
body {
  color: #1f2937; /* Dark gray text (ratio: 12:1 on white) */
  background-color: #ffffff; /* White background */
}

/* Headings */
h1, h2, h3, h4, h5, h6 {
  color: #111827; /* Very dark gray (ratio: 16:1 on white) */
}

/* Links */
a {
  color: #2563eb; /* Blue (ratio: 4.5:1 on white) */
}

a:hover {
  color: #1d4ed8; /* Darker blue (ratio: 5.5:1 on white) */
}

/* Secondary text */
.text-secondary {
  color: #4b5563; /* Medium gray (ratio: 7:1 on white) */
}
```

### Form Elements

```css
/* Form labels */
label {
  color: #374151; /* Dark gray (ratio: 10:1 on white) */
}

/* Form inputs */
input, select, textarea {
  color: #1f2937; /* Dark gray text (ratio: 12:1 on white) */
  background-color: #ffffff; /* White background */
  border: 1px solid #d1d5db; /* Light gray border */
}

/* Placeholder text */
::placeholder {
  color: #6b7280; /* Medium gray (ratio: 4.5:1 on white) */
}

/* Focus state */
input:focus, select:focus, textarea:focus {
  border-color: #2563eb; /* Blue border */
  outline: 2px solid #93c5fd; /* Light blue outline */
}

/* Disabled state */
input:disabled, select:disabled, textarea:disabled {
  background-color: #f3f4f6; /* Light gray background */
  color: #6b7280; /* Medium gray text (ratio: 4.5:1 on light gray) */
}
```

### Buttons

```css
/* Primary button */
.btn-primary {
  background-color: #2563eb; /* Blue background */
  color: #ffffff; /* White text (ratio: 4.5:1) */
}

.btn-primary:hover {
  background-color: #1d4ed8; /* Darker blue background */
}

/* Secondary button */
.btn-secondary {
  background-color: #4b5563; /* Gray background */
  color: #ffffff; /* White text (ratio: 5:1) */
}

.btn-secondary:hover {
  background-color: #374151; /* Darker gray background */
}

/* Danger button */
.btn-danger {
  background-color: #dc2626; /* Red background */
  color: #ffffff; /* White text (ratio: 4.5:1) */
}

.btn-danger:hover {
  background-color: #b91c1c; /* Darker red background */
}

/* Outline button */
.btn-outline {
  background-color: transparent;
  color: #2563eb; /* Blue text (ratio: 4.5:1 on white) */
  border: 1px solid #2563eb; /* Blue border */
}

.btn-outline:hover {
  background-color: #eff6ff; /* Very light blue background */
}
```

### Alerts and Notifications

```css
/* Success alert */
.alert-success {
  background-color: #d1fae5; /* Light green background */
  color: #065f46; /* Dark green text (ratio: 7:1) */
  border: 1px solid #10b981; /* Green border */
}

/* Warning alert */
.alert-warning {
  background-color: #fef3c7; /* Light yellow background */
  color: #92400e; /* Dark orange text (ratio: 7:1) */
  border: 1px solid #f59e0b; /* Orange border */
}

/* Error alert */
.alert-error {
  background-color: #fee2e2; /* Light red background */
  color: #7f1d1d; /* Dark red text (ratio: 7:1) */
  border: 1px solid #ef4444; /* Red border */
}

/* Info alert */
.alert-info {
  background-color: #e0f2fe; /* Light blue background */
  color: #0c4a6e; /* Dark blue text (ratio: 7:1) */
  border: 1px solid #0ea5e9; /* Blue border */
}
```

## Dark Mode Considerations

When implementing dark mode, ensure that color contrast requirements are still met.

```css
/* Light mode */
:root {
  --text-color: #1f2937; /* Dark gray text */
  --background-color: #ffffff; /* White background */
  --primary-color: #2563eb; /* Blue */
  --secondary-color: #4b5563; /* Gray */
  --success-color: #10b981; /* Green */
  --warning-color: #f59e0b; /* Orange */
  --error-color: #ef4444; /* Red */
  --info-color: #0ea5e9; /* Blue */
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --text-color: #f3f4f6; /* Light gray text */
    --background-color: #1f2937; /* Dark gray background */
    --primary-color: #60a5fa; /* Lighter blue */
    --secondary-color: #9ca3af; /* Lighter gray */
    --success-color: #34d399; /* Lighter green */
    --warning-color: #fbbf24; /* Lighter orange */
    --error-color: #f87171; /* Lighter red */
    --info-color: #38bdf8; /* Lighter blue */
  }
}

/* Apply variables */
body {
  color: var(--text-color);
  background-color: var(--background-color);
}

.btn-primary {
  background-color: var(--primary-color);
  color: var(--background-color);
}
```

## Testing Color Contrast

To test color contrast in your UME implementation:

1. **Use automated tools** such as:
   - [WAVE](https://wave.webaim.org/)
   - [axe DevTools](https://www.deque.com/axe/)
   - [Lighthouse](https://developers.google.com/web/tools/lighthouse)

2. **Check contrast manually** using color contrast checkers:
   - [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
   - [Contrast Ratio](https://contrast-ratio.com/)

3. **Test with color blindness simulators**:
   - [Colorblinding](https://chrome.google.com/webstore/detail/colorblinding/dgbgleaofjainknadoffbjkclicbbgaa) (Chrome extension)
   - [Color Oracle](https://colororacle.org/) (Desktop application)

4. **Test in different lighting conditions** to ensure readability in various environments.

For more detailed testing procedures, refer to the [Accessibility Testing](./080-testing-procedures.md) section.

## Common Color Contrast Issues and Solutions

| Issue | Solution |
|-------|----------|
| Insufficient text contrast | Darken text color or lighten background color |
| Low contrast UI elements | Increase contrast of borders and backgrounds |
| Reliance on color alone | Add text labels, icons, or patterns |
| Poor contrast in focus indicators | Use high-contrast focus styles |
| Inconsistent contrast in dark mode | Test and adjust colors specifically for dark mode |

## Additional Resources

- [WebAIM: Contrast and Color Accessibility](https://webaim.org/articles/contrast/)
- [MDN: Color and color contrast](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Understanding_Colors_and_Luminance)
- [Accessible Colors](https://accessible-colors.com/)
- [Contrast Grid](https://contrast-grid.eightshapes.com/)
