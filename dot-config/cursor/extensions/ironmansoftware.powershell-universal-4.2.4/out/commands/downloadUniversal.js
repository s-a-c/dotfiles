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
exports.downloadUniversalCommand = exports.downloadUniversal = void 0;
const vscode = require("vscode");
const os = require('os');
const https = require('https');
const fs = require('fs');
const temp = require('temp');
var AdmZip = require('adm-zip');
const path = require('path');
const settings_1 = require("./../settings");
exports.downloadUniversal = () => __awaiter(void 0, void 0, void 0, function* () {
    temp.track();
    let platform = '';
    switch (os.platform()) {
        case 'darwin':
            platform = 'osx';
            break;
        case 'linux':
            platform = 'linux';
            break;
        case 'win32':
            platform = 'win7';
            break;
        default:
            vscode.window.showErrorMessage("Unsupported platform");
            return;
    }
    return new Promise((resolve, reject) => {
        https.get('https://imsreleases.blob.core.windows.net/universal/production/version.txt', (resp) => {
            let data = '';
            // A chunk of data has been recieved.
            resp.on('data', (chunk) => {
                data += chunk;
            });
            // The whole response has been received. Print out the result.
            resp.on('end', () => {
                temp.open('universal', function (err, info) {
                    const file = fs.createWriteStream(info.path);
                    file.on('finish', function () {
                        file.close();
                        const universalPath = path.join(process.env.APPDATA, "PowerShellUniversal");
                        var zip = new AdmZip(info.path);
                        zip.extractAllTo(universalPath, true);
                        settings_1.SetServerPath(path.join(process.env.APPDATA, "PowerShellUniversal")).then(() => resolve(null));
                    });
                    https.get(`https://imsreleases.blob.core.windows.net/universal/production/${data}/Universal.${platform}-x64.${data}.zip`, function (response) {
                        response.pipe(file);
                    });
                });
            });
        }).on("error", (err) => {
            vscode.window.showErrorMessage(err.message);
            reject();
        });
    });
});
exports.downloadUniversalCommand = () => {
    return vscode.commands.registerCommand('powershell-universal.downloadUniversal', exports.downloadUniversal);
};
//# sourceMappingURL=downloadUniversal.js.map