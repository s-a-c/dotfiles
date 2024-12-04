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
exports.RefactoringCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const types_1 = require("../types");
class RefactoringCommands {
    provideCodeActions(document, range, context, token) {
        return __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized(false))
                return;
            var request = this.getRefactorRequest();
            var validRefactors = yield container_1.Container.PowerShellService.GetValidRefactors(request);
            var codeActions = new Array();
            for (var r of validRefactors) {
                request.type = r.Type;
                if (r.Type == types_1.RefactorType.ExtractVariable) {
                    const newName = `newvariable${new Date().getMilliseconds().toString()}`;
                    request.properties = [
                        { type: types_1.RefactorProperty.name, value: newName }
                    ];
                }
                let we = yield this.requestRefactor(request, false);
                if (we.entries().length == 0)
                    continue;
                var action = new vscode.CodeAction(r.Name, vscode.CodeActionKind.RefactorExtract);
                action.edit = we;
                action.command = {
                    title: 'Rename',
                    command: 'editor.action.rename'
                };
                codeActions.push(action);
            }
            return codeActions;
        });
    }
    // resolveCodeAction?(codeAction: vscode.CodeAction, token: vscode.CancellationToken): vscode.ProviderResult<vscode.CodeAction> {
    //     throw new Error('Method not implemented.');
    // }
    register(context) {
        context.subscriptions.push(vscode.languages.registerCodeActionsProvider('powershell', this, {
            providedCodeActionKinds: [vscode.CodeActionKind.Refactor, vscode.CodeActionKind.RefactorExtract]
        }));
        context.subscriptions.push(this.Refactor());
        context.subscriptions.push(this.MoveLeft());
        context.subscriptions.push(this.MoveRight());
    }
    Move(direction) {
        return __awaiter(this, void 0, void 0, function* () {
            var request = this.getRefactorRequest();
            request.type = types_1.RefactorType.reorder;
            request.properties = [{
                    type: types_1.RefactorProperty.name,
                    value: direction
                }];
            yield this.requestRefactor(request);
        });
    }
    MoveLeft() {
        return vscode.commands.registerCommand('poshProTools.refactorMoveLeft', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            this.Move("Left");
        }));
    }
    MoveRight() {
        return vscode.commands.registerCommand('poshProTools.refactorMoveRight', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            this.Move("Right");
        }));
    }
    Refactor() {
        return vscode.commands.registerCommand('poshProTools.refactor', (node) => __awaiter(this, void 0, void 0, function* () {
            if (!container_1.Container.IsInitialized())
                return;
            var request = this.getRefactorRequest();
            var validRefactors = yield container_1.Container.PowerShellService.GetValidRefactors(request);
            var refactorName = yield vscode.window.showQuickPick(validRefactors.map(m => m.Name));
            var refactor = validRefactors.find(m => m.Name === refactorName);
            if (!refactor)
                return;
            switch (refactor.Type) {
                case types_1.RefactorType.ExtractVariable:
                    yield this.extractVariable(request);
                    break;
                case types_1.RefactorType.extractFile:
                    yield this.extractFile(request);
                    break;
                case types_1.RefactorType.extractFunction:
                    yield this.extractFunction(request);
                    break;
                default:
                    request.type = refactor.Type;
                    yield this.requestRefactor(request);
                    break;
            }
        }));
    }
    createRefactorRequest(selection, document) {
        var request = new types_1.RefactorRequest();
        request.editorState = new types_1.TextEditorState();
        request.editorState.content = document.getText();
        request.editorState.fileName = document.fileName;
        request.editorState.uri = document.uri.toString();
        request.editorState.documentEnd = {
            Character: document.lineAt(document.lineCount - 1).range.end.character,
            Line: document.lineCount - 1
        };
        var startColumn = selection.start.character;
        var startLine = selection.start.line;
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
        var endColumn = selection.end.character;
        var endLine = selection.end.line;
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
    getRefactorRequest() {
        var selection = vscode.window.activeTextEditor.selection;
        return this.createRefactorRequest(selection, vscode.window.activeTextEditor.document);
    }
    extractVariable(request) {
        return __awaiter(this, void 0, void 0, function* () {
            const name = yield vscode.window.showInputBox({
                prompt: "Enter variable name"
            });
            request.properties = [{ type: types_1.RefactorProperty.name, value: name }];
            request.type = types_1.RefactorType.ExtractVariable;
            this.requestRefactor(request);
        });
    }
    extractFunction(request) {
        return __awaiter(this, void 0, void 0, function* () {
            const name = yield vscode.window.showInputBox({
                prompt: "Enter function name"
            });
            request.properties = [{ type: types_1.RefactorProperty.name, value: name }];
            request.type = types_1.RefactorType.extractFunction;
            this.requestRefactor(request);
        });
    }
    extractFile(request) {
        return __awaiter(this, void 0, void 0, function* () {
            const fileName = yield vscode.window.showInputBox({
                prompt: "Enter file name"
            });
            request.properties = [{ type: types_1.RefactorProperty.fileName, value: fileName }];
            request.type = types_1.RefactorType.extractFile;
            this.requestRefactor(request);
        });
    }
    requestRefactor(request, apply = true) {
        return __awaiter(this, void 0, void 0, function* () {
            var result = yield container_1.Container.PowerShellService.Refactor(request);
            var filesToOpen = new Array();
            let we = new vscode.WorkspaceEdit();
            for (var edit of result) {
                let uri = edit.Uri ? vscode.Uri.parse(edit.Uri) : vscode.Uri.file(edit.Uri);
                switch (edit.Type) {
                    case types_1.TextEditType.replace:
                        var range = new vscode.Range(new vscode.Position(edit.Start.Line, edit.Start.Character), new vscode.Position(edit.End.Line, edit.End.Character));
                        we.replace(uri, range, edit.Content);
                        break;
                    case types_1.TextEditType.insert:
                        var position = new vscode.Position(edit.Start.Line, edit.Start.Character);
                        we.insert(uri, position, edit.Content);
                        break;
                    case types_1.TextEditType.newFile:
                        we.createFile(uri, {
                            overwrite: false,
                            ignoreIfExists: true
                        });
                        we.insert(uri, new vscode.Position(1, 1), edit.Content);
                        break;
                }
                filesToOpen.push(uri);
                if (edit.Cursor) {
                    var position = new vscode.Position(edit.Cursor.Line, edit.Cursor.Character);
                    vscode.window.activeTextEditor.selection = new vscode.Selection(position, position);
                }
            }
            if (apply && (yield vscode.workspace.applyEdit(we))) {
                filesToOpen.forEach(uri => vscode.workspace.openTextDocument(uri));
            }
            return we;
        });
    }
}
exports.RefactoringCommands = RefactoringCommands;
//# sourceMappingURL=refactoring.js.map