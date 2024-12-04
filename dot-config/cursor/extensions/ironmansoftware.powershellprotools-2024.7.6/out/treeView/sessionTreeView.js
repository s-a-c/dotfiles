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
exports.SessionTreeItem = exports.SessionTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class SessionTreeViewProvider extends treeViewProvider_1.TreeViewProvider {
    requiresLicense() {
        return false;
    }
    getRefreshCommand() {
        return "sessionsView.refresh";
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var history = yield container_1.Container.PowerShellService.GetSessions();
            return history.map(x => new SessionTreeItem(x));
        });
    }
}
exports.SessionTreeViewProvider = SessionTreeViewProvider;
class SessionTreeItem extends vscode.TreeItem {
    constructor(session) {
        super(session.Name);
        this.session = session;
        this.contextValue = 'session';
        this.description = session.ComputerName;
        this.tooltip = session.Name;
        this.iconPath = new vscode.ThemeIcon('vm-connect');
    }
}
exports.SessionTreeItem = SessionTreeItem;
//# sourceMappingURL=sessionTreeView.js.map