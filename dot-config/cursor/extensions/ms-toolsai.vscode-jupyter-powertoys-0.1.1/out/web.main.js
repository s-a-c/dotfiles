/******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ([
/* 0 */,
/* 1 */
/***/ ((module) => {

"use strict";
module.exports = require("vscode");

/***/ }),
/* 2 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.activateNotebookRunGroups = void 0;
const commands_1 = __webpack_require__(3);
const documents_1 = __webpack_require__(8);
const cellStatusBar_1 = __webpack_require__(9);
function activateNotebookRunGroups(context) {
    (0, commands_1.registerCommands)(context);
    (0, documents_1.registerDocuments)(context);
    (0, cellStatusBar_1.registerCellStatusBarProvider)(context);
}
exports.activateNotebookRunGroups = activateNotebookRunGroups;


/***/ }),
/* 3 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.registerCommands = void 0;
const vscode = __webpack_require__(1);
const cellMetadataHelpers_1 = __webpack_require__(4);
const contextKeys_1 = __webpack_require__(5);
const enums_1 = __webpack_require__(6);
const logging_1 = __webpack_require__(7);
function registerCommands(context) {
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.addGroup1', (args) => {
        addToGroup(enums_1.RunGroup.one, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.addGroup2', (args) => {
        addToGroup(enums_1.RunGroup.two, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.addGroup3', (args) => {
        addToGroup(enums_1.RunGroup.three, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.removeGroup1', (args) => {
        removeFromGroup(enums_1.RunGroup.one, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.removeGroup2', (args) => {
        removeFromGroup(enums_1.RunGroup.two, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.removeGroup3', (args) => {
        removeFromGroup(enums_1.RunGroup.three, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.executeGroup1', (args) => {
        executeGroup(enums_1.RunGroup.one, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.executeGroup2', (args) => {
        executeGroup(enums_1.RunGroup.two, argNotebookCell(args));
    }));
    context.subscriptions.push(vscode.commands.registerCommand('vscode-notebook-groups.executeGroup3', (args) => {
        executeGroup(enums_1.RunGroup.three, argNotebookCell(args));
    }));
}
exports.registerCommands = registerCommands;
function argNotebookCell(args) {
    if (args && 'index' in args && 'kind' in args && 'notebook' in args && 'document' in args) {
        return args;
    }
    (0, logging_1.log)('Non-NotebookCell passed to cell based notebook group function');
    return undefined;
}
function executeGroup(targetRunGroup, notebookCell) {
    var _a;
    let doc = notebookCell === null || notebookCell === void 0 ? void 0 : notebookCell.notebook;
    if (!doc) {
        doc = (_a = vscode.window.activeNotebookEditor) === null || _a === void 0 ? void 0 : _a.notebook;
        doc || (0, logging_1.log)('Execute group called without a valid document to execute');
    }
    const targetCells = doc === null || doc === void 0 ? void 0 : doc.getCells().filter((notebookCell) => cellInGroup(notebookCell, targetRunGroup)).map((cell) => {
        return { start: cell.index, end: cell.index + 1 };
    });
    vscode.commands.executeCommand('notebook.cell.execute', { ranges: targetCells });
}
function cellInGroup(cell, targetRunGroup) {
    const currentValue = (0, cellMetadataHelpers_1.getCellRunGroupMetadata)(cell);
    if (currentValue.includes(targetRunGroup.toString())) {
        return true;
    }
    return false;
}
function addToGroup(targetRunGroup, notebookCell) {
    if (!notebookCell) {
        notebookCell = getCurrentActiveCell();
        if (!notebookCell) {
            return;
        }
    }
    addGroupToCustomMetadata(notebookCell, targetRunGroup);
    (0, contextKeys_1.updateContextKeys)();
}
function removeFromGroup(targetRunGroup, notebookCell) {
    if (!notebookCell) {
        notebookCell = getCurrentActiveCell();
        if (!notebookCell) {
            return;
        }
    }
    removeGroupFromCustomMetadata(notebookCell, targetRunGroup);
    (0, contextKeys_1.updateContextKeys)();
}
function getCurrentActiveCell() {
    var _a;
    const activeNotebook = vscode.window.activeNotebookEditor;
    if (activeNotebook) {
        const selectedCellIndex = ((_a = activeNotebook === null || activeNotebook === void 0 ? void 0 : activeNotebook.selections[0]) === null || _a === void 0 ? void 0 : _a.start) || 0;
        return activeNotebook.notebook.cellCount >= 1 ? activeNotebook.notebook.cellAt(selectedCellIndex) : undefined;
    }
}
function removeGroupFromCustomMetadata(notebookCell, targetRunGroup) {
    const currentValue = (0, cellMetadataHelpers_1.getCellRunGroupMetadata)(notebookCell);
    if (!currentValue.includes(targetRunGroup.toString())) {
        (0, logging_1.log)('Given run group is not present, so cannot be removed from.');
        return;
    }
    const newValue = currentValue.replace(targetRunGroup.toString(), '');
    (0, cellMetadataHelpers_1.updateCellRunGroupMetadata)(notebookCell, newValue);
    (0, logging_1.log)(`Removing from group Cell Index: ${notebookCell.index} Groups Value: ${targetRunGroup.toString()}`);
}
function addGroupToCustomMetadata(notebookCell, targetRunGroup) {
    const currentValue = (0, cellMetadataHelpers_1.getCellRunGroupMetadata)(notebookCell);
    if (currentValue.includes(targetRunGroup.toString())) {
        (0, logging_1.log)('Attempted to add cell to a group it is already in');
        return;
    }
    const newValue = currentValue.concat(targetRunGroup.toString());
    (0, cellMetadataHelpers_1.updateCellRunGroupMetadata)(notebookCell, newValue);
    (0, logging_1.log)(`Adding to group Cell Index: ${notebookCell.index} Groups Value: ${newValue}`);
}


/***/ }),
/* 4 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.updateCellRunGroupMetadata = exports.getCellRunGroupMetadata = void 0;
const vscode = __webpack_require__(1);
function getCellRunGroupMetadata(cell) {
    var _a, _b, _c;
    const customMetadata = (_c = (_b = (_a = cell.metadata) === null || _a === void 0 ? void 0 : _a.custom) === null || _b === void 0 ? void 0 : _b.metadata) === null || _c === void 0 ? void 0 : _c.notebookRunGroups;
    if (customMetadata && customMetadata.groupValue) {
        return customMetadata.groupValue;
    }
    return '';
}
exports.getCellRunGroupMetadata = getCellRunGroupMetadata;
function updateCellRunGroupMetadata(cell, newGroupValue) {
    const newMetadata = { ...(cell.metadata || {}) };
    if (useCustomMetadata()) {
        newMetadata.custom = newMetadata.custom || {};
        newMetadata.custom.metadata = newMetadata.custom.metadata || {};
        newMetadata.custom.metadata.notebookRunGroups = newMetadata.custom.metadata.notebookRunGroups || {};
        newMetadata.custom.metadata.notebookRunGroups.groupValue = newGroupValue;
    }
    else {
        newMetadata.metadata = newMetadata.metadata || {};
        newMetadata.metadata.notebookRunGroups = newMetadata.metadata.notebookRunGroups || {};
        newMetadata.metadata.notebookRunGroups.groupValue = newGroupValue;
    }
    const wsEdit = new vscode.WorkspaceEdit();
    const notebookEdit = vscode.NotebookEdit.updateCellMetadata(cell.index, newMetadata);
    wsEdit.set(cell.notebook.uri, [notebookEdit]);
    vscode.workspace.applyEdit(wsEdit);
}
exports.updateCellRunGroupMetadata = updateCellRunGroupMetadata;
function useCustomMetadata() {
    var _a, _b;
    if ((_b = (_a = vscode.extensions.getExtension('vscode.ipynb')) === null || _a === void 0 ? void 0 : _a.exports) === null || _b === void 0 ? void 0 : _b.dropCustomMetadata) {
        return false;
    }
    return true;
}


/***/ }),
/* 5 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.updateContextKeys = void 0;
const vscode = __webpack_require__(1);
const enums_1 = __webpack_require__(6);
const cellMetadataHelpers_1 = __webpack_require__(4);
function updateContextKeys() {
    const group1Cells = new Set();
    const group2Cells = new Set();
    const group3Cells = new Set();
    const group1Documents = new Set();
    const group2Documents = new Set();
    const group3Documents = new Set();
    vscode.workspace.notebookDocuments.forEach((notebookDocument) => {
        notebookDocument.getCells().forEach((cell) => {
            const cellGroups = (0, cellMetadataHelpers_1.getCellRunGroupMetadata)(cell);
            if (cellGroups.includes(enums_1.RunGroup.one.toString())) {
                group1Cells.add(cell.document.uri);
                group1Documents.add(cell.notebook.uri);
            }
            if (cellGroups.includes(enums_1.RunGroup.two.toString())) {
                group2Cells.add(cell.document.uri);
                group2Documents.add(cell.notebook.uri);
            }
            if (cellGroups.includes(enums_1.RunGroup.three.toString())) {
                group3Cells.add(cell.document.uri);
                group3Documents.add(cell.notebook.uri);
            }
        });
    });
    vscode.commands.executeCommand('setContext', 'notebookRunGroups.groupOneCells', Array.from(group1Cells));
    vscode.commands.executeCommand('setContext', 'notebookRunGroups.groupOneDocuments', Array.from(group1Documents));
    vscode.commands.executeCommand('setContext', 'notebookRunGroups.groupTwoCells', Array.from(group2Cells));
    vscode.commands.executeCommand('setContext', 'notebookRunGroups.groupTwoDocuments', Array.from(group2Documents));
    vscode.commands.executeCommand('setContext', 'notebookRunGroups.groupThreeCells', Array.from(group3Cells));
    vscode.commands.executeCommand('setContext', 'notebookRunGroups.groupThreeDocuments', Array.from(group3Documents));
}
exports.updateContextKeys = updateContextKeys;


/***/ }),
/* 6 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RunGroup = void 0;
var RunGroup;
(function (RunGroup) {
    RunGroup[RunGroup["one"] = 1] = "one";
    RunGroup[RunGroup["two"] = 2] = "two";
    RunGroup[RunGroup["three"] = 3] = "three";
})(RunGroup = exports.RunGroup || (exports.RunGroup = {}));


/***/ }),
/* 7 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.log = void 0;
function log(message) {
    console.log(message);
}
exports.log = log;


/***/ }),
/* 8 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.registerDocuments = void 0;
const vscode = __webpack_require__(1);
const contextKeys_1 = __webpack_require__(5);
function registerDocuments(context) {
    context.subscriptions.push(vscode.workspace.onDidOpenNotebookDocument(documentOpen));
    context.subscriptions.push(vscode.window.onDidChangeActiveNotebookEditor(notebookEditorChanged));
    (0, contextKeys_1.updateContextKeys)();
}
exports.registerDocuments = registerDocuments;
function notebookEditorChanged() {
    (0, contextKeys_1.updateContextKeys)();
}
function documentOpen(document) {
    (0, contextKeys_1.updateContextKeys)();
}


/***/ }),
/* 9 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.registerCellStatusBarProvider = void 0;
const vscode = __webpack_require__(1);
const cellMetadataHelpers_1 = __webpack_require__(4);
const enums_1 = __webpack_require__(6);
function registerCellStatusBarProvider(context) {
    context.subscriptions.push(vscode.notebooks.registerNotebookCellStatusBarItemProvider('*', { provideCellStatusBarItems }));
}
exports.registerCellStatusBarProvider = registerCellStatusBarProvider;
function provideCellStatusBarItems(cell, token) {
    const cellRunGroups = (0, cellMetadataHelpers_1.getCellRunGroupMetadata)(cell);
    const groupStrings = [];
    if (cellRunGroups.includes(enums_1.RunGroup.one.toString())) {
        groupStrings.push('Group 1');
    }
    if (cellRunGroups.includes(enums_1.RunGroup.two.toString())) {
        groupStrings.push('Group 2');
    }
    if (cellRunGroups.includes(enums_1.RunGroup.three.toString())) {
        groupStrings.push('Group 3');
    }
    return { text: groupStrings.join(' '), alignment: vscode.NotebookCellStatusBarAlignment.Left };
}


/***/ }),
/* 10 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.deactivate = exports.activate = void 0;
const vscode_1 = __webpack_require__(1);
const kernelTreeView_1 = __webpack_require__(11);
const utils_1 = __webpack_require__(17);
const commandHandler_1 = __webpack_require__(25);
let activated = false;
async function activate(context) {
    async function activateFeature() {
        if (activated) {
            return;
        }
        activated = true;
        void (0, utils_1.initializeKnownLanguages)();
        const jupyterExt = vscode_1.extensions.getExtension('ms-toolsai.jupyter');
        if (!jupyterExt) {
            return;
        }
        await jupyterExt.activate();
        const kernelService = await jupyterExt.exports.getKernelService();
        if (!kernelService) {
            return;
        }
        commandHandler_1.CommandHandler.register(kernelService, context, jupyterExt.exports);
        kernelTreeView_1.KernelTreeView.register(kernelService, context.subscriptions);
    }
    if (vscode_1.workspace.getConfiguration('jupyter').get('kernelManagement.enabled')) {
        await activateFeature();
        return;
    }
    vscode_1.workspace.onDidChangeConfiguration((e) => {
        if (e.affectsConfiguration('jupyter') &&
            vscode_1.workspace.getConfiguration('jupyter').get('kernelManagement.enabled')) {
            activateFeature().catch((ex) => console.error('Failed to activate kernel management feature', ex));
        }
    }, undefined, context.subscriptions);
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;


/***/ }),
/* 11 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.KernelTreeView = exports.removeNotebookSuffixAddedByExtension = exports.getDisplayNameOrNameOfKernelConnection = exports.getTelemetrySafeVersion = exports.iPyNbNameToTemporarilyStartKernel = void 0;
const path = __webpack_require__(12);
const vscode_1 = __webpack_require__(1);
const vscodeJupyter_1 = __webpack_require__(16);
const utils_1 = __webpack_require__(17);
const constants_1 = __webpack_require__(21);
const integration_1 = __webpack_require__(22);
const kernelChildNodeProvider_1 = __webpack_require__(23);
const python_extension_1 = __webpack_require__(24);
exports.iPyNbNameToTemporarilyStartKernel = '__dummy__.ipynb';
function getConnectionTitle(baseUrl) {
    return baseUrl ? `Remote Kernels (${baseUrl})` : 'Local Connections';
}
class HostTreeItem extends vscode_1.TreeItem {
    constructor(data) {
        super(getConnectionTitle(data.baseUrl), vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.contextValue = this.data.type;
    }
}
class LanguageTreeItem extends vscode_1.TreeItem {
    constructor(data) {
        super(data.language, vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.contextValue = `kernelspec-language:${data}`;
        const ext = (0, utils_1.getLanguageExtension)(data.language);
        this.resourceUri = ext ? vscode_1.Uri.parse(`one${ext}`) : undefined;
        this.iconPath = new vscode_1.ThemeIcon('file');
    }
}
class PythonEnvironmentTreeItem extends vscode_1.TreeItem {
    constructor(data) {
        super(data.category, vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
    }
}
class KernelSpecifications extends vscode_1.TreeItem {
    constructor(data) {
        super('Kernel Specifications', vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.contextValue = this.data.type;
    }
}
class ActiveKernels extends vscode_1.TreeItem {
    constructor(data) {
        super('Active Jupyter Sessions', vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.contextValue = this.data.type;
    }
}
function getOldFormatDisplayNameOrNameOfKernelConnection(kernelConnection) {
    var _a, _b;
    if (!kernelConnection) {
        return '';
    }
    const displayName = kernelConnection.kind === 'connectToLiveRemoteKernel'
        ? kernelConnection.kernelModel.display_name
        : (_a = kernelConnection.kernelSpec) === null || _a === void 0 ? void 0 : _a.display_name;
    const name = kernelConnection.kind === 'connectToLiveRemoteKernel'
        ? kernelConnection.kernelModel.name
        : (_b = kernelConnection.kernelSpec) === null || _b === void 0 ? void 0 : _b.name;
    const interpreterName = kernelConnection.kind === 'startUsingPythonInterpreter' ? '' : undefined;
    return displayName || name || interpreterName || '';
}
function getTelemetrySafeVersion(version) {
    try {
        const [major, minor, patch] = `${version.trim()}...`.split('.').map((item) => parseInt(item, 10));
        if (isNaN(major)) {
            return;
        }
        else if (isNaN(minor)) {
            return major.toString();
        }
        else if (isNaN(patch)) {
            return `${major}.${minor}`;
        }
        return `${major}.${minor}.${patch}`;
    }
    catch (ex) {
        console.error(`Failed to parse version ${version}`, ex);
    }
}
exports.getTelemetrySafeVersion = getTelemetrySafeVersion;
async function getDisplayNameOrNameOfKernelConnection(kernelConnection, pythonApi) {
    var _a, _b, _c, _d, _e, _f;
    let oldDisplayName = getOldFormatDisplayNameOrNameOfKernelConnection(kernelConnection);
    if (!kernelConnection) {
        return oldDisplayName;
    }
    switch (kernelConnection.kind) {
        case 'connectToLiveRemoteKernel': {
            return oldDisplayName;
        }
        case 'startUsingRemoteKernelSpec':
        case 'startUsingLocalKernelSpec': {
            const envType = await (0, vscodeJupyter_1.getEnvironmentTypeFromUri)((_a = kernelConnection.interpreter) === null || _a === void 0 ? void 0 : _a.uri, pythonApi);
            const envNamePromise = (0, vscodeJupyter_1.getPythonEnvironmentName)((_b = kernelConnection.interpreter) === null || _b === void 0 ? void 0 : _b.uri, pythonApi);
            if (envType && envType !== vscodeJupyter_1.EnvironmentType.Global) {
                if (kernelConnection.kernelSpec.language === constants_1.PYTHON_LANGUAGE) {
                    const [version, envName] = await Promise.all([
                        (0, vscodeJupyter_1.getEnvironmentVersionFromUri)((_c = kernelConnection.interpreter) === null || _c === void 0 ? void 0 : _c.uri, pythonApi),
                        envNamePromise
                    ]);
                    const pythonVersion = (version === null || version === void 0 ? void 0 : version.major) && (version === null || version === void 0 ? void 0 : version.minor) && (version === null || version === void 0 ? void 0 : version.micro)
                        ? `Python ${version.major}.${version.minor}.${version.micro}`
                        : `Python`;
                    return envName ? `${envName} (${pythonVersion})` : oldDisplayName;
                }
                else {
                    const envName = await envNamePromise;
                    if (!oldDisplayName) {
                        return envName;
                    }
                    return envName ? `${oldDisplayName} (${envName})` : oldDisplayName;
                }
            }
            else {
                return oldDisplayName || (await envNamePromise) || '';
            }
        }
        case 'startUsingPythonInterpreter':
            const envType = await (0, vscodeJupyter_1.getEnvironmentTypeFromUri)((_d = kernelConnection.interpreter) === null || _d === void 0 ? void 0 : _d.uri, pythonApi);
            if (envType && envType !== vscodeJupyter_1.EnvironmentType.Global) {
                const [versionInfo, envNameInfo] = await Promise.all([
                    (0, vscodeJupyter_1.getEnvironmentVersionFromUri)((_e = kernelConnection.interpreter) === null || _e === void 0 ? void 0 : _e.uri, pythonApi),
                    (0, vscodeJupyter_1.getPythonEnvironmentName)((_f = kernelConnection.interpreter) === null || _f === void 0 ? void 0 : _f.uri, pythonApi)
                ]);
                const version = (versionInfo === null || versionInfo === void 0 ? void 0 : versionInfo.major) && (versionInfo === null || versionInfo === void 0 ? void 0 : versionInfo.minor) && (versionInfo === null || versionInfo === void 0 ? void 0 : versionInfo.micro)
                    ? `Python ${versionInfo.major}.${versionInfo.minor}.${versionInfo.micro}`
                    : `Python`;
                if (kernelConnection.kind === 'startUsingPythonInterpreter' && envType === vscodeJupyter_1.EnvironmentType.Conda) {
                    const envName = envNameInfo || '';
                    if (envName) {
                        return `${envName}${version}`;
                    }
                }
                const pythonDisplayName = version.trim();
                return envNameInfo
                    ? `${envNameInfo} ${pythonDisplayName ? `(${pythonDisplayName})` : ''}`
                    : pythonDisplayName;
            }
    }
    return oldDisplayName;
}
exports.getDisplayNameOrNameOfKernelConnection = getDisplayNameOrNameOfKernelConnection;
const jvscIdentifier = '-jvsc-';
function removeNotebookSuffixAddedByExtension(notebookPath) {
    if (notebookPath.includes(jvscIdentifier)) {
        const guidRegEx = /[a-f0-9]$/;
        if (notebookPath
            .substring(notebookPath.lastIndexOf(jvscIdentifier) + jvscIdentifier.length)
            .search(guidRegEx) !== -1) {
            return notebookPath.substring(0, notebookPath.lastIndexOf(jvscIdentifier));
        }
    }
    return notebookPath;
}
exports.removeNotebookSuffixAddedByExtension = removeNotebookSuffixAddedByExtension;
function getKernelConnectionLanguage(connection) {
    switch (connection.kind) {
        case 'connectToLiveRemoteKernel': {
            return connection.kernelModel.language;
        }
        case 'startUsingLocalKernelSpec':
        case 'startUsingRemoteKernelSpec': {
            return connection.kernelSpec.language;
        }
        case 'startUsingPythonInterpreter': {
            return connection.kernelSpec.language || 'python';
        }
        default:
            return;
    }
}
class KernelSpecTreeItem extends vscode_1.TreeItem {
    constructor(data, pythonApi) {
        super('', vscode_1.TreeItemCollapsibleState.None);
        this.data = data;
        this.pythonApi = pythonApi;
        switch (data.kernelConnectionMetadata.kind) {
            case 'startUsingLocalKernelSpec':
                this.description = data.kernelConnectionMetadata.kernelSpec.specFile
                    ? (0, utils_1.getDisplayPath)(data.kernelConnectionMetadata.kernelSpec.specFile)
                    : '';
                break;
            case 'startUsingPythonInterpreter':
                this.description = (0, utils_1.getDisplayPath)(data.kernelConnectionMetadata.interpreter.uri.fsPath);
                break;
            default:
                break;
        }
        this.contextValue = `${this.data.type}:${this.data.kernelConnectionMetadata.kind}`;
        const ext = (0, utils_1.getLanguageExtension)(getKernelConnectionLanguage(data.kernelConnectionMetadata));
        this.resourceUri = ext ? vscode_1.Uri.parse(`one${ext}`) : undefined;
        this.tooltip = this.label ? (typeof this.label === 'string' ? this.label : this.label.label || '') : '';
        this.iconPath = new vscode_1.ThemeIcon('file');
    }
    async resolve() {
        this.label = await getDisplayNameOrNameOfKernelConnection(this.data.kernelConnectionMetadata, this.pythonApi);
    }
}
class ActiveLocalOrRemoteKernelConnectionTreeItem extends vscode_1.TreeItem {
    constructor(data, pythonApi) {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s;
        super('', vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.pythonApi = pythonApi;
        if (data.uri && !data.uri.fsPath.endsWith(exports.iPyNbNameToTemporarilyStartKernel)) {
            this.description = path.basename(data.uri.fsPath);
        }
        else if (data.kernelConnectionMetadata.kind === 'connectToLiveRemoteKernel') {
            const nbPath = ((_b = (_a = data.kernelConnectionMetadata.kernelModel) === null || _a === void 0 ? void 0 : _a.notebook) === null || _b === void 0 ? void 0 : _b.path) ||
                ((_d = (_c = data.kernelConnectionMetadata.kernelModel) === null || _c === void 0 ? void 0 : _c.model) === null || _d === void 0 ? void 0 : _d.path);
            this.description = nbPath && path.basename(removeNotebookSuffixAddedByExtension(nbPath));
        }
        const ext = (0, utils_1.getLanguageExtension)(getKernelConnectionLanguage(data.kernelConnectionMetadata));
        this.resourceUri = ext ? vscode_1.Uri.parse(`one${ext}`) : undefined;
        this.iconPath = new vscode_1.ThemeIcon('file');
        const prefix = data.type === 'activeLocalKernel' ? 'local' : 'remote';
        this.contextValue = `${prefix}:activeKernel:${((_f = (_e = this.data.connection) === null || _e === void 0 ? void 0 : _e.kernel) === null || _f === void 0 ? void 0 : _f.status) || 'dead'}`;
        console.log(this.contextValue);
        const tooltips = [];
        if ((_h = (_g = this.data.connection) === null || _g === void 0 ? void 0 : _g.kernel) === null || _h === void 0 ? void 0 : _h.status) {
            tooltips.push(`Status ${(_k = (_j = this.data.connection) === null || _j === void 0 ? void 0 : _j.kernel) === null || _k === void 0 ? void 0 : _k.status}`);
        }
        if (data.kernelConnectionMetadata.kind === 'connectToLiveRemoteKernel') {
            if (tooltips.length === 0 && data.kernelConnectionMetadata.kernelModel.execution_state) {
                tooltips.push(`Status ${data.kernelConnectionMetadata.kernelModel.execution_state}`);
            }
            const time = data.kernelConnectionMetadata.kernelModel.lastActivityTime ||
                data.kernelConnectionMetadata.kernelModel.last_activity;
            if (time) {
                tooltips.push(`Last activity ${new Date(time).toLocaleString()}`);
            }
        }
        if ((_m = (_l = this.data.connection) === null || _l === void 0 ? void 0 : _l.kernel) === null || _m === void 0 ? void 0 : _m.status) {
            tooltips.push(`Connection ${(_p = (_o = this.data.connection) === null || _o === void 0 ? void 0 : _o.kernel) === null || _p === void 0 ? void 0 : _p.status}`);
        }
        this.tooltip = tooltips.length
            ? tooltips.join(', ')
            : this.description || this.label || '';
        if (this.data.connection) {
            if (((_q = this.data.connection.kernel) === null || _q === void 0 ? void 0 : _q.connectionStatus) !== 'connected' && this.data.connection.kernel) {
                this.updateIcon((_r = this.data.connection.kernel) === null || _r === void 0 ? void 0 : _r.connectionStatus);
            }
            else if (this.data.connection.kernel) {
                this.updateIcon((_s = this.data.connection.kernel) === null || _s === void 0 ? void 0 : _s.status);
            }
        }
    }
    async resolve() {
        this.label = await getDisplayNameOrNameOfKernelConnection(this.data.kernelConnectionMetadata, this.pythonApi);
    }
    updateIcon(state) {
        switch (state) {
            case 'dead':
            case 'disconnected':
            case 'terminating':
                this.iconPath = new vscode_1.ThemeIcon('error');
                break;
            case 'busy':
                this.iconPath = new vscode_1.ThemeIcon('vm-running');
                break;
            case 'unknown':
                this.iconPath = new vscode_1.ThemeIcon('question');
                break;
            case 'autorestarting':
            case 'connecting':
            case 'restarting':
            case 'starting':
            case 'idle':
            default:
                this.iconPath = new vscode_1.ThemeIcon('file');
                break;
        }
    }
}
class KernelTreeView {
    constructor(kernelService, pythonApi) {
        this.kernelService = kernelService;
        this.pythonApi = pythonApi;
        this._onDidChangeTreeData = new vscode_1.EventEmitter();
        this.disposables = [];
        this.remoteBaseUrls = new Set();
        this.groupBy = 'language';
        this.groupPythonKernelsBy = 'EnvironmentType';
        this.providersAlreadyHandled = new WeakSet();
        this.mappedActiveLocalKernelConnections = [];
        KernelTreeView.instance = this;
        this.kernelService.onDidChangeKernelSpecifications(() => {
            this.cachedKernels = undefined;
            this._onDidChangeTreeData.fire(undefined);
        }, this, this.disposables);
        this.kernelService.onDidChangeKernels(() => {
            this.cachedKernels = undefined;
            this._onDidChangeTreeData.fire(undefined);
        }, this, this.disposables);
    }
    get onDidChangeTreeData() {
        return this._onDidChangeTreeData.event;
    }
    static refresh(node) {
        KernelTreeView.instance._onDidChangeTreeData.fire(node);
    }
    dispose() {
        this.disposables.forEach((d) => d.dispose());
    }
    async getTreeItem(element) {
        switch (element.type) {
            case 'host':
                return new HostTreeItem(element);
            case 'kernelSpecRoot':
                return new KernelSpecifications(element);
            case 'activeKernelRoot':
                return new ActiveKernels(element);
            case 'kernelSpec':
                const item = new KernelSpecTreeItem(element, this.pythonApi);
                await item.resolve();
                return item;
            case 'language':
                return new LanguageTreeItem(element);
            case 'pythonEnvCategory':
                return new PythonEnvironmentTreeItem(element);
            case 'activeLocalKernel':
            case 'activeRemoteKernel': {
                const item = new ActiveLocalOrRemoteKernelConnectionTreeItem(element, this.pythonApi);
                await item.resolve();
                return item;
            }
            case 'customNodeFromAnotherProvider': {
                const provider = kernelChildNodeProvider_1.ActiveKernelChildNodesProviderRegistry.instance.registeredProviders.get(element.providerId);
                return provider.getTreeItem(element);
            }
            default:
                break;
        }
        throw new Error(`Element not supported ${element}`);
    }
    async getChildren(element) {
        if (!element) {
            const specs = await this.kernelService.getKernelSpecifications();
            this.cachedKernels = (await Promise.all(specs.map(async (k) => {
                try {
                    return {
                        ...k,
                        displayName: await getDisplayNameOrNameOfKernelConnection(k, this.pythonApi)
                    };
                }
                catch (ex) {
                    return {
                        ...k,
                        displayName: 'error'
                    };
                }
            })));
            const uniqueKernelIds = new Set();
            this.cachedKernels = this.cachedKernels.filter((item) => {
                if (uniqueKernelIds.has(item.id)) {
                    return false;
                }
                uniqueKernelIds.add(item.id);
                return true;
            });
            this.cachedKernels.sort((a, b) => { var _a; return (_a = a.displayName) === null || _a === void 0 ? void 0 : _a.localeCompare(b.displayName || ''); });
            this.remoteBaseUrls.clear();
            this.cachedKernels.forEach((item) => {
                if (!isLocalKernelConnection(item)) {
                    this.remoteBaseUrls.add(item.baseUrl);
                }
            });
            if (this.remoteBaseUrls.size) {
                const remoteHosts = Array.from(this.remoteBaseUrls).map((baseUrl) => ({ type: 'host', baseUrl }));
                return [{ type: 'host' }, ...remoteHosts];
            }
            else {
                if (!this.cachedKernels) {
                    return [];
                }
                return [
                    {
                        type: 'kernelSpecRoot'
                    },
                    {
                        type: 'activeKernelRoot'
                    }
                ];
            }
        }
        switch (element.type) {
            case 'host': {
                if (!this.cachedKernels) {
                    return [];
                }
                return [
                    {
                        type: 'kernelSpecRoot',
                        baseUrl: element.baseUrl
                    },
                    {
                        type: 'activeKernelRoot',
                        baseUrl: element.baseUrl
                    }
                ];
            }
            case 'pythonEnvCategory': {
                if (!this.cachedKernels) {
                    return [];
                }
                return this.cachedKernels
                    .filter((item) => {
                    switch (item.kind) {
                        case 'startUsingLocalKernelSpec': {
                            if (item.interpreter && item.kernelSpec.language === constants_1.PYTHON_LANGUAGE) {
                                return ((0, integration_1.getPythonEnvironmentCategory)(item.interpreter, this.pythonApi) ===
                                    element.category);
                            }
                            return false;
                        }
                        case 'startUsingPythonInterpreter':
                            return ((0, integration_1.getPythonEnvironmentCategory)(item.interpreter, this.pythonApi) === element.category);
                        default:
                            return false;
                    }
                })
                    .map((item) => {
                    return {
                        type: 'kernelSpec',
                        kernelConnectionMetadata: item
                    };
                });
            }
            case 'language':
            case 'kernelSpecRoot': {
                if (!this.cachedKernels) {
                    return [];
                }
                if (this.groupPythonKernelsBy === 'EnvironmentType' &&
                    element.type === 'language' &&
                    element.language === constants_1.PYTHON_LANGUAGE &&
                    !element.baseUrl) {
                    const categories = new Set();
                    this.cachedKernels.forEach((item) => {
                        switch (item.kind) {
                            case 'startUsingLocalKernelSpec': {
                                if (item.interpreter && item.kernelSpec.language === constants_1.PYTHON_LANGUAGE) {
                                    categories.add((0, integration_1.getPythonEnvironmentCategory)(item.interpreter, this.pythonApi));
                                }
                                break;
                            }
                            case 'startUsingPythonInterpreter': {
                                categories.add((0, integration_1.getPythonEnvironmentCategory)(item.interpreter, this.pythonApi));
                                break;
                            }
                        }
                    });
                    return Array.from(categories)
                        .sort()
                        .map((category) => ({ category, type: 'pythonEnvCategory' }));
                }
                if (this.groupBy === 'language' && element.type === 'kernelSpecRoot') {
                    const languages = new Set();
                    this.cachedKernels.forEach((item) => {
                        switch (item.kind) {
                            case 'startUsingRemoteKernelSpec':
                            case 'startUsingLocalKernelSpec': {
                                if (item.kernelSpec.language) {
                                    languages.add(item.kernelSpec.language);
                                }
                                else {
                                    languages.add('<unknown>');
                                }
                                break;
                            }
                            case 'startUsingPythonInterpreter': {
                                languages.add('python');
                                break;
                            }
                        }
                    });
                    return Array.from(languages)
                        .sort()
                        .map((language) => ({ language, type: 'language', baseUrl: element.baseUrl }));
                }
                return this.cachedKernels
                    .filter((item) => item.kind !== 'connectToLiveRemoteKernel')
                    .filter((item) => {
                    if (element.type !== 'language') {
                        return true;
                    }
                    switch (item.kind) {
                        case 'startUsingRemoteKernelSpec':
                        case 'startUsingLocalKernelSpec':
                            return item.kernelSpec.language
                                ? item.kernelSpec.language === element.language
                                : element.language === '<unknown>';
                            break;
                        case 'startUsingPythonInterpreter':
                            return element.language === 'python';
                        default:
                            return false;
                    }
                })
                    .filter((item) => {
                    if (isLocalKernelConnection(item)) {
                        return element.baseUrl ? false : true;
                    }
                    else {
                        return element.baseUrl === item.baseUrl;
                    }
                })
                    .map((item) => {
                    return {
                        type: 'kernelSpec',
                        kernelConnectionMetadata: item
                    };
                });
            }
            case 'activeKernelRoot': {
                if (!this.cachedKernels) {
                    return [];
                }
                const activeKernels = this.kernelService.getActiveKernels();
                if (element.baseUrl) {
                    const remoteActiveKernels = activeKernels.filter((item) => !isLocalKernelConnection(item.metadata));
                    const remoteActiveKernelStartedUsingConnectToRemoveKernelSpec = remoteActiveKernels.filter((item) => item.metadata.kind === 'startUsingRemoteKernelSpec');
                    const activeRemoteKernelNodes = [];
                    const uniqueKernelIds = new Set();
                    await Promise.all(this.cachedKernels
                        .filter((item) => item.kind === 'connectToLiveRemoteKernel')
                        .filter((item) => !isLocalKernelConnection(item))
                        .map((item) => item)
                        .filter((item) => item.baseUrl === element.baseUrl)
                        .map(async (item) => {
                        if (remoteActiveKernelStartedUsingConnectToRemoveKernelSpec.some((activeRemote) => {
                            var _a;
                            const kernel = activeRemote.uri && this.kernelService.getKernel(activeRemote.uri);
                            return ((_a = kernel === null || kernel === void 0 ? void 0 : kernel.connection.kernel) === null || _a === void 0 ? void 0 : _a.id) === item.kernelModel.id;
                        })) {
                            return;
                        }
                        if (item.kernelModel.id) {
                            if (item.kernelModel.id && uniqueKernelIds.has(item.kernelModel.id)) {
                                return;
                            }
                            uniqueKernelIds.add(item.kernelModel.id);
                        }
                        const activeInfoIndex = remoteActiveKernels.findIndex((activeKernel) => activeKernel.metadata === item);
                        const activeInfo = activeInfoIndex >= 0 ? remoteActiveKernels[activeInfoIndex] : undefined;
                        if (activeInfoIndex >= 0) {
                            remoteActiveKernels.splice(activeInfoIndex, 1);
                        }
                        const info = (activeInfo === null || activeInfo === void 0 ? void 0 : activeInfo.uri)
                            ? await this.kernelService.getKernel(activeInfo === null || activeInfo === void 0 ? void 0 : activeInfo.uri)
                            : undefined;
                        if (info && (activeInfo === null || activeInfo === void 0 ? void 0 : activeInfo.uri)) {
                            activeRemoteKernelNodes.push({
                                type: 'activeRemoteKernel',
                                kernelConnectionMetadata: item,
                                uri: activeInfo.uri,
                                ...info,
                                parent: element
                            });
                        }
                        else {
                            activeRemoteKernelNodes.push({
                                type: 'activeRemoteKernel',
                                kernelConnectionMetadata: item,
                                parent: element
                            });
                        }
                    }));
                    remoteActiveKernels.forEach((item) => {
                        var _a;
                        if (item.metadata.kind === 'connectToLiveRemoteKernel' &&
                            item.metadata.kernelModel.id &&
                            uniqueKernelIds.has(item.metadata.kernelModel.id)) {
                            return;
                        }
                        if (item.metadata.kind === 'startUsingRemoteKernelSpec' && item.uri) {
                            const kernel = this.kernelService.getKernel(item.uri);
                            if (kernel &&
                                kernel.connection.kernel &&
                                uniqueKernelIds.has((_a = kernel.connection.kernel) === null || _a === void 0 ? void 0 : _a.id)) {
                                return;
                            }
                        }
                        if (item.metadata.kind === 'connectToLiveRemoteKernel' &&
                            item.metadata.baseUrl !== element.baseUrl) {
                            return;
                        }
                        activeRemoteKernelNodes.push({
                            type: 'activeRemoteKernel',
                            kernelConnectionMetadata: item.metadata,
                            uri: item.uri,
                            parent: element
                        });
                    });
                    return activeRemoteKernelNodes;
                }
                else {
                    const localActiveKernelSpecs = activeKernels.filter((item) => isLocalKernelConnection(item.metadata));
                    const localActiveKernelsWithInfo = await Promise.all(localActiveKernelSpecs
                        .filter((item) => item.uri)
                        .map(async (item) => {
                        const info = await this.kernelService.getKernel(item.uri);
                        return { ...info, uri: item.uri };
                    }));
                    const activeLocalKernelNodes = localActiveKernelsWithInfo
                        .filter((item) => item.metadata && item.connection)
                        .map((item) => {
                        return {
                            connection: item.connection,
                            kernelConnectionMetadata: item.metadata,
                            uri: item.uri,
                            type: 'activeLocalKernel',
                            parent: element
                        };
                    });
                    activeLocalKernelNodes.forEach((item) => this.trackKernelConnection(item));
                    return activeLocalKernelNodes;
                }
            }
            case 'activeLocalKernel':
            case 'activeRemoteKernel': {
                let nodes = [];
                Array.from(kernelChildNodeProvider_1.ActiveKernelChildNodesProviderRegistry.instance.registeredProviders.values()).forEach((provider) => {
                    this.addOnDidProviderNodeChange(provider);
                    const children = provider.getChildren(element);
                    nodes = nodes.concat(children);
                });
                return nodes;
            }
            case 'customNodeFromAnotherProvider': {
                const provider = kernelChildNodeProvider_1.ActiveKernelChildNodesProviderRegistry.instance.registeredProviders.get(element.providerId);
                if (provider) {
                    this.addOnDidProviderNodeChange(provider);
                    return provider.getChildren(element);
                }
                else {
                    console.error('Unknown provider for custom nodes', element.providerId);
                    return [];
                }
            }
            default:
                return [];
        }
    }
    static register(kernelService, disposables) {
        const pythonApi = python_extension_1.PythonExtension.api().then((api) => {
            const provider = new KernelTreeView(kernelService, api);
            disposables.push(provider);
            const options = {
                treeDataProvider: provider,
                canSelectMany: false,
                showCollapseAll: true
            };
            const treeView = vscode_1.window.createTreeView('jupyterKernelsView', options);
            disposables.push(treeView);
        });
    }
    addOnDidProviderNodeChange(provider) {
        if (this.providersAlreadyHandled.has(provider)) {
            return;
        }
        this.providersAlreadyHandled.add(provider);
        if (!provider.onDidChangeTreeData) {
            return;
        }
        provider.onDidChangeTreeData((node) => this._onDidChangeTreeData.fire(node), this, this.disposables);
    }
    trackKernelConnection(localActiveKernel) {
        var _a, _b;
        if (this.mappedActiveLocalKernelConnections.find((item) => {
            var _a, _b;
            return item.connection === localActiveKernel.connection &&
                item.kernelConnectionMetadata === localActiveKernel.kernelConnectionMetadata &&
                (item.uri ? ((_a = item.uri) === null || _a === void 0 ? void 0 : _a.toString()) === ((_b = localActiveKernel.uri) === null || _b === void 0 ? void 0 : _b.toString()) : true) &&
                item.type === localActiveKernel.type;
        })) {
            return;
        }
        this.mappedActiveLocalKernelConnections.push(localActiveKernel);
        const onConnectionStatusChanged = () => {
            this._onDidChangeTreeData.fire(localActiveKernel);
        };
        const onStatusChanged = () => {
            this._onDidChangeTreeData.fire(localActiveKernel);
        };
        (_a = localActiveKernel.connection.kernel) === null || _a === void 0 ? void 0 : _a.connectionStatusChanged.connect(onConnectionStatusChanged, this);
        (_b = localActiveKernel.connection.kernel) === null || _b === void 0 ? void 0 : _b.statusChanged.connect(onStatusChanged, this);
        const disposable = new vscode_1.Disposable(() => {
            var _a, _b;
            if (localActiveKernel.connection) {
                (_a = localActiveKernel.connection.kernel) === null || _a === void 0 ? void 0 : _a.connectionStatusChanged.disconnect(onConnectionStatusChanged, this);
                (_b = localActiveKernel.connection.kernel) === null || _b === void 0 ? void 0 : _b.statusChanged.disconnect(onStatusChanged, this);
            }
        });
        this.disposables.push(disposable);
    }
}
exports.KernelTreeView = KernelTreeView;
function isLocalKernelConnection(connection) {
    return connection.kind === 'startUsingLocalKernelSpec' || connection.kind === 'startUsingPythonInterpreter';
}


/***/ }),
/* 12 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.delimiter = exports.sep = exports.toNamespacedPath = exports.parse = exports.format = exports.extname = exports.basename = exports.dirname = exports.relative = exports.resolve = exports.join = exports.isAbsolute = exports.normalize = exports.posix = exports.win32 = void 0;
const process = __webpack_require__(13);
const CHAR_UPPERCASE_A = 65;
const CHAR_LOWERCASE_A = 97;
const CHAR_UPPERCASE_Z = 90;
const CHAR_LOWERCASE_Z = 122;
const CHAR_DOT = 46;
const CHAR_FORWARD_SLASH = 47;
const CHAR_BACKWARD_SLASH = 92;
const CHAR_COLON = 58;
const CHAR_QUESTION_MARK = 63;
class ErrorInvalidArgType extends Error {
    constructor(name, expected, actual) {
        let determiner;
        if (typeof expected === 'string' && expected.indexOf('not ') === 0) {
            determiner = 'must not be';
            expected = expected.replace(/^not /, '');
        }
        else {
            determiner = 'must be';
        }
        const type = name.indexOf('.') !== -1 ? 'property' : 'argument';
        let msg = `The "${name}" ${type} ${determiner} of type ${expected}`;
        msg += `. Received type ${typeof actual}`;
        super(msg);
        this.code = 'ERR_INVALID_ARG_TYPE';
    }
}
function validateString(value, name) {
    if (typeof value !== 'string') {
        throw new ErrorInvalidArgType(name, 'string', value);
    }
}
function isPathSeparator(code) {
    return code === CHAR_FORWARD_SLASH || code === CHAR_BACKWARD_SLASH;
}
function isPosixPathSeparator(code) {
    return code === CHAR_FORWARD_SLASH;
}
function isWindowsDeviceRoot(code) {
    return ((code >= CHAR_UPPERCASE_A && code <= CHAR_UPPERCASE_Z) || (code >= CHAR_LOWERCASE_A && code <= CHAR_LOWERCASE_Z));
}
function normalizeString(path, allowAboveRoot, separator, isPathSeparator) {
    let res = '';
    let lastSegmentLength = 0;
    let lastSlash = -1;
    let dots = 0;
    let code = 0;
    for (let i = 0; i <= path.length; ++i) {
        if (i < path.length) {
            code = path.charCodeAt(i);
        }
        else if (isPathSeparator(code)) {
            break;
        }
        else {
            code = CHAR_FORWARD_SLASH;
        }
        if (isPathSeparator(code)) {
            if (lastSlash === i - 1 || dots === 1) {
            }
            else if (dots === 2) {
                if (res.length < 2 ||
                    lastSegmentLength !== 2 ||
                    res.charCodeAt(res.length - 1) !== CHAR_DOT ||
                    res.charCodeAt(res.length - 2) !== CHAR_DOT) {
                    if (res.length > 2) {
                        const lastSlashIndex = res.lastIndexOf(separator);
                        if (lastSlashIndex === -1) {
                            res = '';
                            lastSegmentLength = 0;
                        }
                        else {
                            res = res.slice(0, lastSlashIndex);
                            lastSegmentLength = res.length - 1 - res.lastIndexOf(separator);
                        }
                        lastSlash = i;
                        dots = 0;
                        continue;
                    }
                    else if (res.length !== 0) {
                        res = '';
                        lastSegmentLength = 0;
                        lastSlash = i;
                        dots = 0;
                        continue;
                    }
                }
                if (allowAboveRoot) {
                    res += res.length > 0 ? `${separator}..` : '..';
                    lastSegmentLength = 2;
                }
            }
            else {
                if (res.length > 0) {
                    res += `${separator}${path.slice(lastSlash + 1, i)}`;
                }
                else {
                    res = path.slice(lastSlash + 1, i);
                }
                lastSegmentLength = i - lastSlash - 1;
            }
            lastSlash = i;
            dots = 0;
        }
        else if (code === CHAR_DOT && dots !== -1) {
            ++dots;
        }
        else {
            dots = -1;
        }
    }
    return res;
}
function _format(sep, pathObject) {
    if (pathObject === null || typeof pathObject !== 'object') {
        throw new ErrorInvalidArgType('pathObject', 'Object', pathObject);
    }
    const dir = pathObject.dir || pathObject.root;
    const base = pathObject.base || `${pathObject.name || ''}${pathObject.ext || ''}`;
    if (!dir) {
        return base;
    }
    return dir === pathObject.root ? `${dir}${base}` : `${dir}${sep}${base}`;
}
exports.win32 = {
    resolve(...pathSegments) {
        let resolvedDevice = '';
        let resolvedTail = '';
        let resolvedAbsolute = false;
        for (let i = pathSegments.length - 1; i >= -1; i--) {
            let path;
            if (i >= 0) {
                path = pathSegments[i];
                validateString(path, 'path');
                if (path.length === 0) {
                    continue;
                }
            }
            else if (resolvedDevice.length === 0) {
                path = process.cwd();
            }
            else {
                path = process.env[`=${resolvedDevice}`] || process.cwd();
                if (path === undefined ||
                    (path.slice(0, 2).toLowerCase() !== resolvedDevice.toLowerCase() &&
                        path.charCodeAt(2) === CHAR_BACKWARD_SLASH)) {
                    path = `${resolvedDevice}\\`;
                }
            }
            const len = path.length;
            let rootEnd = 0;
            let device = '';
            let isAbsolute = false;
            const code = path.charCodeAt(0);
            if (len === 1) {
                if (isPathSeparator(code)) {
                    rootEnd = 1;
                    isAbsolute = true;
                }
            }
            else if (isPathSeparator(code)) {
                isAbsolute = true;
                if (isPathSeparator(path.charCodeAt(1))) {
                    let j = 2;
                    let last = j;
                    while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                        j++;
                    }
                    if (j < len && j !== last) {
                        const firstPart = path.slice(last, j);
                        last = j;
                        while (j < len && isPathSeparator(path.charCodeAt(j))) {
                            j++;
                        }
                        if (j < len && j !== last) {
                            last = j;
                            while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                                j++;
                            }
                            if (j === len || j !== last) {
                                device = `\\\\${firstPart}\\${path.slice(last, j)}`;
                                rootEnd = j;
                            }
                        }
                    }
                }
                else {
                    rootEnd = 1;
                }
            }
            else if (isWindowsDeviceRoot(code) && path.charCodeAt(1) === CHAR_COLON) {
                device = path.slice(0, 2);
                rootEnd = 2;
                if (len > 2 && isPathSeparator(path.charCodeAt(2))) {
                    isAbsolute = true;
                    rootEnd = 3;
                }
            }
            if (device.length > 0) {
                if (resolvedDevice.length > 0) {
                    if (device.toLowerCase() !== resolvedDevice.toLowerCase()) {
                        continue;
                    }
                }
                else {
                    resolvedDevice = device;
                }
            }
            if (resolvedAbsolute) {
                if (resolvedDevice.length > 0) {
                    break;
                }
            }
            else {
                resolvedTail = `${path.slice(rootEnd)}\\${resolvedTail}`;
                resolvedAbsolute = isAbsolute;
                if (isAbsolute && resolvedDevice.length > 0) {
                    break;
                }
            }
        }
        resolvedTail = normalizeString(resolvedTail, !resolvedAbsolute, '\\', isPathSeparator);
        return resolvedAbsolute ? `${resolvedDevice}\\${resolvedTail}` : `${resolvedDevice}${resolvedTail}` || '.';
    },
    normalize(path) {
        validateString(path, 'path');
        const len = path.length;
        if (len === 0) {
            return '.';
        }
        let rootEnd = 0;
        let device;
        let isAbsolute = false;
        const code = path.charCodeAt(0);
        if (len === 1) {
            return isPosixPathSeparator(code) ? '\\' : path;
        }
        if (isPathSeparator(code)) {
            isAbsolute = true;
            if (isPathSeparator(path.charCodeAt(1))) {
                let j = 2;
                let last = j;
                while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                    j++;
                }
                if (j < len && j !== last) {
                    const firstPart = path.slice(last, j);
                    last = j;
                    while (j < len && isPathSeparator(path.charCodeAt(j))) {
                        j++;
                    }
                    if (j < len && j !== last) {
                        last = j;
                        while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                            j++;
                        }
                        if (j === len) {
                            return `\\\\${firstPart}\\${path.slice(last)}\\`;
                        }
                        if (j !== last) {
                            device = `\\\\${firstPart}\\${path.slice(last, j)}`;
                            rootEnd = j;
                        }
                    }
                }
            }
            else {
                rootEnd = 1;
            }
        }
        else if (isWindowsDeviceRoot(code) && path.charCodeAt(1) === CHAR_COLON) {
            device = path.slice(0, 2);
            rootEnd = 2;
            if (len > 2 && isPathSeparator(path.charCodeAt(2))) {
                isAbsolute = true;
                rootEnd = 3;
            }
        }
        let tail = rootEnd < len ? normalizeString(path.slice(rootEnd), !isAbsolute, '\\', isPathSeparator) : '';
        if (tail.length === 0 && !isAbsolute) {
            tail = '.';
        }
        if (tail.length > 0 && isPathSeparator(path.charCodeAt(len - 1))) {
            tail += '\\';
        }
        if (device === undefined) {
            return isAbsolute ? `\\${tail}` : tail;
        }
        return isAbsolute ? `${device}\\${tail}` : `${device}${tail}`;
    },
    isAbsolute(path) {
        validateString(path, 'path');
        const len = path.length;
        if (len === 0) {
            return false;
        }
        const code = path.charCodeAt(0);
        return (isPathSeparator(code) ||
            (len > 2 &&
                isWindowsDeviceRoot(code) &&
                path.charCodeAt(1) === CHAR_COLON &&
                isPathSeparator(path.charCodeAt(2))));
    },
    join(...paths) {
        if (paths.length === 0) {
            return '.';
        }
        let joined;
        let firstPart;
        for (let i = 0; i < paths.length; ++i) {
            const arg = paths[i];
            validateString(arg, 'path');
            if (arg.length > 0) {
                if (joined === undefined) {
                    joined = firstPart = arg;
                }
                else {
                    joined += `\\${arg}`;
                }
            }
        }
        if (joined === undefined) {
            return '.';
        }
        let needsReplace = true;
        let slashCount = 0;
        if (typeof firstPart === 'string' && isPathSeparator(firstPart.charCodeAt(0))) {
            ++slashCount;
            const firstLen = firstPart.length;
            if (firstLen > 1 && isPathSeparator(firstPart.charCodeAt(1))) {
                ++slashCount;
                if (firstLen > 2) {
                    if (isPathSeparator(firstPart.charCodeAt(2))) {
                        ++slashCount;
                    }
                    else {
                        needsReplace = false;
                    }
                }
            }
        }
        if (needsReplace) {
            while (slashCount < joined.length && isPathSeparator(joined.charCodeAt(slashCount))) {
                slashCount++;
            }
            if (slashCount >= 2) {
                joined = `\\${joined.slice(slashCount)}`;
            }
        }
        return exports.win32.normalize(joined);
    },
    relative(from, to) {
        validateString(from, 'from');
        validateString(to, 'to');
        if (from === to) {
            return '';
        }
        const fromOrig = exports.win32.resolve(from);
        const toOrig = exports.win32.resolve(to);
        if (fromOrig === toOrig) {
            return '';
        }
        from = fromOrig.toLowerCase();
        to = toOrig.toLowerCase();
        if (from === to) {
            return '';
        }
        let fromStart = 0;
        while (fromStart < from.length && from.charCodeAt(fromStart) === CHAR_BACKWARD_SLASH) {
            fromStart++;
        }
        let fromEnd = from.length;
        while (fromEnd - 1 > fromStart && from.charCodeAt(fromEnd - 1) === CHAR_BACKWARD_SLASH) {
            fromEnd--;
        }
        const fromLen = fromEnd - fromStart;
        let toStart = 0;
        while (toStart < to.length && to.charCodeAt(toStart) === CHAR_BACKWARD_SLASH) {
            toStart++;
        }
        let toEnd = to.length;
        while (toEnd - 1 > toStart && to.charCodeAt(toEnd - 1) === CHAR_BACKWARD_SLASH) {
            toEnd--;
        }
        const toLen = toEnd - toStart;
        const length = fromLen < toLen ? fromLen : toLen;
        let lastCommonSep = -1;
        let i = 0;
        for (; i < length; i++) {
            const fromCode = from.charCodeAt(fromStart + i);
            if (fromCode !== to.charCodeAt(toStart + i)) {
                break;
            }
            else if (fromCode === CHAR_BACKWARD_SLASH) {
                lastCommonSep = i;
            }
        }
        if (i !== length) {
            if (lastCommonSep === -1) {
                return toOrig;
            }
        }
        else {
            if (toLen > length) {
                if (to.charCodeAt(toStart + i) === CHAR_BACKWARD_SLASH) {
                    return toOrig.slice(toStart + i + 1);
                }
                if (i === 2) {
                    return toOrig.slice(toStart + i);
                }
            }
            if (fromLen > length) {
                if (from.charCodeAt(fromStart + i) === CHAR_BACKWARD_SLASH) {
                    lastCommonSep = i;
                }
                else if (i === 2) {
                    lastCommonSep = 3;
                }
            }
            if (lastCommonSep === -1) {
                lastCommonSep = 0;
            }
        }
        let out = '';
        for (i = fromStart + lastCommonSep + 1; i <= fromEnd; ++i) {
            if (i === fromEnd || from.charCodeAt(i) === CHAR_BACKWARD_SLASH) {
                out += out.length === 0 ? '..' : '\\..';
            }
        }
        toStart += lastCommonSep;
        if (out.length > 0) {
            return `${out}${toOrig.slice(toStart, toEnd)}`;
        }
        if (toOrig.charCodeAt(toStart) === CHAR_BACKWARD_SLASH) {
            ++toStart;
        }
        return toOrig.slice(toStart, toEnd);
    },
    toNamespacedPath(path) {
        if (typeof path !== 'string') {
            return path;
        }
        if (path.length === 0) {
            return '';
        }
        const resolvedPath = exports.win32.resolve(path);
        if (resolvedPath.length <= 2) {
            return path;
        }
        if (resolvedPath.charCodeAt(0) === CHAR_BACKWARD_SLASH) {
            if (resolvedPath.charCodeAt(1) === CHAR_BACKWARD_SLASH) {
                const code = resolvedPath.charCodeAt(2);
                if (code !== CHAR_QUESTION_MARK && code !== CHAR_DOT) {
                    return `\\\\?\\UNC\\${resolvedPath.slice(2)}`;
                }
            }
        }
        else if (isWindowsDeviceRoot(resolvedPath.charCodeAt(0)) &&
            resolvedPath.charCodeAt(1) === CHAR_COLON &&
            resolvedPath.charCodeAt(2) === CHAR_BACKWARD_SLASH) {
            return `\\\\?\\${resolvedPath}`;
        }
        return path;
    },
    dirname(path) {
        validateString(path, 'path');
        const len = path.length;
        if (len === 0) {
            return '.';
        }
        let rootEnd = -1;
        let offset = 0;
        const code = path.charCodeAt(0);
        if (len === 1) {
            return isPathSeparator(code) ? path : '.';
        }
        if (isPathSeparator(code)) {
            rootEnd = offset = 1;
            if (isPathSeparator(path.charCodeAt(1))) {
                let j = 2;
                let last = j;
                while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                    j++;
                }
                if (j < len && j !== last) {
                    last = j;
                    while (j < len && isPathSeparator(path.charCodeAt(j))) {
                        j++;
                    }
                    if (j < len && j !== last) {
                        last = j;
                        while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                            j++;
                        }
                        if (j === len) {
                            return path;
                        }
                        if (j !== last) {
                            rootEnd = offset = j + 1;
                        }
                    }
                }
            }
        }
        else if (isWindowsDeviceRoot(code) && path.charCodeAt(1) === CHAR_COLON) {
            rootEnd = len > 2 && isPathSeparator(path.charCodeAt(2)) ? 3 : 2;
            offset = rootEnd;
        }
        let end = -1;
        let matchedSlash = true;
        for (let i = len - 1; i >= offset; --i) {
            if (isPathSeparator(path.charCodeAt(i))) {
                if (!matchedSlash) {
                    end = i;
                    break;
                }
            }
            else {
                matchedSlash = false;
            }
        }
        if (end === -1) {
            if (rootEnd === -1) {
                return '.';
            }
            end = rootEnd;
        }
        return path.slice(0, end);
    },
    basename(path, ext) {
        if (ext !== undefined) {
            validateString(ext, 'ext');
        }
        validateString(path, 'path');
        let start = 0;
        let end = -1;
        let matchedSlash = true;
        let i;
        if (path.length >= 2 && isWindowsDeviceRoot(path.charCodeAt(0)) && path.charCodeAt(1) === CHAR_COLON) {
            start = 2;
        }
        if (ext !== undefined && ext.length > 0 && ext.length <= path.length) {
            if (ext === path) {
                return '';
            }
            let extIdx = ext.length - 1;
            let firstNonSlashEnd = -1;
            for (i = path.length - 1; i >= start; --i) {
                const code = path.charCodeAt(i);
                if (isPathSeparator(code)) {
                    if (!matchedSlash) {
                        start = i + 1;
                        break;
                    }
                }
                else {
                    if (firstNonSlashEnd === -1) {
                        matchedSlash = false;
                        firstNonSlashEnd = i + 1;
                    }
                    if (extIdx >= 0) {
                        if (code === ext.charCodeAt(extIdx)) {
                            if (--extIdx === -1) {
                                end = i;
                            }
                        }
                        else {
                            extIdx = -1;
                            end = firstNonSlashEnd;
                        }
                    }
                }
            }
            if (start === end) {
                end = firstNonSlashEnd;
            }
            else if (end === -1) {
                end = path.length;
            }
            return path.slice(start, end);
        }
        for (i = path.length - 1; i >= start; --i) {
            if (isPathSeparator(path.charCodeAt(i))) {
                if (!matchedSlash) {
                    start = i + 1;
                    break;
                }
            }
            else if (end === -1) {
                matchedSlash = false;
                end = i + 1;
            }
        }
        if (end === -1) {
            return '';
        }
        return path.slice(start, end);
    },
    extname(path) {
        validateString(path, 'path');
        let start = 0;
        let startDot = -1;
        let startPart = 0;
        let end = -1;
        let matchedSlash = true;
        let preDotState = 0;
        if (path.length >= 2 && path.charCodeAt(1) === CHAR_COLON && isWindowsDeviceRoot(path.charCodeAt(0))) {
            start = startPart = 2;
        }
        for (let i = path.length - 1; i >= start; --i) {
            const code = path.charCodeAt(i);
            if (isPathSeparator(code)) {
                if (!matchedSlash) {
                    startPart = i + 1;
                    break;
                }
                continue;
            }
            if (end === -1) {
                matchedSlash = false;
                end = i + 1;
            }
            if (code === CHAR_DOT) {
                if (startDot === -1) {
                    startDot = i;
                }
                else if (preDotState !== 1) {
                    preDotState = 1;
                }
            }
            else if (startDot !== -1) {
                preDotState = -1;
            }
        }
        if (startDot === -1 ||
            end === -1 ||
            preDotState === 0 ||
            (preDotState === 1 && startDot === end - 1 && startDot === startPart + 1)) {
            return '';
        }
        return path.slice(startDot, end);
    },
    format: _format.bind(null, '\\'),
    parse(path) {
        validateString(path, 'path');
        const ret = { root: '', dir: '', base: '', ext: '', name: '' };
        if (path.length === 0) {
            return ret;
        }
        const len = path.length;
        let rootEnd = 0;
        let code = path.charCodeAt(0);
        if (len === 1) {
            if (isPathSeparator(code)) {
                ret.root = ret.dir = path;
                return ret;
            }
            ret.base = ret.name = path;
            return ret;
        }
        if (isPathSeparator(code)) {
            rootEnd = 1;
            if (isPathSeparator(path.charCodeAt(1))) {
                let j = 2;
                let last = j;
                while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                    j++;
                }
                if (j < len && j !== last) {
                    last = j;
                    while (j < len && isPathSeparator(path.charCodeAt(j))) {
                        j++;
                    }
                    if (j < len && j !== last) {
                        last = j;
                        while (j < len && !isPathSeparator(path.charCodeAt(j))) {
                            j++;
                        }
                        if (j === len) {
                            rootEnd = j;
                        }
                        else if (j !== last) {
                            rootEnd = j + 1;
                        }
                    }
                }
            }
        }
        else if (isWindowsDeviceRoot(code) && path.charCodeAt(1) === CHAR_COLON) {
            if (len <= 2) {
                ret.root = ret.dir = path;
                return ret;
            }
            rootEnd = 2;
            if (isPathSeparator(path.charCodeAt(2))) {
                if (len === 3) {
                    ret.root = ret.dir = path;
                    return ret;
                }
                rootEnd = 3;
            }
        }
        if (rootEnd > 0) {
            ret.root = path.slice(0, rootEnd);
        }
        let startDot = -1;
        let startPart = rootEnd;
        let end = -1;
        let matchedSlash = true;
        let i = path.length - 1;
        let preDotState = 0;
        for (; i >= rootEnd; --i) {
            code = path.charCodeAt(i);
            if (isPathSeparator(code)) {
                if (!matchedSlash) {
                    startPart = i + 1;
                    break;
                }
                continue;
            }
            if (end === -1) {
                matchedSlash = false;
                end = i + 1;
            }
            if (code === CHAR_DOT) {
                if (startDot === -1) {
                    startDot = i;
                }
                else if (preDotState !== 1) {
                    preDotState = 1;
                }
            }
            else if (startDot !== -1) {
                preDotState = -1;
            }
        }
        if (end !== -1) {
            if (startDot === -1 ||
                preDotState === 0 ||
                (preDotState === 1 && startDot === end - 1 && startDot === startPart + 1)) {
                ret.base = ret.name = path.slice(startPart, end);
            }
            else {
                ret.name = path.slice(startPart, startDot);
                ret.base = path.slice(startPart, end);
                ret.ext = path.slice(startDot, end);
            }
        }
        if (startPart > 0 && startPart !== rootEnd) {
            ret.dir = path.slice(0, startPart - 1);
        }
        else {
            ret.dir = ret.root;
        }
        return ret;
    },
    sep: '\\',
    delimiter: ';',
    win32: null,
    posix: null
};
exports.posix = {
    resolve(...pathSegments) {
        let resolvedPath = '';
        let resolvedAbsolute = false;
        for (let i = pathSegments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
            const path = i >= 0 ? pathSegments[i] : process.cwd();
            validateString(path, 'path');
            if (path.length === 0) {
                continue;
            }
            resolvedPath = `${path}/${resolvedPath}`;
            resolvedAbsolute = path.charCodeAt(0) === CHAR_FORWARD_SLASH;
        }
        resolvedPath = normalizeString(resolvedPath, !resolvedAbsolute, '/', isPosixPathSeparator);
        if (resolvedAbsolute) {
            return `/${resolvedPath}`;
        }
        return resolvedPath.length > 0 ? resolvedPath : '.';
    },
    normalize(path) {
        validateString(path, 'path');
        if (path.length === 0) {
            return '.';
        }
        const isAbsolute = path.charCodeAt(0) === CHAR_FORWARD_SLASH;
        const trailingSeparator = path.charCodeAt(path.length - 1) === CHAR_FORWARD_SLASH;
        path = normalizeString(path, !isAbsolute, '/', isPosixPathSeparator);
        if (path.length === 0) {
            if (isAbsolute) {
                return '/';
            }
            return trailingSeparator ? './' : '.';
        }
        if (trailingSeparator) {
            path += '/';
        }
        return isAbsolute ? `/${path}` : path;
    },
    isAbsolute(path) {
        validateString(path, 'path');
        return path.length > 0 && path.charCodeAt(0) === CHAR_FORWARD_SLASH;
    },
    join(...paths) {
        if (paths.length === 0) {
            return '.';
        }
        let joined;
        for (let i = 0; i < paths.length; ++i) {
            const arg = paths[i];
            validateString(arg, 'path');
            if (arg.length > 0) {
                if (joined === undefined) {
                    joined = arg;
                }
                else {
                    joined += `/${arg}`;
                }
            }
        }
        if (joined === undefined) {
            return '.';
        }
        return exports.posix.normalize(joined);
    },
    relative(from, to) {
        validateString(from, 'from');
        validateString(to, 'to');
        if (from === to) {
            return '';
        }
        from = exports.posix.resolve(from);
        to = exports.posix.resolve(to);
        if (from === to) {
            return '';
        }
        const fromStart = 1;
        const fromEnd = from.length;
        const fromLen = fromEnd - fromStart;
        const toStart = 1;
        const toLen = to.length - toStart;
        const length = fromLen < toLen ? fromLen : toLen;
        let lastCommonSep = -1;
        let i = 0;
        for (; i < length; i++) {
            const fromCode = from.charCodeAt(fromStart + i);
            if (fromCode !== to.charCodeAt(toStart + i)) {
                break;
            }
            else if (fromCode === CHAR_FORWARD_SLASH) {
                lastCommonSep = i;
            }
        }
        if (i === length) {
            if (toLen > length) {
                if (to.charCodeAt(toStart + i) === CHAR_FORWARD_SLASH) {
                    return to.slice(toStart + i + 1);
                }
                if (i === 0) {
                    return to.slice(toStart + i);
                }
            }
            else if (fromLen > length) {
                if (from.charCodeAt(fromStart + i) === CHAR_FORWARD_SLASH) {
                    lastCommonSep = i;
                }
                else if (i === 0) {
                    lastCommonSep = 0;
                }
            }
        }
        let out = '';
        for (i = fromStart + lastCommonSep + 1; i <= fromEnd; ++i) {
            if (i === fromEnd || from.charCodeAt(i) === CHAR_FORWARD_SLASH) {
                out += out.length === 0 ? '..' : '/..';
            }
        }
        return `${out}${to.slice(toStart + lastCommonSep)}`;
    },
    toNamespacedPath(path) {
        return path;
    },
    dirname(path) {
        validateString(path, 'path');
        if (path.length === 0) {
            return '.';
        }
        const hasRoot = path.charCodeAt(0) === CHAR_FORWARD_SLASH;
        let end = -1;
        let matchedSlash = true;
        for (let i = path.length - 1; i >= 1; --i) {
            if (path.charCodeAt(i) === CHAR_FORWARD_SLASH) {
                if (!matchedSlash) {
                    end = i;
                    break;
                }
            }
            else {
                matchedSlash = false;
            }
        }
        if (end === -1) {
            return hasRoot ? '/' : '.';
        }
        if (hasRoot && end === 1) {
            return '//';
        }
        return path.slice(0, end);
    },
    basename(path, ext) {
        if (ext !== undefined) {
            validateString(ext, 'ext');
        }
        validateString(path, 'path');
        let start = 0;
        let end = -1;
        let matchedSlash = true;
        let i;
        if (ext !== undefined && ext.length > 0 && ext.length <= path.length) {
            if (ext === path) {
                return '';
            }
            let extIdx = ext.length - 1;
            let firstNonSlashEnd = -1;
            for (i = path.length - 1; i >= 0; --i) {
                const code = path.charCodeAt(i);
                if (code === CHAR_FORWARD_SLASH) {
                    if (!matchedSlash) {
                        start = i + 1;
                        break;
                    }
                }
                else {
                    if (firstNonSlashEnd === -1) {
                        matchedSlash = false;
                        firstNonSlashEnd = i + 1;
                    }
                    if (extIdx >= 0) {
                        if (code === ext.charCodeAt(extIdx)) {
                            if (--extIdx === -1) {
                                end = i;
                            }
                        }
                        else {
                            extIdx = -1;
                            end = firstNonSlashEnd;
                        }
                    }
                }
            }
            if (start === end) {
                end = firstNonSlashEnd;
            }
            else if (end === -1) {
                end = path.length;
            }
            return path.slice(start, end);
        }
        for (i = path.length - 1; i >= 0; --i) {
            if (path.charCodeAt(i) === CHAR_FORWARD_SLASH) {
                if (!matchedSlash) {
                    start = i + 1;
                    break;
                }
            }
            else if (end === -1) {
                matchedSlash = false;
                end = i + 1;
            }
        }
        if (end === -1) {
            return '';
        }
        return path.slice(start, end);
    },
    extname(path) {
        validateString(path, 'path');
        let startDot = -1;
        let startPart = 0;
        let end = -1;
        let matchedSlash = true;
        let preDotState = 0;
        for (let i = path.length - 1; i >= 0; --i) {
            const code = path.charCodeAt(i);
            if (code === CHAR_FORWARD_SLASH) {
                if (!matchedSlash) {
                    startPart = i + 1;
                    break;
                }
                continue;
            }
            if (end === -1) {
                matchedSlash = false;
                end = i + 1;
            }
            if (code === CHAR_DOT) {
                if (startDot === -1) {
                    startDot = i;
                }
                else if (preDotState !== 1) {
                    preDotState = 1;
                }
            }
            else if (startDot !== -1) {
                preDotState = -1;
            }
        }
        if (startDot === -1 ||
            end === -1 ||
            preDotState === 0 ||
            (preDotState === 1 && startDot === end - 1 && startDot === startPart + 1)) {
            return '';
        }
        return path.slice(startDot, end);
    },
    format: _format.bind(null, '/'),
    parse(path) {
        validateString(path, 'path');
        const ret = { root: '', dir: '', base: '', ext: '', name: '' };
        if (path.length === 0) {
            return ret;
        }
        const isAbsolute = path.charCodeAt(0) === CHAR_FORWARD_SLASH;
        let start;
        if (isAbsolute) {
            ret.root = '/';
            start = 1;
        }
        else {
            start = 0;
        }
        let startDot = -1;
        let startPart = 0;
        let end = -1;
        let matchedSlash = true;
        let i = path.length - 1;
        let preDotState = 0;
        for (; i >= start; --i) {
            const code = path.charCodeAt(i);
            if (code === CHAR_FORWARD_SLASH) {
                if (!matchedSlash) {
                    startPart = i + 1;
                    break;
                }
                continue;
            }
            if (end === -1) {
                matchedSlash = false;
                end = i + 1;
            }
            if (code === CHAR_DOT) {
                if (startDot === -1) {
                    startDot = i;
                }
                else if (preDotState !== 1) {
                    preDotState = 1;
                }
            }
            else if (startDot !== -1) {
                preDotState = -1;
            }
        }
        if (end !== -1) {
            const start = startPart === 0 && isAbsolute ? 1 : startPart;
            if (startDot === -1 ||
                preDotState === 0 ||
                (preDotState === 1 && startDot === end - 1 && startDot === startPart + 1)) {
                ret.base = ret.name = path.slice(start, end);
            }
            else {
                ret.name = path.slice(start, startDot);
                ret.base = path.slice(start, end);
                ret.ext = path.slice(startDot, end);
            }
        }
        if (startPart > 0) {
            ret.dir = path.slice(0, startPart - 1);
        }
        else if (isAbsolute) {
            ret.dir = '/';
        }
        return ret;
    },
    sep: '/',
    delimiter: ':',
    win32: null,
    posix: null
};
exports.posix.win32 = exports.win32.win32 = exports.win32;
exports.posix.posix = exports.win32.posix = exports.posix;
exports.normalize = process.platform === 'win32' ? exports.win32.normalize : exports.posix.normalize;
exports.isAbsolute = process.platform === 'win32' ? exports.win32.isAbsolute : exports.posix.isAbsolute;
exports.join = process.platform === 'win32' ? exports.win32.join : exports.posix.join;
exports.resolve = process.platform === 'win32' ? exports.win32.resolve : exports.posix.resolve;
exports.relative = process.platform === 'win32' ? exports.win32.relative : exports.posix.relative;
exports.dirname = process.platform === 'win32' ? exports.win32.dirname : exports.posix.dirname;
exports.basename = process.platform === 'win32' ? exports.win32.basename : exports.posix.basename;
exports.extname = process.platform === 'win32' ? exports.win32.extname : exports.posix.extname;
exports.format = process.platform === 'win32' ? exports.win32.format : exports.posix.format;
exports.parse = process.platform === 'win32' ? exports.win32.parse : exports.posix.parse;
exports.toNamespacedPath = process.platform === 'win32' ? exports.win32.toNamespacedPath : exports.posix.toNamespacedPath;
exports.sep = process.platform === 'win32' ? exports.win32.sep : exports.posix.sep;
exports.delimiter = process.platform === 'win32' ? exports.win32.delimiter : exports.posix.delimiter;


/***/ }),
/* 13 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";
/* provided dependency */ var process = __webpack_require__(15);

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.arch = exports.platform = exports.env = exports.cwd = void 0;
const platform_1 = __webpack_require__(14);
let safeProcess;
if (typeof platform_1.globals.vscode !== 'undefined' && typeof platform_1.globals.vscode.process !== 'undefined') {
    const sandboxProcess = platform_1.globals.vscode.process;
    safeProcess = {
        get platform() {
            return sandboxProcess.platform;
        },
        get arch() {
            return sandboxProcess.arch;
        },
        get env() {
            return sandboxProcess.env;
        },
        cwd() {
            return sandboxProcess.cwd();
        }
    };
}
else if (true) {
    safeProcess = {
        get platform() {
            return "web";
        },
        get arch() {
            return process.arch;
        },
        get env() {
            return process.env;
        },
        cwd() {
            return process.env['VSCODE_CWD'] || process.cwd();
        }
    };
}
else {}
exports.cwd = safeProcess.cwd;
exports.env = safeProcess.env;
exports.platform = safeProcess.platform;
exports.arch = safeProcess.arch;


