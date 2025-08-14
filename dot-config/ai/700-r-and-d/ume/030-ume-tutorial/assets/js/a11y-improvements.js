/**
 * Accessibility Improvements for Interactive Code Examples
 * 
 * This file contains JavaScript enhancements to improve the accessibility
 * of interactive code examples, focusing on keyboard navigation, screen reader
 * support, and other accessibility features.
 */

document.addEventListener('DOMContentLoaded', function() {
  // Initialize accessibility enhancements
  initA11yImprovements();
});

/**
 * Initialize all accessibility improvements
 */
function initA11yImprovements() {
  enhanceKeyboardNavigation();
  improveScreenReaderSupport();
  addA11yAttributes();
  setupFocusManagement();
  implementColorContrastToggle();
}

/**
 * Enhance keyboard navigation for interactive elements
 */
function enhanceKeyboardNavigation() {
  // Add keyboard shortcuts for common actions
  document.addEventListener('keydown', function(event) {
    // Only handle keyboard shortcuts when focused on interactive code elements
    if (!isInteractiveCodeFocused()) return;
    
    // Ctrl+Enter or Cmd+Enter to run code
    if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
      event.preventDefault();
      const runButton = document.querySelector('.interactive-code-run-button:focus') || 
                        document.querySelector('.interactive-code-container:focus-within .interactive-code-run-button');
      if (runButton) runButton.click();
    }
    
    // Escape to reset code
    if (event.key === 'Escape') {
      event.preventDefault();
      const resetButton = document.querySelector('.interactive-code-reset-button:focus-within') ||
                          document.querySelector('.interactive-code-container:focus-within .interactive-code-reset-button');
      if (resetButton) resetButton.click();
    }
  });
  
  // Improve tab order for interactive elements
  const interactiveContainers = document.querySelectorAll('.interactive-code-container');
  interactiveContainers.forEach(container => {
    const focusableElements = container.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    
    // Set logical tab order
    focusableElements.forEach((element, index) => {
      element.setAttribute('tabindex', index + 1);
    });
  });
}

/**
 * Improve screen reader support
 */
function improveScreenReaderSupport() {
  // Add descriptive labels to code editors
  const codeEditors = document.querySelectorAll('.code-editor');
  codeEditors.forEach((editor, index) => {
    const container = editor.closest('.interactive-code-container');
    const title = container.querySelector('.interactive-code-title').textContent || `Code Example ${index + 1}`;
    
    editor.setAttribute('aria-label', `Code editor for ${title}`);
    editor.setAttribute('role', 'textbox');
    editor.setAttribute('aria-multiline', 'true');
  });
  
  // Add live regions for code execution results
  const previewAreas = document.querySelectorAll('.code-preview');
  previewAreas.forEach(preview => {
    preview.setAttribute('aria-live', 'polite');
    preview.setAttribute('aria-atomic', 'true');
  });
  
  // Add status announcements for actions
  const runButtons = document.querySelectorAll('.interactive-code-run-button');
  runButtons.forEach(button => {
    button.addEventListener('click', function() {
      announceToScreenReader('Code is running');
      
      // Announce completion after a short delay
      setTimeout(() => {
        announceToScreenReader('Code execution complete');
      }, 500);
    });
  });
}

/**
 * Add ARIA and other accessibility attributes
 */
function addA11yAttributes() {
  // Add ARIA landmarks
  document.querySelectorAll('.interactive-code-container').forEach(container => {
    container.setAttribute('role', 'region');
    container.setAttribute('aria-roledescription', 'Interactive code example');
  });
  
  // Add button labels
  document.querySelectorAll('.interactive-code-button').forEach(button => {
    if (!button.getAttribute('aria-label') && !button.textContent.trim()) {
      const action = button.classList.contains('interactive-code-run-button') ? 'Run code' :
                    button.classList.contains('interactive-code-reset-button') ? 'Reset code' :
                    button.classList.contains('interactive-code-copy-button') ? 'Copy code' : 'Action';
      button.setAttribute('aria-label', action);
    }
  });
  
  // Add expanded states for collapsible sections
  document.querySelectorAll('.interactive-code-collapsible').forEach(collapsible => {
    const trigger = collapsible.querySelector('.interactive-code-collapse-trigger');
    const content = collapsible.querySelector('.interactive-code-collapse-content');
    
    if (trigger && content) {
      trigger.setAttribute('aria-expanded', 'false');
      trigger.setAttribute('aria-controls', generateUniqueId(content));
      content.setAttribute('id', generateUniqueId(content));
      content.setAttribute('aria-hidden', 'true');
      
      trigger.addEventListener('click', function() {
        const expanded = trigger.getAttribute('aria-expanded') === 'true';
        trigger.setAttribute('aria-expanded', !expanded);
        content.setAttribute('aria-hidden', expanded);
      });
    }
  });
}

