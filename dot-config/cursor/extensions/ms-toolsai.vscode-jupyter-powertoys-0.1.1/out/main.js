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
const utils_1 = __webpack_require__(16);
const commandHandler_1 = __webpack_require__(24);
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
const vscodeJupyter_1 = __webpack_require__(15);
const utils_1 = __webpack_require__(16);
const constants_1 = __webpack_require__(20);
const integration_1 = __webpack_require__(21);
const kernelChildNodeProvider_1 = __webpack_require__(22);
const python_extension_1 = __webpack_require__(23);
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
else if (typeof process !== 'undefined') {
    safeProcess = {
        get platform() {
            return process.platform;
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
else {
    safeProcess = {
        get platform() {
            return platform_1.isWindows ? 'win32' : platform_1.isMacintosh ? 'darwin' : 'linux';
        },
        get arch() {
            return undefined;
        },
        get env() {
            return {};
        },
        cwd() {
            return '/';
        }
    };
}
exports.cwd = safeProcess.cwd;
exports.env = safeProcess.env;
exports.platform = safeProcess.platform;
exports.arch = safeProcess.arch;


/***/ }),
/* 14 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

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
exports.globals = typeof self === 'object' ? self : typeof global === 'object' ? global : {};
let nodeProcess = undefined;
if (typeof exports.globals.vscode !== 'undefined' && typeof exports.globals.vscode.process !== 'undefined') {
    nodeProcess = exports.globals.vscode.process;
}
else if (typeof process !== 'undefined') {
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
/* 16 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.initializeKnownLanguages = exports.getLanguageExtension = exports.getDisplayPath = void 0;
const vscode_1 = __webpack_require__(1);
const path = __webpack_require__(12);
const languages_1 = __webpack_require__(17);
const untildify = __webpack_require__(18);
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
/* 17 */
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
/* 18 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

"use strict";

const os = __webpack_require__(19);

const homeDirectory = os.homedir();

module.exports = pathWithTilde => {
	if (typeof pathWithTilde !== 'string') {
		throw new TypeError(`Expected a string, got ${typeof pathWithTilde}`);
	}

	return homeDirectory ? pathWithTilde.replace(/^~(?=$|\/|\\)/, homeDirectory) : pathWithTilde;
};


/***/ }),
/* 19 */
/***/ ((module) => {

"use strict";
module.exports = require("os");

/***/ }),
/* 20 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PYTHON_LANGUAGE = void 0;
exports.PYTHON_LANGUAGE = 'python';


/***/ }),
/* 21 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.getPythonEnvironmentCategory = void 0;
const vscodeJupyter_1 = __webpack_require__(15);
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
/* 22 */
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
/* 23 */
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
/* 24 */
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


/***/ }),
/* 25 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.deactivate = exports.activate = exports.disposables = void 0;
const vscode = __webpack_require__(1);
const constants_1 = __webpack_require__(26);
const contextualHelpProvider_1 = __webpack_require__(28);
const helpProvider = new contextualHelpProvider_1.ContextualHelpProvider();
exports.disposables = [];
function activate(context) {
    context.subscriptions.push(vscode.commands.registerCommand(constants_1.Constants.OpenScratchPadInteractive, openScratchPadInteractive));
    context.subscriptions.push(vscode.commands.registerCommand(constants_1.Constants.OpenContextualHelp, openContextualHelp));
    context.subscriptions.push(vscode.window.registerWebviewViewProvider(helpProvider.viewType, helpProvider, {
        webviewOptions: { retainContextWhenHidden: true }
    }));
    exports.disposables = context.subscriptions;
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;
function openScratchPadInteractive() {
}
async function openContextualHelp() {
    await vscode.commands.executeCommand('jupyterContextualHelp.focus');
}


/***/ }),
/* 26 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.RegExpValues = exports.Identifiers = exports.Constants = exports.NotebookCellScheme = exports.EXTENSION_ROOT_DIR = void 0;
const path = __webpack_require__(27);
const folderName = path.basename(__dirname);
exports.EXTENSION_ROOT_DIR = folderName;
exports.NotebookCellScheme = 'vscode-notebook-cell';
var Constants;
(function (Constants) {
    Constants.OpenScratchPadInteractive = 'jupyter.notebookeditor.openInInteractive';
    Constants.OpenContextualHelp = 'jupyter.notebookeditor.openContextualHelp';
})(Constants = exports.Constants || (exports.Constants = {}));
var Identifiers;
(function (Identifiers) {
    Identifiers.EmptyFileName = '2DB9B899-6519-4E1B-88B0-FA728A274115';
    Identifiers.HistoryPurpose = 'history';
    Identifiers.RawPurpose = 'raw';
    Identifiers.PingPurpose = 'ping';
    Identifiers.MatplotLibDefaultParams = '_VSCode_defaultMatplotlib_Params';
    Identifiers.EditCellId = '3D3AB152-ADC1-4501-B813-4B83B49B0C10';
    Identifiers.SvgSizeTag = 'sizeTag={{0}, {1}}';
    Identifiers.InteractiveWindowIdentityScheme = 'history';
    Identifiers.DefaultCodeCellMarker = '# %%';
    Identifiers.DefaultCommTarget = 'jupyter.widget';
    Identifiers.ALL_VARIABLES = 'ALL_VARIABLES';
    Identifiers.KERNEL_VARIABLES = 'KERNEL_VARIABLES';
    Identifiers.DEBUGGER_VARIABLES = 'DEBUGGER_VARIABLES';
    Identifiers.MULTIPLEXING_DEBUGSERVICE = 'MULTIPLEXING_DEBUGSERVICE';
    Identifiers.RUN_BY_LINE_DEBUGSERVICE = 'RUN_BY_LINE_DEBUGSERVICE';
    Identifiers.REMOTE_URI = 'https://remote/';
    Identifiers.REMOTE_URI_ID_PARAM = 'id';
    Identifiers.REMOTE_URI_HANDLE_PARAM = 'uriHandle';
})(Identifiers = exports.Identifiers || (exports.Identifiers = {}));
var RegExpValues;
(function (RegExpValues) {
    RegExpValues.PythonCellMarker = /^(#\s*%%|#\s*\<codecell\>|#\s*In\[\d*?\]|#\s*In\[ \])/;
    RegExpValues.PythonMarkdownCellMarker = /^(#\s*%%\s*\[markdown\]|#\s*\<markdowncell\>)/;
    RegExpValues.PyKernelOutputRegEx = /.*\s+(.+)$/m;
    RegExpValues.KernelSpecOutputRegEx = /^\s*(\S+)\s+(\S+)$/;
    RegExpValues.UrlPatternRegEx = '(?<PREFIX>https?:\\/\\/)((\\(.+\\s+or\\s+(?<IP>.+)\\))|(?<LOCAL>[^\\s]+))(?<REST>:.+)';
    RegExpValues.HttpPattern = /https?:\/\//;
    RegExpValues.ExtractPortRegex = /https?:\/\/[^\s]+:(\d+)[^\s]+/;
    RegExpValues.ConvertToRemoteUri = /(https?:\/\/)([^\s])+(:\d+[^\s]*)/;
    RegExpValues.ParamsExractorRegEx = /\S+\((.*)\)\s*{/;
    RegExpValues.ArgsSplitterRegEx = /([^\s,]+)/;
    RegExpValues.ShapeSplitterRegEx = /.*,\s*(\d+).*/;
    RegExpValues.SvgHeightRegex = /(\<svg.*height=\")(.*?)\"/;
    RegExpValues.SvgWidthRegex = /(\<svg.*width=\")(.*?)\"/;
    RegExpValues.SvgSizeTagRegex = /\<svg.*tag=\"sizeTag=\{(.*),\s*(.*)\}\"/;
    RegExpValues.StyleTagRegex = /\<style[\s\S]*\<\/style\>/m;
})(RegExpValues = exports.RegExpValues || (exports.RegExpValues = {}));


/***/ }),
/* 27 */
/***/ ((module) => {

"use strict";
module.exports = require("path");

/***/ }),
/* 28 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ContextualHelpProvider = void 0;
const contextualHelp_1 = __webpack_require__(29);
const statusProvider_1 = __webpack_require__(148);
const webviewViewProvider_1 = __webpack_require__(149);
class ContextualHelpProvider {
    constructor() {
        this.viewType = 'jupyterContextualHelp';
        this.webviewProvider = new webviewViewProvider_1.WebviewViewProvider();
        this.statusProvider = new statusProvider_1.StatusProvider();
    }
    async resolveWebviewView(webviewView, _context, _token) {
        webviewView.webview.options = { enableScripts: true, enableCommandUris: true };
        this._contextualHelp = new contextualHelp_1.ContextualHelp(this.webviewProvider, this.statusProvider);
        await this._contextualHelp.load(webviewView);
    }
    get contextualHelp() {
        return this._contextualHelp;
    }
}
exports.ContextualHelpProvider = ContextualHelpProvider;


/***/ }),
/* 29 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ContextualHelp = void 0;
const path = __webpack_require__(27);
const vscode = __webpack_require__(1);
const logging_1 = __webpack_require__(30);
const utils_1 = __webpack_require__(31);
const constants_1 = __webpack_require__(26);
const extension_1 = __webpack_require__(25);
const messages_1 = __webpack_require__(32);
const cellFactory_1 = __webpack_require__(33);
const types_1 = __webpack_require__(143);
const simpleMessageListener_1 = __webpack_require__(144);
const webviewViewHost_1 = __webpack_require__(145);
const root = path.join(__dirname, 'ui', 'viewers');
class ContextualHelp extends webviewViewHost_1.WebviewViewHost {
    constructor(provider, statusProvider) {
        super(provider, (c, d) => new simpleMessageListener_1.SimpleMessageListener(c, d), root, [path.join(root, 'contextualHelp.js')]);
        this.statusProvider = statusProvider;
        this.unfinishedCells = [];
        this.potentiallyUnfinishedStatus = [];
        this.notebookCellMap = new Map();
        this.setStatus = (message, showInWebView) => {
            const result = this.statusProvider.set(message, showInWebView, undefined, undefined, this);
            this.potentiallyUnfinishedStatus.push(result);
            return result;
        };
        vscode.window.onDidChangeActiveNotebookEditor(this.activeEditorChanged, this, extension_1.disposables);
        vscode.window.onDidChangeTextEditorSelection(this.activeSelectionChanged, this, extension_1.disposables);
        vscode.window.onDidChangeNotebookEditorSelection(this.activeNotebookSelectionChanged, this, extension_1.disposables);
    }
    get owningResource() {
        var _a;
        if ((_a = vscode.window.activeNotebookEditor) === null || _a === void 0 ? void 0 : _a.notebook) {
            return vscode.window.activeNotebookEditor.notebook.uri;
        }
        return undefined;
    }
    get title() {
        return 'contextualHelp';
    }
    showHelp(editor) {
        const code = editor.document.getText();
        const cursor_pos = editor.document.offsetAt(editor.selection.active);
        const line = editor.document.lineAt(editor.selection.active.line).text;
        let start = editor.selection.active.character;
        let end = editor.selection.active.character + 1;
        let startFound = false;
        let endFound = false;
        while (!startFound || !endFound) {
            const startChar = start > 0 ? line[start - 1] : ' ';
            const endChar = end < line.length ? line[end] : ' ';
            startFound = /[\s\(\)\[\]'"]+/.test(startChar);
            endFound = /[\s\(\)\[\]'"]+/.test(endChar);
            if (!startFound) {
                start--;
            }
            if (!endFound) {
                end++;
            }
        }
        const word = line.slice(start, end);
        this.inspect(code, cursor_pos, word, editor.document);
    }
    async load(codeWebview) {
        this.vscodeWebView = codeWebview;
        await super.loadWebview(process.cwd(), codeWebview).catch(logging_1.logError);
        if (this.vscodeWebView) {
            await this.activeEditorChanged(vscode.window.activeNotebookEditor);
        }
        this.postMessage(messages_1.WindowMessages.LoadAllCells, {
            cells: [],
            isNotebookTrusted: true
        });
    }
    startProgress() {
        this.postMessage(messages_1.WindowMessages.StartProgress);
    }
    stopProgress() {
        this.postMessage(messages_1.WindowMessages.StopProgress);
    }
    onMessage(message, payload) {
        switch (message) {
            case messages_1.WindowMessages.Started:
                break;
            default:
                break;
        }
        super.onMessage(message, payload);
    }
    postMessage(type, payload) {
        return super.postMessage(type, payload);
    }
    handleMessage(_message, payload, handler) {
        const args = payload;
        handler.bind(this)(args);
    }
    sendCellsToWebView(cells) {
        cells.forEach((cell) => {
            switch (cell.state) {
                case types_1.CellState.init:
                    this.postMessage(messages_1.WindowMessages.StartCell, cell);
                    this.unfinishedCells.push(cell);
                    break;
                case types_1.CellState.executing:
                    this.postMessage(messages_1.WindowMessages.UpdateCellWithExecutionResults, cell);
                    break;
                case types_1.CellState.error:
                case types_1.CellState.finished:
                    this.postMessage(messages_1.WindowMessages.FinishCell, {
                        cell,
                        notebookIdentity: this.owningResource
                    });
                    this.unfinishedCells = this.unfinishedCells.filter((c) => c.id !== cell.id);
                    break;
                default:
                    break;
            }
        });
        if (this.owningResource) {
            this.notebookCellMap.set(this.owningResource.toString(), cells[0]);
        }
    }
    async inspect(code, cursor_pos, word, document) {
        let result = true;
        if (!this.owningResource) {
            return result;
        }
        const config = vscode.workspace.getConfiguration('jupyter');
        const detail_level = config.get('contextualHelp.detailLevel', 'normal') === 'normal' ? 0 : 1;
        const status = this.setStatus('Executing code', false);
        try {
            const kernel = await this.getKernel(document);
            const result = kernel && code && code.length > 0 && kernel.connection.kernel
                ? await kernel.connection.kernel.requestInspect({ code, cursor_pos, detail_level })
                : undefined;
            if (result && result.content.status === 'ok' && 'text/plain' in result.content.data) {
                const output = {
                    output_type: 'stream',
                    text: [result.content.data['text/plain'].toString()],
                    name: 'stdout',
                    metadata: {},
                    execution_count: 1
                };
                const cell = {
                    id: '1',
                    file: constants_1.Identifiers.EmptyFileName,
                    line: 0,
                    state: types_1.CellState.finished,
                    data: (0, cellFactory_1.createCodeCell)([word], [output])
                };
                cell.data.execution_count = 1;
                this.sendCellsToWebView([cell]);
            }
            else {
                const cell = {
                    id: '1',
                    file: constants_1.Identifiers.EmptyFileName,
                    line: 0,
                    state: types_1.CellState.finished,
                    data: (0, cellFactory_1.createCodeCell)(word)
                };
                cell.data.execution_count = kernel ? 1 : 0;
                this.sendCellsToWebView([cell]);
            }
        }
        finally {
            status.dispose();
        }
        return result;
    }
    async activeEditorChanged(editor) {
        await this.postMessage(messages_1.WindowMessages.HideUI, editor === undefined);
        if (vscode.window.activeTextEditor && (0, utils_1.isNotebookCell)(vscode.window.activeTextEditor.document)) {
            this.showHelp(vscode.window.activeTextEditor);
        }
    }
    async activeSelectionChanged(e) {
        if ((0, utils_1.isNotebookCell)(e.textEditor.document)) {
            this.showHelp(e.textEditor);
        }
    }
    async activeNotebookSelectionChanged(e) {
        const cell = e.notebookEditor.notebook.cellAt(e.selections[0].start);
        if (cell) {
            const editor = vscode.window.visibleTextEditors.find((e) => e.document === cell.document);
            if (editor) {
                this.showHelp(editor);
            }
        }
    }
    async activeKernelChanged() {
        if (vscode.window.activeTextEditor && (0, utils_1.isNotebookCell)(vscode.window.activeTextEditor.document)) {
            this.showHelp(vscode.window.activeTextEditor);
        }
    }
    async getKernel(document) {
        var _a;
        const notebook = vscode.workspace.notebookDocuments.find((n) => n.getCells().find((c) => c.document.uri.toString() === document.uri.toString()));
        if (!this.kernelService) {
            if (notebook) {
                const extension = vscode.extensions.getExtension('ms-toolsai.jupyter');
                if (extension) {
                    await extension.activate();
                    const exports = extension.exports;
                    if (exports && exports.getKernelService) {
                        this.kernelService = await exports.getKernelService();
                        (_a = this.kernelService) === null || _a === void 0 ? void 0 : _a.onDidChangeKernels(this.activeKernelChanged, this, extension_1.disposables);
                    }
                }
            }
        }
        if (this.kernelService && notebook) {
            return this.kernelService.getKernel(notebook.uri);
        }
    }
}
exports.ContextualHelp = ContextualHelp;


/***/ }),
/* 30 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.logInfo = exports.logError = exports.logVerbose = exports.log = exports.LogLevel = void 0;
var LogLevel;
(function (LogLevel) {
    LogLevel[LogLevel["Error"] = 40] = "Error";
    LogLevel[LogLevel["Warn"] = 30] = "Warn";
    LogLevel[LogLevel["Info"] = 20] = "Info";
    LogLevel[LogLevel["Debug"] = 10] = "Debug";
    LogLevel[LogLevel["Trace"] = 5] = "Trace";
})(LogLevel = exports.LogLevel || (exports.LogLevel = {}));
function log(logLevel, ...args) {
    switch (logLevel) {
        case LogLevel.Error:
            console.error(args);
            break;
        case LogLevel.Warn:
            console.warn(args);
            break;
        default:
            console.log(args);
            break;
    }
}
exports.log = log;
function logVerbose(...args) {
    log(LogLevel.Trace, ...args);
}
exports.logVerbose = logVerbose;
function logError(...args) {
    log(LogLevel.Error, ...args);
}
exports.logError = logError;
function logInfo(...args) {
    log(LogLevel.Info, ...args);
}
exports.logInfo = logInfo;


/***/ }),
/* 31 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.isUntitledFile = exports.isNotebookCell = exports.isUri = void 0;
const constants_1 = __webpack_require__(26);
function isUri(resource) {
    if (!resource) {
        return false;
    }
    const uri = resource;
    return typeof uri.path === 'string' && typeof uri.scheme === 'string';
}
exports.isUri = isUri;
function isNotebookCell(documentOrUri) {
    const uri = isUri(documentOrUri) ? documentOrUri : documentOrUri.uri;
    return uri.scheme.includes(constants_1.NotebookCellScheme);
}
exports.isNotebookCell = isNotebookCell;
function isUntitledFile(file) {
    return (file === null || file === void 0 ? void 0 : file.scheme) === 'untitled';
}
exports.isUntitledFile = isUntitledFile;


/***/ }),
/* 32 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.MessageMapping = exports.MessageType = exports.SharedMessages = exports.WindowMessages = void 0;
var WindowMessages;
(function (WindowMessages) {
    WindowMessages["StartCell"] = "start_cell";
    WindowMessages["FinishCell"] = "finish_cell";
    WindowMessages["UpdateCellWithExecutionResults"] = "UpdateCellWithExecutionResults";
    WindowMessages["ConvertUriForUseInWebViewRequest"] = "ConvertUriForUseInWebViewRequest";
    WindowMessages["ConvertUriForUseInWebViewResponse"] = "ConvertUriForUseInWebViewResponse";
    WindowMessages["Sync"] = "sync_message_used_to_broadcast_and_sync_editors";
    WindowMessages["OpenSettings"] = "open_settings";
    WindowMessages["GetHTMLByIdRequest"] = "get_html_by_id_request";
    WindowMessages["GetHTMLByIdResponse"] = "get_html_by_id_response";
    WindowMessages["StartProgress"] = "start_progress";
    WindowMessages["StopProgress"] = "stop_progress";
    WindowMessages["LoadAllCells"] = "load_all_cells";
    WindowMessages["LoadAllCellsComplete"] = "load_all_cells_complete";
    WindowMessages["Started"] = "started";
    WindowMessages["HideUI"] = "enable";
})(WindowMessages = exports.WindowMessages || (exports.WindowMessages = {}));
var SharedMessages;
(function (SharedMessages) {
    SharedMessages["UpdateSettings"] = "update_settings";
    SharedMessages["Started"] = "started";
    SharedMessages["LocInit"] = "loc_init";
})(SharedMessages = exports.SharedMessages || (exports.SharedMessages = {}));
var MessageType;
(function (MessageType) {
    MessageType[MessageType["other"] = 0] = "other";
    MessageType[MessageType["syncAcrossSameNotebooks"] = 1] = "syncAcrossSameNotebooks";
    MessageType[MessageType["syncWithLiveShare"] = 2] = "syncWithLiveShare";
    MessageType[MessageType["noIdea"] = 4] = "noIdea";
})(MessageType = exports.MessageType || (exports.MessageType = {}));
class MessageMapping {
}
exports.MessageMapping = MessageMapping;
WindowMessages.StartCell, WindowMessages.FinishCell, WindowMessages.UpdateCellWithExecutionResults, WindowMessages.OpenSettings, SharedMessages.UpdateSettings, SharedMessages.LocInit, WindowMessages.ConvertUriForUseInWebViewRequest, WindowMessages.ConvertUriForUseInWebViewResponse, WindowMessages.GetHTMLByIdRequest, WindowMessages.GetHTMLByIdResponse, WindowMessages.Started, WindowMessages.StartProgress, WindowMessages.StopProgress, WindowMessages.LoadAllCells, WindowMessages.LoadAllCellsComplete, WindowMessages.HideUI;


/***/ }),
/* 33 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.createCellFrom = exports.cloneCell = exports.createCodeCell = void 0;
const cloneDeep = __webpack_require__(34);
const index_1 = __webpack_require__(142);
function uncommentMagicCommands(line) {
    if (/^#\s*!/.test(line)) {
        if (/^#\s*!\s*%%?/.test(line)) {
            return line.replace(/^#\s*!\s*/, '');
        }
        return line.replace(/^#\s*/, '');
    }
    else {
        return line;
    }
}
function createCodeCell(code, options) {
    const magicCommandsAsComments = typeof options === 'boolean' ? options : false;
    const outputs = typeof options === 'boolean' ? [] : options || [];
    code = code || '';
    const source = Array.isArray(code)
        ? (0, index_1.appendLineFeed)(code, magicCommandsAsComments ? uncommentMagicCommands : undefined)
        : code;
    return {
        cell_type: 'code',
        execution_count: null,
        metadata: {},
        outputs,
        source
    };
}
exports.createCodeCell = createCodeCell;
function cloneCell(cell) {
    var _a, _b, _c;
    const clonedCell = cloneDeep(cell);
    const source = Array.isArray(clonedCell.source) || typeof clonedCell.source === 'string' ? clonedCell.source : '';
    switch (cell.cell_type) {
        case 'code': {
            const codeCell = {
                cell_type: 'code',
                metadata: ((_a = clonedCell.metadata) !== null && _a !== void 0 ? _a : {}),
                execution_count: typeof clonedCell.execution_count === 'number' ? clonedCell.execution_count : null,
                outputs: Array.isArray(clonedCell.outputs) ? clonedCell.outputs : [],
                source
            };
            return codeCell;
        }
        case 'markdown': {
            const markdownCell = {
                cell_type: 'markdown',
                metadata: ((_b = clonedCell.metadata) !== null && _b !== void 0 ? _b : {}),
                source,
                attachments: clonedCell.attachments
            };
            return markdownCell;
        }
        case 'raw': {
            const rawCell = {
                cell_type: 'raw',
                metadata: ((_c = clonedCell.metadata) !== null && _c !== void 0 ? _c : {}),
                source,
                attachments: clonedCell.attachments
            };
            return rawCell;
        }
        default: {
            return clonedCell;
        }
    }
}
exports.cloneCell = cloneCell;
function createCellFrom(source, target) {
    const baseCell = source.cell_type === target
        ?
            cloneCell(source)
        : {
            source: source.source,
            cell_type: target,
            metadata: cloneDeep(source.metadata)
        };
    switch (target) {
        case 'code': {
            const codeCell = baseCell;
            codeCell.execution_count = null;
            codeCell.outputs = [];
            return codeCell;
        }
        case 'markdown': {
            return baseCell;
        }
        case 'raw': {
            return baseCell;
        }
        default: {
            throw new Error(`Unsupported target type, ${target}`);
        }
    }
}
exports.createCellFrom = createCellFrom;


/***/ }),
/* 34 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseClone = __webpack_require__(35);

/** Used to compose bitmasks for cloning. */
var CLONE_DEEP_FLAG = 1,
    CLONE_SYMBOLS_FLAG = 4;

/**
 * This method is like `_.clone` except that it recursively clones `value`.
 *
 * @static
 * @memberOf _
 * @since 1.0.0
 * @category Lang
 * @param {*} value The value to recursively clone.
 * @returns {*} Returns the deep cloned value.
 * @see _.clone
 * @example
 *
 * var objects = [{ 'a': 1 }, { 'b': 2 }];
 *
 * var deep = _.cloneDeep(objects);
 * console.log(deep[0] === objects[0]);
 * // => false
 */
function cloneDeep(value) {
  return baseClone(value, CLONE_DEEP_FLAG | CLONE_SYMBOLS_FLAG);
}

module.exports = cloneDeep;


/***/ }),
/* 35 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Stack = __webpack_require__(36),
    arrayEach = __webpack_require__(80),
    assignValue = __webpack_require__(81),
    baseAssign = __webpack_require__(84),
    baseAssignIn = __webpack_require__(106),
    cloneBuffer = __webpack_require__(110),
    copyArray = __webpack_require__(111),
    copySymbols = __webpack_require__(112),
    copySymbolsIn = __webpack_require__(116),
    getAllKeys = __webpack_require__(120),
    getAllKeysIn = __webpack_require__(122),
    getTag = __webpack_require__(123),
    initCloneArray = __webpack_require__(128),
    initCloneByTag = __webpack_require__(129),
    initCloneObject = __webpack_require__(136),
    isArray = __webpack_require__(92),
    isBuffer = __webpack_require__(93),
    isMap = __webpack_require__(138),
    isObject = __webpack_require__(60),
    isSet = __webpack_require__(140),
    keys = __webpack_require__(86),
    keysIn = __webpack_require__(107);

/** Used to compose bitmasks for cloning. */
var CLONE_DEEP_FLAG = 1,
    CLONE_FLAT_FLAG = 2,
    CLONE_SYMBOLS_FLAG = 4;

/** `Object#toString` result references. */
var argsTag = '[object Arguments]',
    arrayTag = '[object Array]',
    boolTag = '[object Boolean]',
    dateTag = '[object Date]',
    errorTag = '[object Error]',
    funcTag = '[object Function]',
    genTag = '[object GeneratorFunction]',
    mapTag = '[object Map]',
    numberTag = '[object Number]',
    objectTag = '[object Object]',
    regexpTag = '[object RegExp]',
    setTag = '[object Set]',
    stringTag = '[object String]',
    symbolTag = '[object Symbol]',
    weakMapTag = '[object WeakMap]';

var arrayBufferTag = '[object ArrayBuffer]',
    dataViewTag = '[object DataView]',
    float32Tag = '[object Float32Array]',
    float64Tag = '[object Float64Array]',
    int8Tag = '[object Int8Array]',
    int16Tag = '[object Int16Array]',
    int32Tag = '[object Int32Array]',
    uint8Tag = '[object Uint8Array]',
    uint8ClampedTag = '[object Uint8ClampedArray]',
    uint16Tag = '[object Uint16Array]',
    uint32Tag = '[object Uint32Array]';

/** Used to identify `toStringTag` values supported by `_.clone`. */
var cloneableTags = {};
cloneableTags[argsTag] = cloneableTags[arrayTag] =
cloneableTags[arrayBufferTag] = cloneableTags[dataViewTag] =
cloneableTags[boolTag] = cloneableTags[dateTag] =
cloneableTags[float32Tag] = cloneableTags[float64Tag] =
cloneableTags[int8Tag] = cloneableTags[int16Tag] =
cloneableTags[int32Tag] = cloneableTags[mapTag] =
cloneableTags[numberTag] = cloneableTags[objectTag] =
cloneableTags[regexpTag] = cloneableTags[setTag] =
cloneableTags[stringTag] = cloneableTags[symbolTag] =
cloneableTags[uint8Tag] = cloneableTags[uint8ClampedTag] =
cloneableTags[uint16Tag] = cloneableTags[uint32Tag] = true;
cloneableTags[errorTag] = cloneableTags[funcTag] =
cloneableTags[weakMapTag] = false;

/**
 * The base implementation of `_.clone` and `_.cloneDeep` which tracks
 * traversed objects.
 *
 * @private
 * @param {*} value The value to clone.
 * @param {boolean} bitmask The bitmask flags.
 *  1 - Deep clone
 *  2 - Flatten inherited properties
 *  4 - Clone symbols
 * @param {Function} [customizer] The function to customize cloning.
 * @param {string} [key] The key of `value`.
 * @param {Object} [object] The parent object of `value`.
 * @param {Object} [stack] Tracks traversed objects and their clone counterparts.
 * @returns {*} Returns the cloned value.
 */