/***/ }),
/* 14 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";
/* provided dependency */ var process = __webpack_require__(15);

var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.isAndroid = exports.isEdge = exports.isSafari = exports.isFirefox = exports.isChrome = exports.isLittleEndian = exports.OS = exports.setTimeout0 = exports.translationsConfigFile = exports.locale = exports.Language = exports.language = exports.userAgent = exports.platform = exports.isCI = exports.isIOS = exports.isWebWorker = exports.isWeb = exports.isElectron = exports.isNative = exports.isLinuxSnap = exports.isLinux = exports.isMacintosh = exports.isWindows = exports.PlatformToString = exports.isElectronSandboxed = exports.globals = void 0;
const LANGUAGE_DEFAULT = 'en';
let _isWindows = false;
let _isMacintosh = false;
let _isLinux = false;
let _isLinuxSnap = false;
let _isNative = false;
let _isWeb = false;
let _isElectron = false;
let _isIOS = false;
let _isCI = false;
let _locale = undefined;
let _language = LANGUAGE_DEFAULT;
let _translationsConfigFile = undefined;
let _userAgent = undefined;
exports.globals = typeof self === 'object' ? self : typeof __webpack_require__.g === 'object' ? __webpack_require__.g : {};
let nodeProcess = undefined;
if (typeof exports.globals.vscode !== 'undefined' && typeof exports.globals.vscode.process !== 'undefined') {
    nodeProcess = exports.globals.vscode.process;
}
else if (true) {
    nodeProcess = process;
}
const isElectronProcess = typeof ((_a = nodeProcess === null || nodeProcess === void 0 ? void 0 : nodeProcess.versions) === null || _a === void 0 ? void 0 : _a.electron) === 'string';
const isElectronRenderer = isElectronProcess && (nodeProcess === null || nodeProcess === void 0 ? void 0 : nodeProcess.type) === 'renderer';
exports.isElectronSandboxed = isElectronRenderer && (nodeProcess === null || nodeProcess === void 0 ? void 0 : nodeProcess.sandboxed);
if (typeof navigator === 'object' && !isElectronRenderer) {
    _userAgent = navigator.userAgent;
    _isWindows = _userAgent.indexOf('Windows') >= 0;
    _isMacintosh = _userAgent.indexOf('Macintosh') >= 0;
    _isIOS =
        (_userAgent.indexOf('Macintosh') >= 0 ||
            _userAgent.indexOf('iPad') >= 0 ||
            _userAgent.indexOf('iPhone') >= 0) &&
            !!navigator.maxTouchPoints &&
            navigator.maxTouchPoints > 0;
    _isLinux = _userAgent.indexOf('Linux') >= 0;
    _isWeb = true;
    _locale = navigator.language;
    _language = _locale;
}
else if (typeof nodeProcess === 'object') {
    _isWindows = nodeProcess.platform === 'win32';
    _isMacintosh = nodeProcess.platform === 'darwin';
    _isLinux = nodeProcess.platform === 'linux';
    _isLinuxSnap = _isLinux && !!nodeProcess.env['SNAP'] && !!nodeProcess.env['SNAP_REVISION'];
    _isElectron = isElectronProcess;
    _isCI = !!nodeProcess.env['CI'] || !!nodeProcess.env['BUILD_ARTIFACTSTAGINGDIRECTORY'];
    _locale = LANGUAGE_DEFAULT;
    _language = LANGUAGE_DEFAULT;
    const rawNlsConfig = nodeProcess.env['VSCODE_NLS_CONFIG'];
    if (rawNlsConfig) {
        try {
            const nlsConfig = JSON.parse(rawNlsConfig);
            const resolved = nlsConfig.availableLanguages['*'];
            _locale = nlsConfig.locale;
            _language = resolved ? resolved : LANGUAGE_DEFAULT;
            _translationsConfigFile = nlsConfig._translationsConfigFile;
        }
        catch (e) { }
    }
    _isNative = true;
}
else {
    console.error('Unable to resolve platform.');
}
function PlatformToString(platform) {
    switch (platform) {
        case 0:
            return 'Web';
        case 1:
            return 'Mac';
        case 2:
            return 'Linux';
        case 3:
            return 'Windows';
    }
}
exports.PlatformToString = PlatformToString;
let _platform = 0;
if (_isMacintosh) {
    _platform = 1;
}
else if (_isWindows) {
    _platform = 3;
}
else if (_isLinux) {
    _platform = 2;
}
exports.isWindows = _isWindows;
exports.isMacintosh = _isMacintosh;
exports.isLinux = _isLinux;
exports.isLinuxSnap = _isLinuxSnap;
exports.isNative = _isNative;
exports.isElectron = _isElectron;
exports.isWeb = _isWeb;
exports.isWebWorker = _isWeb && typeof exports.globals.importScripts === 'function';
exports.isIOS = _isIOS;
exports.isCI = _isCI;
exports.platform = _platform;
exports.userAgent = _userAgent;
exports.language = _language;
var Language;
(function (Language) {
    function value() {
        return exports.language;
    }
    Language.value = value;
    function isDefaultVariant() {
        if (exports.language.length === 2) {
            return exports.language === 'en';
        }
        else if (exports.language.length >= 3) {
            return exports.language[0] === 'e' && exports.language[1] === 'n' && exports.language[2] === '-';
        }
        else {
            return false;
        }
    }
    Language.isDefaultVariant = isDefaultVariant;
    function isDefault() {
        return exports.language === 'en';
    }
    Language.isDefault = isDefault;
})(Language = exports.Language || (exports.Language = {}));
exports.locale = _locale;
exports.translationsConfigFile = _translationsConfigFile;
exports.setTimeout0 = (() => {
    if (typeof exports.globals.postMessage === 'function' && !exports.globals.importScripts) {
        let pending = [];
        exports.globals.addEventListener('message', (e) => {
            if (e.data && e.data.vscodeScheduleAsyncWork) {
                for (let i = 0, len = pending.length; i < len; i++) {
                    const candidate = pending[i];
                    if (candidate.id === e.data.vscodeScheduleAsyncWork) {
                        pending.splice(i, 1);
                        candidate.callback();
                        return;
                    }
                }
            }
        });
        let lastId = 0;
        return (callback) => {
            const myId = ++lastId;
            pending.push({
                id: myId,
                callback: callback
            });
            exports.globals.postMessage({ vscodeScheduleAsyncWork: myId }, '*');
        };
    }
    return (callback) => setTimeout(callback);
})();
exports.OS = _isMacintosh || _isIOS ? 2 : _isWindows ? 1 : 3;
let _isLittleEndian = true;
let _isLittleEndianComputed = false;
function isLittleEndian() {
    if (!_isLittleEndianComputed) {
        _isLittleEndianComputed = true;
        const test = new Uint8Array(2);
        test[0] = 1;
        test[1] = 2;
        const view = new Uint16Array(test.buffer);
        _isLittleEndian = view[0] === (2 << 8) + 1;
    }
    return _isLittleEndian;
}
exports.isLittleEndian = isLittleEndian;
exports.isChrome = !!(exports.userAgent && exports.userAgent.indexOf('Chrome') >= 0);
exports.isFirefox = !!(exports.userAgent && exports.userAgent.indexOf('Firefox') >= 0);
exports.isSafari = !!(!exports.isChrome && exports.userAgent && exports.userAgent.indexOf('Safari') >= 0);
exports.isEdge = !!(exports.userAgent && exports.userAgent.indexOf('Edg/') >= 0);
exports.isAndroid = !!(exports.userAgent && exports.userAgent.indexOf('Android') >= 0);


