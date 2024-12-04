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
exports.registerNotbookCellStatusBarItemProvider = void 0;
const vscode = require("vscode");
const commandsAndEvents = require("./polyglot-notebooks/commandsAndEvents");
const metadataUtilities = require("./metadataUtilities");
const vscodeNotebookManagement = require("./vscodeNotebookManagement");
const polyglot_notebooks_1 = require("./polyglot-notebooks");
const kernelSelectorUtilities = require("./kernelSelectorUtilities");
const constants = require("./constants");
const vscodeUtilities = require("./vscodeUtilities");
const serviceCollection_1 = require("./serviceCollection");
const selectKernelCommandName = 'polyglot-notebook.selectCellKernel';
class KernelSelectorItem {
    constructor(label) {
        this.label = label;
    }
}
function registerNotbookCellStatusBarItemProvider(context, clientMapper) {
    const cellItemProvider = new DotNetNotebookCellStatusBarItemProvider(clientMapper);
    clientMapper.onClientCreate((_uri, client) => {
        client.channel.receiver.subscribe({
            next: envelope => {
                if ((0, polyglot_notebooks_1.isKernelEventEnvelope)(envelope) && envelope.eventType === commandsAndEvents.KernelInfoProducedType) {
                    cellItemProvider.updateKernelDisplayNames();
                }
            }
        });
    });
    context.subscriptions.push(vscode.notebooks.registerNotebookCellStatusBarItemProvider(constants.NotebookViewType, cellItemProvider));
    context.subscriptions.push(vscode.notebooks.registerNotebookCellStatusBarItemProvider(constants.JupyterViewType, cellItemProvider));
    context.subscriptions.push(vscode.commands.registerCommand(selectKernelCommandName, (cell) => __awaiter(this, void 0, void 0, function* () {
        if (cell) {
            const client = yield clientMapper.tryGetClient(cell.notebook.uri);
            if (client) {
                const kernelSelectorOptions = kernelSelectorUtilities
                    .getKernelSelectorOptions(client.kernel, cell.notebook, commandsAndEvents.SubmitCodeType);
                const kernelSelectorItems = kernelSelectorOptions
                    .map(o => {
                    const item = new KernelSelectorItem(o.displayValue);
                    item.description = o.description;
                    item.iconPath = new vscode.ThemeIcon('notebook-kernel-select');
                    return item;
                });
                const selectedDisplayOption = yield vscode.window.showQuickPick(kernelSelectorItems, { title: 'Select cell kernel' });
                if (selectedDisplayOption) {
                    const selectedValueIndex = kernelSelectorItems.indexOf(selectedDisplayOption);
                    if (selectedValueIndex >= 0) {
                        const selectedKernelItem = kernelSelectorOptions[selectedValueIndex];
                        const codeCell = yield vscodeUtilities.ensureCellKernelKind(cell, vscode.NotebookCellKind.Code);
                        const notebookCellMetadata = metadataUtilities.getNotebookCellMetadataFromNotebookCellElement(cell);
                        if (notebookCellMetadata.kernelName !== selectedKernelItem.kernelName) {
                            // update metadata
                            notebookCellMetadata.kernelName = selectedKernelItem.kernelName;
                            const newRawMetadata = metadataUtilities.getRawNotebookCellMetadataFromNotebookCellMetadata(notebookCellMetadata);
                            const mergedMetadata = metadataUtilities.mergeRawMetadata(cell.metadata, newRawMetadata);
                            const _succeeded = yield vscodeNotebookManagement.replaceNotebookCellMetadata(codeCell.notebook.uri, codeCell.index, mergedMetadata);
                            // update language configuration
                            serviceCollection_1.ServiceCollection.Instance.LanguageConfigurationManager.ensureLanguageConfigurationForDocument(cell.document);
                            // update tokens
                            yield vscode.commands.executeCommand('polyglot-notebook.refreshSemanticTokens');
                        }
                    }
                }
            }
        }
    })));
}
exports.registerNotbookCellStatusBarItemProvider = registerNotbookCellStatusBarItemProvider;
function getNotebookDcoumentFromCellDocument(cellDocument) {
    const notebookDocument = vscode.workspace.notebookDocuments.find(notebook => notebook.getCells().some(cell => cell.document === cellDocument));
    return notebookDocument;
}
class DotNetNotebookCellStatusBarItemProvider {
    constructor(clientMapper) {
        this.clientMapper = clientMapper;
        this._onDidChangeCellStatusBarItemsEmitter = new vscode.EventEmitter();
        this.onDidChangeCellStatusBarItems = this._onDidChangeCellStatusBarItemsEmitter.event;
    }
    provideCellStatusBarItems(cell, token) {
        var _a;
        return __awaiter(this, void 0, void 0, function* () {
            if (!metadataUtilities.isDotNetNotebook(cell.notebook) || cell.document.languageId === 'markdown') {
                return [];
            }
            const notebookMetadata = metadataUtilities.getNotebookDocumentMetadataFromNotebookDocument(cell.notebook);
            const cellMetadata = metadataUtilities.getNotebookCellMetadataFromNotebookCellElement(cell);
            const cellKernelName = (_a = cellMetadata.kernelName) !== null && _a !== void 0 ? _a : notebookMetadata.kernelInfo.defaultKernelName;
            const notebookDocument = getNotebookDcoumentFromCellDocument(cell.document);
            const client = yield this.clientMapper.tryGetClient(notebookDocument.uri); // don't force client creation
            let displayText;
            if (client) {
                const matchingKernel = client.kernel.childKernels.find(k => k.kernelInfo.localName === cellKernelName);
                displayText = matchingKernel ? kernelSelectorUtilities.getKernelInfoDisplayValue(matchingKernel.kernelInfo) : cellKernelName;
            }
            else {
                displayText = cellKernelName;
            }
            const item = new vscode.NotebookCellStatusBarItem(displayText, vscode.NotebookCellStatusBarAlignment.Right);
            item.command = selectKernelCommandName;
            item.tooltip = "Select cell kernel";
            return [item];
        });
    }
    updateKernelDisplayNames() {
        this._onDidChangeCellStatusBarItemsEmitter.fire();
    }
}
//# sourceMappingURL=notebookCellStatusBarItemProvider.js.map