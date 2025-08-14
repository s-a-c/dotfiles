/**
 * Monaco Editor Loader
 *
 * This script loads the Monaco Editor from CDN and configures it for use in the UME 010-consolidated-starter-kits.
 */

(function() {
  // Configuration
  const config = {
    // Monaco Editor CDN
    monacoBaseUrl: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.36.1/min',

    // Default editor options
    editorOptions: {
      minimap: { enabled: false },
      scrollBeyondLastLine: false,
      fontSize: 14,
      lineNumbers: 'on',
      roundedSelection: false,
      automaticLayout: true,
      tabSize: 4,
      insertSpaces: true,
      wordWrap: 'on'
    }
  };

  // State
  const state = {
    isMonacoLoaded: false,
    isDarkMode: false,
    editors: new Map(),
    originalCode: new Map()
  };

  /**
   * Load Monaco Editor from CDN
   * @returns {Promise} A promise that resolves when Monaco is loaded
   */
  function loadMonaco() {
    return new Promise((resolve, reject) => {
      // Check if Monaco is already loaded
      if (window.monaco) {
        state.isMonacoLoaded = true;
        resolve(window.monaco);
        return;
      }

      // Create loader script
      const script = document.createElement('script');
      script.src = `${config.monacoBaseUrl}/vs/loader.js`;
      script.async = true;

      script.onload = () => {
        // Configure require
        window.require.config({
          paths: {
            vs: `${config.monacoBaseUrl}/vs`
          }
        });

        // Load Monaco
        window.require(['vs/editor/editor.main'], () => {
          // Register PHP language if not already registered
          if (!monaco.languages.getLanguages().some(lang => lang.id === 'php')) {
            monaco.languages.register({ id: 'php' });
          }

          state.isMonacoLoaded = true;
          resolve(window.monaco);
        });
      };

      script.onerror = () => {
        reject(new Error('Failed to load Monaco Editor'));
      };

      document.head.appendChild(script);
    });
  }

  /**
   * Detect theme (light/dark mode)
   */
  function detectTheme() {
    // Check for dark mode
    state.isDarkMode = document.documentElement.classList.contains('dark') ||
                       window.matchMedia('(prefers-color-scheme: dark)').matches;

    // Update editor themes if editors exist
    if (state.isMonacoLoaded) {
      state.editors.forEach(editor => {
        editor.updateOptions({
          theme: state.isDarkMode ? 'vs-dark' : 'vs'
        });
      });
    }
  }

  /**
   * Create a Monaco Editor instance
   * @param {HTMLElement} container - The container element
   * @param {Object} options - Editor options
   * @returns {Object} The Monaco Editor instance
   */
  function createEditor(container, options = {}) {
    if (!state.isMonacoLoaded) {
      throw new Error('Monaco Editor is not loaded');
    }

    const id = container.id || `editor-${Math.random().toString(36).substr(2, 9)}`;
    if (!container.id) {
      container.id = id;
    }

    const language = options.language || container.dataset.language || 'php';
    const code = options.code || container.dataset.code || '<?php\n\n// Your code here\n';

    // Store original code for reset functionality
    state.originalCode.set(id, code);

    // Create editor
    const editor = monaco.editor.create(container, {
      ...config.editorOptions,
      ...options,
      language: language,
      value: code,
      theme: state.isDarkMode ? 'vs-dark' : 'vs'
    });

    state.editors.set(id, editor);

    return editor;
  }

  /**
   * Reset an editor to its original code
   * @param {string} id - The editor ID
   */
  function resetEditor(id) {
    const editor = state.editors.get(id);
    const originalCode = state.originalCode.get(id);

    if (editor && originalCode) {
      editor.setValue(originalCode);
    }
  }

  /**
   * Get the code from an editor
   * @param {string} id - The editor ID
   * @returns {string} The editor code
   */
  function getEditorCode(id) {
    const editor = state.editors.get(id);

    if (editor) {
      return editor.getValue();
    }

    return '';
  }

  /**
   * Dispose an editor
   * @param {string} id - The editor ID
   */
  function disposeEditor(id) {
    const editor = state.editors.get(id);

    if (editor) {
      editor.dispose();
      state.editors.delete(id);
      state.originalCode.delete(id);
    }
  }

  // Initialize
  function init() {
    // Detect theme
    detectTheme();

    // Listen for theme changes
    const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    darkModeMediaQuery.addEventListener('change', (e) => {
      state.isDarkMode = e.matches;

      // Update editor themes
      if (state.isMonacoLoaded) {
        state.editors.forEach(editor => {
          editor.updateOptions({
            theme: state.isDarkMode ? 'vs-dark' : 'vs'
          });
        });
      }
    });

    // Check for manual theme toggles if they exist
    const themeToggle = document.getElementById('theme-toggle');
    if (themeToggle) {
      themeToggle.addEventListener('click', () => {
        // Allow time for the DOM to update with the new theme
        setTimeout(() => {
          detectTheme();
        }, 100);
      });
    }
  }

  // Export to window
  window.MonacoLoader = {
    load: loadMonaco,
    createEditor: createEditor,
    resetEditor: resetEditor,
    getEditorCode: getEditorCode,
    disposeEditor: disposeEditor,
    getState: () => ({ ...state })
  };

  // Initialize when the DOM is loaded
  document.addEventListener('DOMContentLoaded', init);
})();
