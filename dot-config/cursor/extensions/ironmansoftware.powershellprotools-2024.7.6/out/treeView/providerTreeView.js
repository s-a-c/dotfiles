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
exports.ProviderViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class ProviderViewProvider extends treeViewProvider_1.TreeViewProvider {
    getRefreshCommand() {
        return "providerView.refresh";
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var providers = yield container_1.Container.PowerShellService.GetProviders();
            return providers.map(x => new Provider(x));
        });
    }
    requiresLicense() {
        return true;
    }
}
exports.ProviderViewProvider = ProviderViewProvider;
class Provider extends treeViewProvider_1.ParentTreeItem {
    constructor(label) {
        super(label, vscode.TreeItemCollapsibleState.Collapsed);
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            var drives = yield container_1.Container.PowerShellService.GetProviderDrives(this.label.toString());
            if (drives.map) {
                return drives.map(x => new PSContainer(`${x}:\\`, `${x}:\\`));
            }
            else {
                return [new PSContainer(`${drives}:\\`, `${drives}:\\`)];
            }
        });
    }
}
class PSContainer extends treeViewProvider_1.ParentTreeItem {
    constructor(name, path) {
        super(name, vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "providerContainer";
        this.path = path;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            var containers = yield container_1.Container.PowerShellService.GetContainers(this.path);
            var items = yield container_1.Container.PowerShellService.GetItems(this.path);
            var containerNodes = containers.map ? containers.map(x => new PSContainer(x.Name, x.Path)) : [];
            var itemNodes = items.map ? items.map(x => new PSItem(x.Name, x.Value, x.Path, x.Tooltip)) : [];
            var treeNodes = [];
            treeNodes = treeNodes.concat(containerNodes);
            return treeNodes.concat(itemNodes);
        });
    }
}
class PSItem extends vscode.TreeItem {
    constructor(name, value, path, tooltipStr) {
        super(name, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "providerItem";
        this.tooltipStr = tooltipStr;
        this.value = value;
        this.path = path;
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
        return this.tooltipStr;
    }
    get _description() {
        return this.value;
    }
}
//# sourceMappingURL=providerTreeView.js.map