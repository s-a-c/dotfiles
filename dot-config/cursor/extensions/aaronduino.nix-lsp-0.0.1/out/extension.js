'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const lc = require("vscode-languageclient");
function activate(context) {
    const run = {
        command: 'rnix-lsp',
        options: { cwd: '.' }
    };
    new lc.LanguageClient('rnix-lsp', 'Nix Language Server', { run, debug: run }, { documentSelector: [{ scheme: 'file', language: 'nix' }] }).start();
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map