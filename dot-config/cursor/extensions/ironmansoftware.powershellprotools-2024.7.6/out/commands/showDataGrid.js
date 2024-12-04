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
exports.showDataGrid = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
var fs = require('fs');
const path = require("path");
const net = require("net");
var server = null;
function init(panel) {
    server = net.createServer(function (stream) {
        stream.on('data', (c) => {
            const str = c.toString();
            const msg = JSON.parse(str);
            panel.webview.postMessage(msg);
            stream.end();
        });
    });
    var terminal = vscode.window.terminals.find(x => x.name === "PowerShell Extension");
    if (terminal == null) {
        throw "PowerShell Extension not found.";
    }
    terminal.processId.then(x => {
        var pipePath = `/tmp/PPTPipePerformance${x}`;
        if (process.platform === "win32") {
            pipePath = `\\\\.\\pipe\\PPTPipePerformance${x}`;
        }
        server.listen(pipePath);
    });
}
function showDataGrid(context) {
    return vscode.commands.registerCommand('poshProTools.dataGrid', () => __awaiter(this, void 0, void 0, function* () {
        if (!container_1.Container.IsInitialized())
            return;
        const cssUri = vscode.Uri.file(path.join(context.extensionPath, 'resources', 'datatables.min.css')).with({ scheme: 'vscode-resource' });
        const jsUri = vscode.Uri.file(path.join(context.extensionPath, 'resources', 'datatables.min.js')).with({ scheme: 'vscode-resource' });
        const panel = vscode.window.createWebviewPanel('poshProToolsDataGrid', 'PowerShell Grid View', vscode.ViewColumn.One, {
            enableScripts: true
        });
        init(panel);
        const resourcesHead = `<link rel="stylesheet" href="${cssUri}">
        <script src="${jsUri}"></script>`;
        var text = getText();
        panel.webview.html = text.replace('${head}', resourcesHead);
        panel.onDidDispose(x => {
            server.close();
        });
    }));
}
exports.showDataGrid = showDataGrid;
function getText() {
    var welcomePath = container_1.Container.context.asAbsolutePath(path.join('resources', 'grid-view.html'));
    return fs.readFileSync(welcomePath, 'utf8');
}
//# sourceMappingURL=showDataGrid.js.map