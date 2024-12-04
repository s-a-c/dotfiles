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
exports.EndpointTreeItem = exports.ApiTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("./container");
const parentTreeItem_1 = require("./parentTreeItem");
class ApiTreeViewProvider {
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
                    const endpoints = yield container_1.Container.universal.getEndpoints();
                    const items = endpoints.map(y => new EndpointTreeItem(y));
                    return items;
                }
                catch (ex) {
                    container_1.Container.universal.showConnectionError("Failed to query API endpoints. " + ex);
                    return [];
                }
            }
            if (element instanceof parentTreeItem_1.default) {
                var parentTreeItem = element;
                return parentTreeItem.getChildren();
            }
        });
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
}
exports.ApiTreeViewProvider = ApiTreeViewProvider;
const formatMethod = (endpoint) => {
    if (Array.isArray(endpoint.method)) {
        return endpoint.method.map(m => m.toUpperCase()).join(",");
    }
    else {
        return endpoint.method.toUpperCase();
    }
};
class EndpointTreeItem extends vscode.TreeItem {
    constructor(endpoint) {
        super(`(${formatMethod(endpoint)}) ${endpoint.url}`, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "endpoint";
        this.endpoint = endpoint;
        const icon = endpoint.authentication ? "lock" : "unlock";
        const themeIcon = new vscode.ThemeIcon(icon);
        this.iconPath = themeIcon;
    }
}
exports.EndpointTreeItem = EndpointTreeItem;
//# sourceMappingURL=api-treeview.js.map