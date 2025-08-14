# User Guide for Interactive Examples

This guide explains how to use the interactive code examples in the UME tutorial documentation.

## Getting Started

Interactive code examples allow you to experiment with PHP code directly in your browser. You can edit the code, run it, and see the results immediately.

![Interactive Example Overview](../assets/images/interactive-example-overview.png)

Each interactive example consists of:

1. **Title and Description**: Explains what the example demonstrates
2. **Code Editor**: Where you can view and edit the code
3. **Toolbar**: Contains buttons to run, reset, and copy the code
4. **Output Panel**: Displays the results of running the code
5. **Explanation**: Provides details about how the code works
6. **Challenges**: Suggests modifications you can try

## Using the Code Editor

The code editor is powered by Monaco Editor, the same editor used in Visual Studio Code. It provides:

- **Syntax Highlighting**: Code is colored to make it easier to read
- **Error Checking**: Syntax errors are highlighted as you type
- **Auto-Completion**: Suggestions appear as you type
- **Line Numbers**: Each line is numbered for reference

### Editing Code

To edit the code:

1. Click anywhere in the editor
2. Modify the code as desired
3. Your changes are automatically saved in your browser

### Keyboard Shortcuts

The editor supports many keyboard shortcuts:

| Shortcut | Action |
|----------|--------|
| F9 | Run the code |
| Shift+F9 | Reset the code |
| Ctrl+S / Cmd+S | Format the code |
| Ctrl+Z / Cmd+Z | Undo |
| Ctrl+Shift+Z / Cmd+Shift+Z | Redo |
| Ctrl+F / Cmd+F | Find |
| Ctrl+H / Cmd+H | Replace |
| Tab | Indent |
| Shift+Tab | Unindent |
| Ctrl+/ / Cmd+/ | Toggle comment |

## Running Code

To run the code:

1. Click the "Run" button in the toolbar, or
2. Press F9 on your keyboard

The code will be sent to the server, executed in a secure environment, and the results will be displayed in the output panel.

### Understanding the Output

The output panel shows the result of running your code. This includes:

- **Standard Output**: Text printed by your code
- **Error Messages**: If your code has errors
- **Warnings**: PHP warnings and notices

Different types of output are color-coded:
- Regular output: normal text
- Errors: red text
- Warnings: orange text
- Notices: blue text

## Resetting Code

If you want to start over:

1. Click the "Reset" button in the toolbar, or
2. Press Shift+F9 on your keyboard

This will restore the code to its original state. A confirmation dialog will appear to prevent accidental resets.

## Copying Code

To copy the code to your clipboard:

1. Click the "Copy" button in the toolbar

This is useful if you want to paste the code into your own PHP files.

## Formatting Code

To automatically format the code:

1. Click the "Format" button in the toolbar, or
2. Press Ctrl+S / Cmd+S on your keyboard

This will adjust indentation and spacing to make the code more readable.

## Fullscreen Mode

To enter fullscreen mode:

1. Click the "Fullscreen" button in the toolbar

This expands the editor to fill the entire screen, giving you more space to work. Press Escape or click the button again to exit fullscreen mode.

## Working with Challenges

Each example includes challenges to help you learn:

1. Read the challenges listed below the example
2. Modify the code to complete the challenge
3. Run the code to see if your solution works
4. Reset if you want to start over

Challenges are designed to reinforce the concepts demonstrated in the example.

## Saving Your Work

Your modifications to the code are automatically saved in your browser's local storage. When you return to the page later, your changes will still be there.

To clear your saved changes:

1. Reset the code using the "Reset" button
2. Your browser's local storage for that example will be cleared

## Troubleshooting

### Code Doesn't Run

If the code doesn't run:

1. Check for syntax errors (highlighted in red)
2. Ensure you're connected to the internet
3. Try refreshing the page

### Error Messages

Common error messages and their meanings:

- **Parse error**: You have a syntax error in your code
- **Undefined variable**: You're using a variable that hasn't been defined
- **Call to undefined function**: You're calling a function that doesn't exist
- **Maximum execution time exceeded**: Your code took too long to run
- **Memory limit exceeded**: Your code used too much memory

### Browser Compatibility

The interactive examples work best in:

- Chrome 90+
- Firefox 90+
- Safari 14+
- Edge 90+

If you're using an older browser, you may experience issues.

## Accessibility

The interactive examples are designed to be accessible:

- All features can be accessed using keyboard shortcuts
- ARIA attributes are used for screen reader compatibility
- High contrast mode is supported
- Focus is managed for keyboard navigation

To navigate using a keyboard:

1. Use Tab to move between interactive elements
2. Use Enter to activate buttons
3. Use arrow keys to navigate within the editor
4. Use F9 to run the code
5. Use Shift+F9 to reset the code

## Mobile Usage

On mobile devices:

1. The interface adapts to smaller screens
2. Button labels are hidden to save space
3. The editor and output panel are stacked vertically
4. Touch gestures are supported for editing

For the best experience on mobile, use landscape orientation when possible.

## Getting Help

If you encounter issues or have questions:

1. Check this user guide for answers
2. Look for tooltips on buttons and controls
3. Contact the documentation team through the feedback form

## Privacy Considerations

The interactive examples:

1. Save your code modifications in your browser's local storage
2. Send code to the server for execution
3. Do not track or store your personal information

Your code is executed in a secure, isolated environment and is not stored on the server after execution.
