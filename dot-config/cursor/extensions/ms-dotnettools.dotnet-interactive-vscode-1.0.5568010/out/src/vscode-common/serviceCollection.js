"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.ServiceCollection = void 0;
const kernelInfoUpdaterService_1 = require("./kernelInfoUpdaterService");
const languageConfigurationManager_1 = require("./languageConfigurationManager");
const notebookWatcherService_1 = require("./notebookWatcherService");
class ServiceCollection {
    constructor(context, clientMapper, dynamicTokensProvider) {
        this.kernelInfoUpdaterService = new kernelInfoUpdaterService_1.KernelInfoUpdaterService(clientMapper);
        this.languageConfigurationManager = new languageConfigurationManager_1.LanguageConfigurationManager(dynamicTokensProvider);
        this.notebookWatcherService = new notebookWatcherService_1.NotebookWatcherService(context, clientMapper);
        context.subscriptions.push(this);
    }
    static get Instance() {
        if (!ServiceCollection._instance) {
            throw new Error('ServiceCollection not yet initialized');
        }
        return ServiceCollection._instance;
    }
    get KernelInfoUpdaterService() {
        return this.kernelInfoUpdaterService;
    }
    get LanguageConfigurationManager() {
        return this.languageConfigurationManager;
    }
    get NotebookWatcher() {
        return this.notebookWatcherService;
    }
    static initialize(context, clientMapper, dynamicTokensProvider) {
        ServiceCollection._instance = new ServiceCollection(context, clientMapper, dynamicTokensProvider);
    }
    dispose() {
        this.languageConfigurationManager.dispose();
        this.notebookWatcherService.dispose();
    }
}
exports.ServiceCollection = ServiceCollection;
//# sourceMappingURL=serviceCollection.js.map