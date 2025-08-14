/**
 * Browser Fallbacks for Interactive Code Examples
 * 
 * This file contains fallback mechanisms for browsers that don't fully
 * support all features used in the interactive code examples.
 */

document.addEventListener('DOMContentLoaded', function() {
  // Initialize browser feature detection and fallbacks
  initBrowserFallbacks();
});

/**
 * Initialize all browser fallbacks
 */
function initBrowserFallbacks() {
  detectFeatureSupport();
  applyPolyfills();
  setupFallbackBehaviors();
}

/**
 * Detect browser feature support
 */
function detectFeatureSupport() {
  // Create a global object to track feature support
  window.browserSupport = {
    // ES6+ Features
    arrowFunctions: supportsArrowFunctions(),
    promises: typeof Promise !== 'undefined',
    asyncAwait: supportsAsyncAwait(),
    classes: supportsClasses(),
    
    // DOM Features
    customElements: 'customElements' in window,
    shadowDOM: 'attachShadow' in document.createElement('div'),
    intersectionObserver: 'IntersectionObserver' in window,
    resizeObserver: 'ResizeObserver' in window,
    
    // CSS Features
    flexbox: supportsFlex(),
    grid: supportsGrid(),
    cssVariables: supportsCssVariables(),
    
    // API Features
    fetch: 'fetch' in window,
    localStorage: storageAvailable('localStorage'),
    sessionStorage: storageAvailable('sessionStorage'),
    
    // Misc
    webWorkers: 'Worker' in window,
    webAssembly: typeof WebAssembly === 'object'
  };
  
  // Add browser support classes to the document
  const html = document.documentElement;
  for (const [feature, supported] of Object.entries(window.browserSupport)) {
    html.classList.toggle(`supports-${feature}`, supported);
    html.classList.toggle(`no-${feature}`, !supported);
  }
}

/**
 * Apply polyfills for missing features
 */
function applyPolyfills() {
  // Polyfill for Array.from
  if (!Array.from) {
    Array.from = function(arrayLike) {
      return [].slice.call(arrayLike);
    };
  }
  
  // Polyfill for Element.closest
  if (!Element.prototype.closest) {
    Element.prototype.closest = function(selector) {
      let element = this;
      while (element && element.nodeType === 1) {
        if (element.matches(selector)) return element;
        element = element.parentNode;
      }
      return null;
    };
  }
  
  // Polyfill for Element.matches
  if (!Element.prototype.matches) {
    Element.prototype.matches =
      Element.prototype.matchesSelector ||
      Element.prototype.mozMatchesSelector ||
      Element.prototype.msMatchesSelector ||
      Element.prototype.oMatchesSelector ||
      Element.prototype.webkitMatchesSelector ||
      function(s) {
        const matches = (this.document || this.ownerDocument).querySelectorAll(s);
        let i = matches.length;
        while (--i >= 0 && matches.item(i) !== this) {}
        return i > -1;
      };
  }
  
  // Polyfill for requestAnimationFrame
  if (!window.requestAnimationFrame) {
    window.requestAnimationFrame = function(callback) {
      return setTimeout(function() {
        callback(Date.now());
      }, 16);
    };
  }
  
  // Polyfill for cancelAnimationFrame
  if (!window.cancelAnimationFrame) {
    window.cancelAnimationFrame = function(id) {
      clearTimeout(id);
    };
  }
}

/**
 * Set up fallback behaviors for unsupported features
 */
function setupFallbackBehaviors() {
  setupCodeEditorFallbacks();
  setupLayoutFallbacks();
  setupInteractionFallbacks();
  setupNotificationSystem();
}

/**
 * Set up fallbacks for code editors
 */
function setupCodeEditorFallbacks() {
  // If CodeMirror or Monaco Editor isn't available, use textarea
  const codeEditors = document.querySelectorAll('.code-editor');
  
  if (!window.CodeMirror && !window.monaco) {
    codeEditors.forEach(editor => {
      const codeContent = editor.textContent || editor.dataset.code || '';
      const textarea = document.createElement('textarea');
      textarea.className = 'code-editor-fallback';
      textarea.value = codeContent.trim();
      textarea.setAttribute('spellcheck', 'false');
      textarea.setAttribute('wrap', 'off');
      
      // Replace the editor with the textarea
      editor.innerHTML = '';
      editor.appendChild(textarea);
    });
  }
  
  // If syntax highlighting isn't available, use pre/code
  if (!window.Prism && !window.hljs) {
    document.querySelectorAll('.code-highlight').forEach(highlight => {
      const code = highlight.textContent || '';
      const pre = document.createElement('pre');
      const codeElement = document.createElement('code');
      
      codeElement.textContent = code.trim();
      pre.appendChild(codeElement);
      
      // Replace the highlight element with pre/code
      highlight.parentNode.replaceChild(pre, highlight);
    });
  }
}

/**
 * Set up fallbacks for layout features
 */
