/**
 * Asset Loader
 * 
 * Utility for loading JavaScript and CSS assets for interactive code examples.
 * This file provides functionality to load scripts and styles dynamically.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Base paths for assets
    basePaths: {
      js: '/docs/030-ume-tutorial/assets/js',
      css: '/docs/030-ume-tutorial/assets/css',
      vendor: '/docs/030-ume-tutorial/assets/vendor'
    },
    
    // Core assets that should be loaded first
    coreAssets: {
      js: [
        'interactive/core/interactive-core.js',
        'interactive/core/markdown-parser.js',
        'interactive/core/event-handlers.js'
      ],
      css: [
        'interactive/interactive.css',
        'interactive/themes/light.css',
        'interactive/themes/dark.css'
      ]
    },
    
    // Monaco editor assets
    monacoAssets: {
      js: [
        'interactive/editor/monaco-loader.js'
      ],
      css: []
    },
    
    // Execution assets
    executionAssets: {
      js: [
        'interactive/execution/code-executor.js',
        'interactive/execution/output-handler.js',
        'interactive/execution/error-handler.js'
      ],
      css: []
    },
    
    // UI assets
    uiAssets: {
      js: [
        'interactive/ui/toolbar.js',
        'interactive/ui/output-panel.js',
        'interactive/ui/theme-switcher.js'
      ],
      css: []
    }
  };

  // State
  const state = {
    loadedAssets: new Set(),
    loading: new Map()
  };

  /**
   * Load a JavaScript file
   * @param {string} src - The script source
   * @returns {Promise} - A promise that resolves when the script is loaded
   */
  function loadScript(src) {
    // Check if already loaded
    if (state.loadedAssets.has(src)) {
      return Promise.resolve();
    }
    
    // Check if currently loading
    if (state.loading.has(src)) {
      return state.loading.get(src);
    }
    
    // Create a new promise for loading
    const promise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = src;
      script.async = true;
      
      script.onload = () => {
        state.loadedAssets.add(src);
        state.loading.delete(src);
        resolve();
      };
      
      script.onerror = () => {
        state.loading.delete(src);
        reject(new Error(`Failed to load script: ${src}`));
      };
      
      document.head.appendChild(script);
    });
    
    // Store the promise
    state.loading.set(src, promise);
    
    return promise;
  }

  /**
   * Load a CSS file
   * @param {string} href - The stylesheet href
   * @returns {Promise} - A promise that resolves when the stylesheet is loaded
   */
  function loadStyle(href) {
    // Check if already loaded
    if (state.loadedAssets.has(href)) {
      return Promise.resolve();
    }
    
    // Check if currently loading
    if (state.loading.has(href)) {
      return state.loading.get(href);
    }
    
    // Create a new promise for loading
    const promise = new Promise((resolve, reject) => {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = href;
      
      link.onload = () => {
        state.loadedAssets.add(href);
        state.loading.delete(href);
        resolve();
      };
      
      link.onerror = () => {
        state.loading.delete(href);
        reject(new Error(`Failed to load stylesheet: ${href}`));
      };
      
      document.head.appendChild(link);
    });
    
    // Store the promise
    state.loading.set(href, promise);
    
    return promise;
  }

  /**
   * Load assets by type
   * @param {string} type - The asset type (js or css)
   * @param {Array} assets - The assets to load
   * @param {string} basePath - The base path for the assets
   * @returns {Promise} - A promise that resolves when all assets are loaded
   */
  function loadAssetsByType(type, assets, basePath) {
    const loader = type === 'js' ? loadScript : loadStyle;
    
    return Promise.all(assets.map(asset => {
      const url = `${basePath}/${asset}`;
      return loader(url);
    }));
  }

  /**
   * Load assets
   * @param {Object} assets - The assets to load
   * @returns {Promise} - A promise that resolves when all assets are loaded
   */
  function loadAssets(assets) {
    const promises = [];
    
    // Load JavaScript assets
    if (assets.js && assets.js.length > 0) {
      promises.push(loadAssetsByType('js', assets.js, config.basePaths.js));
    }
    
    // Load CSS assets
    if (assets.css && assets.css.length > 0) {
      promises.push(loadAssetsByType('css', assets.css, config.basePaths.css));
    }
    
    return Promise.all(promises);
  }

  /**
   * Load core assets
   * @returns {Promise} - A promise that resolves when all core assets are loaded
   */
  function loadCoreAssets() {
    return loadAssets(config.coreAssets);
  }

  /**
   * Load Monaco editor assets
   * @returns {Promise} - A promise that resolves when all Monaco editor assets are loaded
   */
  function loadMonacoAssets() {
    return loadAssets(config.monacoAssets);
  }

  /**
   * Load execution assets
   * @returns {Promise} - A promise that resolves when all execution assets are loaded
   */
  function loadExecutionAssets() {
    return loadAssets(config.executionAssets);
  }

  /**
   * Load UI assets
   * @returns {Promise} - A promise that resolves when all UI assets are loaded
   */
  function loadUIAssets() {
    return loadAssets(config.uiAssets);
  }

  /**
   * Load all assets
   * @returns {Promise} - A promise that resolves when all assets are loaded
   */
  function loadAllAssets() {
    return Promise.all([
      loadCoreAssets(),
      loadMonacoAssets(),
      loadExecutionAssets(),
      loadUIAssets()
    ]);
  }

  /**
   * Load Monaco editor from CDN
   * @returns {Promise} - A promise that resolves when Monaco editor is loaded
   */
  function loadMonacoEditor() {
    const monacoVersion = '0.36.1';
    const monacoBaseUrl = `https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/${monacoVersion}/min`;
    
    return new Promise((resolve, reject) => {
      // Check if Monaco is already loaded
      if (window.monaco) {
        resolve(window.monaco);
        return;
      }
      
      // Load the loader script
      loadScript(`${monacoBaseUrl}/vs/loader.js`)
        .then(() => {
          // Configure require
          window.require.config({
            paths: {
              vs: `${monacoBaseUrl}/vs`
            }
          });
          
          // Load Monaco
          window.require(['vs/editor/editor.main'], () => {
            // Register PHP language if not already registered
            if (!monaco.languages.getLanguages().some(lang => lang.id === 'php')) {
              monaco.languages.register({ id: 'php' });
            }
            
            resolve(window.monaco);
          });
        })
        .catch(reject);
    });
  }

  // Export to global namespace
  window.UMEInteractive = window.UMEInteractive || {};
  window.UMEInteractive.AssetLoader = {
    loadScript: loadScript,
    loadStyle: loadStyle,
    loadCoreAssets: loadCoreAssets,
    loadMonacoAssets: loadMonacoAssets,
    loadExecutionAssets: loadExecutionAssets,
    loadUIAssets: loadUIAssets,
    loadAllAssets: loadAllAssets,
    loadMonacoEditor: loadMonacoEditor
  };
})();
