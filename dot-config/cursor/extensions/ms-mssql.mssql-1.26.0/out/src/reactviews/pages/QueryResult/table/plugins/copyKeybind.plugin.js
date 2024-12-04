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
exports.CopyKeybind = void 0;
const utils_1 = require("../utils");
/**
 * Implements the various additional navigation keybindings we want out of slickgrid
 */
class CopyKeybind {
    constructor(uri, resultSetSummary, webViewState) {
        this.handler = new Slick.EventHandler();
        this.uri = uri;
        this.resultSetSummary = resultSetSummary;
        this.webViewState = webViewState;
    }
    init(grid) {
        this.grid = grid;
        this.handler.subscribe(this.grid.onKeyDown, (e) => this.handleKeyDown(e));
    }
    destroy() {
        this.grid.onKeyDown.unsubscribe();
    }
    handleKeyDown(e) {
        return __awaiter(this, void 0, void 0, function* () {
            let handled = false;
            let platform = yield this.webViewState.extensionRpc.call("getPlatform");
            if (platform === "darwin") {
                // Cmd + C
                if (e.metaKey && e.keyCode === 67) {
                    handled = true;
                    yield this.handleCopySelection(this.grid, this.webViewState, this.uri, this.resultSetSummary);
                }
            }
            else {
                if (e.ctrlKey && e.keyCode === 67) {
                    handled = true;
                    yield this.handleCopySelection(this.grid, this.webViewState, this.uri, this.resultSetSummary);
                }
            }
            if (handled) {
                e.preventDefault();
                e.stopPropagation();
            }
        });
    }
    handleCopySelection(grid, webViewState, uri, resultSetSummary) {
        return __awaiter(this, void 0, void 0, function* () {
            let selectedRanges = grid.getSelectionModel().getSelectedRanges();
            let selection = (0, utils_1.tryCombineSelectionsForResults)(selectedRanges);
            yield webViewState.extensionRpc.call("copySelection", {
                uri: uri,
                batchId: resultSetSummary.batchId,
                resultId: resultSetSummary.id,
                selection: selection,
            });
        });
    }
}
exports.CopyKeybind = CopyKeybind;

//# sourceMappingURL=copyKeybind.plugin.js.map
