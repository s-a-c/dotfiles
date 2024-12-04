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
exports.selectDotNetInteractiveKernelForJupyter = exports.registerFileCommands = exports.registerKernelCommands = exports.registerAcquisitionCommands = void 0;
const vscode = require("vscode");
const path = require("path");
const acquisition_1 = require("./acquisition");
const vscodeUtilities_1 = require("./vscodeUtilities");
const extension_1 = require("./extension");
const utilities_1 = require("./utilities");
const notebookControllers = require("./notebookControllers");
const metadataUtilities = require("./metadataUtilities");
const vscodeNotebookManagement = require("./vscodeNotebookManagement");
const promiseCompletionSource_1 = require("./polyglot-notebooks/promiseCompletionSource");
const constants = require("./constants");
function registerAcquisitionCommands(context, diagnosticChannel) {
    return __awaiter(this, void 0, void 0, function* () {
        const dotnetConfig = vscode.workspace.getConfiguration(constants.DotnetConfigurationSectionName);
        const requiredDotNetInteractiveVersion = dotnetConfig.get('requiredInteractiveToolVersion');
        const interactiveToolSource = dotnetConfig.get('interactiveToolSource');
        if (!requiredDotNetInteractiveVersion) {
            const errorTitle = 'Polyglot Notebooks extension will not work.';
            const errorDetails = `Incorrect value for option "${constants.DotnetConfigurationSectionName}.requiredInteractiveToolVersion" in settings.json.  Please remove this value and restart VS Code.`;
            yield vscode.window.showErrorMessage(errorTitle, { modal: true, detail: errorDetails });
            throw new Error(errorDetails);
        }
        let cachedInstallArgs = undefined;
        let acquirePromise = undefined;
        context.subscriptions.push(vscode.commands.registerCommand('dotnet-interactive.acquire', (args) => __awaiter(this, void 0, void 0, function* () {
            try {
                const installArgs = (0, utilities_1.computeToolInstallArguments)(args);
                extension_1.DotNetPathManager.setDotNetPath(installArgs.dotnetPath);
                if (cachedInstallArgs) {
                    // todo: ask Brett
                    if (installArgs.dotnetPath !== cachedInstallArgs.dotnetPath ||
                        installArgs.toolVersion !== cachedInstallArgs.toolVersion) {
                        // if specified install args are different than what we previously computed, invalidate the acquisition
                        acquirePromise = undefined;
                    }
                }
                if (!acquirePromise) {
                    const installationPromiseCompletionSource = new promiseCompletionSource_1.PromiseCompletionSource();
                    acquirePromise = (0, acquisition_1.acquireDotnetInteractive)(installArgs, requiredDotNetInteractiveVersion, context.globalStorageUri.fsPath, getInteractiveVersion, createToolManifest, (version) => {
                        vscode.window.withProgress({ location: vscode.ProgressLocation.Notification, title: `Installing .NET Interactive version ${version}...` }, (_progress, _token) => installationPromiseCompletionSource.promise);
                    }, installInteractiveTool, () => { installationPromiseCompletionSource.resolve(); });
                }
                const launchOptions = yield acquirePromise;
                return launchOptions;
            }
            catch (err) {
                diagnosticChannel.appendLine(`Error acquiring dotnet-interactive tool: ${err}`);
            }
        })));
        function createToolManifest(dotnetPath, globalStoragePath) {
            return __awaiter(this, void 0, void 0, function* () {
                const result = yield (0, utilities_1.executeSafeAndLog)(diagnosticChannel, 'create-tool-manifest', dotnetPath, ['new', 'tool-manifest'], globalStoragePath);
                if (result.code !== 0) {
                    throw new Error(`Unable to create local tool manifest.  Command failed with code ${result.code}.\n\nSTDOUT:\n${result.output}\n\nSTDERR:\n${result.error}`);
                }
            });
        }
        function installInteractiveTool(args, globalStoragePath) {
            return __awaiter(this, void 0, void 0, function* () {
                // remove previous tool; swallow errors in case it's not already installed
                let uninstallArgs = [
                    'tool',
                    'uninstall',
                    'Microsoft.dotnet-interactive'
                ];
                yield (0, utilities_1.executeSafeAndLog)(diagnosticChannel, 'tool-uninstall', args.dotnetPath, uninstallArgs, globalStoragePath);
                let toolArgs = [
                    'tool',
                    'install',
                    '--add-source',
                    interactiveToolSource,
                    '--ignore-failed-sources',
                    'Microsoft.dotnet-interactive'
                ];
                if (args.toolVersion) {
                    toolArgs.push('--version', args.toolVersion);
                }
                return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
                    const result = yield (0, utilities_1.executeSafeAndLog)(diagnosticChannel, 'tool-install', args.dotnetPath, toolArgs, globalStoragePath);
                    if (result.code === 0) {
                        resolve();
                    }
                    else {
                        reject();
                    }
                }));
            });
        }
    });
}
exports.registerAcquisitionCommands = registerAcquisitionCommands;
function getCurrentNotebookDocument() {
    if (!vscode.window.activeNotebookEditor) {
        return undefined;
    }
    return vscodeNotebookManagement.getNotebookDocumentFromEditor(vscode.window.activeNotebookEditor);
}
function registerKernelCommands(context, clientMapper) {
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.notebookEditor.restartKernel', (_notebookEditor) => __awaiter(this, void 0, void 0, function* () {
        yield vscode.commands.executeCommand('polyglot-notebook.restartCurrentNotebookKernel');
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.notebookEditor.openValueViewer', () => __awaiter(this, void 0, void 0, function* () {
        // vscode creates a command named `<viewId>.focus` for all contributed views, so we need to match the id
        yield vscode.commands.executeCommand('polyglot-notebook-panel-values.focus');
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.restartCurrentNotebookKernel', (notebook) => __awaiter(this, void 0, void 0, function* () {
        notebook = notebook || getCurrentNotebookDocument();
        if (notebook) {
            // notifty the client that the kernel is about to restart
            const restartCompletionSource = new promiseCompletionSource_1.PromiseCompletionSource();
            vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: 'Restarting kernel...'
            }, (_progress, _token) => restartCompletionSource.promise);
            yield vscode.commands.executeCommand('polyglot-notebook.stopCurrentNotebookKernel', notebook);
            yield vscode.commands.executeCommand('polyglot-notebook.resetNotebookKernelCollection', notebook);
            const _client = yield clientMapper.getOrAddClient(notebook.uri);
            restartCompletionSource.resolve();
            yield vscode.commands.executeCommand('workbench.notebook.layout.webview.reset', notebook.uri);
            vscode.window.showInformationMessage('Kernel restarted.');
        }
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.stopCurrentNotebookKernel', (notebook) => __awaiter(this, void 0, void 0, function* () {
        notebook = notebook || getCurrentNotebookDocument();
        if (notebook) {
            for (const cell of notebook.getCells()) {
                notebookControllers.endExecution(undefined, cell, false);
            }
            const client = yield clientMapper.tryGetClient(notebook.uri);
            if (client) {
                client.resetExecutionCount();
            }
            clientMapper.closeClient(notebook.uri);
        }
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.stopAllNotebookKernels', () => __awaiter(this, void 0, void 0, function* () {
        vscode.workspace.notebookDocuments
            .filter(document => clientMapper.isDotNetClient(document.uri))
            .forEach((document) => __awaiter(this, void 0, void 0, function* () { return yield vscode.commands.executeCommand('polyglot-notebook.stopCurrentNotebookKernel', document); }));
    })));
}
exports.registerKernelCommands = registerKernelCommands;
function registerFileCommands(context, parserServer, clientMapper) {
    const eol = (0, vscodeUtilities_1.getEol)();
    const notebookFileFilters = {
        'Polyglot Notebook Script': ['dib'],
        'Jupyter Notebook': ['ipynb'],
    };
    function newNotebookCommandHandler(preferDefaults) {
        return __awaiter(this, void 0, void 0, function* () {
            const extension = yield getNewNotebookExtension(preferDefaults);
            if (!extension) {
                return;
            }
            const language = yield getNewNotebookLanguage(preferDefaults);
            if (!language) {
                return;
            }
            yield newNotebookWithLanguage(extension, language);
            if (preferDefaults) {
                // if the defaults were even in play, ask the user if they want to save them
                // don't await this, since it's not critical
                promptToSaveDefaults(extension, language);
            }
        });
    }
    function promptToSaveDefaults(extension, language) {
        return __awaiter(this, void 0, void 0, function* () {
            const polyglotConfig = vscode.workspace.getConfiguration(constants.PolyglotConfigurationSectionName);
            // check to see if the user doesn't want to see this
            const suppressPromptToSaveDefaults = polyglotConfig.get('suppressPromptToSaveDefaults');
            if (suppressPromptToSaveDefaults) {
                return;
            }
            // if some default settings were missing...
            const defaultExtension = polyglotConfig.get('defaultNotebookExtension');
            const defaultLanguage = polyglotConfig.get('defaultNotebookLanguage');
            if (!defaultExtension || !defaultLanguage) {
                // ...ask if they want to save the defaults
                const setDefaultsOption = 'Set defaults';
                const dontAskOption = "Don't ask again";
                const saveDefaults = yield vscode.window.showInformationMessage('Would you like to set default values for future notebooks?', setDefaultsOption, 'Dismiss', dontAskOption);
                if (saveDefaults === setDefaultsOption) {
                    // set the values the user just selected...
                    yield polyglotConfig.update('defaultNotebookExtension', extension, vscode.ConfigurationTarget.Global);
                    yield polyglotConfig.update('defaultNotebookLanguage', language, vscode.ConfigurationTarget.Global);
                    // ...then open the settings so they can make any additional changes
                    vscode.commands.executeCommand('polyglot-notebook.setNewNotebookDefaults');
                }
                else if (saveDefaults === dontAskOption) {
                    // set the value to suppress the prompt
                    yield polyglotConfig.update('suppressPromptToSaveDefaults', true, vscode.ConfigurationTarget.Global);
                }
                else {
                    // anything else was either 'Dismiss' or the dialog was closed
                }
            }
        });
    }
    function getNewNotebookExtension(preferDefault) {
        return __awaiter(this, void 0, void 0, function* () {
            const polyglotConfig = vscode.workspace.getConfiguration(constants.PolyglotConfigurationSectionName);
            if (preferDefault) {
                // try to get the default notebook type
                const defaultNotebookExtension = polyglotConfig.get('defaultNotebookExtension');
                if (defaultNotebookExtension) {
                    return defaultNotebookExtension;
                }
            }
            // either wanted a fresh value, or no default was set; directly ask the user
            const availableNotebookExtensions = ['.dib', '.ipynb'];
            const selectedExtension = yield vscode.window.showQuickPick(availableNotebookExtensions, { title: 'Create as...' });
            if (selectedExtension) {
                return selectedExtension;
            }
            return undefined;
        });
    }
    function getNewNotebookLanguage(preferDefault) {
        return __awaiter(this, void 0, void 0, function* () {
            const polyglotConfig = vscode.workspace.getConfiguration(constants.PolyglotConfigurationSectionName);
            if (preferDefault) {
                // try to get the default notebook type
                const defaultNotebookLanguage = polyglotConfig.get('defaultNotebookLanguage');
                if (defaultNotebookLanguage) {
                    return defaultNotebookLanguage;
                }
            }
            // either wanted a fresh value, or no default was set; directly ask the user
            const languagesAndKernelNames = {
                'C#': 'csharp',
                'F#': 'fsharp',
                'HTML': 'html',
                'JavaScript': 'javascript',
                'KQL': 'kql',
                'Markdown': 'markdown',
                'Mermaid': 'mermaid',
                'PowerShell': 'pwsh',
                'SQL': 'sql',
            };
            const newLanguageOptions = [];
            for (const languageName in languagesAndKernelNames) {
                newLanguageOptions.push(languageName);
            }
            const notebookLanguage = yield vscode.window.showQuickPick(newLanguageOptions, { title: 'Default Language' });
            if (notebookLanguage) {
                return languagesAndKernelNames[notebookLanguage];
            }
            return undefined;
        });
    }
    function newNotebookFromExtension(extension) {
        return __awaiter(this, void 0, void 0, function* () {
            const language = yield getNewNotebookLanguage(true);
            if (!language) {
                return;
            }
            yield newNotebookWithLanguage(extension, language);
        });
    }
    function newNotebookWithLanguage(extension, kernelName) {
        return __awaiter(this, void 0, void 0, function* () {
            const extensionViewTypeMap = {
                '.dib': constants.NotebookViewType,
                '.ipynb': constants.JupyterViewType,
            };
            const viewType = extensionViewTypeMap[extension];
            const isMarkdown = kernelName.toLowerCase() === 'markdown';
            // the metadata needs an actual kernel name, not the special-cased 'markdown'
            const kernelNameInMetadata = isMarkdown ? 'csharp' : kernelName;
            const notebookCellMetadata = {
                kernelName: kernelNameInMetadata,
            };
            const rawCellMetadata = metadataUtilities.getRawNotebookCellMetadataFromNotebookCellMetadata(notebookCellMetadata);
            const [cellKind, cellLanguage] = isMarkdown ? [vscode.NotebookCellKind.Markup, 'markdown'] : [vscode.NotebookCellKind.Code, constants.CellLanguageIdentifier];
            const cell = new vscode.NotebookCellData(cellKind, '', cellLanguage);
            cell.metadata = rawCellMetadata;
            const notebookDocumentMetadata = {
                kernelInfo: {
                    defaultKernelName: kernelNameInMetadata,
                    items: [
                        {
                            name: kernelNameInMetadata,
                            aliases: [],
                            languageName: kernelNameInMetadata // it just happens that the kernel names we allow are also the language names
                        }
                    ]
                }
            };
            const createForIpynb = viewType === constants.JupyterViewType;
            const rawNotebookMetadata = metadataUtilities.getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata, {}, createForIpynb);
            const content = new vscode.NotebookData([cell]);
            content.metadata = rawNotebookMetadata;
            const notebook = yield vscode.workspace.openNotebookDocument(viewType, content);
            const _editor = yield vscode.window.showNotebookDocument(notebook);
            if (viewType === constants.JupyterViewType) {
                // note, new .ipynb notebooks are currently affected by this bug: https://github.com/microsoft/vscode/issues/121974
                yield selectDotNetInteractiveKernelForJupyter();
            }
        });
    }
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.setNewNotebookDefaults', () => __awaiter(this, void 0, void 0, function* () {
        yield vscode.commands.executeCommand('workbench.action.openGlobalSettings', { query: 'polyglot-notebook.defaultNotebook' });
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.newNotebook', () => __awaiter(this, void 0, void 0, function* () {
        yield newNotebookCommandHandler(true);
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.newNotebookNoDefaults', () => __awaiter(this, void 0, void 0, function* () {
        yield newNotebookCommandHandler(false);
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.fileNew', () => __awaiter(this, void 0, void 0, function* () {
        // this command exists purely to forward to the polyglot-notebook.newNotebook command, but we need a separate `title`/`shortTitle` for the command palette
        yield vscode.commands.executeCommand('polyglot-notebook.newNotebook');
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.newNotebookDib', () => __awaiter(this, void 0, void 0, function* () {
        yield newNotebookFromExtension('.dib');
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.newNotebookIpynb', () => __awaiter(this, void 0, void 0, function* () {
        yield newNotebookFromExtension('.ipynb');
    })));
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.openNotebook', (notebookUri) => __awaiter(this, void 0, void 0, function* () {
        // ensure we have a notebook uri
        if (!notebookUri) {
            const uris = yield vscode.window.showOpenDialog({
                filters: notebookFileFilters
            });
            if (uris && uris.length > 0) {
                notebookUri = uris[0];
            }
            if (!notebookUri) {
                // no appropriate uri
                return;
            }
        }
        yield openNotebook(notebookUri);
    })));
    function openNotebook(uri) {
        return __awaiter(this, void 0, void 0, function* () {
            const extension = path.extname(uri.toString());
            const viewType = extension === '.dib'
                ? constants.NotebookViewType
                : constants.JupyterViewType;
            yield vscode.commands.executeCommand('vscode.openWith', uri, viewType);
        });
    }
    context.subscriptions.push(vscode.commands.registerCommand('polyglot-notebook.saveAsNotebook', () => __awaiter(this, void 0, void 0, function* () {
        if (vscode.window.activeNotebookEditor) {
            const uri = yield vscode.window.showSaveDialog({
                filters: notebookFileFilters
            });
            if (!uri) {
                return;
            }
            const notebook = vscodeNotebookManagement.getNotebookDocumentFromEditor(vscode.window.activeNotebookEditor);
            const interactiveDocument = (0, vscodeUtilities_1.toNotebookDocument)(notebook);
            const uriPath = uri.toString();
            const extension = path.extname(uriPath);
            const documentType = (0, utilities_1.extensionToDocumentType)(extension);
            const buffer = yield parserServer.serializeNotebook(documentType, eol, interactiveDocument);
            yield vscode.workspace.fs.writeFile(uri, buffer);
            switch (path.extname(uriPath)) {
                case '.dib':
                    yield vscode.commands.executeCommand('polyglot-notebook.openNotebook', uri);
                    break;
            }
        }
    })));
}
exports.registerFileCommands = registerFileCommands;
function selectDotNetInteractiveKernelForJupyter() {
    return __awaiter(this, void 0, void 0, function* () {
        const extension = 'ms-dotnettools.dotnet-interactive-vscode';
        const id = constants.JupyterKernelId;
        yield vscode.commands.executeCommand('notebook.selectKernel', { extension, id });
    });
}
exports.selectDotNetInteractiveKernelForJupyter = selectDotNetInteractiveKernelForJupyter;
// callbacks used to install interactive tool
function getInteractiveVersion(dotnetPath, globalStoragePath) {
    return __awaiter(this, void 0, void 0, function* () {
        const result = yield (0, utilities_1.executeSafe)(dotnetPath, ['tool', 'run', 'dotnet-interactive', '--', '--version'], globalStoragePath);
        if (result.code === 0) {
            const versionString = (0, utilities_1.getVersionNumber)(result.output);
            return versionString;
        }
        return undefined;
    });
}
//# sourceMappingURL=commands.js.map