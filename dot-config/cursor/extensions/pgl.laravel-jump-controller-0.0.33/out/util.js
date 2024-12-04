'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLineNumber = exports.getFilePath = exports.LaravelControllerLink = void 0;
const vscode_1 = require("vscode");
const fs = require("fs");
const readLine = require("n-readlines");
class LaravelControllerLink extends vscode_1.DocumentLink {
    constructor(range, path, controllerName, funcName) {
        super(range, null);
        this.filePath = path;
        this.controllerName = controllerName;
        this.funcName = funcName;
    }
}
exports.LaravelControllerLink = LaravelControllerLink;
var pathCtrl = vscode_1.workspace.getConfiguration('laravel_jump_controller').pathController; // default settings or user settings
pathCtrl = pathCtrl ? pathCtrl : 'app/Http/Controllers';
// get pathNamespace from config.json
let pathNamespace = vscode_1.workspace.getConfiguration('laravel_jump_controller').pathNamespace;
pathNamespace = pathNamespace ? pathNamespace : 'App\\Http\\Controllers';
/**
 * Finds the controler's filepath
 * @param text
 * @param document
 */
function getFilePath(text, document, composerAutoLoadPSR) {
    let workspaceFolder = vscode_1.workspace.getWorkspaceFolder(document.uri).uri.fsPath;
    let controllerFileName = text + '.php';
    // replace the http controllers namespace to empty string
    if (controllerFileName.indexOf(pathNamespace) === 0) {
        controllerFileName = controllerFileName.slice((pathNamespace + '\\').replace(/\\\\/g, '\\').length);
    }
    if (controllerFileName.charAt(0) === "\\") {
        for (let _i in composerAutoLoadPSR) {
            if (controllerFileName.indexOf('\\' + _i) === 0) {
                controllerFileName = controllerFileName.slice(_i.length + 1 /** include the leading backslash */);
                controllerFileName = (composerAutoLoadPSR[_i] + '/').replace(/\/\//g, '/') + controllerFileName;
                break;
            }
        }
    }
    else {
        controllerFileName = (pathCtrl + '/').replace(/\/\//g, '/') + controllerFileName;
    }
    controllerFileName = controllerFileName.replace(/\\/g, '/');
    let targetPath = (workspaceFolder + '/' + controllerFileName).replace(/\/\//g, '/');
    if (fs.existsSync(targetPath)) {
        return targetPath;
    }
    let dirItems = fs.readdirSync(workspaceFolder);
    for (let item of dirItems) {
        targetPath = workspaceFolder + '/' + item + '/' + controllerFileName;
        if (fs.existsSync(targetPath)) {
            return targetPath;
        }
    }
    return null;
}
exports.getFilePath = getFilePath;
function getLineNumber(text, path) {
    let file = new readLine(path);
    let lineNum = 0;
    let line;
    while (line = file.next()) {
        lineNum++;
        line = line.toString();
        if (line.toLowerCase().includes('function ' + text.toLowerCase() + '(')) {
            return lineNum;
        }
    }
    return -1;
}
exports.getLineNumber = getLineNumber;
//# sourceMappingURL=util.js.map