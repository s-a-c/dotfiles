"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.areEquivalentObjects = exports.createDefaultNotebookDocumentMetadata = exports.mergeRawMetadata = exports.mergeNotebookDocumentMetadata = exports.mergeNotebookCellMetadata = exports.sortInPlace = exports.sortAndMerge = exports.getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata = exports.getRawInteractiveDocumentMetadataFromNotebookDocumentMetadata = exports.getRawNotebookCellMetadataFromNotebookCellMetadata = exports.getRawInteractiveDocumentElementMetadataFromNotebookCellMetadata = exports.createNewIpynbMetadataWithNotebookDocumentMetadata = exports.getKernelspecMetadataFromNotebookDocumentMetadata = exports.getKernelInfosFromNotebookDocument = exports.getKernelspecMetadataFromIpynbNotebookDocument = exports.getNotebookDocumentMetadataFromCompositeKernel = exports.getNotebookDocumentMetadataFromNotebookDocument = exports.getDocumentMetadata = exports.getCellMetadata = exports.getNotebookDocumentMetadataFromInteractiveDocument = exports.getNotebookCellMetadataFromNotebookCellElement = exports.getNotebookCellMetadataFromInteractiveDocumentElement = exports.isDotNetNotebook = exports.isIpynbNotebook = void 0;
const commandsAndEvents = require("./polyglot-notebooks/commandsAndEvents");
function isIpynbNotebook(notebookDocument) {
    return notebookDocument.uri.fsPath.toLowerCase().endsWith('.ipynb');
}
exports.isIpynbNotebook = isIpynbNotebook;
function isDotNetNotebook(notebook) {
    const notebookUriString = notebook.uri.toString();
    if (notebookUriString.endsWith('.dib') || notebook.uri.fsPath.endsWith('.dib')) {
        return true;
    }
    const kernelspecMetadata = getKernelspecMetadataFromIpynbNotebookDocument(notebook);
    if (kernelspecMetadata.name.startsWith('.net-')) {
        return true;
    }
    // doesn't look like us
    return false;
}
exports.isDotNetNotebook = isDotNetNotebook;
function getNotebookCellMetadataFromInteractiveDocumentElement(interactiveDocumentElement) {
    var _a, _b;
    const cellMetadata = createDefaultNotebookCellMetadata();
    // first try to get the old `dotnet_interactive` value...
    const dotnet_interactive = (_a = interactiveDocumentElement.metadata) === null || _a === void 0 ? void 0 : _a.dotnet_interactive;
    if (typeof dotnet_interactive === 'object') {
        const language = dotnet_interactive.language;
        if (typeof language === 'string') {
            // this is a really unfortunate case where we were storing the kernel name, but calling it the language
            cellMetadata.kernelName = language;
        }
    }
    // ...then try newer `polyglot_notebook` value
    const polyglot_notebook = (_b = interactiveDocumentElement.metadata) === null || _b === void 0 ? void 0 : _b.polyglot_notebook;
    if (typeof polyglot_notebook === 'object') {
        const kernelName = polyglot_notebook.kernelName;
        if (typeof kernelName === 'string') {
            cellMetadata.kernelName = kernelName;
        }
    }
    return cellMetadata;
}
exports.getNotebookCellMetadataFromInteractiveDocumentElement = getNotebookCellMetadataFromInteractiveDocumentElement;
function getNotebookCellMetadataFromNotebookCellElement(notebookCell) {
    const cellMetadata = createDefaultNotebookCellMetadata();
    const metadata = getCellMetadata(notebookCell);
    if (typeof metadata === 'object') {
        // first try to get the old `dotnet_interactive` value...
        const dotnet_interactive = metadata.dotnet_interactive;
        if (typeof dotnet_interactive === 'object') {
            const language = dotnet_interactive.language;
            if (typeof language === 'string') {
                // this is a really unfortunate case where we were storing the kernel name, but calling it the language
                cellMetadata.kernelName = language;
            }
        }
        // ...then try newer `polyglot_notebook` value
        const polyglot_notebook = metadata.polyglot_notebook;
        if (typeof polyglot_notebook === 'object') {
            const kernelName = polyglot_notebook.kernelName;
            if (typeof kernelName === 'string') {
                cellMetadata.kernelName = kernelName;
            }
        }
    }
    return cellMetadata;
}
exports.getNotebookCellMetadataFromNotebookCellElement = getNotebookCellMetadataFromNotebookCellElement;
function getNotebookDocumentMetadataFromInteractiveDocument(interactiveDocument) {
    var _a, _b;
    const notebookMetadata = createDefaultNotebookDocumentMetadata();
    const kernelInfo = ((_a = interactiveDocument.metadata) === null || _a === void 0 ? void 0 : _a.kernelInfo) || ((_b = interactiveDocument.metadata.polyglot_notebook) === null || _b === void 0 ? void 0 : _b.kernelInfo);
    if (typeof kernelInfo === 'object') {
        if (typeof kernelInfo.defaultKernelName === 'string') {
            notebookMetadata.kernelInfo.defaultKernelName = kernelInfo.defaultKernelName;
        }
        const items = kernelInfo.items;
        if (Array.isArray(items) && items.every(item => typeof item === 'object')) {
            notebookMetadata.kernelInfo.items = items;
        }
    }
    notebookMetadata.kernelInfo.items = notebookMetadata.kernelInfo.items.map(item => ensureProperShapeForDocumentKernelInfo(item));
    cleanupMedata(notebookMetadata);
    return notebookMetadata;
}
exports.getNotebookDocumentMetadataFromInteractiveDocument = getNotebookDocumentMetadataFromInteractiveDocument;
function getCellMetadata(cell) {
    var _a;
    return ((_a = cell.metadata) === null || _a === void 0 ? void 0 : _a.metadata) || {};
}
exports.getCellMetadata = getCellMetadata;
function getDocumentMetadata(document) {
    var _a, _b, _c, _d;
    const ipynbMetadata = (_c = (_b = (_a = document.metadata) === null || _a === void 0 ? void 0 : _a.metadata) === null || _b === void 0 ? void 0 : _b.polyglot_notebook) !== null && _c !== void 0 ? _c : {};
    const metadata = (_d = document.metadata.polyglot_notebook) !== null && _d !== void 0 ? _d : {};
    const merged = Object.assign(Object.assign({}, ipynbMetadata), metadata);
    return merged;
}
exports.getDocumentMetadata = getDocumentMetadata;
function getNotebookDocumentMetadataFromNotebookDocument(document) {
    const notebookMetadata = createDefaultNotebookDocumentMetadata();
    let setDefaultKernel = false;
    let setItems = false;
    // .dib files will have their metadata at the root; .ipynb files will have their metadata a little deeper
    const polyglot_notebook = getDocumentMetadata(document);
    if (typeof polyglot_notebook === 'object') {
        const kernelInfo = polyglot_notebook.kernelInfo;
        if (typeof kernelInfo === 'object') {
            if (typeof kernelInfo.defaultKernelName === 'string') {
                notebookMetadata.kernelInfo.defaultKernelName = kernelInfo.defaultKernelName;
                setDefaultKernel = true;
            }
            const items = kernelInfo.items;
            if (Array.isArray(items) && items.every(item => typeof item === 'object')) {
                notebookMetadata.kernelInfo.items = items;
                setItems = true;
            }
        }
    }
    // if nothing was found, populate it from the kernelspec metadata
    if (isIpynbNotebook(document)) {
        if (!setDefaultKernel) {
            const kernelSpecMetadata = getKernelspecMetadataFromIpynbNotebookDocument(document);
            if (kernelSpecMetadata.name.startsWith('.net-')) {
                // the command `dotnet interactive jupyter install` lays down 3 well-known kernelspecs, all with the name `.net-<kernelName>`
                notebookMetadata.kernelInfo.defaultKernelName = kernelSpecMetadata.name.substring('.net-'.length);
            }
        }
        if (!setItems) {
            notebookMetadata.kernelInfo.items = [
                {
                    name: notebookMetadata.kernelInfo.defaultKernelName,
                    aliases: [],
                }
            ];
        }
    }
    notebookMetadata.kernelInfo.items = notebookMetadata.kernelInfo.items.map(item => ensureProperShapeForDocumentKernelInfo(item));
    cleanupMedata(notebookMetadata);
    return notebookMetadata;
}
exports.getNotebookDocumentMetadataFromNotebookDocument = getNotebookDocumentMetadataFromNotebookDocument;
function getNotebookDocumentMetadataFromCompositeKernel(kernel) {
    var _a;
    const notebookMetadata = createDefaultNotebookDocumentMetadata();
    notebookMetadata.kernelInfo.defaultKernelName = (_a = kernel.defaultKernelName) !== null && _a !== void 0 ? _a : notebookMetadata.kernelInfo.defaultKernelName;
    notebookMetadata.kernelInfo.items = kernel.childKernels.sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0).filter(k => k.supportsCommand(commandsAndEvents.SubmitCodeType)).map(k => ({ name: k.name, aliases: k.kernelInfo.aliases, languageName: k.kernelInfo.languageName }));
    cleanupMedata(notebookMetadata);
    return notebookMetadata;
}
exports.getNotebookDocumentMetadataFromCompositeKernel = getNotebookDocumentMetadataFromCompositeKernel;
function ensureProperShapeForDocumentKernelInfo(kernelInfo) {
    if (!kernelInfo.aliases) {
        kernelInfo.aliases = [];
    }
    if (kernelInfo.languageName === undefined) {
        delete kernelInfo.languageName;
    }
    return kernelInfo;
}
function getKernelspecMetadataFromIpynbNotebookDocument(notebook) {
    // defaulting to empty values so we don't mis-represent the document
    const kernelspecMetadata = {
        display_name: '',
        language: '',
        name: ''
    };
    const metadata = notebook.metadata.metadata;
    if (typeof metadata === 'object') {
        const kernelspec = metadata.kernelspec;
        if (typeof kernelspec === 'object') {
            const display_name = kernelspec.display_name;
            if (typeof display_name === 'string') {
                kernelspecMetadata.display_name = display_name;
            }
            const language = kernelspec.language;
            if (typeof language === 'string') {
                kernelspecMetadata.language = language;
            }
            const name = kernelspec.name;
            if (typeof name === 'string') {
                kernelspecMetadata.name = name;
            }
        }
    }
    return kernelspecMetadata;
}
exports.getKernelspecMetadataFromIpynbNotebookDocument = getKernelspecMetadataFromIpynbNotebookDocument;
function getKernelInfosFromNotebookDocument(notebookDocument) {
    const notebookDocumentMetadata = getNotebookDocumentMetadataFromNotebookDocument(notebookDocument);
    const kernelInfos = notebookDocumentMetadata.kernelInfo.items.map(item => ({
        // these are the only important ones
        localName: item.name,
        isComposite: false,
        isProxy: false,
        aliases: item.aliases,
        languageName: item.languageName,
        // these are unused
        uri: 'unused',
        displayName: 'unused',
        supportedKernelCommands: [],
        supportedDirectives: []
    }));
    kernelInfos.forEach(ki => {
        if (ki.languageName === undefined || ki.languageName === null) {
            delete ki["languageName"];
        }
    });
    return kernelInfos;
}
exports.getKernelInfosFromNotebookDocument = getKernelInfosFromNotebookDocument;
function getKernelspecMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata) {
    // these options are hard-coded because this is exactly what we put on disk with `dotnet interactive jupyter install`
    switch (notebookDocumentMetadata.kernelInfo.defaultKernelName) {
        case 'fsharp':
            return {
                display_name: '.NET (F#)',
                language: 'F#',
                name: '.net-fsharp'
            };
        case 'pwsh':
            return {
                display_name: '.NET (PowerShell)',
                language: 'PowerShell',
                name: '.net-pwsh'
            };
        case 'csharp':
        default:
            return {
                display_name: '.NET (C#)',
                language: 'C#',
                name: '.net-csharp'
            };
    }
}
exports.getKernelspecMetadataFromNotebookDocumentMetadata = getKernelspecMetadataFromNotebookDocumentMetadata;
function createNewIpynbMetadataWithNotebookDocumentMetadata(existingMetadata, notebookDocumentMetadata) {
    var _a;
    const resultMetadata = Object.assign({}, existingMetadata);
    // FIX: "custom" actually means just the bucket of things we don't persist, and therefore should not cause the document dirty state to be set
    // kernelspec
    const kernelspec = getKernelspecMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata);
    resultMetadata.metadata = (_a = resultMetadata.metadata) !== null && _a !== void 0 ? _a : {};
    resultMetadata.metadata.kernelspec = kernelspec;
    resultMetadata.metadata.polyglot_notebook = notebookDocumentMetadata;
    return resultMetadata;
}
exports.createNewIpynbMetadataWithNotebookDocumentMetadata = createNewIpynbMetadataWithNotebookDocumentMetadata;
function getRawInteractiveDocumentElementMetadataFromNotebookCellMetadata(notebookCellMetadata) {
    return notebookCellMetadata;
}
exports.getRawInteractiveDocumentElementMetadataFromNotebookCellMetadata = getRawInteractiveDocumentElementMetadataFromNotebookCellMetadata;
function getRawNotebookCellMetadataFromNotebookCellMetadata(notebookCellMetadata) {
    return {
        metadata: {
            // this is the canonical metadata
            polyglot_notebook: notebookCellMetadata,
            // this is to maintain backwards compatibility for a while
            dotnet_interactive: {
                language: notebookCellMetadata.kernelName
            }
        }
    };
}
exports.getRawNotebookCellMetadataFromNotebookCellMetadata = getRawNotebookCellMetadataFromNotebookCellMetadata;
function getRawInteractiveDocumentMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata) {
    return notebookDocumentMetadata;
}
exports.getRawInteractiveDocumentMetadataFromNotebookDocumentMetadata = getRawInteractiveDocumentMetadataFromNotebookDocumentMetadata;
function getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata, documentRawMetadata, createForIpynb) {
    const rawMetadata = {};
    if (createForIpynb) {
        const kernelspec = getKernelspecMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata);
        rawMetadata.metadata = {
            kernelspec,
            polyglot_notebook: notebookDocumentMetadata
        };
    }
    else {
        rawMetadata.polyglot_notebook = notebookDocumentMetadata;
    }
    sortAndMerge(rawMetadata, documentRawMetadata);
    return rawMetadata;
}
exports.getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata = getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata;
function sortAndMerge(destination, source) {
    if (destination === null) {
        return;
    }
    if (source === null) {
        if (destination !== null) {
            sortInPlace(destination);
        }
    }
    else {
        sortInPlace(destination);
        sortInPlace(source);
        const sourceKeys = Object.keys(source);
        for (const key of sourceKeys) {
            if (destination[key] === undefined) {
                destination[key] = source[key];
            }
            else {
                if (source[key] !== undefined && source[key] !== null) {
                    if (Array.isArray(destination[key])) {
                        mergeArray(destination[key], source[key]);
                    }
                    else if (typeof destination[key] === 'object') {
                        sortAndMerge(destination[key], source[key]);
                    }
                }
            }
        }
    }
}
exports.sortAndMerge = sortAndMerge;
function mergeArray(destination, source) {
    for (let i = 0; i < source.length; i++) {
        let srcValue = source[i];
        if (srcValue !== null) {
            if (isKernelInfo(srcValue)) {
                const found = destination.find(e => srcValue.localName.localeCompare(e.localName) === 0);
                if (found) {
                    sortAndMerge(found, srcValue);
                }
                else {
                    destination.push(srcValue);
                }
            }
            else if (isDocumentKernelInfo(srcValue)) {
                const found = destination.find(e => srcValue.name.localeCompare(e.name) === 0);
                if (found) {
                    sortAndMerge(found, srcValue);
                }
                else {
                    destination.push(srcValue);
                }
            }
            else {
                const found = destination.find(e => e === srcValue);
                if (found) {
                    sortAndMerge(found, srcValue);
                }
                else {
                    destination.push(srcValue);
                }
            }
        }
    }
}
function isKernelInfo(k) {
    return k.localName !== undefined;
}
function isDocumentKernelInfo(k) {
    return k.name !== undefined;
}
function sortInPlace(value) {
    if (value === null) {
        return value;
    }
    else if (value === undefined) {
        return value;
    }
    else if (Array.isArray(value)) {
        if (value.length > 0) {
            for (let i = 0; i < value.length; i++) {
                value[i] = sortInPlace(value[i]);
            }
            return value.sort((a, b) => {
                if (isKernelInfo(a) && isKernelInfo(b)) {
                    return a.localName.localeCompare(b.localName);
                }
                else if (isDocumentKernelInfo(a) && isDocumentKernelInfo(b)) {
                    return a.name.localeCompare(b.name);
                }
                else {
                    return a > b ? 1 : (a < b ? -1 : 0);
                }
            });
        }
        else {
            return value;
        }
    }
    else if (typeof value === 'object') {
        const sourceKeys = Object.keys(value).sort();
        let sorted = {};
        for (const key of sourceKeys) {
            const sourceValue = value[key];
            sorted[key] = sortInPlace(sourceValue);
            if (isWritable(value, key)) {
                delete value[key];
                value[key] = sorted[key];
            }
        }
        return value;
    }
    else {
        return value;
    }
}
exports.sortInPlace = sortInPlace;
function isWritable(obj, key) {
    const desc = Object.getOwnPropertyDescriptor(obj, key) || {};
    return Boolean(desc.writable);
}
function mergeNotebookCellMetadata(baseMetadata, metadataWithNewValues) {
    const resultMetadata = Object.assign({}, baseMetadata);
    if (metadataWithNewValues.kernelName) {
        resultMetadata.kernelName = metadataWithNewValues.kernelName;
    }
    return sortInPlace(resultMetadata);
}
exports.mergeNotebookCellMetadata = mergeNotebookCellMetadata;
function mergeNotebookDocumentMetadata(baseMetadata, metadataWithNewValues) {
    const resultMetadata = Object.assign({}, baseMetadata);
    const kernelInfoItems = new Map();
    for (const item of baseMetadata.kernelInfo.items) {
        kernelInfoItems.set(item.name, item);
    }
    for (const item of metadataWithNewValues.kernelInfo.items) {
        kernelInfoItems.set(item.name, item);
    }
    resultMetadata.kernelInfo.items = [...kernelInfoItems.values()];
    cleanupMedata(resultMetadata);
    return sortInPlace(resultMetadata);
}
exports.mergeNotebookDocumentMetadata = mergeNotebookDocumentMetadata;
function mergeRawMetadata(baseMetadata, metadataWithNewValues) {
    const resultMetadata = Object.assign({}, baseMetadata);
    for (const key in metadataWithNewValues) {
        resultMetadata[key] = metadataWithNewValues[key];
    }
    return sortInPlace(resultMetadata);
}
exports.mergeRawMetadata = mergeRawMetadata;
function createDefaultNotebookDocumentMetadata() {
    return {
        kernelInfo: {
            defaultKernelName: 'csharp',
            items: [
                {
                    name: 'csharp',
                    aliases: [],
                }
            ],
        }
    };
}
exports.createDefaultNotebookDocumentMetadata = createDefaultNotebookDocumentMetadata;
function createDefaultNotebookCellMetadata() {
    return {};
}
function areEquivalentObjects(object1, object2, keysToIgnore) {
    sortInPlace(object1);
    sortInPlace(object2);
    const isObject = (object) => {
        return object !== null && typeof object === 'object';
    };
    const object1Keys = Object.keys(object1).filter(k => !(keysToIgnore === null || keysToIgnore === void 0 ? void 0 : keysToIgnore.has(k)));
    const object2Keys = Object.keys(object2).filter(k => !(keysToIgnore === null || keysToIgnore === void 0 ? void 0 : keysToIgnore.has(k)));
    if (object1Keys.length !== object2Keys.length) {
        return false;
    }
    for (const key of object1Keys) {
        const value1 = object1[key];
        const value2 = object2[key];
        const bothAreObjects = isObject(value1) && isObject(value2);
        const bothAreArrays = Array.isArray(value1) && Array.isArray(value2);
        if (bothAreArrays) {
            if (value1.length !== value2.length) {
                return false;
            }
            for (let index = 0; index < value1.length; index++) {
                const element1 = value1[index];
                const element2 = value2[index];
                if (!areEquivalentObjects(element1, element2)) {
                    return false;
                }
            }
        }
        else if (bothAreObjects) {
            const equivalent = areEquivalentObjects(value1, value2);
            if (!equivalent) {
                return false;
            }
        }
        else if (value1 !== value2) {
            return false;
        }
    }
    return true;
}
exports.areEquivalentObjects = areEquivalentObjects;
function cleanupMedata(notebookMetadata) {
    notebookMetadata.kernelInfo.items.forEach(ki => {
        if (ki.languageName === undefined || ki.languageName === null) {
            delete ki.languageName;
        }
    });
}
//# sourceMappingURL=metadataUtilities.js.map