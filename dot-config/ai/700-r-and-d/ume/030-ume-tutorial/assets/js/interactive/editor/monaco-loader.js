/**
 * Monaco Editor Loader
 *
 * Loads and configures the Monaco editor for interactive code examples.
 * This file provides functionality to load the Monaco editor from CDN
 * and initialize it for use in interactive examples.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Monaco editor version
    version: '0.36.1',

    // CDN URL
    cdnUrl: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.36.1/min',

    // Default editor options
    defaultOptions: {
      language: 'php',
      theme: 'vs',
      automaticLayout: true,
      minimap: {
        enabled: false
      },
      scrollBeyondLastLine: false,
      lineNumbers: 'on',
      renderLineHighlight: 'all',
      tabSize: 4,
      insertSpaces: true,
      fontFamily: 'Menlo, Monaco, "Courier New", monospace',
      fontSize: 14,
      wordWrap: 'on',
      // Accessibility options
      accessibilitySupport: 'auto',
      ariaLabel: 'Code Editor',
      tabIndex: 0
    },

    // Theme configuration
    themes: {
      light: 'vs',
      dark: 'vs-dark'
    },

    // Keyboard shortcuts
    keyboardShortcuts: [
      { key: 'F1', command: 'editor.action.showAccessibilityHelp' },
      { key: 'Alt+F1', command: 'editor.action.quickCommand' },
      { key: 'Ctrl+S', command: 'editor.action.formatDocument' },
      { key: 'F9', command: 'runCode' },
      { key: 'Shift+F9', command: 'resetCode' }
    ]
  };

  // State
  const state = {
    loaded: false,
    loading: false,
    editors: new Map(),
    currentTheme: 'light'
  };

  /**
   * Load Monaco editor from CDN
   * @returns {Promise} - A promise that resolves when Monaco editor is loaded
   */
  function loadMonaco() {
    // Check if already loaded
    if (state.loaded && window.monaco) {
      return Promise.resolve(window.monaco);
    }

    // Check if currently loading
    if (state.loading) {
      return new Promise((resolve, reject) => {
        // Check every 100ms if Monaco is loaded
        const interval = setInterval(() => {
          if (state.loaded && window.monaco) {
            clearInterval(interval);
            resolve(window.monaco);
          }
        }, 100);

        // Timeout after 10 seconds
        setTimeout(() => {
          clearInterval(interval);
          reject(new Error('Timeout loading Monaco editor'));
        }, 10000);
      });
    }

    // Start loading
    state.loading = true;

    return new Promise((resolve, reject) => {
      // Create a script element to load the Monaco loader
      const script = document.createElement('script');
      script.src = `${config.cdnUrl}/vs/loader.js`;
      script.async = true;

      script.onload = () => {
        // Configure require
        window.require.config({
          paths: {
            vs: `${config.cdnUrl}/vs`
          }
        });

        // Load Monaco
        window.require(['vs/editor/editor.main'], () => {
          // Register PHP language if not already registered
          if (!monaco.languages.getLanguages().some(lang => lang.id === 'php')) {
            registerPHPLanguage();
          }

          // Set up themes
          setupThemes();

          // Mark as loaded
          state.loaded = true;
          state.loading = false;

          // Resolve with Monaco
          resolve(window.monaco);
        });
      };

      script.onerror = () => {
        state.loading = false;
        reject(new Error('Failed to load Monaco editor'));
      };

      // Add the script to the document
      document.head.appendChild(script);
    });
  }

  /**
   * Register PHP language
   */
  function registerPHPLanguage() {
    // This is a simplified version of PHP language support
    // In a real implementation, this would be more comprehensive
    monaco.languages.register({ id: 'php' });

    monaco.languages.setMonarchTokensProvider('php', {
      defaultToken: '',
      tokenPostfix: '.php',

      keywords: [
        'abstract', 'and', 'array', 'as', 'break',
        'callable', 'case', 'catch', 'class', 'clone',
        'const', 'continue', 'declare', 'default', 'die',
        'do', 'echo', 'else', 'elseif', 'empty',
        'enddeclare', 'endfor', 'endforeach', 'endif', 'endswitch',
        'endwhile', 'eval', 'exit', 'extends', 'final',
        'finally', 'for', 'foreach', 'function', 'global',
        'goto', 'if', 'implements', 'include', 'include_once',
        'instanceof', 'insteadof', 'interface', 'isset', 'list',
        'namespace', 'new', 'or', 'print', 'private',
        'protected', 'public', 'require', 'require_once', 'return',
        'static', 'switch', 'throw', 'trait', 'try',
        'unset', 'use', 'var', 'while', 'xor', 'yield',
        'fn', 'match', 'enum'
      ],

      builtins: [
        'array', 'bool', 'callable', 'float', 'int',
        'iterable', 'mixed', 'never', 'null', 'object',
        'resource', 'string', 'void', 'false', 'true',
        'self', 'parent', 'static'
      ],

      operators: [
        '=', '+=', '-=', '*=', '**=', '/=', '.=', '%=', '&=',
        '|=', '^=', '<<=', '>>=', '??=', '||', '&&', '|',
        '^', '&', '==', '===', '!=', '!==', '<', '>', '<=',
        '>=', '<=>', '<<', '>>', '+', '-', '*', '/', '%',
        '!', '~', '++', '--', '.', '?', ':', '??', '=>', '->',
        '?->', '??->'
      ],

      symbols: /[=><!~?:&|+\-*\/\^%\.]+/,

      escapes: /\\(?:[abfnrtv\\"']|x[0-9A-Fa-f]{1,4}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,

      tokenizer: {
        root: [
          [/[{}]/, 'delimiter.bracket'],
          [/[;]/, 'delimiter'],
          [/[()]/, '@brackets'],
          [/\$[a-zA-Z_]\w*/, 'variable'],
          [/[a-zA-Z_]\w*/, {
            cases: {
              '@keywords': 'keyword',
              '@builtins': 'type',
              '@default': 'identifier'
            }
          }],
          [/\#\[[a-zA-Z_]\w*\]/, 'annotation'],
          [/"([^"\\]|\\.)*$/, 'string.invalid'],
          [/'([^'\\]|\\.)*$/, 'string.invalid'],
          [/"/, 'string', '@string_double'],
          [/'/, 'string', '@string_single'],
          [/\#/, 'comment', '@comment_line'],
          [/\/\//, 'comment', '@comment_line'],
          [/\/\*/, 'comment', '@comment_block'],
          [/[\+\-\*\/\%]/, 'operator'],
          [/\d+\.\d+([eE][\-+]?\d+)?/, 'number.float'],
          [/\d+/, 'number'],
          [/[,]/, 'delimiter'],
          [/\s+/, 'white']
        ],

        string_double: [
          [/[^\\"]+/, 'string'],
          [/@escapes/, 'string.escape'],
          [/\\./, 'string.escape.invalid'],
          [/"/, 'string', '@pop']
        ],

        string_single: [
          [/[^\\']+/, 'string'],
          [/@escapes/, 'string.escape'],
          [/\\./, 'string.escape.invalid'],
          [/'/, 'string', '@pop']
        ],

        comment_line: [
          [/.$/, 'comment', '@pop'],
          [/./, 'comment']
        ],

        comment_block: [
          [/\*\//, 'comment', '@pop'],
          [/./, 'comment']
        ]
      }
    });

    monaco.languages.setLanguageConfiguration('php', {
      wordPattern: /(-?\d*\.\d\w*)|([^\`\~\!\@\#\%\^\&\*\(\)\-\=\+\[\{\]\}\\\|\;\:\'\"\,\.\<\>\/\?\s]+)/g,

      comments: {
        lineComment: '//',
        blockComment: ['/*', '*/']
      },

      brackets: [
        ['{', '}'],
        ['[', ']'],
        ['(', ')']
      ],

      autoClosingPairs: [
        { open: '{', close: '}' },
        { open: '[', close: ']' },
        { open: '(', close: ')' },
        { open: '"', close: '"', notIn: ['string'] },
        { open: "'", close: "'", notIn: ['string', 'comment'] }
      ],

      surroundingPairs: [
        { open: '{', close: '}' },
        { open: '[', close: ']' },
        { open: '(', close: ')' },
        { open: '"', close: '"' },
        { open: "'", close: "'" }
      ],

      folding: {
        markers: {
          start: new RegExp('^\\s*//\\s*#?region\\b'),
          end: new RegExp('^\\s*//\\s*#?endregion\\b')
        }
      }
    });
  }

  /**
   * Set up themes
   */
  function setupThemes() {
    // Define custom themes if needed
    // For now, we'll use the built-in themes
  }

  /**
   * Create a Monaco editor instance
   * @param {HTMLElement} container - The container element
   * @param {string} code - The initial code
   * @param {Object} options - The editor options
   * @returns {Object} - The Monaco editor instance
   */
  function createEditor(container, code, options = {}) {
    // Load Monaco if not already loaded
    return loadMonaco().then(monaco => {
      // Merge options with defaults
      const editorOptions = {
        ...config.defaultOptions,
        ...options,
        value: code,
        theme: config.themes[state.currentTheme]
      };

      // Set accessibility attributes on container
      container.setAttribute('role', 'application');
      container.setAttribute('aria-label', options.ariaLabel || 'Code Editor');

      // Create the editor
      const editor = monaco.editor.create(container, editorOptions);

      // Add keyboard shortcuts
      addKeyboardShortcuts(editor);

      // Store the editor
      const id = `editor-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      state.editors.set(id, editor);

      // Return the editor and ID
      return { editor, id };
    });
  }

  /**
   * Add keyboard shortcuts to the editor
   * @param {Object} editor - The Monaco editor instance
   */
  function addKeyboardShortcuts(editor) {
    if (!window.monaco) return;

    // Register custom commands
    editor._commandService.addCommand({
      id: 'runCode',
      handler: () => {
        // Find the run button for this editor
        const editorElement = editor.getDomNode();
        if (!editorElement) return;

        const container = editorElement.closest('.interactive-code-example');
        if (!container) return;

        const runButton = container.querySelector('.run-button');
        if (runButton) {
          runButton.click();
        }
      }
    });

    editor._commandService.addCommand({
      id: 'resetCode',
      handler: () => {
        // Find the reset button for this editor
        const editorElement = editor.getDomNode();
        if (!editorElement) return;

        const container = editorElement.closest('.interactive-code-example');
        if (!container) return;

        const resetButton = container.querySelector('.reset-button');
        if (resetButton) {
          resetButton.click();
        }
      }
    });

    // Add keyboard shortcuts
    config.keyboardShortcuts.forEach(shortcut => {
      editor.addCommand(
        monaco.KeyMod.chord(monaco.KeyCode[shortcut.key]),
        () => {
          editor._commandService.executeCommand(shortcut.command);
        }
      );
    });
  }

  /**
   * Get an editor by ID
   * @param {string} id - The editor ID
   * @returns {Object|null} - The Monaco editor instance or null if not found
   */
  function getEditor(id) {
    return state.editors.get(id) || null;
  }

  /**
   * Set the theme for all editors
   * @param {string} theme - The theme name ('light' or 'dark')
   */
  function setTheme(theme) {
    if (!config.themes[theme]) {
      console.error(`Theme not found: ${theme}`);
      return;
    }

    // Update state
    state.currentTheme = theme;

    // Update all editors
    state.editors.forEach(editor => {
      editor.updateOptions({ theme: config.themes[theme] });
    });
  }

  /**
   * Initialize all Monaco editors in the document
   */
  function initializeEditors() {
    // Load Monaco
    loadMonaco().then(monaco => {
      // Find all editor containers
      const containers = document.querySelectorAll('.monaco-editor');

      // Create an editor for each container
      containers.forEach((container, index) => {
        // Get the code
        const code = container.dataset.code || '';

        // Get the language
        const language = container.closest('.code-editor-container')?.dataset.language || 'php';

        // Get the editable state
        const editable = container.closest('.code-editor-container')?.dataset.editable !== 'false';

        // Get the parent example for accessibility labeling
        const example = container.closest('.interactive-code-example');
        const title = example ? example.querySelector('.example-title')?.textContent : 'Code Example';

        // Create the editor
        createEditor(container, code, {
          language,
          readOnly: !editable,
          ariaLabel: `Code Editor for ${title}`
        }).then(({ editor, id }) => {
          // Store the ID on the container
          container.dataset.editorId = id;

          // Add accessibility attributes to surrounding elements
          if (example) {
            // Add ARIA attributes to buttons
            const runButton = example.querySelector('.run-button');
            if (runButton) {
              runButton.setAttribute('aria-label', `Run code for ${title}`);
              runButton.setAttribute('tabindex', '0');
            }

            const resetButton = example.querySelector('.reset-button');
            if (resetButton) {
              resetButton.setAttribute('aria-label', `Reset code for ${title}`);
              resetButton.setAttribute('tabindex', '0');
            }

            const copyButton = example.querySelector('.copy-button');
            if (copyButton) {
              copyButton.setAttribute('aria-label', `Copy code for ${title}`);
              copyButton.setAttribute('tabindex', '0');
            }

            // Add ARIA attributes to output panel
            const outputPanel = example.querySelector('.output-panel');
            if (outputPanel) {
              outputPanel.setAttribute('role', 'region');
              outputPanel.setAttribute('aria-label', `Output for ${title}`);
              outputPanel.setAttribute('aria-live', 'polite');
            }
          }

          // Log success
          console.log(`Initialized editor ${id}`);
        }).catch(error => {
          console.error(`Failed to initialize editor: ${error.message}`);
        });
      });
    }).catch(error => {
      console.error(`Failed to load Monaco: ${error.message}`);
    });
  }

  /**
   * Initialize the Monaco editor loader
   */
  function initialize() {
    // Check if the document is already loaded
    if (document.readyState === 'complete') {
      initializeEditors();
    } else {
      // Wait for the document to load
      document.addEventListener('DOMContentLoaded', initializeEditors);
    }

    // Listen for theme changes
    document.addEventListener('theme-changed', event => {
      setTheme(event.detail.theme);
    });
  }

  // Export to global namespace
  window.UMEInteractive = window.UMEInteractive || {};
  window.UMEInteractive.MonacoLoader = {
    initialize: initialize,
    loadMonaco: loadMonaco,
    createEditor: createEditor,
    getEditor: getEditor,
    setTheme: setTheme
  };
})();
