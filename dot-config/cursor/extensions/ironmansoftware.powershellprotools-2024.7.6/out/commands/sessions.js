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
exports.SessionCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class SessionCommands {
    register(context) {
        context.subscriptions.push(this.EnterSession());
        context.subscriptions.push(this.RemoveSession());
        context.subscriptions.push(this.ExitSession());
        context.subscriptions.push(this.PinSession());
        context.subscriptions.push(this.UnpinSession());
        this._pinnedTextEditors = new Map();
    }
    EnterSession() {
        return vscode.commands.registerCommand('poshProTools.enterSession', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            this._runspacePushed = true;
            container_1.Container.PowerShellService.EnterSession(node.session.Id);
        }));
    }
    RemoveSession() {
        return vscode.commands.registerCommand('poshProTools.removeSession', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            container_1.Container.PowerShellService.RemoveSession(node.session.Id);
            yield vscode.commands.executeCommand('sessionsView.refresh');
        }));
    }
    ExitSession() {
        return vscode.commands.registerCommand('poshProTools.exitSession', () => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            this._runspacePushed = false;
            container_1.Container.PowerShellService.ExitSession();
        }));
    }
    UnpinSession() {
        return vscode.commands.registerCommand('poshProTools.unpinSession', () => __awaiter(this, void 0, void 0, function* () {
            this._pinnedTextEditors.delete(vscode.window.activeTextEditor.document.uri);
            this._statusBarItem.hide();
        }));
    }
    PinSession() {
        this._statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 1);
        return vscode.commands.registerCommand('poshProTools.pinSession', () => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            const sessions = yield container_1.Container.PowerShellService.GetSessions();
            if (sessions.length === 0 || (sessions.length === 1 && sessions[0] == null)) {
                vscode.window.showWarningMessage("No sessions to pin.");
                return;
            }
            const result = yield vscode.window.showQuickPick(sessions.map(x => x.Name));
            const session = sessions.find(x => x.Name === result);
            this._pinnedTextEditors.set(vscode.window.activeTextEditor.document.uri, session);
            if (this._runspacePushed) {
                this._runspacePushed = false;
                yield container_1.Container.PowerShellService.ExitSession();
            }
            this._runspacePushed = true;
            yield container_1.Container.PowerShellService.EnterSession(session.Id);
            this._statusBarItem.text = `$(pinned) Document pinned to ${session.Name}`;
            this._statusBarItem.show();
            vscode.window.onDidChangeActiveTextEditor((editor) => __awaiter(this, void 0, void 0, function* () {
                if (this._runspacePushed) {
                    this._runspacePushed = false;
                    yield container_1.Container.PowerShellService.ExitSession();
                    this._statusBarItem.hide();
                }
                if (this._pinnedTextEditors.has(editor.document.uri)) {
                    const session = this._pinnedTextEditors.get(editor.document.uri);
                    yield container_1.Container.PowerShellService.EnterSession(session.Id);
                    this._statusBarItem.text = `$(pinned) Document pinned to ${session.Name}`;
                    this._statusBarItem.show();
                    this._runspacePushed = true;
                }
            }));
        }));
    }
}
exports.SessionCommands = SessionCommands;
//# sourceMappingURL=sessions.js.map