function baseClone(value, bitmask, customizer, key, object, stack) {
  var result,
      isDeep = bitmask & CLONE_DEEP_FLAG,
      isFlat = bitmask & CLONE_FLAT_FLAG,
      isFull = bitmask & CLONE_SYMBOLS_FLAG;

  if (customizer) {
    result = object ? customizer(value, key, object, stack) : customizer(value);
  }
  if (result !== undefined) {
    return result;
  }
  if (!isObject(value)) {
    return value;
  }
  var isArr = isArray(value);
  if (isArr) {
    result = initCloneArray(value);
    if (!isDeep) {
      return copyArray(value, result);
    }
  } else {
    var tag = getTag(value),
        isFunc = tag == funcTag || tag == genTag;

    if (isBuffer(value)) {
      return cloneBuffer(value, isDeep);
    }
    if (tag == objectTag || tag == argsTag || (isFunc && !object)) {
      result = (isFlat || isFunc) ? {} : initCloneObject(value);
      if (!isDeep) {
        return isFlat
          ? copySymbolsIn(value, baseAssignIn(result, value))
          : copySymbols(value, baseAssign(result, value));
      }
    } else {
      if (!cloneableTags[tag]) {
        return object ? value : {};
      }
      result = initCloneByTag(value, tag, isDeep);
    }
  }
  // Check for circular references and return its corresponding clone.
  stack || (stack = new Stack);
  var stacked = stack.get(value);
  if (stacked) {
    return stacked;
  }
  stack.set(value, result);

  if (isSet(value)) {
    value.forEach(function(subValue) {
      result.add(baseClone(subValue, bitmask, customizer, subValue, value, stack));
    });
  } else if (isMap(value)) {
    value.forEach(function(subValue, key) {
      result.set(key, baseClone(subValue, bitmask, customizer, key, value, stack));
    });
  }

  var keysFunc = isFull
    ? (isFlat ? getAllKeysIn : getAllKeys)
    : (isFlat ? keysIn : keys);

  var props = isArr ? undefined : keysFunc(value);
  arrayEach(props || value, function(subValue, key) {
    if (props) {
      key = subValue;
      subValue = value[key];
    }
    // Recursively populate clone (susceptible to call stack limits).
    assignValue(result, key, baseClone(subValue, bitmask, customizer, key, value, stack));
  });
  return result;
}

module.exports = baseClone;


/***/ }),
/* 36 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var ListCache = __webpack_require__(37),
    stackClear = __webpack_require__(45),
    stackDelete = __webpack_require__(46),
    stackGet = __webpack_require__(47),
    stackHas = __webpack_require__(48),
    stackSet = __webpack_require__(49);

/**
 * Creates a stack cache object to store key-value pairs.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */
function Stack(entries) {
  var data = this.__data__ = new ListCache(entries);
  this.size = data.size;
}

// Add methods to `Stack`.
Stack.prototype.clear = stackClear;
Stack.prototype['delete'] = stackDelete;
Stack.prototype.get = stackGet;
Stack.prototype.has = stackHas;
Stack.prototype.set = stackSet;

module.exports = Stack;


/***/ }),
/* 37 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var listCacheClear = __webpack_require__(38),
    listCacheDelete = __webpack_require__(39),
    listCacheGet = __webpack_require__(42),
    listCacheHas = __webpack_require__(43),
    listCacheSet = __webpack_require__(44);

/**
 * Creates an list cache object.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */
function ListCache(entries) {
  var index = -1,
      length = entries == null ? 0 : entries.length;

  this.clear();
  while (++index < length) {
    var entry = entries[index];
    this.set(entry[0], entry[1]);
  }
}

// Add methods to `ListCache`.
ListCache.prototype.clear = listCacheClear;
ListCache.prototype['delete'] = listCacheDelete;
ListCache.prototype.get = listCacheGet;
ListCache.prototype.has = listCacheHas;
ListCache.prototype.set = listCacheSet;

module.exports = ListCache;


/***/ }),
/* 38 */
/***/ ((module) => {

/**
 * Removes all key-value entries from the list cache.
 *
 * @private
 * @name clear
 * @memberOf ListCache
 */
function listCacheClear() {
  this.__data__ = [];
  this.size = 0;
}

module.exports = listCacheClear;


/***/ }),
/* 39 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assocIndexOf = __webpack_require__(40);

/** Used for built-in method references. */
var arrayProto = Array.prototype;

/** Built-in value references. */
var splice = arrayProto.splice;

/**
 * Removes `key` and its value from the list cache.
 *
 * @private
 * @name delete
 * @memberOf ListCache
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */
function listCacheDelete(key) {
  var data = this.__data__,
      index = assocIndexOf(data, key);

  if (index < 0) {
    return false;
  }
  var lastIndex = data.length - 1;
  if (index == lastIndex) {
    data.pop();
  } else {
    splice.call(data, index, 1);
  }
  --this.size;
  return true;
}

module.exports = listCacheDelete;


/***/ }),
/* 40 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var eq = __webpack_require__(41);

/**
 * Gets the index at which the `key` is found in `array` of key-value pairs.
 *
 * @private
 * @param {Array} array The array to inspect.
 * @param {*} key The key to search for.
 * @returns {number} Returns the index of the matched value, else `-1`.
 */
function assocIndexOf(array, key) {
  var length = array.length;
  while (length--) {
    if (eq(array[length][0], key)) {
      return length;
    }
  }
  return -1;
}

module.exports = assocIndexOf;


/***/ }),
/* 41 */
/***/ ((module) => {

/**
 * Performs a
 * [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
 * comparison between two values to determine if they are equivalent.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to compare.
 * @param {*} other The other value to compare.
 * @returns {boolean} Returns `true` if the values are equivalent, else `false`.
 * @example
 *
 * var object = { 'a': 1 };
 * var other = { 'a': 1 };
 *
 * _.eq(object, object);
 * // => true
 *
 * _.eq(object, other);
 * // => false
 *
 * _.eq('a', 'a');
 * // => true
 *
 * _.eq('a', Object('a'));
 * // => false
 *
 * _.eq(NaN, NaN);
 * // => true
 */
function eq(value, other) {
  return value === other || (value !== value && other !== other);
}

module.exports = eq;


/***/ }),
/* 42 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assocIndexOf = __webpack_require__(40);

/**
 * Gets the list cache value for `key`.
 *
 * @private
 * @name get
 * @memberOf ListCache
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */
function listCacheGet(key) {
  var data = this.__data__,
      index = assocIndexOf(data, key);

  return index < 0 ? undefined : data[index][1];
}

module.exports = listCacheGet;


/***/ }),
/* 43 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assocIndexOf = __webpack_require__(40);

/**
 * Checks if a list cache value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf ListCache
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */
function listCacheHas(key) {
  return assocIndexOf(this.__data__, key) > -1;
}

module.exports = listCacheHas;


/***/ }),
/* 44 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assocIndexOf = __webpack_require__(40);

/**
 * Sets the list cache `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf ListCache
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the list cache instance.
 */
function listCacheSet(key, value) {
  var data = this.__data__,
      index = assocIndexOf(data, key);

  if (index < 0) {
    ++this.size;
    data.push([key, value]);
  } else {
    data[index][1] = value;
  }
  return this;
}

module.exports = listCacheSet;


/***/ }),
/* 45 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var ListCache = __webpack_require__(37);

/**
 * Removes all key-value entries from the stack.
 *
 * @private
 * @name clear
 * @memberOf Stack
 */
function stackClear() {
  this.__data__ = new ListCache;
  this.size = 0;
}

module.exports = stackClear;


/***/ }),
/* 46 */
/***/ ((module) => {

/**
 * Removes `key` and its value from the stack.
 *
 * @private
 * @name delete
 * @memberOf Stack
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */
function stackDelete(key) {
  var data = this.__data__,
      result = data['delete'](key);

  this.size = data.size;
  return result;
}

module.exports = stackDelete;


/***/ }),
/* 47 */
/***/ ((module) => {

/**
 * Gets the stack value for `key`.
 *
 * @private
 * @name get
 * @memberOf Stack
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */
function stackGet(key) {
  return this.__data__.get(key);
}

module.exports = stackGet;


/***/ }),
/* 48 */
/***/ ((module) => {

/**
 * Checks if a stack value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf Stack
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */
function stackHas(key) {
  return this.__data__.has(key);
}

module.exports = stackHas;


/***/ }),
/* 49 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var ListCache = __webpack_require__(37),
    Map = __webpack_require__(50),
    MapCache = __webpack_require__(65);

/** Used as the size to enable large array optimizations. */
var LARGE_ARRAY_SIZE = 200;

/**
 * Sets the stack `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf Stack
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the stack cache instance.
 */
function stackSet(key, value) {
  var data = this.__data__;
  if (data instanceof ListCache) {
    var pairs = data.__data__;
    if (!Map || (pairs.length < LARGE_ARRAY_SIZE - 1)) {
      pairs.push([key, value]);
      this.size = ++data.size;
      return this;
    }
    data = this.__data__ = new MapCache(pairs);
  }
  data.set(key, value);
  this.size = data.size;
  return this;
}

module.exports = stackSet;


/***/ }),
/* 50 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51),
    root = __webpack_require__(56);

/* Built-in method references that are verified to be native. */
var Map = getNative(root, 'Map');

module.exports = Map;


/***/ }),
/* 51 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsNative = __webpack_require__(52),
    getValue = __webpack_require__(64);

/**
 * Gets the native function at `key` of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @param {string} key The key of the method to get.
 * @returns {*} Returns the function if it's native, else `undefined`.
 */
function getNative(object, key) {
  var value = getValue(object, key);
  return baseIsNative(value) ? value : undefined;
}

module.exports = getNative;


/***/ }),
/* 52 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isFunction = __webpack_require__(53),
    isMasked = __webpack_require__(61),
    isObject = __webpack_require__(60),
    toSource = __webpack_require__(63);

/**
 * Used to match `RegExp`
 * [syntax characters](http://ecma-international.org/ecma-262/7.0/#sec-patterns).
 */
var reRegExpChar = /[\\^$.*+?()[\]{}|]/g;

/** Used to detect host constructors (Safari). */
var reIsHostCtor = /^\[object .+?Constructor\]$/;

/** Used for built-in method references. */
var funcProto = Function.prototype,
    objectProto = Object.prototype;

/** Used to resolve the decompiled source of functions. */
var funcToString = funcProto.toString;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/** Used to detect if a method is native. */
var reIsNative = RegExp('^' +
  funcToString.call(hasOwnProperty).replace(reRegExpChar, '\\$&')
  .replace(/hasOwnProperty|(function).*?(?=\\\()| for .+?(?=\\\])/g, '$1.*?') + '$'
);

/**
 * The base implementation of `_.isNative` without bad shim checks.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a native function,
 *  else `false`.
 */
function baseIsNative(value) {
  if (!isObject(value) || isMasked(value)) {
    return false;
  }
  var pattern = isFunction(value) ? reIsNative : reIsHostCtor;
  return pattern.test(toSource(value));
}

module.exports = baseIsNative;


/***/ }),
/* 53 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(54),
    isObject = __webpack_require__(60);

/** `Object#toString` result references. */
var asyncTag = '[object AsyncFunction]',
    funcTag = '[object Function]',
    genTag = '[object GeneratorFunction]',
    proxyTag = '[object Proxy]';

/**
 * Checks if `value` is classified as a `Function` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a function, else `false`.
 * @example
 *
 * _.isFunction(_);
 * // => true
 *
 * _.isFunction(/abc/);
 * // => false
 */
function isFunction(value) {
  if (!isObject(value)) {
    return false;
  }
  // The use of `Object#toString` avoids issues with the `typeof` operator
  // in Safari 9 which returns 'object' for typed arrays and other constructors.
  var tag = baseGetTag(value);
  return tag == funcTag || tag == genTag || tag == asyncTag || tag == proxyTag;
}

module.exports = isFunction;


/***/ }),
/* 54 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Symbol = __webpack_require__(55),
    getRawTag = __webpack_require__(58),
    objectToString = __webpack_require__(59);

/** `Object#toString` result references. */
var nullTag = '[object Null]',
    undefinedTag = '[object Undefined]';

/** Built-in value references. */
var symToStringTag = Symbol ? Symbol.toStringTag : undefined;

/**
 * The base implementation of `getTag` without fallbacks for buggy environments.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the `toStringTag`.
 */
function baseGetTag(value) {
  if (value == null) {
    return value === undefined ? undefinedTag : nullTag;
  }
  return (symToStringTag && symToStringTag in Object(value))
    ? getRawTag(value)
    : objectToString(value);
}

module.exports = baseGetTag;


/***/ }),
/* 55 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var root = __webpack_require__(56);

/** Built-in value references. */
var Symbol = root.Symbol;

module.exports = Symbol;


/***/ }),
/* 56 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var freeGlobal = __webpack_require__(57);

/** Detect free variable `self`. */
var freeSelf = typeof self == 'object' && self && self.Object === Object && self;

/** Used as a reference to the global object. */
var root = freeGlobal || freeSelf || Function('return this')();

module.exports = root;


/***/ }),
/* 57 */
/***/ ((module) => {

/** Detect free variable `global` from Node.js. */
var freeGlobal = typeof global == 'object' && global && global.Object === Object && global;

module.exports = freeGlobal;


/***/ }),
/* 58 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Symbol = __webpack_require__(55);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Used to resolve the
 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
 * of values.
 */
var nativeObjectToString = objectProto.toString;

/** Built-in value references. */
var symToStringTag = Symbol ? Symbol.toStringTag : undefined;

/**
 * A specialized version of `baseGetTag` which ignores `Symbol.toStringTag` values.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the raw `toStringTag`.
 */
function getRawTag(value) {
  var isOwn = hasOwnProperty.call(value, symToStringTag),
      tag = value[symToStringTag];

  try {
    value[symToStringTag] = undefined;
    var unmasked = true;
  } catch (e) {}

  var result = nativeObjectToString.call(value);
  if (unmasked) {
    if (isOwn) {
      value[symToStringTag] = tag;
    } else {
      delete value[symToStringTag];
    }
  }
  return result;
}

module.exports = getRawTag;


/***/ }),
/* 59 */
/***/ ((module) => {

/** Used for built-in method references. */
var objectProto = Object.prototype;

/**
 * Used to resolve the
 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
 * of values.
 */
var nativeObjectToString = objectProto.toString;

/**
 * Converts `value` to a string using `Object.prototype.toString`.
 *
 * @private
 * @param {*} value The value to convert.
 * @returns {string} Returns the converted string.
 */
function objectToString(value) {
  return nativeObjectToString.call(value);
}

module.exports = objectToString;


/***/ }),
/* 60 */
/***/ ((module) => {

/**
 * Checks if `value` is the
 * [language type](http://www.ecma-international.org/ecma-262/7.0/#sec-ecmascript-language-types)
 * of `Object`. (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
 * @example
 *
 * _.isObject({});
 * // => true
 *
 * _.isObject([1, 2, 3]);
 * // => true
 *
 * _.isObject(_.noop);
 * // => true
 *
 * _.isObject(null);
 * // => false
 */
function isObject(value) {
  var type = typeof value;
  return value != null && (type == 'object' || type == 'function');
}

module.exports = isObject;


/***/ }),
/* 61 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var coreJsData = __webpack_require__(62);

/** Used to detect methods masquerading as native. */
var maskSrcKey = (function() {
  var uid = /[^.]+$/.exec(coreJsData && coreJsData.keys && coreJsData.keys.IE_PROTO || '');
  return uid ? ('Symbol(src)_1.' + uid) : '';
}());

/**
 * Checks if `func` has its source masked.
 *
 * @private
 * @param {Function} func The function to check.
 * @returns {boolean} Returns `true` if `func` is masked, else `false`.
 */
function isMasked(func) {
  return !!maskSrcKey && (maskSrcKey in func);
}

module.exports = isMasked;


/***/ }),
/* 62 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var root = __webpack_require__(56);

/** Used to detect overreaching core-js shims. */
var coreJsData = root['__core-js_shared__'];

module.exports = coreJsData;


/***/ }),
/* 63 */
/***/ ((module) => {

/** Used for built-in method references. */
var funcProto = Function.prototype;

/** Used to resolve the decompiled source of functions. */
var funcToString = funcProto.toString;

/**
 * Converts `func` to its source code.
 *
 * @private
 * @param {Function} func The function to convert.
 * @returns {string} Returns the source code.
 */
function toSource(func) {
  if (func != null) {
    try {
      return funcToString.call(func);
    } catch (e) {}
    try {
      return (func + '');
    } catch (e) {}
  }
  return '';
}

module.exports = toSource;


/***/ }),
/* 64 */
/***/ ((module) => {

/**
 * Gets the value at `key` of `object`.
 *
 * @private
 * @param {Object} [object] The object to query.
 * @param {string} key The key of the property to get.
 * @returns {*} Returns the property value.
 */
function getValue(object, key) {
  return object == null ? undefined : object[key];
}

module.exports = getValue;


/***/ }),
/* 65 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var mapCacheClear = __webpack_require__(66),
    mapCacheDelete = __webpack_require__(74),
    mapCacheGet = __webpack_require__(77),
    mapCacheHas = __webpack_require__(78),
    mapCacheSet = __webpack_require__(79);

/**
 * Creates a map cache object to store key-value pairs.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */
function MapCache(entries) {
  var index = -1,
      length = entries == null ? 0 : entries.length;

  this.clear();
  while (++index < length) {
    var entry = entries[index];
    this.set(entry[0], entry[1]);
  }
}

// Add methods to `MapCache`.
MapCache.prototype.clear = mapCacheClear;
MapCache.prototype['delete'] = mapCacheDelete;
MapCache.prototype.get = mapCacheGet;
MapCache.prototype.has = mapCacheHas;
MapCache.prototype.set = mapCacheSet;

module.exports = MapCache;


/***/ }),
/* 66 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Hash = __webpack_require__(67),
    ListCache = __webpack_require__(37),
    Map = __webpack_require__(50);

/**
 * Removes all key-value entries from the map.
 *
 * @private
 * @name clear
 * @memberOf MapCache
 */
function mapCacheClear() {
  this.size = 0;
  this.__data__ = {
    'hash': new Hash,
    'map': new (Map || ListCache),
    'string': new Hash
  };
}

module.exports = mapCacheClear;


/***/ }),
/* 67 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var hashClear = __webpack_require__(68),
    hashDelete = __webpack_require__(70),
    hashGet = __webpack_require__(71),
    hashHas = __webpack_require__(72),
    hashSet = __webpack_require__(73);

/**
 * Creates a hash object.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */
function Hash(entries) {
  var index = -1,
      length = entries == null ? 0 : entries.length;

  this.clear();
  while (++index < length) {
    var entry = entries[index];
    this.set(entry[0], entry[1]);
  }
}

// Add methods to `Hash`.
Hash.prototype.clear = hashClear;
Hash.prototype['delete'] = hashDelete;
Hash.prototype.get = hashGet;
Hash.prototype.has = hashHas;
Hash.prototype.set = hashSet;

module.exports = Hash;


/***/ }),
/* 68 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var nativeCreate = __webpack_require__(69);

/**
 * Removes all key-value entries from the hash.
 *
 * @private
 * @name clear
 * @memberOf Hash
 */
function hashClear() {
  this.__data__ = nativeCreate ? nativeCreate(null) : {};
  this.size = 0;
}

module.exports = hashClear;


/***/ }),
/* 69 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51);

/* Built-in method references that are verified to be native. */
var nativeCreate = getNative(Object, 'create');

module.exports = nativeCreate;


/***/ }),
/* 70 */
/***/ ((module) => {

/**
 * Removes `key` and its value from the hash.
 *
 * @private
 * @name delete
 * @memberOf Hash
 * @param {Object} hash The hash to modify.
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */
function hashDelete(key) {
  var result = this.has(key) && delete this.__data__[key];
  this.size -= result ? 1 : 0;
  return result;
}

module.exports = hashDelete;


/***/ }),
/* 71 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var nativeCreate = __webpack_require__(69);

/** Used to stand-in for `undefined` hash values. */
var HASH_UNDEFINED = '__lodash_hash_undefined__';

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Gets the hash value for `key`.
 *
 * @private
 * @name get
 * @memberOf Hash
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */
function hashGet(key) {
  var data = this.__data__;
  if (nativeCreate) {
    var result = data[key];
    return result === HASH_UNDEFINED ? undefined : result;
  }
  return hasOwnProperty.call(data, key) ? data[key] : undefined;
}

module.exports = hashGet;


/***/ }),
/* 72 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var nativeCreate = __webpack_require__(69);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Checks if a hash value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf Hash
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */
function hashHas(key) {
  var data = this.__data__;
  return nativeCreate ? (data[key] !== undefined) : hasOwnProperty.call(data, key);
}

module.exports = hashHas;


/***/ }),
/* 73 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var nativeCreate = __webpack_require__(69);

/** Used to stand-in for `undefined` hash values. */
var HASH_UNDEFINED = '__lodash_hash_undefined__';

/**
 * Sets the hash `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf Hash
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the hash instance.
 */
function hashSet(key, value) {
  var data = this.__data__;
  this.size += this.has(key) ? 0 : 1;
  data[key] = (nativeCreate && value === undefined) ? HASH_UNDEFINED : value;
  return this;
}

module.exports = hashSet;


/***/ }),
/* 74 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getMapData = __webpack_require__(75);

/**
 * Removes `key` and its value from the map.
 *
 * @private
 * @name delete
 * @memberOf MapCache
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */
function mapCacheDelete(key) {
  var result = getMapData(this, key)['delete'](key);
  this.size -= result ? 1 : 0;
  return result;
}

module.exports = mapCacheDelete;


/***/ }),
/* 75 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isKeyable = __webpack_require__(76);

/**
 * Gets the data for `map`.
 *
 * @private
 * @param {Object} map The map to query.
 * @param {string} key The reference key.
 * @returns {*} Returns the map data.
 */
function getMapData(map, key) {
  var data = map.__data__;
  return isKeyable(key)
    ? data[typeof key == 'string' ? 'string' : 'hash']
    : data.map;
}

module.exports = getMapData;


/***/ }),
/* 76 */
/***/ ((module) => {

/**
 * Checks if `value` is suitable for use as unique object key.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is suitable, else `false`.
 */
function isKeyable(value) {
  var type = typeof value;
  return (type == 'string' || type == 'number' || type == 'symbol' || type == 'boolean')
    ? (value !== '__proto__')
    : (value === null);
}

module.exports = isKeyable;


/***/ }),
/* 77 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getMapData = __webpack_require__(75);

/**
 * Gets the map value for `key`.
 *
 * @private
 * @name get
 * @memberOf MapCache
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */
function mapCacheGet(key) {
  return getMapData(this, key).get(key);
}

module.exports = mapCacheGet;


/***/ }),
/* 78 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getMapData = __webpack_require__(75);

/**
 * Checks if a map value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf MapCache
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */
function mapCacheHas(key) {
  return getMapData(this, key).has(key);
}

module.exports = mapCacheHas;


/***/ }),
/* 79 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getMapData = __webpack_require__(75);

/**
 * Sets the map `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf MapCache
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the map cache instance.
 */
function mapCacheSet(key, value) {
  var data = getMapData(this, key),
      size = data.size;

  data.set(key, value);
  this.size += data.size == size ? 0 : 1;
  return this;
}

module.exports = mapCacheSet;


/***/ }),
/* 80 */
/***/ ((module) => {

/**
 * A specialized version of `_.forEach` for arrays without support for
 * iteratee shorthands.
 *
 * @private
 * @param {Array} [array] The array to iterate over.
 * @param {Function} iteratee The function invoked per iteration.
 * @returns {Array} Returns `array`.
 */
function arrayEach(array, iteratee) {
  var index = -1,
      length = array == null ? 0 : array.length;

  while (++index < length) {
    if (iteratee(array[index], index, array) === false) {
      break;
    }
  }
  return array;
}

module.exports = arrayEach;


/***/ }),
/* 81 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseAssignValue = __webpack_require__(82),
    eq = __webpack_require__(41);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Assigns `value` to `key` of `object` if the existing value is not equivalent
 * using [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
 * for equality comparisons.
 *
 * @private
 * @param {Object} object The object to modify.
 * @param {string} key The key of the property to assign.
 * @param {*} value The value to assign.
 */
function assignValue(object, key, value) {
  var objValue = object[key];
  if (!(hasOwnProperty.call(object, key) && eq(objValue, value)) ||
      (value === undefined && !(key in object))) {
    baseAssignValue(object, key, value);
  }
}

module.exports = assignValue;


/***/ }),
/* 82 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var defineProperty = __webpack_require__(83);

/**
 * The base implementation of `assignValue` and `assignMergeValue` without
 * value checks.
 *
 * @private
 * @param {Object} object The object to modify.
 * @param {string} key The key of the property to assign.
 * @param {*} value The value to assign.
 */
function baseAssignValue(object, key, value) {
  if (key == '__proto__' && defineProperty) {
    defineProperty(object, key, {
      'configurable': true,
      'enumerable': true,
      'value': value,
      'writable': true
    });
  } else {
    object[key] = value;
  }
}

module.exports = baseAssignValue;


/***/ }),
/* 83 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51);

var defineProperty = (function() {
  try {
    var func = getNative(Object, 'defineProperty');
    func({}, '', {});
    return func;
  } catch (e) {}
}());

module.exports = defineProperty;


/***/ }),
/* 84 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var copyObject = __webpack_require__(85),
    keys = __webpack_require__(86);

/**
 * The base implementation of `_.assign` without support for multiple sources
 * or `customizer` functions.
 *
 * @private
 * @param {Object} object The destination object.
 * @param {Object} source The source object.
 * @returns {Object} Returns `object`.
 */
function baseAssign(object, source) {
  return object && copyObject(source, keys(source), object);
}

module.exports = baseAssign;


/***/ }),
/* 85 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var assignValue = __webpack_require__(81),
    baseAssignValue = __webpack_require__(82);

/**
 * Copies properties of `source` to `object`.
 *
 * @private
 * @param {Object} source The object to copy properties from.
 * @param {Array} props The property identifiers to copy.
 * @param {Object} [object={}] The object to copy properties to.
 * @param {Function} [customizer] The function to customize copied values.
 * @returns {Object} Returns `object`.
 */
function copyObject(source, props, object, customizer) {
  var isNew = !object;
  object || (object = {});

  var index = -1,
      length = props.length;

  while (++index < length) {
    var key = props[index];

    var newValue = customizer
      ? customizer(object[key], source[key], key, object, source)
      : undefined;

    if (newValue === undefined) {
      newValue = source[key];
    }
    if (isNew) {
      baseAssignValue(object, key, newValue);
    } else {
      assignValue(object, key, newValue);
    }
  }
  return object;
}

module.exports = copyObject;


/***/ }),
/* 86 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var arrayLikeKeys = __webpack_require__(87),
    baseKeys = __webpack_require__(101),
    isArrayLike = __webpack_require__(105);

/**
 * Creates an array of the own enumerable property names of `object`.
 *
 * **Note:** Non-object values are coerced to objects. See the
 * [ES spec](http://ecma-international.org/ecma-262/7.0/#sec-object.keys)
 * for more details.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Object
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 * @example
 *
 * function Foo() {
 *   this.a = 1;
 *   this.b = 2;
 * }
 *
 * Foo.prototype.c = 3;
 *
 * _.keys(new Foo);
 * // => ['a', 'b'] (iteration order is not guaranteed)
 *
 * _.keys('hi');
 * // => ['0', '1']
 */
function keys(object) {
  return isArrayLike(object) ? arrayLikeKeys(object) : baseKeys(object);
}

module.exports = keys;


/***/ }),
/* 87 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseTimes = __webpack_require__(88),
    isArguments = __webpack_require__(89),
    isArray = __webpack_require__(92),
    isBuffer = __webpack_require__(93),
    isIndex = __webpack_require__(95),
    isTypedArray = __webpack_require__(96);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Creates an array of the enumerable property names of the array-like `value`.
 *
 * @private
 * @param {*} value The value to query.
 * @param {boolean} inherited Specify returning inherited property names.
 * @returns {Array} Returns the array of property names.
 */
function arrayLikeKeys(value, inherited) {
  var isArr = isArray(value),
      isArg = !isArr && isArguments(value),
      isBuff = !isArr && !isArg && isBuffer(value),
      isType = !isArr && !isArg && !isBuff && isTypedArray(value),
      skipIndexes = isArr || isArg || isBuff || isType,
      result = skipIndexes ? baseTimes(value.length, String) : [],
      length = result.length;

  for (var key in value) {
    if ((inherited || hasOwnProperty.call(value, key)) &&
        !(skipIndexes && (
           // Safari 9 has enumerable `arguments.length` in strict mode.
           key == 'length' ||
           // Node.js 0.10 has enumerable non-index properties on buffers.
           (isBuff && (key == 'offset' || key == 'parent')) ||
           // PhantomJS 2 has enumerable non-index properties on typed arrays.
           (isType && (key == 'buffer' || key == 'byteLength' || key == 'byteOffset')) ||
           // Skip index properties.
           isIndex(key, length)
        ))) {
      result.push(key);
    }
  }
  return result;
}

