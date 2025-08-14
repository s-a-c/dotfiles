# Accessibility Checklist

<link rel="stylesheet" href="../assets/css/styles.css">

This comprehensive checklist will help you ensure that your UME implementation meets accessibility requirements. Use this checklist during development and testing to identify and address accessibility issues.

## How to Use This Checklist

1. Review each item in the checklist
2. Check off items that have been implemented
3. Address any unchecked items
4. Retest after making changes
5. Document any exceptions or workarounds

## General Accessibility

### Page Structure

- [ ] Page has a descriptive and unique title
- [ ] HTML language attribute is set (`<html lang="en">`)
- [ ] Proper heading structure is used (h1, h2, h3, etc.)
- [ ] Headings are used in a logical, hierarchical order
- [ ] ARIA landmarks are used appropriately (header, nav, main, etc.)
- [ ] Skip links are provided to bypass repetitive navigation
- [ ] Page is usable when CSS is disabled
- [ ] Page is usable when JavaScript is disabled (or has appropriate fallbacks)
- [ ] Content is presented in a meaningful sequence
- [ ] Reading order matches visual order

### Keyboard Accessibility

- [ ] All functionality is available using the keyboard alone
- [ ] Focus order follows a logical sequence
- [ ] Focus indicators are visible and have sufficient contrast
- [ ] No keyboard traps exist
- [ ] Custom keyboard shortcuts do not conflict with browser or screen reader shortcuts
- [ ] Keyboard focus is managed appropriately for modal dialogs and other interactive elements
- [ ] Tab index is used appropriately (avoid positive values)

### Text and Typography

- [ ] Text has sufficient color contrast (4.5:1 for normal text, 3:1 for large text)
- [ ] Text can be resized up to 200% without loss of content or functionality
- [ ] Line height is at least 1.5 times the font size
- [ ] Paragraph spacing is at least 2 times the font size
- [ ] Letter spacing is at least 0.12 times the font size
- [ ] Word spacing is at least 0.16 times the font size
- [ ] No justified text is used
- [ ] Font size is at least 16px for body text
- [ ] Text is not presented as images (except for logos)

### Images and Media

- [ ] All images have appropriate alt text
- [ ] Decorative images have empty alt text (`alt=""`) or are hidden from screen readers
- [ ] Complex images have detailed descriptions
- [ ] SVG elements have appropriate accessibility attributes
- [ ] Icon fonts have appropriate text alternatives
- [ ] Videos have captions and audio descriptions
- [ ] Audio content has transcripts
- [ ] No content flashes more than three times per second
- [ ] Animations can be paused or disabled
- [ ] Autoplaying media can be paused, stopped, or hidden

### Color and Contrast

- [ ] Color is not used as the only means of conveying information
- [ ] UI components have sufficient contrast (3:1)
- [ ] Focus indicators have sufficient contrast (3:1)
- [ ] Content is understandable when viewed in high contrast mode
- [ ] Content is understandable when viewed in grayscale
- [ ] Links are distinguishable from surrounding text (not by color alone)

## Forms and Interactive Elements

### Form Controls

- [ ] All form controls have associated labels
- [ ] Required fields are clearly indicated
- [ ] Form fields have appropriate autocomplete attributes
- [ ] Input purpose is programmatically determinable
- [ ] Error messages are clear and descriptive
- [ ] Error messages are associated with their respective form controls
- [ ] Form validation provides suggestions for correction
- [ ] Success messages are provided after form submission
- [ ] Forms can be submitted using keyboard alone
- [ ] Form controls maintain their state after validation errors

### Custom Controls

- [ ] Custom controls have appropriate ARIA roles and states
- [ ] Custom controls are keyboard accessible
- [ ] Custom controls have visible focus indicators
- [ ] Custom controls have appropriate touch target size (at least 44×44 pixels)
- [ ] Custom controls have appropriate text alternatives
- [ ] Custom controls are tested with assistive technologies

### Interactive Elements

- [ ] Buttons have descriptive text
- [ ] Links have descriptive text
- [ ] Links to external sites are indicated
- [ ] Links to downloads are indicated with file type and size
- [ ] Tooltips and popovers are keyboard accessible
- [ ] Tooltips and popovers are dismissible
- [ ] Dropdown menus are keyboard accessible
- [ ] Dropdown menus use appropriate ARIA attributes

## Dynamic Content

### ARIA Live Regions

- [ ] ARIA live regions are used for dynamic content updates
- [ ] Appropriate politeness levels are used (polite, assertive)
- [ ] Live regions are not overused
- [ ] Live regions are tested with screen readers

### Modal Dialogs

