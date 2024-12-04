'use strict';
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
exports.JobTreeViewCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class JobTreeViewCommands {
    register(context) {
        context.subscriptions.push(this.Stop());
        context.subscriptions.push(this.Debug());
        context.subscriptions.push(this.Receive());
        context.subscriptions.push(this.Remove());
    }
    Stop() {
        return vscode.commands.registerCommand('jobView.stop', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            yield container_1.Container.PowerShellService.StopJob(node.job.Id);
            yield vscode.commands.executeCommand('jobView.refresh');
        }));
    }
    Debug() {
        return vscode.commands.registerCommand('jobView.debug', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            yield container_1.Container.PowerShellService.DebugJob(node.job.Id);
        }));
    }
    Receive() {
        return vscode.commands.registerCommand('jobView.receive', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            yield container_1.Container.PowerShellService.ReceiveJob(node.job.Id);
        }));
    }
    Remove() {
        return vscode.commands.registerCommand('jobView.remove', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            yield container_1.Container.PowerShellService.RemoveJob(node.job.Id);
            yield vscode.commands.executeCommand('jobView.refresh');
        }));
    }
}
exports.JobTreeViewCommands = JobTreeViewCommands;
//# sourceMappingURL=jobs.js.map