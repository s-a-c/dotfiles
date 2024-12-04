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
exports.refreshConfig = exports.openConfigLocal = exports.openConfigRemote = exports.openConfigCommand = exports.newConfigFolderCommand = exports.newConfigFileCommand = exports.registerConfigCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const path = require('path');
const fs = require("fs"); // In NodeJS: 'const fs = require('fs')'
const settings_1 = require("../settings");
const utils_1 = require("./utils");
exports.registerConfigCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.openConfigFile', exports.openConfigCommand);
    vscode.commands.registerCommand('powershell-universal.newConfigFile', exports.newConfigFileCommand);
    vscode.commands.registerCommand('powershell-universal.newConfigFolder', exports.newConfigFolderCommand);
    vscode.commands.registerCommand('powershell-universal.reloadConfig', exports.refreshConfig);
    vscode.workspace.onDidSaveTextDocument((file) => __awaiter(void 0, void 0, void 0, function* () {
        if (file.fileName.includes('.universal.code.configuration')) {
            const version = yield container_1.Container.universal.getVersion();
            if (version.startsWith("3") || version.startsWith("4")) {
                const codePath = path.join(utils_1.tmpdir(), '.universal.code.configuration');
                const fileName = file.fileName.toLocaleLowerCase().replace(codePath.toLocaleLowerCase(), "").substring(1);
                yield container_1.Container.universal.saveFileContent(fileName, file.getText());
            }
            else {
                const fileName = path.basename(file.fileName);
                container_1.Container.universal.saveConfiguration(fileName, file.getText());
            }
        }
    }));
};
exports.newConfigFileCommand = (item) => __awaiter(void 0, void 0, void 0, function* () {
    const fileName = yield vscode.window.showInputBox({
        prompt: "Enter a file name"
    });
    yield container_1.Container.universal.newFile(item.fileName + "/" + fileName);
    container_1.Container.ConfigFileTreeView.refresh();
});
exports.newConfigFolderCommand = (item) => __awaiter(void 0, void 0, void 0, function* () {
    const fileName = yield vscode.window.showInputBox({
        prompt: "Enter a folder name"
    });
    yield container_1.Container.universal.newFolder(item.fileName + "/" + fileName);
    container_1.Container.ConfigFileTreeView.refresh();
});
exports.openConfigCommand = (item) => __awaiter(void 0, void 0, void 0, function* () {
    var settings = settings_1.load();
    if (settings.localEditing) {
        yield exports.openConfigLocal(item);
    }
    else {
        yield exports.openConfigRemote(item);
    }
});
exports.openConfigRemote = (item) => __awaiter(void 0, void 0, void 0, function* () {
    const filePath = path.join(utils_1.tmpdir(), '.universal.code.configuration', item.fileName);
    const codePath = path.join(utils_1.tmpdir(), '.universal.code.configuration');
    if (!fs.existsSync(codePath)) {
        fs.mkdirSync(codePath);
    }
    const version = yield container_1.Container.universal.getVersion();
    if (version.startsWith("3") || version.startsWith("4") || version.startsWith("5")) {
        const config = yield container_1.Container.universal.getFileContent(item.fileName);
        const directory = path.dirname(filePath);
        if (!fs.existsSync(directory)) {
            fs.mkdirSync(directory, { recursive: true });
        }
        fs.writeFileSync(filePath, config.content);
    }
    else {
        const config = yield container_1.Container.universal.getConfiguration(item.fileName);
        fs.writeFileSync(filePath, config);
    }
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
    return textDocument;
});
exports.openConfigLocal = (item) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = yield container_1.Container.universal.getSettings();
    const filePath = path.join(settings.repositoryPath, '.universal', item.fileName);
    if (!fs.existsSync(filePath)) {
        fs.writeFileSync(filePath, '');
    }
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.refreshConfig = () => __awaiter(void 0, void 0, void 0, function* () {
    try {
        yield container_1.Container.universal.refreshConfig();
    }
    catch (error) {
        vscode.window.showErrorMessage(error);
        return;
    }
    vscode.window.showInformationMessage("Configuration reloaded.");
});
//# sourceMappingURL=config.js.map