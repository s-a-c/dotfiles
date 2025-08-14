# Mobile Responsiveness Exercises

<link rel="stylesheet" href="../assets/css/styles.css">

These exercises will help you practice implementing mobile-responsive features in your UME application. Complete these exercises to reinforce your understanding of mobile responsiveness concepts.

## Exercise 1: Mobile-First Design

### Multiple Choice Questions

1. What is the primary principle of mobile-first design?
   - A) Design for desktop first, then adapt for mobile
   - B) Design for mobile first, then progressively enhance for larger screens
   - C) Design separately for mobile and desktop
   - D) Focus only on mobile devices and ignore desktop

2. In Tailwind CSS, which of the following correctly applies a style only on medium screens and larger?
   - A) `class="medium:text-lg"`
   - B) `class="md-text-lg"`
   - C) `class="md:text-lg"`
   - D) `class="text-lg-md"`

3. What is the main benefit of mobile-first design?
   - A) It's easier to implement
   - B) It forces you to prioritize content and functionality
   - C) It requires less CSS
   - D) It's faster to develop

### Practical Exercise

Create a mobile-first navigation component for your UME application:

1. Start with a mobile design that uses a hamburger menu
2. Progressively enhance it to show a horizontal navigation bar on larger screens
3. Ensure the navigation is accessible and works with keyboard navigation
4. Include links to Dashboard, Teams, Profile, and Settings

## Exercise 2: Responsive Design Patterns

### Multiple Choice Questions

1. Which responsive design pattern starts with a multi-column layout and drops columns as the screen width narrows?
   - A) Mostly Fluid
   - B) Column Drop
   - C) Layout Shifter
   - D) Off Canvas

2. The Off Canvas pattern is most useful for:
   - A) Image galleries
   - B) Navigation menus on mobile
   - C) Data tables
   - D) Form layouts

3. Which CSS property is most useful for changing the order of elements at different screen sizes?
   - A) `display`
   - B) `position`
   - C) `order`
   - D) `float`

### Practical Exercise

Implement a responsive team members list that:

1. Shows as a grid of cards on large screens (3 or 4 columns)
2. Changes to 2 columns on medium screens
3. Displays as a single column list on mobile
4. Uses appropriate spacing and typography for each screen size

## Exercise 3: Touch Interactions

### Multiple Choice Questions

1. What is the recommended minimum size for touch targets?
   - A) 24×24 pixels
   - B) 32×32 pixels
   - C) 44×44 pixels
   - D) 64×64 pixels

2. Which of the following is the best alternative to hover states on touch devices?
   - A) Long press
   - B) Double tap
   - C) Explicit toggle buttons
   - D) Swipe gestures

3. When implementing swipe actions, what should you consider?
   - A) All users will understand swipe gestures
   - B) Swipe gestures should have visual indicators
   - C) Swipe is always better than buttons
   - D) Swipe should be the only way to perform actions

### Practical Exercise

Create a touch-friendly team member card component that:

1. Has adequately sized touch targets for all interactive elements
2. Implements swipe-to-reveal actions (edit and delete)
3. Provides visual feedback for touch interactions
4. Includes a fallback for devices that don't support touch events

## Exercise 4: Performance Optimization

### Multiple Choice Questions

1. Which of the following has the biggest impact on mobile performance?
   - A) JavaScript execution
   - B) CSS complexity
   - C) HTML structure
   - D) Server response time

2. What is the best approach for handling images on mobile devices?
   - A) Always use the highest resolution images
   - B) Use responsive images with appropriate sizes for different devices
   - C) Avoid images altogether on mobile
   - D) Use only vector images

3. Which of the following is NOT a valid strategy for optimizing JavaScript on mobile?
   - A) Code splitting
   - B) Lazy loading
   - C) Using more animations
   - D) Debouncing event handlers

### Practical Exercise

Optimize the performance of your UME application for mobile devices:

1. Implement lazy loading for team member avatars
2. Optimize API responses for mobile (return only necessary data)
3. Implement efficient event handling for touch interactions
4. Test the performance using Chrome DevTools' Performance panel

## Exercise 5: Offline Capabilities

### Multiple Choice Questions

