/**
 * Scripts for UME Tutorial Interactive Code Examples (Part 1)
 * Main initialization and core functionality
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
