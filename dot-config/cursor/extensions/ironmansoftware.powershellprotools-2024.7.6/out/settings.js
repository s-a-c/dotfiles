"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.load = exports.PowerShellLanguageId = void 0;
const vscode = require("vscode");
exports.PowerShellLanguageId = "poshProTools";
function load() {
    const configuration = vscode.workspace.getConfiguration(exports.PowerShellLanguageId);
    return {
        universalDashboardPreviewPort: configuration.get("universalDashboardPreviewPort", 10000),
        debugModuleLoad: configuration.get("debugModuleLoad", false),
        showUpgradeNotification: configuration.get("showUpgradeNotification", true),
        ignoredModules: configuration.get("ignoredModules", ""),
        ignoredAssemblies: configuration.get("ignoredAssemblies", ""),
        ignoredTypes: configuration.get("ignoredTypes", ".*AnonymousType.*;.*ImplementationDetails.*;_.*"),
        ignoredCommands: configuration.get("ignoredCommands", ""),
        ignoredVariables: configuration.get("ignoredVariables", ""),
        ignoredPaths: configuration.get("ignoredPaths", ""),
        checkForModuleUpdates: configuration.get("checkForModuleUpdates", false),
        license: configuration.get("license", ""),
        defaultPackagePsd1: configuration.get("defaultPackagePsd1Path", ""),
        signOnSave: configuration.get("signOnSave", false),
        signOnSaveCertificate: configuration.get("signOnSaveCertificate", ""),
        excludeAutomaticVariables: configuration.get("excludeAutomaticVariables", false),
        clearScreenAfterLoad: configuration.get("clearScreenAfterLoad", true),
        disableNewsNotification: configuration.get("disableNewsNotification", false)
    };
}
exports.load = load;
//# sourceMappingURL=settings.js.map