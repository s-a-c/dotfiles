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
exports.azureSubscriptionFilterConfigKey = void 0;
exports.confirmVscodeAzureSignin = confirmVscodeAzureSignin;
exports.promptForAzureSubscriptionFilter = promptForAzureSubscriptionFilter;
exports.getQuickPickItems = getQuickPickItems;
exports.fetchServersFromAzure = fetchServersFromAzure;
const vscode = require("vscode");
const vscode_1 = require("vscode");
const utils_1 = require("../utils/utils");
const vscode_azext_azureauth_1 = require("@microsoft/vscode-azext-azureauth");
const arm_resources_1 = require("@azure/arm-resources");
exports.azureSubscriptionFilterConfigKey = "azureResourceGroups.selectedSubscriptions";
function confirmVscodeAzureSignin() {
    return __awaiter(this, void 0, void 0, function* () {
        const auth = new vscode_azext_azureauth_1.VSCodeAzureSubscriptionProvider();
        if (!(yield auth.isSignedIn())) {
            const result = yield auth.signIn();
            if (!result) {
                return undefined;
            }
        }
        return auth;
    });
}
function promptForAzureSubscriptionFilter(state) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const auth = yield confirmVscodeAzureSignin();
            if (!auth) {
                state.formError = vscode_1.l10n.t("Azure sign in failed.");
                return;
            }
            const selectedSubs = yield vscode.window.showQuickPick(getQuickPickItems(auth), {
                canPickMany: true,
                ignoreFocusOut: true,
                placeHolder: vscode_1.l10n.t("Select subscriptions"),
            });
            if (!selectedSubs) {
                return;
            }
            yield vscode.workspace.getConfiguration().update(exports.azureSubscriptionFilterConfigKey, selectedSubs.map((s) => `${s.tenantId}/${s.subscriptionId}`), vscode.ConfigurationTarget.Global);
        }
        catch (error) {
            state.formError = vscode_1.l10n.t("Error loading Azure subscriptions.");
            console.error(state.formError + "\n" + (0, utils_1.getErrorMessage)(error));
            return;
        }
    });
}
function getQuickPickItems(auth) {
    return __awaiter(this, void 0, void 0, function* () {
        var _a;
        const allSubs = yield auth.getSubscriptions(false /* don't use the current filter, 'cause we're gonna set it */);
        const prevSelectedSubs = (_a = vscode.workspace
            .getConfiguration()
            .get(exports.azureSubscriptionFilterConfigKey)) === null || _a === void 0 ? void 0 : _a.map((entry) => entry.split("/")[1]);
        const quickPickItems = allSubs
            .map((sub) => {
            return {
                label: `${sub.name} (${sub.subscriptionId})`,
                tenantId: sub.tenantId,
                subscriptionId: sub.subscriptionId,
                picked: prevSelectedSubs
                    ? prevSelectedSubs.includes(sub.subscriptionId)
                    : true,
            };
        })
            .sort((a, b) => a.label.localeCompare(b.label));
        return quickPickItems;
    });
}
const serverResourceType = "Microsoft.Sql/servers";
const databaseResourceType = "Microsoft.Sql/servers/databases";
const elasticPoolsResourceType = "Microsoft.Sql/servers/elasticpools";
function fetchServersFromAzure(sub) {
    return __awaiter(this, void 0, void 0, function* () {
        const result = [];
        const client = new arm_resources_1.ResourceManagementClient(sub.credential, sub.subscriptionId);
        // for some subscriptions, supplying a `resourceType eq 'Microsoft.Sql/servers/databases'` filter to list() causes an error:
        // > invalid filter in query string 'resourceType eq "Microsoft.Sql/servers/databases'"
        // no idea why, so we're fetching all resources and filtering them ourselves
        const resources = yield (0, utils_1.listAllIterator)(client.resources.list());
        const servers = resources.filter((r) => r.type === serverResourceType);
        const databases = resources.filter((r) => r.type === databaseResourceType ||
            r.type === elasticPoolsResourceType);
        for (const server of servers) {
            result.push({
                server: server.name,
                databases: [],
                location: server.location,
                resourceGroup: extractFromResourceId(server.id, "resourceGroups"),
                subscription: `${sub.name} (${sub.subscriptionId})`,
            });
        }
        for (const database of databases) {
            const serverName = extractFromResourceId(database.id, "servers");
            const server = result.find((s) => s.server === serverName);
            if (server) {
                server.databases.push(database.name.substring(serverName.length + 1)); // database.name is in the form 'serverName/databaseName', so we need to remove the server name and slash
            }
        }
        return result;
    });
}
function extractFromResourceId(resourceId, property) {
    if (!property.endsWith("/")) {
        property += "/";
    }
    let startIndex = resourceId.indexOf(property);
    if (startIndex === -1) {
        return undefined;
    }
    else {
        startIndex += property.length;
    }
    return resourceId.substring(startIndex, resourceId.indexOf("/", startIndex));
}

//# sourceMappingURL=azureHelper.js.map
