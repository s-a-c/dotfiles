"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.showErrorWithConfigFileButton = showErrorWithConfigFileButton;
const vscode = __importStar(require("vscode"));
const config_service_1 = require("./config-service");
/**
 * Shows an error message with a button to open the config file.
 * When opened, it highlights the first relevant section of the config based on the error type.
 */
async function showErrorWithConfigFileButton(errorMessage, config) {
    const configPath = (0, config_service_1.getConfigFilePath)();
    if (!configPath) {
        vscode.window.showErrorMessage(errorMessage);
        return;
    }
    vscode.window.showErrorMessage(errorMessage, 'Open Config File')
        .then(async (selection) => {
        if (selection !== 'Open Config File')
            return;
        const document = await vscode.workspace.openTextDocument(configPath);
        const editor = await vscode.window.showTextDocument(document);
        const configText = document.getText();
        // Find the position of the problematic config using unique identifiers
        let startIndex = -1;
        let endIndex = -1;
        // Find all occurrences of the config type
        const typeRegex = new RegExp(`"type"\\s*:\\s*"${config.type}"`, 'g');
        let match;
        while ((match = typeRegex.exec(configText)) !== null) {
            // For each match, find the enclosing object's bounds
            const objStartIndex = findObjectStart(configText, match.index);
            const objEndIndex = findObjectEnd(configText, match.index);
            if (objStartIndex === -1 || objEndIndex === -1)
                continue;
            const objText = configText.substring(objStartIndex, objEndIndex + 1);
            // Check if this object matches our config based on unique identifiers
            const isMatch = matchesConfig(objText, config);
            if (isMatch) {
                startIndex = objStartIndex;
                endIndex = objEndIndex + 1;
                break;
            }
        }
        if (startIndex === -1 || endIndex === -1)
            return;
        // Create a selection for the matching config
        const startPos = document.positionAt(startIndex);
        const endPos = document.positionAt(endIndex);
        editor.selection = new vscode.Selection(startPos, endPos);
        editor.revealRange(new vscode.Range(startPos, endPos));
    });
}
/**
 * Find the start of the JSON object containing the given position
 */
function findObjectStart(text, position) {
    let depth = 0;
    let index = position;
    while (index >= 0) {
        const char = text[index];
        if (char === '}')
            depth++;
        if (char === '{') {
            depth--;
            if (depth < 0)
                return index;
        }
        index--;
    }
    return -1;
}
/**
 * Find the end of the JSON object containing the given position
 */
function findObjectEnd(text, position) {
    let depth = 0;
    let index = position;
    while (index < text.length) {
        const char = text[index];
        if (char === '{')
            depth++;
        if (char === '}') {
            depth--;
            if (depth < 0)
                return index;
        }
        index++;
    }
    return -1;
}
/**
 * Check if a JSON object string matches the given config based on unique identifiers
 */
function matchesConfig(objText, config) {
    try {
        const obj = JSON.parse(objText);
        switch (config.type) {
            case 'sqlite':
                return obj.path === config.path;
            case 'mysql':
            case 'mariadb':
                return obj.name === config.name &&
                    obj.database === config.database;
            case 'postgres':
                return obj.name === config.name &&
                    obj.database === config.database;
            case 'mssql':
                return obj.name === config.name &&
                    obj.database === config.database;
            default:
                return false;
        }
    }
    catch {
        return false;
    }
}
//# sourceMappingURL=config-error-service.js.map