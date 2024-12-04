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
exports.VariableDetails = exports.VariableViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class VariableViewProvider extends treeViewProvider_1.TreeViewProvider {
    getRefreshCommand() {
        return "variableView.refresh";
    }
    requiresLicense() {
        return true;
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            var variables = yield container_1.Container.PowerShellService.GetVariables();
            return variables.map(x => new VariableDetails(x));
        });
    }
}
exports.VariableViewProvider = VariableViewProvider;
class VariableDetails extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            var children = yield container_1.Container.PowerShellService.ExpandVariable(this.variableDetails.Path);
            return children.map(x => {
                return new VariableDetails(x);
            });
        });
    }
    constructor(variableDetails) {
        super(variableDetails.VarName, variableDetails.HasChildren ? vscode.TreeItemCollapsibleState.Collapsed : vscode.TreeItemCollapsibleState.None);
        this.variableDetails = variableDetails;
        this.contextValue = "variable";
    }
    getTreeItem() {
        return {
            tooltip: this._tooltip,
            contextValue: this.contextValue,
            collapsibleState: this.collapsibleState,
            label: this.label,
            description: this._description || ""
        };
    }
    get _description() {
        return this.variableDetails.VarValue;
    }
    get _tooltip() {
        return this.variableDetails.Type;
    }
}
exports.VariableDetails = VariableDetails;
//# sourceMappingURL=variableTreeView.js.map