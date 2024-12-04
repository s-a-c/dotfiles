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
exports.AstNode = exports.Ast = exports.AstTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
const path = require("path");
class AstTreeViewProvider extends treeViewProvider_1.TreeViewProvider {
    requiresLicense() {
        return false;
    }
    getRefreshCommand() {
        return "astView.refresh";
    }
    constructor() {
        super();
        this.editor = vscode.window.activeTextEditor;
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            return [new Ast()];
        });
    }
}
exports.AstTreeViewProvider = AstTreeViewProvider;
class Ast extends treeViewProvider_1.ParentTreeItem {
    constructor() {
        super("AST", vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "ast";
        this.Editor = vscode.window.activeTextEditor;
    }
    getTreeItem() {
        return {
            tooltip: this._tooltip,
            contextValue: this.contextValue,
            collapsibleState: this.collapsibleState,
            label: this.label,
            description: this._description
        };
    }
    get _description() {
        if (this.Editor && this.Editor.document.languageId === "powershell") {
            return path.basename(this.Editor.document.fileName);
        }
        return "";
    }
    get _tooltip() {
        if (this.Editor && this.Editor.document.languageId === "powershell") {
            return this.Editor.document.fileName;
        }
        return "";
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            if (this.Editor == null) {
                return [new vscode.TreeItem("No file open.")];
            }
            if (this.Editor.document.languageId !== "powershell") {
                return [new vscode.TreeItem("File is not PowerShell.")];
            }
            this.File = this.Editor.document.fileName;
            var ast = yield container_1.Container.PowerShellService.GetAst(this.Editor.document.fileName);
            return [new AstNode(ast, this)];
        });
    }
}
exports.Ast = Ast;
class AstNode extends treeViewProvider_1.ParentTreeItem {
    get StartOffset() {
        return this.ast.StartOffset;
    }
    get EndOffset() {
        return this.ast.EndOffset;
    }
    constructor(ast, parentAst) {
        super(ast.AstType, vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = 'astNode';
        this.ast = ast;
        this.parentAst = parentAst;
    }
    getTreeItem() {
        return {
            tooltip: this._tooltip,
            contextValue: this.contextValue,
            collapsibleState: this.collapsibleState,
            label: this.label,
            description: this._description
        };
    }
    get _description() {
        return `[${this.ast.StartOffset}-${this.ast.EndOffset}]`;
    }
    get _tooltip() {
        return this.ast.AstContent;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            var children = yield container_1.Container.PowerShellService.GetAstByHashcode(this.ast.HashCode);
            if (!Array.isArray(children)) {
                children = [children];
            }
            return children.map(x => new AstNode(x, this.parentAst));
        });
    }
}
exports.AstNode = AstNode;
//# sourceMappingURL=astTreeView.js.map