- [ ] Modal dialogs use `role="dialog"` and `aria-modal="true"`
- [ ] Modal dialogs have descriptive titles
- [ ] Modal dialogs trap focus until closed
- [ ] Modal dialogs can be closed with the Escape key
- [ ] Modal dialogs return focus to the triggering element when closed
- [ ] Modal dialogs are announced to screen readers when opened

### Notifications and Alerts

- [ ] Notifications use appropriate ARIA roles (`role="status"` or `role="alert"`)
- [ ] Notifications are announced to screen readers
- [ ] Notifications are dismissible
- [ ] Notifications have appropriate color contrast
- [ ] Notifications do not rely on color alone to convey information

### Time-Based Content

- [ ] Time limits can be turned off, extended, or adjusted
- [ ] Timeout warnings are provided with options to extend
- [ ] Auto-updating content can be paused, stopped, or hidden
- [ ] Carousels and slideshows can be paused and have accessible controls

## UME-Specific Components

### User Authentication Components

#### Login Form

- [ ] Form controls have associated labels
- [ ] Error messages are clear and associated with form controls
- [ ] Password field is properly labeled
- [ ] "Remember me" checkbox is properly labeled
- [ ] Form can be submitted using keyboard alone
- [ ] Password visibility toggle is accessible

#### Registration Form

- [ ] Form controls have associated labels
- [ ] Required fields are clearly indicated
- [ ] Password requirements are clearly communicated
- [ ] Error messages are clear and associated with form controls
- [ ] Form can be submitted using keyboard alone
- [ ] Terms and conditions are accessible

#### Two-Factor Authentication

- [ ] Instructions are clear and concise
- [ ] Error messages are clear and descriptive
- [ ] Time-sensitive information is clearly communicated
- [ ] Alternative methods are provided if available
- [ ] Recovery codes are accessible

### User Profile Components

#### Profile Form

- [ ] Form controls have associated labels
- [ ] Required fields are clearly indicated
- [ ] Error messages are clear and associated with form controls
- [ ] Form can be submitted using keyboard alone
- [ ] Changes are confirmed before saving

#### Avatar Upload

- [ ] Upload button is keyboard accessible
- [ ] Instructions are clear and concise
- [ ] Error messages are clear and descriptive
- [ ] Alternative text is provided for the avatar image
- [ ] Image cropping interface is accessible

#### Settings Panel

- [ ] Settings are organized in a logical structure
- [ ] Controls have clear labels and instructions
- [ ] Toggle switches have appropriate ARIA roles and states
- [ ] Changes are confirmed or saved explicitly
- [ ] Settings can be reset to defaults

### Team Management Components

#### Team Creation

- [ ] Form controls have associated labels
- [ ] Required fields are clearly indicated
- [ ] Error messages are clear and associated with form controls
- [ ] Form can be submitted using keyboard alone
- [ ] Team creation is confirmed

#### Team Member List

- [ ] Table has appropriate headers and structure
- [ ] Actions are clearly labeled
- [ ] Sorting and filtering controls are accessible
- [ ] Pagination controls are accessible
- [ ] Bulk actions are accessible

#### Role Assignment

- [ ] Roles are clearly labeled and described
- [ ] Selection controls are keyboard accessible
- [ ] Changes are confirmed or saved explicitly
- [ ] Error messages are clear and descriptive
- [ ] Current role is clearly indicated

## Testing and Compliance

### Automated Testing

- [ ] Automated accessibility testing is integrated into the development process
- [ ] Automated tests are run regularly
- [ ] Automated test results are reviewed and addressed
- [ ] Automated testing covers all pages and components

### Manual Testing

- [ ] Manual keyboard testing is performed regularly
- [ ] Manual screen reader testing is performed regularly
- [ ] Manual testing with other assistive technologies is performed as needed
- [ ] Manual testing covers all pages and components

### User Testing

- [ ] User testing with people with disabilities is conducted
- [ ] User testing feedback is incorporated into the development process
- [ ] User testing covers all major user flows

### Documentation

- [ ] Accessibility features are documented
- [ ] Known accessibility issues are documented
- [ ] Accessibility statement is provided
- [ ] Feedback mechanism for accessibility issues is provided

## WCAG 2.1 Compliance

### Level A Compliance

#### Perceivable

