/**
 * Markdown Parser
 * 
 * Parses the Markdown syntax for interactive code examples in the UME tutorial.
 * This file provides functionality to identify interactive code blocks,
 * extract parameters, and validate required fields.
 */

(function() {
  'use strict';

  // Configuration
  const config = {
    // Marker for interactive code blocks
    blockMarker: ':::interactive-code',
    
    // End marker for interactive code blocks
    endMarker: ':::',
    
    // Required parameters
    requiredParams: ['title', 'description', 'code', 'explanation'],
    
    // Optional parameters with defaults
    optionalParams: {
      language: 'php',
      editable: true,
      challenges: ''
    }
  };

  /**
   * Parse Markdown content for interactive code blocks
   * @param {string} content - The Markdown content to parse
   * @returns {Array} - Array of parsed interactive code blocks
   */
  function parseContent(content) {
    console.log('Parsing Markdown content for interactive code blocks');
    
    const blocks = [];
    let startIndex = 0;
    
    // Find all interactive code blocks
    while ((startIndex = content.indexOf(config.blockMarker, startIndex)) !== -1) {
      // Find the end of the block
      const endIndex = content.indexOf(config.endMarker, startIndex + config.blockMarker.length);
      
      if (endIndex === -1) {
        console.error('Unclosed interactive code block');
        break;
      }
      
      // Extract the block content
      const blockContent = content.substring(
        startIndex + config.blockMarker.length,
        endIndex
      ).trim();
      
      // Parse the block
      const parsedBlock = parseBlock(blockContent);
      
      if (parsedBlock) {
        blocks.push(parsedBlock);
      }
      
      // Move to the end of this block
      startIndex = endIndex + config.endMarker.length;
    }
    
    return blocks;
  }

  /**
   * Parse a single interactive code block
   * @param {string} blockContent - The content of the block
   * @returns {Object|null} - The parsed block or null if invalid
   */
  function parseBlock(blockContent) {
    console.log('Parsing interactive code block');
    
    const lines = blockContent.split('\n');
    const params = {};
    
    let currentParam = null;
    let currentValue = [];
    
    // Process each line
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Check if this is a parameter line
      const paramMatch = line.match(/^([a-z_]+):\s*(.*)$/);
      
      if (paramMatch) {
        // Save the previous parameter if there was one
        if (currentParam) {
          params[currentParam] = currentValue.join('\n');
          currentValue = [];
        }
        
        // Start a new parameter
        currentParam = paramMatch[1];
        
        // Check if this is a pipe
        if (paramMatch[2] === '|') {
          // Multi-line value starts on the next line
          currentValue = [];
        } else {
          // Single-line value
          currentValue = [paramMatch[2]];
          
          // Save immediately
          params[currentParam] = currentValue.join('\n');
          currentParam = null;
          currentValue = [];
        }
      } else if (currentParam) {
        // Add to the current parameter value
        currentValue.push(line);
      }
    }
    
    // Save the last parameter if there was one
    if (currentParam) {
      params[currentParam] = currentValue.join('\n');
    }
    
    // Validate required parameters
    for (const param of config.requiredParams) {
      if (!params[param]) {
        console.error(`Missing required parameter: ${param}`);
        return null;
      }
    }
    
    // Add defaults for optional parameters
    for (const [param, defaultValue] of Object.entries(config.optionalParams)) {
      if (!params[param]) {
        params[param] = defaultValue;
      }
    }
    
    // Convert boolean parameters
    if (typeof params.editable === 'string') {
      params.editable = params.editable.toLowerCase() === 'true';
    }
    
    return params;
  }

  /**
   * Generate HTML for an interactive code block
   * @param {Object} block - The parsed block
   * @param {number} index - The index of the block
   * @returns {string} - The HTML for the block
   */
  function generateHTML(block, index) {
    console.log('Generating HTML for interactive code block');
    
    // Escape HTML in code
    const escapedCode = escapeHTML(block.code);
    
    // Generate HTML
    return `
      <div class="interactive-code-example" id="interactive-example-${index}">
        <h3 class="example-title">${escapeHTML(block.title)}</h3>
        
        <div class="example-description">
          <p>${escapeHTML(block.description)}</p>
        </div>
        
        <div class="code-editor-container" data-language="${escapeHTML(block.language)}" data-editable="${block.editable}">
          <div class="editor-toolbar">
            <button class="run-button">Run Code</button>
            <button class="reset-button">Reset</button>
            <button class="copy-button">Copy</button>
            <div class="editor-status"></div>
          </div>
          
          <div class="monaco-editor" data-code="${escapedCode}"></div>
          
          <div class="output-panel">
            <div class="output-header">Output</div>
            <div class="output-content"></div>
          </div>
        </div>
        
        <div class="example-explanation">
          <h4>How it works</h4>
          ${block.explanation}
        </div>
        
        ${block.challenges ? `
          <div class="example-challenges">
            <h4>Challenges</h4>
            ${block.challenges}
          </div>
        ` : ''}
      </div>
    `;
  }

  /**
   * Escape HTML special characters
   * @param {string} str - The string to escape
   * @returns {string} - The escaped string
   */
  function escapeHTML(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  /**
   * Process Markdown content and replace interactive code blocks with HTML
   * @param {string} content - The Markdown content to process
   * @returns {string} - The processed content
   */
  function processMarkdown(content) {
    console.log('Processing Markdown content');
    
    const blocks = parseContent(content);
    
    // Replace each block with HTML
    let processedContent = content;
    let offset = 0;
    
    blocks.forEach((block, index) => {
      // Find the block in the content
      const startIndex = processedContent.indexOf(config.blockMarker, offset);
      
      if (startIndex === -1) {
        return;
      }
      
      // Find the end of the block
      const endIndex = processedContent.indexOf(config.endMarker, startIndex + config.blockMarker.length);
      
      if (endIndex === -1) {
        return;
      }
      
      // Generate HTML for the block
      const html = generateHTML(block, index);
      
      // Replace the block with HTML
      processedContent = processedContent.substring(0, startIndex) +
        html +
        processedContent.substring(endIndex + config.endMarker.length);
      
      // Update offset
      offset = startIndex + html.length;
    });
    
    return processedContent;
  }

  /**
   * Process interactive code blocks in the document
   */
  function processDocument() {
    console.log('Processing document for interactive code blocks');
    
    // Find all Markdown content containers
    const containers = document.querySelectorAll('.markdown-content');
    
    containers.forEach((container) => {
      // Get the content
      const content = container.innerHTML;
      
      // Process the content
      const processedContent = processMarkdown(content);
      
      // Update the container
      container.innerHTML = processedContent;
    });
  }

  // Export to global namespace
  window.UMEInteractive = window.UMEInteractive || {};
  window.UMEInteractive.MarkdownParser = {
    parseContent: parseContent,
    parseBlock: parseBlock,
    generateHTML: generateHTML,
    processMarkdown: processMarkdown,
    processDocument: processDocument
  };
})();
