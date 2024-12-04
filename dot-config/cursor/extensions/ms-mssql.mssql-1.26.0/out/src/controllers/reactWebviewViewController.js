"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReactWebviewViewController = void 0;
const reactWebviewBaseController_1 = require("./reactWebviewBaseController");
/**
 * ReactWebviewViewController is a class that manages a vscode.WebviewView and provides
 * a way to communicate with it. It provides a way to register request handlers and reducers
 * that can be called from the webview. It also provides a way to post notifications to the webview.
 * @template State The type of the state object that the webview will use
 * @template Reducers The type of the reducers that the webview will use
 */
class ReactWebviewViewController extends reactWebviewBaseController_1.ReactWebviewBaseController {
    /**
     * Creates a new ReactWebviewViewController
     * @param _context Extension context
     * @param _sourceFile Source file that the webview will use
     * @param initialData Initial state object that the webview will use
     */
    constructor(_context, _sourceFile, initialData) {
        super(_context, _sourceFile, initialData);
    }
    _getWebview() {
        var _a;
        return (_a = this._webviewView) === null || _a === void 0 ? void 0 : _a.webview;
    }
    /**
     * returns if the webview is visible
     */
    isVisible() {
        var _a;
        return (_a = this._webviewView) === null || _a === void 0 ? void 0 : _a.visible;
    }
    /**
     * Displays the webview in the foreground
     */
    revealToForeground() {
        this._webviewView.show(true);
    }
    resolveWebviewView(webviewView, context, _token) {
        this._webviewView = webviewView;
        webviewView.webview.options = {
            // Allow scripts in the webview
            enableScripts: true,
            localResourceRoots: [this._context.extensionUri],
        };
        this._webviewView.onDidDispose(() => {
            this.dispose();
        });
        this._webviewView.webview.html = this._getHtmlTemplate();
        this.registerDisposable(this._webviewView.webview.onDidReceiveMessage(this._webviewMessageHandler));
        this.initializeBase();
    }
}
exports.ReactWebviewViewController = ReactWebviewViewController;

//# sourceMappingURL=reactWebviewViewController.js.map
