"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runCommand = void 0;
const vscode_1 = require("vscode");
/**
 * Runs a command in the terminal
 *
 * @param {string} title - Title of the terminal
 * @param {string} command - Command to run
 * @example
 * runCommand('echo "Hello, World!"');
 *
 * @returns {Promise<void>} - No return value
 */
const runCommand = async (title, command) => {
    const terminal = vscode_1.window.createTerminal(title);
    terminal.show();
    terminal.sendText(command);
};
exports.runCommand = runCommand;
//# sourceMappingURL=command.helper.js.map