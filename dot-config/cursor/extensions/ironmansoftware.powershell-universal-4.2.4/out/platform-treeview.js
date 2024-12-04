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
exports.CustomModule = exports.PowerShellUniversalModule = exports.RepositoriesTreeViewItem = exports.CustomModules = exports.PowerShellUniversalModules = exports.ModulesTreeItem = exports.RunspaceTreeItem = exports.ProcessTreeItem = exports.ProcessesTreeItem = exports.PlatformTreeViewProvider = void 0;
const vscode = require("vscode");
const parentTreeItem_1 = require("./parentTreeItem");
const container_1 = require("./container");
class PlatformTreeViewProvider {
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
                    new ModulesTreeItem(),
                    new ProcessesTreeItem()
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
exports.PlatformTreeViewProvider = PlatformTreeViewProvider;
class ProcessesTreeItem extends parentTreeItem_1.default {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const processes = yield container_1.Container.universal.getProcesses();
                return processes.map(x => new ProcessTreeItem(x));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query modules. " + err);
                return [];
            }
        });
    }
    constructor() {
        super("Processes", vscode.TreeItemCollapsibleState.Collapsed);
        const themeIcon = new vscode.ThemeIcon("server-process");
        this.iconPath = themeIcon;
    }
}
exports.ProcessesTreeItem = ProcessesTreeItem;
class ProcessTreeItem extends parentTreeItem_1.default {
    constructor(process) {
        super(`${process.description} (${process.processId})`, vscode.TreeItemCollapsibleState.Collapsed);
        this.process = process;
        const themeIcon = new vscode.ThemeIcon("server-process");
        this.iconPath = themeIcon;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const runspaces = yield container_1.Container.universal.getRunspaces(this.process.processId);
                return runspaces.map(x => new RunspaceTreeItem(x));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query modules. " + err);
                return [];
            }
        });
    }
}
exports.ProcessTreeItem = ProcessTreeItem;
class RunspaceTreeItem extends vscode.TreeItem {
    constructor(runspace) {
        super(`Runspace ${runspace.id.toString()}`, vscode.TreeItemCollapsibleState.None);
        this.contextValue = 'runspace';
        this.description = runspace.availability;
        this.tooltip = runspace.state;
        this.runspace = runspace;
        const themeIcon = new vscode.ThemeIcon("circuit-board");
        this.iconPath = themeIcon;
    }
}
exports.RunspaceTreeItem = RunspaceTreeItem;
class ModulesTreeItem extends parentTreeItem_1.default {
    constructor() {
        super("Modules", vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = 'modules';
        const themeIcon = new vscode.ThemeIcon("package");
        this.iconPath = themeIcon;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return [
                new CustomModules(),
                new PowerShellUniversalModules(),
                new RepositoriesTreeViewItem()
            ];
        });
    }
}
exports.ModulesTreeItem = ModulesTreeItem;
class PowerShellUniversalModules extends parentTreeItem_1.default {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const modules = yield container_1.Container.universal.getModules();
                return modules.filter(m => m.extension).map(x => new PowerShellUniversalModule(x));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query modules. " + err);
                return [];
            }
        });
    }
    constructor() {
        super("Extensions", vscode.TreeItemCollapsibleState.Collapsed);
        const themeIcon = new vscode.ThemeIcon("terminal");
        this.iconPath = themeIcon;
    }
}
exports.PowerShellUniversalModules = PowerShellUniversalModules;
class CustomModules extends parentTreeItem_1.default {
    constructor() {
        super("Custom", vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = 'customModules';
        const themeIcon = new vscode.ThemeIcon("folder");
        this.iconPath = themeIcon;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const modules = yield container_1.Container.universal.getModules();
                return modules.filter(m => !m.readOnly).map(x => new CustomModule(x));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query modules. " + err);
                return [];
            }
        });
    }
}
exports.CustomModules = CustomModules;
class RepositoriesTreeViewItem extends parentTreeItem_1.default {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const repos = yield container_1.Container.universal.getRepositories();
                return repos.map(x => {
                    const ti = new vscode.TreeItem(x, vscode.TreeItemCollapsibleState.None);
                    const themeIcon = new vscode.ThemeIcon("repo");
                    ti.iconPath = themeIcon;
                    return ti;
                });
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query repositories. " + err);
                return [];
            }
        });
    }
    constructor() {
        super("Repositories", vscode.TreeItemCollapsibleState.Collapsed);
        const themeIcon = new vscode.ThemeIcon("repo-forked");
        this.iconPath = themeIcon;
    }
}
exports.RepositoriesTreeViewItem = RepositoriesTreeViewItem;
class PowerShellUniversalModule extends vscode.TreeItem {
    constructor(module) {
        super(module.name, vscode.TreeItemCollapsibleState.None);
        const themeIcon = new vscode.ThemeIcon("archive");
        this.iconPath = themeIcon;
        this.tooltip = `${module.version}`;
    }
}
exports.PowerShellUniversalModule = PowerShellUniversalModule;
class CustomModule extends vscode.TreeItem {
    constructor(module) {
        super(module.name, vscode.TreeItemCollapsibleState.None);
        this.contextValue = 'customModule';
        const themeIcon = new vscode.ThemeIcon("archive");
        this.iconPath = themeIcon;
        this.tooltip = `${module.version}`;
        this.module = module;
    }
}
exports.CustomModule = CustomModule;
//# sourceMappingURL=platform-treeview.js.map