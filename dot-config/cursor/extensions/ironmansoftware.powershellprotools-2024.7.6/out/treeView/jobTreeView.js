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
exports.JobTreeItem = exports.JobTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class JobTreeViewProvider extends treeViewProvider_1.TreeViewProvider {
    requiresLicense() {
        return false;
    }
    getRefreshCommand() {
        return "jobView.refresh";
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var history = yield container_1.Container.PowerShellService.GetJobs();
            return history.map(x => new JobTreeItem(x));
        });
    }
}
exports.JobTreeViewProvider = JobTreeViewProvider;
class JobTreeItem extends vscode.TreeItem {
    constructor(job) {
        super(job.Name);
        this.job = job;
        this.description = job.Type;
        switch (job.State) {
            case "NotStarted":
                this.iconPath = new vscode.ThemeIcon('circle-outline');
                this.contextValue = 'job';
                break;
            case 'Running':
                this.iconPath = new vscode.ThemeIcon('play-circle');
                this.contextValue = 'jobrunning';
                break;
            case 'Completed':
                this.iconPath = new vscode.ThemeIcon('check');
                this.contextValue = 'jobcompleted';
                break;
            case 'Failed':
                this.iconPath = new vscode.ThemeIcon('error');
                this.contextValue = 'jobcompleted';
                break;
            case 'Stopped':
            case 'Stopping':
            case 'Blocked':
            case 'Suspended':
            case 'Suspending':
                this.iconPath = new vscode.ThemeIcon('circle-slash');
                this.contextValue = 'jobcompleted';
                break;
            case 'Disconnected':
                this.iconPath = new vscode.ThemeIcon('debug-disconnect');
                this.contextValue = 'jobrunning';
                break;
            case 'AtBreakpoint':
                this.iconPath = new vscode.ThemeIcon('circle-filled');
                this.contextValue = 'jobrunning';
                break;
        }
        this.tooltip = `${job.State} on ${job.Location}`;
    }
}
exports.JobTreeItem = JobTreeItem;
//# sourceMappingURL=jobTreeView.js.map