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
exports.Connection = exports.AddConnection = exports.registerConnectCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
exports.registerConnectCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.addConnection', exports.AddConnection);
    vscode.commands.registerCommand('powershell-universal.connection', x => exports.Connection(x, context));
};
exports.AddConnection = (context) => __awaiter(void 0, void 0, void 0, function* () {
    vscode.commands.executeCommand('workbench.action.openSettings', "PowerShell Universal");
});
exports.Connection = (treeItem, context) => __awaiter(void 0, void 0, void 0, function* () {
    const name = treeItem.connection.name;
    context.globalState.update("universal.connection", name);
    vscode.commands.executeCommand('powershell-universal.refreshAllTreeViews');
    yield container_1.Container.universal.installAndLoadModule();
});
//# sourceMappingURL=connect.js.map