function setupLayoutFallbacks() {
  // Fallback for CSS Grid
  if (!window.browserSupport.grid) {
    document.querySelectorAll('.grid-layout').forEach(grid => {
      grid.classList.add('fallback-grid');
    });
  }
  
  // Fallback for CSS Flexbox
  if (!window.browserSupport.flexbox) {
    document.querySelectorAll('.flex-layout').forEach(flex => {
      flex.classList.add('fallback-flex');
    });
  }
  
  // Fallback for CSS Variables
  if (!window.browserSupport.cssVariables) {
    // Apply fallback colors directly
    document.querySelectorAll('.interactive-code-container').forEach(container => {
      container.style.backgroundColor = '#ffffff';
      container.style.color = '#333333';
      
      container.querySelectorAll('.interactive-code-header').forEach(header => {
        header.style.backgroundColor = '#f5f5f5';
      });
      
      container.querySelectorAll('.code-editor').forEach(editor => {
        editor.style.backgroundColor = '#f8f8f8';
      });
    });
  }
}

/**
 * Set up fallbacks for interaction features
 */
function setupInteractionFallbacks() {
  // Fallback for Fetch API
  if (!window.browserSupport.fetch) {
    window.fetch = function(url, options) {
      return new Promise(function(resolve, reject) {
        const xhr = new XMLHttpRequest();
        xhr.open(options?.method || 'GET', url);
        
        if (options?.headers) {
          Object.keys(options.headers).forEach(key => {
            xhr.setRequestHeader(key, options.headers[key]);
          });
        }
        
        xhr.onload = function() {
          const response = {
            status: xhr.status,
            statusText: xhr.statusText,
            headers: parseHeaders(xhr.getAllResponseHeaders()),
            text: function() {
              return Promise.resolve(xhr.responseText);
            },
            json: function() {
              return Promise.resolve(JSON.parse(xhr.responseText));
            }
          };
          resolve(response);
        };
        
        xhr.onerror = function() {
          reject(new TypeError('Network request failed'));
        };
        
        xhr.send(options?.body || null);
      });
    };
  }
  
  // Fallback for Intersection Observer
  if (!window.browserSupport.intersectionObserver) {
    // Simple scroll-based visibility detection
    document.querySelectorAll('.interactive-code-container').forEach(container => {
      window.addEventListener('scroll', function() {
        const rect = container.getBoundingClientRect();
        const isVisible = rect.top < window.innerHeight && rect.bottom > 0;
        
        if (isVisible && !container.classList.contains('is-visible')) {
          container.classList.add('is-visible');
          // Trigger any initialization that would normally happen on intersection
          if (typeof window.initVisibleCodeExample === 'function') {
            window.initVisibleCodeExample(container);
          }
        }
      });
    });
    
    // Trigger initial check
    window.dispatchEvent(new Event('scroll'));
  }
}

/**
 * Set up notification system for feature warnings
 */
function setupNotificationSystem() {
  const containers = document.querySelectorAll('.interactive-code-container');
  
  containers.forEach(container => {
    // Check if this container uses features not supported by the browser
    const requiredFeatures = container.dataset.requires ? container.dataset.requires.split(' ') : [];
    const missingFeatures = requiredFeatures.filter(feature => !window.browserSupport[feature]);
    
    if (missingFeatures.length > 0) {
      // Create warning notification
      const warning = document.createElement('div');
      warning.className = 'browser-compatibility-warning';
      warning.innerHTML = `
        <p><strong>Browser Compatibility Warning:</strong> Your browser doesn't support all features needed for this interactive example.</p>
        <p>Missing features: ${missingFeatures.join(', ')}</p>
        <p>A simplified version will be shown instead.</p>
        <button class="dismiss-warning">Dismiss</button>
      `;
      
      // Add dismiss functionality
      warning.querySelector('.dismiss-warning').addEventListener('click', function() {
        warning.remove();
      });
      
      // Add warning to container
      container.insertBefore(warning, container.firstChild);
      
      // Apply simplified version
      container.classList.add('simplified-version');
    }
  });
}

/**
 * Helper function to check if arrow functions are supported
 */
function supportsArrowFunctions() {
  try {
    eval('() => {}');
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Helper function to check if async/await is supported
 */
function supportsAsyncAwait() {
  try {
    eval('async function test() { await Promise.resolve(); }');
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Helper function to check if classes are supported
 */
function supportsClasses() {
  try {
    eval('class Test {}');
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Helper function to check if flexbox is supported
 */
function supportsFlex() {
  const div = document.createElement('div');
  div.style.display = 'flex';
  return div.style.display === 'flex';
}

/**
 * Helper function to check if grid is supported
 */
function supportsGrid() {
  const div = document.createElement('div');
  div.style.display = 'grid';
  return div.style.display === 'grid';
}

/**
 * Helper function to check if CSS variables are supported
 */
function supportsCssVariables() {
  return window.CSS && CSS.supports('(--test: 0)');
}

/**
 * Helper function to check if storage is available
 */
function storageAvailable(type) {
  try {
    const storage = window[type];
    const x = '__storage_test__';
    storage.setItem(x, x);
    storage.removeItem(x);
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Helper function to parse headers from XHR
 */
function parseHeaders(headerStr) {
  const headers = {};
  const headerPairs = headerStr.split('\r\n');
  
  headerPairs.forEach(function(line) {
    const parts = line.split(': ');
    const header = parts.shift();
    const value = parts.join(': ');
    
    if (header) {
      headers[header] = value;
    }
  });
  
  return headers;
}
