"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
exports.formatString = formatString;
exports.resolveVscodeThemeType = resolveVscodeThemeType;
exports.themeType = themeType;
exports.removeDuplicates = removeDuplicates;
const vscodeWebviewProvider_1 = require("./vscodeWebviewProvider");
/**
 * Format a string. Behaves like C#'s string.Format() function.
 */
function formatString(str, ...args) {
    // This is based on code originally from https://github.com/Microsoft/vscode/blob/master/src/vs/nls.js
    // License: https://github.com/Microsoft/vscode/blob/master/LICENSE.txt
    let result;
    if (args.length === 0) {
        result = str;
    }
    else {
        result = str.replace(/\{(\d+)\}/g, (match, rest) => {
            let index = rest[0];
            return typeof args[index] !== "undefined" ? args[index] : match;
        });
    }
    return result;
}
/**
 * Get the css string representation of a ColorThemeKind
 * @param themeKind The ColorThemeKind to convert
 */
function resolveVscodeThemeType(themeKind) {
    switch (themeKind) {
        case vscodeWebviewProvider_1.ColorThemeKind.Dark:
            return "vs-dark";
        case vscodeWebviewProvider_1.ColorThemeKind.HighContrast:
            return "hc-black";
        default: // Both hc-light and light themes are treated as light.
            return "light";
    }
}
function themeType(themeKind) {
    const themeType = resolveVscodeThemeType(themeKind);
    if (themeType !== "light") {
        return "dark";
    }
    return themeType;
}
/** Removes duplicate values from an array */
function removeDuplicates(array) {
    return Array.from(new Set(array));
}

//# sourceMappingURL=utils.js.map