1. Which API is fundamental for implementing offline capabilities?
   - A) LocalStorage API
   - B) IndexedDB API
   - C) Service Worker API
   - D) Geolocation API

2. What is the best approach for handling form submissions when offline?
   - A) Disable the form when offline
   - B) Show an error message
   - C) Store the submission and sync when online
   - D) Redirect to an offline page

3. Which of the following is NOT typically cached for offline use?
   - A) CSS files
   - B) JavaScript files
   - C) Dynamic API responses
   - D) User-specific data

### Practical Exercise

Implement basic offline capabilities for your UME application:

1. Create a service worker that caches essential assets
2. Implement an offline page that shows when the user is offline
3. Store team member data locally for offline access
4. Implement a mechanism to sync changes made offline when the connection is restored

## Exercise 6: Responsive Images

### Multiple Choice Questions

1. Which HTML attribute is used to provide different image sources for different screen sizes?
   - A) `sizes`
   - B) `srcset`
   - C) `media`
   - D) `responsive`

2. What is the primary benefit of using WebP images?
   - A) Better color accuracy
   - B) Smaller file size with similar quality
   - C) Better support across browsers
   - D) Higher resolution

3. Which approach is best for responsive background images?
   - A) Use a single high-resolution image
   - B) Use media queries to load different images
   - C) Avoid background images on mobile
   - D) Use only CSS gradients

### Practical Exercise

Implement responsive images in your UME application:

1. Create a user profile component with a responsive avatar
2. Implement a team header with a responsive background image
3. Use appropriate image formats with fallbacks for older browsers
4. Implement lazy loading for images that are not immediately visible

## Exercise 7: Device Testing

### Multiple Choice Questions

1. Which of the following is the most reliable way to test mobile responsiveness?
   - A) Using browser DevTools device emulation
   - B) Testing on actual mobile devices
   - C) Using online responsive testing tools
   - D) Checking on different desktop browsers

2. What should you include in a device testing matrix?
   - A) Only the latest devices
   - B) Only iOS devices
   - C) A representative sample of devices your users are likely to use
   - D) Every possible device

3. Which tool is most useful for remote debugging on iOS devices?
   - A) Chrome DevTools
   - B) Safari Web Inspector
   - C) Firefox Developer Tools
   - D) Edge DevTools

### Practical Exercise

Create a device testing plan for your UME application:

1. Develop a testing matrix with at least 6 different devices
2. Create a checklist of features to test on each device
3. Implement a system for tracking and documenting issues
4. Write a simple automated test that verifies responsive behavior

## Exercise 8: Troubleshooting

### Multiple Choice Questions

1. What is the most common cause of horizontal scrolling on mobile devices?
   - A) Missing viewport meta tag
   - B) Content wider than the viewport
   - C) Too much JavaScript
   - D) Incorrect CSS positioning

2. Which of the following is NOT a valid solution for hover state issues on touch devices?
   - A) Using click/tap events instead
   - B) Making important content always visible
   - C) Using alternative UI patterns
   - D) Disabling touch on the device

3. What is the best approach for debugging performance issues on mobile devices?
   - A) Adding console.log statements
   - B) Using remote debugging with DevTools
   - C) Asking users to report issues
   - D) Testing only on emulators

### Practical Exercise

Troubleshoot and fix common mobile responsiveness issues:

1. Identify and fix content overflow issues in a data table
2. Resolve touch target size issues in a form
3. Fix a navigation menu that relies on hover states
4. Optimize a slow-loading page for better mobile performance

## Submission Guidelines

For each practical exercise:

1. Implement the solution in your UME application
2. Take screenshots showing the solution on different screen sizes
3. Write a brief explanation of your approach and any challenges you faced
4. Include relevant code snippets

## Additional Resources

- [MDN Web Docs: Responsive Design](https://developer.mozilla.org/en-US/docs/Learn/CSS/CSS_layout/Responsive_Design)
- [Google Web Fundamentals: Responsive Web Design Basics](https://developers.google.com/web/fundamentals/design-and-ux/responsive)
- [Tailwind CSS Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [Chrome DevTools Device Mode](https://developers.google.com/web/tools/chrome-devtools/device-mode)

## Next Steps

After completing these exercises, check your solutions against the [sample answers](../070-sample-answers/050-mobile-responsiveness-exercises-answers.md).
