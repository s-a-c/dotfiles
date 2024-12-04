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
Object.defineProperty(exports, "__esModule", { value: true });
exports.SampleService = exports.registerSampleCommands = void 0;
const vscode = require("vscode");
const settings_1 = require("./settings");
const types_1 = require("./types");
const path = require('path');
const fs = require('fs');
const YAML = require('yaml');
const getSamplesPath = () => __awaiter(void 0, void 0, void 0, function* () {
    const settings = settings_1.load();
    const samplesPath = process.env.APPDATA + "";
    if (settings.samplesDirectory === "") {
        yield settings_1.SetSamplesDirectory(samplesPath);
        return samplesPath;
    }
    return settings.samplesDirectory;
});
exports.registerSampleCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.syncSamples', () => __awaiter(void 0, void 0, void 0, function* () {
        var sampleService = new SampleService();
        yield sampleService.synchronizeSamples();
    }));
    vscode.commands.registerCommand('powershell-universal.insertSample', insertSampleCommand);
    vscode.commands.registerCommand('powershell-universal.viewSampleOnGitHub', viewSampleOnGitHubCommand);
};
const insertSampleCommand = (sample) => __awaiter(void 0, void 0, void 0, function* () {
    for (let file of sample.sample.files) {
        let document = yield vscode.commands.executeCommand("powershell-universal.openConfigFile", file);
        if (document) {
            var we = new vscode.WorkspaceEdit();
            var content = file.content;
            if (document.lineCount != 0) {
                content = "\r\n" + content;
            }
            we.insert(document.uri, new vscode.Position(document.lineCount, 0), content);
            vscode.workspace.applyEdit(we);
        }
    }
});
const viewSampleOnGitHubCommand = (sample) => __awaiter(void 0, void 0, void 0, function* () {
    vscode.env.openExternal(vscode.Uri.parse(sample.sample.url));
});
class SampleService {
    synchronizeSamples() {
        return __awaiter(this, void 0, void 0, function* () {
            const settings = settings_1.load();
            if (!settings.syncSamples)
                return;
            const sampleRoot = yield getSamplesPath();
            const samplesPath = path.join(sampleRoot, "universal-samples");
            if (fs.existsSync(samplesPath)) {
                yield vscode.commands.executeCommand("git.openRepository", samplesPath);
                yield vscode.commands.executeCommand("git.pull", samplesPath);
                yield vscode.commands.executeCommand("git.close", samplesPath);
            }
            else {
                yield vscode.commands.executeCommand("git.clone", 'https://github.com/ironmansoftware/universal-samples.git', sampleRoot);
            }
        });
    }
    getRootSamples() {
        return __awaiter(this, void 0, void 0, function* () {
            const sampleRoot = yield getSamplesPath();
            const samplesPath = path.join(sampleRoot, "universal-samples");
            if (!fs.existsSync(samplesPath)) {
                return [];
            }
            return fs.readdirSync(samplesPath).filter((fileName) => {
                return (fileName !== "README.md" && fileName !== "LICENSE" && fileName !== ".git");
            }).map((fileName) => {
                return new types_1.SampleFolder(fileName, path.join(samplesPath, fileName));
            });
        });
    }
    getFolderChildren(folder) {
        return __awaiter(this, void 0, void 0, function* () {
            const sampleRoot = yield getSamplesPath();
            const samplesPath = path.join(sampleRoot, "universal-samples");
            return fs.readdirSync(folder.path).map((fileName) => {
                const itemPath = path.join(folder.path, fileName);
                if (fs.lstatSync(itemPath).isDirectory()) {
                    if (fs.readdirSync(itemPath).find((m) => m === "manifest.yml")) {
                        let manifest = fs.readFileSync(path.join(itemPath, "manifest.yml"), 'utf8');
                        const info = YAML.parse(manifest);
                        const files = fs.readdirSync(itemPath).filter((m) => m !== "manifest.yml").map((sampleFileName) => {
                            let script = fs.readFileSync(path.join(itemPath, sampleFileName), 'utf8');
                            return new types_1.SampleFile(sampleFileName, script);
                        });
                        const sampleBase = itemPath.replace(samplesPath, '').split('\\').join('/');
                        const url = `https://github.com/ironmansoftware/universal-samples/blob/main${sampleBase}`;
                        return new types_1.Sample(info.title, info.description, info.version, files, url);
                    }
                    else {
                        return new types_1.SampleFolder(fileName, itemPath);
                    }
                }
                else {
                    let script = fs.readFileSync(itemPath, 'utf8');
                    const startIndex = script.indexOf("<#") + 2;
                    const endIndex = script.indexOf("#>");
                    const manifest = script.substr(startIndex, endIndex - startIndex);
                    const info = YAML.parse(manifest);
                    script = script.substr(endIndex + 2);
                    var file = new types_1.SampleFile(info.file, script);
                    const sampleBase = itemPath.replace(samplesPath, '').split('\\').join('/');
                    const url = `https://github.com/ironmansoftware/universal-samples/blob/main${sampleBase}`;
                    return new types_1.Sample(info.title, info.description, info.version, [file], url);
                }
            });
        });
    }
}
exports.SampleService = SampleService;
//# sourceMappingURL=samples.js.map