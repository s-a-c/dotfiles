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
exports.ReflectionCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
var fs = require('fs');
class ReflectionCommands {
    register(context) {
        context.subscriptions.push(this.DecompileType());
        context.subscriptions.push(this.LoadAssembly());
    }
    DecompileType() {
        return vscode.commands.registerCommand('poshProTools.decompileType', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            const source = yield container_1.Container.PowerShellService.DecompileType(node.type.AssemblyName, node.type.FullTypeName);
            if (!source || source === '') {
                vscode.window.showErrorMessage("Failed to decompile type.");
                return;
            }
            fs.readFile(source, 'utf8', (err, data) => __awaiter(this, void 0, void 0, function* () {
                const doc = yield vscode.workspace.openTextDocument({
                    language: "csharp",
                    content: data
                });
                vscode.window.showTextDocument(doc);
            }));
        }));
    }
    LoadAssembly() {
        return vscode.commands.registerCommand('poshProTools.loadAssembly', () => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            const result = yield vscode.window.showOpenDialog({
                canSelectFiles: true,
                canSelectFolders: false,
                canSelectMany: true,
                filters: {
                    'Binaries': ['exe', 'dll']
                }
            });
            result.forEach((x) => __awaiter(this, void 0, void 0, function* () {
                container_1.Container.PowerShellService.LoadAssembly(x.fsPath);
            }));
            yield vscode.commands.executeCommand('reflectionView.refresh');
        }));
    }
}
exports.ReflectionCommands = ReflectionCommands;
//# sourceMappingURL=reflection.js.map