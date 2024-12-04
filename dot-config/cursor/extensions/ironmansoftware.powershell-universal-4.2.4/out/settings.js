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
exports.SetCheckModules = exports.SetPort = exports.SetUrl = exports.SetSamplesDirectory = exports.SetServerPath = exports.SetAppToken = exports.load = exports.PowerShellLanguageId = void 0;
const vscode = require("vscode");
exports.PowerShellLanguageId = "powerShellUniversal";
function load() {
    const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
    return {
        appToken: configuration.get("appToken", ""),
        url: configuration.get("url", "http://localhost:5000"),
        samplesDirectory: configuration.get("samplesDirectory", ""),
        syncSamples: configuration.get("syncSamples", false),
        localEditing: configuration.get("localEditing", false),
        checkModules: configuration.get("checkModules", false),
        connections: configuration.get("connections", []),
    };
}
exports.load = load;
function SetAppToken(value) {
    return __awaiter(this, void 0, void 0, function* () {
        const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
        yield configuration.update("appToken", value, vscode.ConfigurationTarget.Global);
    });
}
exports.SetAppToken = SetAppToken;
function SetServerPath(value) {
    return __awaiter(this, void 0, void 0, function* () {
        const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
        yield configuration.update("serverPath", value, vscode.ConfigurationTarget.Global);
    });
}
exports.SetServerPath = SetServerPath;
function SetSamplesDirectory(value) {
    return __awaiter(this, void 0, void 0, function* () {
        const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
        yield configuration.update("samplesDirectory", value, vscode.ConfigurationTarget.Global);
    });
}
exports.SetSamplesDirectory = SetSamplesDirectory;
function SetUrl(value) {
    return __awaiter(this, void 0, void 0, function* () {
        const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
        yield configuration.update("url", value, vscode.ConfigurationTarget.Global);
    });
}
exports.SetUrl = SetUrl;
function SetPort(value) {
    return __awaiter(this, void 0, void 0, function* () {
        const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
        yield configuration.update("port", value, vscode.ConfigurationTarget.Global);
    });
}
exports.SetPort = SetPort;
function SetCheckModules(value) {
    return __awaiter(this, void 0, void 0, function* () {
        const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
        yield configuration.update("checkModules", value, vscode.ConfigurationTarget.Global);
    });
}
exports.SetCheckModules = SetCheckModules;
//# sourceMappingURL=settings.js.map