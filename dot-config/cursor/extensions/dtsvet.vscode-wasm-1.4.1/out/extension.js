"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
const webassembly_content_provider_1 = __importDefault(require("./webassembly-content-provider"));
const utils_1 = require("./utils");
let client;
var BindingLanguage;
(function (BindingLanguage) {
    BindingLanguage["Rust"] = "Rust";
    BindingLanguage["JavaScript"] = "JavaScript";
    BindingLanguage["Python"] = "Python";
    BindingLanguage["C"] = "C";
})(BindingLanguage || (BindingLanguage = {}));
var GenerationDirection;
(function (GenerationDirection) {
    GenerationDirection["Guest"] = "Guest";
    GenerationDirection["Host"] = "Host";
})(GenerationDirection || (GenerationDirection = {}));
var GenerationType;
(function (GenerationType) {
    GenerationType["Import"] = "Import";
    GenerationType["Export"] = "Export";
})(GenerationType || (GenerationType = {}));
function activateWAILsp(context) {
    return __awaiter(this, void 0, void 0, function* () {
        context.globalState.update("inWaiFile", true);
        const traceOutputChannel = vscode_1.window.createOutputChannel("WAI Language Server trace");
        const command = process.env.SERVER_PATH ||
            vscode_1.workspace.getConfiguration("wai-language-server").get("serverPath");
        const run = {
            command,
            options: {
                env: Object.assign(Object.assign({}, process.env), { 
                    // eslint-disable-next-line @typescript-eslint/naming-convention
                    RUST_LOG: "debug" }),
            },
        };
        const serverOptions = {
            run,
            debug: run,
        };
        let clientOptions = {
            documentSelector: [{ scheme: "file", language: "wai" }],
            traceOutputChannel,
        };
        client = new node_1.LanguageClient("wai-language-server", "WAI Language Server", serverOptions, clientOptions);
        client.onRequest("wai/saveFile", ({ fileName, fileContent }) => __awaiter(this, void 0, void 0, function* () {
            var _a;
            // get the current path of root folder
            const rootPath = (_a = vscode_1.workspace.workspaceFolders) === null || _a === void 0 ? void 0 : _a[0].uri.path;
            // get the current path of the file
            const filePath = vscode_1.Uri.file(fileName).path;
            // get the relative path of the file
            const relativePath = filePath.replace(rootPath, "");
            // get the absolute path of the file
            const absolutePath = vscode_1.Uri.file(fileName).fsPath;
            // create a new file with the same name and content
            (0, utils_1.writeFile)(vscode_1.Uri.file(rootPath + "/" + fileName), Buffer.from(fileContent))
                .then(() => {
                return true;
            })
                .catch((err) => {
                console.error(err);
                return false;
            });
        }));
        client.start();
    });
}
function activate(context) {
    // starting the language server for WAI
    // activateWAILsp(context);
    const provider = new webassembly_content_provider_1.default();
    const registration = vscode_1.workspace.registerTextDocumentContentProvider("wasm-preview", provider);
    const openEvent = vscode_1.workspace.onDidOpenTextDocument((document) => {
        showDocument(document);
    });
    const previewCommand = vscode_1.commands.registerCommand("wasm.wasm2wat", (uri) => {
        showPreview(uri);
    });
    const save2watCommand = vscode_1.commands.registerCommand("wasm.save2wat", (uri) => {
        const watPath = uri.path.replace(/\.wasm$/, ".wat");
        const saveDialogOptions = {
            filters: {
                "WebAssembly Text": ["wat", "wast"],
                "WebAssembly Binary": ["wasm"],
            },
            defaultUri: uri.with({ scheme: "file", path: watPath }),
        };
        const from = uri.with({ scheme: "file" });
        vscode_1.window
            .showSaveDialog(saveDialogOptions)
            .then(maybeSaveWat(from), vscode_1.window.showErrorMessage);
    });
    const save2wasmCommand = vscode_1.commands.registerCommand("wasm.save2wasm", (uri) => {
        const wasmPath = uri.path.replace(/\.wat$/, ".wasm");
        const saveDialogOptions = {
            filters: {
                "WebAssembly Binary": ["wasm"],
                "WebAssembly Text": ["wat", "wast"],
            },
            defaultUri: uri.with({ scheme: "file", path: wasmPath }),
        };
        const from = uri.with({ scheme: "file" });
        vscode_1.window
            .showSaveDialog(saveDialogOptions)
            .then(maybeSaveWasm(from), vscode_1.window.showErrorMessage);
    });
    const waiGenerateCommand = vscode_1.commands.registerCommand("wai.WAIGenerate", () => __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        const generationDirectionQuickPickItems = [
            {
                label: GenerationDirection.Guest,
                description: "Generate a guest file",
            },
            {
                label: GenerationDirection.Host,
                description: "Generate a host file",
            },
        ];
        const generationTypeQuickPickItems = [
            {
                label: GenerationType.Import,
                description: "Generate an import file",
            },
            {
                label: GenerationType.Export,
                description: "Generate an export file",
            },
        ];
        const hostLanguageQuickPickItems = [
            {
                label: BindingLanguage.Rust,
                description: "Generate a Rust file",
            },
            {
                label: BindingLanguage.JavaScript,
                description: "Generate a JavaScript file",
            },
            {
                label: BindingLanguage.Python,
                description: "Generate a Python file",
            },
        ];
        const guestLanguageQuickPickItems = [
            {
                label: BindingLanguage.Rust,
                description: "Generate a Rust file",
            },
            {
                label: BindingLanguage.C,
                description: "Generate a C file",
            },
        ];
        const generationDirectionOptions = {
            placeHolder: "Select a generation type",
        };
        const languageOptions = {
            placeHolder: "Select a language for the generated bindings",
        };
        const generationTypeOptions = {
            placeHolder: "Select a generation type",
        };
        const generationDirectionSelection = yield vscode_1.window.showQuickPick(generationDirectionQuickPickItems, generationDirectionOptions);
        if (!generationDirectionSelection) {
            return;
        }
        let languageSelection = null;
        if (generationDirectionSelection.label === GenerationDirection.Guest) {
            languageSelection = yield vscode_1.window.showQuickPick(guestLanguageQuickPickItems, languageOptions);
        }
        else {
            languageSelection = yield vscode_1.window.showQuickPick(hostLanguageQuickPickItems, languageOptions);
        }
        if (!languageSelection) {
            return;
        }
        const generationTypeSelection = yield vscode_1.window.showQuickPick(generationTypeQuickPickItems, generationTypeOptions);
        if (!generationTypeSelection) {
            return;
        }
        yield client
            .sendRequest("wai/generate-code", {
            generation_direction: generationDirectionSelection.label,
            binding_language: languageSelection.label,
            generation_type: generationTypeSelection.label,
            file_name: (_a = vscode_1.window.activeTextEditor) === null || _a === void 0 ? void 0 : _a.document.fileName,
            file_content: (_b = vscode_1.window.activeTextEditor) === null || _b === void 0 ? void 0 : _b.document.getText(),
        })
            .then((response) => {
            console.log(response);
        });
    }));
    if (vscode_1.window.activeTextEditor) {
        showDocument(vscode_1.window.activeTextEditor.document);
    }
    context.subscriptions.push(registration, openEvent, previewCommand, save2watCommand, save2wasmCommand, waiGenerateCommand);
}
exports.activate = activate;
function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
exports.deactivate = deactivate;
function showDocument(document) {
    if (document.languageId === "wasm" &&
        document.uri.scheme !== "wasm-preview") {
        vscode_1.commands.executeCommand("workbench.action.closeActiveEditor").then(() => {
            showPreview(document.uri);
        }, vscode_1.window.showErrorMessage);
    }
}
function showPreview(uri) {
    if (uri.scheme === "wasm-preview") {
        return;
    }
    vscode_1.commands
        .executeCommand("vscode.open", uri.with({ scheme: "wasm-preview" }))
        .then(null, vscode_1.window.showErrorMessage);
}
function maybeSaveWat(from) {
    return (to) => {
        if (!to) {
            return;
        }
        return saveWat(from, to);
    };
}
function saveWat(from, to) {
    return __awaiter(this, void 0, void 0, function* () {
        const wasmContent = yield (0, utils_1.readFile)(from);
        const watContent = yield (0, utils_1.wasm2wat)(wasmContent);
        yield (0, utils_1.writeFile)(to, watContent);
    });
}
function maybeSaveWasm(from) {
    return (to) => {
        if (!to) {
            return;
        }
        return saveWasm(from, to);
    };
}
function saveWasm(from, to) {
    return __awaiter(this, void 0, void 0, function* () {
        const watContent = yield (0, utils_1.readFile)(from);
        const wasmContent = yield (0, utils_1.wat2wasm)(watContent);
        yield (0, utils_1.writeFile)(to, wasmContent);
    });
}
//# sourceMappingURL=extension.js.map