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
exports.Welcome = exports.registerWelcomeCommands = void 0;
const vscode = require("vscode");
const welcome_1 = require("../webviews/welcome");
exports.registerWelcomeCommands = (context) => {
    vscode.commands.registerCommand('powershell-universal.welcome', exports.Welcome);
};
exports.Welcome = (context) => __awaiter(void 0, void 0, void 0, function* () {
    var extension = vscode.extensions.getExtension('ironmansoftware.powershell-universal');
    if (extension) {
        welcome_1.default.createOrShow(extension.extensionUri);
    }
});
//# sourceMappingURL=welcomeCommand.js.map