/**
 * Interactive Examples
 *
 * Main entry point for interactive code examples in the UME tutorial.
 * This file loads all necessary components and initializes the interactive examples.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Core loader scripts
    loaders: [
      '/docs/030-ume-tutorial/assets/js/interactive/core/asset-loader.js',
      '/docs/030-ume-tutorial/assets/js/interactive/core/style-loader.js'
    ],

    // Initialization order
    initOrder: [
      'StyleLoader',
      'AssetLoader',
      'MarkdownParser',
      'EventHandlers'
    ]
  };

  /**
   * Load a script
   * @param {string} src - The script source
   * @returns {Promise} - A promise that resolves when the script is loaded
   */
  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = src;
      script.async = true;

      script.onload = () => {
        resolve();
      };

      script.onerror = () => {
        reject(new Error(`Failed to load script: ${src}`));
      };

      document.head.appendChild(script);
    });
  }

  /**
   * Load core loaders
   * @returns {Promise} - A promise that resolves when all loaders are loaded
   */
  function loadCoreLoaders() {
    return Promise.all(config.loaders.map(loader => loadScript(loader)));
  }

  /**
   * Initialize components in order
   * @returns {Promise} - A promise that resolves when all components are initialized
   */
  function initializeComponents() {
    // Initialize each component in order
    return config.initOrder.reduce((promise, component) => {
      return promise.then(() => {
        if (window.UMEInteractive && window.UMEInteractive[component] &&
            typeof window.UMEInteractive[component].initialize === 'function') {
          console.log(`Initializing ${component}`);
          return window.UMEInteractive[component].initialize();
        } else {
          console.warn(`Component not found or not initializable: ${component}`);
          return Promise.resolve();
        }
      });
    }, Promise.resolve());
  }

  /**
   * Initialize interactive examples
   */
  function initialize() {
    console.log('Initializing interactive examples');

    // Create global namespace if it doesn't exist
    window.UMEInteractive = window.UMEInteractive || {};

    // Load core loaders
    loadCoreLoaders()
      .then(() => {
        console.log('Core loaders loaded');

        // Load assets using the asset loader
        if (window.UMEInteractive.AssetLoader) {
          return window.UMEInteractive.AssetLoader.loadAllAssets();
        } else {
          console.error('Asset loader not found');
          return Promise.reject(new Error('Asset loader not found'));
        }
      })
      .then(() => {
        console.log('All assets loaded');

        // Initialize components
        return initializeComponents();
      })
      .then(() => {
        console.log('All components initialized');

        // Process the document
        if (window.UMEInteractive.MarkdownParser) {
          window.UMEInteractive.MarkdownParser.processDocument();
        }

        // Set up event listeners
        if (window.UMEInteractive.EventHandlers) {
          window.UMEInteractive.EventHandlers.setupEventListeners();
        }
      })
      .catch(error => {
        console.error('Failed to initialize interactive examples:', error);
      });
  }

  // Initialize when DOM is loaded
  document.addEventListener('DOMContentLoaded', initialize);
})();
