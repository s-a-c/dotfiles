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
exports.QuickScriptCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const quickScriptView_1 = require("../treeView/quickScriptView");
class QuickScriptCommands {
    register(context) {
        context.subscriptions.push(this.addQuickScript());
        context.subscriptions.push(this.openQuickScript());
        context.subscriptions.push(this.removeQuickScript());
    }
    addQuickScript() {
        return vscode.commands.registerCommand('poshProTools.addQuickScript', () => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            const editor = vscode.window.activeTextEditor;
            if (!editor) {
                vscode.window.showErrorMessage("Please select a file to add as a Quick Script.");
                return;
            }
            var name = yield vscode.window.showInputBox({
                prompt: "Please enter the name for this Quick Script"
            });
            if (!name || name === "") {
                return;
            }
            yield container_1.Container.QuickScriptService.setScript(name, editor.document.fileName);
            vscode.window.showInformationMessage(`${name} was added to Quick Scripts`);
            quickScriptView_1.QuickScriptViewProvider.Instance.refresh();
        }));
    }
    removeQuickScript() {
        return vscode.commands.registerCommand('poshProTools.removeQuickScript', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            var name = "";
            if (node) {
                name = node.name;
            }
            else {
                name = yield vscode.window.showInputBox({
                    prompt: "Enter the name of the Quick Script to remove"
                });
            }
            if (!name || name === "")
                return;
            yield container_1.Container.QuickScriptService.removeScript(name);
            quickScriptView_1.QuickScriptViewProvider.Instance.refresh();
            vscode.window.showInformationMessage(`${name} was removed from Quick Scripts`);
        }));
    }
    openQuickScript() {
        return vscode.commands.registerCommand('poshProTools.openQuickScript', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            var name = '"';
            if (node) {
                name = node.name;
            }
            else {
                name = yield vscode.window.showInputBox({
                    prompt: "Enter Quick Script name"
                });
            }
            if (!name || name === "")
                return;
            var script = container_1.Container.QuickScriptService.getScript(name);
            if (!script) {
                vscode.window.showErrorMessage(`Quick script ${name} not found`);
                return;
            }
            var document = yield vscode.workspace.openTextDocument(script.File);
            vscode.window.showTextDocument(document);
        }));
    }
}
exports.QuickScriptCommands = QuickScriptCommands;
//# sourceMappingURL=quickScripts.js.map