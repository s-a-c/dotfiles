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
exports.RapidSenseCommand = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const settings_1 = require("./../settings");
class RapidSenseCommand {
    constructor() {
        this.rapidSenseEnabled = false;
        this.enabling = false;
    }
    register(context) {
        context.subscriptions.push(this.toggleRapidSense());
        this.statusBarItem =
            vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 1);
        this.statusBarItem.command = "poshProTools.toggleRapidSense";
        this.statusBarItem.text = "IntelliSense";
        this.statusBarItem.show();
        const provider1 = vscode.languages.registerCompletionItemProvider('powershell', this, "$", ".", "-", "[", "\\");
        context.subscriptions.push(provider1);
        vscode.workspace.onDidChangeConfiguration((e) => __awaiter(this, void 0, void 0, function* () {
            if (e.affectsConfiguration(settings_1.PowerShellLanguageId) && this.rapidSenseEnabled && !this.enabling) {
                this.enabling = true;
                yield container_1.Container.PowerShellService.EnablePsesIntelliSense();
                this.enableRapidSense("Settings changed. Refreshing RapidSense caches...");
            }
        }));
    }
    provideCompletionItems(document, position, token, context) {
        return __awaiter(this, void 0, void 0, function* () {
            if (this.rapidSenseEnabled) {
                const line = document.lineAt(position.line).text;
                const items = yield container_1.Container.PowerShellService.Complete(context.triggerCharacter, line, position.character);
                return items.map(item => new vscode.CompletionItem(item.InsertText, item.CompletionKind));
            }
            return [];
        });
    }
    enableRapidSense(msg) {
        const settings = (0, settings_1.load)();
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: msg
        }, () => __awaiter(this, void 0, void 0, function* () {
            yield container_1.Container.PowerShellService.DisablePsesIntelliSense({
                ignoredAssemblies: settings.ignoredAssemblies,
                ignoredCommands: settings.ignoredCommands,
                ignoredModules: settings.ignoredModules,
                ignoredTypes: settings.ignoredTypes,
                ignoredVariables: settings.ignoredVariables,
                ignoredPaths: settings.ignoredPaths
            });
            this.rapidSenseEnabled = true;
            this.statusBarItem.text = "$(rocket) RapidSense";
            this.enabling = false;
        }));
    }
    toggleRapidSense() {
        vscode.debug.onDidTerminateDebugSession(() => __awaiter(this, void 0, void 0, function* () {
            if (this.rapidSenseEnabled) {
                vscode.window.withProgress({
                    location: vscode.ProgressLocation.Notification,
                    title: "Refreshing RapidSense cache..."
                }, () => __awaiter(this, void 0, void 0, function* () {
                    yield container_1.Container.PowerShellService.RefreshCompletionCache();
                }));
            }
        }));
        return vscode.commands.registerCommand('poshProTools.toggleRapidSense', () => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            if (this.rapidSenseEnabled) {
                this.rapidSenseEnabled = false;
                this.statusBarItem.text = "IntelliSense";
                this.statusBarItem.color = null;
                yield container_1.Container.PowerShellService.EnablePsesIntelliSense();
            }
            else {
                this.enableRapidSense("Enabling RapidSense...");
            }
        }));
    }
}
exports.RapidSenseCommand = RapidSenseCommand;
//# sourceMappingURL=rapidsense.js.map