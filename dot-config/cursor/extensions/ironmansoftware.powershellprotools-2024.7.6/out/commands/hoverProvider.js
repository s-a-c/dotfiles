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
exports.PowerShellHoverProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const types_1 = require("../types");
class PowerShellHoverProvider {
    constructor() {
        vscode.languages.registerHoverProvider('powershell', {
            provideHover(document, position, token) {
                return __awaiter(this, void 0, void 0, function* () {
                    var editorState = new types_1.TextEditorState();
                    editorState.content = document.getText();
                    editorState.fileName = document.fileName;
                    editorState.documentEnd = {
                        Character: document.lineAt(document.lineCount - 1).range.end.character,
                        Line: document.lineCount - 1
                    };
                    var startColumn = position.character;
                    var startLine = position.line;
                    do {
                        var line = document.lineAt(startLine);
                        if (!line.isEmptyOrWhitespace) {
                            break;
                        }
                        startColumn = 0;
                        startLine++;
                    } while (startLine < document.lineCount);
                    editorState.selectionStart = {
                        Line: startLine,
                        Character: startColumn
                    };
                    editorState.selectionEnd = editorState.selectionStart;
                    let hover = yield container_1.Container.PowerShellService.GetHover(editorState);
                    if (hover == null)
                        return null;
                    let hovers = hover.Markdown.split('/n');
                    var ms = new vscode.MarkdownString('', true);
                    ms.isTrusted = true;
                    for (let textHover of hovers) {
                        ms.appendMarkdown(textHover);
                        ms.appendText("\r\n");
                    }
                    return new vscode.Hover(ms);
                });
            }
        });
    }
}
exports.PowerShellHoverProvider = PowerShellHoverProvider;
//# sourceMappingURL=hoverProvider.js.map