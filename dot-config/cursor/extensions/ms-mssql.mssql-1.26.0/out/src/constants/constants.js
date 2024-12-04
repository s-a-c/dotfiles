"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
exports.cmdOpenObjectExplorerCommand = exports.cmdConnectObjectExplorerProfile = exports.cmdConnectObjectExplorerNode = exports.cmdObjectExplorerNodeSignIn = exports.cmdDisconnectObjectExplorerNode = exports.cmdRefreshObjectExplorerNode = exports.cmdRemoveObjectExplorerNode = exports.cmdObjectExplorerNewQuery = exports.cmdAddObjectExplorerPreview = exports.cmdAddObjectExplorer = exports.cmdRebuildIntelliSenseCache = exports.cmdClearPooledConnections = exports.cmdManageConnectionProfiles = exports.cmdNewQuery = exports.cmdCommandPaletteQueryHistory = exports.cmdPauseQueryHistory = exports.cmdStartQueryHistory = exports.cmdRunQueryHistory = exports.cmdOpenQueryHistory = exports.cmdDeleteQueryHistory = exports.cmdClearAllQueryHistory = exports.cmdRefreshQueryHistory = exports.cmdShowGettingStarted = exports.cmdShowReleaseNotes = exports.cmdChooseLanguageFlavor = exports.cmdChooseDatabase = exports.cmdChangeDatabase = exports.cmdDisconnect = exports.cmdConnect = exports.cmdCopyAll = exports.cmdrevealQueryResultPanel = exports.cmdCancelQuery = exports.cmdRunCurrentStatement = exports.cmdRunQuery = exports.folderLabel = exports.serverLabel = exports.disconnectedServerLabel = exports.connectionsArrayName = exports.connectionConfigFilename = exports.outputChannelName = exports.connectionApplicationName = exports.queryHistory = exports.objectExplorerId = exports.noneProviderName = exports.mssqlProviderName = exports.telemetryConfigSectionName = exports.extensionConfigSectionName = exports.extensionName = exports.extensionId = exports.languageId = void 0;
exports.outputContentTypeMessages = exports.outputContentTypeRoot = exports.maxDisplayedStatusTextLength = exports.errorSSLCertificateValidationFailed = exports.errorFirewallRule = exports.errorLoginFailed = exports.errorPasswordNeedsReset = exports.errorPasswordExpired = exports.defaultDatabase = exports.sqlAuthentication = exports.integratedauth = exports.defaultPortNumber = exports.azureMfa = exports.azureDatabase = exports.defaultCommandTimeout = exports.azureSqlDbConnectionTimeout = exports.defaultConnectionTimeout = exports.sqlDbPrefix = exports.enableConnectionPooling = exports.enableSqlAuthenticationProvider = exports.mssqlPiiLogging = exports.piiLogging = exports.cmdLaunchUserFeedback = exports.cmdEditConnection = exports.cmdEditTable = exports.cmdNewTable = exports.cmdDisableActualPlan = exports.cmdEnableActualPlan = exports.cmdShowExecutionPlanInResults = exports.cmdClearAzureTokenCache = exports.cmdAadAddAccount = exports.cmdAadRemoveAccount = exports.cmdAzureSignInToCloud = exports.cmdAzureSignInWithDeviceCode = exports.cmdAzureSignIn = exports.cmdLoadCompletionExtension = exports.cmdOpenExtension = exports.cmdClearFilters = exports.cmdFilterNodeWithExistingFilters = exports.cmdFilterNode = exports.cmdCopyObjectName = exports.cmdToggleSqlCmd = exports.cmdScriptAlter = exports.cmdScriptExecute = exports.cmdScriptDelete = exports.cmdScriptCreate = exports.cmdScriptSelect = exports.cmdObjectExplorerDisableGroupBySchemaCommand = exports.cmdObjectExplorerEnableGroupBySchemaCommand = exports.cmdObjectExplorerGroupBySchemaFlagName = void 0;
exports.configQueryHistoryLimit = exports.configPersistQueryResultTabs = exports.configApplyLocalization = exports.extConfigResultFontFamily = exports.sqlToolsServiceDownloadUrlConfigKey = exports.sqlToolsServiceVersionConfigKey = exports.sqlToolsServiceExecutableFilesConfigKey = exports.sqlToolsServiceInstallDirConfigKey = exports.extConfigResultKeys = exports.configShowBatchTime = exports.configSplitPaneSelection = exports.configCopyRemoveNewLine = exports.configMaxRecentConnections = exports.configRecentConnections = exports.configSaveAsExcel = exports.configSaveAsJson = exports.configSaveAsCsv = exports.configMyConnections = exports.configLogDebugInfo = exports.copyIncludeHeaders = exports.msalCacheFileName = exports.azureAccountProviderCredentials = exports.configAzureAccount = exports.ruleNameRegex = exports.ipAddressRegex = exports.localizedTexts = exports.databaseString = exports.azureAccountExtensionId = exports.sqlToolsServiceCrashLink = exports.integratedAuthHelpLink = exports.encryptionBlogLink = exports.changelogLink = exports.gettingStartedGuideLink = exports.macOpenSslHelpLink = exports.timeToWaitForLanguageModeChange = exports.renamedOpenTimeThreshold = exports.untitledSaveTimeThreshold = exports.contentProviderMinFile = exports.msgContentProviderSqlOutputHtml = exports.outputServiceLocalhost = exports.outputContentTypeShowWarning = exports.outputContentTypeShowError = exports.outputContentTypeEditorSelection = exports.outputContentTypeCopy = exports.outputContentTypeOpenLink = exports.outputContentTypeSaveResults = exports.outputContentTypeConfig = exports.outputContentTypeRows = exports.outputContentTypeColumns = exports.outputContentTypeResultsetMeta = void 0;
exports.Platform = exports.showPlanXmlColumnName = exports.sqlPlanLanguageId = exports.microsoftPrivacyStatementUrl = exports.unixResourceClientPath = exports.windowsResourceClientPath = exports.tenantDisplayName = exports.scriptSelectText = exports.v1SqlToolsServiceConfigKey = exports.sqlToolsServiceConfigKey = exports.resourceProviderId = exports.resourceServiceName = exports.sqlToolsServiceName = exports.invalidServiceFilePath = exports.serviceLoadingFailed = exports.unsupportedPlatformErrorMessage = exports.commandsNotAvailableWhileInstallingTheService = exports.serviceInitializing = exports.serviceInitializingOutputChannelName = exports.sqlToolsServiceCrashButton = exports.sqlToolsServiceCrashMessage = exports.serviceInstallationFailed = exports.serviceInstalled = exports.serviceDownloading = exports.serviceInstalling = exports.serviceInstallingTo = exports.configOpenQueryResultsInTabByDefaultDoNotShowPrompt = exports.configEnableNewQueryResultFeature = exports.configOpenQueryResultsInTabByDefault = exports.richFeaturesLearnMoreLink = exports.configEnableRichExperiencesDoNotShowPrompt = exports.configEnableRichExperiences = exports.configEnableExperimentalFeatures = exports.configEnableQueryHistoryFeature = exports.configEnableQueryHistoryCapture = void 0;
// Collection of Non-localizable Constants
exports.languageId = "sql";
exports.extensionId = "ms-mssql.mssql";
exports.extensionName = "mssql";
exports.extensionConfigSectionName = "mssql";
exports.telemetryConfigSectionName = "telemetry";
exports.mssqlProviderName = "MSSQL";
exports.noneProviderName = "None";
exports.objectExplorerId = "objectExplorer";
exports.queryHistory = "queryHistory";
exports.connectionApplicationName = "vscode-mssql";
exports.outputChannelName = "MSSQL";
exports.connectionConfigFilename = "settings.json";
exports.connectionsArrayName = "connections";
exports.disconnectedServerLabel = "disconnectedServer";
exports.serverLabel = "Server";
exports.folderLabel = "Folder";
exports.cmdRunQuery = "mssql.runQuery";
exports.cmdRunCurrentStatement = "mssql.runCurrentStatement";
exports.cmdCancelQuery = "mssql.cancelQuery";
exports.cmdrevealQueryResultPanel = "mssql.revealQueryResultPanel";
exports.cmdCopyAll = "mssql.copyAll";
exports.cmdConnect = "mssql.connect";
exports.cmdDisconnect = "mssql.disconnect";
exports.cmdChangeDatabase = "mssql.changeDatabase";
exports.cmdChooseDatabase = "mssql.chooseDatabase";
exports.cmdChooseLanguageFlavor = "mssql.chooseLanguageFlavor";
exports.cmdShowReleaseNotes = "mssql.showReleaseNotes";
exports.cmdShowGettingStarted = "mssql.showGettingStarted";
exports.cmdRefreshQueryHistory = "mssql.refreshQueryHistory";
exports.cmdClearAllQueryHistory = "mssql.clearAllQueryHistory";
exports.cmdDeleteQueryHistory = "mssql.deleteQueryHistory";
exports.cmdOpenQueryHistory = "mssql.openQueryHistory";
exports.cmdRunQueryHistory = "mssql.runQueryHistory";
exports.cmdStartQueryHistory = "mssql.startQueryHistoryCapture";
exports.cmdPauseQueryHistory = "mssql.pauseQueryHistoryCapture";
exports.cmdCommandPaletteQueryHistory = "mssql.commandPaletteQueryHistory";
exports.cmdNewQuery = "mssql.newQuery";
exports.cmdManageConnectionProfiles = "mssql.manageProfiles";
exports.cmdClearPooledConnections = "mssql.clearPooledConnections";
exports.cmdRebuildIntelliSenseCache = "mssql.rebuildIntelliSenseCache";
exports.cmdAddObjectExplorer = "mssql.addObjectExplorer";
exports.cmdAddObjectExplorerPreview = "mssql.addObjectExplorerPreview";
exports.cmdObjectExplorerNewQuery = "mssql.objectExplorerNewQuery";
exports.cmdRemoveObjectExplorerNode = "mssql.removeObjectExplorerNode";
exports.cmdRefreshObjectExplorerNode = "mssql.refreshObjectExplorerNode";
exports.cmdDisconnectObjectExplorerNode = "mssql.disconnectObjectExplorerNode";
exports.cmdObjectExplorerNodeSignIn = "mssql.objectExplorerNodeSignIn";
exports.cmdConnectObjectExplorerNode = "mssql.connectObjectExplorerNode";
exports.cmdConnectObjectExplorerProfile = "mssql.connectObjectExplorerProfile";
exports.cmdOpenObjectExplorerCommand = "workbench.view.extension.objectExplorer";
exports.cmdObjectExplorerGroupBySchemaFlagName = "mssql.objectExplorer.groupBySchema";
exports.cmdObjectExplorerEnableGroupBySchemaCommand = "mssql.objectExplorer.enableGroupBySchema";
exports.cmdObjectExplorerDisableGroupBySchemaCommand = "mssql.objectExplorer.disableGroupBySchema";
exports.cmdScriptSelect = "mssql.scriptSelect";
exports.cmdScriptCreate = "mssql.scriptCreate";
exports.cmdScriptDelete = "mssql.scriptDelete";
exports.cmdScriptExecute = "mssql.scriptExecute";
exports.cmdScriptAlter = "mssql.scriptAlter";
exports.cmdToggleSqlCmd = "mssql.toggleSqlCmd";
exports.cmdCopyObjectName = "mssql.copyObjectName";
exports.cmdFilterNode = "mssql.filterNode";
exports.cmdFilterNodeWithExistingFilters = "mssql.filterNodeWithExistingFilters";
exports.cmdClearFilters = "mssql.clearFilters";
exports.cmdOpenExtension = "extension.open";
exports.cmdLoadCompletionExtension = "mssql.loadCompletionExtension";
exports.cmdAzureSignIn = "azure-account.login";
exports.cmdAzureSignInWithDeviceCode = "azure-account.loginWithDeviceCode";
exports.cmdAzureSignInToCloud = "azure-account.loginToCloud";
exports.cmdAadRemoveAccount = "mssql.removeAadAccount";
exports.cmdAadAddAccount = "mssql.addAadAccount";
exports.cmdClearAzureTokenCache = "mssql.clearAzureAccountTokenCache";
exports.cmdShowExecutionPlanInResults = "mssql.showExecutionPlanInResults";
exports.cmdEnableActualPlan = "mssql.enableActualPlan";
exports.cmdDisableActualPlan = "mssql.disableActualPlan";
exports.cmdNewTable = "mssql.newTable";
exports.cmdEditTable = "mssql.editTable";
exports.cmdEditConnection = "mssql.editConnection";
exports.cmdLaunchUserFeedback = "mssql.userFeedback";
exports.piiLogging = "piiLogging";
exports.mssqlPiiLogging = "mssql.piiLogging";
exports.enableSqlAuthenticationProvider = "mssql.enableSqlAuthenticationProvider";
exports.enableConnectionPooling = "mssql.enableConnectionPooling";
exports.sqlDbPrefix = ".database.windows.net";
exports.defaultConnectionTimeout = 15;
exports.azureSqlDbConnectionTimeout = 30;
exports.defaultCommandTimeout = 30;
exports.azureDatabase = "Azure";
exports.azureMfa = "AzureMFA";
exports.defaultPortNumber = 1433;
exports.integratedauth = "Integrated";
exports.sqlAuthentication = "SqlLogin";
exports.defaultDatabase = "master";
exports.errorPasswordExpired = 18487;
exports.errorPasswordNeedsReset = 18488;
exports.errorLoginFailed = 18456;
exports.errorFirewallRule = 40615;
exports.errorSSLCertificateValidationFailed = -2146893019;
exports.maxDisplayedStatusTextLength = 50;
exports.outputContentTypeRoot = "root";
exports.outputContentTypeMessages = "messages";
exports.outputContentTypeResultsetMeta = "resultsetsMeta";
exports.outputContentTypeColumns = "columns";
exports.outputContentTypeRows = "rows";
exports.outputContentTypeConfig = "config";
exports.outputContentTypeSaveResults = "saveResults";
exports.outputContentTypeOpenLink = "openLink";
exports.outputContentTypeCopy = "copyResults";
exports.outputContentTypeEditorSelection = "setEditorSelection";
exports.outputContentTypeShowError = "showError";
exports.outputContentTypeShowWarning = "showWarning";
exports.outputServiceLocalhost = "http://localhost:";
exports.msgContentProviderSqlOutputHtml = "dist/html/sqlOutput.ejs";
exports.contentProviderMinFile = "dist/js/app.min.js";
exports.untitledSaveTimeThreshold = 10.0;
exports.renamedOpenTimeThreshold = 10.0;
exports.timeToWaitForLanguageModeChange = 10000.0;
exports.macOpenSslHelpLink = "https://github.com/Microsoft/vscode-mssql/wiki/OpenSSL-Configuration";
exports.gettingStartedGuideLink = "https://aka.ms/mssql-getting-started";
exports.changelogLink = "https://aka.ms/vscode-mssql-changes";
exports.encryptionBlogLink = "https://aka.ms/vscodemssql-connection";
exports.integratedAuthHelpLink = "https://aka.ms/vscode-mssql-integratedauth";
exports.sqlToolsServiceCrashLink = "https://github.com/Microsoft/vscode-mssql/wiki/SqlToolsService-Known-Issues";
exports.azureAccountExtensionId = "ms-vscode.azure-account";
exports.databaseString = "Database";
exports.localizedTexts = "localizedTexts";
exports.ipAddressRegex = /\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/;
/**
 * Azure Firewall rule name convention is specified here:
 * https://azure.github.io/PSRule.Rules.Azure/en/rules/Azure.Firewall.Name/
 * When naming Azure resources, resource names must meet service requirements. The requirements for Firewall names are:
 * - Between 1 and 80 characters long.
 * - Alphanumerics, underscores, periods, and hyphens.
 * - Start with alphanumeric.
 * - End alphanumeric or underscore.
 * - Firewall names must be unique within a resource group (we can't do string validation for this, so this is ignored)
 */
