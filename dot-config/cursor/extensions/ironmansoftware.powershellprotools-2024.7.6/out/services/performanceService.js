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
exports.PerformanceService = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
class PerformanceService {
    constructor(context) {
        this.statusBarItem =
            vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 1);
        //this.statusBarItem.command = "poshProTools.statusBarMenu";
        this.statusBarItem.show();
        vscode.window.onDidChangeActiveTextEditor((textEditor) => {
            if (textEditor === undefined
                || textEditor.document.languageId !== "powershell") {
                this.statusBarItem.hide();
            }
            else {
                this.statusBarItem.show();
            }
        });
        var perfService = this;
        const interval = setInterval(() => __awaiter(this, void 0, void 0, function* () {
            const performance = yield container_1.Container.PowerShellService.GetPerformance();
            perfService.statusBarItem.text = `$(dashboard) MEM ${performance.Memory}, CPU ${performance.Cpu}`;
        }), 5000);
        this.statusBarItem.tooltip = "PowerShell Performance";
        context.subscriptions.push(this.statusBarItem);
        context.subscriptions.push({
            dispose: () => {
                clearInterval(interval);
            }
        });
    }
}
exports.PerformanceService = PerformanceService;
//# sourceMappingURL=performanceService.js.map