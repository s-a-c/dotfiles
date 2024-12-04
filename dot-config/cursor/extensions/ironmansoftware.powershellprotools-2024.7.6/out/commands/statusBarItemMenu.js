'use strict';
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
exports.statusBarItemMenu = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const powershellservice_1 = require("../services/powershellservice");
function statusBarItemMenu() {
    return vscode.commands.registerCommand('poshProTools.statusBarMenu', () => __awaiter(this, void 0, void 0, function* () {
        if (!container_1.Container.IsInitialized())
            return;
        if (container_1.Container.PowerShellService.status === powershellservice_1.SessionStatus.Failed) {
            var retry = yield vscode.window.showErrorMessage("PowerShell Pro Tools session failed to start. Please check the PowerShell Pro Tools extension output for more information.", "Retry");
            if (retry === "Retry") {
                container_1.Container.PowerShellService.Reconnect(() => { });
            }
            return;
        }
        if (container_1.Container.PowerShellService.status === powershellservice_1.SessionStatus.Initializing) {
            return;
        }
        let options = ["About PowerShell Pro Tools", "Documentation", "Forums", "Report an Issue"];
        const result = yield vscode.window.showQuickPick(options);
        if (result === "About PowerShell Pro Tools") {
            vscode.env.openExternal(vscode.Uri.parse("https://docs.poshtools.com"));
        }
        else if (result === "Install License") {
            vscode.commands.executeCommand("poshProTools.openLicenseFile");
        }
        else if (result === "Documentation") {
            vscode.env.openExternal(vscode.Uri.parse("https://docs.poshtools.com"));
        }
        else if (result === "Forums") {
            vscode.env.openExternal(vscode.Uri.parse("https://forums.ironmansoftware.com"));
        }
        else if (result === "Report an Issue") {
            vscode.env.openExternal(vscode.Uri.parse("https://github.com/ironmansoftware/powershell-pro-tools/issues"));
        }
    }));
}
exports.statusBarItemMenu = statusBarItemMenu;
//# sourceMappingURL=statusBarItemMenu.js.map