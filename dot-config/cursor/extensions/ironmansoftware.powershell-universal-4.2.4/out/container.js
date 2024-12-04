"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Container = void 0;
const vscode_1 = require("vscode");
class Container {
    static initialize(context, universal) {
        this._context = context;
        this._universal = universal;
    }
    static get connected() {
        return this._connected;
    }
    static set connected(value) {
        this._connected = value;
    }
    static get universal() {
        return this._universal;
    }
    static get context() {
        return this._context;
    }
    static getPanel(name) {
        let panel = this._outputPanels.find(panel => panel.name === name);
        if (!panel) {
            panel = vscode_1.window.createOutputChannel(name);
            this._outputPanels.push(panel);
        }
        return panel;
    }
}
exports.Container = Container;
Container._outputPanels = [];
//# sourceMappingURL=container.js.map