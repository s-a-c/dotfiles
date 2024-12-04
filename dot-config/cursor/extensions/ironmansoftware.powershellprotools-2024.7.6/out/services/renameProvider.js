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
exports.PowerShellRenameProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const types_1 = require("../types");
class PowerShellRenameProvider {
    provideRenameEdits(document, position, newName, token) {
        var position;
        return __awaiter(this, void 0, void 0, function* () {
            const request = this.createRefactorRequest(position, document);
            const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
            var result = yield container_1.Container.PowerShellService.RenameSymbol(newName, workspaceFolder.uri.fsPath, request);
            let we = new vscode.WorkspaceEdit();
            for (var edit of result) {
                let uri = vscode.Uri.file(edit.FileName);
                switch (edit.Type) {
                    case types_1.TextEditType.replace:
                        var range = new vscode.Range(new vscode.Position(edit.Start.Line, edit.Start.Character), new vscode.Position(edit.End.Line, edit.End.Character));
                        we.replace(uri, range, edit.Content);
                        break;
                }
                if (edit.Cursor) {
                    position = new vscode.Position(edit.Cursor.Line, edit.Cursor.Character);
                    vscode.window.activeTextEditor.selection = new vscode.Selection(position, position);
                }
            }
            return we;
        });
    }
    createRefactorRequest(position, document) {
        var request = new types_1.RefactorRequest();
        request.editorState = new types_1.TextEditorState();
        request.editorState.content = document.getText();
        request.editorState.fileName = document.fileName;
        request.editorState.documentEnd = {
            Character: document.lineAt(document.lineCount - 1).range.end.character,
            Line: document.lineCount - 1
        };
        var startColumn = position.character;
        var startLine = position.line;
        do {
            var line = document.lineAt(startLine);
            if (!line.isEmptyOrWhitespace && line.text[line.firstNonWhitespaceCharacterIndex] != '#') {
                break;
            }
            startColumn = 0;
            startLine++;
        } while (startLine < document.lineCount);
        request.editorState.selectionStart = {
            Line: startLine,
            Character: startColumn
        };
        var endColumn = position.character;
        var endLine = position.line;
        do {
            var line = document.lineAt(endLine);
            if (!line.isEmptyOrWhitespace) {
                break;
            }
            endColumn = 0;
            endLine--;
        } while (endLine > 0);
        request.editorState.selectionEnd = {
            Line: endLine,
            Character: endColumn
        };
        return request;
    }
}
exports.PowerShellRenameProvider = PowerShellRenameProvider;
//# sourceMappingURL=renameProvider.js.map