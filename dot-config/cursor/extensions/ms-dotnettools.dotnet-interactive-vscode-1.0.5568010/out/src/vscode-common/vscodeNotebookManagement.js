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
exports.hashBangConnect = exports.handleCustomInputRequest = exports.replaceNotebookMetadata = exports.replaceNotebookCellMetadata = exports.replaceNotebookCells = exports.getNotebookDocumentFromEditor = void 0;
const vscode = require("vscode");
const logger_1 = require("./polyglot-notebooks/logger");
const polyglot_notebooks_1 = require("./polyglot-notebooks");
const rxjs = require("rxjs");
const connection = require("./polyglot-notebooks/connection");
const commandsAndEvents = require("./polyglot-notebooks/commandsAndEvents");
const metadataUtilities_1 = require("./metadataUtilities");
function getNotebookDocumentFromEditor(notebookEditor) {
    return notebookEditor.notebook;
}
exports.getNotebookDocumentFromEditor = getNotebookDocumentFromEditor;
function replaceNotebookCells(notebookUri, range, cells) {
    return __awaiter(this, void 0, void 0, function* () {
        const notebookEdit = vscode.NotebookEdit.replaceCells(range, cells);
        const edit = new vscode.WorkspaceEdit();
        edit.set(notebookUri, [notebookEdit]);
        const succeeded = yield vscode.workspace.applyEdit(edit);
        return succeeded;
    });
}
exports.replaceNotebookCells = replaceNotebookCells;
function replaceNotebookCellMetadata(notebookUri, cellIndex, newCellMetadata) {
    return __awaiter(this, void 0, void 0, function* () {
        const notebookEdit = vscode.NotebookEdit.updateCellMetadata(cellIndex, newCellMetadata);
        const edit = new vscode.WorkspaceEdit();
        edit.set(notebookUri, [notebookEdit]);
        const succeeded = yield vscode.workspace.applyEdit(edit);
        return succeeded;
    });
}
exports.replaceNotebookCellMetadata = replaceNotebookCellMetadata;
function replaceNotebookMetadata(notebookUri, documentMetadata) {
    return __awaiter(this, void 0, void 0, function* () {
        const notebook = vscode.workspace.notebookDocuments.find(d => d.uri === notebookUri);
        if (notebook) {
            const metadata = notebook.metadata;
            const keysToIngore = new Set();
            if (!(0, metadataUtilities_1.isIpynbNotebook)(notebook)) {
                // dib format doesn't use the proeprty 'custom' so this should not be involved in the diff.
                keysToIngore.add("custom");
            }
            const shouldUpdate = !(0, metadataUtilities_1.areEquivalentObjects)(metadata, documentMetadata, keysToIngore);
            if (shouldUpdate) {
                const notebookEdit = vscode.NotebookEdit.updateNotebookMetadata(documentMetadata);
                const edit = new vscode.WorkspaceEdit();
                edit.set(notebookUri, [notebookEdit]);
                const succeeded = yield vscode.workspace.applyEdit(edit);
                return succeeded;
            }
            return false;
        }
        return false;
    });
}
exports.replaceNotebookMetadata = replaceNotebookMetadata;
function handleCustomInputRequest(prompt, inputTypeHint, password) {
    return __awaiter(this, void 0, void 0, function* () {
        return { handled: false, result: undefined };
    });
}
exports.handleCustomInputRequest = handleCustomInputRequest;
function hashBangConnect(clientMapper, hostUri, kernelInfos, messageHandlerMap, controllerPostMessage, documentUri) {
    logger_1.Logger.default.info(`handling #!connect for ${documentUri.toString()}`);
    hashBangConnectPrivate(clientMapper, hostUri, kernelInfos, messageHandlerMap, controllerPostMessage, documentUri);
}
exports.hashBangConnect = hashBangConnect;
function hashBangConnectPrivate(clientMapper, hostUri, kernelInfos, messageHandlerMap, controllerPostMessage, documentUri) {
    logger_1.Logger.default.info(`handling #!connect from '${hostUri}' for notebook: ${documentUri.toString()}`);
    const documentUriString = documentUri.toString();
    clientMapper.getOrAddClient(documentUri).then(client => {
        let messageHandler = messageHandlerMap.get(documentUriString);
        if (!messageHandler) {
            messageHandler = new rxjs.Subject();
            messageHandlerMap.set(documentUriString, messageHandler);
        }
        let extensionHostToWebviewSender = polyglot_notebooks_1.KernelCommandAndEventSender.FromFunction(envelope => {
            const commandOrEventForWebview = { envelope: envelope.toJson() };
            controllerPostMessage(commandOrEventForWebview);
        });
        let WebviewToExtensionHostReceiver = polyglot_notebooks_1.KernelCommandAndEventReceiver.FromObservable(messageHandler);
        logger_1.Logger.default.info(`configuring routing for host '${hostUri}'`);
        let subscriptionToExtensionHost = client.channel.receiver.subscribe({
            next: envelope => {
                if ((0, polyglot_notebooks_1.isKernelEventEnvelope)(envelope)) {
                    logger_1.Logger.default.info(`forwarding event to '${hostUri}' ${JSON.stringify(envelope.toJson())}`);
                    extensionHostToWebviewSender.send(envelope);
                }
            }
        });
        let subscriptionToWebView = WebviewToExtensionHostReceiver.subscribe({
            next: envelope => {
                var _a, _b, _c;
                if ((0, polyglot_notebooks_1.isKernelCommandEnvelope)(envelope)) {
                    // handle command routing
                    if (envelope.command.destinationUri) {
                        if (envelope.command.destinationUri.startsWith("kernel://vscode")) {
                            // wants to go to vscode
                            logger_1.Logger.default.info(`routing command from '${hostUri}' ${JSON.stringify(envelope)} to extension host`);
                            const kernel = client.kernelHost.getKernel(envelope);
                            kernel.send(envelope);
                        }
                        else {
                            const host = (0, polyglot_notebooks_1.extractHostAndNomalize)(envelope.command.destinationUri);
                            const connector = client.kernelHost.tryGetConnector(host);
                            if (connector) {
                                // route to interactive
                                logger_1.Logger.default.info(`routing command from '${hostUri}' ${JSON.stringify(envelope)} to '${host}'`);
                                connector.sender.send(envelope);
                            }
                            else {
                                logger_1.Logger.default.error(`cannot find connector to reach${envelope.command.destinationUri}`);
                            }
                        }
                    }
                    else {
                        const kernel = client.kernelHost.getKernel(envelope);
                        kernel.send(envelope);
                    }
                }
                if ((0, polyglot_notebooks_1.isKernelEventEnvelope)(envelope)) {
                    if (envelope.eventType === commandsAndEvents.KernelInfoProducedType) {
                        const kernelInfoProduced = envelope.event;
                        if (!connection.isKernelInfoForProxy(kernelInfoProduced.kernelInfo)) {
                            connection.ensureOrUpdateProxyForKernelInfo(kernelInfoProduced.kernelInfo, client.kernel);
                        }
                    }
                    if ((_a = envelope.command) === null || _a === void 0 ? void 0 : _a.command.originUri) {
                        const host = (0, polyglot_notebooks_1.extractHostAndNomalize)((_b = envelope.command) === null || _b === void 0 ? void 0 : _b.command.originUri);
                        const connector = client.kernelHost.tryGetConnector(host);
                        if (connector) {
                            // route to interactive
                            logger_1.Logger.default.info(`routing event from webview ${JSON.stringify(envelope)} to host ${host}`);
                            connector.sender.send(envelope);
                        }
                        else {
                            logger_1.Logger.default.error(`cannot find connector to reach ${(_c = envelope.command) === null || _c === void 0 ? void 0 : _c.command.originUri}`);
                        }
                    }
                }
            }
        });
        client.kernelHost.tryAddConnector({
            sender: extensionHostToWebviewSender,
            receiver: WebviewToExtensionHostReceiver,
            remoteUris: ["kernel://webview"]
        });
        client.registerForDisposal(() => {
            messageHandlerMap.delete(documentUriString);
            client.kernelHost.tryRemoveConnector({ remoteUris: ["kernel://webview"] });
            subscriptionToExtensionHost.unsubscribe();
            subscriptionToWebView.unsubscribe();
        });
        for (const kernelInfo of kernelInfos) {
            const remoteUri = kernelInfo.isProxy ? kernelInfo.remoteUri : kernelInfo.uri;
            if (!client.kernelHost.tryGetConnector(remoteUri)) {
                client.kernelHost.defaultConnector.addRemoteHostUri(remoteUri);
            }
            connection.ensureOrUpdateProxyForKernelInfo(kernelInfo, client.kernel);
        }
    });
}
//# sourceMappingURL=vscodeNotebookManagement.js.map