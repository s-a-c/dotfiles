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
const commandsAndEvents = require("../../src/vscode-common/polyglot-notebooks/commandsAndEvents");
const kernelSelectorUtilities = require("../../src/vscode-common/kernelSelectorUtilities");
const chai_1 = require("chai");
const polyglot_notebooks_1 = require("../../src/vscode-common/polyglot-notebooks");
describe('kernel selector utility tests', () => __awaiter(void 0, void 0, void 0, function* () {
    it('kernel selector options are properly generated from composite kernel and notebook metadata', () => {
        const kernel = new polyglot_notebooks_1.CompositeKernel('composite');
        // add C# kernel that supports `SubmitCode`
        const cs = new polyglot_notebooks_1.Kernel('csharp', 'csharp', '10.0', 'See Sharp');
        cs.kernelInfo.description = 'Do C# stuff';
        cs.kernelInfo.supportedKernelCommands = [{ name: commandsAndEvents.SubmitCodeType }];
        kernel.add(cs);
        // add webview kernel that _doesn't_ support `SubmitCode`
        const wv = new polyglot_notebooks_1.Kernel('webview');
        kernel.add(wv);
        const notebookDocument = {
            uri: {
                fsPath: 'some-notebook',
                scheme: 'file'
            },
            metadata: {
                polyglot_notebook: {
                    kernelInfo: {
                        defaultKernelName: 'unused',
                        items: [
                            {
                                name: 'csharp',
                                aliases: []
                            },
                            {
                                name: 'fsharp',
                                aliases: []
                            }
                        ]
                    }
                }
            }
        };
        const kernelSelectorOptions = kernelSelectorUtilities.getKernelSelectorOptions(kernel, notebookDocument, commandsAndEvents.SubmitCodeType);
        (0, chai_1.expect)(kernelSelectorOptions).to.deep.equal([
            {
                kernelName: 'csharp',
                displayValue: 'See Sharp',
                languageName: 'csharp',
                description: 'Do C# stuff'
            },
            {
                kernelName: 'fsharp',
                displayValue: 'fsharp',
                description: undefined
            }
        ]);
    });
}));
//# sourceMappingURL=kernelSelectorUtilities.test.js.map