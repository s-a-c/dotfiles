/**
 * Interactive Examples
 *
 * This script integrates the Monaco Editor and Code Executor to create interactive code examples.
 */

(function() {
  // Configuration
  const config = {
    // Selector for interactive code examples
    selector: '.interactive-code-example',

    // Local storage key prefix for saving user modifications
    storageKeyPrefix: 'ume-code-example-',

    // Browser detection
    browsers: {
      isChrome: navigator.userAgent.indexOf('Chrome') > -1,
      isFirefox: navigator.userAgent.indexOf('Firefox') > -1,
      isSafari: navigator.userAgent.indexOf('Safari') > -1 && navigator.userAgent.indexOf('Chrome') === -1,
      isEdge: navigator.userAgent.indexOf('Edg') > -1,
      isIE: navigator.userAgent.indexOf('Trident/') > -1,
      isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
    }
  };

  // Apply browser-specific fixes
  function applyBrowserFixes() {
    const html = document.documentElement;

    // Add browser classes to HTML element
    if (config.browsers.isChrome) html.classList.add('browser-chrome');
    if (config.browsers.isFirefox) html.classList.add('browser-firefox');
    if (config.browsers.isSafari) html.classList.add('browser-safari');
    if (config.browsers.isEdge) html.classList.add('browser-edge');
    if (config.browsers.isIE) html.classList.add('browser-ie');
    if (config.browsers.isMobile) html.classList.add('browser-mobile');

    // Safari-specific fixes
    if (config.browsers.isSafari) {
      // Fix for Safari flexbox issues
      document.querySelectorAll('.interactive-code-example .editor-toolbar').forEach(toolbar => {
        toolbar.style.display = 'block';
        setTimeout(() => {
          toolbar.style.display = 'flex';
        }, 0);
      });
    }

    // IE-specific fixes
    if (config.browsers.isIE) {
      // Show warning for IE users
      const examples = document.querySelectorAll('.interactive-code-example');
      examples.forEach(example => {
        const warning = document.createElement('div');
        warning.className = 'browser-warning';
        warning.innerHTML = 'Internet Explorer is not fully supported. Please use a modern browser for the best experience.';
        example.insertBefore(warning, example.firstChild);
      });
    }
  }

  // State
  const state = {
    examples: new Map()
  };

  /**
   * Initialize interactive code examples
   */
  function initializeExamples() {
    // Find all interactive code examples
    const examples = document.querySelectorAll(config.selector);

    // If there are no examples, return
    if (examples.length === 0) {
      return;
    }

    // Load Monaco Editor
    window.MonacoLoader.load()
      .then(() => {
        // Initialize each example
        examples.forEach((example, index) => {
          initializeExample(example, index);
        });
      })
      .catch(error => {
        console.error('Failed to load Monaco Editor:', error);

        // Display error message
        examples.forEach(example => {
          const container = example.querySelector('.monaco-editor');
          if (container) {
            container.innerHTML = `<div class="error-message">Failed to load code editor: ${error.message}</div>`;
          }
        });
      });
  }

  /**
   * Initialize an interactive code example
   * @param {HTMLElement} example - The example element
   * @param {number} index - The example index
   */
  function initializeExample(example, index) {
    // Get the editor container
    const container = example.querySelector('.monaco-editor');
    if (!container) {
      return;
    }

    // Set the editor ID
    const id = `editor-${index}`;
    container.id = id;

    // Get the language and code
    const language = container.dataset.language || 'php';
    const originalCode = container.dataset.code || '<?php\n\n// Your code here\n';

    // Check if we have a saved version
    const savedCode = getSavedCode(id);
    const initialCode = savedCode || originalCode;

    // Create the editor
    const editor = window.MonacoLoader.createEditor(container, {
      language: language,
      code: initialCode
    });

    // Store the example
    state.examples.set(id, {
      element: example,
      editor: editor,
      language: language,
      originalCode: originalCode // Store the original code for reset functionality
    });

    // Set up buttons
    setupButtons(example, id);

    // Add a reset confirmation dialog to the example
    const resetDialog = document.createElement('div');
    resetDialog.className = 'reset-confirmation-dialog';
    resetDialog.setAttribute('role', 'dialog');
    resetDialog.setAttribute('aria-modal', 'true');
    resetDialog.setAttribute('aria-labelledby', `${id}-reset-dialog-title`);
    resetDialog.setAttribute('aria-describedby', `${id}-reset-dialog-desc`);
    resetDialog.style.display = 'none';

    resetDialog.innerHTML = `
      <div class="dialog-content">
        <h4 id="${id}-reset-dialog-title">Reset Code?</h4>
        <p id="${id}-reset-dialog-desc">This will reset the code to its original state. Any changes you've made will be lost.</p>
        <div class="dialog-buttons">
          <button class="cancel-button">Cancel</button>
          <button class="confirm-button">Reset</button>
        </div>
      </div>
    `;

    example.appendChild(resetDialog);

    // Set up dialog buttons
    const cancelButton = resetDialog.querySelector('.cancel-button');
    const confirmButton = resetDialog.querySelector('.confirm-button');

    cancelButton.addEventListener('click', () => {
      resetDialog.style.display = 'none';
    });

    confirmButton.addEventListener('click', () => {
      resetDialog.style.display = 'none';
      resetEditor(id);
    });

    // Close dialog when clicking outside
    resetDialog.addEventListener('click', (event) => {
      if (event.target === resetDialog) {
        resetDialog.style.display = 'none';
      }
    });

    // Close dialog on escape key
    resetDialog.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        resetDialog.style.display = 'none';
      }
    });
  }

  /**
   * Set up the buttons for an example
   * @param {HTMLElement} example - The example element
   * @param {string} id - The editor ID
   */
  function setupButtons(example, id) {
    // Get the buttons
    const runButton = example.querySelector('.run-button');
    const resetButton = example.querySelector('.reset-button');
    const copyButton = example.querySelector('.copy-button');
    const formatButton = example.querySelector('.format-button');
    const fullscreenButton = example.querySelector('.fullscreen-button');
    const clearOutputButton = example.querySelector('.clear-output-button');
    const copyOutputButton = example.querySelector('.copy-output-button');

    // Get the container elements
    const editorContainer = example.querySelector('.code-editor-container');
    const outputPanel = example.querySelector('.output-panel');

    // Get the status and output elements
    const statusElement = example.querySelector('.editor-status');
    const statusText = statusElement?.querySelector('.status-text');
    const statusIcon = statusElement?.querySelector('.status-icon');
    const outputContent = example.querySelector('.output-content');

    // Set up the run button
    if (runButton) {
      runButton.addEventListener('click', () => {
        // Get the code
        const code = window.MonacoLoader.getEditorCode(id);

        // Get the language
        const language = state.examples.get(id)?.language || 'php';

        // Update status with loading indicator
        const statusLoadingIndicator = document.createElement('div');
        statusLoadingIndicator.className = 'loading-indicator inline small';
        updateStatus('info', 'Running...', statusLoadingIndicator);

        // Clear output
        if (outputContent) {
          outputContent.textContent = '';
        }

        // Add loading indicator to output panel
        const loadingIndicator = document.createElement('div');
        loadingIndicator.className = 'loading-indicator with-text';
        loadingIndicator.setAttribute('data-text', 'Executing code...');
        outputContent.appendChild(loadingIndicator);

        // Add loading progress bar
        const loadingProgress = document.createElement('div');
        loadingProgress.className = 'loading-progress';
        loadingProgress.style.width = '0%';
        outputPanel.appendChild(loadingProgress);

        // Simulate progress
        let progress = 0;
        const progressInterval = setInterval(() => {
          progress += Math.random() * 15;
          if (progress > 90) progress = 90; // Cap at 90% until complete
          loadingProgress.style.width = `${progress}%`;
        }, 300);

        // Execute the code
        window.CodeExecutor.execute(code, language)
          .then(result => {
            // Remove loading indicator
            if (loadingIndicator.parentNode) {
              outputContent.removeChild(loadingIndicator);
            }

            // Complete progress bar and remove it
            clearInterval(progressInterval);
            loadingProgress.style.width = '100%';
            setTimeout(() => {
              if (loadingProgress.parentNode) {
                outputPanel.removeChild(loadingProgress);
              }
            }, 500);

            // Update output
            if (outputContent) {
              // Format the output
              const formattedOutput = formatOutput(result);
              outputContent.innerHTML = formattedOutput;
              outputContent.classList.remove('error');
              outputContent.classList.add('success');
            }

            // Update status
            updateStatus('success', 'Execution complete', '✓');

            // Clear status after a delay
            setTimeout(() => {
              clearStatus();
            }, 3000);
          })
          .catch(error => {
            // Remove loading indicator
            if (loadingIndicator.parentNode) {
              outputContent.removeChild(loadingIndicator);
            }

            // Complete progress bar and remove it
            clearInterval(progressInterval);
            loadingProgress.style.width = '100%';
            setTimeout(() => {
              if (loadingProgress.parentNode) {
                outputPanel.removeChild(loadingProgress);
              }
            }, 500);

            // Update output
            if (outputContent) {
              // Format the error
              let formattedError = '';

              // Check if the error has a stack trace
              if (error.stack) {
                const stackLines = error.stack.split('\n');
                // Format the first line (error message)
                formattedError += `<div class="output-line error">${escapeHtml(stackLines[0])}</div>`;

                // Format the stack trace
                for (let i = 1; i < stackLines.length; i++) {
                  formattedError += `<div class="output-line stack-trace">${escapeHtml(stackLines[i])}</div>`;
                }
              } else {
                // Simple error message
                formattedError = `<div class="output-line error">Error: ${escapeHtml(error.message || 'Unknown error')}</div>`;
              }

              // Add error details if available
              if (error.details) {
                formattedError += `<div class="output-line error-details">${escapeHtml(error.details)}</div>`;
              }

              // Add line number information if available
              if (error.line) {
                formattedError += `<div class="output-line error-location">Line ${error.line}${error.column ? `, Column ${error.column}` : ''}</div>`;
              }

              // Add error code if available
              if (error.code) {
                formattedError += `<div class="output-line error-code">Error code: ${error.code}</div>`;
              }

              // Add suggestions if available
              if (error.suggestions && error.suggestions.length > 0) {
                formattedError += `<div class="output-line error-suggestions">Suggestions:</div>`;
                error.suggestions.forEach(suggestion => {
                  formattedError += `<div class="output-line suggestion">- ${escapeHtml(suggestion)}</div>`;
                });
              }

              outputContent.innerHTML = formattedError;
              outputContent.classList.remove('success');
              outputContent.classList.add('error');
            }

            // Update status
            updateStatus('error', 'Execution failed', '✗');

            // Clear status after a delay
            setTimeout(() => {
              clearStatus();
            }, 3000);
          });
      });
    }

    /**
     * Update the status display
     * @param {string} type - The status type ('info', 'success', 'error')
     * @param {string} message - The status message
     * @param {string|HTMLElement} icon - The status icon (string or HTML element)
     */
    function updateStatus(type, message, icon = '') {
      if (statusElement) {
        // Remove existing status classes
        statusElement.classList.remove('info', 'success', 'error');

        // Add the new status class
        statusElement.classList.add(type);

        // Update the status text
        if (statusText) {
          statusText.textContent = message;
        } else {
          statusElement.textContent = message;
        }

        // Update the status icon
        if (statusIcon) {
          // Clear previous content
          statusIcon.innerHTML = '';

          // Add the new icon
          if (typeof icon === 'string') {
            statusIcon.textContent = icon;
          } else if (icon instanceof HTMLElement) {
            statusIcon.appendChild(icon);
          }
        }

        // Announce to screen readers
        const srAnnouncement = example.querySelector('.sr-announcements');
        if (srAnnouncement) {
          srAnnouncement.textContent = message;
        }
      }
    }

    /**
     * Clear the status display
     */
    function clearStatus() {
      if (statusElement) {
        // Remove status classes
        statusElement.classList.remove('info', 'success', 'error');

        // Clear the status text
        if (statusText) {
          statusText.textContent = '';
        } else {
          statusElement.textContent = '';
        }

        // Clear the status icon
        if (statusIcon) {
          statusIcon.textContent = '';
        }
      }
    }

    // Set up the reset button
    if (resetButton) {
      resetButton.addEventListener('click', () => {
        // Show reset confirmation dialog
        const resetDialog = example.querySelector('.reset-confirmation-dialog');
        if (resetDialog) {
          resetDialog.style.display = 'flex';
          const confirmButton = resetDialog.querySelector('.confirm-button');
          if (confirmButton) {
            confirmButton.focus();
          }
        } else {
          // If dialog doesn't exist, reset directly
          resetEditor(id);
        }
      });
    }

    /**
     * Reset the editor to its original state
     * @param {string} id - The editor ID
     */
    function resetEditor(id) {
      const example = state.examples.get(id);
      if (!example) return;

      // Get the original code
      const originalCode = example.originalCode;

      // Set the editor value
      example.editor.setValue(originalCode);

      // Clear saved code
      clearSavedCode(id);

      // Update status
      if (statusElement) {
        statusElement.textContent = 'Reset to original code';
        statusElement.className = 'editor-status success';

        // Clear status after a delay
        setTimeout(() => {
          statusElement.textContent = '';
          statusElement.className = 'editor-status';
        }, 3000);
      }

      // Announce to screen readers
      const srAnnouncement = example.element.querySelector('.sr-announcements');
      if (srAnnouncement) {
        srAnnouncement.textContent = 'Code has been reset to its original state.';
        setTimeout(() => {
          srAnnouncement.textContent = '';
        }, 3000);
      }
    }

    // Set up the copy button
    if (copyButton) {
      copyButton.addEventListener('click', () => {
        // Get the code
        const code = window.MonacoLoader.getEditorCode(id);

        // Copy to clipboard
        navigator.clipboard.writeText(code)
          .then(() => {
            // Update status
            updateStatus('success', 'Copied to clipboard', '✓');

            // Clear status after a delay
            setTimeout(() => {
              clearStatus();
            }, 3000);
          })
          .catch(error => {
            console.error('Failed to copy code:', error);

            // Update status
            updateStatus('error', 'Failed to copy code', '✗');

            // Clear status after a delay
            setTimeout(() => {
              clearStatus();
            }, 3000);
          });
      });
    }

    // Set up the format button
    if (formatButton) {
      formatButton.addEventListener('click', () => {
        // Get the editor
        const example = state.examples.get(id);
        if (!example || !example.editor) {
          updateStatus('error', 'Editor not found', '✗');
          return;
        }

        try {
          // Format the code
          example.editor.getAction('editor.action.formatDocument').run();

          // Update status
          updateStatus('success', 'Code formatted', '✓');

          // Clear status after a delay
          setTimeout(() => {
            clearStatus();
          }, 3000);
        } catch (error) {
          console.error('Failed to format code:', error);

          // Update status
          updateStatus('error', 'Failed to format code', '✗');

          // Clear status after a delay
          setTimeout(() => {
            clearStatus();
          }, 3000);
        }
      });
    }

    // Set up the fullscreen button
    if (fullscreenButton && editorContainer) {
      fullscreenButton.addEventListener('click', () => {
        // Toggle fullscreen class
        editorContainer.classList.toggle('fullscreen');

        // Get the editor
        const example = state.examples.get(id);
        if (example && example.editor) {
          // Trigger layout update
          setTimeout(() => {
            example.editor.layout();
          }, 100);
        }

        // Update button state
        const isFullscreen = editorContainer.classList.contains('fullscreen');
        fullscreenButton.classList.toggle('active', isFullscreen);

        // Update button text
        const buttonText = fullscreenButton.querySelector('.button-text');
        if (buttonText) {
          buttonText.textContent = isFullscreen ? 'Exit Fullscreen' : 'Fullscreen';
        }

        // Update tooltip
        const tooltip = fullscreenButton.querySelector('.tooltip');
        if (tooltip) {
          tooltip.textContent = isFullscreen ? 'Exit fullscreen mode' : 'Toggle fullscreen mode';
        }

        // Update status
        updateStatus('info', isFullscreen ? 'Entered fullscreen mode' : 'Exited fullscreen mode');

        // Clear status after a delay
        setTimeout(() => {
          clearStatus();
        }, 2000);

        // Add escape key handler for fullscreen mode
        if (isFullscreen) {
          const escapeHandler = (event) => {
            if (event.key === 'Escape') {
              // Exit fullscreen
              editorContainer.classList.remove('fullscreen');
              fullscreenButton.classList.remove('active');

              // Update button text
              if (buttonText) {
                buttonText.textContent = 'Fullscreen';
              }

              // Update tooltip
              if (tooltip) {
                tooltip.textContent = 'Toggle fullscreen mode';
              }

              // Trigger layout update
              if (example && example.editor) {
                setTimeout(() => {
                  example.editor.layout();
                }, 100);
              }

              // Remove the event listener
              document.removeEventListener('keydown', escapeHandler);

              // Update status
              updateStatus('info', 'Exited fullscreen mode');

              // Clear status after a delay
              setTimeout(() => {
                clearStatus();
              }, 2000);
            }
          };

          document.addEventListener('keydown', escapeHandler);
        }
      });
    }

    // Set up the clear output button
    if (clearOutputButton) {
      clearOutputButton.addEventListener('click', () => {
        // Clear the output
        if (outputContent) {
          outputContent.innerHTML = '';
          outputContent.classList.remove('success', 'error');
        }

        // Update status
        updateStatus('info', 'Output cleared');

        // Clear status after a delay
        setTimeout(() => {
          clearStatus();
        }, 2000);
      });
    }

    // Set up the copy output button
    if (copyOutputButton) {
      copyOutputButton.addEventListener('click', () => {
        // Get the output text
        const outputText = outputContent.textContent || '';

        if (!outputText.trim()) {
          // No output to copy
          updateStatus('info', 'No output to copy');

          // Clear status after a delay
          setTimeout(() => {
            clearStatus();
          }, 2000);
          return;
        }

        // Copy to clipboard
        navigator.clipboard.writeText(outputText)
          .then(() => {
            // Update status
            updateStatus('success', 'Output copied to clipboard', '✓');

            // Clear status after a delay
            setTimeout(() => {
              clearStatus();
            }, 3000);
          })
          .catch(error => {
            console.error('Failed to copy output:', error);

            // Update status
            updateStatus('error', 'Failed to copy output', '✗');

            // Clear status after a delay
            setTimeout(() => {
              clearStatus();
            }, 3000);
          });
      });
    }

    /**
     * Format output for display
     * @param {string} output - The raw output
     * @returns {string} - The formatted HTML
     */
    function formatOutput(output) {
      if (!output) return '';

      // Split by lines
      const lines = output.split('\n');

      // Process each line
      const formattedLines = lines.map(line => {
        // Escape HTML
        const escapedLine = escapeHtml(line);

        // Detect line type
        let lineClass = '';
        if (line.toLowerCase().includes('error')) {
          lineClass = 'error';
        } else if (line.toLowerCase().includes('warning')) {
          lineClass = 'warning';
        } else if (line.toLowerCase().includes('notice')) {
          lineClass = 'info';
        } else if (line.toLowerCase().includes('success')) {
          lineClass = 'success';
        }

        // Return formatted line
        return `<div class="output-line ${lineClass}">${escapedLine}</div>`;
      });

      // Join lines
      return formattedLines.join('');
    }

    // Save code on change
    const editor = state.examples.get(id)?.editor;
    if (editor) {
      editor.onDidChangeModelContent(() => {
        // Get the code
        const code = window.MonacoLoader.getEditorCode(id);

        // Save the code
        saveCode(id, code);
      });
    }
  }

  /**
   * Save code to local storage with versioning
   * @param {string} id - The editor ID
   * @param {string} code - The code to save
   */
  function saveCode(id, code) {
    try {
      // Create a versioned storage object
      const storageObject = {
        version: '1.0',
        timestamp: Date.now(),
        code: code,
        language: state.examples.get(id)?.language || 'php'
      };

      // Save to local storage
      localStorage.setItem(`${config.storageKeyPrefix}${id}`, JSON.stringify(storageObject));

      // Cleanup old stored code if needed
      cleanupOldStoredCode();
    } catch (error) {
      console.error('Failed to save code:', error);
    }
  }

  /**
   * Get saved code from local storage
   * @param {string} id - The editor ID
   * @returns {string|null} The saved code or null if not found
   */
  function getSavedCode(id) {
    try {
      const storedData = localStorage.getItem(`${config.storageKeyPrefix}${id}`);

      if (!storedData) {
        return null;
      }

      // Try to parse as JSON (new format)
      try {
        const storageObject = JSON.parse(storedData);
        return storageObject.code;
      } catch (parseError) {
        // If parsing fails, it might be the old format (just the code string)
        return storedData;
      }
    } catch (error) {
      console.error('Failed to get saved code:', error);
      return null;
    }
  }

  /**
   * Clear saved code from local storage
   * @param {string} id - The editor ID
   */
  function clearSavedCode(id) {
    try {
      localStorage.removeItem(`${config.storageKeyPrefix}${id}`);
    } catch (error) {
      console.error('Failed to clear saved code:', error);
    }
  }

  /**
   * Cleanup old stored code
   * Removes items older than 30 days or if there are more than 50 items
   */
  function cleanupOldStoredCode() {
    try {
      // Get all keys with our prefix
      const keys = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(config.storageKeyPrefix)) {
          keys.push(key);
        }
      }

      // If we have too many items, clean up
      if (keys.length > 50) {
        // Get all items with timestamps
        const items = keys.map(key => {
          try {
            const data = localStorage.getItem(key);
            const parsed = JSON.parse(data);
            return {
              key,
              timestamp: parsed.timestamp || 0
            };
          } catch (e) {
            // If we can't parse, use 0 as timestamp (will be removed first)
            return { key, timestamp: 0 };
          }
        });

        // Sort by timestamp (oldest first)
        items.sort((a, b) => a.timestamp - b.timestamp);

        // Remove oldest items until we have 40 left
        const itemsToRemove = items.slice(0, items.length - 40);
        itemsToRemove.forEach(item => {
          localStorage.removeItem(item.key);
        });
      }

      // Remove items older than 30 days
      const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
      keys.forEach(key => {
        try {
          const data = localStorage.getItem(key);
          const parsed = JSON.parse(data);
          if (parsed.timestamp && parsed.timestamp < thirtyDaysAgo) {
            localStorage.removeItem(key);
          }
        } catch (e) {
          // Ignore parsing errors
        }
      });
    } catch (error) {
      console.error('Failed to cleanup old stored code:', error);
    }
  }

  /**
   * Process interactive code blocks from Markdown
   */
  function processMarkdownCodeBlocks() {
    const content = document.querySelector('.markdown-content');
    if (!content) {
      return;
    }

    // Find all interactive code blocks
    const regex = /:::interactive-code\s+([\s\S]*?):::/g;
    let match;
    let index = 0;
    let contentHtml = content.innerHTML;

    // Collect all matches first to avoid modifying the HTML while iterating
    const matches = [];
    while ((match = regex.exec(contentHtml)) !== null) {
      matches.push({
        fullMatch: match[0],
        blockContent: match[1],
        index: index++
      });
    }

    // Now process all matches
    matches.forEach(match => {
      // Parse the block content
      const config = parseCodeBlockConfig(match.blockContent);

      // Create the HTML for the interactive code example
      const html = createInteractiveCodeHTML(config, match.index);

      // Replace the Markdown syntax with the HTML
      contentHtml = contentHtml.replace(match.fullMatch, html);
    });

    // Update the content
    content.innerHTML = contentHtml;

    // Initialize the examples
    initializeExamples();

    // Announce to screen readers that interactive examples are available
    const srAnnouncement = document.createElement('div');
    srAnnouncement.setAttribute('role', 'status');
    srAnnouncement.setAttribute('aria-live', 'polite');
    srAnnouncement.classList.add('visually-hidden');
    srAnnouncement.textContent = `${matches.length} interactive code examples are available on this page. Use keyboard navigation to explore them.`;
    document.body.appendChild(srAnnouncement);

    // Remove the announcement after it's been read
    setTimeout(() => {
      document.body.removeChild(srAnnouncement);
    }, 5000);
  }

  /**
   * Parse the configuration from a code block
   * @param {string} content - The code block content
   * @returns {Object} The parsed configuration
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

    // Parse the configuration
    const lines = content.split('\n');
    let currentSection = null;
    let currentContent = [];

    for (const line of lines) {
      // Check if this is a configuration line
      const configMatch = line.match(/^([a-z]+):\s*(.*)$/);
      if (configMatch) {
        // Save the current section
        if (currentSection && currentContent.length > 0) {
          config[currentSection] = currentContent.join('\n');
          currentContent = [];
        }

        // Start a new section
        currentSection = configMatch[1];

        // Check if this is a simple value or the start of a multi-line value
        if (configMatch[2] === '|') {
          // Multi-line value
          currentContent = [];
        } else {
          // Simple value
          config[currentSection] = configMatch[2];
          currentSection = null;
        }
      } else if (currentSection) {
        // Add to the current section
        currentContent.push(line);
      }
    }

    // Save the last section
    if (currentSection && currentContent.length > 0) {
      config[currentSection] = currentContent.join('\n');
    }

    // Parse challenges
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
   * @param {Object} config - The example configuration
   * @param {number} index - The example index
   * @returns {string} The HTML
   */
  function createInteractiveCodeHTML(config, index) {
    // Create challenges HTML
    let challengesHTML = '';
    if (config.challenges && config.challenges.length > 0) {
      challengesHTML = `
        <div class="example-challenges">
          <h4>Challenges</h4>
          <ul>
            ${config.challenges.map(challenge => `<li>${challenge}</li>`).join('')}
          </ul>
        </div>
      `;
    }

    // Escape HTML in code
    const escapedCode = escapeHtml(config.code);

    // Generate a unique ID for this example
    const exampleId = `interactive-example-${index}`;

    return `
      <div class="interactive-code-example" id="${exampleId}">
        <a href="#${exampleId}-editor" class="skip-link">Skip to code editor</a>
        <h3 class="example-title">${config.title}</h3>

        <div class="example-description">
          <p>${config.description}</p>
        </div>

        <div class="code-editor-container" data-language="${config.language}" data-editable="${config.editable}">
          <div class="editor-toolbar" role="toolbar" aria-label="Code editor controls">
            <div class="button-group execution-controls">
              <button class="run-button" aria-label="Run code">
                <span class="button-icon">▶</span>
                <span class="button-text">Run</span>
                <span class="shortcut-hint">F9</span>
                <span class="tooltip">Execute code (F9)</span>
              </button>
            </div>

            <div class="button-group editor-controls">
              <button class="reset-button" aria-label="Reset code">
                <span class="button-icon">↺</span>
                <span class="button-text">Reset</span>
                <span class="shortcut-hint">⇧F9</span>
                <span class="tooltip">Reset to original code (Shift+F9)</span>
              </button>
              <button class="copy-button" aria-label="Copy code">
                <span class="button-icon">⎘</span>
                <span class="button-text">Copy</span>
                <span class="tooltip">Copy code to clipboard</span>
              </button>
              <button class="format-button" aria-label="Format code">
                <span class="button-icon">{ }</span>
                <span class="button-text">Format</span>
                <span class="shortcut-hint">⌘S</span>
                <span class="tooltip">Format code (Ctrl/Cmd+S)</span>
              </button>
            </div>

            <div class="button-group view-controls">
              <button class="fullscreen-button" aria-label="Toggle fullscreen">
                <span class="button-icon">⛶</span>
                <span class="button-text">Fullscreen</span>
                <span class="tooltip">Toggle fullscreen mode</span>
              </button>
            </div>

            <div class="editor-status" aria-live="polite">
              <span class="status-icon"></span>
              <span class="status-text"></span>
            </div>
          </div>

          <div id="${exampleId}-editor" class="monaco-editor" data-code="${escapedCode}" tabindex="0"></div>

          <div class="output-panel" role="region" aria-label="Code output">
            <div class="output-header">
              <div class="output-title">Output</div>
              <div class="output-controls">
                <button class="clear-output-button" aria-label="Clear output" title="Clear output">
                  <span class="button-icon">✕</span>
                </button>
                <button class="copy-output-button" aria-label="Copy output" title="Copy output to clipboard">
                  <span class="button-icon">⎘</span>
                </button>
              </div>
            </div>
            <div class="output-content" aria-live="polite"></div>
          </div>
        </div>

        <div class="example-explanation">
          <h4>How it works</h4>
          ${config.explanation}
        </div>

        ${challengesHTML}

        <div class="sr-announcements" aria-live="assertive"></div>
      </div>
    `;
  }

  /**
   * Escape HTML special characters
   * @param {string} text - The text to escape
   * @returns {string} The escaped text
   */
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Handle responsive design adjustments
   */
  function handleResponsiveDesign() {
    // Check if we're on a mobile device
    const isMobile = window.innerWidth <= 768;
    const isSmallMobile = window.innerWidth <= 480;

    // Get all examples
    const examples = document.querySelectorAll('.interactive-code-example');

    examples.forEach(example => {
      // Get the editor container
      const editorContainer = example.querySelector('.code-editor-container');
      if (!editorContainer) return;

      // Check if in fullscreen mode
      const isFullscreen = editorContainer.classList.contains('fullscreen');
      if (isFullscreen) return; // Don't adjust fullscreen mode

      // Adjust height based on screen size
      if (isSmallMobile) {
        editorContainer.style.height = '450px';
      } else if (isMobile) {
        editorContainer.style.height = '500px';
      } else {
        editorContainer.style.height = '400px';
      }

      // Get the editor ID
      const editorElement = example.querySelector('.monaco-editor');
      if (!editorElement) return;

      const editorId = editorElement.dataset.editorId;
      if (!editorId) return;

      // Get the editor instance
      const editorInstance = state.examples.get(editorId)?.editor;
      if (editorInstance) {
        // Trigger layout update
        setTimeout(() => {
          editorInstance.layout();
        }, 100);
      }
    });
  }

  // Initialize when the DOM is loaded
  document.addEventListener('DOMContentLoaded', function() {
    // Apply browser-specific fixes
    applyBrowserFixes();

    // Initialize examples
    initializeExamples();
    processMarkdownCodeBlocks();
    handleResponsiveDesign();

    // Log browser information
    console.log('Browser detection:', config.browsers);
  });

  // Re-initialize when the theme changes
  window.addEventListener('theme-changed', function() {
    // Re-initialize examples
    initializeExamples();
  });

  // Handle window resize for responsive design
  window.addEventListener('resize', function() {
    handleResponsiveDesign();
  });
})();
