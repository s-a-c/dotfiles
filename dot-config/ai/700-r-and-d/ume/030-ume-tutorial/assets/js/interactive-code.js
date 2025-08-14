/**
 * UME Interactive Code Examples
 *
 * This script provides functionality for interactive code examples in the UME 010-consolidated-starter-kits.
 * It handles:
 * - Initializing Monaco Editor instances
 * - Running code examples
 * - Resetting code to initial state
 * - Copying code to clipboard
 * - Saving user modifications
 * - Handling light/dark mode
 */

// Configuration
const config = {
  // Monaco Editor CDN
  monacoBaseUrl: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.36.1/min',

  // PHP execution endpoint (placeholder - would be implemented separately)
  phpExecutionEndpoint: '/api/run-php-code',

  // Local storage key prefix for saving user modifications
  storageKeyPrefix: 'ume-code-example-',

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

// State management
const state = {
  editors: new Map(), // Map of editor instances
  originalCode: new Map(), // Map of original code for reset functionality
  isDarkMode: false, // Current theme mode
  isMonacoLoaded: false // Monaco loading state
};

/**
 * Initialize the interactive code examples
 */
function initInteractiveCodeExamples() {
  // Check if there are any interactive code examples on the page
  const examples = document.querySelectorAll('.interactive-code-example');
  if (examples.length === 0) return;

  // Load Monaco Editor if needed
  if (!state.isMonacoLoaded) {
    loadMonacoEditor().then(() => {
      initializeExamples(examples);
    }).catch(error => {
      console.error('Failed to load Monaco Editor:', error);
      displayErrorMessage('Failed to load code editor. Please refresh the page or try again later.');
    });
  } else {
    initializeExamples(examples);
  }

  // Set up theme detection
  detectTheme();
}

/**
 * Load the Monaco Editor from CDN
 */
function loadMonacoEditor() {
  return new Promise((resolve, reject) => {
    // Check if Monaco is already loaded
    if (window.monaco) {
      state.isMonacoLoaded = true;
      resolve();
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
        resolve();
      });
    };

    script.onerror = () => {
      reject(new Error('Failed to load Monaco Editor'));
    };

    document.head.appendChild(script);
  });
}

/**
 * Initialize all interactive code examples on the page
 */
function initializeExamples(examples) {
  examples.forEach((example, index) => {
    const container = example.querySelector('.monaco-editor');
    if (!container) return;

    const id = `editor-${index}`;
    container.id = id;

    const language = container.dataset.language || 'php';
    const code = container.dataset.code || '<?php\n\n// Your code here\n';

    // Store original code for reset functionality
    state.originalCode.set(id, code);

    // Check if we have a saved version
    const savedCode = getSavedCode(id);
    const initialCode = savedCode || code;

    // Create editor
    const editor = monaco.editor.create(container, {
      ...config.editorOptions,
      language: language,
      value: initialCode,
      theme: state.isDarkMode ? 'vs-dark' : 'vs'
    });

    state.editors.set(id, editor);

    // Set up buttons
    setupEditorButtons(example, id);
  });
}

/**
 * Set up the editor buttons (Run, Reset, Copy)
 */
