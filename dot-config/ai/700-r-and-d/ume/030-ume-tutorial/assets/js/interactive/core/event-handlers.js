/**
 * Event Handlers
 * 
 * Handles events for interactive code examples in the UME tutorial.
 * This file provides functionality to handle button clicks, code changes,
 * and other user interactions.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Selectors for interactive elements
    selectors: {
      example: '.interactive-code-example',
      runButton: '.run-button',
      resetButton: '.reset-button',
      copyButton: '.copy-button',
      editor: '.monaco-editor',
      outputContent: '.output-content',
      editorStatus: '.editor-status'
    },
    
    // Messages
    messages: {
      copied: 'Code copied to clipboard',
      reset: 'Code reset to original',
      running: 'Running code...',
      complete: 'Execution complete',
      error: 'Execution failed'
    }
  };

  /**
   * Set up event listeners for all interactive examples
   */
  function setupEventListeners() {
    console.log('Setting up event listeners for interactive examples');
    
    // Find all interactive examples
    const examples = document.querySelectorAll(config.selectors.example);
    
    // Set up listeners for each example
    examples.forEach((example, index) => {
      setupExampleListeners(example, index);
    });
    
    // Set up global listeners
    setupGlobalListeners();
  }

  /**
   * Set up event listeners for a single interactive example
   * @param {HTMLElement} example - The example element
   * @param {number} index - The index of the example
   */
  function setupExampleListeners(example, index) {
    console.log(`Setting up listeners for example ${index}`);
    
    // Run button
    const runButton = example.querySelector(config.selectors.runButton);
    if (runButton) {
      runButton.addEventListener('click', () => {
        handleRunClick(example, index);
      });
    }
    
    // Reset button
    const resetButton = example.querySelector(config.selectors.resetButton);
    if (resetButton) {
      resetButton.addEventListener('click', () => {
        handleResetClick(example, index);
      });
    }
    
    // Copy button
    const copyButton = example.querySelector(config.selectors.copyButton);
    if (copyButton) {
      copyButton.addEventListener('click', () => {
        handleCopyClick(example, index);
      });
    }
  }

  /**
   * Set up global event listeners
   */
  function setupGlobalListeners() {
    console.log('Setting up global event listeners');
    
    // Theme change listener
    const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    darkModeMediaQuery.addEventListener('change', handleThemeChange);
    
    // Window resize listener
    window.addEventListener('resize', handleWindowResize);
  }

  /**
   * Handle run button click
   * @param {HTMLElement} example - The example element
   * @param {number} index - The index of the example
   */
  function handleRunClick(example, index) {
    console.log(`Run button clicked for example ${index}`);
    
    // Get the editor
    const editorElement = example.querySelector(config.selectors.editor);
    if (!editorElement) {
      console.error('Editor not found');
      return;
    }
    
    // Get the output content element
    const outputContent = example.querySelector(config.selectors.outputContent);
    if (!outputContent) {
      console.error('Output content not found');
      return;
    }
    
    // Get the status element
    const statusElement = example.querySelector(config.selectors.editorStatus);
    
    // Update status
    if (statusElement) {
      statusElement.textContent = config.messages.running;
    }
    
    // Get the code from the editor
    // In a real implementation, this would get the code from the Monaco editor instance
    const code = editorElement.dataset.code || '';
    
    // Execute the code
    // This is a placeholder - actual implementation will be in code-executor.js
    executeCode(code)
      .then(result => {
        // Display the result
        if (outputContent) {
          outputContent.textContent = result;
        }
        
        // Update status
        if (statusElement) {
          statusElement.textContent = config.messages.complete;
          
          // Clear status after a delay
          setTimeout(() => {
            statusElement.textContent = '';
          }, 3000);
        }
      })
      .catch(error => {
        // Display the error
        if (outputContent) {
          outputContent.textContent = `Error: ${error.message}`;
        }
        
        // Update status
        if (statusElement) {
          statusElement.textContent = config.messages.error;
        }
      });
  }

  /**
   * Handle reset button click
   * @param {HTMLElement} example - The example element
   * @param {number} index - The index of the example
   */
  function handleResetClick(example, index) {
    console.log(`Reset button clicked for example ${index}`);
    
    // Get the editor
    const editorElement = example.querySelector(config.selectors.editor);
    if (!editorElement) {
      console.error('Editor not found');
      return;
    }
    
    // Get the status element
    const statusElement = example.querySelector(config.selectors.editorStatus);
    
    // Reset the editor
    // In a real implementation, this would reset the Monaco editor instance
    
    // Update status
    if (statusElement) {
      statusElement.textContent = config.messages.reset;
      
      // Clear status after a delay
      setTimeout(() => {
        statusElement.textContent = '';
      }, 3000);
    }
  }

  /**
   * Handle copy button click
   * @param {HTMLElement} example - The example element
   * @param {number} index - The index of the example
   */
  function handleCopyClick(example, index) {
    console.log(`Copy button clicked for example ${index}`);
    
    // Get the editor
    const editorElement = example.querySelector(config.selectors.editor);
    if (!editorElement) {
      console.error('Editor not found');
      return;
    }
    
    // Get the status element
    const statusElement = example.querySelector(config.selectors.editorStatus);
    
    // Get the code from the editor
    // In a real implementation, this would get the code from the Monaco editor instance
    const code = editorElement.dataset.code || '';
    
    // Copy to clipboard
    navigator.clipboard.writeText(code)
      .then(() => {
        // Update status
        if (statusElement) {
          statusElement.textContent = config.messages.copied;
          
          // Clear status after a delay
          setTimeout(() => {
            statusElement.textContent = '';
          }, 3000);
        }
      })
      .catch(error => {
        console.error('Failed to copy code:', error);
      });
  }

  /**
   * Handle theme change
   * @param {MediaQueryListEvent} event - The media query change event
   */
  function handleThemeChange(event) {
    console.log(`Theme changed to ${event.matches ? 'dark' : 'light'}`);
    
    // Update theme
    const theme = event.matches ? 'dark' : 'light';
    
    // Update body class
    document.body.classList.remove('theme-light', 'theme-dark');
    document.body.classList.add(`theme-${theme}`);
    
    // Update editor theme
    // In a real implementation, this would update the Monaco editor theme
  }

  /**
   * Handle window resize
   */
  function handleWindowResize() {
    console.log('Window resized');
    
    // Update editor layout
    // In a real implementation, this would update the Monaco editor layout
  }

  /**
   * Execute code (placeholder)
   * @param {string} code - The code to execute
   * @returns {Promise<string>} - A promise that resolves with the execution result
   */
  function executeCode(code) {
    return new Promise((resolve, reject) => {
      // This is a placeholder - actual implementation will be in code-executor.js
      setTimeout(() => {
        if (code.includes('error')) {
          reject(new Error('Execution failed'));
        } else {
          resolve(`Executed: ${code}`);
        }
      }, 500);
    });
  }

  // Export to global namespace
  window.UMEInteractive = window.UMEInteractive || {};
  window.UMEInteractive.EventHandlers = {
    setupEventListeners: setupEventListeners,
    setupExampleListeners: setupExampleListeners,
    setupGlobalListeners: setupGlobalListeners
  };
})();
