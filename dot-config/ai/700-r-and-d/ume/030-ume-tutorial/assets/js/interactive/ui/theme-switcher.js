/**
 * Theme Switcher
 * 
 * Handles theme switching for interactive code examples.
 * This file provides functionality to switch between light and dark themes.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Theme storage key
    storageKey: 'ume-interactive-theme',
    
    // Default theme
    defaultTheme: 'light',
    
    // Available themes
    themes: ['light', 'dark'],
    
    // Selectors
    selectors: {
      themeToggle: '#theme-toggle',
      body: 'body'
    },
    
    // CSS classes
    classes: {
      light: 'theme-light',
      dark: 'theme-dark'
    }
  };

  // State
  const state = {
    currentTheme: null,
    initialized: false
  };

  /**
   * Get the stored theme preference
   * @returns {string|null} - The stored theme preference or null if not found
   */
  function getStoredTheme() {
    try {
      return localStorage.getItem(config.storageKey);
    } catch (error) {
      console.error('Failed to get stored theme:', error);
      return null;
    }
  }

  /**
   * Store the theme preference
   * @param {string} theme - The theme to store
   */
  function storeTheme(theme) {
    try {
      localStorage.setItem(config.storageKey, theme);
    } catch (error) {
      console.error('Failed to store theme:', error);
    }
  }

  /**
   * Get the system theme preference
   * @returns {string} - The system theme preference ('light' or 'dark')
   */
  function getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  /**
   * Get the preferred theme
   * @returns {string} - The preferred theme
   */
  function getPreferredTheme() {
    // Check for stored preference
    const storedTheme = getStoredTheme();
    if (storedTheme && config.themes.includes(storedTheme)) {
      return storedTheme;
    }
    
    // Check for system preference
    return getSystemTheme();
  }

  /**
   * Apply a theme
   * @param {string} theme - The theme to apply
   */
  function applyTheme(theme) {
    // Validate theme
    if (!config.themes.includes(theme)) {
      console.error(`Invalid theme: ${theme}`);
      return;
    }
    
    // Update state
    state.currentTheme = theme;
    
    // Update body classes
    const body = document.querySelector(config.selectors.body);
    if (body) {
      // Remove all theme classes
      config.themes.forEach(t => {
        body.classList.remove(config.classes[t]);
      });
      
      // Add the current theme class
      body.classList.add(config.classes[theme]);
    }
    
    // Update Monaco editor theme
    if (window.UMEInteractive && window.UMEInteractive.MonacoLoader) {
      window.UMEInteractive.MonacoLoader.setTheme(theme);
    }
    
    // Store the theme preference
    storeTheme(theme);
    
    // Dispatch theme changed event
    const event = new CustomEvent('theme-changed', {
      detail: { theme }
    });
    document.dispatchEvent(event);
    
    console.log(`Theme applied: ${theme}`);
  }

  /**
   * Toggle the theme
   */
  function toggleTheme() {
    const currentTheme = state.currentTheme || getPreferredTheme();
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    applyTheme(newTheme);
  }

  /**
   * Set up theme toggle button
   */
  function setupThemeToggle() {
    const themeToggle = document.querySelector(config.selectors.themeToggle);
    if (themeToggle) {
      themeToggle.addEventListener('click', toggleTheme);
    }
  }

  /**
   * Set up system theme change listener
   */
  function setupSystemThemeListener() {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    // Listen for changes
    mediaQuery.addEventListener('change', event => {
      // Only change theme if no stored preference
      if (!getStoredTheme()) {
        applyTheme(event.matches ? 'dark' : 'light');
      }
    });
  }

  /**
   * Initialize the theme switcher
   */
  function initialize() {
    if (state.initialized) {
      return;
    }
    
    // Get the preferred theme
    const preferredTheme = getPreferredTheme();
    
    // Apply the preferred theme
    applyTheme(preferredTheme);
    
    // Set up theme toggle button
    setupThemeToggle();
    
    // Set up system theme change listener
    setupSystemThemeListener();
    
    // Mark as initialized
    state.initialized = true;
    
    console.log('Theme switcher initialized');
  }

  // Export to global namespace
  window.UMEInteractive = window.UMEInteractive || {};
  window.UMEInteractive.ThemeSwitcher = {
    initialize: initialize,
    applyTheme: applyTheme,
    toggleTheme: toggleTheme,
    getCurrentTheme: () => state.currentTheme
  };
})();