/***/ }),
/* 15 */
/***/ ((module) => {

// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };


/***/ }),
/* 16 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.getPythonEnvironmentName = exports.getEnvironmentType = exports.getEnvironmentVersionFromUri = exports.getCachedEnvironmentTypeFromUri = exports.getEnvironmentTypeFromUri = exports.EnvironmentType = void 0;
const path = __webpack_require__(12);
var EnvironmentType;
(function (EnvironmentType) {
    EnvironmentType["Unknown"] = "Unknown";
    EnvironmentType["Conda"] = "Conda";
    EnvironmentType["VirtualEnv"] = "VirtualEnv";
    EnvironmentType["Pipenv"] = "PipEnv";
    EnvironmentType["Pyenv"] = "Pyenv";
    EnvironmentType["Venv"] = "Venv";
    EnvironmentType["WindowsStore"] = "WindowsStore";
    EnvironmentType["Poetry"] = "Poetry";
    EnvironmentType["VirtualEnvWrapper"] = "VirtualEnvWrapper";
    EnvironmentType["Global"] = "Global";
    EnvironmentType["System"] = "System";
})(EnvironmentType = exports.EnvironmentType || (exports.EnvironmentType = {}));
const KnownEnvironmentToolsToEnvironmentTypeMapping = new Map([
    ['Conda', EnvironmentType.Conda],
    ['Pipenv', EnvironmentType.Pipenv],
    ['Poetry', EnvironmentType.Poetry],
    ['Pyenv', EnvironmentType.Pyenv],
    ['Unknown', EnvironmentType.Unknown],
    ['Venv', EnvironmentType.Venv],
    ['VirtualEnv', EnvironmentType.VirtualEnv],
    ['VirtualEnvWrapper', EnvironmentType.VirtualEnvWrapper]
]);
async function getEnvironmentTypeFromUri(uri, api) {
    if (!uri) {
        return;
    }
    const env = api.environments.known.find((e) => { var _a, _b; return ((_b = (_a = e.executable.uri) === null || _a === void 0 ? void 0 : _a.fsPath) === null || _b === void 0 ? void 0 : _b.toLowerCase()) === uri.fsPath.toLowerCase(); });
    if (env) {
        return getEnvironmentType(env);
    }
    const resolved = await api.environments.resolveEnvironment(uri.fsPath);
    if (!resolved) {
        return;
    }
    return getEnvironmentType(resolved);
}
exports.getEnvironmentTypeFromUri = getEnvironmentTypeFromUri;
function getCachedEnvironmentTypeFromUri(uri, api) {
    if (!uri) {
        return;
    }
    const env = api.environments.known.find((e) => { var _a, _b; return ((_b = (_a = e.executable.uri) === null || _a === void 0 ? void 0 : _a.fsPath) === null || _b === void 0 ? void 0 : _b.toLowerCase()) === uri.fsPath.toLowerCase(); });
    if (env) {
        return getEnvironmentType(env);
    }
}
exports.getCachedEnvironmentTypeFromUri = getCachedEnvironmentTypeFromUri;
async function getEnvironmentVersionFromUri(uri, api) {
    if (!uri) {
        return;
    }
    const env = api.environments.known.find((e) => { var _a, _b; return ((_b = (_a = e.executable.uri) === null || _a === void 0 ? void 0 : _a.fsPath) === null || _b === void 0 ? void 0 : _b.toLowerCase()) === uri.fsPath.toLowerCase(); });
    if (env) {
        return env.version;
    }
    const resolved = await api.environments.resolveEnvironment(uri.fsPath);
    return resolved === null || resolved === void 0 ? void 0 : resolved.version;
}
exports.getEnvironmentVersionFromUri = getEnvironmentVersionFromUri;
function getEnvironmentType({ tools }) {
    tools = tools.map((tool) => tool.toLowerCase());
    for (const tool of tools) {
        if (tool === EnvironmentType.Conda.toLowerCase()) {
            return EnvironmentType.Conda;
        }
        if (tool === EnvironmentType.Venv.toLowerCase()) {
            return EnvironmentType.Venv;
        }
        if (tool === EnvironmentType.VirtualEnv.toLowerCase()) {
            return EnvironmentType.VirtualEnv;
        }
        if (tool === EnvironmentType.VirtualEnvWrapper.toLowerCase()) {
            return EnvironmentType.VirtualEnvWrapper;
        }
        if (tool === EnvironmentType.Poetry.toLowerCase()) {
            return EnvironmentType.Poetry;
        }
        if (tool === EnvironmentType.Pipenv.toLowerCase()) {
            return EnvironmentType.Pipenv;
        }
        if (tool === EnvironmentType.Pyenv.toLowerCase()) {
            return EnvironmentType.Pyenv;
        }
        if (KnownEnvironmentToolsToEnvironmentTypeMapping.has(tool)) {
            return KnownEnvironmentToolsToEnvironmentTypeMapping.get(tool);
        }
    }
    return EnvironmentType.Unknown;
}
exports.getEnvironmentType = getEnvironmentType;
async function getPythonEnvironmentName(uri, api) {
    var _a, _b, _c, _d;
    if (!uri) {
        return '';
    }
    const env = api.environments.known.find((e) => { var _a, _b; return ((_b = (_a = e.executable.uri) === null || _a === void 0 ? void 0 : _a.fsPath) === null || _b === void 0 ? void 0 : _b.toLowerCase()) === uri.fsPath.toLowerCase(); });
    if (env) {
        if ((_a = env.environment) === null || _a === void 0 ? void 0 : _a.name) {
            return env.environment.name;
        }
        if (getEnvironmentType(env) === EnvironmentType.Conda) {
            if ((_b = env.environment) === null || _b === void 0 ? void 0 : _b.folderUri) {
                return path.basename(env.environment.folderUri.fsPath);
            }
        }
    }
    const resolved = await api.environments.resolveEnvironment(uri.fsPath);
    if (resolved) {
        if ((_c = resolved.environment) === null || _c === void 0 ? void 0 : _c.name) {
            return resolved.environment.name;
        }
        if (getEnvironmentType(resolved) === EnvironmentType.Conda) {
            if ((_d = resolved.environment) === null || _d === void 0 ? void 0 : _d.folderUri) {
                return path.basename(resolved.environment.folderUri.fsPath);
            }
        }
    }
}
exports.getPythonEnvironmentName = getPythonEnvironmentName;


/***/ }),
/* 17 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.initializeKnownLanguages = exports.getLanguageExtension = exports.getDisplayPath = void 0;
const vscode_1 = __webpack_require__(1);
const path = __webpack_require__(12);
const languages_1 = __webpack_require__(18);
const untildify = __webpack_require__(19);
const homePath = untildify('~');
function getDisplayPath(filename, workspaceFolders = []) {
    const relativeToHome = getDisplayPathImpl(filename);
    const relativeToWorkspaceFolders = workspaceFolders.map((folder) => getDisplayPathImpl(filename, folder.uri.fsPath));
    let bestDisplayPath = relativeToHome;
    [relativeToHome, ...relativeToWorkspaceFolders].forEach((relativePath) => {
        if (relativePath.length < bestDisplayPath.length) {
            bestDisplayPath = relativePath;
        }
    });
    return bestDisplayPath;
}
exports.getDisplayPath = getDisplayPath;
function getDisplayPathImpl(filename, cwd) {
    let file = '';
    if (typeof filename === 'string') {
        file = filename;
    }
    else if (!filename) {
        file = '';
    }
    else if (filename.scheme === 'file') {
        file = filename.fsPath;
    }
    else {
        file = filename.toString();
    }
    if (!file) {
        return '';
    }
    else if (cwd && file.startsWith(cwd)) {
        const relativePath = `.${path.sep}${path.relative(cwd, file)}`;
        return relativePath === file || relativePath.includes(cwd)
            ? `.${path.sep}${file.substring(file.indexOf(cwd) + cwd.length)}`
            : relativePath;
    }
    else if (file.startsWith(homePath)) {
        return `~${path.sep}${path.relative(homePath, file)}`;
    }
    else {
        return file;
    }
}
const knownVSCodeLanguages = new Set();
function getLanguageExtension(language) {
    if (!language) {
        return '.ipynb';
    }
    const aliases = languages_1.languageAliases.get(language.toLowerCase()) || [language];
    if (!aliases.some((alias) => knownVSCodeLanguages.has(alias))) {
        return '.ipynb';
    }
    for (const alias of aliases) {
        if (languages_1.languages.has(alias)) {
            return languages_1.languages.get(alias)[0];
        }
    }
    return '.ipynb';
}
exports.getLanguageExtension = getLanguageExtension;
async function initializeKnownLanguages() {
    const langs = await vscode_1.languages.getLanguages();
    langs.forEach((language) => knownVSCodeLanguages.add(language.toLowerCase()));
}
exports.initializeKnownLanguages = initializeKnownLanguages;


/***/ }),
/* 18 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.languages = exports.languageAliases = void 0;
const _languageAliases = {
    bat: new Set(['batch']),
    berry: new Set(['be']),
    clojure: new Set(['clj']),
    csharp: new Set(['c#']),
    fsharp: new Set(['f#']),
    handlebars: new Set(['hbs']),
    javascript: new Set(['js']),
    jssm: new Set(['fsl']),
    make: new Set(['makefile']),
    markdown: new Set(['md']),
    'objective-c': new Set(['objc']),
    powershell: new Set(['ps', 'ps1']),
    pug: new Set(['jade']),
    python: new Set(['py']),
    raku: new Set(['perl6']),
    ruby: new Set(['rb']),
    rust: new Set(['rs']),
    'html-ruby-erb': new Set(['erb']),
    shaderlab: new Set(['shader']),
    shellscript: new Set(['shell', 'bash', 'sh', 'zsh']),
    stylus: new Set(['styl']),
    typescript: new Set(['ts']),
    vb: new Set(['cmd']),
    viml: new Set(['vim', 'vimscript']),
    wenyan: new Set(['文言']),
    codeql: new Set(['ql'])
};
exports.languageAliases = new Map();
Object.getOwnPropertyNames(_languageAliases).forEach((key) => {
    const currentLanguages = exports.languageAliases.get(key) || [];
    currentLanguages.push(key);
    const newLanguages = _languageAliases[key];
    Array.from(newLanguages.values()).forEach((item) => currentLanguages.push(item));
    const allAliases = Array.from(new Set(currentLanguages));
    exports.languageAliases.set(key, allAliases);
    currentLanguages.forEach((item) => exports.languageAliases.set(item, allAliases));
});
const _languages = [
    {
        name: 'ABAP',
        type: 'programming',
        extensions: ['.abap']
    },
    {
        name: 'AGS Script',
        type: 'programming',
        extensions: ['.asc', '.ash']
    },
    {
        name: 'AMPL',
        type: 'programming',
        extensions: ['.ampl', '.mod']
    },
    {
        name: 'ANTLR',
        type: 'programming',
        extensions: ['.g4']
    },
    {
        name: 'API Blueprint',
        type: 'markup',
        extensions: ['.apib']
    },
    {
        name: 'APL',
        type: 'programming',
        extensions: ['.apl', '.dyalog']
    },
    {
        name: 'ASP',
        type: 'programming',
        extensions: ['.asp', '.asax', '.ascx', '.ashx', '.asmx', '.aspx', '.axd']
    },
    {
        name: 'ATS',
        type: 'programming',
        extensions: ['.dats', '.hats', '.sats']
    },
    {
        name: 'ActionScript',
        type: 'programming',
        extensions: ['.as']
    },
    {
        name: 'Ada',
        type: 'programming',
        extensions: ['.adb', '.ada', '.ads']
    },
    {
        name: 'Agda',
        type: 'programming',
        extensions: ['.agda']
    },
    {
        name: 'Alloy',
        type: 'programming',
        extensions: ['.als']
    },
    {
        name: 'Ant Build System',
        type: 'data'
    },
    {
        name: 'ApacheConf',
        type: 'markup',
        extensions: ['.apacheconf', '.vhost']
    },
    {
        name: 'Apex',
        type: 'programming',
        extensions: ['.cls']
    },
    {
        name: 'AppleScript',
        type: 'programming',
        extensions: ['.applescript', '.scpt']
    },
    {
        name: 'Arc',
        type: 'programming',
        extensions: ['.arc']
    },
    {
        name: 'Arduino',
        type: 'programming',
        extensions: ['.ino']
    },
    {
        name: 'AsciiDoc',
        type: 'prose',
        extensions: ['.asciidoc', '.adoc', '.asc']
    },
    {
        name: 'AspectJ',
        type: 'programming',
        extensions: ['.aj']
    },
    {
        name: 'Assembly',
        type: 'programming',
        extensions: ['.asm', '.a51', '.inc', '.nasm']
    },
    {
        name: 'Augeas',
        type: 'programming',
        extensions: ['.aug']
    },
    {
        name: 'AutoHotkey',
        type: 'programming',
        extensions: ['.ahk', '.ahkl']
    },
    {
        name: 'AutoIt',
        type: 'programming',
        extensions: ['.au3']
    },
    {
        name: 'Awk',
        type: 'programming',
        extensions: ['.awk', '.auk', '.gawk', '.mawk', '.nawk']
    },
    {
        name: 'Batchfile',
        type: 'programming',
        extensions: ['.bat', '.cmd']
    },
    {
        name: 'Befunge',
        type: 'programming',
        extensions: ['.befunge']
    },
    {
        name: 'Bison',
        type: 'programming',
        extensions: ['.bison']
    },
    {
        name: 'BitBake',
        type: 'programming',
        extensions: ['.bb']
    },
    {
        name: 'BlitzBasic',
        type: 'programming',
        extensions: ['.bb', '.decls']
    },
    {
        name: 'BlitzMax',
        type: 'programming',
        extensions: ['.bmx']
    },
    {
        name: 'Bluespec',
        type: 'programming',
        extensions: ['.bsv']
    },
    {
        name: 'Boo',
        type: 'programming',
        extensions: ['.boo']
    },
    {
        name: 'Brainfuck',
        type: 'programming',
        extensions: ['.b', '.bf']
    },
    {
        name: 'Brightscript',
        type: 'programming',
        extensions: ['.brs']
    },
    {
        name: 'Bro',
        type: 'programming',
        extensions: ['.bro']
    },
    {
        name: 'C',
        type: 'programming',
        extensions: ['.c', '.cats', '.h', '.idc', '.w']
    },
    {
        name: 'C#',
        type: 'programming',
        extensions: ['.cs', '.cake', '.cshtml', '.csx']
    },
    {
        name: 'C++',
        type: 'programming',
        extensions: [
            '.cpp',
            '.c++',
            '.cc',
            '.cp',
            '.cxx',
            '.h',
            '.h++',
            '.hh',
            '.hpp',
            '.hxx',
            '.inc',
            '.inl',
            '.ipp',
            '.tcc',
            '.tpp'
        ]
    },
    {
        name: 'C-ObjDump',
        type: 'data',
        extensions: ['.c-objdump']
    },
    {
        name: 'C2hs Haskell',
        type: 'programming',
        extensions: ['.chs']
    },
    {
        name: 'CLIPS',
        type: 'programming',
        extensions: ['.clp']
    },
    {
        name: 'CMake',
        type: 'programming',
        extensions: ['.cmake', '.cmake.in']
    },
    {
        name: 'COBOL',
        type: 'programming',
        extensions: ['.cob', '.cbl', '.ccp', '.cobol', '.cpy']
    },
    {
        name: 'CSS',
        type: 'markup',
        extensions: ['.css']
    },
    {
        name: 'CSV',
        type: 'data',
        extensions: ['.csv']
    },
    {
        name: "Cap'n Proto",
        type: 'programming',
        extensions: ['.capnp']
    },
    {
        name: 'CartoCSS',
        type: 'programming',
        extensions: ['.mss']
    },
    {
        name: 'Ceylon',
        type: 'programming',
        extensions: ['.ceylon']
    },
    {
        name: 'Chapel',
        type: 'programming',
        extensions: ['.chpl']
    },
    {
        name: 'Charity',
        type: 'programming',
        extensions: ['.ch']
    },
    {
        name: 'ChucK',
        type: 'programming',
        extensions: ['.ck']
    },
    {
        name: 'Cirru',
        type: 'programming',
        extensions: ['.cirru']
    },
    {
        name: 'Clarion',
        type: 'programming',
        extensions: ['.clw']
    },
    {
        name: 'Clean',
        type: 'programming',
        extensions: ['.icl', '.dcl']
    },
    {
        name: 'Click',
        type: 'programming',
        extensions: ['.click']
    },
    {
        name: 'Clojure',
        type: 'programming',
        extensions: ['.clj', '.boot', '.cl2', '.cljc', '.cljs', '.cljs.hl', '.cljscm', '.cljx', '.hic']
    },
    {
        name: 'CoffeeScript',
        type: 'programming',
        extensions: ['.coffee', '._coffee', '.cake', '.cjsx', '.cson', '.iced']
    },
    {
        name: 'ColdFusion',
        type: 'programming',
        extensions: ['.cfm', '.cfml']
    },
    {
        name: 'ColdFusion CFC',
        type: 'programming',
        extensions: ['.cfc']
    },
    {
        name: 'Common Lisp',
        type: 'programming',
        extensions: ['.lisp', '.asd', '.cl', '.l', '.lsp', '.ny', '.podsl', '.sexp']
    },
    {
        name: 'Component Pascal',
        type: 'programming',
        extensions: ['.cp', '.cps']
    },
    {
        name: 'Cool',
        type: 'programming',
        extensions: ['.cl']
    },
    {
        name: 'Coq',
        type: 'programming',
        extensions: ['.coq', '.v']
    },
    {
        name: 'Cpp-ObjDump',
        type: 'data',
        extensions: ['.cppobjdump', '.c++-objdump', '.c++objdump', '.cpp-objdump', '.cxx-objdump']
    },
    {
        name: 'Creole',
        type: 'prose',
        extensions: ['.creole']
    },
    {
        name: 'Crystal',
        type: 'programming',
        extensions: ['.cr']
    },
    {
        name: 'Cucumber',
        type: 'programming',
        extensions: ['.feature']
    },
    {
        name: 'Cuda',
        type: 'programming',
        extensions: ['.cu', '.cuh']
    },
    {
        name: 'Cycript',
        type: 'programming',
        extensions: ['.cy']
    },
    {
        name: 'Cython',
        type: 'programming',
        extensions: ['.pyx', '.pxd', '.pxi']
    },
    {
        name: 'D',
        type: 'programming',
        extensions: ['.d', '.di']
    },
    {
        name: 'D-ObjDump',
        type: 'data',
        extensions: ['.d-objdump']
    },
    {
        name: 'DIGITAL Command Language',
        type: 'programming',
        extensions: ['.com']
    },
    {
        name: 'DM',
        type: 'programming',
        extensions: ['.dm']
    },
    {
        name: 'DNS Zone',
        type: 'data',
        extensions: ['.zone', '.arpa']
    },
    {
        name: 'DTrace',
        type: 'programming',
        extensions: ['.d']
    },
    {
        name: 'Darcs Patch',
        type: 'data',
        extensions: ['.darcspatch', '.dpatch']
    },
    {
        name: 'Dart',
        type: 'programming',
        extensions: ['.dart']
    },
    {
        name: 'Diff',
        type: 'data',
        extensions: ['.diff', '.patch']
    },
    {
        name: 'Dockerfile',
        type: 'data',
        extensions: ['.dockerfile']
    },
    {
        name: 'Dogescript',
        type: 'programming',
        extensions: ['.djs']
    },
    {
        name: 'Dylan',
        type: 'programming',
        extensions: ['.dylan', '.dyl', '.intr', '.lid']
    },
    {
        name: 'E',
        type: 'programming',
        extensions: ['.E']
    },
    {
        name: 'ECL',
        type: 'programming',
        extensions: ['.ecl', '.eclxml']
    },
    {
        name: 'ECLiPSe',
        type: 'programming',
        extensions: ['.ecl']
    },
    {
        name: 'Eagle',
        type: 'markup',
        extensions: ['.sch', '.brd']
    },
    {
        name: 'Ecere Projects',
        type: 'data',
        extensions: ['.epj']
    },
    {
        name: 'Eiffel',
        type: 'programming',
        extensions: ['.e']
    },
    {
        name: 'Elixir',
        type: 'programming',
        extensions: ['.ex', '.exs']
    },
    {
        name: 'Elm',
        type: 'programming',
        extensions: ['.elm']
    },
    {
        name: 'Emacs Lisp',
        type: 'programming',
        extensions: ['.el', '.emacs', '.emacs.desktop']
    },
    {
        name: 'EmberScript',
        type: 'programming',
        extensions: ['.em', '.emberscript']
    },
    {
        name: 'Erlang',
        type: 'programming',
        extensions: ['.erl', '.es', '.escript', '.hrl', '.xrl', '.yrl']
    },
    {
        name: 'F#',
        type: 'programming',
        extensions: ['.fs', '.fsi', '.fsx']
    },
    {
        name: 'FLUX',
        type: 'programming',
        extensions: ['.fx', '.flux']
    },
    {
        name: 'FORTRAN',
        type: 'programming',
        extensions: ['.f90', '.f', '.f03', '.f08', '.f77', '.f95', '.for', '.fpp']
    },
    {
        name: 'Factor',
        type: 'programming',
        extensions: ['.factor']
    },
    {
        name: 'Fancy',
        type: 'programming',
        extensions: ['.fy', '.fancypack']
    },
    {
        name: 'Fantom',
        type: 'programming',
        extensions: ['.fan']
    },
    {
        name: 'Filterscript',
        type: 'programming',
        extensions: ['.fs']
    },
    {
        name: 'Formatted',
        type: 'data',
        extensions: ['.for', '.eam.fs']
    },
    {
        name: 'Forth',
        type: 'programming',
        extensions: ['.fth', '.4th', '.f', '.for', '.forth', '.fr', '.frt', '.fs']
    },
    {
        name: 'FreeMarker',
        type: 'programming',
        extensions: ['.ftl']
    },
    {
        name: 'Frege',
        type: 'programming',
        extensions: ['.fr']
    },
    {
        name: 'G-code',
        type: 'data',
        extensions: ['.g', '.gco', '.gcode']
    },
    {
        name: 'GAMS',
        type: 'programming',
        extensions: ['.gms']
    },
    {
        name: 'GAP',
        type: 'programming',
        extensions: ['.g', '.gap', '.gd', '.gi', '.tst']
    },
    {
        name: 'GAS',
        type: 'programming',
        extensions: ['.s', '.ms']
    },
    {
        name: 'GDScript',
        type: 'programming',
        extensions: ['.gd']
    },
    {
        name: 'GLSL',
        type: 'programming',
        extensions: [
            '.glsl',
            '.fp',
            '.frag',
            '.frg',
            '.fs',
            '.fsh',
            '.fshader',
            '.geo',
            '.geom',
            '.glslv',
            '.gshader',
            '.shader',
            '.vert',
            '.vrx',
            '.vsh',
            '.vshader'
        ]
    },
    {
        name: 'Game Maker Language',
        type: 'programming',
        extensions: ['.gml']
    },
    {
        name: 'Genshi',
        type: 'programming',
        extensions: ['.kid']
    },
    {
        name: 'Gentoo Ebuild',
        type: 'programming',
        extensions: ['.ebuild']
    },
    {
        name: 'Gentoo Eclass',
        type: 'programming',
        extensions: ['.eclass']
    },
    {
        name: 'Gettext Catalog',
        type: 'prose',
        extensions: ['.po', '.pot']
    },
    {
        name: 'Glyph',
        type: 'programming',
        extensions: ['.glf']
    },
    {
        name: 'Gnuplot',
        type: 'programming',
        extensions: ['.gp', '.gnu', '.gnuplot', '.plot', '.plt']
    },
    {
        name: 'Go',
        type: 'programming',
        extensions: ['.go']
    },
    {
        name: 'Golo',
        type: 'programming',
        extensions: ['.golo']
    },
    {
        name: 'Gosu',
        type: 'programming',
        extensions: ['.gs', '.gst', '.gsx', '.vark']
    },
    {
        name: 'Grace',
        type: 'programming',
        extensions: ['.grace']
    },
    {
        name: 'Gradle',
        type: 'data',
        extensions: ['.gradle']
    },
    {
        name: 'Grammatical Framework',
        type: 'programming',
        extensions: ['.gf']
    },
    {
        name: 'Graph Modeling Language',
        type: 'data',
        extensions: ['.gml']
    },
    {
        name: 'GraphQL',
        type: 'data',
        extensions: ['.graphql']
    },
    {
        name: 'Graphviz (DOT)',
        type: 'data',
        extensions: ['.dot', '.gv']
    },
    {
        name: 'Groff',
        type: 'markup',
        extensions: [
            '.man',
            '.1',
            '.1in',
            '.1m',
            '.1x',
            '.2',
            '.3',
            '.3in',
            '.3m',
            '.3qt',
            '.3x',
            '.4',
            '.5',
            '.6',
            '.7',
            '.8',
            '.9',
            '.l',
            '.me',
            '.ms',
            '.n',
            '.rno',
            '.roff'
        ]
    },
    {
        name: 'Groovy',
        type: 'programming',
        extensions: ['.groovy', '.grt', '.gtpl', '.gvy']
    },
    {
        name: 'Groovy Server Pages',
        type: 'programming',
        extensions: ['.gsp']
    },
    {
        name: 'HCL',
        type: 'programming',
        extensions: ['.hcl', '.tf']
    },
    {
        name: 'HLSL',
        type: 'programming',
        extensions: ['.hlsl', '.fx', '.fxh', '.hlsli']
    },
    {
        name: 'HTML',
        type: 'markup',
        extensions: ['.html', '.htm', '.html.hl', '.inc', '.st', '.xht', '.xhtml']
    },
    {
        name: 'HTML+Django',
        type: 'markup',
        extensions: ['.mustache', '.jinja']
    },
    {
        name: 'HTML+EEX',
        type: 'markup',
        extensions: ['.eex']
    },
    {
        name: 'HTML+ERB',
        type: 'markup',
        extensions: ['.erb', '.erb.deface']
    },
    {
        name: 'HTML+PHP',
        type: 'markup',
        extensions: ['.phtml']
    },
    {
        name: 'HTTP',
        type: 'data',
        extensions: ['.http']
    },
    {
        name: 'Hack',
        type: 'programming',
        extensions: ['.hh', '.php']
    },
    {
        name: 'Haml',
        type: 'markup',
        extensions: ['.haml', '.haml.deface']
    },
    {
        name: 'Handlebars',
        type: 'markup',
        extensions: ['.handlebars', '.hbs']
    },
    {
        name: 'Harbour',
        type: 'programming',
        extensions: ['.hb']
    },
    {
        name: 'Haskell',
        type: 'programming',
        extensions: ['.hs', '.hsc']
    },
    {
        name: 'Haxe',
        type: 'programming',
        extensions: ['.hx', '.hxsl']
    },
    {
        name: 'Hy',
        type: 'programming',
        extensions: ['.hy']
    },
    {
        name: 'HyPhy',
        type: 'programming',
        extensions: ['.bf']
    },
    {
        name: 'IDL',
        type: 'programming',
        extensions: ['.pro', '.dlm']
    },
    {
        name: 'IGOR Pro',
        type: 'programming',
        extensions: ['.ipf']
    },
    {
        name: 'INI',
        type: 'data',
        extensions: ['.ini', '.cfg', '.prefs', '.pro', '.properties']
    },
    {
        name: 'IRC log',
        type: 'data',
        extensions: ['.irclog', '.weechatlog']
    },
    {
        name: 'Idris',
        type: 'programming',
        extensions: ['.idr', '.lidr']
    },
    {
        name: 'Inform 7',
        type: 'programming',
        extensions: ['.ni', '.i7x']
    },
    {
        name: 'Inno Setup',
        type: 'programming',
        extensions: ['.iss']
    },
    {
        name: 'Io',
        type: 'programming',
        extensions: ['.io']
    },
    {
        name: 'Ioke',
        type: 'programming',
        extensions: ['.ik']
    },
    {
        name: 'Isabelle',
        type: 'programming',
        extensions: ['.thy']
    },
    {
        name: 'Isabelle ROOT',
        type: 'programming'
    },
    {
        name: 'J',
        type: 'programming',
        extensions: ['.ijs']
    },
    {
        name: 'JFlex',
        type: 'programming',
        extensions: ['.flex', '.jflex']
    },
    {
        name: 'JSON',
        type: 'data',
        extensions: ['.json', '.geojson', '.lock', '.topojson']
    },
    {
        name: 'JSON5',
        type: 'data',
        extensions: ['.json5']
    },
    {
        name: 'JSONLD',
        type: 'data',
        extensions: ['.jsonld']
    },
    {
        name: 'JSONiq',
        type: 'programming',
        extensions: ['.jq']
    },
    {
        name: 'JSX',
        type: 'programming',
        extensions: ['.jsx']
    },
    {
        name: 'Jade',
        type: 'markup',
        extensions: ['.jade']
    },
    {
        name: 'Jasmin',
        type: 'programming',
        extensions: ['.j']
    },
    {
        name: 'Java',
        type: 'programming',
        extensions: ['.java']
    },
    {
        name: 'Java Server Pages',
        type: 'programming',
        extensions: ['.jsp']
    },
    {
        name: 'JavaScript',
        type: 'programming',
        extensions: [
            '.js',
            '._js',
            '.bones',
            '.es',
            '.es6',
            '.frag',
            '.gs',
            '.jake',
            '.jsb',
            '.jscad',
            '.jsfl',
            '.jsm',
            '.jss',
            '.njs',
            '.pac',
            '.sjs',
            '.ssjs',
            '.sublime-build',
            '.sublime-commands',
            '.sublime-completions',
            '.sublime-keymap',
            '.sublime-macro',
            '.sublime-menu',
            '.sublime-mousemap',
            '.sublime-project',
            '.sublime-settings',
            '.sublime-theme',
            '.sublime-workspace',
            '.sublime_metrics',
            '.sublime_session',
            '.xsjs',
            '.xsjslib'
        ]
    },
    {
        name: 'Julia',
        type: 'programming',
        extensions: ['.jl']
    },
    {
        name: 'Jupyter Notebook',
        type: 'markup',
        extensions: ['.ipynb']
    },
    {
        name: 'KRL',
        type: 'programming',
        extensions: ['.krl']
    },
    {
        name: 'KiCad',
        type: 'programming',
        extensions: ['.sch', '.brd', '.kicad_pcb']
    },
    {
        name: 'Kit',
        type: 'markup',
        extensions: ['.kit']
    },
    {
        name: 'Kotlin',
        type: 'programming',
        extensions: ['.kt', '.ktm', '.kts']
    },
    {
        name: 'LFE',
        type: 'programming',
        extensions: ['.lfe']
    },
    {
        name: 'LLVM',
        type: 'programming',
        extensions: ['.ll']
    },
    {
        name: 'LOLCODE',
        type: 'programming',
        extensions: ['.lol']
    },
    {
        name: 'LSL',
        type: 'programming',
        extensions: ['.lsl', '.lslp']
    },
    {
        name: 'LabVIEW',
        type: 'programming',
        extensions: ['.lvproj']
    },
    {
        name: 'Lasso',
        type: 'programming',
        extensions: ['.lasso', '.las', '.lasso8', '.lasso9', '.ldml']
    },
    {
        name: 'Latte',
        type: 'markup',
        extensions: ['.latte']
    },
    {
        name: 'Lean',
        type: 'programming',
        extensions: ['.lean', '.hlean']
    },
    {
        name: 'Less',
        type: 'markup',
        extensions: ['.less']
    },
    {
        name: 'Lex',
        type: 'programming',
        extensions: ['.l', '.lex']
    },
    {
        name: 'LilyPond',
        type: 'programming',
        extensions: ['.ly', '.ily']
    },
    {
        name: 'Limbo',
        type: 'programming',
        extensions: ['.b', '.m']
    },
    {
        name: 'Linker Script',
        type: 'data',
        extensions: ['.ld', '.lds']
    },
    {
        name: 'Linux Kernel Module',
        type: 'data',
        extensions: ['.mod']
    },
    {
        name: 'Liquid',
        type: 'markup',
        extensions: ['.liquid']
    },
    {
        name: 'Literate Agda',
        type: 'programming',
        extensions: ['.lagda']
    },
    {
        name: 'Literate CoffeeScript',
        type: 'programming',
        extensions: ['.litcoffee']
    },
    {
        name: 'Literate Haskell',
        type: 'programming',
        extensions: ['.lhs']
    },
    {
        name: 'LiveScript',
        type: 'programming',
        extensions: ['.ls', '._ls']
    },
    {
        name: 'Logos',
        type: 'programming',
        extensions: ['.xm', '.x', '.xi']
    },
    {
        name: 'Logtalk',
        type: 'programming',
        extensions: ['.lgt', '.logtalk']
    },
    {
        name: 'LookML',
        type: 'programming',
        extensions: ['.lookml']
    },
    {
        name: 'LoomScript',
        type: 'programming',
        extensions: ['.ls']
    },
    {
        name: 'Lua',
        type: 'programming',
        extensions: ['.lua', '.fcgi', '.nse', '.pd_lua', '.rbxs', '.wlua']
    },
    {
        name: 'M',
        type: 'programming',
        extensions: ['.mumps', '.m']
    },
    {
        name: 'M4',
        type: 'programming',
        extensions: ['.m4']
    },
    {
        name: 'M4Sugar',
        type: 'programming',
        extensions: ['.m4']
    },
    {
        name: 'MAXScript',
        type: 'programming',
        extensions: ['.ms', '.mcr']
    },
    {
        name: 'MTML',
        type: 'markup',
        extensions: ['.mtml']
    },
    {
        name: 'MUF',
        type: 'programming',
        extensions: ['.muf', '.m']
    },
    {
        name: 'Makefile',
        type: 'programming',
        extensions: ['.mak', '.d', '.mk', '.mkfile']
    },
    {
        name: 'Mako',
        type: 'programming',
        extensions: ['.mako', '.mao']
    },
    {
        name: 'Markdown',
        type: 'prose',
        extensions: ['.md', '.markdown', '.mkd', '.mkdn', '.mkdown', '.ron']
    },
    {
        name: 'Mask',
        type: 'markup',
        extensions: ['.mask']
    },
    {
        name: 'Mathematica',
        type: 'programming',
        extensions: ['.mathematica', '.cdf', '.m', '.ma', '.mt', '.nb', '.nbp', '.wl', '.wlt']
    },
    {
        name: 'Matlab',
        type: 'programming',
        extensions: ['.matlab', '.m']
    },
    {
        name: 'Maven POM',
        type: 'data'
    },
    {
        name: 'Max',
        type: 'programming',
        extensions: ['.maxpat', '.maxhelp', '.maxproj', '.mxt', '.pat']
    },
    {
        name: 'MediaWiki',
        type: 'prose',
        extensions: ['.mediawiki', '.wiki']
    },
    {
        name: 'Mercury',
        type: 'programming',
        extensions: ['.m', '.moo']
    },
    {
        name: 'Metal',
        type: 'programming',
        extensions: ['.metal']
    },
    {
        name: 'MiniD',
        type: 'programming',
        extensions: ['.minid']
    },
    {
        name: 'Mirah',
        type: 'programming',
        extensions: ['.druby', '.duby', '.mir', '.mirah']
    },
    {
        name: 'Modelica',
        type: 'programming',
        extensions: ['.mo']
    },
    {
        name: 'Modula-2',
        type: 'programming',
        extensions: ['.mod']
    },
    {
        name: 'Module Management System',
        type: 'programming',
        extensions: ['.mms', '.mmk']
    },
    {
        name: 'Monkey',
        type: 'programming',
        extensions: ['.monkey']
    },
    {
        name: 'Moocode',
        type: 'programming',
        extensions: ['.moo']
    },
    {
        name: 'MoonScript',
        type: 'programming',
        extensions: ['.moon']
    },
    {
        name: 'Myghty',
        type: 'programming',
        extensions: ['.myt']
    },
    {
        name: 'NCL',
        type: 'programming',
        extensions: ['.ncl']
    },
    {
        name: 'NL',
        type: 'data',
        extensions: ['.nl']
    },
    {
        name: 'NSIS',
        type: 'programming',
        extensions: ['.nsi', '.nsh']
    },
    {
        name: 'Nemerle',
        type: 'programming',
        extensions: ['.n']
    },
    {
        name: 'NetLinx',
        type: 'programming',
        extensions: ['.axs', '.axi']
    },
    {
        name: 'NetLinx+ERB',
        type: 'programming',
        extensions: ['.axs.erb', '.axi.erb']
    },
    {
        name: 'NetLogo',
        type: 'programming',
        extensions: ['.nlogo']
    },
    {
        name: 'NewLisp',
        type: 'programming',
        extensions: ['.nl', '.lisp', '.lsp']
    },
    {
        name: 'Nginx',
        type: 'markup',
        extensions: ['.nginxconf', '.vhost']
    },
    {
        name: 'Nimrod',
        type: 'programming',
        extensions: ['.nim', '.nimrod']
    },
    {
        name: 'Ninja',
        type: 'data',
        extensions: ['.ninja']
    },
    {
        name: 'Nit',
        type: 'programming',
        extensions: ['.nit']
    },
    {
        name: 'Nix',
        type: 'programming',
        extensions: ['.nix']
    },
    {
        name: 'Nu',
        type: 'programming',
        extensions: ['.nu']
    },
    {
        name: 'NumPy',
        type: 'programming',
        extensions: ['.numpy', '.numpyw', '.numsc']
    },
    {
        name: 'OCaml',
        type: 'programming',
        extensions: ['.ml', '.eliom', '.eliomi', '.ml4', '.mli', '.mll', '.mly']
    },
    {
        name: 'ObjDump',
        type: 'data',
        extensions: ['.objdump']
    },
    {
        name: 'Objective-C',
        type: 'programming',
        extensions: ['.m', '.h']
    },
    {
        name: 'Objective-C++',
        type: 'programming',
        extensions: ['.mm']
    },
    {
        name: 'Objective-J',
        type: 'programming',
        extensions: ['.j', '.sj']
    },
    {
        name: 'Omgrofl',
        type: 'programming',
        extensions: ['.omgrofl']
    },
    {
        name: 'Opa',
        type: 'programming',
        extensions: ['.opa']
    },
    {
        name: 'Opal',
        type: 'programming',
        extensions: ['.opal']
    },
    {
        name: 'OpenCL',
        type: 'programming',
        extensions: ['.cl', '.opencl']
    },
    {
        name: 'OpenEdge ABL',
        type: 'programming',
        extensions: ['.p', '.cls']
    },
    {
        name: 'OpenSCAD',
        type: 'programming',
        extensions: ['.scad']
    },
    {
        name: 'Org',
        type: 'prose',
        extensions: ['.org']
    },
    {
        name: 'Ox',
        type: 'programming',
        extensions: ['.ox', '.oxh', '.oxo']
    },
    {
        name: 'Oxygene',
        type: 'programming',
        extensions: ['.oxygene']
    },
    {
        name: 'Oz',
        type: 'programming',
        extensions: ['.oz']
    },
    {
        name: 'PAWN',
        type: 'programming',
        extensions: ['.pwn', '.inc']
    },
    {
        name: 'PHP',
        type: 'programming',
        extensions: ['.php', '.aw', '.ctp', '.fcgi', '.inc', '.php3', '.php4', '.php5', '.phps', '.phpt']
    },
    {
        name: 'PLSQL',
        type: 'programming',
        extensions: ['.pls', '.pck', '.pkb', '.pks', '.plb', '.plsql', '.sql']
    },
    {
        name: 'PLpgSQL',
        type: 'programming',
        extensions: ['.sql']
    },
    {
        name: 'POV-Ray SDL',
        type: 'programming',
        extensions: ['.pov', '.inc']
    },
    {
        name: 'Pan',
        type: 'programming',
        extensions: ['.pan']
    },
    {
        name: 'Papyrus',
        type: 'programming',
        extensions: ['.psc']
    },
    {
        name: 'Parrot',
        type: 'programming',
        extensions: ['.parrot']
    },
    {
        name: 'Parrot Assembly',
        type: 'programming',
        extensions: ['.pasm']
    },
    {
        name: 'Parrot Internal Representation',
        type: 'programming',
        extensions: ['.pir']
    },
    {
        name: 'Pascal',
        type: 'programming',
        extensions: ['.pas', '.dfm', '.dpr', '.inc', '.lpr', '.pp']
    },
    {
        name: 'Perl',
        type: 'programming',
        extensions: ['.pl', '.al', '.cgi', '.fcgi', '.perl', '.ph', '.plx', '.pm', '.pod', '.psgi', '.t']
    },
    {
        name: 'Perl6',
        type: 'programming',
        extensions: ['.6pl', '.6pm', '.nqp', '.p6', '.p6l', '.p6m', '.pl', '.pl6', '.pm', '.pm6', '.t']
    },
    {
        name: 'Pickle',
        type: 'data',
        extensions: ['.pkl']
    },
    {
        name: 'PicoLisp',
        type: 'programming',
        extensions: ['.l']
    },
    {
        name: 'PigLatin',
        type: 'programming',
        extensions: ['.pig']
    },
    {
        name: 'Pike',
        type: 'programming',
        extensions: ['.pike', '.pmod']
    },
    {
        name: 'Pod',
        type: 'prose',
        extensions: ['.pod']
    },
    {
        name: 'PogoScript',
        type: 'programming',
        extensions: ['.pogo']
    },
    {
        name: 'Pony',
        type: 'programming',
        extensions: ['.pony']
    },
    {
        name: 'PostScript',
        type: 'markup',
        extensions: ['.ps', '.eps']
    },
    {
        name: 'PowerShell',
        type: 'programming',
        extensions: ['.ps1', '.psd1', '.psm1']
    },
    {
        name: 'Processing',
        type: 'programming',
        extensions: ['.pde']
    },
    {
        name: 'Prolog',
        type: 'programming',
        extensions: ['.pl', '.pro', '.prolog', '.yap']
    },
    {
        name: 'Propeller Spin',
        type: 'programming',
        extensions: ['.spin']
    },
    {
        name: 'Protocol Buffer',
        type: 'markup',
        extensions: ['.proto']
    },
    {
        name: 'Public Key',
        type: 'data',
        extensions: ['.asc', '.pub']
    },
    {
        name: 'Puppet',
        type: 'programming',
        extensions: ['.pp']
    },
    {
        name: 'Pure Data',
        type: 'programming',
        extensions: ['.pd']
    },
    {
        name: 'PureBasic',
        type: 'programming',
        extensions: ['.pb', '.pbi']
    },
    {
        name: 'PureScript',
        type: 'programming',
        extensions: ['.purs']
    },
    {
        name: 'Python',
        type: 'programming',
        extensions: [
            '.py',
            '.bzl',
            '.cgi',
            '.fcgi',
            '.gyp',
            '.lmi',
            '.pyde',
            '.pyp',
            '.pyt',
            '.pyw',
            '.rpy',
            '.tac',
            '.wsgi',
            '.xpy'
        ]
    },
    {
        name: 'Python traceback',
        type: 'data',
        extensions: ['.pytb']
    },
    {
        name: 'QML',
        type: 'programming',
        extensions: ['.qml', '.qbs']
    },
    {
        name: 'QMake',
        type: 'programming',
        extensions: ['.pro', '.pri']
    },
    {
        name: 'R',
        type: 'programming',
        extensions: ['.r', '.rd', '.rsx']
    },
    {
        name: 'RAML',
        type: 'markup',
        extensions: ['.raml']
    },
    {
        name: 'RDoc',
        type: 'prose',
        extensions: ['.rdoc']
    },
    {
        name: 'REALbasic',
        type: 'programming',
        extensions: ['.rbbas', '.rbfrm', '.rbmnu', '.rbres', '.rbtbar', '.rbuistate']
    },
    {
        name: 'RHTML',
        type: 'markup',
        extensions: ['.rhtml']
    },
    {
        name: 'RMarkdown',
        type: 'prose',
        extensions: ['.rmd']
    },
    {
        name: 'Racket',
        type: 'programming',
        extensions: ['.rkt', '.rktd', '.rktl', '.scrbl']
    },
    {
        name: 'Ragel in Ruby Host',
        type: 'programming',
        extensions: ['.rl']
    },
    {
        name: 'Raw token data',
        type: 'data',
        extensions: ['.raw']
    },
    {
        name: 'Rebol',
        type: 'programming',
        extensions: ['.reb', '.r', '.r2', '.r3', '.rebol']
    },
    {
        name: 'Red',
        type: 'programming',
        extensions: ['.red', '.reds']
    },
    {
        name: 'Redcode',
        type: 'programming',
        extensions: ['.cw']
    },
    {
        name: "Ren'Py",
        type: 'programming',
        extensions: ['.rpy']
    },
    {
        name: 'RenderScript',
        type: 'programming',
        extensions: ['.rs', '.rsh']
    },
    {
        name: 'RobotFramework',
        type: 'programming',
        extensions: ['.robot']
    },
    {
        name: 'Rouge',
        type: 'programming',
        extensions: ['.rg']
    },
    {
        name: 'Ruby',
        type: 'programming',
        extensions: [
            '.rb',
            '.builder',
            '.fcgi',
            '.gemspec',
            '.god',
            '.irbrc',
            '.jbuilder',
            '.mspec',
            '.pluginspec',
            '.podspec',
            '.rabl',
            '.rake',
            '.rbuild',
            '.rbw',
            '.rbx',
            '.ru',
            '.ruby',
            '.thor',
            '.watchr'
        ]
    },
    {
        name: 'Rust',
        type: 'programming',
        extensions: ['.rs', '.rs.in']
    },
    {
        name: 'SAS',
        type: 'programming',
        extensions: ['.sas']
    },
    {
        name: 'SCSS',
        type: 'markup',
        extensions: ['.scss']
    },
    {
        name: 'SMT',
        type: 'programming',
        extensions: ['.smt2', '.smt']
    },
    {
        name: 'SPARQL',
        type: 'data',
        extensions: ['.sparql', '.rq']
    },
    {
        name: 'SQF',
        type: 'programming',
        extensions: ['.sqf', '.hqf']
    },
    {
        name: 'SQL',
        type: 'data',
        extensions: ['.sql', '.cql', '.ddl', '.inc', '.prc', '.tab', '.udf', '.viw']
    },
    {
        name: 'SQLPL',
        type: 'programming',
        extensions: ['.sql', '.db2']
    },
    {
        name: 'STON',
        type: 'data',
        extensions: ['.ston']
    },
    {
        name: 'SVG',
        type: 'data',
        extensions: ['.svg']
    },
    {
        name: 'Sage',
        type: 'programming',
        extensions: ['.sage', '.sagews']
    },
    {
        name: 'SaltStack',
        type: 'programming',
        extensions: ['.sls']
    },
    {
        name: 'Sass',
        type: 'markup',
        extensions: ['.sass']
    },
    {
        name: 'Scala',
        type: 'programming',
        extensions: ['.scala', '.sbt', '.sc']
    },
    {
        name: 'Scaml',
        type: 'markup',
        extensions: ['.scaml']
    },
    {
        name: 'Scheme',
        type: 'programming',
        extensions: ['.scm', '.sld', '.sls', '.sps', '.ss']
    },
    {
        name: 'Scilab',
        type: 'programming',
        extensions: ['.sci', '.sce', '.tst']
    },
    {
        name: 'Self',
        type: 'programming',
        extensions: ['.self']
    },
    {
        name: 'Shell',
        type: 'programming',
        extensions: ['.sh', '.bash', '.bats', '.cgi', '.command', '.fcgi', '.ksh', '.sh.in', '.tmux', '.tool', '.zsh']
    },
    {
        name: 'ShellSession',
        type: 'programming',
        extensions: ['.sh-session']
    },
    {
        name: 'Shen',
        type: 'programming',
        extensions: ['.shen']
    },
    {
        name: 'Slash',
        type: 'programming',
        extensions: ['.sl']
    },
    {
        name: 'Slim',
        type: 'markup',
        extensions: ['.slim']
    },
    {
        name: 'Smali',
        type: 'programming',
        extensions: ['.smali']
    },
    {
        name: 'Smalltalk',
        type: 'programming',
        extensions: ['.st', '.cs']
    },
    {
        name: 'Smarty',
        type: 'programming',
        extensions: ['.tpl']
    },
    {
        name: 'SourcePawn',
        type: 'programming',
        extensions: ['.sp', '.inc', '.sma']
    },
    {
        name: 'Squirrel',
        type: 'programming',
        extensions: ['.nut']
    },
    {
        name: 'Stan',
        type: 'programming',
        extensions: ['.stan']
    },
    {
        name: 'Standard ML',
        type: 'programming',
        extensions: ['.ML', '.fun', '.sig', '.sml']
    },
    {
        name: 'Stata',
        type: 'programming',
        extensions: ['.do', '.ado', '.doh', '.ihlp', '.mata', '.matah', '.sthlp']
    },
    {
        name: 'Stylus',
        type: 'markup',
        extensions: ['.styl']
    },
    {
        name: 'SuperCollider',
        type: 'programming',
        extensions: ['.sc', '.scd']
    },
    {
        name: 'Swift',
        type: 'programming',
        extensions: ['.swift']
    },
    {
        name: 'SystemVerilog',
        type: 'programming',
        extensions: ['.sv', '.svh', '.vh']
    },
    {
        name: 'TOML',
        type: 'data',
        extensions: ['.toml']
    },
    {
        name: 'TXL',
        type: 'programming',
        extensions: ['.txl']
    },
    {
        name: 'Tcl',
        type: 'programming',
        extensions: ['.tcl', '.adp', '.tm']
    },
    {
        name: 'Tcsh',
        type: 'programming',
        extensions: ['.tcsh', '.csh']
    },
    {
        name: 'TeX',
        type: 'markup',
        extensions: [
            '.tex',
            '.aux',
            '.bbx',
            '.bib',
            '.cbx',
            '.cls',
            '.dtx',
            '.ins',
            '.lbx',
            '.ltx',
            '.mkii',
            '.mkiv',
            '.mkvi',
            '.sty',
            '.toc'
        ]
    },
    {
        name: 'Tea',
        type: 'markup',
        extensions: ['.tea']
    },
    {
        name: 'Terra',
        type: 'programming',
        extensions: ['.t']
    },
    {
        name: 'Text',
        type: 'prose',
        extensions: ['.txt', '.fr', '.nb', '.ncl', '.no']
    },
    {
        name: 'Textile',
        type: 'prose',
        extensions: ['.textile']
    },
    {
        name: 'Thrift',
        type: 'programming',
        extensions: ['.thrift']
    },
    {
        name: 'Turing',
        type: 'programming',
        extensions: ['.t', '.tu']
    },
    {
        name: 'Turtle',
        type: 'data',
        extensions: ['.ttl']
    },
    {
        name: 'Twig',
        type: 'markup',
        extensions: ['.twig']
    },
    {
        name: 'TypeScript',
        type: 'programming',
        extensions: ['.ts', '.tsx']
    },
    {
        name: 'Unified Parallel C',
        type: 'programming',
        extensions: ['.upc']
    },
    {
        name: 'Unity3D Asset',
        type: 'data',
        extensions: ['.anim', '.asset', '.mat', '.meta', '.prefab', '.unity']
    },
    {
        name: 'Uno',
        type: 'programming',
        extensions: ['.uno']
    },
    {
        name: 'UnrealScript',
        type: 'programming',
        extensions: ['.uc']
    },
    {
        name: 'UrWeb',
        type: 'programming',
        extensions: ['.ur', '.urs']
    },
    {
        name: 'VCL',
        type: 'programming',
        extensions: ['.vcl']
    },
    {
        name: 'VHDL',
        type: 'programming',
        extensions: ['.vhdl', '.vhd', '.vhf', '.vhi', '.vho', '.vhs', '.vht', '.vhw']
    },
    {
        name: 'Vala',
        type: 'programming',
        extensions: ['.vala', '.vapi']
    },
    {
        name: 'Verilog',
        type: 'programming',
        extensions: ['.v', '.veo']
    },
    {
        name: 'VimL',
        type: 'programming',
        extensions: ['.vim']
    },
    {
        name: 'Visual Basic',
        type: 'programming',
        extensions: ['.vb', '.bas', '.cls', '.frm', '.frx', '.vba', '.vbhtml', '.vbs']
    },
    {
        name: 'Volt',
        type: 'programming',
        extensions: ['.volt']
    },
    {
        name: 'Vue',
        type: 'markup',
        extensions: ['.vue']
    },
    {
        name: 'Web Ontology Language',
        type: 'markup',
        extensions: ['.owl']
    },
    {
        name: 'WebIDL',
        type: 'programming',
        extensions: ['.webidl']
    },
    {
        name: 'X10',
        type: 'programming',
        extensions: ['.x10']
    },
    {
        name: 'XC',
        type: 'programming',
        extensions: ['.xc']
    },
    {
        name: 'XML',
        type: 'data',
        extensions: [
            '.xml',
            '.ant',
            '.axml',
            '.ccxml',
            '.clixml',
            '.cproject',
            '.csl',
            '.csproj',
            '.ct',
            '.dita',
            '.ditamap',
            '.ditaval',
            '.dll.config',
            '.dotsettings',
            '.filters',
            '.fsproj',
            '.fxml',
            '.glade',
            '.gml',
            '.grxml',
            '.iml',
            '.ivy',
            '.jelly',
            '.jsproj',
            '.kml',
            '.launch',
            '.mdpolicy',
            '.mm',
            '.mod',
            '.mxml',
            '.nproj',
            '.nuspec',
            '.odd',
            '.osm',
            '.plist',
            '.pluginspec',
            '.props',
            '.ps1xml',
            '.psc1',
            '.pt',
            '.rdf',
            '.rss',
            '.scxml',
            '.srdf',
            '.storyboard',
            '.stTheme',
            '.sublime-snippet',
            '.targets',
            '.tmCommand',
            '.tml',
            '.tmLanguage',
            '.tmPreferences',
            '.tmSnippet',
            '.tmTheme',
            '.ts',
            '.tsx',
            '.ui',
            '.urdf',
            '.ux',
            '.vbproj',
            '.vcxproj',
            '.vssettings',
            '.vxml',
            '.wsdl',
            '.wsf',
            '.wxi',
            '.wxl',
            '.wxs',
            '.x3d',
            '.xacro',
            '.xaml',
            '.xib',
            '.xlf',
            '.xliff',
            '.xmi',
            '.xml.dist',
            '.xproj',
            '.xsd',
            '.xul',
            '.zcml'
        ]
    },
    {
        name: 'XPages',
        type: 'programming',
        extensions: ['.xsp-config', '.xsp.metadata']
    },
    {
        name: 'XProc',
        type: 'programming',
        extensions: ['.xpl', '.xproc']
    },
    {
        name: 'XQuery',
        type: 'programming',
        extensions: ['.xquery', '.xq', '.xql', '.xqm', '.xqy']
    },
    {
        name: 'XS',
        type: 'programming',
        extensions: ['.xs']
    },
    {
        name: 'XSLT',
        type: 'programming',
        extensions: ['.xslt', '.xsl']
    },
    {
        name: 'Xojo',
        type: 'programming',
        extensions: ['.xojo_code', '.xojo_menu', '.xojo_report', '.xojo_script', '.xojo_toolbar', '.xojo_window']
    },
    {
        name: 'Xtend',
        type: 'programming',
        extensions: ['.xtend']
    },
    {
        name: 'YAML',
        type: 'data',
        extensions: ['.yml', '.reek', '.rviz', '.sublime-syntax', '.syntax', '.yaml', '.yaml-tmlanguage']
    },
    {
        name: 'YANG',
        type: 'data',
        extensions: ['.yang']
    },
    {
        name: 'Yacc',
        type: 'programming',
        extensions: ['.y', '.yacc', '.yy']
    },
    {
        name: 'Zephir',
        type: 'programming',
        extensions: ['.zep']
    },
    {
        name: 'Zimpl',
        type: 'programming',
        extensions: ['.zimpl', '.zmpl', '.zpl']
    },
    {
        name: 'desktop',
        type: 'data',
        extensions: ['.desktop', '.desktop.in']
    },
    {
        name: 'eC',
        type: 'programming',
        extensions: ['.ec', '.eh']
    },
    {
        name: 'edn',
        type: 'data',
        extensions: ['.edn']
    },
    {
        name: 'fish',
        type: 'programming',
        extensions: ['.fish']
    },
    {
        name: 'mupad',
        type: 'programming',
        extensions: ['.mu']
    },
    {
        name: 'nesC',
        type: 'programming',
        extensions: ['.nc']
    },
    {
        name: 'ooc',
        type: 'programming',
        extensions: ['.ooc']
    },
    {
        name: 'reStructuredText',
        type: 'prose',
        extensions: ['.rst', '.rest', '.rest.txt', '.rst.txt']
    },
    {
        name: 'wisp',
        type: 'programming',
        extensions: ['.wisp']
    },
    {
        name: 'xBase',
        type: 'programming',
        extensions: ['.prg', '.ch', '.prw']
    }
];
exports.languages = new Map();
_languages.forEach((item) => {
    if (Array.isArray(item.extensions)) {
        exports.languages.set(item.name.toLowerCase(), item.extensions.map((ext) => ext.toLowerCase()));
    }
});


/***/ }),
/* 19 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";

const os = __webpack_require__(20);

const homeDirectory = os.homedir();

module.exports = pathWithTilde => {
	if (typeof pathWithTilde !== 'string') {
		throw new TypeError(`Expected a string, got ${typeof pathWithTilde}`);
	}

	return homeDirectory ? pathWithTilde.replace(/^~(?=$|\/|\\)/, homeDirectory) : pathWithTilde;
};


/***/ }),
/* 20 */
/***/ ((__unused_webpack_module, exports) => {

exports.endianness = function () { return 'LE' };

exports.hostname = function () {
    if (typeof location !== 'undefined') {
        return location.hostname
    }
    else return '';
};

exports.loadavg = function () { return [] };

exports.uptime = function () { return 0 };

exports.freemem = function () {
    return Number.MAX_VALUE;
};

exports.totalmem = function () {
    return Number.MAX_VALUE;
};

exports.cpus = function () { return [] };

exports.type = function () { return 'Browser' };

exports.release = function () {
    if (typeof navigator !== 'undefined') {
        return navigator.appVersion;
    }
    return '';
};

exports.networkInterfaces
= exports.getNetworkInterfaces
= function () { return {} };

exports.arch = function () { return 'javascript' };

exports.platform = function () { return 'browser' };

exports.tmpdir = exports.tmpDir = function () {
    return '/tmp';
};

exports.EOL = '\n';

exports.homedir = function () {
	return '/'
};


/***/ }),
/* 21 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PYTHON_LANGUAGE = void 0;
exports.PYTHON_LANGUAGE = 'python';


/***/ }),
/* 22 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.getPythonEnvironmentCategory = void 0;
const vscodeJupyter_1 = __webpack_require__(16);
function getPythonEnvironmentCategory(interpreter, pythonApi) {
    const envType = (0, vscodeJupyter_1.getCachedEnvironmentTypeFromUri)(interpreter.uri, pythonApi);
    switch (envType) {
        case vscodeJupyter_1.EnvironmentType.Conda:
            return 'Conda Env';
        case vscodeJupyter_1.EnvironmentType.Pipenv:
            return 'Pipenv Env';
        case vscodeJupyter_1.EnvironmentType.Poetry:
            return 'Poetry Env';
        case vscodeJupyter_1.EnvironmentType.Pyenv:
            return 'PyEnv Env';
        case vscodeJupyter_1.EnvironmentType.Venv:
        case vscodeJupyter_1.EnvironmentType.VirtualEnv:
        case vscodeJupyter_1.EnvironmentType.VirtualEnvWrapper:
            return 'Virtual Env';
        default:
            return 'Global Env';
    }
}
exports.getPythonEnvironmentCategory = getPythonEnvironmentCategory;


/***/ }),
/* 23 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ActiveKernelChildNodesProviderRegistry = void 0;
class ActiveKernelChildNodesProviderRegistry {
    constructor() {
        this.registeredProviders = new Map();
    }
    registerProvider(provider) {
        ActiveKernelChildNodesProviderRegistry.instance.registeredProviders.set(provider.id, provider);
    }
}
exports.ActiveKernelChildNodesProviderRegistry = ActiveKernelChildNodesProviderRegistry;
ActiveKernelChildNodesProviderRegistry.instance = new ActiveKernelChildNodesProviderRegistry();


/***/ }),
/* 24 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PythonExtension = exports.PVSC_EXTENSION_ID = void 0;
const vscode_1 = __webpack_require__(1);
exports.PVSC_EXTENSION_ID = 'ms-python.python';
// eslint-disable-next-line @typescript-eslint/no-namespace
var PythonExtension;
(function (PythonExtension) {
    /**
     * Returns the API exposed by the Python extension in VS Code.
     */
    async function api() {
        const extension = vscode_1.extensions.getExtension(exports.PVSC_EXTENSION_ID);
        if (extension === undefined) {
            throw new Error(`Python extension is not installed or is disabled`);
        }
        if (!extension.isActive) {
            await extension.activate();
        }
        const pythonApi = extension.exports;
        return pythonApi;
    }
    PythonExtension.api = api;
})(PythonExtension = exports.PythonExtension || (exports.PythonExtension = {}));
//# sourceMappingURL=main.js.map

