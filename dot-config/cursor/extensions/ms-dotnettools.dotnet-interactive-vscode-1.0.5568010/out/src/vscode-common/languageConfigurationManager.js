"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.LanguageConfigurationManager = void 0;
const vscode = require("vscode");
const constants = require("./constants");
const metadataUtilities = require("./metadataUtilities");
class LanguageConfigurationManager {
    constructor(dynamicTokensProvider) {
        this.dynamicTokensProvider = dynamicTokensProvider;
        this._disposables = [];
        this._lastLanguageConfigurationObject = undefined;
        // whenever a new notebok cell is selected...
        this._disposables.push(vscode.window.onDidChangeActiveTextEditor(textEditor => {
            const document = textEditor === null || textEditor === void 0 ? void 0 : textEditor.document;
            if (document) {
                this.ensureLanguageConfigurationForDocument(document);
            }
        }));
    }
    ensureLanguageConfigurationForDocument(document) {
        const cell = vscode.workspace.notebookDocuments.flatMap(notebook => notebook.getCells()).find(cell => cell.document === document);
        if (cell && metadataUtilities.isDotNetNotebook(cell.notebook)) {
            const notebookCellMetadata = metadataUtilities.getNotebookCellMetadataFromNotebookCellElement(cell);
            if (notebookCellMetadata.kernelName) {
                const languageConfiguration = this.dynamicTokensProvider.getLanguageConfigurationFromKernelNameOrAlias(cell.notebook, notebookCellMetadata.kernelName);
                if (languageConfiguration !== this._lastLanguageConfigurationObject) {
                    this._lastLanguageConfigurationObject = languageConfiguration;
                    const typedLanguageConfiguration = languageConfiguration;
                    vscode.languages.setLanguageConfiguration(constants.CellLanguageIdentifier, typedLanguageConfiguration);
                }
            }
        }
    }
    dispose() {
        for (const disposable of this._disposables) {
            disposable.dispose();
        }
    }
}
exports.LanguageConfigurationManager = LanguageConfigurationManager;
//# sourceMappingURL=languageConfigurationManager.js.map