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
exports.ProviderCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class ProviderCommands {
    register(context) {
        context.subscriptions.push(this.insertProviderPath());
        context.subscriptions.push(this.viewItemProperties());
        context.subscriptions.push(this.viewChildItems());
    }
    insertProviderPath() {
        return vscode.commands.registerCommand('poshProTools.insertProviderPath', (item) => __awaiter(this, void 0, void 0, function* () {
            var activeEditor = vscode.window.activeTextEditor;
            if (!activeEditor)
                return;
            activeEditor.edit(x => {
                x.insert(activeEditor.selection.active, item.path);
            });
        }));
    }
    viewItemProperties() {
        return vscode.commands.registerCommand('poshProTools.viewItemProperties', (item) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            container_1.Container.PowerShellService.GetItemProperty(item.path);
        }));
    }
    viewChildItems() {
        return vscode.commands.registerCommand('poshProTools.viewItems', (item) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            container_1.Container.PowerShellService.ViewItems(item.path);
        }));
    }
}
exports.ProviderCommands = ProviderCommands;
//# sourceMappingURL=providers.js.map