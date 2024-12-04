'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNetVersion = exports.updateNetVersion = exports.documentRange = void 0;
const vscode = require("vscode");
const NET_VERSION = 'NET_VERSION';
function documentRange() {
    const editor = vscode.window.activeTextEditor;
    var firstLine = editor.document.lineAt(0);
    var lastLine = editor.document.lineAt(editor.document.lineCount - 1);
    return new vscode.Range(0, firstLine.range.start.character, editor.document.lineCount - 1, lastLine.range.end.character);
}
exports.documentRange = documentRange;
function updateNetVersion(storage, state) {
    storage.update(NET_VERSION, state);
}
exports.updateNetVersion = updateNetVersion;
function getNetVersion(storage) {
    return storage.get(NET_VERSION, 0);
}
exports.getNetVersion = getNetVersion;
//# sourceMappingURL=util.js.map