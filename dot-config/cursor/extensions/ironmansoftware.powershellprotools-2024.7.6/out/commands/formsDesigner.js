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
exports.showWinFormDesigner = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
function LaunchEditor(context) {
    return __awaiter(this, void 0, void 0, function* () {
        if (vscode.window.activeTextEditor == null) {
            vscode.window.showErrorMessage("Open a PS1 file to edit with the form designer before running this command.");
            return;
        }
        var fsPath = vscode.window.activeTextEditor.document.fileName.toLowerCase();
        const codeFilePath = fsPath;
        if (fsPath.endsWith(".ps1")) {
            const designerFilePath = fsPath.replace('.ps1', '.designer.ps1');
            vscode.window.setStatusBarMessage("Starting form designer...", 3000);
            yield container_1.Container.PowerShellService.ShowFormDesigner(codeFilePath, designerFilePath);
        }
        else {
            vscode.window.showErrorMessage("Open a PS1 file to edit with the form designer before running this command.");
        }
    });
}
function showWinFormDesigner(context) {
    return vscode.commands.registerCommand('powershell.showWinFormDesigner', () => {
        if (!container_1.Container.IsInitialized())
            return;
        LaunchEditor(context);
    });
}
exports.showWinFormDesigner = showWinFormDesigner;
//# sourceMappingURL=formsDesigner.js.map