module.exports = arrayLikeKeys;


/***/ }),
/* 88 */
/***/ ((module) => {

/**
 * The base implementation of `_.times` without support for iteratee shorthands
 * or max array length checks.
 *
 * @private
 * @param {number} n The number of times to invoke `iteratee`.
 * @param {Function} iteratee The function invoked per iteration.
 * @returns {Array} Returns the array of results.
 */
function baseTimes(n, iteratee) {
  var index = -1,
      result = Array(n);

  while (++index < n) {
    result[index] = iteratee(index);
  }
  return result;
}

module.exports = baseTimes;


/***/ }),
/* 89 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsArguments = __webpack_require__(90),
    isObjectLike = __webpack_require__(91);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/** Built-in value references. */
var propertyIsEnumerable = objectProto.propertyIsEnumerable;

/**
 * Checks if `value` is likely an `arguments` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an `arguments` object,
 *  else `false`.
 * @example
 *
 * _.isArguments(function() { return arguments; }());
 * // => true
 *
 * _.isArguments([1, 2, 3]);
 * // => false
 */
var isArguments = baseIsArguments(function() { return arguments; }()) ? baseIsArguments : function(value) {
  return isObjectLike(value) && hasOwnProperty.call(value, 'callee') &&
    !propertyIsEnumerable.call(value, 'callee');
};

module.exports = isArguments;


/***/ }),
/* 90 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(54),
    isObjectLike = __webpack_require__(91);

/** `Object#toString` result references. */
var argsTag = '[object Arguments]';

/**
 * The base implementation of `_.isArguments`.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an `arguments` object,
 */
function baseIsArguments(value) {
  return isObjectLike(value) && baseGetTag(value) == argsTag;
}

module.exports = baseIsArguments;


/***/ }),
/* 91 */
/***/ ((module) => {

/**
 * Checks if `value` is object-like. A value is object-like if it's not `null`
 * and has a `typeof` result of "object".
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
 * @example
 *
 * _.isObjectLike({});
 * // => true
 *
 * _.isObjectLike([1, 2, 3]);
 * // => true
 *
 * _.isObjectLike(_.noop);
 * // => false
 *
 * _.isObjectLike(null);
 * // => false
 */
function isObjectLike(value) {
  return value != null && typeof value == 'object';
}

module.exports = isObjectLike;


/***/ }),
/* 92 */
/***/ ((module) => {

/**
 * Checks if `value` is classified as an `Array` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an array, else `false`.
 * @example
 *
 * _.isArray([1, 2, 3]);
 * // => true
 *
 * _.isArray(document.body.children);
 * // => false
 *
 * _.isArray('abc');
 * // => false
 *
 * _.isArray(_.noop);
 * // => false
 */
var isArray = Array.isArray;

module.exports = isArray;


/***/ }),
/* 93 */
/***/ ((module, exports, __webpack_require__) => {

/* module decorator */ module = __webpack_require__.nmd(module);
var root = __webpack_require__(56),
    stubFalse = __webpack_require__(94);

/** Detect free variable `exports`. */
var freeExports =  true && exports && !exports.nodeType && exports;

/** Detect free variable `module`. */
var freeModule = freeExports && "object" == 'object' && module && !module.nodeType && module;

/** Detect the popular CommonJS extension `module.exports`. */
var moduleExports = freeModule && freeModule.exports === freeExports;

/** Built-in value references. */
var Buffer = moduleExports ? root.Buffer : undefined;

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeIsBuffer = Buffer ? Buffer.isBuffer : undefined;

/**
 * Checks if `value` is a buffer.
 *
 * @static
 * @memberOf _
 * @since 4.3.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a buffer, else `false`.
 * @example
 *
 * _.isBuffer(new Buffer(2));
 * // => true
 *
 * _.isBuffer(new Uint8Array(2));
 * // => false
 */
var isBuffer = nativeIsBuffer || stubFalse;

module.exports = isBuffer;


/***/ }),
/* 94 */
/***/ ((module) => {

/**
 * This method returns `false`.
 *
 * @static
 * @memberOf _
 * @since 4.13.0
 * @category Util
 * @returns {boolean} Returns `false`.
 * @example
 *
 * _.times(2, _.stubFalse);
 * // => [false, false]
 */
function stubFalse() {
  return false;
}

module.exports = stubFalse;


/***/ }),
/* 95 */
/***/ ((module) => {

/** Used as references for various `Number` constants. */
var MAX_SAFE_INTEGER = 9007199254740991;

/** Used to detect unsigned integer values. */
var reIsUint = /^(?:0|[1-9]\d*)$/;

/**
 * Checks if `value` is a valid array-like index.
 *
 * @private
 * @param {*} value The value to check.
 * @param {number} [length=MAX_SAFE_INTEGER] The upper bounds of a valid index.
 * @returns {boolean} Returns `true` if `value` is a valid index, else `false`.
 */
function isIndex(value, length) {
  var type = typeof value;
  length = length == null ? MAX_SAFE_INTEGER : length;

  return !!length &&
    (type == 'number' ||
      (type != 'symbol' && reIsUint.test(value))) &&
        (value > -1 && value % 1 == 0 && value < length);
}

module.exports = isIndex;


/***/ }),
/* 96 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsTypedArray = __webpack_require__(97),
    baseUnary = __webpack_require__(99),
    nodeUtil = __webpack_require__(100);

/* Node.js helper references. */
var nodeIsTypedArray = nodeUtil && nodeUtil.isTypedArray;

/**
 * Checks if `value` is classified as a typed array.
 *
 * @static
 * @memberOf _
 * @since 3.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a typed array, else `false`.
 * @example
 *
 * _.isTypedArray(new Uint8Array);
 * // => true
 *
 * _.isTypedArray([]);
 * // => false
 */
var isTypedArray = nodeIsTypedArray ? baseUnary(nodeIsTypedArray) : baseIsTypedArray;

module.exports = isTypedArray;


/***/ }),
/* 97 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetTag = __webpack_require__(54),
    isLength = __webpack_require__(98),
    isObjectLike = __webpack_require__(91);

/** `Object#toString` result references. */
var argsTag = '[object Arguments]',
    arrayTag = '[object Array]',
    boolTag = '[object Boolean]',
    dateTag = '[object Date]',
    errorTag = '[object Error]',
    funcTag = '[object Function]',
    mapTag = '[object Map]',
    numberTag = '[object Number]',
    objectTag = '[object Object]',
    regexpTag = '[object RegExp]',
    setTag = '[object Set]',
    stringTag = '[object String]',
    weakMapTag = '[object WeakMap]';

var arrayBufferTag = '[object ArrayBuffer]',
    dataViewTag = '[object DataView]',
    float32Tag = '[object Float32Array]',
    float64Tag = '[object Float64Array]',
    int8Tag = '[object Int8Array]',
    int16Tag = '[object Int16Array]',
    int32Tag = '[object Int32Array]',
    uint8Tag = '[object Uint8Array]',
    uint8ClampedTag = '[object Uint8ClampedArray]',
    uint16Tag = '[object Uint16Array]',
    uint32Tag = '[object Uint32Array]';

/** Used to identify `toStringTag` values of typed arrays. */
var typedArrayTags = {};
typedArrayTags[float32Tag] = typedArrayTags[float64Tag] =
typedArrayTags[int8Tag] = typedArrayTags[int16Tag] =
typedArrayTags[int32Tag] = typedArrayTags[uint8Tag] =
typedArrayTags[uint8ClampedTag] = typedArrayTags[uint16Tag] =
typedArrayTags[uint32Tag] = true;
typedArrayTags[argsTag] = typedArrayTags[arrayTag] =
typedArrayTags[arrayBufferTag] = typedArrayTags[boolTag] =
typedArrayTags[dataViewTag] = typedArrayTags[dateTag] =
typedArrayTags[errorTag] = typedArrayTags[funcTag] =
typedArrayTags[mapTag] = typedArrayTags[numberTag] =
typedArrayTags[objectTag] = typedArrayTags[regexpTag] =
typedArrayTags[setTag] = typedArrayTags[stringTag] =
typedArrayTags[weakMapTag] = false;

/**
 * The base implementation of `_.isTypedArray` without Node.js optimizations.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a typed array, else `false`.
 */
function baseIsTypedArray(value) {
  return isObjectLike(value) &&
    isLength(value.length) && !!typedArrayTags[baseGetTag(value)];
}

module.exports = baseIsTypedArray;


/***/ }),
/* 98 */
/***/ ((module) => {

/** Used as references for various `Number` constants. */
var MAX_SAFE_INTEGER = 9007199254740991;

/**
 * Checks if `value` is a valid array-like length.
 *
 * **Note:** This method is loosely based on
 * [`ToLength`](http://ecma-international.org/ecma-262/7.0/#sec-tolength).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a valid length, else `false`.
 * @example
 *
 * _.isLength(3);
 * // => true
 *
 * _.isLength(Number.MIN_VALUE);
 * // => false
 *
 * _.isLength(Infinity);
 * // => false
 *
 * _.isLength('3');
 * // => false
 */
function isLength(value) {
  return typeof value == 'number' &&
    value > -1 && value % 1 == 0 && value <= MAX_SAFE_INTEGER;
}

module.exports = isLength;


/***/ }),
/* 99 */
/***/ ((module) => {

/**
 * The base implementation of `_.unary` without support for storing metadata.
 *
 * @private
 * @param {Function} func The function to cap arguments for.
 * @returns {Function} Returns the new capped function.
 */
function baseUnary(func) {
  return function(value) {
    return func(value);
  };
}

module.exports = baseUnary;


/***/ }),
/* 100 */
/***/ ((module, exports, __webpack_require__) => {

/* module decorator */ module = __webpack_require__.nmd(module);
var freeGlobal = __webpack_require__(57);

/** Detect free variable `exports`. */
var freeExports =  true && exports && !exports.nodeType && exports;

/** Detect free variable `module`. */
var freeModule = freeExports && "object" == 'object' && module && !module.nodeType && module;

/** Detect the popular CommonJS extension `module.exports`. */
var moduleExports = freeModule && freeModule.exports === freeExports;

/** Detect free variable `process` from Node.js. */
var freeProcess = moduleExports && freeGlobal.process;

/** Used to access faster Node.js helpers. */
var nodeUtil = (function() {
  try {
    // Use `util.types` for Node.js 10+.
    var types = freeModule && freeModule.require && freeModule.require('util').types;

    if (types) {
      return types;
    }

    // Legacy `process.binding('util')` for Node.js < 10.
    return freeProcess && freeProcess.binding && freeProcess.binding('util');
  } catch (e) {}
}());

module.exports = nodeUtil;


/***/ }),
/* 101 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isPrototype = __webpack_require__(102),
    nativeKeys = __webpack_require__(103);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * The base implementation of `_.keys` which doesn't treat sparse arrays as dense.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 */
function baseKeys(object) {
  if (!isPrototype(object)) {
    return nativeKeys(object);
  }
  var result = [];
  for (var key in Object(object)) {
    if (hasOwnProperty.call(object, key) && key != 'constructor') {
      result.push(key);
    }
  }
  return result;
}

module.exports = baseKeys;


/***/ }),
/* 102 */
/***/ ((module) => {

/** Used for built-in method references. */
var objectProto = Object.prototype;

/**
 * Checks if `value` is likely a prototype object.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a prototype, else `false`.
 */
function isPrototype(value) {
  var Ctor = value && value.constructor,
      proto = (typeof Ctor == 'function' && Ctor.prototype) || objectProto;

  return value === proto;
}

module.exports = isPrototype;


/***/ }),
/* 103 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var overArg = __webpack_require__(104);

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeKeys = overArg(Object.keys, Object);

module.exports = nativeKeys;


/***/ }),
/* 104 */
/***/ ((module) => {

/**
 * Creates a unary function that invokes `func` with its argument transformed.
 *
 * @private
 * @param {Function} func The function to wrap.
 * @param {Function} transform The argument transform.
 * @returns {Function} Returns the new function.
 */
function overArg(func, transform) {
  return function(arg) {
    return func(transform(arg));
  };
}

module.exports = overArg;


/***/ }),
/* 105 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isFunction = __webpack_require__(53),
    isLength = __webpack_require__(98);

/**
 * Checks if `value` is array-like. A value is considered array-like if it's
 * not a function and has a `value.length` that's an integer greater than or
 * equal to `0` and less than or equal to `Number.MAX_SAFE_INTEGER`.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is array-like, else `false`.
 * @example
 *
 * _.isArrayLike([1, 2, 3]);
 * // => true
 *
 * _.isArrayLike(document.body.children);
 * // => true
 *
 * _.isArrayLike('abc');
 * // => true
 *
 * _.isArrayLike(_.noop);
 * // => false
 */
function isArrayLike(value) {
  return value != null && isLength(value.length) && !isFunction(value);
}

module.exports = isArrayLike;


/***/ }),
/* 106 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var copyObject = __webpack_require__(85),
    keysIn = __webpack_require__(107);

/**
 * The base implementation of `_.assignIn` without support for multiple sources
 * or `customizer` functions.
 *
 * @private
 * @param {Object} object The destination object.
 * @param {Object} source The source object.
 * @returns {Object} Returns `object`.
 */
function baseAssignIn(object, source) {
  return object && copyObject(source, keysIn(source), object);
}

module.exports = baseAssignIn;


/***/ }),
/* 107 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var arrayLikeKeys = __webpack_require__(87),
    baseKeysIn = __webpack_require__(108),
    isArrayLike = __webpack_require__(105);

/**
 * Creates an array of the own and inherited enumerable property names of `object`.
 *
 * **Note:** Non-object values are coerced to objects.
 *
 * @static
 * @memberOf _
 * @since 3.0.0
 * @category Object
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 * @example
 *
 * function Foo() {
 *   this.a = 1;
 *   this.b = 2;
 * }
 *
 * Foo.prototype.c = 3;
 *
 * _.keysIn(new Foo);
 * // => ['a', 'b', 'c'] (iteration order is not guaranteed)
 */
function keysIn(object) {
  return isArrayLike(object) ? arrayLikeKeys(object, true) : baseKeysIn(object);
}

module.exports = keysIn;


/***/ }),
/* 108 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isObject = __webpack_require__(60),
    isPrototype = __webpack_require__(102),
    nativeKeysIn = __webpack_require__(109);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * The base implementation of `_.keysIn` which doesn't treat sparse arrays as dense.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 */
function baseKeysIn(object) {
  if (!isObject(object)) {
    return nativeKeysIn(object);
  }
  var isProto = isPrototype(object),
      result = [];

  for (var key in object) {
    if (!(key == 'constructor' && (isProto || !hasOwnProperty.call(object, key)))) {
      result.push(key);
    }
  }
  return result;
}

module.exports = baseKeysIn;


/***/ }),
/* 109 */
/***/ ((module) => {

/**
 * This function is like
 * [`Object.keys`](http://ecma-international.org/ecma-262/7.0/#sec-object.keys)
 * except that it includes inherited enumerable properties.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names.
 */
function nativeKeysIn(object) {
  var result = [];
  if (object != null) {
    for (var key in Object(object)) {
      result.push(key);
    }
  }
  return result;
}

module.exports = nativeKeysIn;


/***/ }),
/* 110 */
/***/ ((module, exports, __webpack_require__) => {

/* module decorator */ module = __webpack_require__.nmd(module);
var root = __webpack_require__(56);

/** Detect free variable `exports`. */
var freeExports =  true && exports && !exports.nodeType && exports;

/** Detect free variable `module`. */
var freeModule = freeExports && "object" == 'object' && module && !module.nodeType && module;

/** Detect the popular CommonJS extension `module.exports`. */
var moduleExports = freeModule && freeModule.exports === freeExports;

/** Built-in value references. */
var Buffer = moduleExports ? root.Buffer : undefined,
    allocUnsafe = Buffer ? Buffer.allocUnsafe : undefined;

/**
 * Creates a clone of  `buffer`.
 *
 * @private
 * @param {Buffer} buffer The buffer to clone.
 * @param {boolean} [isDeep] Specify a deep clone.
 * @returns {Buffer} Returns the cloned buffer.
 */
function cloneBuffer(buffer, isDeep) {
  if (isDeep) {
    return buffer.slice();
  }
  var length = buffer.length,
      result = allocUnsafe ? allocUnsafe(length) : new buffer.constructor(length);

  buffer.copy(result);
  return result;
}

module.exports = cloneBuffer;


/***/ }),
/* 111 */
/***/ ((module) => {

/**
 * Copies the values of `source` to `array`.
 *
 * @private
 * @param {Array} source The array to copy values from.
 * @param {Array} [array=[]] The array to copy values to.
 * @returns {Array} Returns `array`.
 */
function copyArray(source, array) {
  var index = -1,
      length = source.length;

  array || (array = Array(length));
  while (++index < length) {
    array[index] = source[index];
  }
  return array;
}

module.exports = copyArray;


/***/ }),
/* 112 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var copyObject = __webpack_require__(85),
    getSymbols = __webpack_require__(113);

/**
 * Copies own symbols of `source` to `object`.
 *
 * @private
 * @param {Object} source The object to copy symbols from.
 * @param {Object} [object={}] The object to copy symbols to.
 * @returns {Object} Returns `object`.
 */
function copySymbols(source, object) {
  return copyObject(source, getSymbols(source), object);
}

module.exports = copySymbols;


/***/ }),
/* 113 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var arrayFilter = __webpack_require__(114),
    stubArray = __webpack_require__(115);

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Built-in value references. */
var propertyIsEnumerable = objectProto.propertyIsEnumerable;

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeGetSymbols = Object.getOwnPropertySymbols;

/**
 * Creates an array of the own enumerable symbols of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of symbols.
 */
var getSymbols = !nativeGetSymbols ? stubArray : function(object) {
  if (object == null) {
    return [];
  }
  object = Object(object);
  return arrayFilter(nativeGetSymbols(object), function(symbol) {
    return propertyIsEnumerable.call(object, symbol);
  });
};

module.exports = getSymbols;


/***/ }),
/* 114 */
/***/ ((module) => {

/**
 * A specialized version of `_.filter` for arrays without support for
 * iteratee shorthands.
 *
 * @private
 * @param {Array} [array] The array to iterate over.
 * @param {Function} predicate The function invoked per iteration.
 * @returns {Array} Returns the new filtered array.
 */
function arrayFilter(array, predicate) {
  var index = -1,
      length = array == null ? 0 : array.length,
      resIndex = 0,
      result = [];

  while (++index < length) {
    var value = array[index];
    if (predicate(value, index, array)) {
      result[resIndex++] = value;
    }
  }
  return result;
}

module.exports = arrayFilter;


/***/ }),
/* 115 */
/***/ ((module) => {

/**
 * This method returns a new empty array.
 *
 * @static
 * @memberOf _
 * @since 4.13.0
 * @category Util
 * @returns {Array} Returns the new empty array.
 * @example
 *
 * var arrays = _.times(2, _.stubArray);
 *
 * console.log(arrays);
 * // => [[], []]
 *
 * console.log(arrays[0] === arrays[1]);
 * // => false
 */
function stubArray() {
  return [];
}

module.exports = stubArray;


/***/ }),
/* 116 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var copyObject = __webpack_require__(85),
    getSymbolsIn = __webpack_require__(117);

/**
 * Copies own and inherited symbols of `source` to `object`.
 *
 * @private
 * @param {Object} source The object to copy symbols from.
 * @param {Object} [object={}] The object to copy symbols to.
 * @returns {Object} Returns `object`.
 */
function copySymbolsIn(source, object) {
  return copyObject(source, getSymbolsIn(source), object);
}

module.exports = copySymbolsIn;


/***/ }),
/* 117 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var arrayPush = __webpack_require__(118),
    getPrototype = __webpack_require__(119),
    getSymbols = __webpack_require__(113),
    stubArray = __webpack_require__(115);

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeGetSymbols = Object.getOwnPropertySymbols;

/**
 * Creates an array of the own and inherited enumerable symbols of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of symbols.
 */
var getSymbolsIn = !nativeGetSymbols ? stubArray : function(object) {
  var result = [];
  while (object) {
    arrayPush(result, getSymbols(object));
    object = getPrototype(object);
  }
  return result;
};

module.exports = getSymbolsIn;


/***/ }),
/* 118 */
/***/ ((module) => {

/**
 * Appends the elements of `values` to `array`.
 *
 * @private
 * @param {Array} array The array to modify.
 * @param {Array} values The values to append.
 * @returns {Array} Returns `array`.
 */
function arrayPush(array, values) {
  var index = -1,
      length = values.length,
      offset = array.length;

  while (++index < length) {
    array[offset + index] = values[index];
  }
  return array;
}

module.exports = arrayPush;


/***/ }),
/* 119 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var overArg = __webpack_require__(104);

/** Built-in value references. */
var getPrototype = overArg(Object.getPrototypeOf, Object);

module.exports = getPrototype;


/***/ }),
/* 120 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetAllKeys = __webpack_require__(121),
    getSymbols = __webpack_require__(113),
    keys = __webpack_require__(86);

/**
 * Creates an array of own enumerable property names and symbols of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names and symbols.
 */
function getAllKeys(object) {
  return baseGetAllKeys(object, keys, getSymbols);
}

module.exports = getAllKeys;


/***/ }),
/* 121 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var arrayPush = __webpack_require__(118),
    isArray = __webpack_require__(92);

/**
 * The base implementation of `getAllKeys` and `getAllKeysIn` which uses
 * `keysFunc` and `symbolsFunc` to get the enumerable property names and
 * symbols of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @param {Function} keysFunc The function to get the keys of `object`.
 * @param {Function} symbolsFunc The function to get the symbols of `object`.
 * @returns {Array} Returns the array of property names and symbols.
 */
function baseGetAllKeys(object, keysFunc, symbolsFunc) {
  var result = keysFunc(object);
  return isArray(object) ? result : arrayPush(result, symbolsFunc(object));
}

module.exports = baseGetAllKeys;


/***/ }),
/* 122 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseGetAllKeys = __webpack_require__(121),
    getSymbolsIn = __webpack_require__(117),
    keysIn = __webpack_require__(107);

/**
 * Creates an array of own and inherited enumerable property names and
 * symbols of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @returns {Array} Returns the array of property names and symbols.
 */
function getAllKeysIn(object) {
  return baseGetAllKeys(object, keysIn, getSymbolsIn);
}

module.exports = getAllKeysIn;


/***/ }),
/* 123 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var DataView = __webpack_require__(124),
    Map = __webpack_require__(50),
    Promise = __webpack_require__(125),
    Set = __webpack_require__(126),
    WeakMap = __webpack_require__(127),
    baseGetTag = __webpack_require__(54),
    toSource = __webpack_require__(63);

/** `Object#toString` result references. */
var mapTag = '[object Map]',
    objectTag = '[object Object]',
    promiseTag = '[object Promise]',
    setTag = '[object Set]',
    weakMapTag = '[object WeakMap]';

var dataViewTag = '[object DataView]';

/** Used to detect maps, sets, and weakmaps. */
var dataViewCtorString = toSource(DataView),
    mapCtorString = toSource(Map),
    promiseCtorString = toSource(Promise),
    setCtorString = toSource(Set),
    weakMapCtorString = toSource(WeakMap);

/**
 * Gets the `toStringTag` of `value`.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the `toStringTag`.
 */
var getTag = baseGetTag;

// Fallback for data views, maps, sets, and weak maps in IE 11 and promises in Node.js < 6.
if ((DataView && getTag(new DataView(new ArrayBuffer(1))) != dataViewTag) ||
    (Map && getTag(new Map) != mapTag) ||
    (Promise && getTag(Promise.resolve()) != promiseTag) ||
    (Set && getTag(new Set) != setTag) ||
    (WeakMap && getTag(new WeakMap) != weakMapTag)) {
  getTag = function(value) {
    var result = baseGetTag(value),
        Ctor = result == objectTag ? value.constructor : undefined,
        ctorString = Ctor ? toSource(Ctor) : '';

    if (ctorString) {
      switch (ctorString) {
        case dataViewCtorString: return dataViewTag;
        case mapCtorString: return mapTag;
        case promiseCtorString: return promiseTag;
        case setCtorString: return setTag;
        case weakMapCtorString: return weakMapTag;
      }
    }
    return result;
  };
}

module.exports = getTag;


/***/ }),
/* 124 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51),
    root = __webpack_require__(56);

/* Built-in method references that are verified to be native. */
var DataView = getNative(root, 'DataView');

module.exports = DataView;


/***/ }),
/* 125 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51),
    root = __webpack_require__(56);

/* Built-in method references that are verified to be native. */
var Promise = getNative(root, 'Promise');

module.exports = Promise;


/***/ }),
/* 126 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51),
    root = __webpack_require__(56);

/* Built-in method references that are verified to be native. */
var Set = getNative(root, 'Set');

module.exports = Set;


/***/ }),
/* 127 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getNative = __webpack_require__(51),
    root = __webpack_require__(56);

/* Built-in method references that are verified to be native. */
var WeakMap = getNative(root, 'WeakMap');

module.exports = WeakMap;


/***/ }),
/* 128 */
/***/ ((module) => {

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * Initializes an array clone.
 *
 * @private
 * @param {Array} array The array to clone.
 * @returns {Array} Returns the initialized clone.
 */
function initCloneArray(array) {
  var length = array.length,
      result = new array.constructor(length);

  // Add properties assigned by `RegExp#exec`.
  if (length && typeof array[0] == 'string' && hasOwnProperty.call(array, 'index')) {
    result.index = array.index;
    result.input = array.input;
  }
  return result;
}

module.exports = initCloneArray;


/***/ }),
/* 129 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var cloneArrayBuffer = __webpack_require__(130),
    cloneDataView = __webpack_require__(132),
    cloneRegExp = __webpack_require__(133),
    cloneSymbol = __webpack_require__(134),
    cloneTypedArray = __webpack_require__(135);

/** `Object#toString` result references. */
var boolTag = '[object Boolean]',
    dateTag = '[object Date]',
    mapTag = '[object Map]',
    numberTag = '[object Number]',
    regexpTag = '[object RegExp]',
    setTag = '[object Set]',
    stringTag = '[object String]',
    symbolTag = '[object Symbol]';

var arrayBufferTag = '[object ArrayBuffer]',
    dataViewTag = '[object DataView]',
    float32Tag = '[object Float32Array]',
    float64Tag = '[object Float64Array]',
    int8Tag = '[object Int8Array]',
    int16Tag = '[object Int16Array]',
    int32Tag = '[object Int32Array]',
    uint8Tag = '[object Uint8Array]',
    uint8ClampedTag = '[object Uint8ClampedArray]',
    uint16Tag = '[object Uint16Array]',
    uint32Tag = '[object Uint32Array]';

/**
 * Initializes an object clone based on its `toStringTag`.
 *
 * **Note:** This function only supports cloning values with tags of
 * `Boolean`, `Date`, `Error`, `Map`, `Number`, `RegExp`, `Set`, or `String`.
 *
 * @private
 * @param {Object} object The object to clone.
 * @param {string} tag The `toStringTag` of the object to clone.
 * @param {boolean} [isDeep] Specify a deep clone.
 * @returns {Object} Returns the initialized clone.
 */
function initCloneByTag(object, tag, isDeep) {
  var Ctor = object.constructor;
  switch (tag) {
    case arrayBufferTag:
      return cloneArrayBuffer(object);

    case boolTag:
    case dateTag:
      return new Ctor(+object);

    case dataViewTag:
      return cloneDataView(object, isDeep);

    case float32Tag: case float64Tag:
    case int8Tag: case int16Tag: case int32Tag:
    case uint8Tag: case uint8ClampedTag: case uint16Tag: case uint32Tag:
      return cloneTypedArray(object, isDeep);

    case mapTag:
      return new Ctor;

    case numberTag:
    case stringTag:
      return new Ctor(object);

    case regexpTag:
      return cloneRegExp(object);

    case setTag:
      return new Ctor;

    case symbolTag:
      return cloneSymbol(object);
  }
}

module.exports = initCloneByTag;


/***/ }),
/* 130 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Uint8Array = __webpack_require__(131);

/**
 * Creates a clone of `arrayBuffer`.
 *
 * @private
 * @param {ArrayBuffer} arrayBuffer The array buffer to clone.
 * @returns {ArrayBuffer} Returns the cloned array buffer.
 */
function cloneArrayBuffer(arrayBuffer) {
  var result = new arrayBuffer.constructor(arrayBuffer.byteLength);
  new Uint8Array(result).set(new Uint8Array(arrayBuffer));
  return result;
}

module.exports = cloneArrayBuffer;


/***/ }),
/* 131 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var root = __webpack_require__(56);

/** Built-in value references. */
var Uint8Array = root.Uint8Array;

module.exports = Uint8Array;


/***/ }),
/* 132 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var cloneArrayBuffer = __webpack_require__(130);

/**
 * Creates a clone of `dataView`.
 *
 * @private
 * @param {Object} dataView The data view to clone.
 * @param {boolean} [isDeep] Specify a deep clone.
 * @returns {Object} Returns the cloned data view.
 */
