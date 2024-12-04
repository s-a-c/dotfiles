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
exports.ConnectionDialogWebviewController = void 0;
const vscode = require("vscode");
const telemetry_1 = require("../sharedInterfaces/telemetry");
const connectionDialog_1 = require("../sharedInterfaces/connectionDialog");
const connection_1 = require("../models/contracts/connection");
const form_1 = require("../reactviews/common/forms/form");
const locConstants_1 = require("../constants/locConstants");
const azureHelper_1 = require("./azureHelper");
const telemetry_2 = require("../telemetry/telemetry");
const webview_1 = require("../sharedInterfaces/webview");
const azureController_1 = require("../azure/azureController");
const logger_1 = require("../models/logger");
const reactWebviewPanelController_1 = require("../controllers/reactWebviewPanelController");
const userSurvey_1 = require("../nps/userSurvey");
const vscodeWrapper_1 = require("../controllers/vscodeWrapper");
const connectionConstants_1 = require("./connectionConstants");
const connectionInfo_1 = require("../models/connectionInfo");
const utils_1 = require("../utils/utils");
const vscode_1 = require("vscode");
const interfaces_1 = require("../models/interfaces");
class ConnectionDialogWebviewController extends reactWebviewPanelController_1.ReactWebviewPanelController {
    constructor(context, _mainController, _objectExplorerProvider, _connectionToEdit) {
        super(context, "connectionDialog", new connectionDialog_1.ConnectionDialogWebviewState({
            connectionProfile: {},
            savedConnections: [],
            recentConnections: [],
            selectedInputMode: connectionDialog_1.ConnectionInputMode.Parameters,
            connectionComponents: {
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                components: {}, // force empty record for intial blank state
                mainOptions: [],
                topAdvancedOptions: [],
                groupedAdvancedOptions: {},
            },
            azureSubscriptions: [],
            azureServers: [],
            connectionStatus: webview_1.ApiStatus.NotStarted,
            formError: "",
            loadingAzureSubscriptionsStatus: webview_1.ApiStatus.NotStarted,
            loadingAzureServersStatus: webview_1.ApiStatus.NotStarted,
            trustServerCertError: undefined,
        }), {
            title: locConstants_1.ConnectionDialog.connectionDialog,
            viewColumn: vscode.ViewColumn.Active,
            iconPath: {
                dark: vscode.Uri.joinPath(context.extensionUri, "media", "connectionDialogEditor_dark.svg"),
                light: vscode.Uri.joinPath(context.extensionUri, "media", "connectionDialogEditor_light.svg"),
            },
        });
        this._mainController = _mainController;
        this._objectExplorerProvider = _objectExplorerProvider;
        this._connectionToEdit = _connectionToEdit;
        this._mainOptionNames = new Set([
            "server",
            "authenticationType",
            "user",
            "password",
            "savePassword",
            "accountId",
            "tenantId",
            "database",
            "trustServerCertificate",
            "encrypt",
            "profileName",
        ]);
        if (!ConnectionDialogWebviewController._logger) {
            const vscodeWrapper = new vscodeWrapper_1.default();
            const channel = vscodeWrapper.createOutputChannel(locConstants_1.ConnectionDialog.connectionDialog);
            ConnectionDialogWebviewController._logger = logger_1.Logger.create(channel);
        }
        this.registerRpcHandlers();
        this.initializeDialog().catch((err) => {
            void vscode.window.showErrorMessage((0, utils_1.getErrorMessage)(err));
            // The spots in initializeDialog() that handle potential PII have their own error catches that emit error telemetry with `includeErrorMessage` set to false.
            // Everything else during initialization shouldn't have PII, so it's okay to include the error message here.
            (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.Initialize, err, true);
        });
    }
    initializeDialog() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                yield this.updateLoadedConnections(this.state);
                this.updateState();
            }
            catch (err) {
                void vscode.window.showErrorMessage((0, utils_1.getErrorMessage)(err));
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.Initialize, err, false);
            }
            try {
                if (this._connectionToEdit) {
                    yield this.loadConnectionToEdit();
                }
                else {
                    yield this.loadEmptyConnection();
                }
            }
            catch (err) {
                yield this.loadEmptyConnection();
                void vscode.window.showErrorMessage((0, utils_1.getErrorMessage)(err));
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.Initialize, err, false);
            }
            this.state.connectionComponents = {
                components: yield this.generateConnectionComponents(),
                mainOptions: [
                    "server",
                    "trustServerCertificate",
                    "authenticationType",
                    "user",
                    "password",
                    "savePassword",
                    "accountId",
                    "tenantId",
                    "database",
                    "encrypt",
                ],
                topAdvancedOptions: [
                    "port",
                    "applicationName",
                    // TODO: 'autoDisconnect',
                    // TODO: 'sslConfiguration',
                    "connectTimeout",
                    "multiSubnetFailover",
                ],
                groupedAdvancedOptions: {}, // computed below
            };
            this.state.connectionComponents.groupedAdvancedOptions =
                this.groupAdvancedOptions(this.state.connectionComponents);
            yield this.updateItemVisibility();
            this.updateState();
        });
    }
    loadConnectionToEdit() {
        return __awaiter(this, void 0, void 0, function* () {
            if (this._connectionToEdit) {
                this._connectionToEditCopy = structuredClone(this._connectionToEdit);
                const connection = yield this.initializeConnectionForDialog(this._connectionToEdit);
                this.state.connectionProfile = connection;
                this.state.selectedInputMode =
                    connection.connectionString && connection.server === undefined
                        ? connectionDialog_1.ConnectionInputMode.ConnectionString
                        : connectionDialog_1.ConnectionInputMode.Parameters;
                this.updateState();
            }
        });
    }
    loadEmptyConnection() {
        return __awaiter(this, void 0, void 0, function* () {
            const emptyConnection = {
                authenticationType: connectionDialog_1.AuthenticationType.SqlLogin,
                connectTimeout: 15, // seconds
                applicationName: "vscode-mssql",
            };
            this.state.connectionProfile = emptyConnection;
        });
    }
    initializeConnectionForDialog(connection) {
        return __awaiter(this, void 0, void 0, function* () {
            // Load the password if it's saved
            const isConnectionStringConnection = connection.connectionString !== undefined &&
                connection.connectionString !== "";
            if (!isConnectionStringConnection) {
                const password = yield this._mainController.connectionManager.connectionStore.lookupPassword(connection, isConnectionStringConnection);
                connection.password = password;
            }
            else {
                // If the connection is a connection string connection with SQL Auth:
                //   * the full connection string is stored as the "password" in the credential store
                //   * we need to extract the password from the connection string
                // If the connection is a connection string connection with a different auth type, then there's nothing in the credential store.
                const connectionString = yield this._mainController.connectionManager.connectionStore.lookupPassword(connection, isConnectionStringConnection);
                if (connectionString) {
                    const passwordIndex = connectionString
                        .toLowerCase()
                        .indexOf("password=");
                    if (passwordIndex !== -1) {
                        // extract password from connection string; found between 'Password=' and the next ';'
                        const passwordStart = passwordIndex + "password=".length;
                        const passwordEnd = connectionString.indexOf(";", passwordStart);
                        if (passwordEnd !== -1) {
                            connection.password = connectionString.substring(passwordStart, passwordEnd);
                        }
                        // clear the connection string from the IConnectionDialogProfile so that the ugly connection string key
                        // that's used to look up the actual connection string (with password) isn't displayed
                        connection.connectionString = "";
                    }
                }
            }
            const dialogConnection = connection;
            // Set the display name
            dialogConnection.displayName = dialogConnection.profileName
                ? dialogConnection.profileName
                : (0, connectionInfo_1.getConnectionDisplayName)(connection);
            return dialogConnection;
        });
    }
    updateItemVisibility() {
        return __awaiter(this, void 0, void 0, function* () {
            let hiddenProperties = [];
            if (this.state.selectedInputMode === connectionDialog_1.ConnectionInputMode.Parameters ||
                this.state.selectedInputMode === connectionDialog_1.ConnectionInputMode.AzureBrowse) {
                if (this.state.connectionProfile.authenticationType !==
                    connectionDialog_1.AuthenticationType.SqlLogin) {
                    hiddenProperties.push("user", "password", "savePassword");
                }
                if (this.state.connectionProfile.authenticationType !==
                    connectionDialog_1.AuthenticationType.AzureMFA) {
                    hiddenProperties.push("accountId", "tenantId");
                }
                if (this.state.connectionProfile.authenticationType ===
                    connectionDialog_1.AuthenticationType.AzureMFA) {
                    // Hide tenantId if accountId has only one tenant
                    const tenants = yield this.getTenants(this.state.connectionProfile.accountId);
                    if (tenants.length === 1) {
                        hiddenProperties.push("tenantId");
                    }
                }
            }
            for (const component of Object.values(this.state.connectionComponents.components)) {
                component.hidden = hiddenProperties.includes(component.propertyName);
            }
        });
    }
    getActiveFormComponents() {
        if (this.state.selectedInputMode === connectionDialog_1.ConnectionInputMode.Parameters ||
            this.state.selectedInputMode === connectionDialog_1.ConnectionInputMode.AzureBrowse) {
            return this.state.connectionComponents.mainOptions;
        }
        return ["connectionString", "profileName"];
    }
    getFormComponent(propertyName) {
        return this.getActiveFormComponents().includes(propertyName)
            ? this.state.connectionComponents.components[propertyName]
            : undefined;
    }
    getAccounts() {
        return __awaiter(this, void 0, void 0, function* () {
            let accounts = [];
            try {
                accounts =
                    yield this._mainController.azureAccountService.getAccounts();
                return accounts.map((account) => {
                    return {
                        displayName: account.displayInfo.displayName,
                        value: account.displayInfo.userId,
                    };
                });
            }
            catch (error) {
                console.error(`Error loading Azure accounts: ${(0, utils_1.getErrorMessage)(error)}`);
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadAzureAccountsForEntraAuth, error, false, // includeErrorMessage
                undefined, // errorCode
                undefined, // errorType
                undefined, // additionalProperties
                {
                    accountCount: accounts.length,
                    undefinedAccountCount: accounts.filter((x) => x === undefined).length,
                    undefinedDisplayInfoCount: accounts.filter((x) => x !== undefined && x.displayInfo === undefined).length,
                });
                return [];
            }
        });
    }
    getTenants(accountId) {
        return __awaiter(this, void 0, void 0, function* () {
            let tenants = [];
            try {
                const account = (yield this._mainController.azureAccountService.getAccounts()).find((account) => { var _a; return ((_a = account.displayInfo) === null || _a === void 0 ? void 0 : _a.userId) === accountId; });
                if (!account) {
                    return [];
                }
                tenants = account.properties.tenants;
                if (!tenants) {
                    return [];
                }
                return tenants.map((tenant) => {
                    return {
                        displayName: tenant.displayName,
                        value: tenant.id,
                    };
                });
            }
            catch (error) {
                console.error(`Error loading Azure tenants: ${(0, utils_1.getErrorMessage)(error)}`);
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadAzureTenantsForEntraAuth, error, false, // includeErrorMessage
                undefined, // errorCode
                undefined, // errorType
                undefined, // additionalProperties
                {
                    tenant: tenants.length,
                    undefinedTenantCount: tenants.filter((x) => x === undefined)
                        .length,
                });
                return [];
            }
        });
    }
    convertToFormComponent(connOption) {
        switch (connOption.valueType) {
            case "boolean":
                return {
                    propertyName: connOption.name,
                    label: connOption.displayName,
                    required: connOption.isRequired,
                    type: form_1.FormItemType.Checkbox,
                    tooltip: connOption.description,
                };
            case "string":
                return {
                    propertyName: connOption.name,
                    label: connOption.displayName,
                    required: connOption.isRequired,
                    type: form_1.FormItemType.Input,
                    tooltip: connOption.description,
                };
            case "password":
                return {
                    propertyName: connOption.name,
                    label: connOption.displayName,
                    required: connOption.isRequired,
                    type: form_1.FormItemType.Password,
                    tooltip: connOption.description,
                };
            case "number":
                return {
                    propertyName: connOption.name,
                    label: connOption.displayName,
                    required: connOption.isRequired,
                    type: form_1.FormItemType.Input,
                    tooltip: connOption.description,
                };
            case "category":
                return {
                    propertyName: connOption.name,
                    label: connOption.displayName,
                    required: connOption.isRequired,
                    type: form_1.FormItemType.Dropdown,
                    tooltip: connOption.description,
                    options: connOption.categoryValues.map((v) => {
                        var _a;
                        return {
                            displayName: (_a = v.displayName) !== null && _a !== void 0 ? _a : v.name, // Use name if displayName is not provided
                            value: v.name,
                        };
                    }),
                };
            default:
                const error = `Unhandled connection option type: ${connOption.valueType}`;
                ConnectionDialogWebviewController._logger.log(error);
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadConnectionProperties, new Error(error), true);
        }
    }
    completeFormComponents(components) {
        return __awaiter(this, void 0, void 0, function* () {
            // Add additional components that are not part of the connection options
            components["profileName"] = {
                propertyName: "profileName",
                label: locConstants_1.ConnectionDialog.profileName,
                required: false,
                type: form_1.FormItemType.Input,
                isAdvancedOption: false,
            };
            components["savePassword"] = {
                propertyName: "savePassword",
                label: locConstants_1.ConnectionDialog.savePassword,
                required: false,
                type: form_1.FormItemType.Checkbox,
                isAdvancedOption: false,
            };
            components["accountId"] = {
                propertyName: "accountId",
                label: locConstants_1.ConnectionDialog.azureAccount,
                required: true,
                type: form_1.FormItemType.Dropdown,
                options: yield this.getAccounts(),
                placeholder: locConstants_1.ConnectionDialog.selectAnAccount,
                actionButtons: yield this.getAzureActionButtons(),
                validate: (value) => {
                    if (this.state.connectionProfile.authenticationType ===
                        connectionDialog_1.AuthenticationType.AzureMFA &&
                        !value) {
                        return {
                            isValid: false,
                            validationMessage: locConstants_1.ConnectionDialog.azureAccountIsRequired,
                        };
                    }
                    return {
                        isValid: true,
                        validationMessage: "",
                    };
                },
                isAdvancedOption: false,
            };
            components["tenantId"] = {
                propertyName: "tenantId",
                label: locConstants_1.ConnectionDialog.tenantId,
                required: true,
                type: form_1.FormItemType.Dropdown,
                options: [],
                hidden: true,
                placeholder: locConstants_1.ConnectionDialog.selectATenant,
                validate: (value) => {
                    if (this.state.connectionProfile.authenticationType ===
                        connectionDialog_1.AuthenticationType.AzureMFA &&
                        !value) {
                        return {
                            isValid: false,
                            validationMessage: locConstants_1.ConnectionDialog.tenantIdIsRequired,
                        };
                    }
                    return {
                        isValid: true,
                        validationMessage: "",
                    };
                },
                isAdvancedOption: false,
            };
            components["connectionString"] = {
                type: form_1.FormItemType.TextArea,
                propertyName: "connectionString",
                label: locConstants_1.ConnectionDialog.connectionString,
                required: true,
                validate: (value) => {
                    if (this.state.selectedInputMode ===
                        connectionDialog_1.ConnectionInputMode.ConnectionString &&
                        !value) {
                        return {
                            isValid: false,
                            validationMessage: locConstants_1.ConnectionDialog.connectionStringIsRequired,
                        };
                    }
                    return {
                        isValid: true,
                        validationMessage: "",
                    };
                },
                isAdvancedOption: false,
            };
            // add missing validation functions for generated components
            components["server"].validate = (value) => {
                if (this.state.connectionProfile.authenticationType ===
                    connectionDialog_1.AuthenticationType.SqlLogin &&
                    !value) {
                    return {
                        isValid: false,
                        validationMessage: locConstants_1.ConnectionDialog.usernameIsRequired,
                    };
                }
                return {
                    isValid: true,
                    validationMessage: "",
                };
            };
            components["user"].validate = (value) => {
                if (this.state.connectionProfile.authenticationType ===
                    connectionDialog_1.AuthenticationType.SqlLogin &&
                    !value) {
                    return {
                        isValid: false,
                        validationMessage: locConstants_1.ConnectionDialog.usernameIsRequired,
                    };
                }
                return {
                    isValid: true,
                    validationMessage: "",
                };
            };
        });
    }
    generateConnectionComponents() {
        return __awaiter(this, void 0, void 0, function* () {
            // get list of connection options from Tools Service
            const capabilitiesResult = yield this._mainController.connectionManager.client.sendRequest(connection_1.GetCapabilitiesRequest.type, {});
            const connectionOptions = capabilitiesResult.capabilities.connectionProvider.options;
            const result = {}; // force empty record for intial blank state
            for (const option of connectionOptions) {
                try {
                    result[option.name] = Object.assign(Object.assign({}, this.convertToFormComponent(option)), { isAdvancedOption: !this._mainOptionNames.has(option.name), optionCategory: option.groupName });
                }
                catch (err) {
                    console.error(`Error loading connection option '${option.name}': ${(0, utils_1.getErrorMessage)(err)}`);
                    (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadConnectionProperties, err, true, // includeErrorMessage
                    undefined, // errorCode
                    undefined, // errorType
                    {
                        connectionOptionName: option.name,
                    });
                }
            }
            yield this.completeFormComponents(result);
            return result;
        });
    }
    groupAdvancedOptions({ components, mainOptions, topAdvancedOptions, }) {
        const result = {};
        for (const component of Object.values(components)) {
            if (component.isAdvancedOption &&
                !mainOptions.includes(component.propertyName) &&
                !topAdvancedOptions.includes(component.propertyName)) {
                if (!result[component.optionCategory]) {
                    result[component.optionCategory] = [component.propertyName];
                }
                else {
                    result[component.optionCategory].push(component.propertyName);
                }
            }
        }
        return result;
    }
    validateConnectionProfile(connectionProfile, propertyName) {
        return __awaiter(this, void 0, void 0, function* () {
            let errorCount = 0;
            if (propertyName) {
                const component = this.getFormComponent(propertyName);
                if (component && component.validate) {
                    component.validation = component.validate(connectionProfile[propertyName]);
                    if (!component.validation.isValid) {
                        return 1;
                    }
                }
            }
            else {
                this.getActiveFormComponents()
                    .map((x) => this.state.connectionComponents.components[x])
                    .forEach((c) => {
                    if (c.hidden) {
                        c.validation = {
                            isValid: true,
                            validationMessage: "",
                        };
                        return;
                    }
                    else {
                        if (c.validate) {
                            c.validation = c.validate(connectionProfile[c.propertyName]);
                            if (!c.validation.isValid) {
                                errorCount++;
                            }
                        }
                    }
                });
            }
            return errorCount;
        });
    }
    getAzureActionButtons() {
        return __awaiter(this, void 0, void 0, function* () {
            const actionButtons = [];
            actionButtons.push({
                label: locConstants_1.ConnectionDialog.signIn,
                id: "azureSignIn",
                callback: () => __awaiter(this, void 0, void 0, function* () {
                    const account = yield this._mainController.azureAccountService.addAccount();
                    const accountsComponent = this.getFormComponent("accountId");
                    if (accountsComponent) {
                        accountsComponent.options = yield this.getAccounts();
                        this.state.connectionProfile.accountId = account.key.id;
                        this.updateState();
                        yield this.handleAzureMFAEdits("accountId");
                    }
                }),
            });
            if (this.state.connectionProfile.authenticationType ===
                connectionDialog_1.AuthenticationType.AzureMFA &&
                this.state.connectionProfile.accountId) {
                const account = (yield this._mainController.azureAccountService.getAccounts()).find((account) => account.displayInfo.userId ===
                    this.state.connectionProfile.accountId);
                if (account) {
                    const session = yield this._mainController.azureAccountService.getAccountSecurityToken(account, undefined);
                    const isTokenExpired = azureController_1.AzureController.isTokenInValid(session.token, session.expiresOn);
                    if (isTokenExpired) {
                        actionButtons.push({
                            label: locConstants_1.refreshTokenLabel,
                            id: "refreshToken",
                            callback: () => __awaiter(this, void 0, void 0, function* () {
                                const account = (yield this._mainController.azureAccountService.getAccounts()).find((account) => account.displayInfo.userId ===
                                    this.state.connectionProfile.accountId);
                                if (account) {
                                    const session = yield this._mainController.azureAccountService.getAccountSecurityToken(account, undefined);
                                    ConnectionDialogWebviewController._logger.log("Token refreshed", session.expiresOn);
                                }
                            }),
                        });
                    }
                }
            }
            return actionButtons;
        });
    }
    handleAzureMFAEdits(propertyName) {
        return __awaiter(this, void 0, void 0, function* () {
            const mfaComponents = [
                "accountId",
                "tenantId",
                "authenticationType",
            ];
            if (mfaComponents.includes(propertyName)) {
                if (this.state.connectionProfile.authenticationType !==
                    connectionDialog_1.AuthenticationType.AzureMFA) {
                    return;
                }
                const accountComponent = this.getFormComponent("accountId");
                const tenantComponent = this.getFormComponent("tenantId");
                let tenants = [];
                switch (propertyName) {
                    case "accountId":
                        tenants = yield this.getTenants(this.state.connectionProfile.accountId);
                        if (tenantComponent) {
                            tenantComponent.options = tenants;
                            if (tenants && tenants.length > 0) {
                                this.state.connectionProfile.tenantId =
                                    tenants[0].value;
                            }
                        }
                        accountComponent.actionButtons =
                            yield this.getAzureActionButtons();
                        break;
                    case "tenantId":
                        break;
                    case "authenticationType":
                        const firstOption = accountComponent.options[0];
                        if (firstOption) {
                            this.state.connectionProfile.accountId =
                                firstOption.value;
                        }
                        tenants = yield this.getTenants(this.state.connectionProfile.accountId);
                        if (tenantComponent) {
                            tenantComponent.options = tenants;
                            if (tenants && tenants.length > 0) {
                                this.state.connectionProfile.tenantId =
                                    tenants[0].value;
                            }
                        }
                        accountComponent.actionButtons =
                            yield this.getAzureActionButtons();
                        break;
                }
            }
        });
    }
    clearFormError() {
        this.state.formError = "";
        for (const component of this.getActiveFormComponents().map((x) => this.state.connectionComponents.components[x])) {
            component.validation = undefined;
        }
    }
    registerRpcHandlers() {
        this.registerReducer("setConnectionInputType", (state, payload) => __awaiter(this, void 0, void 0, function* () {
            this.state.selectedInputMode = payload.inputMode;
            yield this.updateItemVisibility();
            this.updateState();
            if (this.state.selectedInputMode ===
                connectionDialog_1.ConnectionInputMode.AzureBrowse) {
                yield this.loadAllAzureServers(state);
            }
            return state;
        }));
        this.registerReducer("formAction", (state, payload) => __awaiter(this, void 0, void 0, function* () {
            if (payload.event.isAction) {
                const component = this.getFormComponent(payload.event.propertyName);
                if (component && component.actionButtons) {
                    const actionButton = component.actionButtons.find((b) => b.id === payload.event.value);
                    if (actionButton === null || actionButton === void 0 ? void 0 : actionButton.callback) {
                        yield actionButton.callback();
                    }
                }
            }
            else {
                this.state.connectionProfile[payload.event.propertyName
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                ] = payload.event.value;
                yield this.validateConnectionProfile(this.state.connectionProfile, payload.event.propertyName);
                yield this.handleAzureMFAEdits(payload.event.propertyName);
            }
            yield this.updateItemVisibility();
            return state;
        }));
        this.registerReducer("loadConnection", (state, payload) => __awaiter(this, void 0, void 0, function* () {
            (0, telemetry_2.sendActionEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadConnection);
            this._connectionToEditCopy = structuredClone(payload.connection);
            this.clearFormError();
            this.state.connectionProfile = payload.connection;
            this.state.selectedInputMode = this._connectionToEditCopy
                .connectionString
                ? connectionDialog_1.ConnectionInputMode.ConnectionString
                : connectionDialog_1.ConnectionInputMode.Parameters;
            yield this.updateItemVisibility();
            yield this.handleAzureMFAEdits("azureAuthType");
            yield this.handleAzureMFAEdits("accountId");
            return state;
        }));
        this.registerReducer("connect", (state) => __awaiter(this, void 0, void 0, function* () {
            this.clearFormError();
            this.state.connectionStatus = webview_1.ApiStatus.Loading;
            this.state.formError = "";
            this.updateState();
            const cleanedConnection = structuredClone(this.state.connectionProfile);
            this.cleanConnection(cleanedConnection); // clean the connection by clearing the options that aren't being used
            // Perform final validation of all inputs
            const errorCount = yield this.validateConnectionProfile(cleanedConnection);
            if (errorCount > 0) {
                this.state.connectionStatus = webview_1.ApiStatus.Error;
                return state;
            }
            try {
                try {
                    const result = yield this._mainController.connectionManager.connectionUI.validateAndSaveProfileFromDialog(
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    cleanedConnection);
                    if (result.errorMessage) {
                        if (result.errorNumber ===
                            connectionConstants_1.connectionCertValidationFailedErrorCode) {
                            this.state.connectionStatus = webview_1.ApiStatus.Error;
                            this.state.trustServerCertError =
                                result.errorMessage;
                            // connection failing because the user didn't trust the server cert is not an error worth logging;
                            // just prompt the user to trust the cert
                            return state;
                        }
                        this.state.formError = result.errorMessage;
                        this.state.connectionStatus = webview_1.ApiStatus.Error;
                        (0, telemetry_2.sendActionEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.CreateConnection, {
                            result: "connectionError",
                            errorNumber: String(result.errorNumber),
                            newOrEditedConnection: this
                                ._connectionToEditCopy
                                ? "edited"
                                : "new",
                            connectionInputType: this.state.selectedInputMode,
                            authMode: this.state.connectionProfile
                                .authenticationType,
                        });
                        return state;
                    }
                }
                catch (error) {
                    this.state.formError = (0, utils_1.getErrorMessage)(error);
                    this.state.connectionStatus = webview_1.ApiStatus.Error;
                    (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.CreateConnection, error, false, // includeErrorMessage
                    undefined, // errorCode
                    undefined, // errorType
                    {
                        connectionInputType: this.state.selectedInputMode,
                        authMode: this.state.connectionProfile.authenticationType,
                    });
                    return state;
                }
                (0, telemetry_2.sendActionEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.CreateConnection, {
                    result: "success",
                    newOrEditedConnection: this._connectionToEditCopy
                        ? "edited"
                        : "new",
                    connectionInputType: this.state.selectedInputMode,
                    authMode: this.state.connectionProfile.authenticationType,
                });
                if (this._connectionToEditCopy) {
                    yield this._mainController.connectionManager.getUriForConnection(this._connectionToEditCopy);
                    yield this._objectExplorerProvider.removeConnectionNodes([
                        this._connectionToEditCopy,
                    ]);
                    yield this._mainController.connectionManager.connectionStore.removeProfile(
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    this._connectionToEditCopy);
                    this._objectExplorerProvider.refresh(undefined);
                }
                yield this._mainController.connectionManager.connectionUI.saveProfile(
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                this.state.connectionProfile);
                const node = yield this._mainController.createObjectExplorerSessionFromDialog(this.state.connectionProfile);
                this._objectExplorerProvider.refresh(undefined);
                yield this.updateLoadedConnections(state);
                this.updateState();
                this.state.connectionStatus = webview_1.ApiStatus.Loaded;
                yield this._mainController.objectExplorerTree.reveal(node, {
                    focus: true,
                    select: true,
                    expand: true,
                });
                yield this.panel.dispose();
                yield userSurvey_1.UserSurvey.getInstance().promptUserForNPSFeedback();
            }
            catch (error) {
                this.state.connectionStatus = webview_1.ApiStatus.Error;
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.CreateConnection, error, undefined, // includeErrorMessage
                undefined, // errorCode
                undefined, // errorType
                {
                    connectionInputType: this.state.selectedInputMode,
                    authMode: this.state.connectionProfile.authenticationType,
                });
                return state;
            }
            return state;
        }));
        this.registerReducer("loadAzureServers", (state, payload) => __awaiter(this, void 0, void 0, function* () {
            yield this.loadAzureServersForSubscription(state, payload.subscriptionId);
            return state;
        }));
        this.registerReducer("cancelTrustServerCertDialog", (state) => __awaiter(this, void 0, void 0, function* () {
            state.trustServerCertError = undefined;
            return state;
        }));
        this.registerReducer("filterAzureSubscriptions", (state) => __awaiter(this, void 0, void 0, function* () {
            yield (0, azureHelper_1.promptForAzureSubscriptionFilter)(state);
            yield this.loadAllAzureServers(state);
            return state;
        }));
        this.registerReducer("refreshConnectionsList", (state) => __awaiter(this, void 0, void 0, function* () {
            yield this.updateLoadedConnections(state);
            return state;
        }));
        this.registerReducer("deleteSavedConnection", (state, payload) => __awaiter(this, void 0, void 0, function* () {
            const confirm = yield vscode.window.showQuickPick([locConstants_1.Common.delete, locConstants_1.Common.cancel], {
                title: locConstants_1.Common.areYouSureYouWantTo(locConstants_1.ConnectionDialog.deleteTheSavedConnection(payload.connection.displayName)),
            });
            if (confirm !== locConstants_1.Common.delete) {
                return state;
            }
            const success = yield this._mainController.connectionManager.connectionStore.removeProfile(payload.connection);
            if (success) {
                yield this.updateLoadedConnections(state);
            }
            return state;
        }));
        this.registerReducer("removeRecentConnection", (state, payload) => __awaiter(this, void 0, void 0, function* () {
            yield this._mainController.connectionManager.connectionStore.removeRecentlyUsed(payload.connection);
            yield this.updateLoadedConnections(state);
            return state;
        }));
    }
    //#region Helpers
    //#region Azure helpers
    loadAzureSubscriptions(state) {
        return __awaiter(this, void 0, void 0, function* () {
            let endActivity;
            try {
                const auth = yield (0, azureHelper_1.confirmVscodeAzureSignin)();
                if (!auth) {
                    state.formError = vscode_1.l10n.t("Azure sign in failed.");
                    return undefined;
                }
                state.loadingAzureSubscriptionsStatus = webview_1.ApiStatus.Loading;
                this.updateState();
                // getSubscriptions() below checks this config setting if filtering is specified.  If the user has this set, then we use it; if not, we get all subscriptions.
                // The specific vscode config setting it uses is hardcoded into the VS Code Azure SDK, so we need to use the same value here.
                const shouldUseFilter = vscode.workspace
                    .getConfiguration()
                    .get(azureHelper_1.azureSubscriptionFilterConfigKey) !== undefined;
                endActivity = (0, telemetry_2.startActivity)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadAzureSubscriptions);
                this._azureSubscriptions = new Map((yield auth.getSubscriptions(shouldUseFilter)).map((s) => [
                    s.subscriptionId,
                    s,
                ]));
                const tenantSubMap = this.groupBy(Array.from(this._azureSubscriptions.values()), "tenantId"); // TODO: replace with Object.groupBy once ES2024 is supported
                const subs = [];
                for (const t of tenantSubMap.keys()) {
                    for (const s of tenantSubMap.get(t)) {
                        subs.push({
                            id: s.subscriptionId,
                            name: s.name,
                            loaded: false,
                        });
                    }
                }
                state.azureSubscriptions = subs;
                state.loadingAzureSubscriptionsStatus = webview_1.ApiStatus.Loaded;
                endActivity.end(telemetry_1.ActivityStatus.Succeeded, undefined, // additionalProperties
                {
                    subscriptionCount: subs.length,
                });
                this.updateState();
                return tenantSubMap;
            }
            catch (error) {
                state.formError = vscode_1.l10n.t("Error loading Azure subscriptions.");
                state.loadingAzureSubscriptionsStatus = webview_1.ApiStatus.Error;
                console.error(state.formError + "\n" + (0, utils_1.getErrorMessage)(error));
                endActivity.endFailed(error, false);
                return undefined;
            }
        });
    }
    loadAllAzureServers(state) {
        return __awaiter(this, void 0, void 0, function* () {
            const endActivity = (0, telemetry_2.startActivity)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadAzureServers);
            try {
                const tenantSubMap = yield this.loadAzureSubscriptions(state);
                if (!tenantSubMap) {
                    return;
                }
                if (tenantSubMap.size === 0) {
                    state.formError = vscode_1.l10n.t("No subscriptions available.  Adjust your subscription filters to try again.");
                }
                else {
                    state.loadingAzureServersStatus = webview_1.ApiStatus.Loading;
                    state.azureServers = [];
                    this.updateState();
                    const promiseArray = [];
                    for (const t of tenantSubMap.keys()) {
                        for (const s of tenantSubMap.get(t)) {
                            promiseArray.push(this.loadAzureServersForSubscription(state, s.subscriptionId));
                        }
                    }
                    yield Promise.all(promiseArray);
                    endActivity.end(telemetry_1.ActivityStatus.Succeeded, undefined, // additionalProperties
                    {
                        subscriptionCount: promiseArray.length,
                    });
                    state.loadingAzureServersStatus = webview_1.ApiStatus.Loaded;
                    return;
                }
            }
            catch (error) {
                state.formError = vscode_1.l10n.t("Error loading Azure databases.");
                state.loadingAzureServersStatus = webview_1.ApiStatus.Error;
                console.error(state.formError + "\n" + (0, utils_1.getErrorMessage)(error));
                endActivity.endFailed(error, false);
                return;
            }
        });
    }
    loadAzureServersForSubscription(state, subscriptionId) {
        return __awaiter(this, void 0, void 0, function* () {
            const azSub = this._azureSubscriptions.get(subscriptionId);
            const stateSub = state.azureSubscriptions.find((s) => s.id === subscriptionId);
            try {
                const servers = yield (0, azureHelper_1.fetchServersFromAzure)(azSub);
                state.azureServers.push(...servers);
                stateSub.loaded = true;
                this.updateState();
                console.log(`Loaded ${servers.length} servers for subscription ${azSub.name} (${azSub.subscriptionId})`);
            }
            catch (error) {
                console.error(locConstants_1.ConnectionDialog.errorLoadingAzureDatabases(azSub.name, azSub.subscriptionId), +"\n" + (0, utils_1.getErrorMessage)(error));
                (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadAzureServers, error, true, // includeErrorMessage
                undefined, // errorCode
                undefined);
            }
        });
    }
    //#endregion
    groupBy(values, key) {
        return values.reduce((rv, x) => {
            const keyValue = x[key];
            if (!rv.has(keyValue)) {
                rv.set(keyValue, []);
            }
            rv.get(keyValue).push(x);
            return rv;
        }, new Map());
    }
    /** Cleans up a connection profile by clearing the properties that aren't being used
     * (e.g. due to form selections, like authType and inputMode) */
    cleanConnection(connection) {
        // Clear values for inputs that are hidden due to form selections
        for (const option of Object.values(this.state.connectionComponents.components)) {
            if (option.hidden) {
                connection[option.propertyName
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                ] = undefined;
            }
        }
        // Clear values for inputs that are not applicable due to the selected input mode
        if (this.state.selectedInputMode === connectionDialog_1.ConnectionInputMode.Parameters ||
            this.state.selectedInputMode === connectionDialog_1.ConnectionInputMode.AzureBrowse) {
            connection.connectionString = undefined;
        }
        else if (this.state.selectedInputMode ===
            connectionDialog_1.ConnectionInputMode.ConnectionString) {
            Object.keys(connection).forEach((key) => {
                if (key !== "connectionString" && key !== "profileName") {
                    connection[key] = undefined;
                }
            });
        }
    }
    loadConnections() {
        return __awaiter(this, void 0, void 0, function* () {
            const unsortedConnections = this._mainController.connectionManager.connectionStore.loadAllConnections(true /* addRecentConnections */);
            const savedConnections = unsortedConnections
                .filter((c) => c.quickPickItemType ===
                interfaces_1.CredentialsQuickPickItemType.Profile)
                .map((c) => c.connectionCreds);
            const recentConnections = unsortedConnections
                .filter((c) => c.quickPickItemType === interfaces_1.CredentialsQuickPickItemType.Mru)
                .map((c) => c.connectionCreds);
            (0, telemetry_2.sendActionEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadRecentConnections, undefined, // additionalProperties
            {
                savedConnectionsCount: savedConnections.length,
                recentConnectionsCount: recentConnections.length,
            });
            return {
                recentConnections: yield Promise.all(recentConnections
                    .map((conn) => {
                    try {
                        return this.initializeConnectionForDialog(conn);
                    }
                    catch (ex) {
                        console.error("Error initializing recent connection: " +
                            (0, utils_1.getErrorMessage)(ex));
                        (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadConnections, ex, false, // includeErrorMessage
                        undefined, // errorCode
                        undefined, // errorType
                        {
                            connectionType: "recent",
                            authType: conn.authenticationType,
                        });
                        return Promise.resolve(undefined);
                    }
                })
                    .filter((c) => c !== undefined)),
                savedConnections: yield Promise.all(savedConnections
                    .map((conn) => {
                    try {
                        return this.initializeConnectionForDialog(conn);
                    }
                    catch (ex) {
                        console.error("Error initializing saved connection: " +
                            (0, utils_1.getErrorMessage)(ex));
                        (0, telemetry_2.sendErrorEvent)(telemetry_1.TelemetryViews.ConnectionDialog, telemetry_1.TelemetryActions.LoadConnections, ex, false, // includeErrorMessage
                        undefined, // errorCode
                        undefined, // errorType
                        {
                            connectionType: "saved",
                            authType: conn.authenticationType,
                        });
                        return Promise.resolve(undefined);
                    }
                })
                    .filter((c) => c !== undefined)),
            };
        });
    }
    updateLoadedConnections(state) {
        return __awaiter(this, void 0, void 0, function* () {
            const loadedConnections = yield this.loadConnections();
            state.recentConnections = loadedConnections.recentConnections;
            state.savedConnections = loadedConnections.savedConnections;
        });
    }
}
exports.ConnectionDialogWebviewController = ConnectionDialogWebviewController;

//# sourceMappingURL=connectionDialogWebviewController.js.map
