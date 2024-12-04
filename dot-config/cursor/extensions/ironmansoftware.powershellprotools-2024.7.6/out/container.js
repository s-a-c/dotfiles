"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Container = void 0;
const vscode = require("vscode");
const ast_1 = require("./commands/ast");
const quickScriptService_1 = require("./services/quickScriptService");
const quickScripts_1 = require("./commands/quickScripts");
const variables_1 = require("./commands/variables");
const vscodeService_1 = require("./services/vscodeService");
const rapidsense_1 = require("./services/rapidsense");
const providers_1 = require("./commands/providers");
const debugging_1 = require("./commands/debugging");
const refactoring_1 = require("./commands/refactoring");
const hoverProvider_1 = require("./commands/hoverProvider");
const settings_1 = require("./settings");
const signOnSave_1 = require("./commands/signOnSave");
const reflection_1 = require("./commands/reflection");
const customTreeView_1 = require("./commands/customTreeView");
const history_1 = require("./commands/history");
const sessions_1 = require("./commands/sessions");
const jobs_1 = require("./commands/jobs");
const performanceService_1 = require("./services/performanceService");
const news_1 = require("./commands/news");
class Container {
    static initialize(context, powershellService) {
        this._context = context;
        this._service = powershellService;
        this._commands = [];
        this._commands.push(new ast_1.AstCommands());
        this._commands.push(new quickScripts_1.QuickScriptCommands());
        this._commands.push(new variables_1.VariableCommands());
        this._commands.push(new rapidsense_1.RapidSenseCommand());
        this._commands.push(new providers_1.ProviderCommands());
        this._commands.push(new debugging_1.DebuggingCommands());
        this._commands.push(new refactoring_1.RefactoringCommands());
        this._commands.push(new reflection_1.ReflectionCommands());
        this._commands.push(new customTreeView_1.CustomTreeViewCommands());
        this._commands.push(new history_1.HistoryTreeViewCommands());
        this._commands.push(new sessions_1.SessionCommands());
        this._commands.push(new jobs_1.JobTreeViewCommands());
        this._commands.push(new news_1.NewsTreeViewCommands());
        this.RegisterCommands();
        //this._codeLensProvider = new PowerShellCodeLensProvider();
        // let docSelector = {
        // 	language: 'powershell',
        // 	scheme: 'file',
        // }
        // let codeLensProviderDisposable = vscode.languages.registerCodeLensProvider(
        // 	docSelector,
        // 	this._codeLensProvider
        // )
        // context.subscriptions.push(codeLensProviderDisposable)
        this.outputChannel = vscode.window.createOutputChannel("PowerShell Pro Tools");
        this.Log("Starting PowerShell Pro Tools...");
    }
    static FinishInitialize() {
        if (this._initialized) {
            return;
        }
        this._quickScriptService = new quickScriptService_1.QuickScriptService();
        this._quickScriptService.initialize();
        (0, signOnSave_1.signOnSave)();
        this._vscodeService = new vscodeService_1.default();
        this._hoverProvider = new hoverProvider_1.PowerShellHoverProvider();
        this._performanceService = new performanceService_1.PerformanceService(this._context);
        this._initialized = true;
    }
    static get context() {
        return this._context;
    }
    static get performanceService() {
        return this._performanceService;
    }
    static get hoverProvider() {
        return this._hoverProvider;
    }
    static get PowerShellService() {
        return this._service;
    }
    static get QuickScriptService() {
        return this._quickScriptService;
    }
    static RegisterCommands() {
        this._commands.forEach(x => x.register(this._context));
    }
    static get VSCodeService() {
        return this._vscodeService;
    }
    static Log(msg) {
        this.outputChannel.appendLine(`[${this.TimeStamp()}] ${msg}`);
        console.log(`[${this.TimeStamp()}] ${msg}`);
    }
    static TimeStamp() {
        const dateObject = new Date();
        const hours = dateObject.getHours();
        const minutes = dateObject.getMinutes();
        const seconds = dateObject.getSeconds();
        const milliseconds = dateObject.getMilliseconds();
        return `${hours}:${minutes}:${seconds}.${milliseconds}`;
    }
    static FocusLog() {
        this.outputChannel.show();
    }
    static GetSettings() {
        return (0, settings_1.load)();
    }
    static IsInitialized(showWaring = true) {
        if (showWaring && !this._initialized) {
            vscode.window.showWarningMessage("PowerShell Pro Tools is still starting.");
        }
        return this._initialized;
    }
}
exports.Container = Container;
Container._initialized = false;
//# sourceMappingURL=container.js.map