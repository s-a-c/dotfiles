/**
 * Basic tests for UME Tutorial Interactive Code Examples
 */

// Mock DOM elements
document.body.innerHTML = `
  <div class="interactive-code-container">
    <div class="interactive-code-header">
      <h3 class="interactive-code-title">Test Example</h3>
      <div class="interactive-code-controls">
        <button class="interactive-code-run-button">Run</button>
        <button class="interactive-code-reset-button">Reset</button>
      </div>
    </div>
    <div class="interactive-code-content">
      <div class="interactive-code-editor">console.log("Hello, World!");</div>
      <div class="interactive-code-output"></div>
    </div>
  </div>
`;

// Import functions to test
const escapeHtml = require('docs/030-ume-tutorial/assets/010-interactive-code-examples/scripts-part1').escapeHtml;
const createNotification = require('docs/030-ume-tutorial/assets/010-interactive-code-examples/scripts-part3').createNotification;

describe('Basic Functionality', () => {
  test('escapeHtml escapes HTML special characters', () => {
    const input = '<script>alert("XSS")</script>';
    const expected = '&lt;script&gt;alert("XSS")&lt;/script&gt;';
    expect(escapeHtml(input)).toBe(expected);
  });

  test('createNotification creates a notification element', () => {
    // Mock document.createElement
    const mockElement = {
      className: '',
      textContent: '',
      classList: {
        add: jest.fn()
      },
      remove: jest.fn()
    };

    document.createElement = jest.fn().mockReturnValue(mockElement);
    document.body.appendChild = jest.fn();

    createNotification('Test notification', 'info', 1000);

    expect(document.createElement).toHaveBeenCalledWith('div');
    expect(mockElement.className).toBe('notification notification-info');
    expect(mockElement.textContent).toBe('Test notification');
    expect(document.body.appendChild).toHaveBeenCalledWith(mockElement);
  });
});

describe('Interactive Code Editor', () => {
  test('Run button executes code', () => {
    // Initialize the interactive examples
    require('docs/030-ume-tutorial/assets/010-interactive-code-examples/scripts-part1').initInteractiveExamples();

    // Mock console.log
    console.log = jest.fn();

    // Get elements
    const runButton = document.querySelector('.interactive-code-run-button');
    const output = document.querySelector('.interactive-code-output');

    // Click run button
    runButton.click();

    // Check output
    expect(output.innerHTML).toContain('Hello, World!');
  });

  test('Reset button resets code', () => {
    // Initialize the interactive examples
    require('docs/030-ume-tutorial/assets/010-interactive-code-examples/scripts-part1').initInteractiveExamples();

    // Get elements
    const editor = document.querySelector('.interactive-code-editor');
    const resetButton = document.querySelector('.interactive-code-reset-button');
    const output = document.querySelector('.interactive-code-output');

    // Change editor content
    editor.textContent = 'console.log("Changed");';

    // Click reset button
    resetButton.click();

    // Check editor content
    expect(editor.textContent).toBe('console.log("Hello, World!");');
    expect(output.innerHTML).toContain('Code has been reset');
  });
});

describe('Theme and Accessibility', () => {
  test('Theme toggle switches between light and dark themes', () => {
    // Create theme toggle button
    const themeToggle = document.createElement('button');
    themeToggle.id = 'theme-toggle';
    document.body.appendChild(themeToggle);

    // Initialize theme toggle
    require('docs/030-ume-tutorial/assets/010-interactive-code-examples/scripts-part2').initThemeToggle();

    // Click theme toggle
    themeToggle.click();

    // Check if dark theme is applied
    expect(document.body.classList.contains('dark-theme')).toBe(true);
    expect(themeToggle.textContent).toBe('Switch to Light Theme');

    // Click theme toggle again
    themeToggle.click();

    // Check if light theme is applied
    expect(document.body.classList.contains('dark-theme')).toBe(false);
    expect(themeToggle.textContent).toBe('Switch to Dark Theme');
  });

  test('Contrast toggle switches between normal and high contrast', () => {
    // Create contrast toggle button
    const contrastToggle = document.createElement('button');
    contrastToggle.id = 'contrast-toggle';
    document.body.appendChild(contrastToggle);

    // Initialize accessibility features
    require('docs/030-ume-tutorial/assets/010-interactive-code-examples/scripts-part2').initAccessibility();

    // Click contrast toggle
    contrastToggle.click();

    // Check if high contrast is applied
    expect(document.body.classList.contains('high-contrast')).toBe(true);
    expect(contrastToggle.textContent).toBe('Disable High Contrast');

    // Click contrast toggle again
    contrastToggle.click();

    // Check if normal contrast is applied
    expect(document.body.classList.contains('high-contrast')).toBe(false);
    expect(contrastToggle.textContent).toBe('Enable High Contrast');
  });
});
