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
    return vscode.commands.registerCommand('poshProTools.help', (item) => __awaiter(void 0, void 0, void 0, function* () {
        let url = '';
        switch (item.label) {
            case "Documentation":
                url = "https://docs.poshtools.com/powershell-pro-tools-documentation/visual-studio-code";
                break;
            case "Forums":
                url = "https://forums.ironmansoftware.com";
                break;
            case "Support":
                url = "https://ironmansoftware.com/product-support";
                break;
        }
        if (url !== '') {
            vscode.env.openExternal(vscode.Uri.parse(url));
        }
    }));
};
exports.default = help;
//# sourceMappingURL=help.js.map