/**
 * Set up focus management for interactive components
 */
function setupFocusManagement() {
  // Trap focus within modal dialogs
  document.querySelectorAll('.interactive-code-modal').forEach(modal => {
    const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];
    
    modal.addEventListener('keydown', function(event) {
      if (event.key === 'Tab') {
        // Shift+Tab on first element should focus last element
        if (event.shiftKey && document.activeElement === firstElement) {
          event.preventDefault();
          lastElement.focus();
        }
        // Tab on last element should focus first element
        else if (!event.shiftKey && document.activeElement === lastElement) {
          event.preventDefault();
          firstElement.focus();
        }
      }
    });
  });
  
  // Return focus after modal closes
  document.querySelectorAll('.interactive-code-modal-close').forEach(closeButton => {
    closeButton.addEventListener('click', function() {
      const modal = closeButton.closest('.interactive-code-modal');
      const opener = document.querySelector(`[aria-controls="${modal.id}"]`);
      if (opener) opener.focus();
    });
  });
  
  // Highlight focused elements
  document.addEventListener('focusin', function(event) {
    if (isInteractiveCodeElement(event.target)) {
      event.target.classList.add('focus-visible');
    }
  });
  
  document.addEventListener('focusout', function(event) {
    if (isInteractiveCodeElement(event.target)) {
      event.target.classList.remove('focus-visible');
    }
  });
}

/**
 * Implement color contrast toggle for accessibility
 */
function implementColorContrastToggle() {
  // Create high contrast toggle button
  const containers = document.querySelectorAll('.interactive-code-container');
  containers.forEach(container => {
    const header = container.querySelector('.interactive-code-header');
    if (!header) return;
    
    const contrastButton = document.createElement('button');
    contrastButton.className = 'interactive-code-contrast-toggle';
    contrastButton.setAttribute('aria-label', 'Toggle high contrast mode');
    contrastButton.setAttribute('title', 'Toggle high contrast mode');
    contrastButton.innerHTML = '<span class="visually-hidden">Toggle high contrast</span>';
    
    contrastButton.addEventListener('click', function() {
      container.classList.toggle('high-contrast');
      const isHighContrast = container.classList.contains('high-contrast');
      contrastButton.setAttribute('aria-pressed', isHighContrast);
      
      // Announce change to screen readers
      announceToScreenReader(`High contrast mode ${isHighContrast ? 'enabled' : 'disabled'}`);
    });
    
    header.appendChild(contrastButton);
  });
}

/**
 * Helper function to announce messages to screen readers
 */
function announceToScreenReader(message) {
  let announcer = document.getElementById('a11y-announcer');
  
  if (!announcer) {
    announcer = document.createElement('div');
    announcer.id = 'a11y-announcer';
    announcer.setAttribute('aria-live', 'assertive');
    announcer.setAttribute('aria-atomic', 'true');
    announcer.className = 'visually-hidden';
    document.body.appendChild(announcer);
  }
  
  // Clear previous announcement
  announcer.textContent = '';
  
  // Set new announcement after a brief delay
  setTimeout(() => {
    announcer.textContent = message;
  }, 50);
}

/**
 * Helper function to generate a unique ID for an element
 */
function generateUniqueId(element) {
  if (element.id) return element.id;
  
  const id = `interactive-element-${Math.random().toString(36).substr(2, 9)}`;
  element.id = id;
  return id;
}

/**
 * Helper function to check if an element is part of an interactive code example
 */
function isInteractiveCodeElement(element) {
  return element.closest('.interactive-code-container') !== null;
}

/**
 * Helper function to check if focus is within an interactive code example
 */
function isInteractiveCodeFocused() {
  return document.querySelector('.interactive-code-container:focus-within') !== null;
}
