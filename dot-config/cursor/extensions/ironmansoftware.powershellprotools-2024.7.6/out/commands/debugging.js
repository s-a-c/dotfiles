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
exports.DebuggingCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class DebuggingCommands {
    register(context) {
        context.subscriptions.push(this.AttachRunspace());
        context.subscriptions.push(this.RunInNewTerminal());
    }
    AttachRunspace() {
        return vscode.commands.registerCommand('poshProTools.attachRunspace', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
        }));
    }
    RunInNewTerminal() {
        return vscode.commands.registerCommand('poshProTools.runInNewTerminal', () => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            if (vscode.window.activeTextEditor == null || !vscode.window.activeTextEditor.document.fileName.endsWith(".ps1")) {
                return;
            }
            const path = yield container_1.Container.PowerShellService.GetPowerShellProcessPath();
            var terminal = vscode.window.createTerminal("PowerShell", path, ['-NoExit', '-File', `${vscode.window.activeTextEditor.document.uri.fsPath}`]);
            terminal.show();
        }));
    }
}
exports.DebuggingCommands = DebuggingCommands;
//# sourceMappingURL=debugging.js.map