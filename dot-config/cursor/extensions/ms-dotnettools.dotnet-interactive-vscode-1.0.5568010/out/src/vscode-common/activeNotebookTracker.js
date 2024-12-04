"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ActiveNotebookTracker = void 0;
const serviceCollection_1 = require("./serviceCollection");
const diagnostics = require("./diagnostics");
class ActiveNotebookTracker {
    constructor(clientMapper) {
        this.clientMapper = clientMapper;
        this.activeClients = new Map();
        serviceCollection_1.ServiceCollection.Instance.NotebookWatcher.onNotebookDocumentOpened((notebook, client) => this.notebookDocumentOpened(notebook, client));
        serviceCollection_1.ServiceCollection.Instance.NotebookWatcher.onNotebookDocumentClosed((notebook, client) => this.notebookDocumentClosed(notebook, client));
    }
    notebookDocumentOpened(notebook, client) {
        this.activeClients.set(notebook.uri, client);
    }
    notebookDocumentClosed(notebook, client) {
        this.activeClients.delete(notebook.uri);
        this.clientMapper.closeClient(notebook.uri, true);
        for (const cell of notebook.getCells()) {
            diagnostics.getDiagnosticCollection(cell.document.uri).set(cell.document.uri, undefined);
        }
    }
    dispose() {
        this.activeClients.forEach(client => client.dispose());
        this.activeClients.clear();
    }
}
exports.ActiveNotebookTracker = ActiveNotebookTracker;
//# sourceMappingURL=activeNotebookTracker.js.map