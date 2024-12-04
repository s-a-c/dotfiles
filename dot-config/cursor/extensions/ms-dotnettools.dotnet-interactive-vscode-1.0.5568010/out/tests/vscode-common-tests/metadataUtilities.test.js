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
const metadataUtilities = require("../../src/vscode-common/metadataUtilities");
const vscodeLike = require("../../src/vscode-common/interfaces/vscode-like");
const chai_1 = require("chai");
const polyglot_notebooks_1 = require("../../src/vscode-common/polyglot-notebooks");
describe(`metadata utility tests`, () => __awaiter(void 0, void 0, void 0, function* () {
    it("ipynb notebooks can be identified", () => {
        const notebookDocument = {
            uri: {
                fsPath: "notebook.ipynb",
                scheme: "untitled",
            },
            metadata: {},
        };
        const isIpynb = metadataUtilities.isIpynbNotebook(notebookDocument);
        (0, chai_1.expect)(isIpynb).to.be.true;
    });
    it("interactive notebook can be identified from .dib", () => {
        const notebookDocument = {
            uri: {
                fsPath: "notebook.dib",
                scheme: "untitled",
            },
            metadata: {},
        };
        const isDotNet = metadataUtilities.isDotNetNotebook(notebookDocument);
        (0, chai_1.expect)(isDotNet).to.be.true;
    });
    it("interactive notebook can be identified from metadata in .ipynb", () => {
        let notebookDocument = {
            uri: {
                fsPath: "notebook.ipynb",
                scheme: "untitled",
            },
            metadata: {
                metadata: {
                    kernelspec: {
                        name: ".net-csharp",
                    },
                },
            },
        };
        const isDotNet = metadataUtilities.isDotNetNotebook(notebookDocument);
        (0, chai_1.expect)(isDotNet).to.be.true;
    });
    it("non-interactive notebook is not identified from metadata in .ipynb", () => {
        const notebookDocument = {
            uri: {
                fsPath: "notebook.ipynb",
                scheme: "untitled",
            },
            metadata: {
                custom: {
                    metadata: {
                        kernelspec: {
                            name: "python",
                        },
                    },
                },
            },
        };
        const isDotNet = metadataUtilities.isDotNetNotebook(notebookDocument);
        (0, chai_1.expect)(isDotNet).to.be.false;
    });
    it("cell metadata can be extracted from an interactive document element with old metadata", () => {
        const interactiveDocumentElement = {
            contents: "",
            outputs: [],
            executionOrder: 0,
            metadata: {
                dotnet_interactive: {
                    language: "fsharp",
                },
            },
        };
        const notebookCellMetadata = metadataUtilities.getNotebookCellMetadataFromInteractiveDocumentElement(interactiveDocumentElement);
        (0, chai_1.expect)(notebookCellMetadata).to.deep.equal({
            kernelName: "fsharp",
        });
    });
    it("cell metadata can be extracted from an interactive document element", () => {
        const interactiveDocumentElement = {
            contents: "",
            outputs: [],
            executionOrder: 0,
            metadata: {
                polyglot_notebook: {
                    kernelName: "fsharp",
                },
            },
        };
        const notebookCellMetadata = metadataUtilities.getNotebookCellMetadataFromInteractiveDocumentElement(interactiveDocumentElement);
        (0, chai_1.expect)(notebookCellMetadata).to.deep.equal({
            kernelName: "fsharp",
        });
    });
    it("cell metadata can be extracted from a notebook cell with old metadata", () => {
        const notebookCell = {
            kind: vscodeLike.NotebookCellKind.Code,
            metadata: {
                metadata: {
                    dotnet_interactive: {
                        language: "fsharp",
                    },
                },
            },
        };
        const notebookCellMetadata = metadataUtilities.getNotebookCellMetadataFromNotebookCellElement(notebookCell);
        (0, chai_1.expect)(notebookCellMetadata).to.deep.equal({
            kernelName: "fsharp",
        });
    });
    it("cell metadata can be extracted from a notebook cell", () => {
        const notebookCell = {
            kind: vscodeLike.NotebookCellKind.Code,
            metadata: {
                metadata: {
                    polyglot_notebook: {
                        kernelName: "fsharp",
                    },
                },
            },
        };
        const notebookCellMetadata = metadataUtilities.getNotebookCellMetadataFromNotebookCellElement(notebookCell);
        (0, chai_1.expect)(notebookCellMetadata).to.deep.equal({
            kernelName: "fsharp",
        });
    });
    it("cell metadata can be extracted from a notebook cell", () => { });
    it("notebook metadata can be extracted from an interactive document", () => {
        const interactiveDocument = {
            elements: [],
            metadata: {
                custom: {
                    name: "some value",
                },
                kernelInfo: {
                    defaultKernelName: "fsharp",
                    items: [
                        {
                            name: "fsharp",
                            aliases: ["fs"],
                            languageName: "fsharp",
                        },
                    ],
                },
            },
        };
        const notebookDocumentMetadata = metadataUtilities.getNotebookDocumentMetadataFromInteractiveDocument(interactiveDocument);
        (0, chai_1.expect)(notebookDocumentMetadata).to.deep.equal({
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        });
    });
    it("notebook metadata can be extracted from vscode notebook document", () => {
        const notebookDocument = {
            uri: {
                fsPath: "some-notebook.ipynb",
                scheme: "file",
            },
            metadata: {
                custom: {
                    name: "some value",
                },
                polyglot_notebook: {
                    kernelInfo: {
                        defaultKernelName: "fsharp",
                        items: [
                            {
                                name: "fsharp",
                                aliases: ["fs"],
                                languageName: "fsharp",
                            },
                        ],
                    },
                },
            },
        };
        const notebookDocumentMetadata = metadataUtilities.getNotebookDocumentMetadataFromNotebookDocument(notebookDocument);
        (0, chai_1.expect)(notebookDocumentMetadata).to.deep.equal({
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        });
    });
    it("notebook document metadata can be synthesized from .ipynb kernelspec", () => {
        const notebookDocument = {
            uri: {
                fsPath: "test-notebook.ipynb",
                scheme: "unused",
            },
            metadata: {
                metadata: {
                    kernelspec: {
                        display_name: ".NET (F#)",
                        language: "F#",
                        name: ".net-fsharp",
                    },
                },
            },
        };
        const notebookDocumentMetadata = metadataUtilities.getNotebookDocumentMetadataFromNotebookDocument(notebookDocument);
        (0, chai_1.expect)(notebookDocumentMetadata).to.deep.equal({
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "fsharp",
                        aliases: [],
                    },
                ],
            },
        });
    });
    it("kernel infos can be created from .dib notebook document", () => {
        const notebookDocument = {
            uri: {
                fsPath: "notebook.dib",
                scheme: "file",
            },
            metadata: {
                polyglot_notebook: {
                    kernelInfo: {
                        defaultKernelName: "fsharp",
                        items: [
                            {
                                name: "fsharp",
                                aliases: [],
                            },
                            {
                                name: "snake",
                                languageName: "python",
                                aliases: [],
                            },
                        ],
                    },
                },
            },
        };
        const kernelInfos = metadataUtilities.getKernelInfosFromNotebookDocument(notebookDocument);
        (0, chai_1.expect)(kernelInfos).to.deep.equal([
            {
                aliases: [],
                displayName: "unused",
                isComposite: false,
                isProxy: false,
                localName: "fsharp",
                supportedDirectives: [],
                supportedKernelCommands: [],
                uri: "unused",
            },
            {
                aliases: [],
                displayName: "unused",
                isComposite: false,
                isProxy: false,
                languageName: "python",
                localName: "snake",
                supportedDirectives: [],
                supportedKernelCommands: [],
                uri: "unused",
            },
        ]);
    });
    it("kernel infos can be created from .ipynb notebook document", () => {
        const notebookDocument = {
            uri: {
                fsPath: "notebook.ipynb",
                scheme: "file",
            },
            metadata: {
                metadata: {
                    polyglot_notebook: {
                        kernelInfo: {
                            defaultKernelName: "fsharp",
                            items: [
                                {
                                    name: "fsharp",
                                    aliases: [],
                                },
                                {
                                    name: "snake",
                                    languageName: "python",
                                    aliases: [],
                                },
                            ],
                        },
                    },
                },
            },
        };
        const kernelInfos = metadataUtilities.getKernelInfosFromNotebookDocument(notebookDocument);
        (0, chai_1.expect)(kernelInfos).to.deep.equal([
            {
                aliases: [],
                displayName: "unused",
                isComposite: false,
                isProxy: false,
                localName: "fsharp",
                supportedDirectives: [],
                supportedKernelCommands: [],
                uri: "unused",
            },
            {
                aliases: [],
                displayName: "unused",
                isComposite: false,
                isProxy: false,
                languageName: "python",
                localName: "snake",
                supportedDirectives: [],
                supportedKernelCommands: [],
                uri: "unused",
            },
        ]);
    });
    it("kernelspec metadata can be created from notebook document metadata (C#)", () => {
        const notebookDocumentMetadata = {
            kernelInfo: {
                defaultKernelName: "csharp",
                items: [],
            },
        };
        const kernelspecMetadata = metadataUtilities.getKernelspecMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata);
        (0, chai_1.expect)(kernelspecMetadata).to.deep.equal({
            display_name: ".NET (C#)",
            language: "C#",
            name: ".net-csharp",
        });
    });
    it("kernelspec metadata can be created from notebook document metadata (F#)", () => {
        const notebookDocumentMetadata = {
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [],
            },
        };
        const kernelspecMetadata = metadataUtilities.getKernelspecMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata);
        (0, chai_1.expect)(kernelspecMetadata).to.deep.equal({
            display_name: ".NET (F#)",
            language: "F#",
            name: ".net-fsharp",
        });
    });
    it("kernelspec metadata can be created from notebook document metadata (PowerShell)", () => {
        const notebookDocumentMetadata = {
            kernelInfo: {
                defaultKernelName: "pwsh",
                items: [],
            },
        };
        const kernelspecMetadata = metadataUtilities.getKernelspecMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata);
        (0, chai_1.expect)(kernelspecMetadata).to.deep.equal({
            display_name: ".NET (PowerShell)",
            language: "PowerShell",
            name: ".net-pwsh",
        });
    });
    it("new ipynb metadata can be created from existing data", () => {
        const notebookMetadata = {
            kernelInfo: {
                defaultKernelName: "csharp",
                items: [
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                ],
            },
        };
        const existingMetadata = {
            metadata: {
                kernelspec: "this gets replaced",
                someKey: "some value",
            },
            metadata2: "electric boogaloo",
            notCustom: "not custom",
        };
        const newRawMetadata = metadataUtilities.createNewIpynbMetadataWithNotebookDocumentMetadata(existingMetadata, notebookMetadata);
        (0, chai_1.expect)(newRawMetadata).to.deep.equal({
            metadata: {
                kernelspec: {
                    display_name: ".NET (C#)",
                    language: "C#",
                    name: ".net-csharp",
                },
                polyglot_notebook: {
                    kernelInfo: {
                        defaultKernelName: "csharp",
                        items: [
                            {
                                aliases: ["cs"],
                                languageName: "csharp",
                                name: "csharp",
                            },
                        ],
                    },
                },
                someKey: "some value",
            },
            metadata2: "electric boogaloo",
            notCustom: "not custom",
        });
    });
    it("notebook metadata can be extracted from a composite kernel", () => {
        const kernel = new polyglot_notebooks_1.CompositeKernel("composite");
        const cs = new polyglot_notebooks_1.Kernel("csharp", "csharp");
        cs.registerCommandHandler({
            commandType: commandsAndEvents.SubmitCodeType,
            handle: (_invocation) => Promise.resolve(),
        });
        cs.kernelInfo.aliases.push("cs");
        kernel.add(cs);
        const fs = new polyglot_notebooks_1.Kernel("fsharp", "fsharp");
        fs.registerCommandHandler({
            commandType: commandsAndEvents.SubmitCodeType,
            handle: (_invocation) => Promise.resolve(),
        });
        fs.kernelInfo.aliases.push("fs");
        kernel.add(fs);
        const value = new polyglot_notebooks_1.Kernel("value", "value");
        kernel.defaultKernelName = fs.name;
        const notebookDocumentMetadata = metadataUtilities.getNotebookDocumentMetadataFromCompositeKernel(kernel);
        (0, chai_1.expect)(notebookDocumentMetadata).to.deep.equal({
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        });
    });
    it("interactive document cell metadata can be created from notebook cell metadata", () => {
        const notebookCellMetadata = {
            kernelName: "fsharp",
        };
        const interactiveDocumentElementMetadata = metadataUtilities.getRawInteractiveDocumentElementMetadataFromNotebookCellMetadata(notebookCellMetadata);
        (0, chai_1.expect)(interactiveDocumentElementMetadata).to.deep.equal({
            kernelName: "fsharp",
        });
    });
    it("notebook cell metadata can be created from notebook cell metadata", () => {
        const notebookCellMetadata = {
            kernelName: "fsharp",
        };
        const rawNotebookDocumentElementMetadata = metadataUtilities.getRawNotebookCellMetadataFromNotebookCellMetadata(notebookCellMetadata);
        (0, chai_1.expect)(rawNotebookDocumentElementMetadata).to.deep.equal({
            metadata: {
                dotnet_interactive: {
                    language: "fsharp",
                },
                polyglot_notebook: {
                    kernelName: "fsharp",
                },
            },
        });
    });
    it("interactive document metadata can be created from notebook metadata", () => {
        const notebookDocumentMetadata = {
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                ],
            },
        };
        const interactiveDocumentMetadata = metadataUtilities.getRawInteractiveDocumentMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata);
        (0, chai_1.expect)(interactiveDocumentMetadata).to.deep.equal({
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    { aliases: ["fs"], languageName: "fsharp", name: "fsharp" },
                    { aliases: ["cs"], languageName: "csharp", name: "csharp" },
                ],
            },
        });
    });
    it("notebook document metadata can be created from notebook metadata for ipynb", () => {
        const notebookDocumentMetadata = {
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        };
        const rawNotebookDocumentMetadata = metadataUtilities.getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata, {}, true);
        (0, chai_1.expect)(rawNotebookDocumentMetadata).to.deep.equal({
            metadata: {
                kernelspec: {
                    display_name: ".NET (F#)",
                    language: "F#",
                    name: ".net-fsharp",
                },
                polyglot_notebook: {
                    kernelInfo: {
                        defaultKernelName: "fsharp",
                        items: [
                            {
                                aliases: ["cs"],
                                languageName: "csharp",
                                name: "csharp",
                            },
                            {
                                aliases: ["fs"],
                                languageName: "fsharp",
                                name: "fsharp",
                            },
                        ],
                    },
                },
            },
        });
    });
    it("notebook document metadata can be created from notebook metadata for dib", () => {
        const notebookDocumentMetadata = {
            kernelInfo: {
                defaultKernelName: "fsharp",
                items: [
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        };
        const rawNotebookDocumentMetadata = metadataUtilities.getMergedRawNotebookDocumentMetadataFromNotebookDocumentMetadata(notebookDocumentMetadata, {}, false);
        (0, chai_1.expect)(rawNotebookDocumentMetadata).to.deep.equal({
            polyglot_notebook: {
                kernelInfo: {
                    defaultKernelName: "fsharp",
                    items: [
                        {
                            name: "csharp",
                            aliases: ["cs"],
                            languageName: "csharp",
                        },
                        {
                            name: "fsharp",
                            aliases: ["fs"],
                            languageName: "fsharp",
                        },
                    ],
                },
            },
        });
    });
    it("notebook cell metadata can be merged", () => {
        const baseMetadata = {
            kernelName: "csharp",
        };
        const metadataWithNewValues = {
            kernelName: "fsharp",
        };
        const resultMetadata = metadataUtilities.mergeNotebookCellMetadata(baseMetadata, metadataWithNewValues);
        (0, chai_1.expect)(resultMetadata).to.deep.equal({
            kernelName: "fsharp",
        });
    });
    it("notebook metadata can be merged", () => {
        const baseMetadata = {
            kernelInfo: {
                defaultKernelName: "base default kernel name",
                items: [
                    {
                        name: "csharp",
                        aliases: [],
                    },
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        };
        const metadataWithNewValues = {
            kernelInfo: {
                defaultKernelName: "original default kernel name will be retained",
                items: [
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                ],
            },
        };
        const resultMetadata = metadataUtilities.mergeNotebookDocumentMetadata(baseMetadata, metadataWithNewValues);
        (0, chai_1.expect)(resultMetadata).to.deep.equal({
            kernelInfo: {
                defaultKernelName: "base default kernel name",
                items: [
                    {
                        name: "csharp",
                        aliases: ["cs"],
                        languageName: "csharp",
                    },
                    {
                        name: "fsharp",
                        aliases: ["fs"],
                        languageName: "fsharp",
                    },
                ],
            },
        });
    });
    it("merges metadata correctly", () => {
        let destination = {
            custom: {
                metadata: {
                    kernelspec: {
                        display_name: ".NET (C#)",
                        language: "C#",
                        name: ".net-csharp",
                    },
                    polyglot_notebook: {
                        kernelInfo: {
                            defaultKernelName: "powershell",
                            items: [
                                {
                                    aliases: [],
                                    languageName: null,
                                    name: ".NET",
                                },
                                {
                                    aliases: ["C#", "c#"],
                                    languageName: "C#",
                                    name: "csharp",
                                },
                                {
                                    aliases: ["F#", "f#"],
                                    languageName: "F#",
                                    name: "fsharp",
                                },
                                {
                                    aliases: [],
                                    languageName: "HTML",
                                    name: "html",
                                },
                                {
                                    aliases: ["js"],
                                    languageName: "JavaScript",
                                    name: "javascript",
                                },
                                {
                                    aliases: [],
                                    languageName: "Mermaid",
                                    name: "mermaid",
                                },
                                {
                                    aliases: [],
                                    name: "powershell",
                                },
                                {
                                    aliases: ["powershell"],
                                    languageName: "PowerShell",
                                    name: "pwsh",
                                },
                                {
                                    aliases: [],
                                    languageName: null,
                                    name: "value",
                                },
                                {
                                    aliases: ["frontend"],
                                    languageName: null,
                                    name: "vscode",
                                },
                                {
                                    aliases: [],
                                    name: "webview",
                                },
                            ],
                        },
                    },
                },
            },
        };
        let source = {
            custom: {
                metadata: {
                    kernelspec: {
                        display_name: ".NET (C#)",
                        language: "C#",
                        name: ".net-csharp",
                    },
                    polyglot_notebook: {
                        kernelInfo: {
                            defaultKernelName: "powershell",
                            items: [
                                {
                                    aliases: ["C#", "c#"],
                                    languageName: "C#",
                                    name: "csharp",
                                },
                                {
                                    aliases: ["F#", "f#"],
                                    languageName: "F#",
                                    name: "fsharp",
                                },
                                {
                                    aliases: [],
                                    languageName: "HTML",
                                    name: "html",
                                },
                                {
                                    aliases: ["js"],
                                    languageName: "JavaScript",
                                    name: "javascript",
                                },
                                {
                                    aliases: [],
                                    languageName: "Mermaid",
                                    name: "mermaid",
                                },
                                {
                                    aliases: [],
                                    name: "powershell",
                                },
                                {
                                    aliases: ["powershell"],
                                    languageName: "PowerShell",
                                    name: "pwsh",
                                },
                                {
                                    aliases: [],
                                    languageName: null,
                                    name: "value",
                                },
                                {
                                    aliases: ["frontend"],
                                    languageName: null,
                                    name: "vscode",
                                },
                                {
                                    aliases: [],
                                    name: "webview",
                                },
                            ],
                        },
                    },
                },
                cells: [],
                nbformat: 4,
                nbformat_minor: 2,
            },
            indentAmount: " ",
        };
        metadataUtilities.sortAndMerge(destination, source);
        (0, chai_1.expect)(destination).to.deep.equal({
            custom: {
                cells: [],
                metadata: {
                    kernelspec: {
                        display_name: ".NET (C#)",
                        language: "C#",
                        name: ".net-csharp",
                    },
                    polyglot_notebook: {
                        kernelInfo: {
                            defaultKernelName: "powershell",
                            items: [
                                {
                                    aliases: [],
                                    languageName: null,
                                    name: ".NET",
                                },
                                {
                                    aliases: ["C#", "c#"],
                                    languageName: "C#",
                                    name: "csharp",
                                },
                                {
                                    aliases: ["F#", "f#"],
                                    languageName: "F#",
                                    name: "fsharp",
                                },
                                {
                                    aliases: [],
                                    languageName: "HTML",
                                    name: "html",
                                },
                                {
                                    aliases: ["js"],
                                    languageName: "JavaScript",
                                    name: "javascript",
                                },
                                {
                                    aliases: [],
                                    languageName: "Mermaid",
                                    name: "mermaid",
                                },
                                { aliases: [], name: "powershell" },
                                {
                                    aliases: ["powershell"],
                                    languageName: "PowerShell",
                                    name: "pwsh",
                                },
                                {
                                    aliases: [],
                                    languageName: null,
                                    name: "value",
                                },
                                {
                                    aliases: ["frontend"],
                                    languageName: null,
                                    name: "vscode",
                                },
                                { aliases: [], name: "webview" },
                            ],
                        },
                    },
                },
                nbformat: 4,
                nbformat_minor: 2,
            },
            indentAmount: " ",
        });
    });
    it("raw metadata can be merged", () => {
        const baseMetadata = {
            custom: {
                name: "some value",
            },
            polyglot_notebook: {
                this_will: "be replaced",
            },
        };
        const metadataWithNewValues = {
            polyglot_notebook: {
                kernelInfo: {
                    defaultKernelName: "fsharp",
                    items: [
                        {
                            name: "fsharp",
                            aliases: ["fs"],
                            languageName: "fsharp",
                        },
                    ],
                },
            },
        };
        const resultMetadata = metadataUtilities.mergeRawMetadata(baseMetadata, metadataWithNewValues);
        (0, chai_1.expect)(resultMetadata).to.deep.equal({
            custom: {
                name: "some value",
            },
            polyglot_notebook: {
                kernelInfo: {
                    defaultKernelName: "fsharp",
                    items: [
                        {
                            name: "fsharp",
                            aliases: ["fs"],
                            languageName: "fsharp",
                        },
                    ],
                },
            },
        });
    });
}));
//# sourceMappingURL=metadataUtilities.test.js.map