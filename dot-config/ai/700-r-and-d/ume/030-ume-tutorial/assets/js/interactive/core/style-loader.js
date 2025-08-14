/**
 * Style Loader
 * 
 * Utility for managing CSS styles for interactive code examples.
 * This file provides functionality to load, apply, and switch themes.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Theme stylesheets
    themes: {
      light: '/docs/030-ume-tutorial/assets/css/interactive/themes/light.css',
      dark: '/docs/030-ume-tutorial/assets/css/interactive/themes/dark.css'
    },
    
    // Main stylesheet
    mainStylesheet: '/docs/030-ume-tutorial/assets/css/interactive/interactive.css',
    
    // Theme storage key
    themeStorageKey: 'ume-interactive-theme',
    
    // Default theme
    defaultTheme: 'light'
  };

  // State
  const state = {
    currentTheme: null,
    themeStylesheets: new Map(),
    mainStylesheetLoaded: false
  };

  /**
   * Load the main stylesheet
   * @returns {Promise} - A promise that resolves when the stylesheet is loaded
   */
  function loadMainStylesheet() {
    if (state.mainStylesheetLoaded) {
      return Promise.resolve();
    }
    
    return new Promise((resolve, reject) => {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = config.mainStylesheet;
      
      link.onload = () => {
        state.mainStylesheetLoaded = true;
        resolve();
      };
      
      link.onerror = () => {
        reject(new Error(`Failed to load main stylesheet: ${config.mainStylesheet}`));
      };
      
      document.head.appendChild(link);
    });
  }

  /**
   * Load a theme stylesheet
   * @param {string} theme - The theme to load
   * @returns {Promise} - A promise that resolves when the stylesheet is loaded
   */
  function loadThemeStylesheet(theme) {
    if (state.themeStylesheets.has(theme)) {
      return Promise.resolve(state.themeStylesheets.get(theme));
    }
    
    return new Promise((resolve, reject) => {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = config.themes[theme];
      link.dataset.theme = theme;
      link.disabled = true;
      
      link.onload = () => {
        state.themeStylesheets.set(theme, link);
        resolve(link);
      };
      
      link.onerror = () => {
        reject(new Error(`Failed to load theme stylesheet: ${config.themes[theme]}`));
      };
      
      document.head.appendChild(link);
    });
  }

  /**
   * Load all theme stylesheets
   * @returns {Promise} - A promise that resolves when all stylesheets are loaded
   */
  function loadAllThemeStylesheets() {
    const themes = Object.keys(config.themes);
    
    return Promise.all(themes.map(theme => loadThemeStylesheet(theme)));
  }

  /**
   * Apply a theme
   * @param {string} theme - The theme to apply
   */
  function applyTheme(theme) {
    if (!config.themes[theme]) {
      console.error(`Theme not found: ${theme}`);
      return;
    }
    
    // Load the theme stylesheet if not already loaded
    loadThemeStylesheet(theme)
      .then(stylesheet => {
        // Disable all theme stylesheets
        state.themeStylesheets.forEach(sheet => {
          sheet.disabled = true;
        });
        
        // Enable the selected theme stylesheet
        stylesheet.disabled = false;
        
        // Update the current theme
        state.currentTheme = theme;
        
        // Update body class
        document.body.classList.remove('theme-light', 'theme-dark');
        document.body.classList.add(`theme-${theme}`);
        
        // Store the theme preference
        localStorage.setItem(config.themeStorageKey, theme);
        
        console.log(`Theme applied: ${theme}`);
      })
      .catch(error => {
        console.error('Failed to apply theme:', error);
      });
  }

  /**
   * Get the current theme
   * @returns {string} - The current theme
   */
  function getCurrentTheme() {
    return state.currentTheme;
  }

  /**
   * Detect the preferred theme
   * @returns {string} - The preferred theme
   */
  function detectPreferredTheme() {
    // Check for stored preference
    const storedTheme = localStorage.getItem(config.themeStorageKey);
    if (storedTheme && config.themes[storedTheme]) {
      return storedTheme;
    }
    
    // Check for system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    
    // Default to light theme
    return config.defaultTheme;
  }

  /**
   * Initialize the style loader
   * @returns {Promise} - A promise that resolves when initialization is complete
   */
  function initialize() {
    return Promise.all([
      loadMainStylesheet(),
      loadAllThemeStylesheets()
    ])
      .then(() => {
        // Detect and apply the preferred theme
        const preferredTheme = detectPreferredTheme();
        applyTheme(preferredTheme);
        
        // Set up theme change listener
        const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
        darkModeMediaQuery.addEventListener('change', event => {
          // Only change theme if no stored preference
          if (!localStorage.getItem(config.themeStorageKey)) {
            applyTheme(event.matches ? 'dark' : 'light');
          }
        });
        
        console.log('Style loader initialized');
      })
      .catch(error => {
        console.error('Failed to initialize style loader:', error);
      });
  }

  // Export to global namespace
  window.UMEInteractive = window.UMEInteractive || {};
  window.UMEInteractive.StyleLoader = {
    initialize: initialize,
    applyTheme: applyTheme,
    getCurrentTheme: getCurrentTheme,
    detectPreferredTheme: detectPreferredTheme
  };
})();
