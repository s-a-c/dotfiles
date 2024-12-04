"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
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
exports.QueryResultWebviewPanelController = void 0;
const vscode = require("vscode");
const qr = require("../sharedInterfaces/queryResult");
// import * as Constants from "../constants/constants";
const crypto_1 = require("crypto");
const vscodeWrapper_1 = require("../controllers/vscodeWrapper");
const reactWebviewPanelController_1 = require("../controllers/reactWebviewPanelController");
const utils_1 = require("./utils");
class QueryResultWebviewPanelController extends reactWebviewPanelController_1.ReactWebviewPanelController {
    constructor(context, _vscodeWrapper, _viewColumn, _uri, title, _queryResultWebviewViewController) {
        super(context, "queryResult", {
            resultSetSummaries: {},
            messages: [],
            tabStates: {
                resultPaneTab: qr.QueryResultPaneTabs.Messages,
            },
            executionPlanState: {},
        }, {
            title: vscode.l10n.t({
                message: "{0} (Preview)",
                args: [title],
                comment: "{0} is the editor title",
            }),
            viewColumn: _viewColumn,
            iconPath: {
                dark: vscode.Uri.joinPath(context.extensionUri, "media", "revealQueryResult.svg"),
                light: vscode.Uri.joinPath(context.extensionUri, "media", "revealQueryResult.svg"),
            },
        });
        this._vscodeWrapper = _vscodeWrapper;
        this._viewColumn = _viewColumn;
        this._uri = _uri;
        this._queryResultWebviewViewController = _queryResultWebviewViewController;
        this._correlationId = (0, crypto_1.randomUUID)();
        void this.initialize();
        if (!this._vscodeWrapper) {
            this._vscodeWrapper = new vscodeWrapper_1.default();
        }
    }
    initialize() {
        return __awaiter(this, void 0, void 0, function* () {
            this.registerRpcHandlers();
        });
    }
    registerRpcHandlers() {
        this.registerRequestHandler("getWebviewLocation", () => __awaiter(this, void 0, void 0, function* () {
            return qr.QueryResultWebviewLocation.Document;
        }));
        (0, utils_1.registerCommonRequestHandlers)(this, this._correlationId);
    }
    dispose() {
        super.dispose();
        this._queryResultWebviewViewController.removePanel(this._uri);
    }
    revealToForeground() {
        this.panel.reveal(this._viewColumn);
    }
    getQueryResultWebviewViewController() {
        return this._queryResultWebviewViewController;
    }
}
exports.QueryResultWebviewPanelController = QueryResultWebviewPanelController;

//# sourceMappingURL=queryResultWebviewPanelController.js.map
