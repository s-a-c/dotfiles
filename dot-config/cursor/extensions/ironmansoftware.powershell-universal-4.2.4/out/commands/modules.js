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
exports.editModuleCommand = exports.addModuleCommand = exports.registerModuleCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const path = require('path');
const fs = require("fs");
const utils_1 = require("./utils");
let files = [];
exports.registerModuleCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.editModule', exports.editModuleCommand);
    vscode.commands.registerCommand('powershell-universal.newModule', exports.addModuleCommand);
    vscode.workspace.onDidSaveTextDocument((file) => __awaiter(void 0, void 0, void 0, function* () {
        if (file.fileName.includes('.universal.code.modules')) {
            const info = files.find(x => x.filePath.toLowerCase() === file.fileName.toLowerCase());
            container_1.Container.universal.getModule(info.id).then((module) => {
                module.content = file.getText();
                container_1.Container.universal.updateModule(module);
            });
        }
    }));
};
exports.addModuleCommand = () => __awaiter(void 0, void 0, void 0, function* () {
    const name = yield vscode.window.showInputBox({
        prompt: 'Enter the name of the module to add.'
    });
    if (!name) {
        return;
    }
    yield container_1.Container.universal.newModule(name);
    vscode.commands.executeCommand('powershell-universal.refreshPlatformTreeView');
});
exports.editModuleCommand = (node) => __awaiter(void 0, void 0, void 0, function* () {
    const filePath = path.join(utils_1.tmpdir(), '.universal.code.modules', `${node.module.id}.ps1`);
    const codePath = path.join(utils_1.tmpdir(), '.universal.code.modules');
    const config = yield container_1.Container.universal.getModule(node.module.id);
    if (!fs.existsSync(codePath)) {
        fs.mkdirSync(codePath);
    }
    fs.writeFileSync(filePath, config.content);
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
    files.push({
        id: node.module.id,
        filePath: filePath
    });
});
//# sourceMappingURL=modules.js.map