function cloneDataView(dataView, isDeep) {
  var buffer = isDeep ? cloneArrayBuffer(dataView.buffer) : dataView.buffer;
  return new dataView.constructor(buffer, dataView.byteOffset, dataView.byteLength);
}

module.exports = cloneDataView;


/***/ }),
/* 133 */
/***/ ((module) => {

/** Used to match `RegExp` flags from their coerced string values. */
var reFlags = /\w*$/;

/**
 * Creates a clone of `regexp`.
 *
 * @private
 * @param {Object} regexp The regexp to clone.
 * @returns {Object} Returns the cloned regexp.
 */
function cloneRegExp(regexp) {
  var result = new regexp.constructor(regexp.source, reFlags.exec(regexp));
  result.lastIndex = regexp.lastIndex;
  return result;
}

module.exports = cloneRegExp;


/***/ }),
/* 134 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var Symbol = __webpack_require__(55);

/** Used to convert symbols to primitives and strings. */
var symbolProto = Symbol ? Symbol.prototype : undefined,
    symbolValueOf = symbolProto ? symbolProto.valueOf : undefined;

/**
 * Creates a clone of the `symbol` object.
 *
 * @private
 * @param {Object} symbol The symbol object to clone.
 * @returns {Object} Returns the cloned symbol object.
 */
function cloneSymbol(symbol) {
  return symbolValueOf ? Object(symbolValueOf.call(symbol)) : {};
}

module.exports = cloneSymbol;


/***/ }),
/* 135 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var cloneArrayBuffer = __webpack_require__(130);

/**
 * Creates a clone of `typedArray`.
 *
 * @private
 * @param {Object} typedArray The typed array to clone.
 * @param {boolean} [isDeep] Specify a deep clone.
 * @returns {Object} Returns the cloned typed array.
 */
function cloneTypedArray(typedArray, isDeep) {
  var buffer = isDeep ? cloneArrayBuffer(typedArray.buffer) : typedArray.buffer;
  return new typedArray.constructor(buffer, typedArray.byteOffset, typedArray.length);
}

module.exports = cloneTypedArray;


/***/ }),
/* 136 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseCreate = __webpack_require__(137),
    getPrototype = __webpack_require__(119),
    isPrototype = __webpack_require__(102);

/**
 * Initializes an object clone.
 *
 * @private
 * @param {Object} object The object to clone.
 * @returns {Object} Returns the initialized clone.
 */
function initCloneObject(object) {
  return (typeof object.constructor == 'function' && !isPrototype(object))
    ? baseCreate(getPrototype(object))
    : {};
}

module.exports = initCloneObject;


/***/ }),
/* 137 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var isObject = __webpack_require__(60);

/** Built-in value references. */
var objectCreate = Object.create;

/**
 * The base implementation of `_.create` without support for assigning
 * properties to the created object.
 *
 * @private
 * @param {Object} proto The object to inherit from.
 * @returns {Object} Returns the new object.
 */
var baseCreate = (function() {
  function object() {}
  return function(proto) {
    if (!isObject(proto)) {
      return {};
    }
    if (objectCreate) {
      return objectCreate(proto);
    }
    object.prototype = proto;
    var result = new object;
    object.prototype = undefined;
    return result;
  };
}());

module.exports = baseCreate;


/***/ }),
/* 138 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsMap = __webpack_require__(139),
    baseUnary = __webpack_require__(99),
    nodeUtil = __webpack_require__(100);

/* Node.js helper references. */
var nodeIsMap = nodeUtil && nodeUtil.isMap;

/**
 * Checks if `value` is classified as a `Map` object.
 *
 * @static
 * @memberOf _
 * @since 4.3.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a map, else `false`.
 * @example
 *
 * _.isMap(new Map);
 * // => true
 *
 * _.isMap(new WeakMap);
 * // => false
 */
var isMap = nodeIsMap ? baseUnary(nodeIsMap) : baseIsMap;

module.exports = isMap;


/***/ }),
/* 139 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getTag = __webpack_require__(123),
    isObjectLike = __webpack_require__(91);

/** `Object#toString` result references. */
var mapTag = '[object Map]';

/**
 * The base implementation of `_.isMap` without Node.js optimizations.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a map, else `false`.
 */
function baseIsMap(value) {
  return isObjectLike(value) && getTag(value) == mapTag;
}

module.exports = baseIsMap;


/***/ }),
/* 140 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var baseIsSet = __webpack_require__(141),
    baseUnary = __webpack_require__(99),
    nodeUtil = __webpack_require__(100);

/* Node.js helper references. */
var nodeIsSet = nodeUtil && nodeUtil.isSet;

/**
 * Checks if `value` is classified as a `Set` object.
 *
 * @static
 * @memberOf _
 * @since 4.3.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a set, else `false`.
 * @example
 *
 * _.isSet(new Set);
 * // => true
 *
 * _.isSet(new WeakSet);
 * // => false
 */
var isSet = nodeIsSet ? baseUnary(nodeIsSet) : baseIsSet;

module.exports = isSet;


/***/ }),
/* 141 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var getTag = __webpack_require__(123),
    isObjectLike = __webpack_require__(91);

/** `Object#toString` result references. */
var setTag = '[object Set]';

/**
 * The base implementation of `_.isSet` without Node.js optimizations.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a set, else `false`.
 */
function baseIsSet(value) {
  return isObjectLike(value) && getTag(value) == setTag;
}

module.exports = baseIsSet;


/***/ }),
/* 142 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.parseForComments = exports.generateMarkdownFromCodeLines = exports.appendLineFeed = exports.splitMultilineString = exports.concatMultilineString = void 0;
const SingleQuoteMultiline = "'''";
const DoubleQuoteMultiline = '"""';
function concatMultilineString(str, trim) {
    const nonLineFeedWhiteSpaceTrim = /(^[\t\f\v\r ]+|[\t\f\v\r ]+$)/g;
    if (Array.isArray(str)) {
        let result = '';
        for (let i = 0; i < str.length; i += 1) {
            const s = str[i];
            if (i < str.length - 1 && !s.endsWith('\n')) {
                result = result.concat(`${s}\n`);
            }
            else {
                result = result.concat(s);
            }
        }
        return trim ? result.replace(nonLineFeedWhiteSpaceTrim, '') : result;
    }
    return trim ? str.toString().replace(nonLineFeedWhiteSpaceTrim, '') : str.toString();
}
exports.concatMultilineString = concatMultilineString;
function splitMultilineString(source) {
    if (Array.isArray(source)) {
        return source;
    }
    const str = source.toString();
    if (str.length > 0) {
        const arr = str.split('\n');
        return arr
            .map((s, i) => {
            if (i < arr.length - 1) {
                return `${s}\n`;
            }
            return s;
        })
            .filter((s) => s.length > 0);
    }
    return [];
}
exports.splitMultilineString = splitMultilineString;
function fixBackspace(txt) {
    let tmp = txt;
    do {
        txt = tmp;
        tmp = txt.replace(/[^\n]\x08/gm, '');
    } while (tmp.length < txt.length);
    return txt;
}
function fixCarriageReturn(str) {
    let result = '';
    let previousLinePos = 0;
    for (let i = 0; i < str.length; i += 1) {
        if (str[i] === '\r') {
            if (i < str.length - 1 && str[i + 1] === '\n') {
                result += str.substr(previousLinePos, i - previousLinePos);
                result += '\n';
                previousLinePos = i + 2;
                i += 1;
            }
            else {
                previousLinePos = i + 1;
            }
        }
        else if (str[i] === '\n') {
            result += str.substr(previousLinePos, i - previousLinePos + 1);
            previousLinePos = i + 1;
        }
    }
    result += str.substr(previousLinePos, str.length - previousLinePos);
    return result;
}
function appendLineFeed(arr, modifier) {
    return arr.map((s, i) => {
        const out = modifier ? modifier(s) : s;
        return i === arr.length - 1 ? `${out}` : `${out}\n`;
    });
}
exports.appendLineFeed = appendLineFeed;
function generateMarkdownFromCodeLines(lines) {
    return appendLineFeed(extractComments(lines.slice(lines.length > 1 ? 1 : 0)));
}
exports.generateMarkdownFromCodeLines = generateMarkdownFromCodeLines;
function parseForComments(lines, foundCommentLine, foundNonCommentLine) {
    let insideMultilineComment;
    let insideMultilineQuote;
    let pos = 0;
    for (const l of lines) {
        const trim = l.trim();
        const isMultilineComment = trim.startsWith(SingleQuoteMultiline)
            ? SingleQuoteMultiline
            : trim.startsWith(DoubleQuoteMultiline)
                ? DoubleQuoteMultiline
                : undefined;
        const isMultilineQuote = trim.includes(SingleQuoteMultiline)
            ? SingleQuoteMultiline
            : trim.includes(DoubleQuoteMultiline)
                ? DoubleQuoteMultiline
                : undefined;
        if (insideMultilineQuote) {
            if (insideMultilineQuote === isMultilineQuote) {
                insideMultilineQuote = undefined;
            }
            foundNonCommentLine(l, pos);
        }
        else if (insideMultilineComment) {
            if (insideMultilineComment === isMultilineComment) {
                insideMultilineComment = undefined;
            }
            if (insideMultilineComment) {
                foundCommentLine(l, pos);
            }
        }
        else if (isMultilineQuote && !isMultilineComment) {
            const beginQuote = trim.indexOf(isMultilineQuote);
            const endQuote = trim.lastIndexOf(isMultilineQuote);
            insideMultilineQuote = endQuote !== beginQuote ? undefined : isMultilineQuote;
            foundNonCommentLine(l, pos);
        }
        else if (isMultilineComment) {
            const endIndex = trim.indexOf(isMultilineComment, 3);
            insideMultilineComment = endIndex >= 0 ? undefined : isMultilineComment;
            if (trim.length > 3) {
                foundCommentLine(trim.slice(3, endIndex >= 0 ? endIndex : undefined), pos);
            }
        }
        else {
            if (trim.startsWith('#')) {
                foundCommentLine(trim.slice(1), pos);
            }
            else {
                foundNonCommentLine(l, pos);
            }
        }
        pos += 1;
    }
}
exports.parseForComments = parseForComments;
function extractComments(lines) {
    const result = [];
    parseForComments(lines, (s) => result.push(s), (_s) => { });
    return result;
}


/***/ }),
/* 143 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.CursorPos = exports.CellState = void 0;
var CellState;
(function (CellState) {
    CellState[CellState["editing"] = -1] = "editing";
    CellState[CellState["init"] = 0] = "init";
    CellState[CellState["executing"] = 1] = "executing";
    CellState[CellState["finished"] = 2] = "finished";
    CellState[CellState["error"] = 3] = "error";
})(CellState = exports.CellState || (exports.CellState = {}));
var CursorPos;
(function (CursorPos) {
    CursorPos[CursorPos["Top"] = 0] = "Top";
    CursorPos[CursorPos["Bottom"] = 1] = "Bottom";
    CursorPos[CursorPos["Current"] = 2] = "Current";
})(CursorPos = exports.CursorPos || (exports.CursorPos = {}));


/***/ }),
/* 144 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SimpleMessageListener = void 0;
class SimpleMessageListener {
    constructor(callback, disposed) {
        this.disposedCallback = disposed;
        this.callback = callback;
    }
    async dispose() {
        this.disposedCallback();
    }
    onMessage(message, payload) {
        this.callback(message, payload);
    }
}
exports.SimpleMessageListener = SimpleMessageListener;


/***/ }),
/* 145 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WebviewViewHost = void 0;
const webviewHost_1 = __webpack_require__(146);
class WebviewViewHost extends webviewHost_1.WebviewHost {
    constructor(provider, messageListenerCtor, rootPath, scripts) {
        super(rootPath, scripts);
        this.provider = provider;
        this.messageListener = messageListenerCtor(this.onMessage.bind(this), this.dispose.bind(this));
    }
    get isDisposed() {
        return this.disposed;
    }
    async provideWebview(cwd, workspaceFolder, vscodeWebview) {
        if (!vscodeWebview) {
            throw new Error('WebviewViews must be passed an initial VS Code Webview');
        }
        return this.provider.create({
            additionalPaths: workspaceFolder ? [workspaceFolder.fsPath] : [],
            rootPath: this.rootPath,
            cwd,
            listener: this.messageListener,
            scripts: this.scripts,
            webviewHost: vscodeWebview
        });
    }
}
exports.WebviewViewHost = WebviewViewHost;


/***/ }),
/* 146 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WebviewHost = void 0;
const vscode = __webpack_require__(1);
const async_1 = __webpack_require__(147);
const messages_1 = __webpack_require__(32);
class WebviewHost {
    constructor(rootPath, scripts) {
        this.rootPath = rootPath;
        this.scripts = scripts;
        this.disposed = false;
        this.themeIsDarkPromise = (0, async_1.createDeferred)();
        this.webviewInit = (0, async_1.createDeferred)();
        this._disposables = [];
        this._onDidDisposeWebviewPanel = new vscode.EventEmitter();
    }
    get onDidDispose() {
        return this._onDidDisposeWebviewPanel.event;
    }
    dispose() {
        if (!this.disposed) {
            this.disposed = true;
            this.themeIsDarkPromise = undefined;
            this._disposables.forEach((item) => item.dispose());
        }
        this.webviewInit = undefined;
        this._onDidDisposeWebviewPanel.fire();
    }
    asWebviewUri(localResource) {
        var _a;
        if (!this.webview) {
            throw new Error('asWebViewUri called too early');
        }
        return (_a = this.webview) === null || _a === void 0 ? void 0 : _a.asWebviewUri(localResource);
    }
    postMessage(type, payload) {
        return this.postMessageInternal(type.toString(), payload);
    }
    onMessage(message, payload) {
        switch (message) {
            case messages_1.SharedMessages.Started:
                this.webViewRendered();
                break;
            default:
                break;
        }
    }
    async loadWebview(cwd, webView) {
        var _a;
        this.disposed = false;
        this.webviewInit = this.webviewInit || (0, async_1.createDeferred)();
        if (this.webview === undefined) {
            const workspaceFolder = (_a = vscode.workspace.getWorkspaceFolder(vscode.Uri.file(cwd))) === null || _a === void 0 ? void 0 : _a.uri;
            this.webview = await this.provideWebview(cwd, workspaceFolder, webView);
        }
    }
    async postMessageInternal(type, payload) {
        var _a;
        if (this.webviewInit) {
            await this.webviewInit.promise;
            (_a = this.webview) === null || _a === void 0 ? void 0 : _a.postMessage({ type: type.toString(), payload });
        }
    }
    webViewRendered() {
        if (this.webviewInit && !this.webviewInit.resolved) {
            this.webviewInit.resolve();
        }
    }
}
exports.WebviewHost = WebviewHost;


/***/ }),
/* 147 */
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.PromiseChain = exports.flattenIterator = exports.iterable = exports.mapToIterator = exports.chain = exports.NEVER = exports.iterEmpty = exports.createDeferredFromPromise = exports.createDeferredFrom = exports.createDeferred = exports.isPromise = exports.isThenable = exports.waitForPromise = exports.sleep = void 0;
async function sleep(timeout) {
    return new Promise((resolve) => {
        setTimeout(() => resolve(timeout), timeout);
    });
}
exports.sleep = sleep;
async function waitForPromise(promise, timeout) {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => resolve(null), timeout);
        promise
            .then((result) => {
            clearTimeout(timer);
            resolve(result);
        })
            .catch((e) => {
            clearTimeout(timer);
            reject(e);
        });
    });
}
exports.waitForPromise = waitForPromise;
function isThenable(v) {
    return typeof (v === null || v === void 0 ? void 0 : v.then) === 'function';
}
exports.isThenable = isThenable;
function isPromise(v) {
    return typeof (v === null || v === void 0 ? void 0 : v.then) === 'function' && typeof (v === null || v === void 0 ? void 0 : v.catch) === 'function';
}
exports.isPromise = isPromise;
class DeferredImpl {
    constructor(scope = null) {
        this.scope = scope;
        this._resolved = false;
        this._rejected = false;
        this._promise = new Promise((res, rej) => {
            this._resolve = res;
            this._reject = rej;
        });
    }
    get value() {
        return this._value;
    }
    resolve(value) {
        this._value = value;
        this._resolve.apply(this.scope ? this.scope : this, arguments);
        this._resolved = true;
    }
    reject(_reason) {
        this._reject.apply(this.scope ? this.scope : this, arguments);
        this._rejected = true;
    }
    get promise() {
        return this._promise;
    }
    get resolved() {
        return this._resolved;
    }
    get rejected() {
        return this._rejected;
    }
    get completed() {
        return this._rejected || this._resolved;
    }
}
function createDeferred(scope = null) {
    return new DeferredImpl(scope);
}
exports.createDeferred = createDeferred;
function createDeferredFrom(...promises) {
    const deferred = createDeferred();
    Promise.all(promises)
        .then(deferred.resolve.bind(deferred))
        .catch(deferred.reject.bind(deferred));
    return deferred;
}
exports.createDeferredFrom = createDeferredFrom;
function createDeferredFromPromise(promise) {
    const deferred = createDeferred();
    promise.then(deferred.resolve.bind(deferred)).catch(deferred.reject.bind(deferred));
    return deferred;
}
exports.createDeferredFromPromise = createDeferredFromPromise;
function iterEmpty() {
    return (async function* () { })();
}
exports.iterEmpty = iterEmpty;
async function getNext(it, indexMaybe) {
    const index = indexMaybe === undefined ? -1 : indexMaybe;
    try {
        const result = await it.next();
        return { index, result, err: null };
    }
    catch (err) {
        return { index, err: err, result: null };
    }
}
exports.NEVER = new Promise(() => { });
async function* chain(iterators, onError) {
    const promises = iterators.map(getNext);
    let numRunning = iterators.length;
    while (numRunning > 0) {
        const { index, result, err } = await Promise.race(promises);
        if (err !== null) {
            promises[index] = exports.NEVER;
            numRunning -= 1;
            if (onError !== undefined) {
                await onError(err, index);
            }
        }
        else if (result.done) {
            promises[index] = exports.NEVER;
            numRunning -= 1;
            if (result.value !== undefined) {
                yield result.value;
            }
        }
        else {
            promises[index] = getNext(iterators[index], index);
            yield result.value;
        }
    }
}
exports.chain = chain;
async function* mapToIterator(items, func, race = true) {
    if (race) {
        const iterators = items.map((item) => {
            async function* generator() {
                yield func(item);
            }
            return generator();
        });
        yield* iterable(chain(iterators));
    }
    else {
        yield* items.map(func);
    }
}
exports.mapToIterator = mapToIterator;
function iterable(iterator) {
    const it = iterator;
    if (it[Symbol.asyncIterator] === undefined) {
        it[Symbol.asyncIterator] = () => it;
    }
    return it;
}
exports.iterable = iterable;
async function flattenIterator(iterator) {
    const results = [];
    let result = await iterator.next();
    while (!result.done) {
        results.push(result.value);
        result = await iterator.next();
    }
    return results;
}
exports.flattenIterator = flattenIterator;
class PromiseChain {
    constructor() {
        this.currentPromise = Promise.resolve(undefined);
    }
    async chain(promise) {
        const deferred = createDeferred();
        const previousPromise = this.currentPromise;
        this.currentPromise = this.currentPromise.then(async () => {
            try {
                const result = await promise();
                deferred.resolve(result);
            }
            catch (ex) {
                deferred.reject(ex);
                throw ex;
            }
        });
        await previousPromise;
        return deferred.promise;
    }
    chainFinally(promise) {
        const deferred = createDeferred();
        this.currentPromise = this.currentPromise.finally(() => promise()
            .then((result) => deferred.resolve(result))
            .catch((ex) => deferred.reject(ex)));
        return deferred.promise;
    }
}
exports.PromiseChain = PromiseChain;


