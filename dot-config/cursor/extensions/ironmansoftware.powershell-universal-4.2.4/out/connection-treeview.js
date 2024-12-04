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
exports.ConnectionTreeItem = exports.ConnectionTreeViewProvider = void 0;
const vscode = require("vscode");
const settings_1 = require("./settings");
class ConnectionTreeViewProvider {
    constructor(context) {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        this.context = context;
    }
    getTreeItem(element) {
        return element;
    }
    getChildren(element) {
        return __awaiter(this, void 0, void 0, function* () {
            if (element == null) {
                const settings = settings_1.load();
                const connectionName = this.context.globalState.get("universal.connection");
                var items = settings.connections.map(m => new ConnectionTreeItem(m, m.name === connectionName));
                if (settings.appToken && settings.appToken !== '') {
                    items.push(new ConnectionTreeItem({
                        name: "Default",
                        appToken: settings.appToken,
                        url: settings.url,
                        allowInvalidCertificate: false
                    }, !connectionName || connectionName === 'Default'));
                }
                return items;
            }
        });
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
}
exports.ConnectionTreeViewProvider = ConnectionTreeViewProvider;
class ConnectionTreeItem extends vscode.TreeItem {
    constructor(connection, connected) {
        super(connection.name, vscode.TreeItemCollapsibleState.None);
        this.connection = connection;
        this.connected = connected;
        const themeIcon = this.connected ? new vscode.ThemeIcon("check") : new vscode.ThemeIcon("close");
        this.iconPath = themeIcon;
        this.contextValue = this.connected ? "connection-connected" : "connection";
    }
}
exports.ConnectionTreeItem = ConnectionTreeItem;
//# sourceMappingURL=connection-treeview.js.map