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
exports.CustomTreeItemParentNode = exports.CustomTreeItemNode = exports.CustomTreeViewParentNode = exports.CustomTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class CustomTreeViewProvider extends treeViewProvider_1.TreeViewProvider {
    requiresLicense() {
        return false;
    }
    getRefreshCommand() {
        return "customView.refresh";
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var treeViews = yield container_1.Container.PowerShellService.GetTreeViews();
            return treeViews.map(x => new CustomTreeViewParentNode(x));
        });
    }
}
exports.CustomTreeViewProvider = CustomTreeViewProvider;
class CustomTreeViewParentNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            var treeItems = yield container_1.Container.PowerShellService.LoadChildren(this.treeView.Label, "");
            return treeItems.map(x => x.HasChildren ? new CustomTreeItemParentNode(x) : new CustomTreeItemNode(x));
        });
    }
    constructor(treeView) {
        super(treeView.Label, vscode.TreeItemCollapsibleState.Collapsed);
        this.treeView = treeView;
        if (treeView.Icon)
            this.iconPath = new vscode.ThemeIcon(treeView.Icon);
        this.description = treeView.Description;
        this.tooltip = treeView.Tooltip;
    }
}
exports.CustomTreeViewParentNode = CustomTreeViewParentNode;
class CustomTreeItemNode extends vscode.TreeItem {
    constructor(treeItem) {
        super(treeItem.Label);
        this.path = treeItem.Path;
        this.treeViewId = treeItem.TreeViewId;
        this.contextValue = treeItem.CanInvoke ? "customViewItem" : null;
        this.tooltip = treeItem.Tooltip;
        this.description = treeItem.Tooltip;
        if (treeItem.Icon)
            this.iconPath = new vscode.ThemeIcon(treeItem.Icon);
    }
}
exports.CustomTreeItemNode = CustomTreeItemNode;
class CustomTreeItemParentNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            var treeItems = yield container_1.Container.PowerShellService.LoadChildren(this.treeItem.TreeViewId, this.treeItem.Path);
            return treeItems.map(x => x.HasChildren ? new CustomTreeItemParentNode(x) : new CustomTreeItemNode(x));
        });
    }
    constructor(treeItem) {
        super(treeItem.Label, vscode.TreeItemCollapsibleState.Collapsed);
        this.treeItem = treeItem;
        this.path = treeItem.Path;
        this.treeViewId = treeItem.TreeViewId;
        this.contextValue = treeItem.CanInvoke ? "customViewItem" : null;
        this.tooltip = treeItem.Tooltip;
        this.description = treeItem.Tooltip;
        if (treeItem.Icon)
            this.iconPath = new vscode.ThemeIcon(treeItem.Icon);
    }
}
exports.CustomTreeItemParentNode = CustomTreeItemParentNode;
//# sourceMappingURL=customTreeView.js.map