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
exports.PowerShellCodeLensProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class PowerShellCodeLensProvider {
    provideCodeLenses(document) {
        return __awaiter(this, void 0, void 0, function* () {
            let wsUri = vscode.workspace.getWorkspaceFolder(document.uri);
            let funcDefs = yield container_1.Container.PowerShellService.GetFunctionDefinitions(document.uri.fsPath, wsUri.uri.fsPath);
            let codeLenses = new Array();
            for (let def of funcDefs) {
                let funcPosition = new vscode.Range(def.Line, def.Character, def.Line, def.Character);
                let locations = def.References.map(m => new vscode.Location(vscode.Uri.parse(m.FileName), new vscode.Position(m.Line, m.Character)));
                let command = {
                    title: def.References.length === 1 ? '1 reference????' : `${def.References.length} references???`,
                    command: 'editor.action.showReferences',
                    arguments: [vscode.Uri.file(def.FileName), new vscode.Position(def.Line, def.Character), locations]
                };
                codeLenses.push(new vscode.CodeLens(funcPosition, command));
            }
            return codeLenses;
        });
    }
}
exports.PowerShellCodeLensProvider = PowerShellCodeLensProvider;
//# sourceMappingURL=codeLensProvider.js.map