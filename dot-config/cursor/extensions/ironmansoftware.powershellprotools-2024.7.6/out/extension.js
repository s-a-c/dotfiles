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
exports.activate = void 0;
const vscode = require("vscode");
const packageAsExe_1 = require("./commands/packageAsExe");
const convertToUdElement_1 = require("./commands/convertToUdElement");
const profile_1 = require("./commands/profile");
const formsDesigner_1 = require("./commands/formsDesigner");
const generateWinForm_1 = require("./commands/generateWinForm");
const powershellservice_1 = require("./services/powershellservice");
const container_1 = require("./container");
const showDataGrid_1 = require("./commands/showDataGrid");
const statusBarItemMenu_1 = require("./commands/statusBarItemMenu");
const installPoshToolsModule_1 = require("./commands/installPoshToolsModule");
const generateTool_1 = require("./commands/generateTool");
const astTreeView_1 = require("./treeView/astTreeView");
const hostProcessView_1 = require("./treeView/hostProcessView");
const moduleTreeView_1 = require("./treeView/moduleTreeView");
const providerTreeView_1 = require("./treeView/providerTreeView");
const quickScriptView_1 = require("./treeView/quickScriptView");
const variableTreeView_1 = require("./treeView/variableTreeView");
const infoTreeView_1 = require("./treeView/infoTreeView");
const help_1 = require("./commands/help");
const reflectionTreeView_1 = require("./treeView/reflectionTreeView");
const customTreeView_1 = require("./treeView/customTreeView");
const historyTreeView_1 = require("./treeView/historyTreeView");
const sessionTreeView_1 = require("./treeView/sessionTreeView");
const jobTreeView_1 = require("./treeView/jobTreeView");
const renameProvider_1 = require("./services/renameProvider");
const welcomeCommand_1 = require("./commands/welcomeCommand");
const newsTreeView_1 = require("./treeView/newsTreeView");
const news_1 = require("./commands/news");
const version = "PowerShellProTools.Version";
var powerShellService;
function activate(context) {
    return __awaiter(this, void 0, void 0, function* () {
        (0, news_1.notifyAboutNews)(context);
        var service = powerShellService = new powershellservice_1.PowerShellService(context);
        context.subscriptions.push((0, showDataGrid_1.showDataGrid)(context));
        context.subscriptions.push((0, packageAsExe_1.packageAsExe)());
        context.subscriptions.push((0, convertToUdElement_1.convertToUdElement)());
        context.subscriptions.push((0, profile_1.profile)());
        context.subscriptions.push((0, profile_1.clearProfiling)());
        context.subscriptions.push((0, formsDesigner_1.showWinFormDesigner)(context));
        context.subscriptions.push((0, generateWinForm_1.generateWinForm)());
        context.subscriptions.push((0, generateTool_1.generateTool)());
        context.subscriptions.push((0, installPoshToolsModule_1.InstallPoshToolsModule)());
        context.subscriptions.push((0, help_1.default)());
        context.subscriptions.push((0, statusBarItemMenu_1.statusBarItemMenu)());
        container_1.Container.initialize(context, powerShellService);
        var extension = vscode.extensions.getExtension("ms-vscode.PowerShell");
        if (!extension) {
            extension = vscode.extensions.getExtension("ms-vscode.PowerShell-Preview");
        }
        if (!extension) {
            vscode.window.showErrorMessage("PowerShell Pro Tools requires the Microsoft PowerShell or PowerShell Preview extension.");
            return;
        }
        const configuration = vscode.workspace.getConfiguration("terminal.integrated");
        var persistentSessions = configuration.get("enablePersistentSessions");
        if (persistentSessions) {
            var result = yield vscode.window.showErrorMessage("PowerShell Pro Tools requires the terminal.integrated.enablePersistentSessions setting to be disabled.", "Disable", "Learn About Persistent Sessions");
            if (result == "Learn About Persistent Sessions") {
                vscode.env.openExternal(vscode.Uri.parse("https://code.visualstudio.com/docs/terminal/advanced#_persistent-sessions"));
            }
            else if (result == "Disable") {
                yield configuration.update("enablePersistentSessions", false, true);
                vscode.window.showInformationMessage("Persistent sessions have been disabled. Please reload the window for the changes to take effect.");
            }
            else {
                vscode.window.showErrorMessage("PowerShell Pro Tools did not start because Persistent Terminal Sessions is enabled.");
                service.setSessionStatus(powershellservice_1.SessionStatus.Disabled);
            }
            return;
        }
        if (!extension.isActive) {
            yield extension.activate();
            const powerShellExtensionClient = extension.exports;
            const id = powerShellExtensionClient.registerExternalExtension(context.extension.id);
            yield powerShellExtensionClient.waitUntilStarted(id);
        }
        yield finishActivation(context);
    });
}
exports.activate = activate;
function finishActivation(context) {
    return __awaiter(this, void 0, void 0, function* () {
        container_1.Container.Log("Finishing extension activation.");
        let terminal = null;
        do {
            terminal = vscode.window.terminals.find(x => x.name.startsWith("PowerShell Extension"));
        } while (!terminal);
        if (terminal == null) {
            throw "PowerShell Extension not found.";
        }
        const powershellProTools = vscode.extensions.getExtension("ironmansoftware.powershellprotools");
        const currentVersion = powershellProTools.packageJSON.version;
        container_1.Container.Log("Connecting to PowerShell Editor Services.");
        powerShellService.Connect(() => {
            container_1.Container.Log("Creating tree views.");
            vscode.window.createTreeView('astView', { treeDataProvider: new astTreeView_1.AstTreeViewProvider() });
            vscode.window.createTreeView('hostProcessView', { treeDataProvider: new hostProcessView_1.HostProcessViewProvider() });
            vscode.window.createTreeView('moduleView', { treeDataProvider: new moduleTreeView_1.ModuleViewProvider() });
            vscode.window.createTreeView('newsView', { treeDataProvider: new newsTreeView_1.NewsViewProvider() });
            vscode.window.createTreeView('providerView', { treeDataProvider: new providerTreeView_1.ProviderViewProvider() });
            vscode.window.createTreeView('quickScriptView', { treeDataProvider: new quickScriptView_1.QuickScriptViewProvider() });
            vscode.window.createTreeView('variableView', { treeDataProvider: new variableTreeView_1.VariableViewProvider() });
            vscode.window.createTreeView('infoView', { treeDataProvider: new infoTreeView_1.InfoViewProvider() });
            vscode.window.createTreeView('reflectionView', { treeDataProvider: new reflectionTreeView_1.ReflectionViewProvider() });
            vscode.window.createTreeView('customView', { treeDataProvider: new customTreeView_1.CustomTreeViewProvider() });
            vscode.window.createTreeView('historyView', { treeDataProvider: new historyTreeView_1.HistoryTreeViewProvider() });
            vscode.window.createTreeView('sessionsView', { treeDataProvider: new sessionTreeView_1.SessionTreeViewProvider() });
            vscode.window.createTreeView('jobView', { treeDataProvider: new jobTreeView_1.JobTreeViewProvider() });
            container_1.Container.Log("Starting code analysis.");
            if (vscode.workspace.workspaceFolders) {
                for (let wsf of vscode.workspace.workspaceFolders) {
                    container_1.Container.PowerShellService.AddWorkspaceFolder(wsf.uri.fsPath);
                }
            }
            vscode.workspace.onDidChangeWorkspaceFolders(e => {
                for (let add of e.added) {
                    container_1.Container.PowerShellService.AddWorkspaceFolder(add.uri.fsPath);
                }
                for (let remove of e.removed) {
                    container_1.Container.PowerShellService.RemoveWorkspaceFolder(remove.uri.fsPath);
                }
            });
            vscode.workspace.onDidSaveTextDocument(x => {
                container_1.Container.PowerShellService.AnalyzeWorkspaceFile(x.uri.fsPath);
            });
            vscode.workspace.onDidCreateFiles(x => {
                container_1.Container.PowerShellService.AnalyzeWorkspaceFile(x.files[0].fsPath);
            });
            vscode.workspace.onDidDeleteFiles(x => {
                container_1.Container.PowerShellService.AnalyzeWorkspaceFile(x.files[0].fsPath);
            });
            vscode.workspace.onDidRenameFiles(x => {
                container_1.Container.PowerShellService.AnalyzeWorkspaceFile(x.files[0].newUri.fsPath);
            });
            container_1.Container.Log("Started PowerShell Pro Tools process.");
            context.globalState.update(version, currentVersion);
            container_1.Container.VSCodeService.init();
            context.subscriptions.push(vscode.languages.registerRenameProvider({ scheme: 'file', language: 'powershell' }, new renameProvider_1.PowerShellRenameProvider()));
            (0, welcomeCommand_1.registerWelcomeCommands)(context);
        });
    });
}
//# sourceMappingURL=extension.js.map