/***/ }),
/* 148 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.StatusProvider = void 0;
const vscode = __webpack_require__(1);
const async_1 = __webpack_require__(147);
class StatusItem {
    constructor(_title, disposeCallback, timeout) {
        this.disposed = false;
        this.dispose = () => {
            if (!this.disposed) {
                this.disposed = true;
                if (this.timeout) {
                    clearTimeout(this.timeout);
                    this.timeout = undefined;
                }
                this.disposeCallback();
                if (!this.deferred.completed) {
                    this.deferred.resolve();
                }
            }
        };
        this.promise = () => {
            return this.deferred.promise;
        };
        this.reject = () => {
            this.deferred.reject();
            this.dispose();
        };
        this.deferred = (0, async_1.createDeferred)();
        this.disposeCallback = disposeCallback;
        if (timeout) {
            this.timeout = setTimeout(this.dispose, timeout);
        }
    }
}
class StatusProvider {
    constructor() {
        this.statusCount = 0;
        this.incrementCount = (showInWebView, panel) => {
            if (this.statusCount === 0) {
                if (panel && showInWebView) {
                    panel.startProgress();
                }
            }
            this.statusCount += 1;
        };
        this.decrementCount = (panel) => {
            const updatedCount = this.statusCount - 1;
            if (updatedCount === 0) {
                if (panel) {
                    panel.stopProgress();
                }
            }
            this.statusCount = Math.max(updatedCount, 0);
        };
    }
    set(message, showInWebView, timeout, cancel, participant) {
        this.incrementCount(showInWebView, participant);
        const statusItem = new StatusItem(message, () => this.decrementCount(participant), timeout);
        const progressOptions = {
            location: cancel ? vscode.ProgressLocation.Notification : vscode.ProgressLocation.Window,
            title: message,
            cancellable: cancel !== undefined
        };
        vscode.window.withProgress(progressOptions, (_p, c) => {
            if (c && cancel) {
                c.onCancellationRequested(() => {
                    cancel();
                    statusItem.reject();
                });
            }
            return statusItem.promise();
        });
        return statusItem;
    }
    async waitWithStatus(promise, message, showInWebView, timeout, cancel, panel) {
        const status = this.set(message, showInWebView, timeout, cancel, panel);
        let result;
        try {
            result = await promise();
        }
        finally {
            status.dispose();
        }
        return result;
    }
}
exports.StatusProvider = StatusProvider;


/***/ }),
/* 149 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WebviewViewProvider = void 0;
const webviewView_1 = __webpack_require__(150);
class WebviewViewProvider {
    async create(options) {
        return new webviewView_1.WebviewView(options);
    }
}
exports.WebviewViewProvider = WebviewViewProvider;


/***/ }),
/* 150 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WebviewView = void 0;
const vscode_1 = __webpack_require__(1);
const webview_1 = __webpack_require__(151);
const extension_1 = __webpack_require__(25);
class WebviewView extends webview_1.Webview {
    constructor(panelOptions, additionalRootPaths = []) {
        super(panelOptions, additionalRootPaths);
        this.panelOptions = panelOptions;
        this._onDidChangeVisibility = new vscode_1.EventEmitter();
    }
    get visible() {
        if (!this.webviewHost) {
            return false;
        }
        else {
            return this.webviewHost.visible;
        }
    }
    get onDidChangeVisiblity() {
        return this._onDidChangeVisibility.event;
    }
    createWebview(_webviewOptions) {
        throw new Error('Webview Views must be passed in an initial view');
    }
    postLoad(webviewHost) {
        extension_1.disposables.push(webviewHost.onDidDispose(() => {
            this.webviewHost = undefined;
            this.panelOptions.listener.dispose();
        }));
        extension_1.disposables.push(webviewHost.webview.onDidReceiveMessage((message) => {
            this.panelOptions.listener.onMessage(message.type, message.payload);
        }));
        extension_1.disposables.push(webviewHost.onDidChangeVisibility(() => {
            this._onDidChangeVisibility.fire();
        }));
        this._onDidChangeVisibility.fire();
    }
}
exports.WebviewView = WebviewView;


/***/ }),
/* 151 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.Webview = void 0;
const vscode_1 = __webpack_require__(1);
const logging_1 = __webpack_require__(30);
const files_1 = __webpack_require__(152);
class Webview {
    constructor(options, additionalRootPaths = []) {
        this.options = options;
        this.loadFailedEmitter = new vscode_1.EventEmitter();
        const webViewOptions = {
            enableScripts: true,
            localResourceRoots: [vscode_1.Uri.file(this.options.rootPath), vscode_1.Uri.file(this.options.cwd), ...additionalRootPaths]
        };
        if (options.webviewHost) {
            this.webviewHost = options.webviewHost;
            this.webviewHost.webview.options = webViewOptions;
        }
        else {
            this.webviewHost = this.createWebview(webViewOptions);
        }
        this.loadPromise = this.load();
    }
    get loadFailed() {
        return this.loadFailedEmitter.event;
    }
    asWebviewUri(localResource) {
        var _a;
        if (!((_a = this.webviewHost) === null || _a === void 0 ? void 0 : _a.webview)) {
            throw new Error('WebView not initialized, too early to get a Uri');
        }
        return this.webviewHost.webview.asWebviewUri(localResource);
    }
    postMessage(message) {
        var _a, _b;
        if ((_a = this.webviewHost) === null || _a === void 0 ? void 0 : _a.webview) {
            void ((_b = this.webviewHost) === null || _b === void 0 ? void 0 : _b.webview.postMessage(message));
        }
    }
    async generateLocalReactHtml() {
        var _a, _b;
        if (!((_a = this.webviewHost) === null || _a === void 0 ? void 0 : _a.webview)) {
            throw new Error('WebView not initialized, too early to get a Uri');
        }
        const uriBase = (_b = this.webviewHost) === null || _b === void 0 ? void 0 : _b.webview.asWebviewUri(vscode_1.Uri.file(this.options.cwd)).toString();
        const uris = this.options.scripts.map((script) => this.webviewHost.webview.asWebviewUri(vscode_1.Uri.file(script)));
        const testFiles = await (0, files_1.getFiles)(vscode_1.Uri.file(this.options.rootPath));
        testFiles
            .filter((f) => f.fsPath.toLowerCase().endsWith('.js') || f.fsPath.toLowerCase().endsWith('.js.map'))
            .forEach((f) => { var _a; return (_a = this.webviewHost) === null || _a === void 0 ? void 0 : _a.webview.asWebviewUri(f); });
        const rootPath = this.webviewHost.webview.asWebviewUri(vscode_1.Uri.file(this.options.rootPath)).toString();
        const forceTestMiddleware = process.env.VSC_JUPYTER_WEBVIEW_TEST_MIDDLEWARE || 'false';
        return `<!doctype html>
        <html lang="en">
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no">
                <meta http-equiv="Content-Security-Policy" content="img-src 'self' data: https: http: blob: ${this.webviewHost.webview.cspSource}; default-src 'unsafe-inline' 'unsafe-eval' data: https: http: blob: ${this.webviewHost.webview.cspSource};">
                <title>VS Code Python React UI</title>
                <base href="${uriBase}${uriBase.endsWith('/') ? '' : '/'}"/>
                </head>
            <body>
                <noscript>You need to enable JavaScript to run this app.</noscript>
                <div id="root"></div>
                <script type="text/javascript">
                    // Public path that will be used by webpack.
                    window.__PVSC_Public_Path = "${rootPath}/";
                    function resolvePath(relativePath) {
                        if (relativePath && relativePath[0] == '.' && relativePath[1] != '.') {
                            return "${uriBase}" + relativePath.substring(1);
                        }

                        return "${uriBase}" + relativePath;
                    }
                    function forceTestMiddleware() {
                        return ${forceTestMiddleware};
                    }
                </script>
                ${uris.map((uri) => `<script type="text/javascript" src="${uri}"></script>`).join('\n')}
            </body>
        </html>`;
    }
    async load() {
        var _a;
        try {
            if ((_a = this.webviewHost) === null || _a === void 0 ? void 0 : _a.webview) {
                const localFilesExist = await Promise.all(this.options.scripts.map((s) => (0, files_1.localFileExists)(s)));
                if (localFilesExist.every((exists) => exists === true)) {
                    this.webviewHost.webview.html = await this.generateLocalReactHtml();
                    this.postLoad(this.webviewHost);
                }
                else {
                    const badPanelString = `<html><body><h1>${this.options.scripts.join(', ')} is not a valid file name</h1></body></html>`;
                    this.webviewHost.webview.html = badPanelString;
                }
            }
        }
        catch (error) {
            (0, logging_1.logError)(`Error Loading WebviewPanel: ${error}`);
            this.loadFailedEmitter.fire();
        }
    }
}
exports.Webview = Webview;


/***/ }),
/* 152 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.getFiles = exports.readLocalFile = exports.readFile = exports.localFileExists = exports.localDirectoryExists = exports.searchLocal = void 0;
const vscode = __webpack_require__(1);
const errors_1 = __webpack_require__(153);
const logging_1 = __webpack_require__(30);
const glob = __webpack_require__(154);
const util_1 = __webpack_require__(163);
const globPromise = (0, util_1.promisify)(glob);
const ENCODING = 'utf8';
async function localPathExists(filename, fileType) {
    let stat;
    try {
        const uri = vscode.Uri.file(filename);
        stat = await vscode.workspace.fs.stat(uri);
    }
    catch (err) {
        if ((0, errors_1.isFileNotFoundError)(err)) {
            return false;
        }
        (0, logging_1.logError)(`stat() failed for "${filename}"`, err);
        return false;
    }
    if (fileType === undefined) {
        return true;
    }
    if (fileType === vscode.FileType.Unknown) {
        return stat.type === vscode.FileType.Unknown;
    }
    return (stat.type & fileType) === fileType;
}
async function searchLocal(globPattern, cwd, dot) {
    let options;
    if (cwd) {
        options = { ...options, cwd };
    }
    if (dot) {
        options = { ...options, dot };
    }
    const found = await globPromise(globPattern, options);
    return Array.isArray(found) ? found : [];
}
exports.searchLocal = searchLocal;
async function localDirectoryExists(dirname) {
    return localPathExists(dirname, vscode.FileType.Directory);
}
exports.localDirectoryExists = localDirectoryExists;
async function localFileExists(filename) {
    return localPathExists(filename, vscode.FileType.File);
}
exports.localFileExists = localFileExists;
async function readFile(uri) {
    const result = await vscode.workspace.fs.readFile(uri);
    const data = Buffer.from(result);
    return data.toString(ENCODING);
}
exports.readFile = readFile;
async function readLocalFile(filename) {
    const uri = vscode.Uri.file(filename);
    return readFile(uri);
}
exports.readLocalFile = readLocalFile;
async function getFiles(dir) {
    const files = await vscode.workspace.fs.readDirectory(dir);
    return files.filter((f) => f[1] === vscode.FileType.File).map((f) => vscode.Uri.file(f[0]));
}
exports.getFiles = getFiles;


/***/ }),
/* 153 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.isDirNotEmptyError = exports.isNoPermissionsError = exports.isNotDirError = exports.isFileIsDirError = exports.isFileExistsError = exports.isFileNotFoundError = exports.createDirNotEmptyError = void 0;
const vscode = __webpack_require__(1);
var vscErrors;
(function (vscErrors) {
    const FILE_NOT_FOUND = vscode.FileSystemError.FileNotFound().name;
    const FILE_EXISTS = vscode.FileSystemError.FileExists().name;
    const IS_DIR = vscode.FileSystemError.FileIsADirectory().name;
    const NOT_DIR = vscode.FileSystemError.FileNotADirectory().name;
    const NO_PERM = vscode.FileSystemError.NoPermissions().name;
    const known = [
        FILE_NOT_FOUND,
        FILE_EXISTS,
        IS_DIR,
        NOT_DIR,
        NO_PERM
    ];
    function errorMatches(err, expectedName) {
        if (!known.includes(err.name)) {
            return undefined;
        }
        return err.name === expectedName;
    }
    function isFileNotFound(err) {
        return errorMatches(err, FILE_NOT_FOUND);
    }
    vscErrors.isFileNotFound = isFileNotFound;
    function isFileExists(err) {
        return errorMatches(err, FILE_EXISTS);
    }
    vscErrors.isFileExists = isFileExists;
    function isFileIsDir(err) {
        return errorMatches(err, IS_DIR);
    }
    vscErrors.isFileIsDir = isFileIsDir;
    function isNotDir(err) {
        return errorMatches(err, NOT_DIR);
    }
    vscErrors.isNotDir = isNotDir;
    function isNoPermissions(err) {
        return errorMatches(err, NO_PERM);
    }
    vscErrors.isNoPermissions = isNoPermissions;
})(vscErrors || (vscErrors = {}));
function createDirNotEmptyError(dirname) {
    const err = new Error(`directory "${dirname}" not empty`);
    err.name = 'SystemError';
    err.code = 'ENOTEMPTY';
    err.path = dirname;
    err.syscall = 'rmdir';
    return err;
}
exports.createDirNotEmptyError = createDirNotEmptyError;
function isSystemError(err, expectedCode) {
    const code = err.code;
    if (!code) {
        return undefined;
    }
    return code === expectedCode;
}
function isFileNotFoundError(err) {
    const matched = vscErrors.isFileNotFound(err);
    if (matched !== undefined) {
        return matched;
    }
    return isSystemError(err, 'ENOENT');
}
exports.isFileNotFoundError = isFileNotFoundError;
function isFileExistsError(err) {
    const matched = vscErrors.isFileExists(err);
    if (matched !== undefined) {
        return matched;
    }
    return isSystemError(err, 'EEXIST');
}
exports.isFileExistsError = isFileExistsError;
function isFileIsDirError(err) {
    const matched = vscErrors.isFileIsDir(err);
    if (matched !== undefined) {
        return matched;
    }
    return isSystemError(err, 'EISDIR');
}
exports.isFileIsDirError = isFileIsDirError;
function isNotDirError(err) {
    const matched = vscErrors.isNotDir(err);
    if (matched !== undefined) {
        return matched;
    }
    return isSystemError(err, 'ENOTDIR');
}
exports.isNotDirError = isNotDirError;
function isNoPermissionsError(err) {
    const matched = vscErrors.isNoPermissions(err);
    if (matched !== undefined) {
        return matched;
    }
    return isSystemError(err, 'EACCES');
}
exports.isNoPermissionsError = isNoPermissionsError;
function isDirNotEmptyError(err) {
    return isSystemError(err, 'ENOTEMPTY');
}
exports.isDirNotEmptyError = isDirNotEmptyError;


/***/ }),
/* 154 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

// Approach:
//
// 1. Get the minimatch set
// 2. For each pattern in the set, PROCESS(pattern, false)
// 3. Store matches per-set, then uniq them
//
// PROCESS(pattern, inGlobStar)
// Get the first [n] items from pattern that are all strings
// Join these together.  This is PREFIX.
//   If there is no more remaining, then stat(PREFIX) and
//   add to matches if it succeeds.  END.
//
// If inGlobStar and PREFIX is symlink and points to dir
//   set ENTRIES = []
// else readdir(PREFIX) as ENTRIES
//   If fail, END
//
// with ENTRIES
//   If pattern[n] is GLOBSTAR
//     // handle the case where the globstar match is empty
//     // by pruning it out, and testing the resulting pattern
//     PROCESS(pattern[0..n] + pattern[n+1 .. $], false)
//     // handle other cases.
//     for ENTRY in ENTRIES (not dotfiles)
//       // attach globstar + tail onto the entry
//       // Mark that this entry is a globstar match
//       PROCESS(pattern[0..n] + ENTRY + pattern[n .. $], true)
//
//   else // not globstar
//     for ENTRY in ENTRIES (not dotfiles, unless pattern[n] is dot)
//       Test ENTRY against pattern[n]
//       If fails, continue
//       If passes, PROCESS(pattern[0..n] + item + pattern[n+1 .. $])
//
// Caveat:
//   Cache all stats and readdirs results to minimize syscall.  Since all
//   we ever care about is existence and directory-ness, we can just keep
//   `true` for files, and [children,...] for directories, or `false` for
//   things that don't exist.

module.exports = glob

var rp = __webpack_require__(155)
var minimatch = __webpack_require__(158)
var Minimatch = minimatch.Minimatch
var inherits = __webpack_require__(162)
var EE = (__webpack_require__(165).EventEmitter)
var path = __webpack_require__(27)
var assert = __webpack_require__(166)
var isAbsolute = __webpack_require__(167)
var globSync = __webpack_require__(168)
var common = __webpack_require__(169)
var setopts = common.setopts
var ownProp = common.ownProp
var inflight = __webpack_require__(170)
var util = __webpack_require__(163)
var childrenIgnored = common.childrenIgnored
var isIgnored = common.isIgnored

var once = __webpack_require__(172)

function glob (pattern, options, cb) {
  if (typeof options === 'function') cb = options, options = {}
  if (!options) options = {}

  if (options.sync) {
    if (cb)
      throw new TypeError('callback provided to sync glob')
    return globSync(pattern, options)
  }

  return new Glob(pattern, options, cb)
}

glob.sync = globSync
var GlobSync = glob.GlobSync = globSync.GlobSync

// old api surface
glob.glob = glob

function extend (origin, add) {
  if (add === null || typeof add !== 'object') {
    return origin
  }

  var keys = Object.keys(add)
  var i = keys.length
  while (i--) {
    origin[keys[i]] = add[keys[i]]
  }
  return origin
}

glob.hasMagic = function (pattern, options_) {
  var options = extend({}, options_)
  options.noprocess = true

  var g = new Glob(pattern, options)
  var set = g.minimatch.set

  if (!pattern)
    return false

  if (set.length > 1)
    return true

  for (var j = 0; j < set[0].length; j++) {
    if (typeof set[0][j] !== 'string')
      return true
  }

  return false
}

glob.Glob = Glob
inherits(Glob, EE)
function Glob (pattern, options, cb) {
  if (typeof options === 'function') {
    cb = options
    options = null
  }

  if (options && options.sync) {
    if (cb)
      throw new TypeError('callback provided to sync glob')
    return new GlobSync(pattern, options)
  }

  if (!(this instanceof Glob))
    return new Glob(pattern, options, cb)

  setopts(this, pattern, options)
  this._didRealPath = false

  // process each pattern in the minimatch set
  var n = this.minimatch.set.length

  // The matches are stored as {<filename>: true,...} so that
  // duplicates are automagically pruned.
  // Later, we do an Object.keys() on these.
  // Keep them as a list so we can fill in when nonull is set.
  this.matches = new Array(n)

  if (typeof cb === 'function') {
    cb = once(cb)
    this.on('error', cb)
    this.on('end', function (matches) {
      cb(null, matches)
    })
  }

  var self = this
  this._processing = 0

  this._emitQueue = []
  this._processQueue = []
  this.paused = false

  if (this.noprocess)
    return this

  if (n === 0)
    return done()

  var sync = true
  for (var i = 0; i < n; i ++) {
    this._process(this.minimatch.set[i], i, false, done)
  }
  sync = false

  function done () {
    --self._processing
    if (self._processing <= 0) {
      if (sync) {
        process.nextTick(function () {
          self._finish()
        })
      } else {
        self._finish()
      }
    }
  }
}

Glob.prototype._finish = function () {
  assert(this instanceof Glob)
  if (this.aborted)
    return

  if (this.realpath && !this._didRealpath)
    return this._realpath()

  common.finish(this)
  this.emit('end', this.found)
}

Glob.prototype._realpath = function () {
  if (this._didRealpath)
    return

  this._didRealpath = true

  var n = this.matches.length
  if (n === 0)
    return this._finish()

  var self = this
  for (var i = 0; i < this.matches.length; i++)
    this._realpathSet(i, next)

  function next () {
    if (--n === 0)
      self._finish()
  }
}

Glob.prototype._realpathSet = function (index, cb) {
  var matchset = this.matches[index]
  if (!matchset)
    return cb()

  var found = Object.keys(matchset)
  var self = this
  var n = found.length

  if (n === 0)
    return cb()

  var set = this.matches[index] = Object.create(null)
  found.forEach(function (p, i) {
    // If there's a problem with the stat, then it means that
    // one or more of the links in the realpath couldn't be
    // resolved.  just return the abs value in that case.
    p = self._makeAbs(p)
    rp.realpath(p, self.realpathCache, function (er, real) {
      if (!er)
        set[real] = true
      else if (er.syscall === 'stat')
        set[p] = true
      else
        self.emit('error', er) // srsly wtf right here

      if (--n === 0) {
        self.matches[index] = set
        cb()
      }
    })
  })
}

Glob.prototype._mark = function (p) {
  return common.mark(this, p)
}

Glob.prototype._makeAbs = function (f) {
  return common.makeAbs(this, f)
}

Glob.prototype.abort = function () {
  this.aborted = true
  this.emit('abort')
}

Glob.prototype.pause = function () {
  if (!this.paused) {
    this.paused = true
    this.emit('pause')
  }
}

Glob.prototype.resume = function () {
  if (this.paused) {
    this.emit('resume')
    this.paused = false
    if (this._emitQueue.length) {
      var eq = this._emitQueue.slice(0)
      this._emitQueue.length = 0
      for (var i = 0; i < eq.length; i ++) {
        var e = eq[i]
        this._emitMatch(e[0], e[1])
      }
    }
    if (this._processQueue.length) {
      var pq = this._processQueue.slice(0)
      this._processQueue.length = 0
      for (var i = 0; i < pq.length; i ++) {
        var p = pq[i]
        this._processing--
        this._process(p[0], p[1], p[2], p[3])
      }
    }
  }
}

Glob.prototype._process = function (pattern, index, inGlobStar, cb) {
  assert(this instanceof Glob)
  assert(typeof cb === 'function')

  if (this.aborted)
    return

  this._processing++
  if (this.paused) {
    this._processQueue.push([pattern, index, inGlobStar, cb])
    return
  }

  //console.error('PROCESS %d', this._processing, pattern)

  // Get the first [n] parts of pattern that are all strings.
  var n = 0
  while (typeof pattern[n] === 'string') {
    n ++
  }
  // now n is the index of the first one that is *not* a string.

  // see if there's anything else
  var prefix
  switch (n) {
    // if not, then this is rather simple
    case pattern.length:
      this._processSimple(pattern.join('/'), index, cb)
      return

    case 0:
      // pattern *starts* with some non-trivial item.
      // going to readdir(cwd), but not include the prefix in matches.
      prefix = null
      break

    default:
      // pattern has some string bits in the front.
      // whatever it starts with, whether that's 'absolute' like /foo/bar,
      // or 'relative' like '../baz'
      prefix = pattern.slice(0, n).join('/')
      break
  }

  var remain = pattern.slice(n)

  // get the list of entries.
  var read
  if (prefix === null)
    read = '.'
  else if (isAbsolute(prefix) || isAbsolute(pattern.join('/'))) {
    if (!prefix || !isAbsolute(prefix))
      prefix = '/' + prefix
    read = prefix
  } else
    read = prefix

  var abs = this._makeAbs(read)

  //if ignored, skip _processing
  if (childrenIgnored(this, read))
    return cb()

  var isGlobStar = remain[0] === minimatch.GLOBSTAR
  if (isGlobStar)
    this._processGlobStar(prefix, read, abs, remain, index, inGlobStar, cb)
  else
    this._processReaddir(prefix, read, abs, remain, index, inGlobStar, cb)
}

Glob.prototype._processReaddir = function (prefix, read, abs, remain, index, inGlobStar, cb) {
  var self = this
  this._readdir(abs, inGlobStar, function (er, entries) {
    return self._processReaddir2(prefix, read, abs, remain, index, inGlobStar, entries, cb)
  })
}

Glob.prototype._processReaddir2 = function (prefix, read, abs, remain, index, inGlobStar, entries, cb) {

  // if the abs isn't a dir, then nothing can match!
  if (!entries)
    return cb()

  // It will only match dot entries if it starts with a dot, or if
  // dot is set.  Stuff like @(.foo|.bar) isn't allowed.
  var pn = remain[0]
  var negate = !!this.minimatch.negate
  var rawGlob = pn._glob
  var dotOk = this.dot || rawGlob.charAt(0) === '.'

  var matchedEntries = []
  for (var i = 0; i < entries.length; i++) {
    var e = entries[i]
    if (e.charAt(0) !== '.' || dotOk) {
      var m
      if (negate && !prefix) {
        m = !e.match(pn)
      } else {
        m = e.match(pn)
      }
      if (m)
        matchedEntries.push(e)
    }
  }

  //console.error('prd2', prefix, entries, remain[0]._glob, matchedEntries)

  var len = matchedEntries.length
  // If there are no matched entries, then nothing matches.
  if (len === 0)
    return cb()

  // if this is the last remaining pattern bit, then no need for
  // an additional stat *unless* the user has specified mark or
  // stat explicitly.  We know they exist, since readdir returned
  // them.

  if (remain.length === 1 && !this.mark && !this.stat) {
    if (!this.matches[index])
      this.matches[index] = Object.create(null)

    for (var i = 0; i < len; i ++) {
      var e = matchedEntries[i]
      if (prefix) {
        if (prefix !== '/')
          e = prefix + '/' + e
        else
          e = prefix + e
      }

      if (e.charAt(0) === '/' && !this.nomount) {
        e = path.join(this.root, e)
      }
      this._emitMatch(index, e)
    }
    // This was the last one, and no stats were needed
    return cb()
  }

  // now test all matched entries as stand-ins for that part
  // of the pattern.
  remain.shift()
  for (var i = 0; i < len; i ++) {
    var e = matchedEntries[i]
    var newPattern
    if (prefix) {
      if (prefix !== '/')
        e = prefix + '/' + e
      else
        e = prefix + e
    }
    this._process([e].concat(remain), index, inGlobStar, cb)
  }
  cb()
}

Glob.prototype._emitMatch = function (index, e) {
  if (this.aborted)
    return

  if (isIgnored(this, e))
    return

  if (this.paused) {
    this._emitQueue.push([index, e])
    return
  }

  var abs = isAbsolute(e) ? e : this._makeAbs(e)

  if (this.mark)
    e = this._mark(e)

  if (this.absolute)
    e = abs

  if (this.matches[index][e])
    return

  if (this.nodir) {
    var c = this.cache[abs]
    if (c === 'DIR' || Array.isArray(c))
      return
  }

  this.matches[index][e] = true

  var st = this.statCache[abs]
  if (st)
    this.emit('stat', e, st)

  this.emit('match', e)
}

Glob.prototype._readdirInGlobStar = function (abs, cb) {
  if (this.aborted)
    return

  // follow all symlinked directories forever
  // just proceed as if this is a non-globstar situation
  if (this.follow)
    return this._readdir(abs, false, cb)

  var lstatkey = 'lstat\0' + abs
  var self = this
  var lstatcb = inflight(lstatkey, lstatcb_)

  if (lstatcb)
    self.fs.lstat(abs, lstatcb)

  function lstatcb_ (er, lstat) {
    if (er && er.code === 'ENOENT')
      return cb()

    var isSym = lstat && lstat.isSymbolicLink()
    self.symlinks[abs] = isSym

    // If it's not a symlink or a dir, then it's definitely a regular file.
    // don't bother doing a readdir in that case.
    if (!isSym && lstat && !lstat.isDirectory()) {
      self.cache[abs] = 'FILE'
      cb()
    } else
      self._readdir(abs, false, cb)
  }
}

Glob.prototype._readdir = function (abs, inGlobStar, cb) {
  if (this.aborted)
    return

  cb = inflight('readdir\0'+abs+'\0'+inGlobStar, cb)
  if (!cb)
    return

  //console.error('RD %j %j', +inGlobStar, abs)
  if (inGlobStar && !ownProp(this.symlinks, abs))
    return this._readdirInGlobStar(abs, cb)

  if (ownProp(this.cache, abs)) {
    var c = this.cache[abs]
    if (!c || c === 'FILE')
      return cb()

    if (Array.isArray(c))
      return cb(null, c)
  }

  var self = this
  self.fs.readdir(abs, readdirCb(this, abs, cb))
}

function readdirCb (self, abs, cb) {
  return function (er, entries) {
    if (er)
      self._readdirError(abs, er, cb)
    else
      self._readdirEntries(abs, entries, cb)
  }
}

Glob.prototype._readdirEntries = function (abs, entries, cb) {
  if (this.aborted)
    return

  // if we haven't asked to stat everything, then just
  // assume that everything in there exists, so we can avoid
  // having to stat it a second time.
  if (!this.mark && !this.stat) {
    for (var i = 0; i < entries.length; i ++) {
      var e = entries[i]
      if (abs === '/')
        e = abs + e
      else
        e = abs + '/' + e
      this.cache[e] = true
    }
  }

  this.cache[abs] = entries
  return cb(null, entries)
}

Glob.prototype._readdirError = function (f, er, cb) {
  if (this.aborted)
    return

  // handle errors, and cache the information
  switch (er.code) {
    case 'ENOTSUP': // https://github.com/isaacs/node-glob/issues/205
    case 'ENOTDIR': // totally normal. means it *does* exist.
      var abs = this._makeAbs(f)
      this.cache[abs] = 'FILE'
      if (abs === this.cwdAbs) {
        var error = new Error(er.code + ' invalid cwd ' + this.cwd)
        error.path = this.cwd
        error.code = er.code
        this.emit('error', error)
        this.abort()
      }
      break

    case 'ENOENT': // not terribly unusual
    case 'ELOOP':
    case 'ENAMETOOLONG':
    case 'UNKNOWN':
      this.cache[this._makeAbs(f)] = false
      break

    default: // some unusual error.  Treat as failure.
      this.cache[this._makeAbs(f)] = false
      if (this.strict) {
        this.emit('error', er)
        // If the error is handled, then we abort
        // if not, we threw out of here
        this.abort()
      }
      if (!this.silent)
        console.error('glob error', er)
      break
  }

  return cb()
}

Glob.prototype._processGlobStar = function (prefix, read, abs, remain, index, inGlobStar, cb) {
  var self = this
  this._readdir(abs, inGlobStar, function (er, entries) {
    self._processGlobStar2(prefix, read, abs, remain, index, inGlobStar, entries, cb)
  })
}


Glob.prototype._processGlobStar2 = function (prefix, read, abs, remain, index, inGlobStar, entries, cb) {
  //console.error('pgs2', prefix, remain[0], entries)

  // no entries means not a dir, so it can never have matches
  // foo.txt/** doesn't match foo.txt
  if (!entries)
    return cb()

  // test without the globstar, and with every child both below
  // and replacing the globstar.
  var remainWithoutGlobStar = remain.slice(1)
  var gspref = prefix ? [ prefix ] : []
  var noGlobStar = gspref.concat(remainWithoutGlobStar)

  // the noGlobStar pattern exits the inGlobStar state
  this._process(noGlobStar, index, false, cb)

  var isSym = this.symlinks[abs]
  var len = entries.length

  // If it's a symlink, and we're in a globstar, then stop
  if (isSym && inGlobStar)
    return cb()

  for (var i = 0; i < len; i++) {
    var e = entries[i]
    if (e.charAt(0) === '.' && !this.dot)
      continue

    // these two cases enter the inGlobStar state
    var instead = gspref.concat(entries[i], remainWithoutGlobStar)
    this._process(instead, index, true, cb)

    var below = gspref.concat(entries[i], remain)
    this._process(below, index, true, cb)
  }

  cb()
}

Glob.prototype._processSimple = function (prefix, index, cb) {
  // XXX review this.  Shouldn't it be doing the mounting etc
  // before doing stat?  kinda weird?
  var self = this
  this._stat(prefix, function (er, exists) {
    self._processSimple2(prefix, index, er, exists, cb)
  })
}
Glob.prototype._processSimple2 = function (prefix, index, er, exists, cb) {

  //console.error('ps2', prefix, exists)

  if (!this.matches[index])
    this.matches[index] = Object.create(null)

  // If it doesn't exist, then just mark the lack of results
  if (!exists)
    return cb()

  if (prefix && isAbsolute(prefix) && !this.nomount) {
    var trail = /[\/\\]$/.test(prefix)
    if (prefix.charAt(0) === '/') {
      prefix = path.join(this.root, prefix)
    } else {
      prefix = path.resolve(this.root, prefix)
      if (trail)
        prefix += '/'
    }
  }

  if (process.platform === 'win32')
    prefix = prefix.replace(/\\/g, '/')

  // Mark this as a match
  this._emitMatch(index, prefix)
  cb()
}

// Returns either 'DIR', 'FILE', or false
Glob.prototype._stat = function (f, cb) {
  var abs = this._makeAbs(f)
  var needDir = f.slice(-1) === '/'

  if (f.length > this.maxLength)
    return cb()

  if (!this.stat && ownProp(this.cache, abs)) {
    var c = this.cache[abs]

    if (Array.isArray(c))
      c = 'DIR'

    // It exists, but maybe not how we need it
    if (!needDir || c === 'DIR')
      return cb(null, c)

    if (needDir && c === 'FILE')
      return cb()

    // otherwise we have to stat, because maybe c=true
    // if we know it exists, but not what it is.
  }

  var exists
  var stat = this.statCache[abs]
  if (stat !== undefined) {
    if (stat === false)
      return cb(null, stat)
    else {
      var type = stat.isDirectory() ? 'DIR' : 'FILE'
      if (needDir && type === 'FILE')
        return cb()
      else
        return cb(null, type, stat)
    }
  }

  var self = this
  var statcb = inflight('stat\0' + abs, lstatcb_)
  if (statcb)
    self.fs.lstat(abs, statcb)

  function lstatcb_ (er, lstat) {
    if (lstat && lstat.isSymbolicLink()) {
      // If it's a symlink, then treat it as the target, unless
      // the target does not exist, then treat it as a file.
      return self.fs.stat(abs, function (er, stat) {
        if (er)
          self._stat2(f, abs, null, lstat, cb)
        else
          self._stat2(f, abs, er, stat, cb)
      })
    } else {
      self._stat2(f, abs, er, lstat, cb)
    }
  }
}

Glob.prototype._stat2 = function (f, abs, er, stat, cb) {
  if (er && (er.code === 'ENOENT' || er.code === 'ENOTDIR')) {
    this.statCache[abs] = false
    return cb()
  }

  var needDir = f.slice(-1) === '/'
  this.statCache[abs] = stat

  if (abs.slice(-1) === '/' && stat && !stat.isDirectory())
    return cb(null, false, stat)

  var c = true
  if (stat)
    c = stat.isDirectory() ? 'DIR' : 'FILE'
  this.cache[abs] = this.cache[abs] || c

  if (needDir && c === 'FILE')
    return cb()

  return cb(null, c, stat)
}


/***/ }),
/* 155 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

module.exports = realpath
realpath.realpath = realpath
realpath.sync = realpathSync
realpath.realpathSync = realpathSync
realpath.monkeypatch = monkeypatch
realpath.unmonkeypatch = unmonkeypatch

var fs = __webpack_require__(156)
var origRealpath = fs.realpath
var origRealpathSync = fs.realpathSync

var version = process.version
var ok = /^v[0-5]\./.test(version)
var old = __webpack_require__(157)

function newError (er) {
  return er && er.syscall === 'realpath' && (
    er.code === 'ELOOP' ||
    er.code === 'ENOMEM' ||
    er.code === 'ENAMETOOLONG'
  )
}

function realpath (p, cache, cb) {
  if (ok) {
    return origRealpath(p, cache, cb)
  }

  if (typeof cache === 'function') {
    cb = cache
    cache = null
  }
  origRealpath(p, cache, function (er, result) {
    if (newError(er)) {
      old.realpath(p, cache, cb)
    } else {
      cb(er, result)
    }
  })
}

function realpathSync (p, cache) {
  if (ok) {
    return origRealpathSync(p, cache)
  }

  try {
    return origRealpathSync(p, cache)
  } catch (er) {
    if (newError(er)) {
      return old.realpathSync(p, cache)
    } else {
      throw er
    }
  }
}

function monkeypatch () {
  fs.realpath = realpath
  fs.realpathSync = realpathSync
}

function unmonkeypatch () {
  fs.realpath = origRealpath
  fs.realpathSync = origRealpathSync
}


/***/ }),
/* 156 */
/***/ ((module) => {

"use strict";
module.exports = require("fs");

/***/ }),
/* 157 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var pathModule = __webpack_require__(27);
var isWindows = process.platform === 'win32';
var fs = __webpack_require__(156);

// JavaScript implementation of realpath, ported from node pre-v6

var DEBUG = process.env.NODE_DEBUG && /fs/.test(process.env.NODE_DEBUG);

function rethrow() {
  // Only enable in debug mode. A backtrace uses ~1000 bytes of heap space and
  // is fairly slow to generate.
  var callback;
  if (DEBUG) {
    var backtrace = new Error;
    callback = debugCallback;
  } else
    callback = missingCallback;

  return callback;

  function debugCallback(err) {
    if (err) {
      backtrace.message = err.message;
      err = backtrace;
      missingCallback(err);
    }
  }

  function missingCallback(err) {
    if (err) {
      if (process.throwDeprecation)
        throw err;  // Forgot a callback but don't know where? Use NODE_DEBUG=fs
      else if (!process.noDeprecation) {
        var msg = 'fs: missing callback ' + (err.stack || err.message);
        if (process.traceDeprecation)
          console.trace(msg);
        else
          console.error(msg);
      }
    }
  }
}

function maybeCallback(cb) {
  return typeof cb === 'function' ? cb : rethrow();
}

var normalize = pathModule.normalize;

// Regexp that finds the next partion of a (partial) path
// result is [base_with_slash, base], e.g. ['somedir/', 'somedir']
if (isWindows) {
  var nextPartRe = /(.*?)(?:[\/\\]+|$)/g;
} else {
  var nextPartRe = /(.*?)(?:[\/]+|$)/g;
}

// Regex to find the device root, including trailing slash. E.g. 'c:\\'.
if (isWindows) {
  var splitRootRe = /^(?:[a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/][^\\\/]+)?[\\\/]*/;
} else {
  var splitRootRe = /^[\/]*/;
}

