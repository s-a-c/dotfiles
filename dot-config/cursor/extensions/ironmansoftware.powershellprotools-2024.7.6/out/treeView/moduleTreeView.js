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
exports.Module = exports.ModuleViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
const path = require("path");
const versioning_1 = require("../utilities/versioning");
const settings_1 = require("../settings");
class ModuleViewProvider extends treeViewProvider_1.TreeViewProvider {
    getRefreshCommand() {
        return "moduleView.refresh";
    }
    requiresLicense() {
        return true;
    }
    constructor() {
        super();
        this.highestVersion = [];
        ModuleViewProvider.Instance = this;
        vscode.commands.registerCommand('moduleExplorer.updateModule', this.updateModule);
        vscode.commands.registerCommand('moduleExplorer.uninstallModule', this.uninstallModule);
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var modules = yield container_1.Container.PowerShellService.GetModules();
            return modules.map(m => {
                return new Module(m.Name, m.Versions.map(x => new ModuleVersion(x.Version, x.ModuleBase, m.FromRepository)), m.FromRepository);
            });
        });
    }
    updateModule(item) {
        return __awaiter(this, void 0, void 0, function* () {
            yield item.setUpdating(true);
            yield container_1.Container.PowerShellService.SendTerminalCommand(`Update-Module -Name '${item.label}' -RequiredVersion '${item.higherVersion}'`);
            yield item.setUpdating(false);
        });
    }
    uninstallModule(item) {
        return __awaiter(this, void 0, void 0, function* () {
            var _this = this;
            vscode.window.setStatusBarMessage(`Uninstalling module ${item.label} (${item.version})...`);
            yield container_1.Container.PowerShellService.UninstallModule(item.label.toString(), item.version);
            vscode.window.showInformationMessage(`Uninstalled module ${item.label} (${item.version})`);
            vscode.window.setStatusBarMessage('');
            _this.refresh();
        });
    }
    cacheHighestVersion(moduleVersion) {
        this.highestVersion.push(moduleVersion);
    }
    findHighestVersion(module) {
        var highest = this.highestVersion.find(m => m.Name === module.label);
        if (highest != null) {
            return highest.version;
        }
        return null;
    }
}
exports.ModuleViewProvider = ModuleViewProvider;
class Module extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return Promise.resolve(this.versions);
    }
    constructor(label, versions, fromGallery) {
        super(label, vscode.TreeItemCollapsibleState.Collapsed);
        this.label = label;
        this.versions = versions;
        this.fromGallery = fromGallery;
        this.foundHigherVersion = false;
        this.updating = false;
        this.iconPath = {
            light: path.join(__filename, '..', '..', 'resources', 'light', 'dependency.svg'),
            dark: path.join(__filename, '..', '..', 'resources', 'dark', 'dependency.svg')
        };
        var settings = (0, settings_1.load)();
        if (settings.checkForModuleUpdates) {
            if (this.fromGallery) {
                vscode.window.setStatusBarMessage(`Checking for new version of module ${label}...`);
                var highestVersion = ModuleViewProvider.Instance.findHighestVersion(this);
                if (highestVersion == null) {
                    container_1.Container.PowerShellService.FindModuleVersion(this.label).then(version => {
                        this.checkVersion(version);
                    });
                }
                else {
                    this.checkVersion(highestVersion);
                }
                vscode.window.setStatusBarMessage('');
            }
        }
    }
    setUpdating(updating) {
        return __awaiter(this, void 0, void 0, function* () {
            if (updating) {
                this.updating = updating;
                this.contextValue = '';
                ModuleViewProvider.Instance.refresh(this);
            }
            else {
                var x = yield container_1.Container.PowerShellService.GetModulePath(this.label, this.higherVersion);
                this.updating = updating;
                this.contextValue = '';
                this.foundHigherVersion = false;
                this.versions.push(new ModuleVersion(this.higherVersion, x, this.fromGallery));
                this.higherVersion = '';
                ModuleViewProvider.Instance.refresh(this);
            }
        });
    }
    checkVersion(version) {
        var versioning = new versioning_1.default();
        var uptodate = false;
        this.versions.forEach(x => {
            if (versioning.compare(x.version, version) >= 0) {
                uptodate = true;
            }
        });
        ModuleViewProvider.Instance.cacheHighestVersion({ Name: this.label, Version: version });
        if (!uptodate) {
            this.contextValue = 'update';
            this.higherVersion = version;
            this.foundHigherVersion = true;
            ModuleViewProvider.Instance.refresh(this);
        }
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
    get _tooltip() {
        return `${this.label}`;
    }
    get _description() {
        if (this.updating) {
            return `Updating to ${this.higherVersion}...`;
        }
        var updateAvailable = "";
        if (this.foundHigherVersion) {
            updateAvailable = `(Update Available - ${this.higherVersion})`;
        }
        return updateAvailable;
    }
}
exports.Module = Module;
class ModuleVersion extends vscode.TreeItem {
    constructor(version, location, fromRepository) {
        super(version, vscode.TreeItemCollapsibleState.None);
        this.version = version;
        this.location = location;
        this.fromRepository = fromRepository;
        if (fromRepository) {
            this.contextValue = 'uninstall';
        }
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
    get _tooltip() {
        return this.location;
    }
    get _description() {
        return this.location;
    }
}
//# sourceMappingURL=moduleTreeView.js.map