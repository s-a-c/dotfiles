"use strict";
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
exports.Universal = void 0;
const vscode = require("vscode");
const axios_1 = require("axios");
const settings_1 = require("./settings");
const container_1 = require("./container");
const https = require('https');
class Universal {
    constructor(context) {
        this.context = context;
    }
    hasConnection() {
        const settings = settings_1.load();
        if (settings.appToken === '' && settings.connections.length === 0) {
            return false;
        }
        return true;
    }
    request(path, method, data = null, contentType = 'application/json') {
        const settings = settings_1.load();
        const connectionName = this.context.globalState.get("universal.connection");
        if (!this.hasConnection()) {
            return;
        }
        var appToken = settings.appToken;
        var url = settings.url;
        var rejectUnauthorized = true;
        var windowsAuth = false;
        if (connectionName && connectionName !== 'Default') {
            const connection = settings.connections.find(m => m.name === connectionName);
            if (connection) {
                appToken = connection.appToken;
                url = connection.url;
                rejectUnauthorized = !connection.allowInvalidCertificate;
            }
        }
        https.globalAgent.options.rejectUnauthorized = true;
        const agent = new https.Agent({
            rejectUnauthorized
        });
        return axios_1.default({
            url: `${url}${path}`,
            method,
            headers: {
                authorization: windowsAuth ? null : `Bearer ${appToken}`,
                'Content-Type': contentType
            },
            data: data,
            httpsAgent: agent
        });
    }
    getVersion() {
        return new Promise((resolve) => {
            var _a;
            (_a = this.request('/api/v1/version', 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                resolve("failed");
            });
        });
    }
    getReleasedVersion() {
        return __awaiter(this, void 0, void 0, function* () {
            const response = yield axios_1.default.get("https://imsreleases.blob.core.windows.net/universal/production/version.txt");
            return response === null || response === void 0 ? void 0 : response.data;
        });
    }
    installAndLoadModule() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const settings = settings_1.load();
                if (settings.checkModules) {
                    const version = yield container_1.Container.universal.getVersion();
                    var appToken = settings.appToken;
                    var url = settings.url;
                    const connectionName = this.context.globalState.get("universal.connection");
                    if (connectionName && connectionName !== 'Default') {
                        const connection = settings.connections.find(m => m.name === connectionName);
                        if (connection) {
                            appToken = connection.appToken;
                            url = connection.url;
                        }
                    }
                    if (!vscode.window.terminals.find(x => x.name === "PowerShell Extension")) {
                        container_1.Container.connected = true;
                        return;
                    }
                    container_1.Container.universal.sendTerminalCommand(`Import-Module (Join-Path '${__dirname}' 'Universal.VSCode.psm1')`);
                    container_1.Container.universal.sendTerminalCommand(`Install-UniversalModule -Version '${version}'`);
                    container_1.Container.universal.sendTerminalCommand(`Connect-PSUServer -ComputerName '${url}' -AppToken '${appToken}'`);
                    container_1.Container.connected = true;
                }
            }
            catch (_a) {
            }
        });
    }
    isAlive(url) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                yield axios_1.default({
                    url: `${url}/api/v1/alive`,
                    method: "get"
                });
                return true;
            }
            catch (_a) { }
            return false;
        });
    }
    waitForAlive() {
        return __awaiter(this, void 0, void 0, function* () {
            const settings = settings_1.load();
            var retries = 0;
            const connectionName = this.context.globalState.get("universal.connection");
            var url = settings.url;
            if (connectionName && connectionName !== 'Default') {
                const connection = settings.connections.find(m => m.name === connectionName);
                if (connection) {
                    url = connection.url;
                }
            }
            let disposable = vscode.window.setStatusBarMessage(`Attempting to connect to PowerShell Universal at ${url}`);
            while (retries < 60) {
                if (yield this.isAlive(url)) {
                    disposable.dispose();
                    return true;
                }
                retries++;
            }
            vscode.window.showWarningMessage(`Failed to connect to PowerShell Universal. Ensure that the server is running on ${settings.url}.`);
            disposable.dispose();
            return false;
        });
    }
    grantAppToken() {
        return __awaiter(this, void 0, void 0, function* () {
            const settings = settings_1.load();
            const connectionName = this.context.globalState.get("universal.connection");
            var url = settings.url;
            if (connectionName && connectionName !== 'Default') {
                const connection = settings.connections.find(m => m.name === connectionName);
                if (connection) {
                    url = connection.url;
                }
            }
            const transport = axios_1.default.create({
                withCredentials: true
            });
            var response = yield transport.post(`${url}/api/v1/signin`, {
                username: 'admin',
                password: 'admin'
            });
            if (response.data.errorMessage && response.data.errorMessage !== '') {
                var result = yield vscode.window.showErrorMessage("We couldn't generate an App Token automatically. You will have to do it manually.", "View Admin Console");
                if (result === "View Admin Console") {
                    vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/settings/security`));
                }
                return false;
            }
            const [cookie] = response.headers["set-cookie"];
            transport.defaults.headers.Cookie = cookie;
            const appToken = yield transport.get(`${url}/api/v1/appToken/grant`, {
                headers: {
                    Cookie: cookie
                }
            });
            yield settings_1.SetAppToken(appToken.data.token);
            return true;
        });
    }
    addDashboard() {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request('/api/v1/dashboard', 'POST')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    addDashboardPage(dashboardId, page) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${dashboardId}/page`, 'POST', page)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    deleteDashboardPage(dashboardId, pageId) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${dashboardId}/page/${pageId}`, 'DELETE')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    startDashboard(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}/status`, 'PUT')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    stopDashboard(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}/status`, 'DELETE')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDashboard(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDashboardPages(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}/page`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDashboardPage(dashboardId, id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${dashboardId}/page/${id}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDashboardDiagnostics(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}/diagnostics`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDashboardLog(name) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/logging/log/file?feature=app&resource=${name}&take=1000`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDashboards() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve([]);
            }
            (_a = this.request('/api/v1/dashboard', 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    saveDashboard(id, dashboard) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}`, 'PUT', dashboard)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    saveDashboardPage(id, dashboardId, page) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${dashboardId}/page/${id}`, 'PUT', page)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    executeDashboardTerminal(dashboardId, sessionId, pageId, command) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${dashboardId}/terminal/${sessionId}/${pageId}`, 'POST', {
                command
            })) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getDiagnostics(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/dashboard/${id}/diagnostics`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getEndpoints() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve([]);
            }
            (_a = this.request('/api/v1/endpoint', 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getJob(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/job/${id}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getJobLog(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/job/${id}/log`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getScripts() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve([]);
            }
            (_a = this.request('/api/v1/script', 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    newTerminalInstance(terminal) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request('/api/v1/terminal/instance', 'POST', terminal)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    stopTerminalInstance(terminalInstanceId) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/terminal/instance/${terminalInstanceId}`, 'DELETE')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    executeTerminalCommand(terminalInstanceId, command) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/terminal/instance/${terminalInstanceId}`, 'POST', JSON.stringify(command))) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getTerminals() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve([]);
            }
            (_a = this.request('/api/v1/terminal', 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getTerminalInstances() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve([]);
            }
            (_a = this.request(`/api/v1/terminal/instance`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getJobs() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve({
                    page: []
                });
            }
            (_a = this.request('/api/v1/job?take=50&orderBy=Id&orderDirection=Descending', 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getScript(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/script/${id}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getScriptFilePath(filePath) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/script/path/${filePath}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    saveScript(script) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/script/`, 'PUT', script)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getScriptParameters(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/script/${id}/parameter`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    runScript(id) {
        return new Promise((resolve, reject) => {
            var _a;
            const jobContext = {};
            (_a = this.request(`/api/v1/script/${id}`, 'POST', jobContext)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    refreshConfig() {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration`, 'POST')) === null || _a === void 0 ? void 0 : _a.then(() => resolve(null)).catch(x => {
                reject(x.message);
            });
        });
    }
    getSettings() {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/settings`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data[0])).catch(x => {
                reject(x.message);
            });
        });
    }
    getConfigurations() {
        return new Promise((resolve, reject) => {
            var _a;
            if (!this.hasConnection()) {
                resolve([]);
            }
            (_a = this.request(`/api/v1/configuration/list`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getEndpoint(endpoint) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/endpoint/${endpoint.id}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject();
            });
        });
    }
    saveEndpoint(endpoint) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/endpoint/${endpoint.id}`, 'PUT', endpoint)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    newModule(name) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/module`, 'POST', {
                name,
                version: '1.0.0'
            })) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                resolve({});
            });
        });
    }
    updateModule(module) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/module/${module.id}`, 'PUT', module)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                resolve({});
            });
        });
    }
    getModules() {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/module`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                resolve([]);
            });
        });
    }
    getModule(id) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/module/${id}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject();
            });
        });
    }
    getRepositories() {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/module/repository`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                resolve([]);
            });
        });
    }
    getConfiguration(fileName) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/${fileName}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                resolve('');
            });
        });
    }
    saveConfiguration(fileName, data) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/${fileName}`, 'PUT', data)) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    saveFileContent(fileName, data) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/content/${fileName}`, 'PUT', {
                content: data
            })) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x.message);
            });
        });
    }
    getFileContent(fileName) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/content/${fileName}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x);
            });
        });
    }
    getFiles(fileName) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/list/${fileName}`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x);
            });
        });
    }
    newFile(fileName) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/item/`, 'POST', {
                fullName: fileName,
                isLeaf: true
            })) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x);
            });
        });
    }
    newFolder(folderName) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/configuration/item/`, 'POST', {
                fullName: folderName,
                isLeaf: false
            })) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x);
            });
        });
    }
    sendTerminalCommand(command) {
        var terminal = vscode.window.terminals.find(x => x.name === "PowerShell Extension");
        if (terminal == null) {
            vscode.window.showErrorMessage("PowerShell Terminal is missing!");
        }
        terminal === null || terminal === void 0 ? void 0 : terminal.sendText(command, true);
    }
    getProcesses() {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/diagnostics/processes`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data)).catch(x => {
                reject(x);
            });
        });
    }
    getRunspaces(processId) {
        return new Promise((resolve, reject) => {
            var _a;
            (_a = this.request(`/api/v1/diagnostics/processes/${processId}/runspaces`, 'GET')) === null || _a === void 0 ? void 0 : _a.then(x => resolve(x.data.map((y) => { return Object.assign(Object.assign({}, y), { processId }); }))).catch(x => {
                reject(x);
            });
        });
    }
    connectUniversal(url) {
        axios_1.default.get(url).then(x => {
            settings_1.SetUrl(x.data.url);
            settings_1.SetAppToken(x.data.appToken);
            vscode.window.showInformationMessage(`You are connected to ${x.data.url}`);
            container_1.Container.connected = false;
            vscode.commands.executeCommand('powershell-universal.refreshAllTreeViews');
        }).catch(() => {
            vscode.window.showErrorMessage('Failed to connect to Universal.');
        });
    }
    showConnectionError(message) {
        return __awaiter(this, void 0, void 0, function* () {
            const result = yield vscode.window.showErrorMessage(message + " This is a connection error. Click Settings to adjust your connection settings or App Tokens to generate a new token.", "Settings", "App Tokens");
            if (result === 'Settings') {
                vscode.commands.executeCommand('workbench.action.openSettings', "PowerShell Universal");
            }
            if (result === 'App Tokens') {
                const settings = settings_1.load();
                const connectionName = this.context.globalState.get("universal.connection");
                var url = settings.url;
                if (connectionName && connectionName !== 'Default') {
                    const connection = settings.connections.find(m => m.name === connectionName);
                    if (connection) {
                        url = connection.url;
                    }
                }
                vscode.env.openExternal(vscode.Uri.parse(`${url}/admin/security/tokens`));
            }
        });
    }
}
exports.Universal = Universal;
//# sourceMappingURL=universal.js.map