- [ ] 1.1.1 Non-text Content: All non-text content has a text alternative
- [ ] 1.2.1 Audio-only and Video-only (Prerecorded): Alternatives are provided
- [ ] 1.2.2 Captions (Prerecorded): Captions are provided for all prerecorded audio
- [ ] 1.2.3 Audio Description or Media Alternative (Prerecorded): Audio description or alternative is provided
- [ ] 1.3.1 Info and Relationships: Information, structure, and relationships can be programmatically determined
- [ ] 1.3.2 Meaningful Sequence: The reading sequence is logical and meaningful
- [ ] 1.3.3 Sensory Characteristics: Instructions do not rely solely on sensory characteristics
- [ ] 1.4.1 Use of Color: Color is not used as the only visual means of conveying information
- [ ] 1.4.2 Audio Control: Audio can be paused, stopped, or the volume can be changed

#### Operable

- [ ] 2.1.1 Keyboard: All functionality is available from a keyboard
- [ ] 2.1.2 No Keyboard Trap: Keyboard focus is not trapped
- [ ] 2.1.4 Character Key Shortcuts: Keyboard shortcuts can be turned off or remapped
- [ ] 2.2.1 Timing Adjustable: Time limits can be turned off, extended, or adjusted
- [ ] 2.2.2 Pause, Stop, Hide: Moving, blinking, or auto-updating content can be paused, stopped, or hidden
- [ ] 2.3.1 Three Flashes or Below Threshold: No content flashes more than three times per second
- [ ] 2.4.1 Bypass Blocks: Skip links are provided
- [ ] 2.4.2 Page Titled: Pages have descriptive titles
- [ ] 2.4.3 Focus Order: Focus order is logical and meaningful
- [ ] 2.4.4 Link Purpose (In Context): The purpose of each link can be determined from the link text or context
- [ ] 2.5.1 Pointer Gestures: Complex gestures have simpler alternatives
- [ ] 2.5.2 Pointer Cancellation: Functions are not completed on the down-event
- [ ] 2.5.3 Label in Name: The visible label is included in the accessible name
- [ ] 2.5.4 Motion Actuation: Functionality triggered by motion can also be triggered by UI components

#### Understandable

- [ ] 3.1.1 Language of Page: The language of the page is specified
- [ ] 3.2.1 On Focus: Elements do not change context when they receive focus
- [ ] 3.2.2 On Input: Elements do not change context when they receive input
- [ ] 3.3.1 Error Identification: Errors are identified and described to the user
- [ ] 3.3.2 Labels or Instructions: Labels or instructions are provided for user input

#### Robust

- [ ] 4.1.1 Parsing: HTML is valid and well-formed
- [ ] 4.1.2 Name, Role, Value: Name, role, and value of UI components can be programmatically determined

### Level AA Compliance

#### Perceivable

- [ ] 1.2.4 Captions (Live): Captions are provided for all live audio
- [ ] 1.2.5 Audio Description (Prerecorded): Audio description is provided for all prerecorded video
- [ ] 1.3.4 Orientation: Content is not restricted to a specific orientation
- [ ] 1.3.5 Identify Input Purpose: The purpose of input fields can be programmatically determined
- [ ] 1.4.3 Contrast (Minimum): Text has sufficient contrast
- [ ] 1.4.4 Resize Text: Text can be resized without loss of content or functionality
- [ ] 1.4.5 Images of Text: Images of text are not used except where necessary
- [ ] 1.4.10 Reflow: Content can be presented without scrolling in two dimensions
- [ ] 1.4.11 Non-text Contrast: UI components and graphical objects have sufficient contrast
- [ ] 1.4.12 Text Spacing: No loss of content or functionality occurs when text spacing is adjusted
- [ ] 1.4.13 Content on Hover or Focus: Additional content that appears on hover or focus is dismissible, hoverable, and persistent

#### Operable

- [ ] 2.4.5 Multiple Ways: Multiple ways are available to locate a page
- [ ] 2.4.6 Headings and Labels: Headings and labels are descriptive
- [ ] 2.4.7 Focus Visible: Keyboard focus is visible

#### Understandable

- [ ] 3.1.2 Language of Parts: The language of parts of the page is specified
- [ ] 3.2.3 Consistent Navigation: Navigation is consistent
- [ ] 3.2.4 Consistent Identification: Components with the same functionality are identified consistently
- [ ] 3.3.3 Error Suggestion: Suggestions for error correction are provided
- [ ] 3.3.4 Error Prevention (Legal, Financial, Data): Submissions can be reviewed, corrected, and confirmed

#### Robust

- [ ] 4.1.3 Status Messages: Status messages can be programmatically determined

## Additional Resources

- [WebAIM WCAG 2 Checklist](https://webaim.org/standards/wcag/checklist)
- [W3C Easy Checks](https://www.w3.org/WAI/test-evaluate/preliminary/)
- [A11Y Project Checklist](https://www.a11yproject.com/checklist/)
- [Deque University Accessibility Checklist](https://dequeuniversity.com/checklists/web/)
