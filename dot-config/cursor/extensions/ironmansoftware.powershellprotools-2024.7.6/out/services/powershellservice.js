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
exports.PowerShellService = exports.SessionStatus = void 0;
const vscode = require("vscode");
const net = require("net");
const path = require("path");
const container_1 = require("../container");
const settings_1 = require("../settings");
const randomstring = require('randomstring');
const os = require('os');
const fs = require('fs');
var SessionStatus;
(function (SessionStatus) {
    SessionStatus[SessionStatus["Initializing"] = 0] = "Initializing";
    SessionStatus[SessionStatus["Failed"] = 1] = "Failed";
    SessionStatus[SessionStatus["Connected"] = 2] = "Connected";
    SessionStatus[SessionStatus["Disabled"] = 3] = "Disabled";
})(SessionStatus = exports.SessionStatus || (exports.SessionStatus = {}));
class PowerShellService {
    get status() {
        return this.sessionStatus;
    }
    constructor(context, pipeName) {
        this.reconnectDepth = 0;
        this.statusBarItem =
            vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 1);
        this.statusBarItem.command = "poshProTools.statusBarMenu";
        this.statusBarItem.show();
        vscode.window.onDidChangeActiveTextEditor((textEditor) => {
            if (textEditor === undefined
                || textEditor.document.languageId !== "powershell") {
                this.statusBarItem.hide();
            }
            else {
                this.statusBarItem.show();
            }
        });
        context.subscriptions.push(this.statusBarItem);
        if (pipeName) {
            this.pipeName = pipeName;
        }
        else {
            this.pipeName = randomstring.generate({
                length: 12,
                charset: 'alphabetic'
            }).toLowerCase();
        }
        this.setSessionStatus(SessionStatus.Initializing);
    }
    setSessionStatus(status) {
        // Set color and icon for 'Running' by default
        let statusIconText = "$(sync) PowerShell Pro Tools";
        let statusColor = "#f3fc74";
        let toolTip = "PowerShell Pro Tools is connecting...";
        if (status === SessionStatus.Connected) {
            statusIconText = "$(link) PowerShell Pro Tools";
            statusColor = "#affc74";
            toolTip = "PowerShell Pro Tools is connected";
        }
        else if (status === SessionStatus.Failed) {
            statusIconText = "$(alert) PowerShell Pro Tools";
            statusColor = "#fcc174";
            toolTip = "PowerShell Pro Tools failed to connect. Check out the Output channel for PowerShell Pro Tools for more information.";
        }
        else if (status === SessionStatus.Disabled) {
            statusIconText = "$(circle-slash) PowerShell Pro Tools";
            statusColor = "#fcc174";
            toolTip = "PowerShell Pro Tools is disabled because Persistent Terminal Sessions is enabled. Please disable Persistent Terminal Sessions and reload the window.";
        }
        this.statusBarItem.color = statusColor;
        this.statusBarItem.text = statusIconText;
        this.statusBarItem.tooltip = toolTip;
        this.sessionStatus = status;
    }
    Reconnect(callback) {
        var _a;
        this.reconnectDepth++;
        this.setSessionStatus(SessionStatus.Initializing);
        (_a = this.logger) === null || _a === void 0 ? void 0 : _a.destroy();
        if (this.reconnectDepth > 10) {
            container_1.Container.Log("Reconnect depth exceeded. Connection failed.");
            this.setSessionStatus(SessionStatus.Failed);
            return;
        }
        const handle = setInterval(() => __awaiter(this, void 0, void 0, function* () {
            var terminal = vscode.window.terminals.find(x => x.name.startsWith("PowerShell Extension"));
            if (terminal == null) {
                container_1.Container.Log("Terminal has not restarted.");
                return;
            }
            container_1.Container.Log("PowerShell Extension has restarted. Connecting.");
            clearInterval(handle);
            this.Connect(callback);
        }), 5000);
    }
    Connect(callback) {
        if (this.status === SessionStatus.Connected) {
            container_1.Container.Log("Already connected to PowerShell process.");
            callback();
            return;
        }
        var cmdletPath = path.join(vscode.extensions.getExtension("ironmansoftware.powershellprotools").extensionPath, "Modules", "PowerShellProTools.VSCode", "PowerShellProTools.VSCode.psd1");
        if (!fs.existsSync(cmdletPath)) {
            cmdletPath = path.join(vscode.extensions.getExtension("ironmansoftware.powershellprotools").extensionPath, "src", "Modules", "PowerShellProTools.VSCode", "PowerShellProTools.VSCode.psd1");
        }
        var poshToolsModulePath = path.join(vscode.extensions.getExtension("ironmansoftware.powershellprotools").extensionPath, "Modules", "PowerShellProTools", "PowerShellProTools.psd1");
        if (!fs.existsSync(poshToolsModulePath)) {
            poshToolsModulePath = path.join(vscode.extensions.getExtension("ironmansoftware.powershellprotools").extensionPath, "src", "Modules", "PowerShellProTools", "PowerShellProTools.psd1");
        }
        var terminal = vscode.window.terminals.find(x => x.name.startsWith("PowerShell Extension"));
        if (terminal != null) {
            container_1.Container.Log("Importing module in PowerShell and starting server.");
            terminal.sendText(`Import-Module '${cmdletPath}'`, true);
            terminal.sendText(`Import-Module '${poshToolsModulePath}'`, true);
            terminal.sendText(`Start-PoshToolsServer -PipeName '${this.pipeName}'`, true);
            const settings = (0, settings_1.load)();
            if (settings.clearScreenAfterLoad) {
                terminal.sendText('Clear-Host', true);
            }
        }
        else {
            container_1.Container.Log("PowerShell Extension not found.");
            this.setSessionStatus(SessionStatus.Failed);
            throw ("PowerShell Extension not found.");
        }
        setTimeout(() => {
            container_1.Container.Log("Connecting named pipe to PoshTools server.");
            var pipePath = path.join(os.tmpdir(), `CoreFxPipe_${this.pipeName}_log`);
            if (process.platform === "win32") {
                pipePath = `\\\\.\\pipe\\${this.pipeName}_log`;
            }
            this.logger = net.connect(pipePath);
            this.logger.on('data', (data) => {
                try {
                    let buff = Buffer.from(data.toString(), 'base64');
                    let text = buff.toString('utf-8');
                    container_1.Container.Log(text);
                }
                catch (e) {
                    container_1.Container.Log("Error parsing log data. " + e);
                }
            });
            this.invokeMethod("Connect", []).then((result) => {
                this.reconnectDepth = 0;
                this.setSessionStatus(SessionStatus.Connected);
                container_1.Container.FinishInitialize();
                container_1.Container.Log("Connected to PowerShell process.");
                callback();
            }).catch(x => {
                container_1.Container.Log("Failed to connect to PowerShell process." + x);
                this.setSessionStatus(SessionStatus.Failed);
            });
        }, 1000);
    }
    InvokePowerShell(command) {
        return new Promise((resolve, reject) => {
            this.invokeMethod("ExecutePowerShell", [command]).then(response => {
                if (response.error) {
                    container_1.Container.Log("Error executing PowerShell command: " + response.error);
                    vscode.window.showErrorMessage(response.error);
                    reject();
                }
                else {
                    resolve(response);
                }
            });
        });
    }
    invokeMethod(method, args) {
        return new Promise((resolve, reject) => {
            var pipePath = path.join(os.tmpdir(), `CoreFxPipe_${this.pipeName}`);
            if (process.platform === "win32") {
                pipePath = `\\\\.\\pipe\\${this.pipeName}`;
            }
            var client = net.connect(pipePath, function () {
                const request = {
                    method,
                    args
                };
                const json = JSON.stringify(request);
                let buf = Buffer.from(json);
                let encodedData = buf.toString('base64');
                client.write(encodedData + "\r\n");
            });
            client.on("error", (e) => {
                container_1.Container.Log(`Invoke method: ${method} Error sending data on named pipe. ${e}`);
                client.destroy();
                setTimeout(() => __awaiter(this, void 0, void 0, function* () {
                    yield this.Reconnect(() => this.invokeMethod(method, args).then(any => resolve(any)));
                }), 1000);
            });
            client.on('data', (data) => {
                try {
                    let buff = Buffer.from(data.toString(), 'base64');
                    let text = buff.toString('utf-8');
                    var response = JSON.parse(text);
                    resolve(response);
                }
                catch (_a) {
                }
                client.destroy();
            });
        });
    }
    Package(packageConfig) {
        return __awaiter(this, void 0, void 0, function* () {
            this.SendTerminalCommand(`Merge-Script -ConfigFile '${packageConfig}' -Verbose`);
        });
    }
    OpenPsScriptPad(file) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("OpenPsScriptPad", [file]);
            return response.Data;
        });
    }
    DisablePsesIntelliSense(options) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("DisablePsesIntelliSense", [JSON.stringify(options)]);
            return response.Data;
        });
    }
    EnablePsesIntelliSense() {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("EnablePsesIntelliSense", []);
            return response.Data;
        });
    }
    RefreshCompletionCache() {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("RefreshCompletionCache", []);
            return response.Data;
        });
    }
    InstallPoshToolsModule() {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("InstallPoshToolsModule", []);
            return response.Data;
        });
    }
    GetVariables() {
        return __awaiter(this, void 0, void 0, function* () {
            const settings = (0, settings_1.load)();
            var response = yield this.invokeMethod("GetVariables", [settings.excludeAutomaticVariables]);
            return response.Data;
        });
    }
    ExpandVariable(path) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("ExpandVariable", [path]);
            return response.Data;
        });
    }
    GetAst(path) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("ParseAst", [path]);
            return response.Data;
        });
    }
    GetAstByHashcode(hashcode) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("GetAstChildren", [hashcode]);
            return response.Data;
        });
    }
    GetModulePath(name, version) {
        return __awaiter(this, void 0, void 0, function* () {
            return this.invokeMethod("GetModulePath", [name, version]);
        });
    }
    FindModuleVersion(name) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("FindModuleVersion", [name]);
            return response.Data;
        });
    }
    UninstallModule(name, version) {
        return __awaiter(this, void 0, void 0, function* () {
            return yield this.invokeMethod("UninstallModule", [name, version]);
        });
    }
    UpdateModule(name) {
        return __awaiter(this, void 0, void 0, function* () {
            return yield this.invokeMethod("UpdateModule", [name]);
        });
    }
    GetModules() {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("GetModules", []);
            return response.Data;
        });
    }
    GetProviders() {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("GetProviders", []);
            return response.Data;
        });
    }
    GetProviderDrives(provider) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("GetProviderDrives", [provider]);
            return response.Data;
        });
    }
    GetContainers(parent) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetContainers", [parent]);
            return result.Data;
        });
    }
    GetItems(parent) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetItems", [parent]);
            return result.Data;
        });
    }
    MeasureScript(fileName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("MeasureScript", [fileName]);
            return result.Data;
        });
    }
    GetPSHostProcess() {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("GetPSHostProcesses", []);
            return response.Data;
        });
    }
    GetRunspaces(processId) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("GetRunspaces", [processId]);
            return response.Data;
        });
    }
    AttachToRunspace(processId, runspaceId) {
        vscode.debug.startDebugging(vscode.workspace.workspaceFolders[0], {
            name: "PowerShell Attach",
            type: "PowerShell",
            request: "attach",
            processId,
            runspaceId
        });
    }
    Complete(trigger, currentLine, position) {
        return __awaiter(this, void 0, void 0, function* () {
            var response = yield this.invokeMethod("Complete", [trigger, currentLine, position]);
            return response.Data;
        });
    }
    GenerateWinForm(codeFilePath, formPath) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("GenerateWinForm", [codeFilePath, formPath, false]);
        });
    }
    GenerateTool(codeFilePath, formPath) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("GenerateWinForm", [codeFilePath, formPath, true]);
        });
    }
    ShowFormDesigner(codeFilePath, designerFilePath) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("ShowWinFormDesigner", [designerFilePath, codeFilePath]);
        });
    }
    ShowWpfFormDesigner(codeFilePath) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("ShowWpfFormDesigner", [codeFilePath]);
        });
    }
    ConvertToPowerShellFromFile(fileName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("ConvertToPowerShellFromFile", [fileName]);
            return result.Data;
        });
    }
    ConvertToPowerShell(script) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("ConvertToPowerShell", [script]);
            return result.Data;
        });
    }
    ConvertToCSharpFromFile(fileName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("ConvertToCSharpFromFile", [fileName]);
            return result.Data;
        });
    }
    ConvertToCSharp(script) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("ConvertToCSharp", [script]);
            return result.Data;
        });
    }
    GetItemProperty(path) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetItemProperty", [path]);
            return result.Data;
        });
    }
    ViewItems(path) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("ViewItems", [path]);
            return result.Data;
        });
    }
    GetPowerShellProcessPath() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetPowerShellProcessPath", []);
            return result.Data;
        });
    }
    RenameSymbol(newName, workspaceRoot, request) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("RenameSymbol", [newName, workspaceRoot, JSON.stringify(request)]);
            return result.Data;
        });
    }
    Refactor(request) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("Refactor", [JSON.stringify(request)]);
            return result.Data;
        });
    }
    GetValidRefactors(request) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetValidRefactors", [JSON.stringify(request)]);
            return result.Data;
        });
    }
    GetHover(state) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetHover", [JSON.stringify(state)]);
            return result.Data;
        });
    }
    AddWorkspaceFolder(root) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("AddWorkspaceFolder", [root]);
            return result.Data;
        });
    }
    AnalyzeWorkspaceFile(file) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("AnalyzeWorkspaceFile", [file]);
            return result.Data;
        });
    }
    RemoveWorkspaceFolder(root) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("RemoveWorkspaceFolder", [root]);
            return result.Data;
        });
    }
    GetFunctionDefinitions(file, root) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetFunctionDefinitions", [file, root]);
            return result.Data;
        });
    }
    GetCodeSigningCerts() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetCodeSigningCerts", []);
            return result.Data;
        });
    }
    SignScript(filePath, certificatePath) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("SignScript", [filePath, certificatePath]);
            return result.Data;
        });
    }
    GetAssemblies() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetAssemblies", []);
            return result.Data;
        });
    }
    GetTypes(assembly, parentNamespace) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetTypes", [assembly, parentNamespace]);
            return result.Data;
        });
    }
    GetNamespaces(assembly, parentNamespace) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetNamespaces", [assembly, parentNamespace]);
            return result.Data;
        });
    }
    GetMethods(assembly, typeName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetMethods", [assembly, typeName]);
            return result.Data;
        });
    }
    GetProperties(assembly, typeName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetProperties", [assembly, typeName]);
            return result.Data;
        });
    }
    GetFields(assembly, typeName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetFields", [assembly, typeName]);
            return result.Data;
        });
    }
    FindType(typeName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("FindType", [typeName]);
            return result.Data;
        });
    }
    DecompileType(assemblyName, fullTypeName) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("DecompileType", [assemblyName, fullTypeName]);
            return result.Data;
        });
    }
    LoadAssembly(assemblyPath) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("LoadAssembly", [assemblyPath]);
            return result.Data;
        });
    }
    GetTreeViews() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetTreeViews", []);
            return result.Data;
        });
    }
    LoadChildren(treeViewId, path) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("LoadChildren", [treeViewId, path]);
            return result.Data;
        });
    }
    InvokeChild(treeViewId, path) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("InvokeChild", [treeViewId, path]);
        });
    }
    RefreshTreeView(treeViewId) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("RefreshTreeView", [treeViewId]);
        });
    }
    GetHistory() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetHistory", []);
            return result.Data;
        });
    }
    GetSessions() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetSessions", []);
            return result.Data;
        });
    }
    EnterSession(id) {
        return __awaiter(this, void 0, void 0, function* () {
            container_1.Container.PowerShellService.SendTerminalCommand(`Enter-PSSession ${id}`);
        });
    }
    ExitSession() {
        return __awaiter(this, void 0, void 0, function* () {
            container_1.Container.PowerShellService.SendTerminalCommand('Exit-PSSession');
        });
    }
    RemoveSession(id) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("RemoveSession", [id]);
        });
    }
    GetJobs() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetJobs", []);
            return result.Data;
        });
    }
    DebugJob(id) {
        return __awaiter(this, void 0, void 0, function* () {
            this.SendTerminalCommand(`Debug-Job -Id ${id}`);
        });
    }
    RemoveJob(id) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("RemoveJob", [id]);
        });
    }
    ReceiveJob(id) {
        return __awaiter(this, void 0, void 0, function* () {
            this.SendTerminalCommand(`Receive-Job -Id ${id}`);
        });
    }
    StopJob(id) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("StopJob", [id]);
        });
    }
    FindModule(module) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("FindModule", [module]);
            return result.Data;
        });
    }
    InstallModule(module) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.invokeMethod("InstallModule", [module]);
        });
    }
    GetPerformance() {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield this.invokeMethod("GetPerformance", []);
            return result.Data;
        });
    }
    SendTerminalCommand(command) {
        var terminal = vscode.window.terminals.find(x => x.name.startsWith("PowerShell Extension"));
        if (terminal == null) {
            return;
        }
        terminal.sendText(command, true);
    }
}
exports.PowerShellService = PowerShellService;
//# sourceMappingURL=powershellservice.js.map