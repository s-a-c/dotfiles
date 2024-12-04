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
exports.signOnSave = exports.PowerShellLanguageId = void 0;
const vscode = require("vscode");
const container_1 = require("./../container");
exports.PowerShellLanguageId = "poshProTools";
function signOnSave() {
    vscode.workspace.onDidSaveTextDocument((x) => __awaiter(this, void 0, void 0, function* () {
        var settings = container_1.Container.GetSettings();
        if (!settings.signOnSave || !x.fileName.toLocaleLowerCase().endsWith('.ps1'))
            return;
        var selectedCert = settings.signOnSaveCertificate;
        if (selectedCert === '') {
            var certs = yield container_1.Container.PowerShellService.GetCodeSigningCerts();
            var certStrings = certs.map((x, i) => `${i} - ${x.Subject} | ${x.Expiration} | ${x.Thumbprint}`);
            var result = yield vscode.window.showQuickPick(certStrings);
            if (result) {
                var certIndex = Number.parseInt(result.split('-')[0].trimEnd());
                selectedCert = certs[certIndex].Path;
                const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
                yield configuration.update('signOnSaveCertificate', selectedCert);
            }
        }
        yield container_1.Container.PowerShellService.SignScript(x.fileName, selectedCert);
    }));
}
exports.signOnSave = signOnSave;
//# sourceMappingURL=signOnSave.js.map