function setupEditorButtons(example, editorId) {
  const runButton = example.querySelector('.run-button');
  const resetButton = example.querySelector('.reset-button');
  const copyButton = example.querySelector('.copy-button');
  const statusElement = example.querySelector('.editor-status');
  const outputContent = example.querySelector('.output-content');

  if (runButton) {
    runButton.addEventListener('click', () => {
      const editor = state.editors.get(editorId);
      if (!editor) return;

      const code = editor.getValue();

      // Save current code
      saveCode(editorId, code);

      // Show loading state
      if (statusElement) statusElement.textContent = 'Running...';
      if (outputContent) outputContent.textContent = 'Executing code...';

      // Execute code (this would call the backend in a real implementation)
      executeCode(code)
        .then(result => {
          if (outputContent) outputContent.textContent = result;
          if (statusElement) statusElement.textContent = 'Execution complete';

          // Clear status after a delay
          setTimeout(() => {
            if (statusElement) statusElement.textContent = '';
          }, 3000);
        })
        .catch(error => {
          if (outputContent) outputContent.textContent = `Error: ${error.message}`;
          if (statusElement) statusElement.textContent = 'Execution failed';
        });
    });
  }

  if (resetButton) {
    resetButton.addEventListener('click', () => {
      const editor = state.editors.get(editorId);
      if (!editor) return;

      const originalCode = state.originalCode.get(editorId);
      editor.setValue(originalCode);

      // Clear saved code
      clearSavedCode(editorId);

      if (statusElement) statusElement.textContent = 'Reset to original code';
      if (outputContent) outputContent.textContent = '';

      // Clear status after a delay
      setTimeout(() => {
        if (statusElement) statusElement.textContent = '';
      }, 3000);
    });
  }

  if (copyButton) {
    copyButton.addEventListener('click', () => {
      const editor = state.editors.get(editorId);
      if (!editor) return;

      const code = editor.getValue();

      // Copy to clipboard
      navigator.clipboard.writeText(code).then(() => {
        if (statusElement) statusElement.textContent = 'Copied to clipboard';

        // Clear status after a delay
        setTimeout(() => {
          if (statusElement) statusElement.textContent = '';
        }, 3000);
      }).catch(error => {
        console.error('Failed to copy code:', error);
        if (statusElement) statusElement.textContent = 'Failed to copy code';
      });
    });
  }
}

/**
 * Execute PHP code (placeholder implementation)
 * In a real implementation, this would send the code to a backend for execution
 */
function executeCode(code) {
  return new Promise((resolve, reject) => {
    // This is a placeholder - in a real implementation, this would call a backend API
    // For now, we'll simulate a response

    setTimeout(() => {
      // Simple validation
      if (!code.includes('<?php')) {
        reject(new Error('Code must include <?php tag'));
        return;
      }

      // Simulate output based on the code
      try {
        let output = 'Output would appear here in a real implementation.\n\n';

        // Detect some common patterns for simulation
        if (code.includes('echo')) {
          const echoMatch = code.match(/echo\s+["'](.+?)["']/);
          if (echoMatch) {
            output += echoMatch[1] + '\n';
          }
        }

        if (code.includes('function')) {
          output += 'Function defined.\n';
        }

        if (code.includes('class')) {
          output += 'Class defined.\n';
        }

        if (code.includes('return')) {
          output += 'Return statement found, but values are not displayed without echo.\n';
        }

        resolve(output);
      } catch (error) {
        reject(new Error('Error parsing code'));
      }
    }, 500); // Simulate network delay
  });
}

/**
 * Save code to local storage
 */
function saveCode(editorId, code) {
  const key = `${config.storageKeyPrefix}${editorId}`;
  localStorage.setItem(key, code);
}

/**
 * Get saved code from local storage
 */
function getSavedCode(editorId) {
  const key = `${config.storageKeyPrefix}${editorId}`;
  return localStorage.getItem(key);
}

/**
 * Clear saved code from local storage
 */
function clearSavedCode(editorId) {
  const key = `${config.storageKeyPrefix}${editorId}`;
  localStorage.removeItem(key);
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
        state.isDarkMode = document.documentElement.classList.contains('dark') ||
                           window.matchMedia('(prefers-color-scheme: dark)').matches;

        // Update editor themes
        if (state.isMonacoLoaded) {
          state.editors.forEach(editor => {
            editor.updateOptions({
              theme: state.isDarkMode ? 'vs-dark' : 'vs'
            });
          });
        }
      }, 100);
    });
  }
}

/**
 * Display an error message
 */
