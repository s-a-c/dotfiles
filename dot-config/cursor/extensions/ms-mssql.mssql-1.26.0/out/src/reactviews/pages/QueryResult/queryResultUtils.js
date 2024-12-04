"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
exports.saveAsExcelIcon = exports.saveAsJsonIcon = exports.saveAsCsvIcon = void 0;
exports.hasResultsOrMessages = hasResultsOrMessages;
const vscodeWebviewProvider_1 = require("../../common/vscodeWebviewProvider");
const saveAsCsvIcon = (theme) => {
    return theme === vscodeWebviewProvider_1.ColorThemeKind.Light
        ? require("../../media/saveCsv.svg")
        : require("../../media/saveCsv_inverse.svg");
};
exports.saveAsCsvIcon = saveAsCsvIcon;
const saveAsJsonIcon = (theme) => {
    return theme === vscodeWebviewProvider_1.ColorThemeKind.Light
        ? require("../../media/saveJson.svg")
        : require("../../media/saveJson_inverse.svg");
};
exports.saveAsJsonIcon = saveAsJsonIcon;
const saveAsExcelIcon = (theme) => {
    return theme === vscodeWebviewProvider_1.ColorThemeKind.Light
        ? require("../../media/saveExcel.svg")
        : require("../../media/saveExcel_inverse.svg");
};
exports.saveAsExcelIcon = saveAsExcelIcon;
function hasResultsOrMessages(state) {
    return (Object.keys(state.resultSetSummaries).length > 0 ||
        state.messages.length > 0);
}

//# sourceMappingURL=queryResultUtils.js.map
