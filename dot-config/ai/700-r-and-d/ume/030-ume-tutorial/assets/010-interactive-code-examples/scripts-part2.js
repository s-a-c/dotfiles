/**
 * Scripts for UME Tutorial Interactive Code Examples (Part 2)
 * Theme and accessibility features
 */

/**
 * Initialize theme toggle
 */
function initThemeToggle() {
  const themeToggle = document.getElementById('theme-toggle');
  
  if (themeToggle) {
    themeToggle.addEventListener('click', function() {
      document.body.classList.toggle('dark-theme');
      
      // Update toggle text
      const isDarkTheme = document.body.classList.contains('dark-theme');
      themeToggle.textContent = isDarkTheme ? 'Switch to Light Theme' : 'Switch to Dark Theme';
      
      // Store preference
      localStorage.setItem('theme', isDarkTheme ? 'dark' : 'light');
    });
    
    // Apply saved theme preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
      document.body.classList.add('dark-theme');
      themeToggle.textContent = 'Switch to Light Theme';
    }
  }
}

/**
 * Initialize accessibility features
 */
function initAccessibility() {
  // Add keyboard shortcuts
  document.addEventListener('keydown', function(event) {
    // Ctrl+Enter or Cmd+Enter to run code
    if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
      const activeExample = document.activeElement.closest('.interactive-code-container');
      if (activeExample) {
        const runButton = activeExample.querySelector('.interactive-code-run-button');
        if (runButton) {
          event.preventDefault();
          runButton.click();
        }
      }
    }
    
    // Escape to reset code
    if (event.key === 'Escape') {
      const activeExample = document.activeElement.closest('.interactive-code-container');
      if (activeExample) {
        const resetButton = activeExample.querySelector('.interactive-code-reset-button');
        if (resetButton) {
          event.preventDefault();
          resetButton.click();
        }
      }
    }
  });
  
  // Add high contrast toggle
  const contrastToggle = document.getElementById('contrast-toggle');
  
  if (contrastToggle) {
    contrastToggle.addEventListener('click', function() {
      document.body.classList.toggle('high-contrast');
      
      // Update toggle text
      const isHighContrast = document.body.classList.contains('high-contrast');
      contrastToggle.textContent = isHighContrast ? 'Disable High Contrast' : 'Enable High Contrast';
      
      // Store preference
      localStorage.setItem('contrast', isHighContrast ? 'high' : 'normal');
    });
    
    // Apply saved contrast preference
    const savedContrast = localStorage.getItem('contrast');
    if (savedContrast === 'high') {
      document.body.classList.add('high-contrast');
      contrastToggle.textContent = 'Disable High Contrast';
    }
  }
}
