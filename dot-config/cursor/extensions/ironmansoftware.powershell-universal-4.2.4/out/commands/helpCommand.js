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
const vscode = require("vscode");
const help = () => {
    return vscode.commands.registerCommand('powershell-universal.help', (item) => __awaiter(void 0, void 0, void 0, function* () {
        let url = '';
        switch (item.label) {
            case "Documentation":
                url = "https://docs.ironmansoftware.com";
                break;
            case "Forums":
                url = "https://forums.ironmansoftware.com";
                break;
            case "Issues":
                url = "mailto:support@ironmansoftware.com";
                break;
            case "Pricing":
                url = "https://www.ironmansoftware.com/pricing/powershell-universal";
                break;
        }
        if (url !== '') {
            vscode.env.openExternal(vscode.Uri.parse(url));
        }
    }));
};
exports.default = help;
//# sourceMappingURL=helpCommand.js.map