exports.realpathSync = function realpathSync(p, cache) {
  // make p is absolute
  p = pathModule.resolve(p);

  if (cache && Object.prototype.hasOwnProperty.call(cache, p)) {
    return cache[p];
  }

  var original = p,
      seenLinks = {},
      knownHard = {};

  // current character position in p
  var pos;
  // the partial path so far, including a trailing slash if any
  var current;
  // the partial path without a trailing slash (except when pointing at a root)
  var base;
  // the partial path scanned in the previous round, with slash
  var previous;

  start();

  function start() {
    // Skip over roots
    var m = splitRootRe.exec(p);
    pos = m[0].length;
    current = m[0];
    base = m[0];
    previous = '';

    // On windows, check that the root exists. On unix there is no need.
    if (isWindows && !knownHard[base]) {
      fs.lstatSync(base);
      knownHard[base] = true;
    }
  }

  // walk down the path, swapping out linked pathparts for their real
  // values
  // NB: p.length changes.
  while (pos < p.length) {
    // find the next part
    nextPartRe.lastIndex = pos;
    var result = nextPartRe.exec(p);
    previous = current;
    current += result[0];
    base = previous + result[1];
    pos = nextPartRe.lastIndex;

    // continue if not a symlink
    if (knownHard[base] || (cache && cache[base] === base)) {
      continue;
    }

    var resolvedLink;
    if (cache && Object.prototype.hasOwnProperty.call(cache, base)) {
      // some known symbolic link.  no need to stat again.
      resolvedLink = cache[base];
    } else {
      var stat = fs.lstatSync(base);
      if (!stat.isSymbolicLink()) {
        knownHard[base] = true;
        if (cache) cache[base] = base;
        continue;
      }

      // read the link if it wasn't read before
      // dev/ino always return 0 on windows, so skip the check.
      var linkTarget = null;
      if (!isWindows) {
        var id = stat.dev.toString(32) + ':' + stat.ino.toString(32);
        if (seenLinks.hasOwnProperty(id)) {
          linkTarget = seenLinks[id];
        }
      }
      if (linkTarget === null) {
        fs.statSync(base);
        linkTarget = fs.readlinkSync(base);
      }
      resolvedLink = pathModule.resolve(previous, linkTarget);
      // track this, if given a cache.
      if (cache) cache[base] = resolvedLink;
      if (!isWindows) seenLinks[id] = linkTarget;
    }

    // resolve the link, then start over
    p = pathModule.resolve(resolvedLink, p.slice(pos));
    start();
  }

  if (cache) cache[original] = p;

  return p;
};


exports.realpath = function realpath(p, cache, cb) {
  if (typeof cb !== 'function') {
    cb = maybeCallback(cache);
    cache = null;
  }

  // make p is absolute
  p = pathModule.resolve(p);

  if (cache && Object.prototype.hasOwnProperty.call(cache, p)) {
    return process.nextTick(cb.bind(null, null, cache[p]));
  }

  var original = p,
      seenLinks = {},
      knownHard = {};

  // current character position in p
  var pos;
  // the partial path so far, including a trailing slash if any
  var current;
  // the partial path without a trailing slash (except when pointing at a root)
  var base;
  // the partial path scanned in the previous round, with slash
  var previous;

  start();

  function start() {
    // Skip over roots
    var m = splitRootRe.exec(p);
    pos = m[0].length;
    current = m[0];
    base = m[0];
    previous = '';

    // On windows, check that the root exists. On unix there is no need.
    if (isWindows && !knownHard[base]) {
      fs.lstat(base, function(err) {
        if (err) return cb(err);
        knownHard[base] = true;
        LOOP();
      });
    } else {
      process.nextTick(LOOP);
    }
  }

  // walk down the path, swapping out linked pathparts for their real
  // values
  function LOOP() {
    // stop if scanned past end of path
    if (pos >= p.length) {
      if (cache) cache[original] = p;
      return cb(null, p);
    }

    // find the next part
    nextPartRe.lastIndex = pos;
    var result = nextPartRe.exec(p);
    previous = current;
    current += result[0];
    base = previous + result[1];
    pos = nextPartRe.lastIndex;

    // continue if not a symlink
    if (knownHard[base] || (cache && cache[base] === base)) {
      return process.nextTick(LOOP);
    }

    if (cache && Object.prototype.hasOwnProperty.call(cache, base)) {
      // known symbolic link.  no need to stat again.
      return gotResolvedLink(cache[base]);
    }

    return fs.lstat(base, gotStat);
  }

  function gotStat(err, stat) {
    if (err) return cb(err);

    // if not a symlink, skip to the next path part
    if (!stat.isSymbolicLink()) {
      knownHard[base] = true;
      if (cache) cache[base] = base;
      return process.nextTick(LOOP);
    }

    // stat & read the link if not read before
    // call gotTarget as soon as the link target is known
    // dev/ino always return 0 on windows, so skip the check.
    if (!isWindows) {
      var id = stat.dev.toString(32) + ':' + stat.ino.toString(32);
      if (seenLinks.hasOwnProperty(id)) {
        return gotTarget(null, seenLinks[id], base);
      }
    }
    fs.stat(base, function(err) {
      if (err) return cb(err);

      fs.readlink(base, function(err, target) {
        if (!isWindows) seenLinks[id] = target;
        gotTarget(err, target);
      });
    });
  }

  function gotTarget(err, target, base) {
    if (err) return cb(err);

    var resolvedLink = pathModule.resolve(previous, target);
    if (cache) cache[base] = resolvedLink;
    gotResolvedLink(resolvedLink);
  }

  function gotResolvedLink(resolvedLink) {
    // resolve the link, then start over
    p = pathModule.resolve(resolvedLink, p.slice(pos));
    start();
  }
};


/***/ }),
/* 158 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

module.exports = minimatch
minimatch.Minimatch = Minimatch

var path = (function () { try { return __webpack_require__(27) } catch (e) {}}()) || {
  sep: '/'
}
minimatch.sep = path.sep

var GLOBSTAR = minimatch.GLOBSTAR = Minimatch.GLOBSTAR = {}
var expand = __webpack_require__(159)

var plTypes = {
  '!': { open: '(?:(?!(?:', close: '))[^/]*?)'},
  '?': { open: '(?:', close: ')?' },
  '+': { open: '(?:', close: ')+' },
  '*': { open: '(?:', close: ')*' },
  '@': { open: '(?:', close: ')' }
}

// any single thing other than /
// don't need to escape / when using new RegExp()
var qmark = '[^/]'

// * => any number of characters
var star = qmark + '*?'

// ** when dots are allowed.  Anything goes, except .. and .
// not (^ or / followed by one or two dots followed by $ or /),
// followed by anything, any number of times.
var twoStarDot = '(?:(?!(?:\\\/|^)(?:\\.{1,2})($|\\\/)).)*?'

// not a ^ or / followed by a dot,
// followed by anything, any number of times.
var twoStarNoDot = '(?:(?!(?:\\\/|^)\\.).)*?'

// characters that need to be escaped in RegExp.
var reSpecials = charSet('().*{}+?[]^$\\!')

// "abc" -> { a:true, b:true, c:true }
function charSet (s) {
  return s.split('').reduce(function (set, c) {
    set[c] = true
    return set
  }, {})
}

// normalizes slashes.
var slashSplit = /\/+/

minimatch.filter = filter
function filter (pattern, options) {
  options = options || {}
  return function (p, i, list) {
    return minimatch(p, pattern, options)
  }
}

function ext (a, b) {
  b = b || {}
  var t = {}
  Object.keys(a).forEach(function (k) {
    t[k] = a[k]
  })
  Object.keys(b).forEach(function (k) {
    t[k] = b[k]
  })
  return t
}

minimatch.defaults = function (def) {
  if (!def || typeof def !== 'object' || !Object.keys(def).length) {
    return minimatch
  }

  var orig = minimatch

  var m = function minimatch (p, pattern, options) {
    return orig(p, pattern, ext(def, options))
  }

  m.Minimatch = function Minimatch (pattern, options) {
    return new orig.Minimatch(pattern, ext(def, options))
  }
  m.Minimatch.defaults = function defaults (options) {
    return orig.defaults(ext(def, options)).Minimatch
  }

  m.filter = function filter (pattern, options) {
    return orig.filter(pattern, ext(def, options))
  }

  m.defaults = function defaults (options) {
    return orig.defaults(ext(def, options))
  }

  m.makeRe = function makeRe (pattern, options) {
    return orig.makeRe(pattern, ext(def, options))
  }

  m.braceExpand = function braceExpand (pattern, options) {
    return orig.braceExpand(pattern, ext(def, options))
  }

  m.match = function (list, pattern, options) {
    return orig.match(list, pattern, ext(def, options))
  }

  return m
}

Minimatch.defaults = function (def) {
  return minimatch.defaults(def).Minimatch
}

function minimatch (p, pattern, options) {
  assertValidPattern(pattern)

  if (!options) options = {}

  // shortcut: comments match nothing.
  if (!options.nocomment && pattern.charAt(0) === '#') {
    return false
  }

  return new Minimatch(pattern, options).match(p)
}

function Minimatch (pattern, options) {
  if (!(this instanceof Minimatch)) {
    return new Minimatch(pattern, options)
  }

  assertValidPattern(pattern)

  if (!options) options = {}

  pattern = pattern.trim()

  // windows support: need to use /, not \
  if (!options.allowWindowsEscape && path.sep !== '/') {
    pattern = pattern.split(path.sep).join('/')
  }

  this.options = options
  this.set = []
  this.pattern = pattern
  this.regexp = null
  this.negate = false
  this.comment = false
  this.empty = false
  this.partial = !!options.partial

  // make the set of regexps etc.
  this.make()
}

Minimatch.prototype.debug = function () {}

Minimatch.prototype.make = make
function make () {
  var pattern = this.pattern
  var options = this.options

  // empty patterns and comments match nothing.
  if (!options.nocomment && pattern.charAt(0) === '#') {
    this.comment = true
    return
  }
  if (!pattern) {
    this.empty = true
    return
  }

  // step 1: figure out negation, etc.
  this.parseNegate()

  // step 2: expand braces
  var set = this.globSet = this.braceExpand()

  if (options.debug) this.debug = function debug() { console.error.apply(console, arguments) }

  this.debug(this.pattern, set)

  // step 3: now we have a set, so turn each one into a series of path-portion
  // matching patterns.
  // These will be regexps, except in the case of "**", which is
  // set to the GLOBSTAR object for globstar behavior,
  // and will not contain any / characters
  set = this.globParts = set.map(function (s) {
    return s.split(slashSplit)
  })

  this.debug(this.pattern, set)

  // glob --> regexps
  set = set.map(function (s, si, set) {
    return s.map(this.parse, this)
  }, this)

  this.debug(this.pattern, set)

  // filter out everything that didn't compile properly.
  set = set.filter(function (s) {
    return s.indexOf(false) === -1
  })

  this.debug(this.pattern, set)

  this.set = set
}

Minimatch.prototype.parseNegate = parseNegate
function parseNegate () {
  var pattern = this.pattern
  var negate = false
  var options = this.options
  var negateOffset = 0

  if (options.nonegate) return

  for (var i = 0, l = pattern.length
    ; i < l && pattern.charAt(i) === '!'
    ; i++) {
    negate = !negate
    negateOffset++
  }

  if (negateOffset) this.pattern = pattern.substr(negateOffset)
  this.negate = negate
}

// Brace expansion:
// a{b,c}d -> abd acd
// a{b,}c -> abc ac
// a{0..3}d -> a0d a1d a2d a3d
// a{b,c{d,e}f}g -> abg acdfg acefg
// a{b,c}d{e,f}g -> abdeg acdeg abdeg abdfg
//
// Invalid sets are not expanded.
// a{2..}b -> a{2..}b
// a{b}c -> a{b}c
minimatch.braceExpand = function (pattern, options) {
  return braceExpand(pattern, options)
}

Minimatch.prototype.braceExpand = braceExpand

function braceExpand (pattern, options) {
  if (!options) {
    if (this instanceof Minimatch) {
      options = this.options
    } else {
      options = {}
    }
  }

  pattern = typeof pattern === 'undefined'
    ? this.pattern : pattern

  assertValidPattern(pattern)

  // Thanks to Yeting Li <https://github.com/yetingli> for
  // improving this regexp to avoid a ReDOS vulnerability.
  if (options.nobrace || !/\{(?:(?!\{).)*\}/.test(pattern)) {
    // shortcut. no need to expand.
    return [pattern]
  }

  return expand(pattern)
}

var MAX_PATTERN_LENGTH = 1024 * 64
var assertValidPattern = function (pattern) {
  if (typeof pattern !== 'string') {
    throw new TypeError('invalid pattern')
  }

  if (pattern.length > MAX_PATTERN_LENGTH) {
    throw new TypeError('pattern is too long')
  }
}

// parse a component of the expanded set.
// At this point, no pattern may contain "/" in it
// so we're going to return a 2d array, where each entry is the full
// pattern, split on '/', and then turned into a regular expression.
// A regexp is made at the end which joins each array with an
// escaped /, and another full one which joins each regexp with |.
//
// Following the lead of Bash 4.1, note that "**" only has special meaning
// when it is the *only* thing in a path portion.  Otherwise, any series
// of * is equivalent to a single *.  Globstar behavior is enabled by
// default, and can be disabled by setting options.noglobstar.
Minimatch.prototype.parse = parse
var SUBPARSE = {}
function parse (pattern, isSub) {
  assertValidPattern(pattern)

  var options = this.options

  // shortcuts
  if (pattern === '**') {
    if (!options.noglobstar)
      return GLOBSTAR
    else
      pattern = '*'
  }
  if (pattern === '') return ''

  var re = ''
  var hasMagic = !!options.nocase
  var escaping = false
  // ? => one single character
  var patternListStack = []
  var negativeLists = []
  var stateChar
  var inClass = false
  var reClassStart = -1
  var classStart = -1
  // . and .. never match anything that doesn't start with .,
  // even when options.dot is set.
  var patternStart = pattern.charAt(0) === '.' ? '' // anything
  // not (start or / followed by . or .. followed by / or end)
  : options.dot ? '(?!(?:^|\\\/)\\.{1,2}(?:$|\\\/))'
  : '(?!\\.)'
  var self = this

  function clearStateChar () {
    if (stateChar) {
      // we had some state-tracking character
      // that wasn't consumed by this pass.
      switch (stateChar) {
        case '*':
          re += star
          hasMagic = true
        break
        case '?':
          re += qmark
          hasMagic = true
        break
        default:
          re += '\\' + stateChar
        break
      }
      self.debug('clearStateChar %j %j', stateChar, re)
      stateChar = false
    }
  }

  for (var i = 0, len = pattern.length, c
    ; (i < len) && (c = pattern.charAt(i))
    ; i++) {
    this.debug('%s\t%s %s %j', pattern, i, re, c)

    // skip over any that are escaped.
    if (escaping && reSpecials[c]) {
      re += '\\' + c
      escaping = false
      continue
    }

    switch (c) {
      /* istanbul ignore next */
      case '/': {
        // completely not allowed, even escaped.
        // Should already be path-split by now.
        return false
      }

      case '\\':
        clearStateChar()
        escaping = true
      continue

      // the various stateChar values
      // for the "extglob" stuff.
      case '?':
      case '*':
      case '+':
      case '@':
      case '!':
        this.debug('%s\t%s %s %j <-- stateChar', pattern, i, re, c)

        // all of those are literals inside a class, except that
        // the glob [!a] means [^a] in regexp
        if (inClass) {
          this.debug('  in class')
          if (c === '!' && i === classStart + 1) c = '^'
          re += c
          continue
        }

        // if we already have a stateChar, then it means
        // that there was something like ** or +? in there.
        // Handle the stateChar, then proceed with this one.
        self.debug('call clearStateChar %j', stateChar)
        clearStateChar()
        stateChar = c
        // if extglob is disabled, then +(asdf|foo) isn't a thing.
        // just clear the statechar *now*, rather than even diving into
        // the patternList stuff.
        if (options.noext) clearStateChar()
      continue

      case '(':
        if (inClass) {
          re += '('
          continue
        }

        if (!stateChar) {
          re += '\\('
          continue
        }

        patternListStack.push({
          type: stateChar,
          start: i - 1,
          reStart: re.length,
          open: plTypes[stateChar].open,
          close: plTypes[stateChar].close
        })
        // negation is (?:(?!js)[^/]*)
        re += stateChar === '!' ? '(?:(?!(?:' : '(?:'
        this.debug('plType %j %j', stateChar, re)
        stateChar = false
      continue

      case ')':
        if (inClass || !patternListStack.length) {
          re += '\\)'
          continue
        }

        clearStateChar()
        hasMagic = true
        var pl = patternListStack.pop()
        // negation is (?:(?!js)[^/]*)
        // The others are (?:<pattern>)<type>
        re += pl.close
        if (pl.type === '!') {
          negativeLists.push(pl)
        }
        pl.reEnd = re.length
      continue

      case '|':
        if (inClass || !patternListStack.length || escaping) {
          re += '\\|'
          escaping = false
          continue
        }

        clearStateChar()
        re += '|'
      continue

      // these are mostly the same in regexp and glob
      case '[':
        // swallow any state-tracking char before the [
        clearStateChar()

        if (inClass) {
          re += '\\' + c
          continue
        }

        inClass = true
        classStart = i
        reClassStart = re.length
        re += c
      continue

      case ']':
        //  a right bracket shall lose its special
        //  meaning and represent itself in
        //  a bracket expression if it occurs
        //  first in the list.  -- POSIX.2 2.8.3.2
        if (i === classStart + 1 || !inClass) {
          re += '\\' + c
          escaping = false
          continue
        }

        // handle the case where we left a class open.
        // "[z-a]" is valid, equivalent to "\[z-a\]"
        // split where the last [ was, make sure we don't have
        // an invalid re. if so, re-walk the contents of the
        // would-be class to re-translate any characters that
        // were passed through as-is
        // TODO: It would probably be faster to determine this
        // without a try/catch and a new RegExp, but it's tricky
        // to do safely.  For now, this is safe and works.
        var cs = pattern.substring(classStart + 1, i)
        try {
          RegExp('[' + cs + ']')
        } catch (er) {
          // not a valid class!
          var sp = this.parse(cs, SUBPARSE)
          re = re.substr(0, reClassStart) + '\\[' + sp[0] + '\\]'
          hasMagic = hasMagic || sp[1]
          inClass = false
          continue
        }

        // finish up the class.
        hasMagic = true
        inClass = false
        re += c
      continue

      default:
        // swallow any state char that wasn't consumed
        clearStateChar()

        if (escaping) {
          // no need
          escaping = false
        } else if (reSpecials[c]
          && !(c === '^' && inClass)) {
          re += '\\'
        }

        re += c

    } // switch
  } // for

  // handle the case where we left a class open.
  // "[abc" is valid, equivalent to "\[abc"
  if (inClass) {
    // split where the last [ was, and escape it
    // this is a huge pita.  We now have to re-walk
    // the contents of the would-be class to re-translate
    // any characters that were passed through as-is
    cs = pattern.substr(classStart + 1)
    sp = this.parse(cs, SUBPARSE)
    re = re.substr(0, reClassStart) + '\\[' + sp[0]
    hasMagic = hasMagic || sp[1]
  }

  // handle the case where we had a +( thing at the *end*
  // of the pattern.
  // each pattern list stack adds 3 chars, and we need to go through
  // and escape any | chars that were passed through as-is for the regexp.
  // Go through and escape them, taking care not to double-escape any
  // | chars that were already escaped.
  for (pl = patternListStack.pop(); pl; pl = patternListStack.pop()) {
    var tail = re.slice(pl.reStart + pl.open.length)
    this.debug('setting tail', re, pl)
    // maybe some even number of \, then maybe 1 \, followed by a |
    tail = tail.replace(/((?:\\{2}){0,64})(\\?)\|/g, function (_, $1, $2) {
      if (!$2) {
        // the | isn't already escaped, so escape it.
        $2 = '\\'
      }

      // need to escape all those slashes *again*, without escaping the
      // one that we need for escaping the | character.  As it works out,
      // escaping an even number of slashes can be done by simply repeating
      // it exactly after itself.  That's why this trick works.
      //
      // I am sorry that you have to see this.
      return $1 + $1 + $2 + '|'
    })

    this.debug('tail=%j\n   %s', tail, tail, pl, re)
    var t = pl.type === '*' ? star
      : pl.type === '?' ? qmark
      : '\\' + pl.type

    hasMagic = true
    re = re.slice(0, pl.reStart) + t + '\\(' + tail
  }

  // handle trailing things that only matter at the very end.
  clearStateChar()
  if (escaping) {
    // trailing \\
    re += '\\\\'
  }

  // only need to apply the nodot start if the re starts with
  // something that could conceivably capture a dot
  var addPatternStart = false
  switch (re.charAt(0)) {
    case '[': case '.': case '(': addPatternStart = true
  }

  // Hack to work around lack of negative lookbehind in JS
  // A pattern like: *.!(x).!(y|z) needs to ensure that a name
  // like 'a.xyz.yz' doesn't match.  So, the first negative
  // lookahead, has to look ALL the way ahead, to the end of
  // the pattern.
  for (var n = negativeLists.length - 1; n > -1; n--) {
    var nl = negativeLists[n]

    var nlBefore = re.slice(0, nl.reStart)
    var nlFirst = re.slice(nl.reStart, nl.reEnd - 8)
    var nlLast = re.slice(nl.reEnd - 8, nl.reEnd)
    var nlAfter = re.slice(nl.reEnd)

    nlLast += nlAfter

    // Handle nested stuff like *(*.js|!(*.json)), where open parens
    // mean that we should *not* include the ) in the bit that is considered
    // "after" the negated section.
    var openParensBefore = nlBefore.split('(').length - 1
    var cleanAfter = nlAfter
    for (i = 0; i < openParensBefore; i++) {
      cleanAfter = cleanAfter.replace(/\)[+*?]?/, '')
    }
    nlAfter = cleanAfter

    var dollar = ''
    if (nlAfter === '' && isSub !== SUBPARSE) {
      dollar = '$'
    }
    var newRe = nlBefore + nlFirst + nlAfter + dollar + nlLast
    re = newRe
  }

  // if the re is not "" at this point, then we need to make sure
  // it doesn't match against an empty path part.
  // Otherwise a/* will match a/, which it should not.
  if (re !== '' && hasMagic) {
    re = '(?=.)' + re
  }

  if (addPatternStart) {
    re = patternStart + re
  }

  // parsing just a piece of a larger pattern.
  if (isSub === SUBPARSE) {
    return [re, hasMagic]
  }

  // skip the regexp for non-magical patterns
  // unescape anything in it, though, so that it'll be
  // an exact match against a file etc.
  if (!hasMagic) {
    return globUnescape(pattern)
  }

  var flags = options.nocase ? 'i' : ''
  try {
    var regExp = new RegExp('^' + re + '$', flags)
  } catch (er) /* istanbul ignore next - should be impossible */ {
    // If it was an invalid regular expression, then it can't match
    // anything.  This trick looks for a character after the end of
    // the string, which is of course impossible, except in multi-line
    // mode, but it's not a /m regex.
    return new RegExp('$.')
  }

  regExp._glob = pattern
  regExp._src = re

  return regExp
}

minimatch.makeRe = function (pattern, options) {
  return new Minimatch(pattern, options || {}).makeRe()
}

Minimatch.prototype.makeRe = makeRe
function makeRe () {
  if (this.regexp || this.regexp === false) return this.regexp

  // at this point, this.set is a 2d array of partial
  // pattern strings, or "**".
  //
  // It's better to use .match().  This function shouldn't
  // be used, really, but it's pretty convenient sometimes,
  // when you just want to work with a regex.
  var set = this.set

  if (!set.length) {
    this.regexp = false
    return this.regexp
  }
  var options = this.options

  var twoStar = options.noglobstar ? star
    : options.dot ? twoStarDot
    : twoStarNoDot
  var flags = options.nocase ? 'i' : ''

  var re = set.map(function (pattern) {
    return pattern.map(function (p) {
      return (p === GLOBSTAR) ? twoStar
      : (typeof p === 'string') ? regExpEscape(p)
      : p._src
    }).join('\\\/')
  }).join('|')

  // must match entire pattern
  // ending in a * or ** will make it less strict.
  re = '^(?:' + re + ')$'

  // can match anything, as long as it's not this.
  if (this.negate) re = '^(?!' + re + ').*$'

  try {
    this.regexp = new RegExp(re, flags)
  } catch (ex) /* istanbul ignore next - should be impossible */ {
    this.regexp = false
  }
  return this.regexp
}

minimatch.match = function (list, pattern, options) {
  options = options || {}
  var mm = new Minimatch(pattern, options)
  list = list.filter(function (f) {
    return mm.match(f)
  })
  if (mm.options.nonull && !list.length) {
    list.push(pattern)
  }
  return list
}

Minimatch.prototype.match = function match (f, partial) {
  if (typeof partial === 'undefined') partial = this.partial
  this.debug('match', f, this.pattern)
  // short-circuit in the case of busted things.
  // comments, etc.
  if (this.comment) return false
  if (this.empty) return f === ''

  if (f === '/' && partial) return true

  var options = this.options

  // windows: need to use /, not \
  if (path.sep !== '/') {
    f = f.split(path.sep).join('/')
  }

  // treat the test path as a set of pathparts.
  f = f.split(slashSplit)
  this.debug(this.pattern, 'split', f)

  // just ONE of the pattern sets in this.set needs to match
  // in order for it to be valid.  If negating, then just one
  // match means that we have failed.
  // Either way, return on the first hit.

  var set = this.set
  this.debug(this.pattern, 'set', set)

  // Find the basename of the path by looking for the last non-empty segment
  var filename
  var i
  for (i = f.length - 1; i >= 0; i--) {
    filename = f[i]
    if (filename) break
  }

  for (i = 0; i < set.length; i++) {
    var pattern = set[i]
    var file = f
    if (options.matchBase && pattern.length === 1) {
      file = [filename]
    }
    var hit = this.matchOne(file, pattern, partial)
    if (hit) {
      if (options.flipNegate) return true
      return !this.negate
    }
  }

  // didn't get any hits.  this is success if it's a negative
  // pattern, failure otherwise.
  if (options.flipNegate) return false
  return this.negate
}

// set partial to true to test if, for example,
// "/a/b" matches the start of "/*/b/*/d"
// Partial means, if you run out of file before you run
// out of pattern, then that's fine, as long as all
// the parts match.
Minimatch.prototype.matchOne = function (file, pattern, partial) {
  var options = this.options

  this.debug('matchOne',
    { 'this': this, file: file, pattern: pattern })

  this.debug('matchOne', file.length, pattern.length)

  for (var fi = 0,
      pi = 0,
      fl = file.length,
      pl = pattern.length
      ; (fi < fl) && (pi < pl)
      ; fi++, pi++) {
    this.debug('matchOne loop')
    var p = pattern[pi]
    var f = file[fi]

    this.debug(pattern, p, f)

    // should be impossible.
    // some invalid regexp stuff in the set.
    /* istanbul ignore if */
    if (p === false) return false

    if (p === GLOBSTAR) {
      this.debug('GLOBSTAR', [pattern, p, f])

      // "**"
      // a/**/b/**/c would match the following:
      // a/b/x/y/z/c
      // a/x/y/z/b/c
      // a/b/x/b/x/c
      // a/b/c
      // To do this, take the rest of the pattern after
      // the **, and see if it would match the file remainder.
      // If so, return success.
      // If not, the ** "swallows" a segment, and try again.
      // This is recursively awful.
      //
      // a/**/b/**/c matching a/b/x/y/z/c
      // - a matches a
      // - doublestar
      //   - matchOne(b/x/y/z/c, b/**/c)
      //     - b matches b
      //     - doublestar
      //       - matchOne(x/y/z/c, c) -> no
      //       - matchOne(y/z/c, c) -> no
      //       - matchOne(z/c, c) -> no
      //       - matchOne(c, c) yes, hit
      var fr = fi
      var pr = pi + 1
      if (pr === pl) {
        this.debug('** at the end')
        // a ** at the end will just swallow the rest.
        // We have found a match.
        // however, it will not swallow /.x, unless
        // options.dot is set.
        // . and .. are *never* matched by **, for explosively
        // exponential reasons.
        for (; fi < fl; fi++) {
          if (file[fi] === '.' || file[fi] === '..' ||
            (!options.dot && file[fi].charAt(0) === '.')) return false
        }
        return true
      }

      // ok, let's see if we can swallow whatever we can.
      while (fr < fl) {
        var swallowee = file[fr]

        this.debug('\nglobstar while', file, fr, pattern, pr, swallowee)

        // XXX remove this slice.  Just pass the start index.
        if (this.matchOne(file.slice(fr), pattern.slice(pr), partial)) {
          this.debug('globstar found match!', fr, fl, swallowee)
          // found a match.
          return true
        } else {
          // can't swallow "." or ".." ever.
          // can only swallow ".foo" when explicitly asked.
          if (swallowee === '.' || swallowee === '..' ||
            (!options.dot && swallowee.charAt(0) === '.')) {
            this.debug('dot detected!', file, fr, pattern, pr)
            break
          }

          // ** swallows a segment, and continue.
          this.debug('globstar swallow a segment, and continue')
          fr++
        }
      }

      // no match was found.
      // However, in partial mode, we can't say this is necessarily over.
      // If there's more *pattern* left, then
      /* istanbul ignore if */
      if (partial) {
        // ran out of file
        this.debug('\n>>> no match, partial?', file, fr, pattern, pr)
        if (fr === fl) return true
      }
      return false
    }

    // something other than **
    // non-magic patterns just have to match exactly
    // patterns with magic have been turned into regexps.
    var hit
    if (typeof p === 'string') {
      hit = f === p
      this.debug('string match', p, f, hit)
    } else {
      hit = f.match(p)
      this.debug('pattern match', p, f, hit)
    }

    if (!hit) return false
  }

  // Note: ending in / means that we'll get a final ""
  // at the end of the pattern.  This can only match a
  // corresponding "" at the end of the file.
  // If the file ends in /, then it can only match a
  // a pattern that ends in /, unless the pattern just
  // doesn't have any more for it. But, a/b/ should *not*
  // match "a/b/*", even though "" matches against the
  // [^/]*? pattern, except in partial mode, where it might
  // simply not be reached yet.
  // However, a/b/ should still satisfy a/*

  // now either we fell off the end of the pattern, or we're done.
  if (fi === fl && pi === pl) {
    // ran out of pattern and filename at the same time.
    // an exact hit!
    return true
  } else if (fi === fl) {
    // ran out of file, but still had pattern left.
    // this is ok if we're doing the match as part of
    // a glob fs traversal.
    return partial
  } else /* istanbul ignore else */ if (pi === pl) {
    // ran out of pattern, still have file left.
    // this is only acceptable if we're on the very last
    // empty segment of a file with a trailing slash.
    // a/* should match a/b/
    return (fi === fl - 1) && (file[fi] === '')
  }

  // should be unreachable.
  /* istanbul ignore next */
  throw new Error('wtf?')
}

