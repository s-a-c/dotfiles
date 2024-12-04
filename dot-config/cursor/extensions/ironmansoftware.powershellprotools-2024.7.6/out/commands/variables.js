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
exports.VariableCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class VariableCommands {
    register(context) {
        context.subscriptions.push(this.insertVariable());
    }
    insertVariable() {
        return vscode.commands.registerCommand('poshProTools.insertVariable', (variable) => __awaiter(this, void 0, void 0, function* () {
            var activeEditor = vscode.window.activeTextEditor;
            if (!activeEditor)
                return;
            activeEditor.edit(x => {
                x.insert(activeEditor.selection.active, variable.variableDetails.Path);
            });
        }));
    }
    viewType() {
        return vscode.commands.registerCommand('poshProTools.viewType', (variable) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            const type = container_1.Container.PowerShellService.FindType(variable.variableDetails.type);
            if (!type) {
                vscode.window.showWarningMessage(`Failed to find type ${variable.variableDetails.type}`);
                return;
            }
        }));
    }
}
exports.VariableCommands = VariableCommands;
//# sourceMappingURL=variables.js.map