function displayErrorMessage(message) {
  const examples = document.querySelectorAll('.interactive-code-example');

  examples.forEach(example => {
    const container = example.querySelector('.monaco-editor');
    if (!container) return;

    container.innerHTML = `<div class="error-message">${message}</div>`;
  });
}

/**
 * Process interactive code blocks from Markdown
 * This function converts the custom Markdown syntax to HTML
 */
function processMarkdownCodeBlocks() {
  const content = document.querySelector('.markdown-content');
  if (!content) return;

  // Find all interactive code blocks
  const regex = /:::interactive-code\s+([\s\S]*?):::/g;
  let match;
  let index = 0;

  while ((match = regex.exec(content.innerHTML)) !== null) {
    // Parse the block content
    const blockContent = match[1];
    const config = parseCodeBlockConfig(blockContent);

    // Create the HTML for the interactive code example
    const html = createInteractiveCodeHTML(config, index);

    // Replace the Markdown syntax with the HTML
    content.innerHTML = content.innerHTML.replace(match[0], html);

    index++;
  }

  // Initialize the examples after processing
  initInteractiveCodeExamples();
}

/**
 * Parse the configuration from a code block
 */
function parseCodeBlockConfig(content) {
  const config = {
    title: 'Code Example',
    description: '',
    language: 'php',
    editable: true,
    code: '',
    explanation: '',
    challenges: []
  };

  // Extract key-value pairs
  const lines = content.split('\n');
  let currentKey = null;
  let currentValue = [];

  for (const line of lines) {
    // Check if this is a new key
    const keyMatch = line.match(/^(\w+):\s*(.*)$/);

    if (keyMatch) {
      // Save the previous key if there was one
      if (currentKey) {
        config[currentKey] = currentValue.join('\n').trim();
        currentValue = [];
      }

      currentKey = keyMatch[1];

      // If this is a simple value (not a multi-line value)
      if (!line.includes('|')) {
        config[currentKey] = keyMatch[2].trim();
        currentKey = null;
      } else {
        // This is the start of a multi-line value
        currentValue = [];
      }
    } else if (currentKey) {
      // This is part of a multi-line value
      currentValue.push(line);
    }
  }

  // Save the last key if there was one
  if (currentKey) {
    config[currentKey] = currentValue.join('\n').trim();
  }

  // Parse challenges if they exist
  if (typeof config.challenges === 'string') {
    config.challenges = config.challenges
      .split('\n')
      .filter(line => line.trim().startsWith('-'))
      .map(line => line.trim().substring(1).trim());
  }

  return config;
}

/**
 * Create HTML for an interactive code example
 */
function createInteractiveCodeHTML(config, index) {
  const challengesHTML = config.challenges.length > 0
    ? `
      <div class="example-challenges">
        <h4>Challenges</h4>
        <ol>
          ${config.challenges.map(challenge => `<li>${challenge}</li>`).join('')}
        </ol>
      </div>
    `
    : '';

  return `
    <div class="interactive-code-example">
      <h3 class="example-title">${config.title}</h3>

      <div class="example-description">
        <p>${config.description}</p>
      </div>

      <div class="code-editor-container" data-language="${config.language}" data-editable="${config.editable}">
        <div class="editor-toolbar">
          <button class="run-button">Run Code</button>
          <button class="reset-button">Reset</button>
          <button class="copy-button">Copy</button>
          <div class="editor-status"></div>
        </div>

        <div class="monaco-editor" data-code="${escapeHtml(config.code)}"></div>

        <div class="output-panel">
          <div class="output-header">Output</div>
          <div class="output-content"></div>
        </div>
      </div>

      <div class="example-explanation">
        <h4>How it works</h4>
        ${config.explanation}
      </div>

      ${challengesHTML}
    </div>
  `;
}

/**
 * Escape HTML special characters
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Initialize when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
  initInteractiveCodeExamples();
  processMarkdownCodeBlocks();
});

// Re-initialize when the theme changes
window.addEventListener('theme-changed', function() {
  detectTheme();
});
