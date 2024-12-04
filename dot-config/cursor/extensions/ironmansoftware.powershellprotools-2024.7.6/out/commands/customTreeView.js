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
exports.CustomTreeViewCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class CustomTreeViewCommands {
    register(context) {
        context.subscriptions.push(this.AttachRunspace());
    }
    AttachRunspace() {
        return vscode.commands.registerCommand('customView.invoke', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            yield container_1.Container.PowerShellService.InvokeChild(node.treeViewId, node.path);
        }));
    }
}
exports.CustomTreeViewCommands = CustomTreeViewCommands;
//# sourceMappingURL=customTreeView.js.map