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
exports.KernelInfoUpdaterService = void 0;
const vscode = require("vscode");
const connection = require("./polyglot-notebooks/connection");
class KernelInfoUpdaterService {
    constructor(clientMapper) {
        this.clientMapper = clientMapper;
        this._callbacks = [];
        this._compositeKernelToNotebookUri = new Map();
        clientMapper.onClientCreate((uri, client) => {
            this._compositeKernelToNotebookUri.set(client.kernel, uri);
        });
        connection.registerForKernelInfoUpdates((compositeKernel) => __awaiter(this, void 0, void 0, function* () {
            const notebookUri = this._compositeKernelToNotebookUri.get(compositeKernel);
            if (notebookUri) {
                const notebookDocument = vscode.workspace.notebookDocuments.find(document => document.uri.fsPath === notebookUri.fsPath);
                if (notebookDocument) {
                    const client = yield this.clientMapper.getOrAddClient(notebookDocument.uri);
                    this.notifyOfKernelInfoUpdates(notebookDocument, client);
                }
            }
        }));
    }
    notifyOfKernelInfoUpdates(notebook, client) {
        for (const callback of this._callbacks) {
            try {
                callback(notebook, client);
            }
            catch (_a) {
                // don't care
            }
        }
    }
    onKernelInfoUpdated(callback) {
        this._callbacks.push(callback);
        return {
            dispose: () => {
                this._callbacks = this._callbacks.filter(d => d !== callback);
            }
        };
    }
}
exports.KernelInfoUpdaterService = KernelInfoUpdaterService;
//# sourceMappingURL=kernelInfoUpdaterService.js.map