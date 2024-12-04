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
exports.generateWinForm = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
function generateWinForm() {
    return vscode.commands.registerCommand('powershell.generateWinForm', () => __awaiter(this, void 0, void 0, function* () {
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
        yield container_1.Container.PowerShellService.GenerateWinForm(codeFilePath, formPath);
        vscode.workspace.openTextDocument(formPath).then(y => {
            vscode.window.showTextDocument(y);
        });
    }));
}
exports.generateWinForm = generateWinForm;
//# sourceMappingURL=generateWinForm.js.map