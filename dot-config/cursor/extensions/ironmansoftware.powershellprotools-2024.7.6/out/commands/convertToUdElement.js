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
exports.convertToUdElement = void 0;
const vscode = require("vscode");
const cheerio = require('cheerio');
function convertToUdElement() {
    return vscode.commands.registerCommand('powershell.convertToUdElement', () => __awaiter(this, void 0, void 0, function* () {
        const editor = vscode.window.activeTextEditor;
        if (editor.selection.isEmpty)
            return;
        const html = editor.document.getText(editor.selection);
        const $ = cheerio.load(html);
        const rootNode = $('body')[0].firstChild;
        var script = '';
        script = createElement(rootNode, 0, script);
        editor.edit(x => {
            x.replace(editor.selection, script);
        });
    }));
}
exports.convertToUdElement = convertToUdElement;
function createElement(element, depth, script) {
    if (element == null)
        return script;
    if (element.type !== 'tag') {
        return createElement(element.nextSibling, depth, script);
    }
    script += makeTabs(depth);
    script += `New-UDElement -Tag '${element.tagName}'`;
    if (Object.keys(element.attribs).length > 0) {
        script += ' -Attributes @{ ';
        Object.keys(element.attribs).forEach(x => {
            var attribName = x;
            if (x === 'class') {
                attribName = 'className';
            }
            script += `${attribName} = '${element.attribs[x]}'; `;
        });
        script += '} ';
    }
    if (element.firstChild != null) {
        script += '-Content {\n';
        script = createElement(element.firstChild, depth + 1, script);
        script += makeTabs(depth) + '}\n';
    }
    else {
        script += '\n';
    }
    if (element.nextSibling != null) {
        script = createElement(element.nextSibling, depth, script);
    }
    return script;
}
function makeTabs(depth) {
    var script = '';
    for (var i = 0; i < depth; i++) {
        script += '\t';
    }
    return script;
}
//# sourceMappingURL=convertToUdElement.js.map