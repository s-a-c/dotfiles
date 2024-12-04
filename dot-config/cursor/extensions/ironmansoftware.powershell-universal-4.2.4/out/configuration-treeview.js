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
exports.ConfigTreeItem = exports.ConfigTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("./container");
class ConfigTreeViewProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }
    getTreeItem(element) {
        return element;
    }
    getChildren(element) {
        return __awaiter(this, void 0, void 0, function* () {
            if (element == null) {
                try {
                    var version = yield container_1.Container.universal.getVersion();
                    if (version.startsWith("3") || version.startsWith("4") || version.startsWith("5")) {
                        const configs = yield container_1.Container.universal.getFiles("");
                        var configTree = [];
                        configs.forEach(c => configTree.push(new ConfigTreeItem(c.name, c.fullName, c.isLeaf, c.content)));
                        return configTree;
                    }
                    else {
                        const configs = yield container_1.Container.universal.getConfigurations();
                        var configTree = [];
                        configs.forEach(c => configTree.push(new ConfigTreeItem(c, c, false, "")));
                        return configTree;
                    }
                }
                catch (err) {
                    container_1.Container.universal.showConnectionError("Failed to query configuration files. " + err);
                    return [];
                }
            }
            else {
                const configs = yield container_1.Container.universal.getFiles(element.fileName);
                var configTree = [];
                configs.forEach(c => configTree.push(new ConfigTreeItem(c.name, c.fullName, c.isLeaf, c.content)));
                return configTree;
            }
        });
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
}
exports.ConfigTreeViewProvider = ConfigTreeViewProvider;
class ConfigTreeItem extends vscode.TreeItem {
    constructor(name, fileName, leaf, content) {
        super(name, leaf ? vscode.TreeItemCollapsibleState.None : vscode.TreeItemCollapsibleState.Collapsed);
        this.description = fileName;
        this.fileName = fileName;
        const themeIcon = leaf ? new vscode.ThemeIcon('file-code') : new vscode.ThemeIcon('folder');
        this.iconPath = themeIcon;
        this.leaf = leaf;
        this.content = content;
        this.contextValue = leaf ? "configFile" : "configFolder";
    }
}
exports.ConfigTreeItem = ConfigTreeItem;
//# sourceMappingURL=configuration-treeview.js.map