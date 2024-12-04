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
exports.MethodNode = exports.MethodsNode = exports.FieldNode = exports.FieldsNode = exports.PropertyNode = exports.PropertiesNode = exports.TypeNode = exports.NamespaceNode = exports.AssemblyNode = exports.ReflectionViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("../container");
const treeViewProvider_1 = require("./treeViewProvider");
class ReflectionViewProvider extends treeViewProvider_1.TreeViewProvider {
    getRefreshCommand() {
        return "reflectionView.refresh";
    }
    requiresLicense() {
        return false;
    }
    constructor() {
        super();
        ReflectionViewProvider.Instance = this;
    }
    getNodes() {
        return __awaiter(this, void 0, void 0, function* () {
            const assemblies = yield container_1.Container.PowerShellService.GetAssemblies();
            return assemblies.map(x => new AssemblyNode(x.Name, x.Version, x.Path));
        });
    }
}
exports.ReflectionViewProvider = ReflectionViewProvider;
class AssemblyNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return (yield container_1.Container.PowerShellService.GetNamespaces(this.name, "")).map(m => new NamespaceNode(m, this.name));
        });
    }
    constructor(name, version, path) {
        super(name, vscode.TreeItemCollapsibleState.Collapsed);
        this.name = name;
        this.version = version;
        this.path = path;
        this.contextValue = "assembly";
    }
    getTreeItem() {
        return {
            tooltip: this._tooltip,
            contextValue: this.contextValue,
            collapsibleState: this.collapsibleState,
            label: this.label,
            description: this._description,
            iconPath: new vscode.ThemeIcon('package')
        };
    }
    get _description() {
        return this.version;
    }
    get _tooltip() {
        return this.path;
    }
}
exports.AssemblyNode = AssemblyNode;
class NamespaceNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            const nodes = new Array();
            var namespaces = (yield container_1.Container.PowerShellService.GetNamespaces(this.assembly, this.namespace.FullName)).map(m => new NamespaceNode(m, this.assembly));
            var types = yield container_1.Container.PowerShellService.GetTypes(this.assembly, this.namespace.FullName);
            var typeNodes = types.map(x => new TypeNode(x));
            return nodes.concat(namespaces).concat(typeNodes);
        });
    }
    constructor(namespace, assembly) {
        super(namespace.Name, vscode.TreeItemCollapsibleState.Collapsed);
        this.namespace = namespace;
        this.assembly = assembly;
        this.contextValue = "namespace";
        this.iconPath = new vscode.ThemeIcon('symbol-namespace');
    }
}
exports.NamespaceNode = NamespaceNode;
class TypeNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return [
                new FieldsNode(this.type),
                new PropertiesNode(this.type),
                new MethodsNode(this.type)
            ];
        });
    }
    constructor(type) {
        super(type.Name, vscode.TreeItemCollapsibleState.Collapsed);
        this.type = type;
        this.contextValue = "type";
        this.iconPath = new vscode.ThemeIcon('symbol-class');
    }
}
exports.TypeNode = TypeNode;
class PropertiesNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            const properties = yield container_1.Container.PowerShellService.GetProperties(this.type.AssemblyName, this.type.Name);
            return properties.map(m => new PropertyNode(m));
        });
    }
    constructor(type) {
        super('Properties', vscode.TreeItemCollapsibleState.Collapsed);
        this.type = type;
        this.iconPath = new vscode.ThemeIcon('symbol-property');
    }
}
exports.PropertiesNode = PropertiesNode;
class PropertyNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return [];
        });
    }
    constructor(property) {
        super(property.Name, vscode.TreeItemCollapsibleState.None);
        this.property = property;
        this.contextValue = "property";
        this.iconPath = new vscode.ThemeIcon('symbol-property');
        this.description = property.PropertyType;
    }
}
exports.PropertyNode = PropertyNode;
class FieldsNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            const properties = yield container_1.Container.PowerShellService.GetFields(this.type.AssemblyName, this.type.Name);
            return properties.map(m => new FieldNode(m));
        });
    }
    constructor(type) {
        super('Fields', vscode.TreeItemCollapsibleState.Collapsed);
        this.type = type;
        this.iconPath = new vscode.ThemeIcon('symbol-field');
    }
}
exports.FieldsNode = FieldsNode;
class FieldNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return [];
        });
    }
    constructor(field) {
        super(field.Name, vscode.TreeItemCollapsibleState.None);
        this.field = field;
        this.contextValue = "field";
        this.iconPath = new vscode.ThemeIcon('symbol-field');
        this.description = field.FieldType;
    }
}
exports.FieldNode = FieldNode;
class MethodsNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            const properties = yield container_1.Container.PowerShellService.GetMethods(this.type.AssemblyName, this.type.Name);
            return properties.map(m => new MethodNode(m));
        });
    }
    constructor(type) {
        super('Methods', vscode.TreeItemCollapsibleState.Collapsed);
        this.type = type;
        this.iconPath = new vscode.ThemeIcon('symbol-method');
    }
}
exports.MethodsNode = MethodsNode;
class MethodNode extends treeViewProvider_1.ParentTreeItem {
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return [];
        });
    }
    constructor(method) {
        super(method.Display, vscode.TreeItemCollapsibleState.None);
        this.method = method;
        this.contextValue = "method";
        this.iconPath = new vscode.ThemeIcon('symbol-method');
    }
}
exports.MethodNode = MethodNode;
//# sourceMappingURL=reflectionTreeView.js.map