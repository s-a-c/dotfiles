/**
 * Code Executor
 *
 * This script handles the execution of code in the interactive code examples.
 */

(function() {
  // Configuration
  const config = {
    // PHP execution endpoint
    phpExecutionEndpoint: '/api/run-php-code',

    // Execution timeout (in milliseconds)
    executionTimeout: 10000,

    // Retry configuration
    retry: {
      // Maximum number of retry attempts
      maxAttempts: 3,

      // Delay between retry attempts (in milliseconds)
      delay: 1000,

      // Status codes that should trigger a retry
      statusCodes: [408, 429, 500, 502, 503, 504]
    }
  };

  /**
   * Execute PHP code
   * @param {string} code - The PHP code to execute
   * @param {number} [attempt=1] - The current attempt number
   * @returns {Promise} A promise that resolves with the execution result
   */
  function executePhpCode(code, attempt = 1) {
    return new Promise((resolve, reject) => {
      // Check if we've exceeded the maximum number of attempts
      if (attempt > config.retry.maxAttempts) {
        reject(new Error(`Failed after ${config.retry.maxAttempts} attempts`));
        return;
      }

      // Create a timeout
      const timeoutId = setTimeout(() => {
        console.warn(`Execution timed out (attempt ${attempt} of ${config.retry.maxAttempts})`);

        // Retry if we haven't exceeded the maximum number of attempts
        if (attempt < config.retry.maxAttempts) {
          console.info(`Retrying in ${config.retry.delay}ms...`);
          setTimeout(() => {
            executePhpCode(code, attempt + 1)
              .then(resolve)
              .catch(reject);
          }, config.retry.delay);
        } else {
          reject(new Error('Execution timed out'));
        }
      }, config.executionTimeout);

      // Send the code to the server
      fetch(config.phpExecutionEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          code: code,
          language: 'php'
        })
      })
      .then(response => {
        // Clear the timeout
        clearTimeout(timeoutId);

        // Check if the response is OK
        if (!response.ok) {
          // Check if we should retry
          if (config.retry.statusCodes.includes(response.status) && attempt < config.retry.maxAttempts) {
            console.warn(`Received status ${response.status} (attempt ${attempt} of ${config.retry.maxAttempts})`);
            console.info(`Retrying in ${config.retry.delay}ms...`);

            // Retry after a delay
            setTimeout(() => {
              executePhpCode(code, attempt + 1)
                .then(resolve)
                .catch(reject);
            }, config.retry.delay);

            return null; // Return null to skip the next then block
          }

          throw new Error(`HTTP error ${response.status}`);
        }

        // Parse the response
        return response.json();
      })
      .then(data => {
        // Skip if we're retrying
        if (data === null) return;

        if (data.success) {
          resolve(data.output);
        } else {
          reject(new Error(data.error || data.output || 'Execution failed'));
        }
      })
      .catch(error => {
        // Clear the timeout
        clearTimeout(timeoutId);

        // Check if we should retry
        if (error.name === 'TypeError' && attempt < config.retry.maxAttempts) {
          console.warn(`Network error (attempt ${attempt} of ${config.retry.maxAttempts})`);
          console.info(`Retrying in ${config.retry.delay}ms...`);

          // Retry after a delay
          setTimeout(() => {
            executePhpCode(code, attempt + 1)
              .then(resolve)
              .catch(reject);
          }, config.retry.delay);
        } else {
          // Reject the promise
          reject(error);
        }
      });
    });
  }

  /**
   * Execute code in a sandbox (fallback for when the server is not available)
   * @param {string} code - The code to execute
   * @returns {Promise} A promise that resolves with the execution result
   */
  function executeCodeInSandbox(code) {
    return new Promise((resolve) => {
      console.warn('Falling back to sandbox execution');

      // This is a simple sandbox that just returns the code
      // In a real implementation, this would execute the code in a sandbox
      resolve(`Code execution in sandbox is not available.\n\nYour code:\n\n${code}`);
    });
  }

  /**
   * Parse the execution result
   * @param {string} output - The raw output from the server
   * @returns {object} The parsed result
   */
  function parseExecutionResult(output) {
    // Check if the output is empty
    if (!output || output.trim() === '') {
      return {
        success: true,
        output: '(No output)',
        warnings: [],
        errors: []
      };
    }

    // Split the output into lines
    const lines = output.split('\n');

    // Extract warnings and errors
    const warnings = [];
    const errors = [];

    lines.forEach(line => {
      if (line.toLowerCase().includes('warning')) {
        warnings.push(line);
      } else if (line.toLowerCase().includes('error') || line.toLowerCase().includes('exception')) {
        errors.push(line);
      }
    });

    return {
      success: errors.length === 0,
      output: output,
      warnings: warnings,
      errors: errors
    };
  }

  /**
   * Execute code
   * @param {string} code - The code to execute
   * @param {string} language - The language of the code
   * @returns {Promise} A promise that resolves with the execution result
   */
  function executeCode(code, language = 'php') {
    // Only support PHP for now
    if (language !== 'php') {
      return Promise.reject(new Error('Only PHP is supported at this time.'));
    }

    // Log the execution
    console.info(`Executing ${language} code...`);

    // Try to execute the code on the server
    return executePhpCode(code)
      .then(output => {
        // Parse the execution result
        const result = parseExecutionResult(output);

        // Log warnings
        if (result.warnings.length > 0) {
          console.warn('Execution warnings:', result.warnings);
        }

        // Return the output
        return output;
      })
      .catch(error => {
        console.error('Server execution failed:', error);

        // Fall back to sandbox execution
        return executeCodeInSandbox(code);
      });
  }

  // Export to window
  window.CodeExecutor = {
    execute: executeCode
  };
})();