// replace stuff like \* with *
function globUnescape (s) {
  return s.replace(/\\(.)/g, '$1')
}

function regExpEscape (s) {
  return s.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')
}


/***/ }),
/* 159 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var concatMap = __webpack_require__(160);
var balanced = __webpack_require__(161);

module.exports = expandTop;

var escSlash = '\0SLASH'+Math.random()+'\0';
var escOpen = '\0OPEN'+Math.random()+'\0';
var escClose = '\0CLOSE'+Math.random()+'\0';
var escComma = '\0COMMA'+Math.random()+'\0';
var escPeriod = '\0PERIOD'+Math.random()+'\0';

function numeric(str) {
  return parseInt(str, 10) == str
    ? parseInt(str, 10)
    : str.charCodeAt(0);
}

function escapeBraces(str) {
  return str.split('\\\\').join(escSlash)
            .split('\\{').join(escOpen)
            .split('\\}').join(escClose)
            .split('\\,').join(escComma)
            .split('\\.').join(escPeriod);
}

function unescapeBraces(str) {
  return str.split(escSlash).join('\\')
            .split(escOpen).join('{')
            .split(escClose).join('}')
            .split(escComma).join(',')
            .split(escPeriod).join('.');
}


// Basically just str.split(","), but handling cases
// where we have nested braced sections, which should be
// treated as individual members, like {a,{b,c},d}
function parseCommaParts(str) {
  if (!str)
    return [''];

  var parts = [];
  var m = balanced('{', '}', str);

  if (!m)
    return str.split(',');

  var pre = m.pre;
  var body = m.body;
  var post = m.post;
  var p = pre.split(',');

  p[p.length-1] += '{' + body + '}';
  var postParts = parseCommaParts(post);
  if (post.length) {
    p[p.length-1] += postParts.shift();
    p.push.apply(p, postParts);
  }

  parts.push.apply(parts, p);

  return parts;
}

function expandTop(str) {
  if (!str)
    return [];

  // I don't know why Bash 4.3 does this, but it does.
  // Anything starting with {} will have the first two bytes preserved
  // but *only* at the top level, so {},a}b will not expand to anything,
  // but a{},b}c will be expanded to [a}c,abc].
  // One could argue that this is a bug in Bash, but since the goal of
  // this module is to match Bash's rules, we escape a leading {}
  if (str.substr(0, 2) === '{}') {
    str = '\\{\\}' + str.substr(2);
  }

  return expand(escapeBraces(str), true).map(unescapeBraces);
}

function identity(e) {
  return e;
}

function embrace(str) {
  return '{' + str + '}';
}
function isPadded(el) {
  return /^-?0\d/.test(el);
}

function lte(i, y) {
  return i <= y;
}
function gte(i, y) {
  return i >= y;
}

function expand(str, isTop) {
  var expansions = [];

  var m = balanced('{', '}', str);
  if (!m || /\$$/.test(m.pre)) return [str];

  var isNumericSequence = /^-?\d+\.\.-?\d+(?:\.\.-?\d+)?$/.test(m.body);
  var isAlphaSequence = /^[a-zA-Z]\.\.[a-zA-Z](?:\.\.-?\d+)?$/.test(m.body);
  var isSequence = isNumericSequence || isAlphaSequence;
  var isOptions = m.body.indexOf(',') >= 0;
  if (!isSequence && !isOptions) {
    // {a},b}
    if (m.post.match(/,.*\}/)) {
      str = m.pre + '{' + m.body + escClose + m.post;
      return expand(str);
    }
    return [str];
  }

  var n;
  if (isSequence) {
    n = m.body.split(/\.\./);
  } else {
    n = parseCommaParts(m.body);
    if (n.length === 1) {
      // x{{a,b}}y ==> x{a}y x{b}y
      n = expand(n[0], false).map(embrace);
      if (n.length === 1) {
        var post = m.post.length
          ? expand(m.post, false)
          : [''];
        return post.map(function(p) {
          return m.pre + n[0] + p;
        });
      }
    }
  }

  // at this point, n is the parts, and we know it's not a comma set
  // with a single entry.

  // no need to expand pre, since it is guaranteed to be free of brace-sets
  var pre = m.pre;
  var post = m.post.length
    ? expand(m.post, false)
    : [''];

  var N;

  if (isSequence) {
    var x = numeric(n[0]);
    var y = numeric(n[1]);
    var width = Math.max(n[0].length, n[1].length)
    var incr = n.length == 3
      ? Math.abs(numeric(n[2]))
      : 1;
    var test = lte;
    var reverse = y < x;
    if (reverse) {
      incr *= -1;
      test = gte;
    }
    var pad = n.some(isPadded);

    N = [];

    for (var i = x; test(i, y); i += incr) {
      var c;
      if (isAlphaSequence) {
        c = String.fromCharCode(i);
        if (c === '\\')
          c = '';
      } else {
        c = String(i);
        if (pad) {
          var need = width - c.length;
          if (need > 0) {
            var z = new Array(need + 1).join('0');
            if (i < 0)
              c = '-' + z + c.slice(1);
            else
              c = z + c;
          }
        }
      }
      N.push(c);
    }
  } else {
    N = concatMap(n, function(el) { return expand(el, false) });
  }

  for (var j = 0; j < N.length; j++) {
    for (var k = 0; k < post.length; k++) {
      var expansion = pre + N[j] + post[k];
      if (!isTop || isSequence || expansion)
        expansions.push(expansion);
    }
  }

  return expansions;
}



/***/ }),
/* 160 */
/***/ ((module) => {

module.exports = function (xs, fn) {
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        var x = fn(xs[i], i);
        if (isArray(x)) res.push.apply(res, x);
        else res.push(x);
    }
    return res;
};

var isArray = Array.isArray || function (xs) {
    return Object.prototype.toString.call(xs) === '[object Array]';
};


/***/ }),
/* 161 */
/***/ ((module) => {

"use strict";

module.exports = balanced;
function balanced(a, b, str) {
  if (a instanceof RegExp) a = maybeMatch(a, str);
  if (b instanceof RegExp) b = maybeMatch(b, str);

  var r = range(a, b, str);

  return r && {
    start: r[0],
    end: r[1],
    pre: str.slice(0, r[0]),
    body: str.slice(r[0] + a.length, r[1]),
    post: str.slice(r[1] + b.length)
  };
}

function maybeMatch(reg, str) {
  var m = str.match(reg);
  return m ? m[0] : null;
}

balanced.range = range;
function range(a, b, str) {
  var begs, beg, left, right, result;
  var ai = str.indexOf(a);
  var bi = str.indexOf(b, ai + 1);
  var i = ai;

  if (ai >= 0 && bi > 0) {
    if(a===b) {
      return [ai, bi];
    }
    begs = [];
    left = str.length;

    while (i >= 0 && !result) {
      if (i == ai) {
        begs.push(i);
        ai = str.indexOf(a, i + 1);
      } else if (begs.length == 1) {
        result = [ begs.pop(), bi ];
      } else {
        beg = begs.pop();
        if (beg < left) {
          left = beg;
          right = bi;
        }

        bi = str.indexOf(b, i + 1);
      }

      i = ai < bi && ai >= 0 ? ai : bi;
    }

    if (begs.length) {
      result = [ left, right ];
    }
  }

  return result;
}


/***/ }),
/* 162 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

try {
  var util = __webpack_require__(163);
  /* istanbul ignore next */
  if (typeof util.inherits !== 'function') throw '';
  module.exports = util.inherits;
} catch (e) {
  /* istanbul ignore next */
  module.exports = __webpack_require__(164);
}


/***/ }),
/* 163 */
/***/ ((module) => {

"use strict";
module.exports = require("util");

/***/ }),
/* 164 */
/***/ ((module) => {

if (typeof Object.create === 'function') {
  // implementation from standard node.js 'util' module
  module.exports = function inherits(ctor, superCtor) {
    if (superCtor) {
      ctor.super_ = superCtor
      ctor.prototype = Object.create(superCtor.prototype, {
        constructor: {
          value: ctor,
          enumerable: false,
          writable: true,
          configurable: true
        }
      })
    }
  };
} else {
  // old school shim for old browsers
  module.exports = function inherits(ctor, superCtor) {
    if (superCtor) {
      ctor.super_ = superCtor
      var TempCtor = function () {}
      TempCtor.prototype = superCtor.prototype
      ctor.prototype = new TempCtor()
      ctor.prototype.constructor = ctor
    }
  }
}


/***/ }),
/* 165 */
/***/ ((module) => {

"use strict";
module.exports = require("events");

/***/ }),
/* 166 */
/***/ ((module) => {

"use strict";
module.exports = require("assert");

/***/ }),
/* 167 */
/***/ ((module) => {

"use strict";


function posix(path) {
	return path.charAt(0) === '/';
}

function win32(path) {
	// https://github.com/nodejs/node/blob/b3fcc245fb25539909ef1d5eaa01dbf92e168633/lib/path.js#L56
	var splitDeviceRe = /^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$/;
	var result = splitDeviceRe.exec(path);
	var device = result[1] || '';
	var isUnc = Boolean(device && device.charAt(1) !== ':');

	// UNC paths are always absolute
	return Boolean(result[2] || isUnc);
}

module.exports = process.platform === 'win32' ? win32 : posix;
module.exports.posix = posix;
module.exports.win32 = win32;


/***/ }),
/* 168 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

module.exports = globSync
globSync.GlobSync = GlobSync

var rp = __webpack_require__(155)
var minimatch = __webpack_require__(158)
var Minimatch = minimatch.Minimatch
var Glob = (__webpack_require__(154).Glob)
var util = __webpack_require__(163)
var path = __webpack_require__(27)
var assert = __webpack_require__(166)
var isAbsolute = __webpack_require__(167)
var common = __webpack_require__(169)
var setopts = common.setopts
var ownProp = common.ownProp
var childrenIgnored = common.childrenIgnored
var isIgnored = common.isIgnored

function globSync (pattern, options) {
  if (typeof options === 'function' || arguments.length === 3)
    throw new TypeError('callback provided to sync glob\n'+
                        'See: https://github.com/isaacs/node-glob/issues/167')

  return new GlobSync(pattern, options).found
}

function GlobSync (pattern, options) {
  if (!pattern)
    throw new Error('must provide pattern')

  if (typeof options === 'function' || arguments.length === 3)
    throw new TypeError('callback provided to sync glob\n'+
                        'See: https://github.com/isaacs/node-glob/issues/167')

  if (!(this instanceof GlobSync))
    return new GlobSync(pattern, options)

  setopts(this, pattern, options)

  if (this.noprocess)
    return this

  var n = this.minimatch.set.length
  this.matches = new Array(n)
  for (var i = 0; i < n; i ++) {
    this._process(this.minimatch.set[i], i, false)
  }
  this._finish()
}

GlobSync.prototype._finish = function () {
  assert(this instanceof GlobSync)
  if (this.realpath) {
    var self = this
    this.matches.forEach(function (matchset, index) {
      var set = self.matches[index] = Object.create(null)
      for (var p in matchset) {
        try {
          p = self._makeAbs(p)
          var real = rp.realpathSync(p, self.realpathCache)
          set[real] = true
        } catch (er) {
          if (er.syscall === 'stat')
            set[self._makeAbs(p)] = true
          else
            throw er
        }
      }
    })
  }
  common.finish(this)
}


GlobSync.prototype._process = function (pattern, index, inGlobStar) {
  assert(this instanceof GlobSync)

  // Get the first [n] parts of pattern that are all strings.
  var n = 0
  while (typeof pattern[n] === 'string') {
    n ++
  }
  // now n is the index of the first one that is *not* a string.

  // See if there's anything else
  var prefix
  switch (n) {
    // if not, then this is rather simple
    case pattern.length:
      this._processSimple(pattern.join('/'), index)
      return

    case 0:
      // pattern *starts* with some non-trivial item.
      // going to readdir(cwd), but not include the prefix in matches.
      prefix = null
      break

    default:
      // pattern has some string bits in the front.
      // whatever it starts with, whether that's 'absolute' like /foo/bar,
      // or 'relative' like '../baz'
      prefix = pattern.slice(0, n).join('/')
      break
  }

  var remain = pattern.slice(n)

  // get the list of entries.
  var read
  if (prefix === null)
    read = '.'
  else if (isAbsolute(prefix) || isAbsolute(pattern.join('/'))) {
    if (!prefix || !isAbsolute(prefix))
      prefix = '/' + prefix
    read = prefix
  } else
    read = prefix

  var abs = this._makeAbs(read)

  //if ignored, skip processing
  if (childrenIgnored(this, read))
    return

  var isGlobStar = remain[0] === minimatch.GLOBSTAR
  if (isGlobStar)
    this._processGlobStar(prefix, read, abs, remain, index, inGlobStar)
  else
    this._processReaddir(prefix, read, abs, remain, index, inGlobStar)
}


GlobSync.prototype._processReaddir = function (prefix, read, abs, remain, index, inGlobStar) {
  var entries = this._readdir(abs, inGlobStar)

  // if the abs isn't a dir, then nothing can match!
  if (!entries)
    return

  // It will only match dot entries if it starts with a dot, or if
  // dot is set.  Stuff like @(.foo|.bar) isn't allowed.
  var pn = remain[0]
  var negate = !!this.minimatch.negate
  var rawGlob = pn._glob
  var dotOk = this.dot || rawGlob.charAt(0) === '.'

  var matchedEntries = []
  for (var i = 0; i < entries.length; i++) {
    var e = entries[i]
    if (e.charAt(0) !== '.' || dotOk) {
      var m
      if (negate && !prefix) {
        m = !e.match(pn)
      } else {
        m = e.match(pn)
      }
      if (m)
        matchedEntries.push(e)
    }
  }

  var len = matchedEntries.length
  // If there are no matched entries, then nothing matches.
  if (len === 0)
    return

  // if this is the last remaining pattern bit, then no need for
  // an additional stat *unless* the user has specified mark or
  // stat explicitly.  We know they exist, since readdir returned
  // them.

  if (remain.length === 1 && !this.mark && !this.stat) {
    if (!this.matches[index])
      this.matches[index] = Object.create(null)

    for (var i = 0; i < len; i ++) {
      var e = matchedEntries[i]
      if (prefix) {
        if (prefix.slice(-1) !== '/')
          e = prefix + '/' + e
        else
          e = prefix + e
      }

      if (e.charAt(0) === '/' && !this.nomount) {
        e = path.join(this.root, e)
      }
      this._emitMatch(index, e)
    }
    // This was the last one, and no stats were needed
    return
  }

  // now test all matched entries as stand-ins for that part
  // of the pattern.
  remain.shift()
  for (var i = 0; i < len; i ++) {
    var e = matchedEntries[i]
    var newPattern
    if (prefix)
      newPattern = [prefix, e]
    else
      newPattern = [e]
    this._process(newPattern.concat(remain), index, inGlobStar)
  }
}


GlobSync.prototype._emitMatch = function (index, e) {
  if (isIgnored(this, e))
    return

  var abs = this._makeAbs(e)

  if (this.mark)
    e = this._mark(e)

  if (this.absolute) {
    e = abs
  }

  if (this.matches[index][e])
    return

  if (this.nodir) {
    var c = this.cache[abs]
    if (c === 'DIR' || Array.isArray(c))
      return
  }

  this.matches[index][e] = true

  if (this.stat)
    this._stat(e)
}


GlobSync.prototype._readdirInGlobStar = function (abs) {
  // follow all symlinked directories forever
  // just proceed as if this is a non-globstar situation
  if (this.follow)
    return this._readdir(abs, false)

  var entries
  var lstat
  var stat
  try {
    lstat = this.fs.lstatSync(abs)
  } catch (er) {
    if (er.code === 'ENOENT') {
      // lstat failed, doesn't exist
      return null
    }
  }

  var isSym = lstat && lstat.isSymbolicLink()
  this.symlinks[abs] = isSym

  // If it's not a symlink or a dir, then it's definitely a regular file.
  // don't bother doing a readdir in that case.
  if (!isSym && lstat && !lstat.isDirectory())
    this.cache[abs] = 'FILE'
  else
    entries = this._readdir(abs, false)

  return entries
}

GlobSync.prototype._readdir = function (abs, inGlobStar) {
  var entries

  if (inGlobStar && !ownProp(this.symlinks, abs))
    return this._readdirInGlobStar(abs)

  if (ownProp(this.cache, abs)) {
    var c = this.cache[abs]
    if (!c || c === 'FILE')
      return null

    if (Array.isArray(c))
      return c
  }

  try {
    return this._readdirEntries(abs, this.fs.readdirSync(abs))
  } catch (er) {
    this._readdirError(abs, er)
    return null
  }
}

GlobSync.prototype._readdirEntries = function (abs, entries) {
  // if we haven't asked to stat everything, then just
  // assume that everything in there exists, so we can avoid
  // having to stat it a second time.
  if (!this.mark && !this.stat) {
    for (var i = 0; i < entries.length; i ++) {
      var e = entries[i]
      if (abs === '/')
        e = abs + e
      else
        e = abs + '/' + e
      this.cache[e] = true
    }
  }

  this.cache[abs] = entries

  // mark and cache dir-ness
  return entries
}

GlobSync.prototype._readdirError = function (f, er) {
  // handle errors, and cache the information
  switch (er.code) {
    case 'ENOTSUP': // https://github.com/isaacs/node-glob/issues/205
    case 'ENOTDIR': // totally normal. means it *does* exist.
      var abs = this._makeAbs(f)
      this.cache[abs] = 'FILE'
      if (abs === this.cwdAbs) {
        var error = new Error(er.code + ' invalid cwd ' + this.cwd)
        error.path = this.cwd
        error.code = er.code
        throw error
      }
      break

    case 'ENOENT': // not terribly unusual
    case 'ELOOP':
    case 'ENAMETOOLONG':
    case 'UNKNOWN':
      this.cache[this._makeAbs(f)] = false
      break

    default: // some unusual error.  Treat as failure.
      this.cache[this._makeAbs(f)] = false
      if (this.strict)
        throw er
      if (!this.silent)
        console.error('glob error', er)
      break
  }
}

GlobSync.prototype._processGlobStar = function (prefix, read, abs, remain, index, inGlobStar) {

  var entries = this._readdir(abs, inGlobStar)

  // no entries means not a dir, so it can never have matches
  // foo.txt/** doesn't match foo.txt
  if (!entries)
    return

  // test without the globstar, and with every child both below
  // and replacing the globstar.
  var remainWithoutGlobStar = remain.slice(1)
  var gspref = prefix ? [ prefix ] : []
  var noGlobStar = gspref.concat(remainWithoutGlobStar)

  // the noGlobStar pattern exits the inGlobStar state
  this._process(noGlobStar, index, false)

  var len = entries.length
  var isSym = this.symlinks[abs]

  // If it's a symlink, and we're in a globstar, then stop
  if (isSym && inGlobStar)
    return

  for (var i = 0; i < len; i++) {
    var e = entries[i]
    if (e.charAt(0) === '.' && !this.dot)
      continue

    // these two cases enter the inGlobStar state
    var instead = gspref.concat(entries[i], remainWithoutGlobStar)
    this._process(instead, index, true)

    var below = gspref.concat(entries[i], remain)
    this._process(below, index, true)
  }
}

GlobSync.prototype._processSimple = function (prefix, index) {
  // XXX review this.  Shouldn't it be doing the mounting etc
  // before doing stat?  kinda weird?
  var exists = this._stat(prefix)

  if (!this.matches[index])
    this.matches[index] = Object.create(null)

  // If it doesn't exist, then just mark the lack of results
  if (!exists)
    return

  if (prefix && isAbsolute(prefix) && !this.nomount) {
    var trail = /[\/\\]$/.test(prefix)
    if (prefix.charAt(0) === '/') {
      prefix = path.join(this.root, prefix)
    } else {
      prefix = path.resolve(this.root, prefix)
      if (trail)
        prefix += '/'
    }
  }

  if (process.platform === 'win32')
    prefix = prefix.replace(/\\/g, '/')

  // Mark this as a match
  this._emitMatch(index, prefix)
}

// Returns either 'DIR', 'FILE', or false
GlobSync.prototype._stat = function (f) {
  var abs = this._makeAbs(f)
  var needDir = f.slice(-1) === '/'

  if (f.length > this.maxLength)
    return false

  if (!this.stat && ownProp(this.cache, abs)) {
    var c = this.cache[abs]

    if (Array.isArray(c))
      c = 'DIR'

    // It exists, but maybe not how we need it
    if (!needDir || c === 'DIR')
      return c

    if (needDir && c === 'FILE')
      return false

    // otherwise we have to stat, because maybe c=true
    // if we know it exists, but not what it is.
  }

  var exists
  var stat = this.statCache[abs]
  if (!stat) {
    var lstat
    try {
      lstat = this.fs.lstatSync(abs)
    } catch (er) {
      if (er && (er.code === 'ENOENT' || er.code === 'ENOTDIR')) {
        this.statCache[abs] = false
        return false
      }
    }

    if (lstat && lstat.isSymbolicLink()) {
      try {
        stat = this.fs.statSync(abs)
      } catch (er) {
        stat = lstat
      }
    } else {
      stat = lstat
    }
  }

  this.statCache[abs] = stat

  var c = true
  if (stat)
    c = stat.isDirectory() ? 'DIR' : 'FILE'

  this.cache[abs] = this.cache[abs] || c

  if (needDir && c === 'FILE')
    return false

  return c
}

GlobSync.prototype._mark = function (p) {
  return common.mark(this, p)
}

GlobSync.prototype._makeAbs = function (f) {
  return common.makeAbs(this, f)
}


/***/ }),
/* 169 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

exports.setopts = setopts
exports.ownProp = ownProp
exports.makeAbs = makeAbs
exports.finish = finish
exports.mark = mark
exports.isIgnored = isIgnored
exports.childrenIgnored = childrenIgnored

function ownProp (obj, field) {
  return Object.prototype.hasOwnProperty.call(obj, field)
}

var fs = __webpack_require__(156)
var path = __webpack_require__(27)
var minimatch = __webpack_require__(158)
var isAbsolute = __webpack_require__(167)
var Minimatch = minimatch.Minimatch

function alphasort (a, b) {
  return a.localeCompare(b, 'en')
}

function setupIgnores (self, options) {
  self.ignore = options.ignore || []

  if (!Array.isArray(self.ignore))
    self.ignore = [self.ignore]

  if (self.ignore.length) {
    self.ignore = self.ignore.map(ignoreMap)
  }
}

// ignore patterns are always in dot:true mode.
function ignoreMap (pattern) {
  var gmatcher = null
  if (pattern.slice(-3) === '/**') {
    var gpattern = pattern.replace(/(\/\*\*)+$/, '')
    gmatcher = new Minimatch(gpattern, { dot: true })
  }

  return {
    matcher: new Minimatch(pattern, { dot: true }),
    gmatcher: gmatcher
  }
}

function setopts (self, pattern, options) {
  if (!options)
    options = {}

  // base-matching: just use globstar for that.
  if (options.matchBase && -1 === pattern.indexOf("/")) {
    if (options.noglobstar) {
      throw new Error("base matching requires globstar")
    }
    pattern = "**/" + pattern
  }

  self.silent = !!options.silent
  self.pattern = pattern
  self.strict = options.strict !== false
  self.realpath = !!options.realpath
  self.realpathCache = options.realpathCache || Object.create(null)
  self.follow = !!options.follow
  self.dot = !!options.dot
  self.mark = !!options.mark
  self.nodir = !!options.nodir
  if (self.nodir)
    self.mark = true
  self.sync = !!options.sync
  self.nounique = !!options.nounique
  self.nonull = !!options.nonull
  self.nosort = !!options.nosort
  self.nocase = !!options.nocase
  self.stat = !!options.stat
  self.noprocess = !!options.noprocess
  self.absolute = !!options.absolute
  self.fs = options.fs || fs

  self.maxLength = options.maxLength || Infinity
  self.cache = options.cache || Object.create(null)
  self.statCache = options.statCache || Object.create(null)
  self.symlinks = options.symlinks || Object.create(null)

  setupIgnores(self, options)

  self.changedCwd = false
  var cwd = process.cwd()
  if (!ownProp(options, "cwd"))
    self.cwd = cwd
  else {
    self.cwd = path.resolve(options.cwd)
    self.changedCwd = self.cwd !== cwd
  }

  self.root = options.root || path.resolve(self.cwd, "/")
  self.root = path.resolve(self.root)
  if (process.platform === "win32")
    self.root = self.root.replace(/\\/g, "/")

  // TODO: is an absolute `cwd` supposed to be resolved against `root`?
  // e.g. { cwd: '/test', root: __dirname } === path.join(__dirname, '/test')
  self.cwdAbs = isAbsolute(self.cwd) ? self.cwd : makeAbs(self, self.cwd)
  if (process.platform === "win32")
    self.cwdAbs = self.cwdAbs.replace(/\\/g, "/")
  self.nomount = !!options.nomount

  // disable comments and negation in Minimatch.
  // Note that they are not supported in Glob itself anyway.
  options.nonegate = true
  options.nocomment = true

  self.minimatch = new Minimatch(pattern, options)
  self.options = self.minimatch.options
}

function finish (self) {
  var nou = self.nounique
  var all = nou ? [] : Object.create(null)

  for (var i = 0, l = self.matches.length; i < l; i ++) {
    var matches = self.matches[i]
    if (!matches || Object.keys(matches).length === 0) {
      if (self.nonull) {
        // do like the shell, and spit out the literal glob
        var literal = self.minimatch.globSet[i]
        if (nou)
          all.push(literal)
        else
          all[literal] = true
      }
    } else {
      // had matches
      var m = Object.keys(matches)
      if (nou)
        all.push.apply(all, m)
      else
        m.forEach(function (m) {
          all[m] = true
        })
    }
  }

  if (!nou)
    all = Object.keys(all)

  if (!self.nosort)
    all = all.sort(alphasort)

  // at *some* point we statted all of these
  if (self.mark) {
    for (var i = 0; i < all.length; i++) {
      all[i] = self._mark(all[i])
    }
    if (self.nodir) {
      all = all.filter(function (e) {
        var notDir = !(/\/$/.test(e))
        var c = self.cache[e] || self.cache[makeAbs(self, e)]
        if (notDir && c)
          notDir = c !== 'DIR' && !Array.isArray(c)
        return notDir
      })
    }
  }

  if (self.ignore.length)
    all = all.filter(function(m) {
      return !isIgnored(self, m)
    })

  self.found = all
}

function mark (self, p) {
  var abs = makeAbs(self, p)
  var c = self.cache[abs]
  var m = p
  if (c) {
    var isDir = c === 'DIR' || Array.isArray(c)
    var slash = p.slice(-1) === '/'

    if (isDir && !slash)
      m += '/'
    else if (!isDir && slash)
      m = m.slice(0, -1)

    if (m !== p) {
      var mabs = makeAbs(self, m)
      self.statCache[mabs] = self.statCache[abs]
      self.cache[mabs] = self.cache[abs]
    }
  }

  return m
}

// lotta situps...
function makeAbs (self, f) {
  var abs = f
  if (f.charAt(0) === '/') {
    abs = path.join(self.root, f)
  } else if (isAbsolute(f) || f === '') {
    abs = f
  } else if (self.changedCwd) {
    abs = path.resolve(self.cwd, f)
  } else {
    abs = path.resolve(f)
  }

  if (process.platform === 'win32')
    abs = abs.replace(/\\/g, '/')

  return abs
}


