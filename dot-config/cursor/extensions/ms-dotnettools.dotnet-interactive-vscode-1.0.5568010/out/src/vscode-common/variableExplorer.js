"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
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
exports.registerVariableExplorer = void 0;
const path = require("path");
const vscode = require("vscode");
const commandsAndEvents = require("./polyglot-notebooks/commandsAndEvents");
const connection = require("./polyglot-notebooks/connection");
const utilities = require("./utilities");
const vscodeNotebookManagement = require("./vscodeNotebookManagement");
const polyglot_notebooks_1 = require("./polyglot-notebooks");
const kernelSelectorUtilities = require("./kernelSelectorUtilities");
function debounce(callback) {
    utilities.debounce('variable-explorer', 500, callback);
}
function registerVariableExplorer(context, clientMapper) {
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.shareValueWith', (variableInfo) => __awaiter(this, void 0, void 0, function* () {
        const activeNotebookEditor = vscode.window.activeNotebookEditor;
        if (variableInfo && activeNotebookEditor) {
            const notebookDocument = vscodeNotebookManagement.getNotebookDocumentFromEditor(activeNotebookEditor);
            const client = yield clientMapper.tryGetClient(notebookDocument.uri);
            if (client) {
                const kernelSelectorOptions = kernelSelectorUtilities.getKernelSelectorOptions(client.kernel, notebookDocument, commandsAndEvents.SendValueType);
                const kernelDisplayValues = kernelSelectorOptions.map(k => k.displayValue);
                const selectedKernelDisplayName = yield vscode.window.showQuickPick(kernelDisplayValues, { title: `Share value [${variableInfo.valueName}] from [${variableInfo.sourceKernelName}] to ...` });
                if (selectedKernelDisplayName) {
                    const targetKernelIndex = kernelDisplayValues.indexOf(selectedKernelDisplayName);
                    if (targetKernelIndex >= 0) {
                        const targetKernelSelectorOption = kernelSelectorOptions[targetKernelIndex];
                        // ends with newline to make adding code easier
                        const code = `#!set --value @${variableInfo.sourceKernelName}:${variableInfo.valueName} --name ${variableInfo.valueName}\n`;
                        const command = {
                            kernelName: targetKernelSelectorOption.kernelName,
                            code,
                        };
                        const commandEnvelope = new commandsAndEvents.KernelCommandEnvelope(commandsAndEvents.SendEditableCodeType, command);
                        yield client.kernel.rootKernel.send(commandEnvelope);
                    }
                }
            }
        }
    })));
    const webViewProvider = new WatchWindowTableViewProvider(clientMapper, context.extensionPath);
    context.subscriptions.push(vscode.window.registerWebviewViewProvider('polyglot-notebook-panel-values', webViewProvider, { webviewOptions: { retainContextWhenHidden: true } }));
    vscode.window.onDidChangeActiveNotebookEditor((editor) => __awaiter(this, void 0, void 0, function* () {
        const notebookUri = editor === null || editor === void 0 ? void 0 : editor.notebook.uri;
        debounce(() => webViewProvider.showNotebookVariables(notebookUri));
    }));
}
exports.registerVariableExplorer = registerVariableExplorer;
class WatchWindowTableViewProvider {
    constructor(clientMapper, extensionPath) {
        this.clientMapper = clientMapper;
        this.extensionPath = extensionPath;
        this.webview = undefined;
        this.clientMessageSubscriptions = new Map();
        this.notebookVariables = new Map();
        this.completedNotebookKernels = new Map();
        // on every new notebook, track it's completion events
        clientMapper.onClientCreate((uri, client) => {
            const subscription = client.channel.receiver.subscribe({
                next: (envelope) => {
                    var _a, _b, _c, _d, _e;
                    if ((0, polyglot_notebooks_1.isKernelEventEnvelope)(envelope)) {
                        switch (envelope.eventType) {
                            case commandsAndEvents.CommandSucceededType:
                            case commandsAndEvents.CommandFailedType:
                                if (((_a = envelope.command) === null || _a === void 0 ? void 0 : _a.commandType) === commandsAndEvents.SubmitCodeType
                                    || ((_b = envelope.command) === null || _b === void 0 ? void 0 : _b.commandType) === commandsAndEvents.SendValueType) {
                                    const completedKernels = (_c = this.completedNotebookKernels.get(uri)) !== null && _c !== void 0 ? _c : new Set();
                                    const kernelName = (_e = (_d = envelope.command) === null || _d === void 0 ? void 0 : _d.command) === null || _e === void 0 ? void 0 : _e.targetKernelName;
                                    if (kernelName) {
                                        completedKernels.add(kernelName);
                                    }
                                    const uris = envelope.routingSlip.toArray();
                                    if (uris.length > 0) {
                                        const kernelUri = uris[0];
                                        let kernel = client.kernel.findKernelByUri(kernelUri);
                                        if (kernel) {
                                            completedKernels.add(kernel.name);
                                        }
                                    }
                                    this.completedNotebookKernels.set(uri, completedKernels);
                                    debounce(() => {
                                        this.refreshVariables(uri).then(() => {
                                            var _a;
                                            this.showNotebookVariables((_a = vscode.window.activeNotebookEditor) === null || _a === void 0 ? void 0 : _a.notebook.uri);
                                        });
                                    });
                                }
                                break;
                        }
                    }
                }
            });
            this.clientMessageSubscriptions.set(uri, {
                dispose: () => {
                    subscription.unsubscribe();
                    this.completedNotebookKernels.delete(uri);
                    this.notebookVariables.delete(uri);
                }
            });
        });
        // when the notebook is closed, stop tracking it's completion events
        clientMapper.onClientDispose((uri, _client) => {
            const disposable = this.clientMessageSubscriptions.get(uri);
            if (disposable) {
                disposable.dispose();
            }
        });
    }
    resolveWebviewView(webviewView, context, token) {
        var _a;
        return __awaiter(this, void 0, void 0, function* () {
            this.webview = webviewView.webview;
            webviewView.webview.options = {
                enableScripts: true,
                enableCommandUris: true,
            };
            this.webview.onDidReceiveMessage(message => {
                const x = message;
                if (message.command === 'shareValueWith') {
                    vscode.commands.executeCommand('polyglot-notebook.shareValueWith', message.variableInfo);
                }
            });
            const jsFileUri = this.webview.asWebviewUri(vscode.Uri.file(path.join(this.extensionPath, 'resources', 'variable-grid.bundle.js')));
            const htmlFileUri = vscode.Uri.file(path.join(this.extensionPath, 'resources', 'index.variable-grid.html'));
            const decoder = new TextDecoder();
            let rawhtmlContent = yield vscode.workspace.fs.readFile(htmlFileUri);
            let htmlContent = decoder.decode(rawhtmlContent);
            htmlContent = htmlContent.replace("variable-grid.bundle.js", jsFileUri.toString());
            this.webview.html = htmlContent;
            const currentNotebookUri = (_a = vscode.window.activeNotebookEditor) === null || _a === void 0 ? void 0 : _a.notebook.uri;
            this.showNotebookVariables(currentNotebookUri);
        });
    }
    setRows(rows) {
        if (this.webview) {
            const localizationStrings = {
                actionsColumnHeader: this.translate('VariableGridColumnActions', 'Actions'),
                nameColumnHeader: this.translate('VariableGridColumnName', 'Name'),
                valueColumnHeader: this.translate('VariableGridColumnValue', 'Value'),
                typeColumnHeader: this.translate('VariableGridColumnType', 'Type'),
                kernelNameColumnHeader: this.translate('VariableGridColumnKernel', 'Kernel'),
                shareTemplate: this.translate('VariableGridshareTemplate', 'Share value "{value-name}" from kernel "{kernel-name}"'),
                gridCaption: this.translate('VariableGridCaption', 'Polyglot Notebook variables')
            };
            const jsonRows = JSON.parse(connection.Serialize(rows));
            this.webview.postMessage({
                command: 'set-rows',
                rows: jsonRows,
                localizationStrings: localizationStrings
            });
        }
    }
    translate(key, fallback) {
        const translation = vscode.l10n.t(key);
        return translation === key ? fallback : translation;
    }
    showNotebookVariables(notebookUri) {
        let rows = [];
        if (notebookUri) {
            const cachedRows = this.notebookVariables.get(notebookUri);
            rows = cachedRows !== null && cachedRows !== void 0 ? cachedRows : [];
        }
        this.setRows(rows);
    }
    refreshVariables(uri) {
        return __awaiter(this, void 0, void 0, function* () {
            const rows = [];
            const client = yield this.clientMapper.tryGetClient(uri);
            if (client) {
                const allKernels = Array.from(client.kernel.childKernels.filter(k => k.kernelInfo.supportedKernelCommands.find(ci => ci.name === commandsAndEvents.RequestValueInfosType)));
                const kernels = allKernels.filter(kernel => {
                    var _a, _b;
                    return (_b = (_a = this.completedNotebookKernels.get(uri)) === null || _a === void 0 ? void 0 : _a.has(kernel.name)) !== null && _b !== void 0 ? _b : false;
                });
                for (const kernel of kernels) {
                    try {
                        const valueInfos = yield client.requestValueInfos(kernel.name);
                        for (const valueInfo of valueInfos.valueInfos) {
                            try {
                                const valueName = valueInfo.name;
                                const valueValue = valueInfo.formattedValue.value;
                                const typeName = valueInfo.typeName;
                                const displayName = kernelSelectorUtilities.getKernelInfoDisplayValue(kernel.kernelInfo);
                                rows.push({
                                    name: valueName,
                                    value: valueValue,
                                    typeName: typeName,
                                    kernelDisplayName: displayName,
                                    kernelName: kernel.name
                                });
                            }
                            catch (e) {
                                // likely didn't support `RequestValue`
                                const x = e;
                            }
                        }
                    }
                    catch (e) {
                        // likely didn't support `RequestValueInfos`
                        const x = e;
                    }
                }
            }
            this.notebookVariables.set(uri, rows);
        });
    }
}
//# sourceMappingURL=variableExplorer.js.map