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
exports.NotebookWatcherService = void 0;
const vscode = require("vscode");
const polyglot_notebooks_1 = require("./polyglot-notebooks");
class NotebookWatcherService {
    constructor(context, clientMapper) {
        this.notebookOpenDelegates = [];
        this.notebookCloseDelegates = [];
        context.subscriptions.push(vscode.workspace.onDidCloseNotebookDocument((notebook) => __awaiter(this, void 0, void 0, function* () {
            const client = yield clientMapper.tryGetClient(notebook.uri);
            if (client) {
                // if one of ours...
                this.notebookDocumentClosed(notebook, client);
            }
        })));
        clientMapper.onClientCreate((uri, client) => {
            const notebooks = vscode.workspace.notebookDocuments.filter(n => n.uri.fsPath === uri.fsPath);
            if (notebooks.length === 1) {
                const notebook = notebooks[0];
                this.notebookDocumentOpened(notebook, client);
            }
            else {
                polyglot_notebooks_1.Logger.default.error(`Unable to find single notebook for URI ${uri.toString()}`);
            }
        });
    }
    onNotebookDocumentOpened(callback) {
        this.notebookOpenDelegates.push(callback);
        return {
            dispose: () => {
                this.notebookOpenDelegates = this.notebookOpenDelegates.filter(d => d !== callback);
            }
        };
    }
    onNotebookDocumentClosed(callback) {
        this.notebookCloseDelegates.push(callback);
        return {
            dispose: () => {
                this.notebookCloseDelegates = this.notebookCloseDelegates.filter(d => d !== callback);
            }
        };
    }
    notebookDocumentOpened(notebook, client) {
        for (const callback of this.notebookOpenDelegates) {
            try {
                callback(notebook, client);
            }
            catch (e) {
                polyglot_notebooks_1.Logger.default.error(`Error calling notebook open delegate for ${notebook.uri.toString()}: ${e}`);
            }
        }
    }
    notebookDocumentClosed(notebook, client) {
        for (const callback of this.notebookCloseDelegates) {
            try {
                callback(notebook, client);
            }
            catch (e) {
                polyglot_notebooks_1.Logger.default.error(`Error calling notebook close delegate for ${notebook.uri.toString()}: ${e}`);
            }
        }
    }
    dispose() {
    }
}
exports.NotebookWatcherService = NotebookWatcherService;
//# sourceMappingURL=notebookWatcherService.js.map