// Return true, if pattern ends with globstar '**', for the accompanying parent directory.
// Ex:- If node_modules/** is the pattern, add 'node_modules' to ignore list along with it's contents
function isIgnored (self, path) {
  if (!self.ignore.length)
    return false

  return self.ignore.some(function(item) {
    return item.matcher.match(path) || !!(item.gmatcher && item.gmatcher.match(path))
  })
}

function childrenIgnored (self, path) {
  if (!self.ignore.length)
    return false

  return self.ignore.some(function(item) {
    return !!(item.gmatcher && item.gmatcher.match(path))
  })
}


/***/ }),
/* 170 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var wrappy = __webpack_require__(171)
var reqs = Object.create(null)
var once = __webpack_require__(172)

module.exports = wrappy(inflight)

function inflight (key, cb) {
  if (reqs[key]) {
    reqs[key].push(cb)
    return null
  } else {
    reqs[key] = [cb]
    return makeres(key)
  }
}

function makeres (key) {
  return once(function RES () {
    var cbs = reqs[key]
    var len = cbs.length
    var args = slice(arguments)

    // XXX It's somewhat ambiguous whether a new callback added in this
    // pass should be queued for later execution if something in the
    // list of callbacks throws, or if it should just be discarded.
    // However, it's such an edge case that it hardly matters, and either
    // choice is likely as surprising as the other.
    // As it happens, we do go ahead and schedule it for later execution.
    try {
      for (var i = 0; i < len; i++) {
        cbs[i].apply(null, args)
      }
    } finally {
      if (cbs.length > len) {
        // added more in the interim.
        // de-zalgo, just in case, but don't call again.
        cbs.splice(0, len)
        process.nextTick(function () {
          RES.apply(null, args)
        })
      } else {
        delete reqs[key]
      }
    }
  })
}

function slice (args) {
  var length = args.length
  var array = []

  for (var i = 0; i < length; i++) array[i] = args[i]
  return array
}


/***/ }),
/* 171 */
/***/ ((module) => {

// Returns a wrapper function that returns a wrapped callback
// The wrapper function should do some stuff, and return a
// presumably different callback function.
// This makes sure that own properties are retained, so that
// decorations and such are not lost along the way.
module.exports = wrappy
function wrappy (fn, cb) {
  if (fn && cb) return wrappy(fn)(cb)

  if (typeof fn !== 'function')
    throw new TypeError('need wrapper function')

  Object.keys(fn).forEach(function (k) {
    wrapper[k] = fn[k]
  })

  return wrapper

  function wrapper() {
    var args = new Array(arguments.length)
    for (var i = 0; i < args.length; i++) {
      args[i] = arguments[i]
    }
    var ret = fn.apply(this, args)
    var cb = args[args.length-1]
    if (typeof ret === 'function' && ret !== cb) {
      Object.keys(cb).forEach(function (k) {
        ret[k] = cb[k]
      })
    }
    return ret
  }
}


/***/ }),
/* 172 */
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

var wrappy = __webpack_require__(171)
module.exports = wrappy(once)
module.exports.strict = wrappy(onceStrict)

once.proto = once(function () {
  Object.defineProperty(Function.prototype, 'once', {
    value: function () {
      return once(this)
    },
    configurable: true
  })

  Object.defineProperty(Function.prototype, 'onceStrict', {
    value: function () {
      return onceStrict(this)
    },
    configurable: true
  })
})

function once (fn) {
  var f = function () {
    if (f.called) return f.value
    f.called = true
    return f.value = fn.apply(this, arguments)
  }
  f.called = false
  return f
}

function onceStrict (fn) {
  var f = function () {
    if (f.called)
      throw new Error(f.onceError)
    f.called = true
    return f.value = fn.apply(this, arguments)
  }
  var name = fn.name || 'Function wrapped with `once`'
  f.onceError = name + " shouldn't be called more than once"
  f.called = false
  return f
}


/***/ }),
/* 173 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.activate = void 0;
const kernelChildNodeProvider_1 = __webpack_require__(22);
const vscode_1 = __webpack_require__(1);
const kernelMessageProvider_1 = __webpack_require__(174);
let activated = false;
async function activate(context) {
    async function activateFeature() {
        if (activated) {
            return;
        }
        activated = true;
        const jupyterExt = vscode_1.extensions.getExtension('ms-toolsai.jupyter');
        if (!jupyterExt) {
            return;
        }
        await jupyterExt.activate();
        const kernelService = await jupyterExt.exports.getKernelService();
        if (!kernelService) {
            return;
        }
        const provider = new kernelMessageProvider_1.ActiveKernelMessageProvider(kernelService);
        kernelChildNodeProvider_1.ActiveKernelChildNodesProviderRegistry.instance.registerProvider(provider);
        context.subscriptions.push(provider);
        vscode_1.commands.registerCommand('jupyter-kernelManager.inspectKernelMessages', () => {
            provider.activate();
        });
    }
    if (vscode_1.workspace.getConfiguration('jupyter').get('inspectKernelMessages.enabled') &&
        vscode_1.workspace.getConfiguration('jupyter').get('kernelManagement.enabled')) {
        await activateFeature();
        return;
    }
    vscode_1.workspace.onDidChangeConfiguration((e) => {
        if (e.affectsConfiguration('jupyter') &&
            vscode_1.workspace.getConfiguration('jupyter').get('inspectKernelMessages.enabled') &&
            vscode_1.workspace.getConfiguration('jupyter').get('kernelManagement.enabled')) {
            activateFeature().catch((ex) => console.error('Failed to activate kernel management feature', ex));
        }
    }, undefined, context.subscriptions);
}
exports.activate = activate;


/***/ }),
/* 174 */
/***/ ((__unused_webpack_module, exports, __webpack_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ActiveKernelMessageProvider = void 0;
const vscode_1 = __webpack_require__(1);
class MessagesTreeItem extends vscode_1.TreeItem {
    constructor(data) {
        super('Kernel Messages', vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.contextValue = 'kernelMessagesRoot';
    }
}
const requestIconsByMessageType = new Map([
    ['clear_output', 'clear-all'],
    ['error', 'error'],
    ['complete_request', 'symbol-enum'],
    ['is_complete_request', 'symbol-enum'],
    ['execute_request', 'play'],
    ['input_request', 'play'],
    ['inspect_request', 'inspect'],
    ['debug_request', 'debug'],
    ['history_request', 'history'],
    ['interrupt_request', 'symbol-event'],
    ['kernel_info_request', 'info'],
    ['comm_info_request', 'info'],
    ['comm_close', 'close'],
    ['comm_open', 'folder-opened'],
    ['comm_msg', 'gear'],
    ['shutdown_request', 'close']
]);
const responseIconsByMessageType = new Map([
    ['clear_output', 'clear-all'],
    ['error', 'error'],
    ['comm_close', 'sign-out'],
    ['comm_open', 'sign-in'],
    ['comm_msg', 'gear'],
    ['status', 'pulse'],
    ['debug_event', 'debug'],
    ['debug_reply', 'debug'],
    ['display_data', 'output'],
    ['stream', 'symbol-key']
]);
function getTextForClipboard(value) {
    if (typeof value === 'string') {
        return value.trim();
    }
    else if (typeof value === 'number') {
        return value.toString();
    }
    else if (typeof value === 'boolean') {
        return value.toString();
    }
    return undefined;
}
class MessageTreeItem extends vscode_1.TreeItem {
    constructor(data) {
        super(data.label, vscode_1.TreeItemCollapsibleState.Collapsed);
        this.data = data;
        this.description = data.description;
        this.contextValue = `kernelMessageItem:${data.__type}:${data.clipboardText ? 'canCopyToClipboard' : ''}`;
        if (data.__type === 'parentMessageNode' || data.direction === 'send') {
            this.iconPath = new vscode_1.ThemeIcon('call-outgoing');
            if (data.__type !== 'parentMessageNode') {
                const icon = requestIconsByMessageType.get(data.msg.header.msg_type) || 'indent';
                this.iconPath = new vscode_1.ThemeIcon(icon);
            }
            const exec = data.msg;
            if (data.msg.header.msg_type === 'execute_request' && data.msg.channel === 'shell' && exec.content.code) {
                this.description = getSingleLineValue(exec.content.code);
                this.tooltip = exec.content.code;
            }
            const complete = data.msg;
            if (data.msg.header.msg_type === 'complete_request' &&
                data.msg.channel === 'shell' &&
                complete.content.code) {
                this.description = getSingleLineValue(complete.content.code);
                this.tooltip = complete.content.code;
            }
            const inspect = data.msg;
            if (data.msg.header.msg_type === 'inspect_request' &&
                data.msg.channel === 'shell' &&
                inspect.content.code) {
                this.description = getSingleLineValue(inspect.content.code);
                this.tooltip = inspect.content.code;
            }
            const debugRequest = data.msg;
            if (data.msg.header.msg_type === 'debug_request' &&
                data.msg.channel === 'control' &&
                debugRequest.content.command) {
                let descriptionParts = [`${debugRequest.content.command} (seq: ${debugRequest.content.seq}`];
                this.description = `${debugRequest.content.command} (seq: ${debugRequest.content.seq})`;
                if ((debugRequest.content.command === 'evaluate' ||
                    debugRequest.content.command === 'variables' ||
                    debugRequest.content.command === 'stackTrace') &&
                    debugRequest.content.arguments &&
                    typeof debugRequest.content.arguments === 'object') {
                    this.description = descriptionParts
                        .concat([`, arguments, ${JSON.stringify(debugRequest.content.arguments)})`])
                        .join('');
                }
                if (debugRequest.content.command === 'dumpCell' &&
                    debugRequest.content.arguments &&
                    typeof debugRequest.content.arguments === 'object' &&
                    typeof debugRequest.content.arguments['code'] === 'string') {
                    descriptionParts = [`${debugRequest.content.command}`];
                    this.description = descriptionParts
                        .concat([
                        `, ${debugRequest.content.arguments.code
                            .split('\r\n')
                            .join('\\r\\n')
                            .split('\n')
                            .join('\\n')}`
                    ])
                        .join('');
                    this.tooltip = debugRequest.content.arguments.code;
                }
                if (debugRequest.content.command === 'setBreakpoints' &&
                    debugRequest.content.arguments &&
                    typeof debugRequest.content.arguments === 'object' &&
                    typeof debugRequest.content.arguments['source'] === 'object' &&
                    typeof debugRequest.content.arguments['source']['path'] === 'string' &&
                    Array.isArray(debugRequest.content.arguments['breakpoints'])) {
                    descriptionParts = [
                        `${debugRequest.content.command}, source: ${debugRequest.content.arguments.source.path}`
                    ];
                    const lines = [];
                    debugRequest.content.arguments['breakpoints'].forEach((line) => {
                        lines.push(line.line);
                        descriptionParts.push(`\n,line: ${line.line}`);
                    });
                    this.description = descriptionParts.join('');
                    this.tooltip = `${debugRequest.content.arguments.source.path}\nlines: ${lines.join(', ')}`;
                }
            }
        }
        else if (data.direction === 'recv') {
            const icon = responseIconsByMessageType.get(data.msg.header.msg_type) || 'call-incoming';
            this.iconPath = new vscode_1.ThemeIcon(icon);
            const statusMsg = data.msg;
            if (data.msg.header.msg_type === 'status' &&
                data.msg.channel === 'iopub' &&
                statusMsg.content.execution_state) {
                this.description = statusMsg.content.execution_state;
            }
            const execInput = data.msg;
            if (data.msg.header.msg_type === 'execute_input' &&
                data.msg.channel === 'iopub' &&
                typeof execInput.content.execution_count === 'number') {
                this.description = `execution_count = ${execInput.content.execution_count}`;
            }
            const stream = data.msg;
            if (data.msg.header.msg_type === 'stream' &&
                data.msg.channel === 'iopub' &&
                stream.content.name &&
                stream.content.text) {
                this.description = `${stream.content.name}: ${stream.content.text
                    .split('\r\n')
                    .join('\\r\\n')
                    .split('\n')
                    .join('\\n')}`;
                this.tooltip = stream.content.text;
            }
            const execReply = data.msg;
            if (data.msg.header.msg_type === 'execute_reply' && data.msg.channel === 'shell') {
                this.description = `${execReply.content.status}, execution_count = ${execReply.content.execution_count}`;
            }
            const inspect = data.msg;
            if (data.msg.header.msg_type === 'inspect_reply' && data.msg.channel === 'shell') {
                this.description = inspect.content.status;
            }
            const debugReply = data.msg;
            if (data.msg.header.msg_type === 'debug_reply' &&
                data.msg.channel === 'control' &&
                debugReply.content.command) {
                this.description = `${debugReply.content.command} (success: ${debugReply.content.success}, seq: ${debugReply.content.seq})`;
                if (debugReply.content.command === 'dumpCell' &&
                    debugReply.content.body &&
                    typeof debugReply.content.body['sourcePath'] === 'string') {
                    this.description = `${debugReply.content.command}, ${debugReply.content.body['sourcePath']}`;
                }
            }
            const debugEvent = data.msg;
            if (data.msg.header.msg_type === 'debug_event' &&
                data.msg.channel === 'iopub' &&
                debugEvent.content.event) {
                this.description = `${debugEvent.content.event} (seq: ${debugEvent.content.seq})`;
            }
            const errorMsg = data.msg;
            if (data.msg.header.msg_type === 'error' && data.msg.channel === 'iopub' && errorMsg.content.ename) {
                this.description = errorMsg.content.ename;
            }
        }
        if (!this.tooltip) {
            this.tooltip = (this.description || '').replace(/\\n/g, '\n');
        }
    }
}
class DataTreeItem extends vscode_1.TreeItem {
    constructor(data) {
        super(data.label, data.hasChildren ? vscode_1.TreeItemCollapsibleState.Collapsed : vscode_1.TreeItemCollapsibleState.None);
        this.data = data;
        this.description = data.description;
        this.tooltip = data.tooltip;
        this.contextValue = `kernelMessageItem:${data.__type}:${data.clipboardText ? 'canCopyToClipboard' : ''}`;
    }
}
function getStringRepresentation(value) {
    if (value === undefined) {
        return 'undefined';
    }
    else if (value === null) {
        return 'null';
    }
    else {
        return value.toString();
    }
}
function getSingleLineValue(value) {
    return value.split('\r\n').join('\\r\\n').split('\n').join('\\n');
}
class ActiveKernelMessageProvider {
    constructor(kernelService) {
        this.kernelService = kernelService;
        this._onDidChangeTreeData = new vscode_1.EventEmitter();
        this.connections = new WeakMap();
        this.disposables = [];
        this.messagesByConnection = new WeakMap();
        this.id = 'kernelSpy';
        this.messageViewType = 'tree';
    }
    get onDidChangeTreeData() {
        return this._onDidChangeTreeData.event;
    }
    activate() {
        if (this.activated) {
            return;
        }
        this.disposables.push(...[
            vscode_1.commands.registerCommand('jupyter-kernelManager.clearKernelMessages', (data) => {
                const info = this.getConnectionInfo(data.connection);
                info.requestsById.clear();
                info.messages.splice(0, info.messages.length);
                this._onDidChangeTreeData.fire(data);
            }),
            vscode_1.commands.registerCommand('jupyter-kernelManager.viewKernelMessagesAsTree', (data) => {
                this.messageViewType = 'tree';
                this._onDidChangeTreeData.fire(data);
            }),
            vscode_1.commands.registerCommand('jupyter-kernelManager.viewKernelMessagesAsList', (data) => {
                this.messageViewType = 'list';
                this._onDidChangeTreeData.fire(data);
            }),
            vscode_1.commands.registerCommand('jupyter-kernelManager.kernelMessageCopy', (data) => {
                vscode_1.env.clipboard.writeText(data.clipboardText || '');
            })
        ]);
        this.activated = true;
        this.kernelService.onDidChangeKernels(() => {
            const kernels = this.kernelService.getActiveKernels();
            kernels.forEach((item) => {
                if (!item.uri) {
                    return;
                }
                const kernel = this.kernelService.getKernel(item.uri);
                if (!kernel) {
                    return;
                }
                this.addHandler(kernel.connection);
            });
        }, this, this.disposables);
    }
    dispose() {
        this._onDidChangeTreeData.dispose();
        this.disposables.forEach((d) => d.dispose());
    }
    getChildren(node) {
        var _a;
        if (!this.activated) {
            return [];
        }
        if (node.type === 'activeLocalKernel' || node.type === 'activeRemoteKernel') {
            if (!((_a = node.connection) === null || _a === void 0 ? void 0 : _a.kernel)) {
                return [];
            }
            const rootNode = {
                type: 'customNodeFromAnotherProvider',
                __type: 'rootNode',
                providerId: this.id,
                connection: node.connection.kernel
            };
            this.addHandler(node.connection, rootNode);
            return [rootNode];
        }
        if (node.type !== 'customNodeFromAnotherProvider') {
            return [];
        }
        const ourNode = node;
        if (ourNode.__type === 'rootNode') {
            const messages = this.getConnectionInfo(ourNode.connection).messages;
            if (this.messageViewType === 'tree') {
                return messages.filter((msg) => msg.isTopLevelMessage);
            }
            else {
                return messages;
            }
        }
        else if (ourNode.__type === 'parentMessageNode') {
            const info = this.getConnectionInfo(ourNode.connection);
            const children = info.requestsById.get(ourNode.msg_id);
            if (children) {
                return children.children;
            }
            else {
                return [];
            }
        }
        else if (ourNode.__type === 'messageNode') {
            const header = ourNode.msg.header;
            return Object.keys(ourNode.msg).map((prop) => {
                const value = ourNode.msg[prop];
                const hasChildren = typeof value !== 'undefined' &&
                    value !== null &&
                    (typeof value === 'object' || Array.isArray(value));
                const isEmptyObject = hasChildren && !Array.isArray(value) && Object.keys(value).length === 0;
                const isEmptyArray = hasChildren && Array.isArray(value) && value.length === 0;
                const stringValue = typeof value === 'string' ? getSingleLineValue(value) : getStringRepresentation(value);
                let description = isEmptyObject ? '{ }' : isEmptyArray ? '[ ]' : stringValue;
                let tooltip = isEmptyObject ? '{ }' : isEmptyArray ? '[ ]' : getStringRepresentation(value);
                if (!value) {
                }
                else if (prop === 'header') {
                    description = `msg_id: ${header.msg_id}`;
                }
                else if (prop === 'parent_header') {
                    const parentHeader = ourNode.msg.parent_header;
                    if (parentHeader && 'msg_id' in parentHeader) {
                        description = `msg_id: ${parentHeader.msg_id}`;
                    }
                }
                else if (prop === 'content' && header.msg_type === 'comm_open') {
                    const commOpen = ourNode.msg;
                    description = `${commOpen.content.target_name}: ${commOpen.content.comm_id}`;
                    tooltip = `target_name: ${commOpen.content.target_name}\ncomm_id: ${commOpen.content.comm_id}\target_module: ${commOpen.content.target_module}`;
                }
                else if (prop === 'content' && header.msg_type === 'comm_msg') {
                    const commMsg = ourNode.msg;
                    description = `comm_id: ${commMsg.content.comm_id}`;
                }
                else if (prop === 'content' && header.msg_type === 'display_data') {
                    const commMsg = ourNode.msg;
                    const mimes = Object.keys(commMsg.content.data);
                    tooltip = mimes.join(', ');
                    description = mimes
                        .map((mime) => {
                        if (mime === 'application/vnd.jupyter.widget-view+json') {
                            const mimeData = commMsg.content.data[mime] || { model_id: '' };
                            return `${mime}:${mimeData['model_id']}`;
                        }
                        else {
                            return mime;
                        }
                    })
                        .join(', ');
                }
                return {
                    __type: 'dataNode',
                    description,
                    tooltip,
                    property: prop,
                    label: prop,
                    paths: [prop],
                    providerId: ourNode.providerId,
                    type: 'customNodeFromAnotherProvider',
                    msg: ourNode.msg,
                    hasChildren: hasChildren && !isEmptyObject && !isEmptyArray,
                    clipboardText: getTextForClipboard(value)
                };
            });
        }
        else {
            let data = ourNode.msg;
            const currentPath = ourNode.paths.join('.');
            ourNode.paths.forEach((path) => {
                data = data[path];
            });
            if (typeof data === 'undefined' || data === null) {
                return [];
            }
            const header = ourNode.msg.header;
            if (Array.isArray(data)) {
                return data.map((value, index) => {
                    const hasChildren = typeof value !== 'undefined' &&
                        value !== null &&
                        (typeof value === 'object' || Array.isArray(value));
                    const isEmptyObject = hasChildren && !Array.isArray(value) && Object.keys(value).length === 0;
                    const isEmptyArray = hasChildren && Array.isArray(value) && value.length === 0;
                    const stringValue = typeof value === 'string' ? getSingleLineValue(value) : getStringRepresentation(value);
                    const description = isEmptyObject ? '{ }' : isEmptyArray ? '[ ]' : stringValue;
                    const tooltip = isEmptyObject ? '{ }' : isEmptyArray ? '[ ]' : getStringRepresentation(value);
                    return {
                        __type: 'dataNode',
                        description,
                        tooltip,
                        index,
                        label: index.toString(),
                        paths: ourNode.paths.concat(index),
                        providerId: ourNode.providerId,
                        type: 'customNodeFromAnotherProvider',
                        msg: ourNode.msg,
                        hasChildren: hasChildren && !isEmptyObject && !isEmptyArray,
                        clipboardText: getTextForClipboard(value)
                    };
                });
            }
            else if (typeof data === 'object') {
                return Object.keys(data).map((prop) => {
                    const value = data[prop];
                    const hasChildren = typeof value !== 'undefined' &&
                        value !== null &&
                        (typeof value === 'object' || Array.isArray(value));
                    const isEmptyObject = hasChildren && !Array.isArray(value) && Object.keys(value).length === 0;
                    const isEmptyArray = hasChildren && Array.isArray(value) && value.length === 0;
                    const stringValue = typeof value === 'string' ? getSingleLineValue(value) : getStringRepresentation(value);
                    let description = isEmptyObject ? '{ }' : isEmptyArray ? '[ ]' : stringValue;
                    let tooltip = isEmptyObject ? '{ }' : isEmptyArray ? '[ ]' : getStringRepresentation(value);
                    if (header.msg_type === 'comm_msg' && value && typeof value === 'object') {
                        if ((currentPath === 'content' && prop === 'data') ||
                            (currentPath === 'content.data' && prop === 'state')) {
                            try {
                                description = JSON.stringify({ ...value, buffer_paths: [] });
                                tooltip = JSON.stringify({ ...value, buffer_paths: [] }, undefined, 4);
                            }
                            catch (_a) {
                            }
                        }
                    }
                    return {
                        __type: 'dataNode',
                        description,
                        tooltip,
                        property: prop,
                        label: prop,
                        paths: ourNode.paths.concat(prop),
                        providerId: ourNode.providerId,
                        type: 'customNodeFromAnotherProvider',
                        msg: ourNode.msg,
                        hasChildren: hasChildren && !isEmptyObject && !isEmptyArray,
                        clipboardText: getTextForClipboard(value)
                    };
                });
            }
            else {
                return [];
            }
        }
        return [];
    }
    getTreeItem(node) {
        const ourNode = node;
        if (ourNode.__type && (ourNode.__type === 'messageNode' || ourNode.__type === 'parentMessageNode')) {
            return new MessageTreeItem(ourNode);
        }
        else if (ourNode.__type && ourNode.__type === 'dataNode') {
            return new DataTreeItem(ourNode);
        }
        return new MessagesTreeItem(ourNode);
    }
    getConnectionInfo(connection) {
        if (!this.messagesByConnection.has(connection)) {
            this.messagesByConnection.set(connection, {
                messages: [],
                requestsById: new Map()
            });
        }
        return this.messagesByConnection.get(connection);
    }
    addHandler(connection, parent) {
        if (connection.kernel && this.connections.has(connection.kernel)) {
            if (parent && !this.connections.get(connection.kernel)) {
                this.connections.set(connection.kernel, parent);
            }
            return;
        }
        if (!connection.kernel) {
            return;
        }
        this.connections.set(connection.kernel, parent);
        const anyHandler = this.onAnyMessageHandler.bind(this, parent);
        connection.kernel.anyMessage.connect(anyHandler, this);
        this.disposables.push(new vscode_1.Disposable(() => connection.kernel.anyMessage.disconnect(anyHandler)));
        const ioPubHandler = this.onIOPubMessageHandler.bind(this, parent);
        connection.kernel.iopubMessage.connect(ioPubHandler, this);
        this.disposables.push(new vscode_1.Disposable(() => connection.kernel.iopubMessage.disconnect(ioPubHandler)));
        const unhandledHandler = this.onUnhandledMessageHandler.bind(this, parent);
        connection.kernel.unhandledMessage.connect(unhandledHandler, this);
        this.disposables.push(new vscode_1.Disposable(() => connection.kernel.unhandledMessage.disconnect(unhandledHandler)));
    }
    onAnyMessageHandler(root, connection, args) {
        root = root || this.connections.get(connection);
        if (args.direction === 'recv' && args.msg.channel === 'iopub') {
            return;
        }
        const { messages, requestsById } = this.getConnectionInfo(connection);
        const label = `${args.msg.channel}.${args.msg.header.msg_type}`;
        const description = args.msg.header.msg_id;
        const parentId = 'msg_id' in args.msg.parent_header ? args.msg.parent_header.msg_id : '';
        const message = {
            __type: 'messageNode',
            direction: args.direction,
            providerId: this.id,
            label,
            description,
            msg_id: args.msg.header.msg_id,
            parent: undefined,
            connection,
            msg: args.msg,
            type: 'customNodeFromAnotherProvider'
        };
        const info = requestsById.get(args.msg.header.msg_id) || requestsById.get(parentId);
        messages.push(message);
        if (info) {
            message.parent = info.parent;
            info.children.push(message);
            this._onDidChangeTreeData.fire(info.parent);
        }
        else {
            message.isTopLevelMessage = true;
            if (args.direction === 'send' && !requestsById.has(args.msg.header.msg_id)) {
                requestsById.set(args.msg.header.msg_id, { parent: message, children: [{ ...message }] });
                message.__type = 'parentMessageNode';
            }
            if (root) {
                this._onDidChangeTreeData.fire(root);
            }
        }
    }
    onIOPubMessageHandler(root, connection, args) {
        root = root || this.connections.get(connection);
        const { messages, requestsById } = this.getConnectionInfo(connection);
        const label = `${args.channel}.${args.header.msg_type}`;
        const description = args.header.msg_id;
        const parentId = 'msg_id' in args.parent_header ? args.parent_header.msg_id : '';
        const message = {
            __type: 'messageNode',
            direction: 'recv',
            providerId: this.id,
            label,
            description,
            msg_id: args.header.msg_id,
            parent: undefined,
            connection,
            msg: args,
            type: 'customNodeFromAnotherProvider'
        };
        const info = requestsById.get(args.header.msg_id) || requestsById.get(parentId);
        messages.push(message);
        if (info) {
            message.parent = info.parent;
            info.children.push(message);
            this._onDidChangeTreeData.fire(info.parent);
        }
        else {
            message.isTopLevelMessage = true;
            if (root) {
                this._onDidChangeTreeData.fire(root);
            }
        }
    }
    onUnhandledMessageHandler(root, connection, args) {
        root = root || this.connections.get(connection);
        const { messages, requestsById } = this.getConnectionInfo(connection);
        const label = `${args.channel}.${args.header.msg_type}`;
        const description = args.header.msg_id;
        const parentId = 'msg_id' in args.parent_header ? args.parent_header.msg_id : '';
        const message = {
            __type: 'messageNode',
            direction: 'recv',
            providerId: this.id,
            label,
            description,
            msg_id: args.header.msg_id,
            parent: undefined,
            connection,
            msg: args,
            type: 'customNodeFromAnotherProvider'
        };
        const info = requestsById.get(args.header.msg_id) || requestsById.get(parentId);
        messages.push(message);
        if (info) {
            message.parent = info.parent;
            info.children.push(message);
            this._onDidChangeTreeData.fire(info.parent);
        }
        else {
            message.isTopLevelMessage = true;
            if (root) {
                this._onDidChangeTreeData.fire(root);
            }
        }
    }
}
exports.ActiveKernelMessageProvider = ActiveKernelMessageProvider;


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
/******/ 			id: moduleId,
/******/ 			loaded: false,
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/node module decorator */
/******/ 	(() => {
/******/ 		__webpack_require__.nmd = (module) => {
/******/ 			module.paths = [];
/******/ 			if (!module.children) module.children = [];
/******/ 			return module;
/******/ 		};
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
const extension_2 = __webpack_require__(25);
const extension_3 = __webpack_require__(173);
async function activate(context) {
    if (vscode.workspace.getConfiguration('jupyter').get('notebookRunGroups.enabled')) {
        (0, startup_1.activateNotebookRunGroups)(context);
    }
    await (0, extension_1.activate)(context);
    await (0, extension_3.activate)(context);
    if (vscode.workspace.getConfiguration('jupyter').get('contextualHelp.enabled')) {
        await (0, extension_2.activate)(context);
    }
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;

})();

module.exports = __webpack_exports__;
/******/ })()
;
//# sourceMappingURL=main.js.map