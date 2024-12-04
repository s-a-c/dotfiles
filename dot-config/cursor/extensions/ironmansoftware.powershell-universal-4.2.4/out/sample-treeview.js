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
exports.SampleTreeItem = exports.SampleFolderTreeItem = exports.SampleTreeViewProvider = void 0;
const vscode = require("vscode");
const types_1 = require("./types");
const samples_1 = require("./samples");
class SampleTreeViewProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        this.service = new samples_1.SampleService();
    }
    getTreeItem(element) {
        return element;
    }
    getChildren(element) {
        return __awaiter(this, void 0, void 0, function* () {
            if (element == null) {
                return (yield this.service.getRootSamples()).map(folder => new SampleFolderTreeItem(folder));
            }
            if (element instanceof SampleFolderTreeItem) {
                var parentTreeItem = element;
                return (yield this.service.getFolderChildren(parentTreeItem.folder)).map(item => {
                    if (item instanceof types_1.Sample) {
                        const sample = item;
                        return new SampleTreeItem(sample);
                    }
                    if (item instanceof types_1.SampleFolder) {
                        const sample = item;
                        return new SampleFolderTreeItem(sample);
                    }
                    return new vscode.TreeItem("Unknown");
                });
            }
        });
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
}
exports.SampleTreeViewProvider = SampleTreeViewProvider;
class SampleFolderTreeItem extends vscode.TreeItem {
    constructor(folder) {
        super(folder.name, vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "sample-folder";
        this.folder = folder;
        const themeIcon = new vscode.ThemeIcon("folder");
        this.iconPath = themeIcon;
    }
}
exports.SampleFolderTreeItem = SampleFolderTreeItem;
class SampleTreeItem extends vscode.TreeItem {
    constructor(sample) {
        super(sample.title, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "sample";
        this.sample = sample;
        this.tooltip = sample.description;
        const themeIcon = new vscode.ThemeIcon("notebook");
        this.iconPath = themeIcon;
    }
}
exports.SampleTreeItem = SampleTreeItem;
//# sourceMappingURL=sample-treeview.js.map