/***/ }),
/* 25 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.CommandHandler = void 0;
const vscode_1 = __webpack_require__(1);
const kernelTreeView_1 = __webpack_require__(11);
const path = __webpack_require__(12);
class CommandHandler {
    constructor(kernelService, context, jupyterApi) {
        this.kernelService = kernelService;
        this.context = context;
        this.jupyterApi = jupyterApi;
        this.disposables = [];
        this.addCommandHandlers();
    }
    dispose() {
        this.disposables.forEach((d) => d.dispose());
    }
    static register(kernelService, context, jupyterApi) {
        context.subscriptions.push(new CommandHandler(kernelService, context, jupyterApi));
    }
    addCommandHandlers() {
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.shutdownKernel', this.shutdownKernel, this));
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.interruptKernel', this.interruptKernel, this));
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.restartKernel', this.restartKernel, this));
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.createnewinteractive', this.createInteractiveWindow, this));
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.createnewnotebook', this.createNotebook, this));
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.editKernelSpec', this.editKernelSpec, this));
        this.disposables.push(vscode_1.commands.registerCommand('jupyter-kernelManager.refreshKernels', async () => {
            await Promise.all([this.kernelService.getKernelSpecifications(true)]);
            kernelTreeView_1.KernelTreeView.refresh();
        }, this));
    }
    async createInteractiveWindow(node) {
        if (node.kernelConnectionMetadata.kind === 'startUsingRemoteKernelSpec' && node.type === 'activeRemoteKernel') {
            const kernel = node.uri ? this.kernelService.getKernel(node.uri) : undefined;
            const activeKernels = await this.kernelService.getKernelSpecifications(true);
            const activeKernelSpecConnection = kernel &&
                activeKernels.find((item) => {
                    var _a, _b;
                    return item.kind === 'connectToLiveRemoteKernel' &&
                        item.kernelModel.id === ((_b = (_a = kernel === null || kernel === void 0 ? void 0 : kernel.connection) === null || _a === void 0 ? void 0 : _a.kernel) === null || _b === void 0 ? void 0 : _b.id);
                });
            if (activeKernelSpecConnection) {
                void vscode_1.commands.executeCommand('jupyter.createnewinteractive', activeKernelSpecConnection);
                return;
            }
        }
        void vscode_1.commands.executeCommand('jupyter.createnewinteractive', node.kernelConnectionMetadata);
    }
    async createNotebook(node) {
        var _a;
        if (node.kernelConnectionMetadata.kind === 'startUsingRemoteKernelSpec' && node.type === 'activeRemoteKernel') {
            const kernel = node.uri ? this.kernelService.getKernel(node.uri) : undefined;
            const activeKernels = await this.kernelService.getKernelSpecifications(true);
            const activeKernelSpecConnection = kernel &&
                activeKernels.find((item) => {
                    var _a, _b;
                    return item.kind === 'connectToLiveRemoteKernel' &&
                        item.kernelModel.id === ((_b = (_a = kernel === null || kernel === void 0 ? void 0 : kernel.connection) === null || _a === void 0 ? void 0 : _a.kernel) === null || _b === void 0 ? void 0 : _b.id);
                });
            if (activeKernelSpecConnection) {
                const notebook = await vscode_1.commands.executeCommand('ipynb.newUntitledIpynb');
                console.log(notebook);
                return;
            }
        }
        await vscode_1.commands.executeCommand('ipynb.newUntitledIpynb');
        const nb = (_a = vscode_1.window.activeNotebookEditor) === null || _a === void 0 ? void 0 : _a.notebook;
        if (!nb) {
            return;
        }
        this.jupyterApi.openNotebook(nb.uri, node.kernelConnectionMetadata.id);
        console.log(nb);
    }
    async isValidConnection(a) {
        const [kernels, activeKernels] = await Promise.all([
            this.kernelService.getKernelSpecifications(true),
            this.kernelService.getActiveKernels()
        ]);
        if (!activeKernels.some((item) => item.metadata.id === a.kernelConnectionMetadata.id) &&
            !kernels.some((item) => item.id === a.kernelConnectionMetadata.id)) {
            kernelTreeView_1.KernelTreeView.refresh(a.parent);
            return false;
        }
        return true;
    }
    async shutdownKernel(a) {
        if (!(await this.isValidConnection(a))) {
            return;
        }
        const kernelConnection = await this.getKernelConnection(a);
        if (!kernelConnection) {
            return;
        }
        if (this.context.globalState.get('dontAskShutdownKernel', false)) {
            await kernelConnection.shutdown();
            kernelTreeView_1.KernelTreeView.refresh(a.parent);
            return;
        }
        const result = await vscode_1.window.showWarningMessage('Are you sure you want to shutdown the kernel?', { modal: true }, 'Yes', 'Yes, do not ask again');
        switch (result) {
            case 'Yes, do not ask again':
                void this.context.globalState.update('dontAskShutdownKernel', true);
            case 'Yes':
                await kernelConnection.shutdown();
                kernelTreeView_1.KernelTreeView.refresh(a.parent);
                break;
            default:
                break;
        }
    }
    async restartKernel(a) {
        if (!(await this.isValidConnection(a))) {
            return;
        }
        const kernelConnection = await this.getKernelConnection(a);
        if (!kernelConnection) {
            return;
        }
        if (a.uri) {
            void vscode_1.commands.executeCommand('jupyter.restartkernel', a.uri);
            return;
        }
        if (this.context.globalState.get('dontAskRestartKernel', false)) {
            void kernelConnection.restart();
            return;
        }
        const result = await vscode_1.window.showWarningMessage('Do you want to restart the Jupyter kernel?', { modal: true, detail: 'All variables will be lost.' }, 'Restart', "Yes, Don't Ask Again");
        switch (result) {
            case "Yes, Don't Ask Again":
                void this.context.globalState.update('dontAskRestartKernel', true);
            case 'Restart':
                void kernelConnection.restart();
                break;
            default:
                break;
        }
    }
    async interruptKernel(a) {
        if (!(await this.isValidConnection(a))) {
            return;
        }
        const kernelConnection = await this.getKernelConnection(a);
        try {
            if (kernelConnection) {
                await kernelConnection.interrupt();
            }
        }
        catch (ex) {
            console.error('Failed to shutdown kernel', ex);
        }
        finally {
            kernelTreeView_1.KernelTreeView.refresh(a.parent);
        }
    }
    async editKernelSpec(a) {
        if (a.kernelConnectionMetadata.kind !== 'startUsingLocalKernelSpec' ||
            !a.kernelConnectionMetadata.kernelSpec.specFile) {
            return;
        }
        const document = await vscode_1.workspace.openTextDocument(a.kernelConnectionMetadata.kernelSpec.specFile);
        void vscode_1.window.showTextDocument(document);
    }
    async getKernelConnection(a) {
        var _a, _b, _c;
        if (!(await this.isValidConnection(a))) {
            return;
        }
        if (!((_a = a.connection) === null || _a === void 0 ? void 0 : _a.kernel)) {
            if (a.kernelConnectionMetadata.kind === 'startUsingRemoteKernelSpec' && a.uri) {
                const kernel = this.kernelService.getKernel(a.uri);
                if (kernel) {
                    return kernel.connection.kernel;
                }
                kernelTreeView_1.KernelTreeView.refresh(a.parent);
                return;
            }
            try {
                const workspaceFolder = ((_b = vscode_1.workspace.workspaceFolders) === null || _b === void 0 ? void 0 : _b.length)
                    ? vscode_1.workspace.workspaceFolders[0].uri
                    : this.context.extensionUri;
                const filePath = path.join(workspaceFolder.fsPath, a.kernelConnectionMetadata.id, kernelTreeView_1.iPyNbNameToTemporarilyStartKernel);
                const kernel = await this.kernelService.startKernel(a.kernelConnectionMetadata, vscode_1.Uri.file(filePath));
                return kernel.kernel;
            }
            catch (ex) {
                console.error('Failed to shutdown kernel', ex);
            }
            kernelTreeView_1.KernelTreeView.refresh(a.parent);
        }
        return (_c = a.connection) === null || _c === void 0 ? void 0 : _c.kernel;
    }
}
exports.CommandHandler = CommandHandler;


/***/ })
/******/ 	]);
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/global */
/******/ 	(() => {
/******/ 		__webpack_require__.g = (function() {
/******/ 			if (typeof globalThis === 'object') return globalThis;
/******/ 			try {
/******/ 				return this || new Function('return this')();
/******/ 			} catch (e) {
/******/ 				if (typeof window === 'object') return window;
/******/ 			}
/******/ 		})();
/******/ 	})();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be in strict mode.
(() => {
"use strict";
var exports = __webpack_exports__;

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.deactivate = exports.activate = void 0;
const vscode = __webpack_require__(1);
const startup_1 = __webpack_require__(2);
const extension_1 = __webpack_require__(10);
async function activate(context) {
    if (vscode.workspace.getConfiguration('jupyter').get('notebookRunGroups.enabled')) {
        (0, startup_1.activateNotebookRunGroups)(context);
    }
    await (0, extension_1.activate)(context);
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;

})();

module.exports = __webpack_exports__;
/******/ })()
;