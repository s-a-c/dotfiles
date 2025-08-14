/**
 * Scripts for UME Tutorial Interactive Code Examples
 */

document.addEventListener('DOMContentLoaded', function() {
  // Initialize interactive code examples
  initInteractiveExamples();
  
  // Initialize theme toggle
  initThemeToggle();
  
  // Initialize accessibility features
  initAccessibility();
});

/**
 * Initialize interactive code examples
 */
function initInteractiveExamples() {
  const examples = document.querySelectorAll('.interactive-code-container');
  
  examples.forEach(function(example) {
    const runButton = example.querySelector('.interactive-code-run-button');
    const resetButton = example.querySelector('.interactive-code-reset-button');
    const editor = example.querySelector('.interactive-code-editor');
    const output = example.querySelector('.interactive-code-output');
    
    if (runButton && editor && output) {
      // Store original code for reset functionality
      const originalCode = editor.textContent;
      
      // Run button functionality
      runButton.addEventListener('click', function() {
        const code = editor.textContent;
        try {
          // In a real implementation, this would execute the code
          // For this example, we'll just display the code in the output
          output.innerHTML = '<pre><code>' + escapeHtml(code) + '</code></pre>';
          output.innerHTML += '<div class="success-message">Code executed successfully!</div>';
        } catch (error) {
          output.innerHTML = '<div class="error-message">Error: ' + error.message + '</div>';
        }
      });
      
      // Reset button functionality
      if (resetButton) {
        resetButton.addEventListener('click', function() {
          editor.textContent = originalCode;
          output.innerHTML = '<div class="info-message">Code has been reset.</div>';
        });
      }
    }
  });
}

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

/**
 * Escape HTML special characters
 * 
 * @param {string} html - The HTML string to escape
 * @return {string} - The escaped HTML string
 */
function escapeHtml(html) {
  const div = document.createElement('div');
  div.textContent = html;
  return div.innerHTML;
}

/**
 * Create a notification
 * 
 * @param {string} message - The notification message
 * @param {string} type - The notification type (info, success, warning, error)
 * @param {number} duration - The duration in milliseconds
 */
function createNotification(message, type = 'info', duration = 3000) {
  const notification = document.createElement('div');
  notification.className = 'notification notification-' + type;
  notification.textContent = message;
  
  document.body.appendChild(notification);
  
  // Show notification
  setTimeout(function() {
    notification.classList.add('show');
  }, 10);
  
  // Hide and remove notification
  setTimeout(function() {
    notification.classList.remove('show');
    setTimeout(function() {
      notification.remove();
    }, 300);
  }, duration);
}

/**
 * Load example from file
 * 
 * @param {string} url - The URL of the example file
 * @param {Element} container - The container element
 */
function loadExample(url, container) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to load example: ' + response.status);
      }
      return response.text();
    })
    .then(text => {
      // Parse the example file
      const parser = new DOMParser();
      const doc = parser.parseFromString(text, 'text/html');
      
      // Extract parts
      const title = doc.querySelector('h1').textContent;
      const description = doc.querySelector('p').textContent;
      const code = doc.querySelector('pre code').textContent;
      const explanation = doc.querySelector('.explanation').innerHTML;
      
      // Create interactive example
      createInteractiveExample(container, title, description, code, explanation);
    })
    .catch(error => {
      console.error('Error loading example:', error);
      container.innerHTML = '<div class="error-message">Failed to load example: ' + error.message + '</div>';
    });
}

/**
 * Create interactive example
 * 
 * @param {Element} container - The container element
 * @param {string} title - The example title
 * @param {string} description - The example description
 * @param {string} code - The example code
 * @param {string} explanation - The example explanation
 */
function createInteractiveExample(container, title, description, code, explanation) {
  container.innerHTML = `
    <div class="interactive-code-container">
      <div class="interactive-code-header">
        <h3 class="interactive-code-title">${title}</h3>
        <div class="interactive-code-controls">
          <button class="interactive-code-run-button">Run</button>
          <button class="interactive-code-reset-button">Reset</button>
        </div>
      </div>
      <div class="interactive-code-description">
        <p>${description}</p>
      </div>
      <div class="interactive-code-content">
        <div class="interactive-code-editor" contenteditable="true">${code}</div>
        <div class="interactive-code-output">
          <div class="info-message">Click "Run" to execute the code.</div>
        </div>
      </div>
      <div class="interactive-code-explanation">
        ${explanation}
      </div>
    </div>
  `;
  
  // Initialize the example
  initInteractiveExamples();
}
