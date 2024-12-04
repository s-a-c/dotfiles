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
exports.QuickScript = exports.QuickScriptViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class QuickScriptViewProvider extends treeViewProvider_1.TreeViewProvider {
    getRefreshCommand() {
        return "quickScriptView.refresh";
    }
    requiresLicense() {
        return false;
    }
    constructor() {
        super();
        QuickScriptViewProvider.Instance = this;
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            return container_1.Container.QuickScriptService.getScripts().map(x => new QuickScript(x.Name, x.File));
        });
    }
}
exports.QuickScriptViewProvider = QuickScriptViewProvider;
class QuickScript extends vscode.TreeItem {
    constructor(name, file) {
        super(name, vscode.TreeItemCollapsibleState.None);
        this.name = name;
        this.file = file;
        this.contextValue = "quickscript";
    }
    getTreeItem() {
        return {
            tooltip: this._tooltip,
            contextValue: this.contextValue,
            collapsibleState: this.collapsibleState,
            label: this.label,
            description: this._description
        };
    }
    get _description() {
        return this.file;
    }
    get _tooltip() {
        return this.file;
    }
}
exports.QuickScript = QuickScript;
//# sourceMappingURL=quickScriptView.js.map