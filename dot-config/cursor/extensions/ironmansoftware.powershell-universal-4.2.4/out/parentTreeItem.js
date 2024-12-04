"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
class ParentTreeItem extends vscode.TreeItem {
    constructor(label, state) {
        super(label, state);
    }
}
exports.default = ParentTreeItem;
//# sourceMappingURL=parentTreeItem.js.map