exports.ruleNameRegex = /^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,78}[a-zA-Z0-9_]?$/;
exports.configAzureAccount = "azureAccount";
exports.azureAccountProviderCredentials = "azureAccountProviderCredentials";
exports.msalCacheFileName = "accessTokenCache";
// Configuration Constants
exports.copyIncludeHeaders = "copyIncludeHeaders";
exports.configLogDebugInfo = "logDebugInfo";
exports.configMyConnections = "connections";
exports.configSaveAsCsv = "saveAsCsv";
exports.configSaveAsJson = "saveAsJson";
exports.configSaveAsExcel = "saveAsExcel";
exports.configRecentConnections = "recentConnections";
exports.configMaxRecentConnections = "maxRecentConnections";
exports.configCopyRemoveNewLine = "copyRemoveNewLine";
exports.configSplitPaneSelection = "splitPaneSelection";
exports.configShowBatchTime = "showBatchTime";
exports.extConfigResultKeys = [
    "shortcuts",
    "messagesDefaultOpen",
    "resultsFontSize",
    "resultsFontFamily",
];
exports.sqlToolsServiceInstallDirConfigKey = "installDir";
exports.sqlToolsServiceExecutableFilesConfigKey = "executableFiles";
exports.sqlToolsServiceVersionConfigKey = "version";
exports.sqlToolsServiceDownloadUrlConfigKey = "downloadUrl";
exports.extConfigResultFontFamily = "resultsFontFamily";
exports.configApplyLocalization = "applyLocalization";
exports.configPersistQueryResultTabs = "persistQueryResultTabs";
exports.configQueryHistoryLimit = "queryHistoryLimit";
exports.configEnableQueryHistoryCapture = "enableQueryHistoryCapture";
exports.configEnableQueryHistoryFeature = "enableQueryHistoryFeature";
exports.configEnableExperimentalFeatures = "mssql.enableExperimentalFeatures";
exports.configEnableRichExperiences = "mssql.enableRichExperiences";
exports.configEnableRichExperiencesDoNotShowPrompt = "mssql.enableRichExperiencesDoNotShowPrompt";
exports.richFeaturesLearnMoreLink = "https://aka.ms/mssql-rich-features";
exports.configOpenQueryResultsInTabByDefault = "mssql.openQueryResultsInTabByDefault";
exports.configEnableNewQueryResultFeature = "mssql.enableNewQueryResultFeature";
exports.configOpenQueryResultsInTabByDefaultDoNotShowPrompt = "mssql.openQueryResultsInTabByDefaultDoNotShowPrompt";
// ToolsService Constants
exports.serviceInstallingTo = "Installing SQL tools service to";
exports.serviceInstalling = "Installing";
exports.serviceDownloading = "Downloading";
exports.serviceInstalled = "Sql Tools Service installed";
exports.serviceInstallationFailed = "Failed to install Sql Tools Service";
exports.sqlToolsServiceCrashMessage = "SQL Tools Service component could not start.";
exports.sqlToolsServiceCrashButton = "View Known Issues";
exports.serviceInitializingOutputChannelName = "SqlToolsService Initialization";
exports.serviceInitializing = "Initializing SQL tools service for the mssql extension.";
exports.commandsNotAvailableWhileInstallingTheService = "Note: mssql commands will be available after installing the service.";
exports.unsupportedPlatformErrorMessage = "The platform is not supported";
exports.serviceLoadingFailed = "Failed to load Sql Tools Service";
exports.invalidServiceFilePath = "Invalid file path for Sql Tools Service";
exports.sqlToolsServiceName = "SQLToolsService";
exports.resourceServiceName = "AzureResourceProvider";
exports.resourceProviderId = "azurePublicCloud";
exports.sqlToolsServiceConfigKey = "service";
exports.v1SqlToolsServiceConfigKey = "v1Service";
exports.scriptSelectText = "SELECT TOP (1000) * FROM ";
exports.tenantDisplayName = "Microsoft";
exports.windowsResourceClientPath = "SqlToolsResourceProviderService.exe";
exports.unixResourceClientPath = "SqlToolsResourceProviderService";
exports.microsoftPrivacyStatementUrl = "https://www.microsoft.com/en-us/privacy/privacystatement";
exports.sqlPlanLanguageId = "sqlplan";
exports.showPlanXmlColumnName = "Microsoft SQL Server 2005 XML Showplan";
var Platform;
(function (Platform) {
    Platform["Windows"] = "win32";
    Platform["Mac"] = "darwin";
    Platform["Linux"] = "linux";
})(Platform || (exports.Platform = Platform = {}));

//# sourceMappingURL=constants.js.map
