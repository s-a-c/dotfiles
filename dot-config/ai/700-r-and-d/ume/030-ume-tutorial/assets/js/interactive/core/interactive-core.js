/**
 * Interactive Core
 * 
 * Core functionality for interactive code examples in the UME tutorial.
 * This file provides initialization, configuration, and utility functions.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Selector for interactive code examples
    selector: '.interactive-code-example',
    
    // Default settings
    defaults: {
      language: 'php',
      editable: true
    },
    
    // Storage key prefix for saving user modifications
    storageKeyPrefix: 'ume-interactive-example-'
  };

  // State
  const state = {
    initialized: false,
    examples: new Map(),
    theme: 'light'
  };

  /**
   * Initialize interactive examples
   */
  function initialize() {
    if (state.initialized) {
      return;
    }

    // Detect theme
    detectTheme();

    // Parse Markdown blocks
    parseMarkdownBlocks();

    // Initialize examples
    initializeExamples();

    // Set up event listeners
    setupEventListeners();

    // Mark as initialized
    state.initialized = true;

    // Log initialization
    console.log('Interactive examples initialized');
  }

  /**
   * Detect theme (light/dark)
   */
  function detectTheme() {
    // Check for dark mode
    const isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches;
    state.theme = isDarkMode ? 'dark' : 'light';

    // Add theme class to body
    document.body.classList.add(`theme-${state.theme}`);

    // Log theme detection
    console.log(`Theme detected: ${state.theme}`);
  }

  /**
   * Parse Markdown blocks
   * This is a placeholder - actual implementation will be in markdown-parser.js
   */
  function parseMarkdownBlocks() {
    console.log('Parsing Markdown blocks');
    // This will be implemented in markdown-parser.js
  }

  /**
   * Initialize examples
   * This is a placeholder - actual implementation will use the editor and execution components
   */
  function initializeExamples() {
    console.log('Initializing examples');
    // This will be implemented using the editor and execution components
  }

  /**
   * Set up event listeners
   * This is a placeholder - actual implementation will be in event-handlers.js
   */
  function setupEventListeners() {
    console.log('Setting up event listeners');
    // This will be implemented in event-handlers.js
  }

  // Export to global namespace
  window.UMEInteractive = {
    initialize: initialize,
    config: config,
    getState: function() {
      return { ...state };
    }
  };

  // Initialize when DOM is loaded
  document.addEventListener('DOMContentLoaded', initialize);
})();
