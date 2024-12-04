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
exports.AstCommands = void 0;
const vscode = require("vscode");
class AstCommands {
    register(context) {
        context.subscriptions.push(this.highlightAst());
        context.subscriptions.push(this.clearAstSelect());
    }
    selectRegion(startOffset, endOffset) {
        if (this.decoration) {
            this.decoration.dispose();
        }
        var editor = vscode.window.activeTextEditor;
        var decorationType = vscode.window.createTextEditorDecorationType({
            backgroundColor: new vscode.ThemeColor("editor.selectionBackground"),
            rangeBehavior: vscode.DecorationRangeBehavior.OpenOpen
        });
        var startPos = editor.document.positionAt(startOffset);
        var endPos = editor.document.positionAt(endOffset);
        editor.setDecorations(decorationType, [new vscode.Range(startPos, endPos)]);
        this.decoration = decorationType;
    }
    clearAstSelect() {
        return vscode.commands.registerCommand('poshProTools.clearAstSelection', () => __awaiter(this, void 0, void 0, function* () {
            if (this.decoration) {
                this.decoration.dispose();
            }
        }));
    }
    highlightAst() {
        return vscode.commands.registerCommand('poshProTools.selectAst', (ast) => __awaiter(this, void 0, void 0, function* () {
            const editor = vscode.window.activeTextEditor;
            if (!editor) {
                vscode.window.showErrorMessage("No editor is open to highlight this AST.");
                return;
            }
            if (editor.document.fileName !== ast.parentAst.File) {
                vscode.window.showErrorMessage(`This AST does not match the active file. AST is from ${ast.parentAst.File} `);
                return;
            }
            this.selectRegion(ast.StartOffset, ast.EndOffset);
        }));
    }
}
exports.AstCommands = AstCommands;
//# sourceMappingURL=ast.js.map