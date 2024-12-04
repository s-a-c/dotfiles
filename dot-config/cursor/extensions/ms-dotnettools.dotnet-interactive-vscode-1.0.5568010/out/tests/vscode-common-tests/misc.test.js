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
const chai_1 = require("chai");
const utilities_1 = require("../../src/vscode-common/interfaces/utilities");
const utilities_2 = require("../../src/vscode-common/utilities");
const utilities_3 = require("./utilities");
const vscodeLike = require("../../src/vscode-common/interfaces/vscode-like");
const metadataUtilities_1 = require("../../src/vscode-common/metadataUtilities");
describe('Miscellaneous tests', () => {
    it(`verify command and argument replacement is as expected`, () => {
        let template = {
            args: [
                '{dotnet_path}',
                'tool',
                'run',
                'dotnet-interactive',
                '--',
                'stdio',
                '--working-dir',
                '{working_dir}'
            ],
            workingDirectory: '{global_storage_path}'
        };
        let actual = (0, utilities_2.processArguments)(template, 'replacement-working-dir', 'replacement-dotnet-path', 'replacement-global-storage-path');
        (0, chai_1.expect)(actual).to.deep.equal({
            command: 'replacement-dotnet-path',
            args: [
                'tool',
                'run',
                'dotnet-interactive',
                '--',
                'stdio',
                '--working-dir',
                'replacement-working-dir'
            ],
            workingDirectory: 'replacement-global-storage-path',
            env: {}
        });
    });
    it('notebook working directory comes from notebook uri if local', () => {
        const notebookUri = (0, utilities_2.createUri)('path/to/notebook.dib');
        const workspaceFolderUris = [
            (0, utilities_2.createUri)('not/used/1'),
            (0, utilities_2.createUri)('not/used/2'),
        ];
        const workingDir = (0, utilities_2.getWorkingDirectoryForNotebook)(notebookUri, workspaceFolderUris, 'fallback-not-used');
        (0, chai_1.expect)(workingDir).to.equal('path/to');
    });
    it('notebook working directory comes from local workspace if notebook is untitled', () => {
        const notebookUri = (0, utilities_2.createUri)('path/to/notebook.dib', 'untitled');
        const workspaceFolderUris = [
            (0, utilities_2.createUri)('not/used', 'remote'),
            (0, utilities_2.createUri)('this/is/local/and/used'),
        ];
        const workingDir = (0, utilities_2.getWorkingDirectoryForNotebook)(notebookUri, workspaceFolderUris, 'fallback-not-used');
        (0, chai_1.expect)(workingDir).to.equal('this/is/local/and/used');
    });
    it('notebook working directory comes from fallback if notebook is remote', () => {
        const notebookUri = (0, utilities_2.createUri)('path/to/notebook.dib', 'remote');
        const workspaceFolderUris = [
            (0, utilities_2.createUri)('not/used/1'),
            (0, utilities_2.createUri)('not/used/2'),
        ];
        const workingDir = (0, utilities_2.getWorkingDirectoryForNotebook)(notebookUri, workspaceFolderUris, 'fallback-is-used');
        (0, chai_1.expect)(workingDir).to.equal('fallback-is-used');
    });
    it('debounce test', () => __awaiter(void 0, void 0, void 0, function* () {
        let callbackHit = false;
        let debounceDelay = 500;
        // repeatedly call `debounce` with small delays
        for (let i = 0; i < 10; i++) {
            (0, utilities_2.debounce)('key', debounceDelay, () => {
                if (callbackHit) {
                    throw new Error('Deboune callback was called more than once; this should never happen.');
                }
                callbackHit = true;
            });
            yield new Promise(resolve => setTimeout(resolve, 100));
        }
        // wait for the debounced callback to actually have a chance
        yield new Promise(resolve => setTimeout(resolve, debounceDelay * 1.1));
        (0, chai_1.expect)(callbackHit).to.be.true;
    })).timeout(5000);
    it('cell error output shape can be detected', () => {
        // strongly typed to catch interface changes
        const error = {
            errorName: 'ename',
            errorValue: 'evalue',
            stackTrace: [
                'stack trace line 1',
                'stack trace line 2'
            ]
        };
        (0, chai_1.expect)((0, utilities_1.isErrorOutput)(error)).to.be.true;
    });
    it('cell display output shape can be detected', () => {
        // strongly typed to catch interface changes
        const display = {
            data: {
                'text/html': 'html',
                'text/plain': 'text'
            },
            metadata: {}
        };
        (0, chai_1.expect)((0, utilities_1.isDisplayOutput)(display)).to.be.true;
    });
    it('cell text output shape can be detected', () => {
        // strongly typed to catch interface changes
        const text = {
            name: 'some name',
            text: 'some text'
        };
        (0, chai_1.expect)((0, utilities_1.isTextOutput)(text)).to.be.true;
    });
    it('parse function can handle base64-encoded Uint8Array', () => {
        const numbers = [1, 2, 3];
        const base64 = Buffer.from(numbers).toString('base64');
        const value = (0, utilities_2.parse)(`{"rawData":"${base64}"}`);
        (0, chai_1.expect)(value).to.deep.equal({
            rawData: Uint8Array.from(numbers)
        });
    });
    it('stringify function can handle Uint8Array', () => {
        const numbers = [1, 2, 3];
        const text = (0, utilities_2.stringify)({
            rawData: new Uint8Array(numbers)
        });
        const expectedBase64 = Buffer.from(numbers).toString('base64');
        (0, chai_1.expect)(text).to.equal(`{"rawData":"${expectedBase64}"}`);
    });
    it('stringify function can handle Buffer', () => {
        const numbers = [1, 2, 3];
        const text = (0, utilities_2.stringify)({
            rawData: Buffer.from(numbers)
        });
        const expectedBase64 = Buffer.from(numbers).toString('base64');
        (0, chai_1.expect)(text).to.equal(`{"rawData":"${expectedBase64}"}`);
    });
    it('stringify function can handle cell output', () => {
        const numbers = [97, 98, 99];
        const text = (0, utilities_2.stringify)({
            'text/html': Buffer.from(numbers)
        });
        (0, chai_1.expect)(text).to.equal(`{"text/html":"abc"}`);
    });
    describe('vs code output value reshaping', () => {
        it('error string is reshaped', () => {
            const reshaped = (0, utilities_1.reshapeOutputValueForVsCode)('some error message', vscodeLike.ErrorOutputMimeType);
            const decoded = JSON.parse((0, utilities_3.decodeToString)(reshaped));
            (0, chai_1.expect)(decoded).to.deep.equal({
                ename: 'Error',
                evalue: 'some error message',
                traceback: [],
            });
        });
        it(`non-error mime type doesn't reshape output`, () => {
            const reshaped = (0, utilities_1.reshapeOutputValueForVsCode)('some error message', 'text/plain');
            const decoded = (0, utilities_3.decodeToString)(reshaped);
            (0, chai_1.expect)(decoded).to.equal('some error message');
        });
    });
    it('executing a non-existent process still returns', () => __awaiter(void 0, void 0, void 0, function* () {
        const result = yield (0, utilities_2.executeSafe)('this-is-a-command-that-will-fail', []);
        (0, chai_1.expect)(result).to.deep.equal({
            code: -1,
            output: '',
            error: 'Error: spawn this-is-a-command-that-will-fail ENOENT',
        });
    }));
    describe('dotnet version checking', () => {
        it('version number can be obtained from simple value', () => {
            const version = (0, utilities_2.getVersionNumber)('5.0');
            (0, chai_1.expect)(version).to.equal('5.0');
        });
        it(`version number from empty string doesn't throw`, () => {
            const version = (0, utilities_2.getVersionNumber)('');
            (0, chai_1.expect)(version).to.equal('');
        });
        for (const newline of ['\n', '\r\n']) {
            it(`version number with leading and trailing newlines returns correct result with ${JSON.stringify(newline)} newlines`, () => {
                const version = (0, utilities_2.getVersionNumber)(`${newline}5.0${newline}`);
                (0, chai_1.expect)(version).to.equal('5.0');
            });
            it(`version number with first-run text is properly pulled out with ${JSON.stringify(newline)} newlines`, () => {
                const version = (0, utilities_2.getVersionNumber)(`${newline}Welcome to .NET 5.0!${newline}--------${newline}5.0.101`);
                (0, chai_1.expect)(version).to.equal('5.0.101');
            });
        }
    });
    describe('sorted objects', () => {
        it('sorts object keys', () => {
            const source = {
                'key2': "value",
                'key1': [1, 2, 3, 4]
            };
            const sorted = (0, metadataUtilities_1.sortInPlace)(source);
            (0, chai_1.expect)(sorted).to.deep.equal({
                key1: [1, 2, 3, 4],
                key2: 'value'
            });
        });
        it('sorts object recursively', () => {
            const source = {
                'key2': "value",
                'key1': [1, 2, 3, 4],
                'key3': {
                    'key2': "value",
                    'key1': [1, 2, 3, 4],
                }
            };
            const sorted = (0, metadataUtilities_1.sortInPlace)(source);
            (0, chai_1.expect)(sorted).to.deep.equal({
                key1: [1, 2, 3, 4],
                key2: 'value',
                key3: {
                    key1: [1, 2, 3, 4],
                    key2: 'value'
                }
            });
        });
        it('sorts object containing arrays', () => {
            const source = {
                'key2': "value",
                'key1': [6, 2, 3, 4],
                'key3': {
                    'key2': "value",
                    'key1': [1, 5, 3, 4],
                }
            };
            const sorted = (0, metadataUtilities_1.sortInPlace)(source);
            (0, chai_1.expect)(sorted).to.deep.equal({
                key1: [2, 3, 4, 6],
                key2: 'value',
                key3: {
                    key1: [1, 3, 4, 5],
                    key2: 'value'
                }
            });
        });
        it('sorts kernel infos by local name', () => {
            const source = {
                'key2': "value",
                'key1': [6, 2, 3, 4],
                'key3': {
                    'key2': "value",
                    'key1': [{ localName: "d", displayName: "1" }, { localName: "a", displayName: "3" }, { localName: "b", displayName: "2" }],
                }
            };
            const sorted = (0, metadataUtilities_1.sortInPlace)(source);
            (0, chai_1.expect)(sorted).to.deep.equal({
                key1: [2, 3, 4, 6],
                key2: 'value',
                key3: {
                    key1: [
                        { displayName: '3', localName: 'a' },
                        { displayName: '2', localName: 'b' },
                        { displayName: '1', localName: 'd' }
                    ],
                    key2: 'value'
                }
            });
        });
    });
    describe('comparing objects', () => {
        it('objects are equivalent regardles of key order', () => {
            const data1 = {
                'key2': "value",
                'key1': [1, 2, 3, 4]
            };
            const data2 = {
                'key1': [1, 2, 3, 4],
                'key2': "value"
            };
            const d = (0, metadataUtilities_1.areEquivalentObjects)(data1, data2);
            (0, chai_1.expect)(d).to.be.true;
        });
        it('objects are equivalent regardles of array order', () => {
            const data1 = {
                'key2': "value",
                'key1': [1, 2, 3, 4]
            };
            const data2 = {
                'key1': [1, 3, 2, 4],
                'key2': "value"
            };
            const d = (0, metadataUtilities_1.areEquivalentObjects)(data1, data2);
            (0, chai_1.expect)(d).to.be.true;
        });
        it('can ingore keys when checking if objects are equivalent', () => {
            const data1 = {
                'key2': "value",
                'key1': [1, 2, 3, 4],
                'key5': "value"
            };
            const data2 = {
                'key1': [1, 3, 2, 4],
                'key2': "value",
                'key4': "value"
            };
            const ingoreKeys = new Set();
            ingoreKeys.add("key4");
            ingoreKeys.add("key5");
            const d = (0, metadataUtilities_1.areEquivalentObjects)(data1, data2, ingoreKeys);
            (0, chai_1.expect)(d).to.be.true;
        });
        it('objects are not equivalent if they have different data', () => {
            const data1 = {
                'key2': "value",
                'key1': [1, 2, 3, 4]
            };
            const data2 = {
                'key1': [1, 2, 3, 4, 5],
                'key2': "value"
            };
            const d = (0, metadataUtilities_1.areEquivalentObjects)(data1, data2);
            (0, chai_1.expect)(d).to.be.false;
        });
        it('objects are not equivalent if they have different keys', () => {
            const data1 = {
                'key2': "value",
                'key1': [1, 2, 3, 4]
            };
            const data2 = {
                'key12': [1, 2, 3, 4],
                'key22': "value"
            };
            const d = (0, metadataUtilities_1.areEquivalentObjects)(data1, data2);
            (0, chai_1.expect)(d).to.be.false;
        });
    });
});
//# sourceMappingURL=misc.test.js.map