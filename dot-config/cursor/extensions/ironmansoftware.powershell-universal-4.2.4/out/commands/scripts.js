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
exports.getJobPipelineOutputCommand = exports.viewJobCommand = exports.viewJobLogCommand = exports.manageScriptsCommand = exports.invokeScriptCommand = exports.editScriptLocal = exports.editScriptRemote = exports.editScriptCommand = exports.openScriptConfigFileCommand = exports.registerScriptCommands = void 0;
const vscode = require("vscode");
const settings_1 = require("./../settings");
const container_1 = require("../container");
const job_tracker_1 = require("../job-tracker");
const path = require('path');
const os = require('os');
const fs = require("fs");
const utils_1 = require("./utils");
function normalizeDriveLetter(path) {
    if (hasDriveLetter(path)) {
        return path.charAt(0).toUpperCase() + path.slice(1);
    }
    return path;
}
function hasDriveLetter(path) {
    if (os.platform() == 'win32') {
        return isWindowsDriveLetter(path.charCodeAt(0)) && path.charCodeAt(1) === 58;
    }
    return false;
}
function isWindowsDriveLetter(char0) {
    return char0 >= 65 && char0 <= 90 || char0 >= 97 && char0 <= 122;
}
exports.registerScriptCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.openScriptConfigFile', exports.openScriptConfigFileCommand);
    vscode.commands.registerCommand('powershell-universal.invokeScript', item => exports.invokeScriptCommand(item, context));
    vscode.commands.registerCommand('powershell-universal.manageScripts', () => exports.manageScriptsCommand(context));
    vscode.commands.registerCommand('powershell-universal.editScript', exports.editScriptCommand);
    vscode.commands.registerCommand('powershell-universal.viewJobLog', exports.viewJobLogCommand);
    vscode.commands.registerCommand('powershell-universal.viewJob', (item) => exports.viewJobCommand(item, context));
    vscode.commands.registerCommand('powershell-universal.getJobPipelineOutput', exports.getJobPipelineOutputCommand);
    vscode.workspace.onDidSaveTextDocument((file) => __awaiter(void 0, void 0, void 0, function* () {
        if (file.fileName.includes('.universal.code.script')) {
            const codePath = path.join(utils_1.tmpdir(), '.universal.code.script');
            const normCodePath = normalizeDriveLetter(codePath);
            const normFileName = normalizeDriveLetter(file.fileName);
            const fileName = normFileName.replace(normCodePath, "").replace(/^\\*/, "").replace(/^\/*/, "");
            try {
                var script = yield container_1.Container.universal.getScriptFilePath(fileName);
                script.content = file.getText();
                script = yield container_1.Container.universal.saveScript(script);
                if (script.content && script.content !== file.getText()) {
                    throw "Failed to save script!";
                }
            }
            catch (e) {
                vscode.window.showErrorMessage(e);
            }
        }
    }));
};
exports.openScriptConfigFileCommand = () => __awaiter(void 0, void 0, void 0, function* () {
    const settings = yield container_1.Container.universal.getSettings();
    const filePath = path.join(settings.repositoryPath, '.universal', 'scripts.ps1');
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.editScriptCommand = (item) => __awaiter(void 0, void 0, void 0, function* () {
    var settings = settings_1.load();
    if (settings.localEditing) {
        yield exports.editScriptLocal(item);
    }
    else {
        yield exports.editScriptRemote(item);
    }
});
exports.editScriptRemote = (item) => __awaiter(void 0, void 0, void 0, function* () {
    //https://stackoverflow.com/a/56620552
    const filePath = path.join(utils_1.tmpdir(), '.universal.code.script', item.script.fullPath);
    const codePath = path.join(utils_1.tmpdir(), '.universal.code.script');
    const script = yield container_1.Container.universal.getScript(item.script.id);
    if (!fs.existsSync(codePath)) {
        fs.mkdirSync(codePath);
    }
    fs.mkdirSync(path.dirname(filePath), { "recursive": true });
    fs.writeFileSync(filePath, script.content);
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.editScriptLocal = (item) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = yield container_1.Container.universal.getSettings();
    const filePath = path.join(settings.repositoryPath, item.script.fullPath);
    if (!fs.existsSync(filePath)) {
        yield vscode.window.showErrorMessage(`Failed to find file ${filePath}. If you have local editing on and are accessing a remote file, you may need to turn off local editing.`);
        return;
    }
    const textDocument = yield vscode.workspace.openTextDocument(filePath);
    vscode.window.showTextDocument(textDocument);
});
exports.invokeScriptCommand = (item, context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    const parameters = yield container_1.Container.universal.getScriptParameters(item.script.id);
    if (parameters && parameters.length > 0) {
        const result = yield vscode.window.showWarningMessage(`Script has parameters and cannot be run from VS Code.`, "View Script");
        if (result === "View Script") {
            vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/automation/scripts/${item.script.fullPath}`));
        }
    }
    else {
        const jobId = yield container_1.Container.universal.runScript(item.script.id);
        const result = yield vscode.window.showInformationMessage(`Job ${jobId} started.`, "View Job");
        if (result === "View Job") {
            vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/automation/jobs/${jobId}`));
        }
        job_tracker_1.trackJob(jobId);
    }
});
exports.manageScriptsCommand = (context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/automation/scripts`));
});
let jobLogChannel = vscode.window.createOutputChannel("PowerShell Universal - Job");
exports.viewJobLogCommand = (jobItem) => __awaiter(void 0, void 0, void 0, function* () {
    jobLogChannel.clear();
    jobLogChannel.show();
    jobLogChannel.append(`Loading log for job ${jobItem.job.id}...`);
    container_1.Container.universal.getJobLog(jobItem.job.id).then((log) => {
        jobLogChannel.clear();
        jobLogChannel.appendLine(log.log);
    });
});
exports.viewJobCommand = (jobItem, context) => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const connectionName = context.globalState.get("universal.connection");
    var url = settings.url;
    if (connectionName && connectionName !== 'Default') {
        const connection = settings.connections.find(m => m.name === connectionName);
        if (connection) {
            url = connection.url;
        }
    }
    vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/automation/jobs/${jobItem.job.id}`));
});
exports.getJobPipelineOutputCommand = (jobItem) => __awaiter(void 0, void 0, void 0, function* () {
    container_1.Container.universal.sendTerminalCommand(`Get-PSUJobPipelineOutput -JobId ${jobItem.job.id}`);
});
//# sourceMappingURL=scripts.js.map