"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthenticationType = exports.ConnectionInputMode = exports.ConnectionDialogWebviewState = void 0;
class ConnectionDialogWebviewState {
    /** The underlying connection profile for the form target; a more intuitively-named alias for `formState` */
    get connectionProfile() {
        return this.formState;
    }
    set connectionProfile(value) {
        this.formState = value;
    }
    constructor({ connectionProfile, selectedInputMode, connectionComponents, azureSubscriptions, azureServers, savedConnections, recentConnections, connectionStatus, formError, loadingAzureSubscriptionsStatus, loadingAzureServersStatus, trustServerCertError, }) {
        this.formState = connectionProfile;
        this.selectedInputMode = selectedInputMode;
        this.connectionComponents = connectionComponents;
        this.azureSubscriptions = azureSubscriptions;
        this.azureServers = azureServers;
        this.savedConnections = savedConnections;
        this.recentConnections = recentConnections;
        this.connectionStatus = connectionStatus;
        this.formError = formError;
        this.loadingAzureSubscriptionsStatus = loadingAzureSubscriptionsStatus;
        this.loadingAzureServersStatus = loadingAzureServersStatus;
        this.trustServerCertError = trustServerCertError;
    }
}
exports.ConnectionDialogWebviewState = ConnectionDialogWebviewState;
var ConnectionInputMode;
(function (ConnectionInputMode) {
    ConnectionInputMode["Parameters"] = "parameters";
    ConnectionInputMode["ConnectionString"] = "connectionString";
    ConnectionInputMode["AzureBrowse"] = "azureBrowse";
})(ConnectionInputMode || (exports.ConnectionInputMode = ConnectionInputMode = {}));
var AuthenticationType;
(function (AuthenticationType) {
    AuthenticationType["SqlLogin"] = "SqlLogin";
    AuthenticationType["Integrated"] = "Integrated";
    AuthenticationType["AzureMFA"] = "AzureMFA";
})(AuthenticationType || (exports.AuthenticationType = AuthenticationType = {}));

//# sourceMappingURL=connectionDialog.js.map
