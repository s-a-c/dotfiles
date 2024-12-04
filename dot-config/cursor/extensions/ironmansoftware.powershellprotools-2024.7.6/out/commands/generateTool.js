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
exports.generateTool = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
function generateTool() {
    return vscode.commands.registerCommand('powershell.generateTool', () => __awaiter(this, void 0, void 0, function* () {
        if (!container_1.Container.IsInitialized())
            return;
        if (vscode.window.activeTextEditor == null) {
            vscode.window.showErrorMessage("You must open a .ps1 file to generate a Windows Form.");
            return;
        }
        var fsPath = vscode.window.activeTextEditor.document.fileName;
        if (!fsPath.endsWith('.ps1')) {
            vscode.window.showErrorMessage("You must open a .ps1 file to generate a Windows Form.");
            return;
        }
        const codeFilePath = fsPath;
        const formPath = fsPath.replace('.ps1', '.form.ps1');
        yield container_1.Container.PowerShellService.GenerateTool(codeFilePath, formPath);
        var exePath = fsPath.replace('.ps1', '.form.exe');
        var result = yield vscode.window.showInformationMessage(`Generated application: ${exePath}`, 'Launch');
        if (result === 'Launch') {
            vscode.env.openExternal(vscode.Uri.file(exePath));
        }
    }));
}
exports.generateTool = generateTool;
//# sourceMappingURL=generateTool.js.map