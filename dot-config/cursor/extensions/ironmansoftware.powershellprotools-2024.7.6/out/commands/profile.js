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
exports.profile = exports.clearProfiling = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
var decorationTypes = [];
function clearProfiling() {
    return vscode.commands.registerCommand('powershell.clearProfiling', () => {
        decorationTypes.forEach(x => x.dispose());
        decorationTypes = [];
    });
}
exports.clearProfiling = clearProfiling;
function profile() {
    return vscode.commands.registerCommand('powershell.profileScript', () => __awaiter(this, void 0, void 0, function* () {
        if (!container_1.Container.IsInitialized())
            return;
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: "Executing PowerShell Profiler"
        }, () => __awaiter(this, void 0, void 0, function* () {
            decorationTypes.forEach(x => x.dispose());
            decorationTypes = [];
            const editor = vscode.window.activeTextEditor;
            var profileResult = yield container_1.Container.PowerShellService.MeasureScript(editor.document.fileName);
            var timingForFile = profileResult.Timings.filter(x => x.SequencePoint.FromAst && !x.SequencePoint.Root);
            timingForFile.forEach(element => {
                var percentTime = (element.DurationMilliseconds / profileResult.TotalDuration) * 100;
                var decorationType = vscode.window.createTextEditorDecorationType({
                    after: {
                        color: '#939393',
                        fontWeight: '100',
                        margin: '0 0 0 1em',
                        textDecoration: 'none',
                        contentText: `${percentTime.toFixed(2)}% (${element.CallCount} calls, ${element.DurationMilliseconds}ms)`
                    },
                    rangeBehavior: vscode.DecorationRangeBehavior.OpenOpen
                });
                var startPos = editor.document.positionAt(element.SequencePoint.StartOffset);
                var endPos = editor.document.positionAt(element.SequencePoint.EndOffset);
                editor.setDecorations(decorationType, [new vscode.Range(startPos, endPos)]);
                decorationTypes.push(decorationType);
            });
        }));
    }));
}
exports.profile = profile;
//# sourceMappingURL=profile.js.map