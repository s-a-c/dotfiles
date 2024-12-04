"use strict";
const vscode = require("vscode");
const lst = require("vscode-languageserver-types");
const css = require("vscode-css-languageservice");
const path = require("path");
const fs = require("fs");
const models_1 = require("../models");
class ClassProvider {
    constructor(context, configurationManager, stylesheetManager) {
        this.context = context;
        this.configurationManager = configurationManager;
        this.stylesheetManager = stylesheetManager;
        this.cssLanguageService = css.getSCSSLanguageService();
        this.dot = vscode.CompletionItemKind.Class;
        this.hash = vscode.CompletionItemKind.Reference;
        this.glob = '**/*.scss';
        this.regex = [
            /(class|\[class\]|\[id\]|id|\[ngClass\])=["|']([^"^']*$)/i,
            /<style[\s\S]*>([\s\S]*)<\/style>/ig
        ];
        this.initialize();
        configurationManager.setConfigChangeListener(() => this.onConfigurationChange());
    }
    provideCompletionItems(document, position, token) {
        let start = new vscode.Position(0, 0);
        let range = new vscode.Range(start, position);
        let text = document.getText(range);
        let tag = this.regex[0].exec(text);
        if (tag) {
            let internal = new Array();
            let style;
            while (style = this.regex[1].exec(document.getText())) {
                let snippet = new models_1.Snippet(style[1], this.cssLanguageService);
                let symbols = this.cssLanguageService.findDocumentSymbols(snippet.document, snippet.stylesheet);
                for (let symbol of symbols) {
                    internal.push(symbol);
                }
            }
            this.pushSymbols('style', internal);
            let items = {};
            for (let key in this.stylesheetManager.globalMap) {
                for (let item of this.stylesheetManager.globalMap[key]) {
                    items[item.label] = item;
                }
            }
            for (let key in this.stylesheetManager.localMap) {
                for (let item of this.stylesheetManager.localMap[key]) {
                    items[item.label] = item;
                }
            }
            let id = tag[0].startsWith('id') || tag[0].startsWith('#');
            let ci = new Array();
            for (let item in items) {
                if ((id && items[item].kind === this.hash) || !id && items[item].kind === this.dot) {
                    ci.push(items[item]);
                }
            }
            return new vscode.CompletionList(ci);
        }
        return null;
    }
    resolveCompletionItem(item, token) {
        return null;
    }
    initialize() {
        if (vscode.workspace.rootPath) {
            this.configuration = this.configurationManager.getConfiguration();
            if (!this.configuration.globalStyles) {
                this.findGlobalFiles();
            }
            else {
                this.getGlobalStylesheets();
            }
            if (this.configuration.isAngularProject) {
                this.initializeAngularProject();
            }
        }
    }
    findGlobalFiles() {
        vscode.workspace.findFiles(this.glob, '').then((uris) => {
            for (let i = 0; i < uris.length; i++) {
                this.stylesheetManager.globalStyleSheets[uris[i].fsPath] = [];
                this.parse(uris[i], true);
            }
        });
        this.setGlobalWatcher();
    }
    pushSymbols(key, symbols, isGlobal = false) {
        let regex = /[\.\#]([\w-]+)/g;
        let ci = new Array();
        for (let i = 0; i < symbols.length; i++) {
            if (symbols[i].kind !== 5) {
                continue;
            }
            let symbol;
            while (symbol = regex.exec(symbols[i].name)) {
                let item = new vscode.CompletionItem(symbol[1]);
                item.kind = symbol[0].startsWith('.') ? this.dot : this.hash;
                item.detail = path.basename(key);
                ci.push(item);
            }
        }
        if (isGlobal) {
            this.stylesheetManager.globalMap[key] = ci;
        }
        else {
            this.stylesheetManager.localMap[key] = ci;
        }
    }
    parse(uri, isGlobal = false, callback) {
        fs.readFile(uri.fsPath, 'utf8', (err, data) => {
            if (err) {
                delete this.stylesheetManager.globalMap[uri.fsPath];
                if (callback) {
                    callback(false);
                }
            }
            else {
                let doc = lst.TextDocument.create(uri.fsPath, 'scss', 1, data);
                let parsedDoc = this.cssLanguageService.parseStylesheet(doc);
                this.findImports(doc, isGlobal);
                let symbols = this.cssLanguageService.findDocumentSymbols(doc, parsedDoc);
                this.pushSymbols(uri.fsPath, symbols, isGlobal);
                if (callback) {
                    callback(true);
                }
            }
        });
    }
    findImports(doc, isGlobal) {
        let imports = doc.getText().match(/@import '([^;]*)';/g);
        if (!imports) {
            return;
        }
        let currentDir = doc.uri.substring(0, doc.uri.lastIndexOf('\\'));
        imports.forEach(imp => {
            let relativePath = imp.match(/'(.*)'/).pop();
            this.parseImport(currentDir, relativePath, doc.uri, isGlobal);
            let _relativePath;
            if (relativePath.indexOf('/_') === -1) {
                _relativePath = [relativePath.slice(0, relativePath.lastIndexOf('/') + 1), '_', relativePath.slice(relativePath.lastIndexOf('/') + 1)].join('');
            }
            if (_relativePath) {
                this.parseImport(currentDir, _relativePath, doc.uri, isGlobal);
            }
        });
    }
    getLocalClasses(htmlUri) {
        // Clear local map
        this.stylesheetManager.localMap = {};
        let filePath = htmlUri.fsPath.replace(/\.[^/.]+$/, '');
        filePath += '.scss';
        let scssUri = vscode.Uri.file(filePath);
        this.parse(scssUri);
    }
    getGlobalStylesheets() {
        if (this.configuration.globalStyles.length === 0) {
            return;
        }
        for (let styleSheetPath of this.configuration.globalStyles) {
            let uri = vscode.Uri.file(path.resolve(vscode.workspace.rootPath, styleSheetPath));
            this.stylesheetManager.globalStyleSheets[uri.fsPath] = [];
            this.parse(uri, true);
        }
        this.setGlobalWatcher();
    }
    setGlobalWatcher() {
        this.globalWatcher = vscode.workspace.createFileSystemWatcher(this.glob);
        this.globalWatcher.onDidCreate(uri => {
            if (Object.keys(this.stylesheetManager.globalStyleSheets).length === 0 || this.stylesheetManager.globalStyleSheets[uri.fsPath] || this.stylesheetManager.globalImports[uri.fsPath]) {
                this.parse(uri, true);
            }
        });
        this.globalWatcher.onDidChange(uri => {
            if (Object.keys(this.stylesheetManager.globalStyleSheets).length === 0 || this.stylesheetManager.globalStyleSheets[uri.fsPath] || this.stylesheetManager.globalImports[uri.fsPath]) {
                this.parse(uri, true);
            }
        });
        this.globalWatcher.onDidDelete(uri => {
            delete this.stylesheetManager.globalMap[uri.fsPath];
        });
        this.context.subscriptions.push(this.globalWatcher);
    }
    initializeAngularProject() {
        if (vscode.window.activeTextEditor) {
            let currentDocument = vscode.window.activeTextEditor.document;
            if (currentDocument.languageId === 'html' || 'typescript') {
                this.getLocalClasses(currentDocument.uri);
            }
        }
        this.setFileOpenListener();
    }
    setFileOpenListener() {
        this.fileOpenListener = vscode.workspace.onDidOpenTextDocument(document => {
            let fileExtension = document.fileName.split('.').pop();
            if (fileExtension === 'html' || fileExtension === 'ts') {
                this.getLocalClasses(document.uri);
            }
        });
        this.context.subscriptions.push(this.fileOpenListener);
    }
    parseImport(currentDir, relativePath, parent, isGlobal) {
        let filePath = path.resolve(currentDir, relativePath + '.scss');
        let uri = vscode.Uri.file(filePath);
        if (this.stylesheetManager.globalImports[uri.fsPath]) {
            return;
        }
        this.parse(uri, isGlobal, succes => {
            if (succes && isGlobal) {
                let existingImport = this.stylesheetManager.globalImports[uri.fsPath];
                if (!existingImport) {
                    this.stylesheetManager.globalImports[uri.fsPath] = parent;
                }
                let parentSheetImports = this.stylesheetManager.globalStyleSheets[parent];
                if (parentSheetImports) {
                    parentSheetImports.push(uri.fsPath);
                }
                else {
                }
            }
        });
    }
    onConfigurationChange() {
        this.stylesheetManager.globalMap = {};
        this.stylesheetManager.localMap = {};
        this.stylesheetManager.globalStyleSheets = {};
        this.stylesheetManager.globalImports = {};
        if (this.globalWatcher) {
            this.globalWatcher.dispose();
        }
        if (this.fileOpenListener) {
            this.fileOpenListener.dispose();
        }
        this.initialize();
    }
}
exports.ClassProvider = ClassProvider;
//# sourceMappingURL=class.provider.js.map