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
exports.manageEndpointsCommand = exports.insertInvokeRestMethodCommand = exports.openEndpointConfigFileCommand = exports.openEndpointScriptBlockCommand = exports.registerEndpointCommands = void 0;
const vscode = require("vscode");
const settings_1 = require("./../settings");
const container_1 = require("../container");
const path = require('path');
const fs = require("fs");
const utils_1 = require("./utils");
let files = [];
exports.registerEndpointCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.openEndpointScriptBlock', exports.openEndpointScriptBlockCommand);
    vscode.commands.registerCommand('powershell-universal.openEndpointConfigFile', exports.openEndpointConfigFileCommand);
    vscode.commands.registerCommand('powershell-universal.insertRestMethod', (item) => exports.insertInvokeRestMethodCommand(item, context));
    vscode.commands.registerCommand('powershell-universal.manageEndpoints', () => exports.manageEndpointsCommand(context));
    vscode.workspace.onDidSaveTextDocument((file) => __awaiter(void 0, void 0, void 0, function* () {
        if (file.fileName.includes('.universal.code.endpoints')) {
            const info = files.find(x => x.filePath.toLowerCase() === file.fileName.toLowerCase());
            container_1.Container.universal.getEndpoint(info).then((endpoint) => {
                endpoint.scriptBlock = file.getText();
                container_1.Container.universal.saveEndpoint(endpoint);
            });
        }
    }));
    vscode.workspace.onDidCloseTextDocument((file) => {
        files = files.filter(x => x.filePath !== file.fileName);
    });
};
exports.openEndpointScriptBlockCommand = (node) => __awaiter(void 0, void 0, void 0, function* () {
    var settings = settings_1.load();
    if (settings.localEditing) {
        vscode.window.showErrorMessage('Local editing is not supported for this command');
    }
    else {
        const os = require('os');
        const filePath = path.join(utils_1.tmpdir(), '.universal.code.endpoints', `${node.endpoint.id}.ps1`);
        const codePath = path.join(utils_1.tmpdir(), '.universal.code.endpoints');
        const config = yield container_1.Container.universal.getEndpoint(node.endpoint);
        if (!fs.existsSync(codePath)) {
            fs.mkdirSync(codePath);
        }
        fs.writeFileSync(filePath, config.scriptBlock);
        const textDocument = yield vscode.workspace.openTextDocument(filePath);
        vscode.window.showTextDocument(textDocument);
        files.push({
            id: node.endpoint.id,
            filePath: filePath
        });
    }
});
exports.openEndpointConfigFileCommand = () => __awaiter(void 0, void 0, void 0, function* () {
    var settings = settings_1.load();
    if (settings.localEditing) {
        const psuSettings = yield container_1.Container.universal.getSettings();
        const filePath = path.join(psuSettings.repositoryPath, '.universal', 'endpoints.ps1');
        const textDocument = yield vscode.workspace.openTextDocument(filePath);
        vscode.window.showTextDocument(textDocument);
    }
    else {
        const os = require('os');
        const filePath = path.join(utils_1.tmpdir(), '.universal.code.configuration', 'endpoints.ps1');
        const codePath = path.join(utils_1.tmpdir(), '.universal.code.configuration');
        const config = yield container_1.Container.universal.getConfiguration('endpoints.ps1');
        if (!fs.existsSync(codePath)) {
            fs.mkdirSync(codePath);
        }
        fs.writeFileSync(filePath, config);
        const textDocument = yield vscode.workspace.openTextDocument(filePath);
        vscode.window.showTextDocument(textDocument);
    }
});
exports.insertInvokeRestMethodCommand = (endpoint, context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    var terminal = vscode.window.terminals.find(x => x.name === "PowerShell Extension");
    terminal === null || terminal === void 0 ? void 0 : terminal.sendText(`Invoke-RestMethod -Uri "${url}${endpoint.endpoint.url.replace(':', '$')}" -Method ${endpoint.endpoint.method}`, false);
});
exports.manageEndpointsCommand = (context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/apis/endpoints`));
});
//# sourceMappingURL=endpoints.js.map