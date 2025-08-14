/**
 * Scripts for UME Tutorial Interactive Code Examples (Part 3)
 * Utility functions and dynamic example loading
 */

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
