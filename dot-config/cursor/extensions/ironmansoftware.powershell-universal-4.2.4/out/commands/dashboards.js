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
exports.viewDashboardLogCommand = exports.openDashboardConfigFileCommand = exports.openPageFile = exports.openFileRemote = exports.openFileCommand = exports.restartDashboardCommand = exports.startDashboardCommand = exports.stopDashboardCommand = exports.deleteDashboardPageCommand = exports.addDashboardPageCommand = exports.viewDashboardCommand = exports.openDashboardTerminalCommand = exports.manageDashboardsCommand = exports.registerDashboardCommands = void 0;
const vscode = require("vscode");
const settings_1 = require("./../settings");
const container_1 = require("../container");
const path = require('path');
const fs = require("fs");
const utils_1 = require("./utils");
let files = [];
exports.registerDashboardCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.manageDashboards', () => exports.manageDashboardsCommand(context));
    vscode.commands.registerCommand('powershell-universal.viewDashboard', (item) => exports.viewDashboardCommand(item, context));
    vscode.commands.registerCommand('powershell-universal.stopDashboard', exports.stopDashboardCommand);
    vscode.commands.registerCommand('powershell-universal.addDashboardPage', exports.addDashboardPageCommand);
    vscode.commands.registerCommand('powershell-universal.deleteDashboardPage', exports.deleteDashboardPageCommand);
    vscode.commands.registerCommand('powershell-universal.openDashboardTerminal', exports.openDashboardTerminalCommand);
    vscode.commands.registerCommand('powershell-universal.startDashboard', exports.startDashboardCommand);
    vscode.commands.registerCommand('powershell-universal.restartDashboard', exports.restartDashboardCommand);
    vscode.commands.registerCommand('powershell-universal.openDashboardFile', exports.openFileCommand);
    vscode.commands.registerCommand('powershell-universal.openDashboardPageFile', exports.openPageFile);
    vscode.commands.registerCommand('powershell-universal.openDashboardConfigFile', exports.openDashboardConfigFileCommand);
    vscode.commands.registerCommand('powershell-universal.viewDashboardLog', exports.viewDashboardLogCommand);
    vscode.workspace.onDidSaveTextDocument((file) => __awaiter(void 0, void 0, void 0, function* () {
        if (file.fileName.includes('.universal.code.dashboardPage')) {
            const info = files.find(x => x.filePath.toLowerCase() === file.fileName.toLowerCase());
            if (!info) {
                vscode.window.showErrorMessage(`File from a previous session. Re-open file from the Activity Bar.`);
                return;
            }
            const dashboards = yield container_1.Container.universal.getDashboards();
            const dashboard = dashboards.find(x => x.name === info.dashboardName);
            if (!dashboard) {
                vscode.window.showErrorMessage(`Dashboard ${info.dashboardName} not found.`);
                return;
            }
            const pages = yield container_1.Container.universal.getDashboardPages(dashboard.id);
            const page = pages.find(x => x.name === info.name);
            if (!page) {
                vscode.window.showErrorMessage(`Page ${info.name} not found.`);
                return;
            }
            else {
                page.content = file.getText();
                container_1.Container.universal.saveDashboardPage(page.modelId, dashboard.id, page);
            }
        }
        else if (file.fileName.includes('.universal.code.dashboard')) {
            const info = files.find(x => x.filePath.toLowerCase() === file.fileName.toLowerCase());
            if (!info) {
                vscode.window.showErrorMessage(`File from a previous session. Re-open file from the Activity Bar.`);
                return;
            }
            const dashboards = yield container_1.Container.universal.getDashboards();
            const dashboard = dashboards.find(x => x.name === info.name);
            if (dashboard) {
                dashboard.content = file.getText();
                container_1.Container.universal.saveDashboard(dashboard.id, dashboard);
            }
            else {
                vscode.window.showErrorMessage(`Dashboard ${info.name} not found.`);
            }
        }
    }));
    vscode.workspace.onDidCloseTextDocument((file) => {
        files = files.filter(x => x.filePath !== file.fileName);
    });
};
exports.manageDashboardsCommand = (context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/apps`));
});
exports.openDashboardTerminalCommand = (pageInfo, context) => __awaiter(void 0, void 0, void 0, function* () {
    const writeEmitter = new vscode.EventEmitter();
    var str = '';
    const pty = {
        onDidWrite: writeEmitter.event,
        open: () => __awaiter(void 0, void 0, void 0, function* () {
            var output = yield container_1.Container.universal.executeDashboardTerminal(pageInfo.dashboardId, pageInfo.sessionId, pageInfo.pageId, 'prompt');
            writeEmitter.fire(output.replace(/\r\n$/, ''));
        }),
        close: () => { },
        handleInput: (data) => __awaiter(void 0, void 0, void 0, function* () {
            if (data.charCodeAt(0) === 127) {
                str = str.slice(0, -1);
                writeEmitter.fire('\b \b');
                return;
            }
            else {
                writeEmitter.fire(data);
                str += data;
            }
            if (data === '\r') {
                writeEmitter.fire('\r\n');
                var output = yield container_1.Container.universal.executeDashboardTerminal(pageInfo.dashboardId, pageInfo.sessionId, pageInfo.pageId, str);
                writeEmitter.fire(output.replace("\r", '\r\n'));
                var output = yield container_1.Container.universal.executeDashboardTerminal(pageInfo.dashboardId, pageInfo.sessionId, pageInfo.pageId, 'prompt');
                writeEmitter.fire(output.replace(/\r\n$/, ''));
                str = '';
            }
        })
    };
    const terminal = vscode.window.createTerminal({ name: `App Terminal (${pageInfo.sessionId} \\ ${pageInfo.pageId})`, pty });
    terminal.show();
});
exports.viewDashboardCommand = (dashboard, context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    vscode.env.openExternal(vscode.Uri.parse(`${url}${dashboard.dashboard.baseUrl}`));
});
exports.addDashboardPageCommand = (dashboard) => __awaiter(void 0, void 0, void 0, function* () {
    var name = yield vscode.window.showInputBox({
        prompt: "Enter the name of the page",
    });
    if (name) {
        yield container_1.Container.universal.addDashboardPage(dashboard.dashboard.id, {
            name,
            modelId: 0,
            dashboardId: dashboard.dashboard.id,
            content: ""
        });
        vscode.commands.executeCommand('powershell-universal.refreshTreeView');
    }
});
exports.deleteDashboardPageCommand = (page) => __awaiter(void 0, void 0, void 0, function* () {
    var result = yield vscode.window.showQuickPick(["Yes", "No"], {
        placeHolder: `Are you sure you want to delete ${page.page.name}?`
    });
    if (result === "Yes") {
        yield container_1.Container.universal.deleteDashboardPage(page.page.dashboardId, page.page.modelId);
        vscode.commands.executeCommand('powershell-universal.refreshTreeView');
    }
});
exports.stopDashboardCommand = (dashboard) => __awaiter(void 0, void 0, void 0, function* () {
    yield container_1.Container.universal.stopDashboard(dashboard.dashboard.id);
});
exports.startDashboardCommand = (dashboard) => __awaiter(void 0, void 0, void 0, function* () {
    yield container_1.Container.universal.startDashboard(dashboard.dashboard.id);
});
exports.restartDashboardCommand = (dashboard) => __awaiter(void 0, void 0, void 0, function* () {
    yield container_1.Container.universal.stopDashboard(dashboard.dashboard.id);
    yield container_1.Container.universal.startDashboard(dashboard.dashboard.id);
    const d = yield container_1.Container.universal.getDashboard(dashboard.dashboard.id);
    vscode.commands.executeCommand('powershell-universal.refreshTreeView');
    vscode.window.showInformationMessage(`Dashboard restarted. Process ID: ${d.processId}`);
    yield dashboard.clearLog();
});
exports.openFileCommand = (dashboard) => __awaiter(void 0, void 0, void 0, function* () {
    yield exports.openFileRemote(dashboard);
});
exports.openFileRemote = (dashboard) => __awaiter(void 0, void 0, void 0, function* () {
    const os = require('os');
    const codePath = path.join(utils_1.tmpdir(), '.universal.code.dashboard');
    //Use the id in the path so that we can save the dashboard
    const codePathId = path.join(codePath, dashboard.dashboard.id.toString());
    const filePath = path.join(codePathId, dashboard.dashboard.name + ".ps1");
    const dashboardFile = yield container_1.Container.universal.getDashboard(dashboard.dashboard.id);
    var dirName = path.dirname(filePath);
    if (!fs.existsSync(dirName)) {
        fs.mkdirSync(dirName, { recursive: true });
    }
    fs.writeFileSync(filePath, dashboardFile.content);
    files.push({
        id: dashboard.dashboard.id,
        name: dashboard.dashboard.name,
        filePath: filePath
    });
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.openPageFile = (page) => __awaiter(void 0, void 0, void 0, function* () {
    const os = require('os');
    const codePath = path.join(utils_1.tmpdir(), '.universal.code.dashboardPage');
    //Use the id in the path so that we can save the dashboard
    const codePathId = path.join(codePath, page.page.modelId.toString());
    const filePath = path.join(codePathId, page.page.name + ".ps1");
    const dashboardFile = yield container_1.Container.universal.getDashboardPage(page.page.dashboardId, page.page.modelId);
    const dashboard = yield container_1.Container.universal.getDashboard(page.page.dashboardId);
    var dirName = path.dirname(filePath);
    if (!fs.existsSync(dirName)) {
        fs.mkdirSync(dirName, { recursive: true });
    }
    fs.writeFileSync(filePath, dashboardFile.content);
    files.push({
        id: page.page.modelId,
        name: page.page.name,
        dashboardName: dashboard.name,
        dashboardId: page.page.dashboardId,
        filePath: filePath
    });
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.openDashboardConfigFileCommand = () => __awaiter(void 0, void 0, void 0, function* () {
    const os = require('os');
    const filePath = path.join(utils_1.tmpdir(), '.universal.code.configuration', 'dashboards.ps1');
    const codePath = path.join(utils_1.tmpdir(), '.universal.code.configuration');
    const config = yield container_1.Container.universal.getConfiguration('dashboards.ps1');
    if (!fs.existsSync(codePath)) {
        fs.mkdirSync(codePath);
    }
    fs.writeFileSync(filePath, config);
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.viewDashboardLogCommand = (item) => __awaiter(void 0, void 0, void 0, function* () {
    yield item.showLog();
});
//# sourceMappingURL=dashboards.js.map