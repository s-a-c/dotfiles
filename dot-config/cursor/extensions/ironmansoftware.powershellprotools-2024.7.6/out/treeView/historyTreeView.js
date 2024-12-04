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
exports.HistoryTreeItem = exports.HistoryTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class HistoryTreeViewProvider extends treeViewProvider_1.TreeViewProvider {
    requiresLicense() {
        return false;
    }
    getRefreshCommand() {
        return "historyView.refresh";
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var history = yield container_1.Container.PowerShellService.GetHistory();
            return history.map(x => new HistoryTreeItem(x));
        });
    }
}
exports.HistoryTreeViewProvider = HistoryTreeViewProvider;
class HistoryTreeItem extends vscode.TreeItem {
    constructor(history) {
        super(history);
        this.history = history;
        this.contextValue = 'historyItem';
        if (history.length > 60) {
            this.label = history.substring(0, 60) + "...";
        }
        this.tooltip = history;
        this.iconPath = new vscode.ThemeIcon('history');
    }
}
exports.HistoryTreeItem = HistoryTreeItem;
//# sourceMappingURL=historyTreeView.js.map