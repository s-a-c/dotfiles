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
exports.openTerminalCommand = exports.registerTerminalCommands = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const path = require('path');
exports.registerTerminalCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.openTerminal', exports.openTerminalCommand);
};
exports.openTerminalCommand = (terminal, context) => __awaiter(void 0, void 0, void 0, function* () {
    const writeEmitter = new vscode.EventEmitter();
    var str = '';
    var terminalInstanceId = 0;
    var readOnly = true;
    const pty = {
        onDidWrite: writeEmitter.event,
        open: () => __awaiter(void 0, void 0, void 0, function* () {
            writeEmitter.fire(`Starting terminal...\r\n`);
            var terminalInstance = yield container_1.Container.universal.newTerminalInstance(terminal.terminal);
            terminalInstanceId = terminalInstance.id;
            var output = yield container_1.Container.universal.executeTerminalCommand(terminalInstanceId, 'prompt');
            writeEmitter.fire(output.replace(/\r\n\r\n$/, ''));
            readOnly = false;
        }),
        close: () => {
            container_1.Container.universal.stopTerminalInstance(terminalInstanceId);
        },
        handleInput: (data) => __awaiter(void 0, void 0, void 0, function* () {
            if (readOnly) {
                return;
            }
            ;
            if (data.charCodeAt(0) === 127) {
                str = str.slice(0, -1);
                writeEmitter.fire('\b \b');
                return;
            }
            else {
                writeEmitter.fire(data);
                str += data;
            }
            if (data === '\r') {
                writeEmitter.fire('\r\n');
                readOnly = true;
                var output = yield container_1.Container.universal.executeTerminalCommand(terminalInstanceId, str);
                writeEmitter.fire(output);
                var output = yield container_1.Container.universal.executeTerminalCommand(terminalInstanceId, 'prompt');
                writeEmitter.fire(output.replace(/\r\n\r\n$/, ''));
                str = '';
                readOnly = false;
            }
        })
    };
    const terminalInstance = vscode.window.createTerminal({ name: `Terminal (${terminal.terminal.name})`, pty });
    terminalInstance.show();
});
//# sourceMappingURL=terminals.js.map