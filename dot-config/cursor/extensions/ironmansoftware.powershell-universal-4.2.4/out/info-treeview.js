"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InfoTreeViewProvider = void 0;
const vscode = require("vscode");
class Node extends vscode.TreeItem {
    constructor(label, icon) {
        super(label);
        this.iconPath = new vscode.ThemeIcon(icon);
        this.contextValue = 'help';
        this.command = {
            command: 'powershell-universal.help',
            arguments: [this],
            title: 'Help'
        };
    }
}
class InfoTreeViewProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }
    getTreeItem(element) {
        return element;
    }
    getChildren(element) {
        if (element == null) {
            return [
                new Node('Documentation', 'book'),
                new Node('Forums', 'account'),
                new Node('Support', 'question'),
                new Node('Pricing', 'key')
            ];
        }
        return null;
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
}
exports.InfoTreeViewProvider = InfoTreeViewProvider;
//# sourceMappingURL=info-treeview.js.map