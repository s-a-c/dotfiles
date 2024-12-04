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
exports.HostProcessViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class HostProcessViewProvider extends treeViewProvider_1.TreeViewProvider {
    getRefreshCommand() {
        return "hostProcessView.refresh";
    }
    requiresLicense() {
        return false;
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var providers = yield container_1.Container.PowerShellService.GetPSHostProcess();
            return providers.filter(m => m.Process !== 'PowerShellProTools.Host').map(x => new PSHostProcess(x));
        });
    }
}
exports.HostProcessViewProvider = HostProcessViewProvider;
class PSHostProcess extends treeViewProvider_1.ParentTreeItem {
    constructor(process) {
        super(`${process.Process} (${process.ProcessId})`, vscode.TreeItemCollapsibleState.Collapsed);
        this.process = process;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            const runspaces = yield container_1.Container.PowerShellService.GetRunspaces(this.process.ProcessId);
            return runspaces.filter(m => m.Name !== "RemoteHost").map(m => new Runspace(m, this.process.ProcessId));
        });
    }
}
class Runspace extends vscode.TreeItem {
    constructor(runspace, processId) {
        super(`${runspace.Name} (${runspace.Id})`, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "runspace";
        this.ProcessId = processId;
        this.RunspaceId = runspace.Id;
    }
}
//# sourceMappingURL=hostProcessView.js.map