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
exports.UniversalDebugAdapter = exports.attachRunspace = exports.registerDebuggerCommands = void 0;
const vscode = require("vscode");
const settings_1 = require("../settings");
// @ts-ignore
const signalr_1 = require("@microsoft/signalr");
let adapter;
exports.registerDebuggerCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.attachRunspace', (item) => exports.attachRunspace(item, context));
    adapter = new UniversalDebugAdapter(context);
    vscode.debug.registerDebugAdapterDescriptorFactory('powershelluniversal', {
        createDebugAdapterDescriptor: (_session) => {
            return new vscode.DebugAdapterInlineImplementation(adapter);
        }
    });
};
exports.attachRunspace = (runspace, context) => __awaiter(void 0, void 0, void 0, function* () {
    adapter.startSession();
    yield vscode.debug.startDebugging(undefined, {
        name: "PowerShell Universal",
        type: "powershelluniversal",
        request: "attach",
        processId: runspace.runspace.processId,
        runspaceId: runspace.runspace.id
    });
});
class UniversalDebugAdapter {
    constructor(context) {
        this.sendMessage = new vscode.EventEmitter();
        this.onDidSendMessage = this.sendMessage.event;
        this.connectionName = context.globalState.get("universal.connection");
    }
    startSession() {
        const settings = settings_1.load();
        var appToken = settings.appToken;
        var url = settings.url;
        var rejectUnauthorized = true;
        var windowsAuth = false;
        if (this.connectionName && this.connectionName !== 'Default') {
            const connection = settings.connections.find(m => m.name === this.connectionName);
            if (connection) {
                appToken = connection.appToken;
                url = connection.url;
                rejectUnauthorized = !connection.allowInvalidCertificate;
            }
        }
        this.hubConnection = new signalr_1.HubConnectionBuilder()
            .withUrl(`${url}/debuggerhub`, { accessTokenFactory: () => appToken })
            .configureLogging(signalr_1.LogLevel.Information)
            .build();
        this.hubConnection.on("message", (message) => {
            const protocolMessage = JSON.parse(message);
            this.handleMessage(protocolMessage);
        });
        this.hubConnection.onclose(() => {
            vscode.window.showInformationMessage("Disconnected from PowerShell Universal Debugger.");
        });
    }
    handleMessage(message) {
        var _a, _b;
        if (((_a = this.hubConnection) === null || _a === void 0 ? void 0 : _a.state) === 'Disconnected') {
            this.hubConnection.start().then(() => {
                this.handleMessage(message);
            });
            return;
        }
        switch (message.type) {
            case 'request':
                (_b = this.hubConnection) === null || _b === void 0 ? void 0 : _b.send("message", JSON.stringify(message));
                break;
            case 'response':
                this.sendMessage.fire(message);
                break;
            case 'event':
                this.sendMessage.fire(message);
                break;
        }
    }
    dispose() {
        var _a;
        (_a = this.hubConnection) === null || _a === void 0 ? void 0 : _a.stop();
    }
}
exports.UniversalDebugAdapter = UniversalDebugAdapter;
//# sourceMappingURL=debugger.js.map