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
exports.JobTreeItem = exports.JobsTreeItem = exports.TerminalTreeItem = exports.TerminalsTreeItem = exports.ScriptTreeItem = exports.ScriptsTreeItem = exports.AutomationTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("./container");
const types_1 = require("./types");
const parentTreeItem_1 = require("./parentTreeItem");
class AutomationTreeViewProvider {
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
                return [
                    new ScriptsTreeItem(),
                    new JobsTreeItem(),
                    new TerminalsTreeItem()
                ];
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
exports.AutomationTreeViewProvider = AutomationTreeViewProvider;
class ScriptsTreeItem extends parentTreeItem_1.default {
    constructor() {
        super("Scripts", vscode.TreeItemCollapsibleState.Collapsed);
        this.iconPath = new vscode.ThemeIcon('files');
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return yield container_1.Container.universal.getScripts().then(x => x.sort((a, b) => (a.name > b.name) ? 1 : -1).map(y => new ScriptTreeItem(y)));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query scripts. " + err);
                return [];
            }
        });
    }
}
exports.ScriptsTreeItem = ScriptsTreeItem;
class ScriptTreeItem extends vscode.TreeItem {
    constructor(script) {
        super(script.name, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "script";
        this.script = script;
        const themeIcon = new vscode.ThemeIcon('file-code');
        this.iconPath = themeIcon;
    }
}
exports.ScriptTreeItem = ScriptTreeItem;
class TerminalsTreeItem extends parentTreeItem_1.default {
    constructor() {
        super("Terminals", vscode.TreeItemCollapsibleState.Collapsed);
        this.iconPath = new vscode.ThemeIcon('terminal');
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return yield container_1.Container.universal.getTerminals().then(x => x.sort((a, b) => (a.name > b.name) ? 1 : -1).map(y => new TerminalTreeItem(y)));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query scripts. " + err);
                return [];
            }
        });
    }
}
exports.TerminalsTreeItem = TerminalsTreeItem;
class TerminalTreeItem extends vscode.TreeItem {
    constructor(terminal) {
        super(terminal.name, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "terminal";
        this.terminal = terminal;
        const themeIcon = new vscode.ThemeIcon('terminal');
        this.iconPath = themeIcon;
    }
}
exports.TerminalTreeItem = TerminalTreeItem;
class JobsTreeItem extends parentTreeItem_1.default {
    constructor() {
        super("Jobs", vscode.TreeItemCollapsibleState.Collapsed);
        this.iconPath = new vscode.ThemeIcon('checklist');
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return yield container_1.Container.universal.getJobs().then(x => x.page.sort((a, b) => (a.id < b.id) ? 1 : -1).map(y => new JobTreeItem(y)));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query jobs. " + err);
                return [];
            }
        });
    }
}
exports.JobsTreeItem = JobsTreeItem;
class JobTreeItem extends vscode.TreeItem {
    constructor(job) {
        super(job.scriptFullPath, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "job";
        this.job = job;
        if (job.status == types_1.JobStatus.Completed) {
            this.iconPath = new vscode.ThemeIcon('check');
            this.tooltip = 'Completed successfully';
        }
        if (job.status == types_1.JobStatus.Running) {
            this.iconPath = new vscode.ThemeIcon('play');
            this.tooltip = 'Running';
        }
        if (job.status == types_1.JobStatus.Failed) {
            this.iconPath = new vscode.ThemeIcon('error');
            this.tooltip = 'Failed';
        }
        if (job.status == types_1.JobStatus.WaitingOnFeedback) {
            this.iconPath = new vscode.ThemeIcon('question');
            this.tooltip = 'Waiting on feedback';
        }
        this.description = job.id.toString();
    }
}
exports.JobTreeItem = JobTreeItem;
//# sourceMappingURL=automation-treeview.js.map