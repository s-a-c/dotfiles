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
exports.deactivate = exports.activate = void 0;
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require("vscode");
const universal_1 = require("./universal");
const container_1 = require("./container");
const dashboard_treeview_1 = require("./dashboard-treeview");
const info_treeview_1 = require("./info-treeview");
const helpCommand_1 = require("./commands/helpCommand");
const downloadUniversal_1 = require("./commands/downloadUniversal");
const settings_1 = require("./settings");
const dashboards_1 = require("./commands/dashboards");
const api_treeview_1 = require("./api-treeview");
const endpoints_1 = require("./commands/endpoints");
const automation_treeview_1 = require("./automation-treeview");
const scripts_1 = require("./commands/scripts");
const config_1 = require("./commands/config");
const configuration_treeview_1 = require("./configuration-treeview");
const connect_1 = require("./commands/connect");
const samples_1 = require("./samples");
const sample_treeview_1 = require("./sample-treeview");
const connection_treeview_1 = require("./connection-treeview");
const welcomeCommand_1 = require("./commands/welcomeCommand");
const walkthrough_1 = require("./commands/walkthrough");
const terminals_1 = require("./commands/terminals");
const platform_treeview_1 = require("./platform-treeview");
const modules_1 = require("./commands/modules");
const debugger_1 = require("./commands/debugger");
function activate(context) {
    return __awaiter(this, void 0, void 0, function* () {
        connect_1.registerConnectCommands(context);
        const universal = new universal_1.Universal(context);
        container_1.Container.initialize(context, universal);
        let settings = settings_1.load();
        if (settings.appToken === "" && settings.connections.length === 0) {
            vscode.commands.executeCommand('powershell-universal.welcome');
            vscode.window.showInformationMessage("You need to configure the PowerShell Universal extension. If you haven't installed PowerShell Universal, you should download it. If you have PowerShell Universal running, you can connect.", "Download", "Settings").then(result => {
                if (result === "Download") {
                    vscode.env.openExternal(vscode.Uri.parse("https://ironmansoftware.com/downloads"));
                }
                if (result === "Settings") {
                    vscode.commands.executeCommand('workbench.action.openSettings', "PowerShell Universal");
                }
            });
        }
        vscode.window.registerUriHandler({
            handleUri: (uri) => {
                if (uri.path.startsWith('/debug')) {
                    const querystring = require('querystring');
                    const query = querystring.parse(uri.query);
                    container_1.Container.universal.sendTerminalCommand(`if ($PID -ne ${query.PID}) {Enter-PSHostProcess -ID ${query.PID} }`);
                    container_1.Container.universal.sendTerminalCommand(`Debug-Runspace -ID ${query.RS}`);
                }
                if (uri.path.startsWith('/connect')) {
                    var atob = require('atob');
                    const querystring = require('querystring');
                    const query = querystring.parse(uri.query);
                    const url = atob(query.CB);
                    container_1.Container.universal.connectUniversal(url);
                    vscode.commands.executeCommand('powershell-universal.refreshAllTreeViews');
                }
            }
        });
        const connectionProvider = new connection_treeview_1.ConnectionTreeViewProvider(context);
        const moduleProvider = new dashboard_treeview_1.DashboardTreeViewProvider();
        const infoProvider = new info_treeview_1.InfoTreeViewProvider();
        const endpointProvider = new api_treeview_1.ApiTreeViewProvider();
        const scriptProvider = new automation_treeview_1.AutomationTreeViewProvider();
        const configProvider = new configuration_treeview_1.ConfigTreeViewProvider();
        const samplesProvider = new sample_treeview_1.SampleTreeViewProvider();
        const platformProvider = new platform_treeview_1.PlatformTreeViewProvider();
        vscode.window.createTreeView('universalConnectionProviderView', { treeDataProvider: connectionProvider });
        vscode.window.createTreeView('universalDashboardProviderView', { treeDataProvider: moduleProvider });
        vscode.window.createTreeView('universalEndpointProviderView', { treeDataProvider: endpointProvider });
        vscode.window.createTreeView('universalScriptProviderView', { treeDataProvider: scriptProvider });
        vscode.window.createTreeView('universalConfigProviderView', { treeDataProvider: configProvider });
        vscode.window.createTreeView('sampleProviderView', { treeDataProvider: samplesProvider });
        vscode.window.createTreeView('universalInfoProviderView', { treeDataProvider: infoProvider });
        vscode.window.createTreeView('universalPlatformProviderView', { treeDataProvider: platformProvider });
        container_1.Container.ConfigFileTreeView = configProvider;
        vscode.commands.registerCommand('powershell-universal.refreshTreeView', () => moduleProvider.refresh());
        vscode.commands.registerCommand('powershell-universal.refreshEndpointTreeView', () => endpointProvider.refresh());
        vscode.commands.registerCommand('powershell-universal.refreshScriptTreeView', () => scriptProvider.refresh());
        vscode.commands.registerCommand('powershell-universal.refreshConfigurationTreeView', () => configProvider.refresh());
        vscode.commands.registerCommand('powershell-universal.refreshConnectionTreeView', () => connectionProvider.refresh());
        vscode.commands.registerCommand('powershell-universal.refreshPlatformTreeView', () => platformProvider.refresh());
        vscode.commands.registerCommand('powershell-universal.refreshAllTreeViews', () => {
            vscode.commands.executeCommand('powershell-universal.refreshTreeView');
            vscode.commands.executeCommand('powershell-universal.refreshEndpointTreeView');
            vscode.commands.executeCommand('powershell-universal.refreshScriptTreeView');
            vscode.commands.executeCommand('powershell-universal.refreshConfigurationTreeView');
            vscode.commands.executeCommand('powershell-universal.refreshConnectionTreeView');
            vscode.commands.executeCommand('powershell-universal.refreshPlatformTreeView');
        });
        downloadUniversal_1.downloadUniversalCommand();
        helpCommand_1.default();
        dashboards_1.registerDashboardCommands(context);
        endpoints_1.registerEndpointCommands(context);
        scripts_1.registerScriptCommands(context);
        config_1.registerConfigCommands(context);
        samples_1.registerSampleCommands(context);
        welcomeCommand_1.registerWelcomeCommands(context);
        walkthrough_1.registerWalkthroughCommands(context);
        terminals_1.registerTerminalCommands(context);
        modules_1.registerModuleCommands(context);
        debugger_1.registerDebuggerCommands(context);
        yield vscode.commands.executeCommand("powershell-universal.syncSamples");
        if (container_1.Container.universal.hasConnection()) {
            if (yield container_1.Container.universal.waitForAlive()) {
                yield container_1.Container.universal.installAndLoadModule();
            }
        }
    });
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map