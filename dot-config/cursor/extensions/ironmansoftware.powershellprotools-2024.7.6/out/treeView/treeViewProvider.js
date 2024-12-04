"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ParentTreeItem = exports.Node = exports.TreeViewProvider = void 0;
const vscode = require("vscode");
class TreeViewProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        let command = this.getRefreshCommand();
        if (command)
            vscode.commands.registerCommand(command, () => this.refresh());
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
    getTreeItem(element) {
        if (element instanceof ParentTreeItem) {
            const node = element;
            return node.getTreeItem();
        }
        return element;
    }
    getChildren(element) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return yield this.getChildrenImpl(element);
            }
            catch (err) {
                //vscode.window.showErrorMessage(err.message);
                return [];
            }
        });
    }
    getChildrenImpl(element) {
        return __awaiter(this, void 0, void 0, function* () {
            if (element == null) {
                var nodes = [];
                let implNodes = yield this.getNodes();
                implNodes.forEach(node => nodes.push(node));
                return nodes;
            }
            if (element instanceof ParentTreeItem) {
                var parentTreeItem = element;
                return parentTreeItem.getChildren();
            }
        });
    }
}
exports.TreeViewProvider = TreeViewProvider;
class Node extends vscode.TreeItem {
    constructor(label, icon, tooltip) {
        super(label);
        this.iconPath = new vscode.ThemeIcon(icon);
        this.contextValue = 'help';
        this.tooltip = tooltip;
        this.command = {
            command: 'poshProTools.help',
            arguments: [this],
            title: 'Help'
        };
    }
}
exports.Node = Node;
class ParentTreeItem extends vscode.TreeItem {
    constructor(label, state) {
        super(label, state);
    }
    getTreeItem() {
        return this;
    }
}
exports.ParentTreeItem = ParentTreeItem;
//# sourceMappingURL=treeViewProvider.js.map