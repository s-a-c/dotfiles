"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require("vscode");
const id = "terminal-in-status-bar";
const ALIGNMENT_KEY = "statusBarAlignment";
const PRIORITY_KEY = "statusBarPriority";
const LABEL_KEY = "statusBarLabel";
let statusBarItem;
// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
function activate(context) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log(`"${id}" activate!`);
    showStatusBarItem(context);
    context.subscriptions.push(vscode.workspace.onDidChangeConfiguration((event) => {
        if (event.affectsConfiguration(`${id}.${ALIGNMENT_KEY}`) ||
            event.affectsConfiguration(`${id}.${PRIORITY_KEY}`) ||
            event.affectsConfiguration(`${id}.${LABEL_KEY}`)) {
            statusBarItem.dispose();
            showStatusBarItem(context);
        }
    }));
    // The command has been defined in the package.json file
    // Now provide the implementation of the command with registerCommand
    // The commandId parameter must match the command field in package.json
    let disposable = vscode.commands.registerCommand("terminal-in-status-bar.toggle", () => {
        vscode.commands.executeCommand("workbench.action.terminal.focus");
    });
    context.subscriptions.push(disposable);
}
exports.activate = activate;
function showStatusBarItem(context) {
    const conf = vscode.workspace.getConfiguration(id);
    const alignment = conf.get(ALIGNMENT_KEY) === "right"
        ? vscode.StatusBarAlignment.Right
        : vscode.StatusBarAlignment.Left;
    const priority = conf.get(PRIORITY_KEY);
    const showLabel = conf.get(LABEL_KEY);
    console.log("load config:", alignment, priority);
    statusBarItem = vscode.window.createStatusBarItem(alignment, priority);
    statusBarItem.command = "terminal-in-status-bar.toggle";
    statusBarItem.text = `$(terminal)${showLabel ? " Terminal" : ""}`;
    statusBarItem.tooltip = "Toggle Integrated Terminal";
    context.subscriptions.push(statusBarItem);
    statusBarItem.show();
}
// this method is called when your extension is deactivated
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map