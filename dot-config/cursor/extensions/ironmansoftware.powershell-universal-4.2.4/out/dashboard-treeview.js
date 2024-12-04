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
exports.DashboardEndpointTreeItem = exports.DashboardEndpointsTreeItem = exports.DashboardSessionPageTreeItem = exports.DashboardSessionPagesTreeItem = exports.DashboardSessionTreeItem = exports.DashboardSessionsTreeItem = exports.DashboardPageTreeItem = exports.DashboardPagesTreeItem = exports.DashboardTreeItem = exports.DashboardsTreeItem = exports.DashboardTreeViewProvider = void 0;
const vscode = require("vscode");
const container_1 = require("./container");
const types_1 = require("./types");
const parentTreeItem_1 = require("./parentTreeItem");
class DashboardTreeViewProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }
    getTreeItem(element) {
        return element;
    }
    getChildren(element) {
        return __awaiter(this, void 0, void 0, function* () {
            if (element == null) {
                return [
                    new DashboardsTreeItem()
                ];
            }
            if (element instanceof parentTreeItem_1.default) {
                var parentTreeItem = element;
                return parentTreeItem.getChildren();
            }
        });
    }
    refresh(node) {
        this._onDidChangeTreeData.fire(node);
    }
}
exports.DashboardTreeViewProvider = DashboardTreeViewProvider;
class DashboardsTreeItem extends parentTreeItem_1.default {
    constructor() {
        super("Apps", vscode.TreeItemCollapsibleState.Collapsed);
        this.iconPath = new vscode.ThemeIcon('dashboard');
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const dashboards = yield container_1.Container.universal.getDashboards();
                return dashboards.map(y => new DashboardTreeItem(y));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query apps. " + err);
                return [];
            }
        });
    }
}
exports.DashboardsTreeItem = DashboardsTreeItem;
class DashboardTreeItem extends parentTreeItem_1.default {
    constructor(dashboard) {
        super(dashboard.name, vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "dashboard";
        this.dashboard = dashboard;
        const icon = dashboard.status === types_1.DashboardStatus.Started ? "debug-start" : "debug-stop";
        const themeIcon = new vscode.ThemeIcon(icon);
        this.iconPath = themeIcon;
        this.logIndex = 0;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return [
                    new DashboardPagesTreeItem(this.dashboard),
                    new DashboardSessionsTreeItem(this.dashboard),
                ];
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query apps pages. " + err);
                return [];
            }
        });
    }
    reloadLog() {
        return __awaiter(this, void 0, void 0, function* () {
            const log = yield container_1.Container.universal.getDashboardLog(this.dashboard.name);
            const logChannel = container_1.Container.getPanel(`App (${this.dashboard.name})`);
            logChannel.clear();
            logChannel.appendLine(log);
        });
    }
    clearLog() {
        return __awaiter(this, void 0, void 0, function* () {
            const logChannel = container_1.Container.getPanel(`App (${this.dashboard.name})`);
            logChannel.clear();
            this.logIndex = 0;
        });
    }
    showLog() {
        return __awaiter(this, void 0, void 0, function* () {
            const logChannel = container_1.Container.getPanel(`App (${this.dashboard.name})`);
            yield this.reloadLog();
            logChannel.show();
        });
    }
}
exports.DashboardTreeItem = DashboardTreeItem;
class DashboardPagesTreeItem extends parentTreeItem_1.default {
    constructor(dashboard) {
        super("Pages", vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "dashboardPages";
        this.dashboard = dashboard;
        this.iconPath = new vscode.ThemeIcon('files');
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const pages = yield container_1.Container.universal.getDashboardPages(this.dashboard.id);
                return pages.map(y => new DashboardPageTreeItem(y));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query apps. " + err);
                return [];
            }
        });
    }
}
exports.DashboardPagesTreeItem = DashboardPagesTreeItem;
class DashboardPageTreeItem extends vscode.TreeItem {
    constructor(page) {
        super(page.name, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "dashboardPage";
        this.page = page;
        const themeIcon = new vscode.ThemeIcon('file');
        this.iconPath = themeIcon;
    }
}
exports.DashboardPageTreeItem = DashboardPageTreeItem;
class DashboardSessionsTreeItem extends parentTreeItem_1.default {
    constructor(dashboard) {
        super("Sessions", vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "dashboardPages";
        this.dashboard = dashboard;
        this.iconPath = new vscode.ThemeIcon('debug-disconnect');
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const diagnostics = yield container_1.Container.universal.getDashboardDiagnostics(this.dashboard.id);
                return diagnostics.sessions.map(y => new DashboardSessionTreeItem(this.dashboard.id, y));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query apps. " + err);
                return [];
            }
        });
    }
}
exports.DashboardSessionsTreeItem = DashboardSessionsTreeItem;
class DashboardSessionTreeItem extends parentTreeItem_1.default {
    constructor(dashboardId, session) {
        super(`${session.userName} (${session.id})`, vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "dashboardSession";
        this.session = session;
        this.dashboardId = dashboardId;
        const themeIcon = new vscode.ThemeIcon('file');
        this.iconPath = themeIcon;
        this.tooltip = session.lastTouched;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            return [
                new DashboardSessionPagesTreeItem(this.dashboardId, this.session)
            ];
        });
    }
}
exports.DashboardSessionTreeItem = DashboardSessionTreeItem;
class DashboardSessionPagesTreeItem extends parentTreeItem_1.default {
    constructor(dashboardId, session) {
        super("Tabs", vscode.TreeItemCollapsibleState.Collapsed);
        this.contextValue = "dashboardPages";
        this.session = session;
        this.iconPath = new vscode.ThemeIcon('browser');
        this.dashboardId = dashboardId;
    }
    getChildren() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return this.session.pages.map(y => new DashboardSessionPageTreeItem(y, this.session.id, this.dashboardId));
            }
            catch (err) {
                container_1.Container.universal.showConnectionError("Failed to query session pages. " + err);
                return [];
            }
        });
    }
}
exports.DashboardSessionPagesTreeItem = DashboardSessionPagesTreeItem;
class DashboardSessionPageTreeItem extends vscode.TreeItem {
    constructor(pageId, sessionId, dashboardId) {
        super(pageId, vscode.TreeItemCollapsibleState.None);
        this.contextValue = "dashboardSessionPage";
        const themeIcon = new vscode.ThemeIcon('browser');
        this.iconPath = themeIcon;
        this.pageId = pageId;
        this.sessionId = sessionId;
        this.dashboardId = dashboardId;
    }
}
exports.DashboardSessionPageTreeItem = DashboardSessionPageTreeItem;
class DashboardEndpointsTreeItem extends parentTreeItem_1.default {
    constructor(endpoints) {
        super("Endpoints", vscode.TreeItemCollapsibleState.Collapsed);
        this.endpoints = endpoints;
    }
    getChildren() {
        if (!this.endpoints) {
            return new Promise((resolve) => resolve([]));
        }
        return new Promise((resolve) => resolve(this.endpoints.map(x => new DashboardEndpointTreeItem(x))));
    }
}
exports.DashboardEndpointsTreeItem = DashboardEndpointsTreeItem;
class DashboardEndpointTreeItem extends vscode.TreeItem {
    constructor(endpoint) {
        super(endpoint.id);
        this.contextValue = 'endpoint';
        this.iconPath = '$(code)';
        this.endpoint = endpoint;
    }
}
exports.DashboardEndpointTreeItem = DashboardEndpointTreeItem;
//# sourceMappingURL=dashboard-treeview.js.map