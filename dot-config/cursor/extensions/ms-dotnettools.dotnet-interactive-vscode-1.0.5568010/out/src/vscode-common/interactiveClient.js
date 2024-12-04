"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
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
exports.InteractiveClient = void 0;
const commandsAndEvents_1 = require("./polyglot-notebooks/commandsAndEvents");
const utilities_1 = require("./utilities");
const compositeKernel_1 = require("./polyglot-notebooks/compositeKernel");
const kernelHost_1 = require("./polyglot-notebooks/kernelHost");
const connection = require("./polyglot-notebooks/connection");
class InteractiveClient {
    constructor(config) {
        this.config = config;
        this.disposables = [];
        this.nextExecutionCount = 1;
        this.nextOutputId = 1;
        this.nextToken = 1;
        this.tokenEventObservers = new Map();
        this.deferredOutput = [];
        this._kernel = new compositeKernel_1.CompositeKernel("vscode");
        this._kernelHost = new kernelHost_1.KernelHost(this._kernel, config.channel.sender, config.channel.receiver, "kernel://vscode");
        config.channel.receiver.subscribe({
            next: (envelope) => {
                if (connection.isKernelEventEnvelope(envelope)) {
                    this.eventListener(envelope);
                    if (envelope.eventType === commandsAndEvents_1.KernelInfoProducedType) {
                        const kernelInfoProduced = envelope.event;
                        connection.ensureOrUpdateProxyForKernelInfo(kernelInfoProduced.kernelInfo, this._kernel);
                    }
                }
            }
        });
        for (const kernelInfo of config.kernelInfos) {
            const remoteHostUri = connection.extractHostAndNomalize(kernelInfo.isProxy ? kernelInfo.remoteUri : kernelInfo.uri);
            this._kernelHost.defaultConnector.addRemoteHostUri(remoteHostUri);
            connection.ensureOrUpdateProxyForKernelInfo(kernelInfo, this._kernel);
        }
        this._kernelHost.connect();
    }
    get kernel() {
        return this._kernel;
    }
    get kernelHost() {
        return this._kernelHost;
    }
    get channel() {
        return this.config.channel;
    }
    tryGetProperty(propertyName) {
        try {
            return (this.config.channel[propertyName]);
        }
        catch (_a) {
            return null;
        }
    }
    clearExistingLanguageServiceRequests(requestId) {
        (0, utilities_1.clearDebounce)(requestId);
        (0, utilities_1.clearDebounce)(`completion-${requestId}`);
        (0, utilities_1.clearDebounce)(`diagnostics-${requestId}`);
        (0, utilities_1.clearDebounce)(`hover-${requestId}`);
        (0, utilities_1.clearDebounce)(`sighelp-${requestId}`);
    }
    execute(source, cell, outputReporter, diagnosticObserver, configuration) {
        if (configuration !== undefined && configuration.id !== undefined) {
            this.clearExistingLanguageServiceRequests(configuration.id);
        }
        return new Promise((resolve, reject) => {
            var _a;
            let diagnostics = [];
            let reportDiagnostics = () => {
                diagnosticObserver(diagnostics);
            };
            let failureReported = false;
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.SubmitCodeType, {
                code: source,
                targetKernelName: cell.kernelName,
                parameters: {
                    cellIndex: (_a = cell.index) === null || _a === void 0 ? void 0 : _a.toString()
                }
            });
            const commandToken = command.getOrCreateToken();
            try {
                return this.submitCode(command, eventEnvelope => {
                    var _a, _b, _c;
                    if (this.deferredOutput.length > 0) {
                        for (const output of this.deferredOutput) {
                            outputReporter(output);
                        }
                        this.deferredOutput = [];
                    }
                    switch (eventEnvelope.eventType) {
                        // if kernel languages were added, handle those events here
                        case commandsAndEvents_1.CommandSucceededType:
                            if (((_a = eventEnvelope.command) === null || _a === void 0 ? void 0 : _a.getToken()) === commandToken) {
                                // only complete this promise if it's the root command
                                resolve(!failureReported);
                            }
                            break;
                        case commandsAndEvents_1.CommandFailedType:
                            {
                                if (((_b = eventEnvelope.command) === null || _b === void 0 ? void 0 : _b.getToken()) === commandToken) {
                                    const err = eventEnvelope.event;
                                    const errorOutput = this.config.createErrorOutput(err.message, this.getNextOutputId());
                                    outputReporter(errorOutput);
                                    failureReported = true;
                                    // only complete this promise if it's the root command
                                    reject(err);
                                }
                            }
                            break;
                        case commandsAndEvents_1.ErrorProducedType: {
                            const err = eventEnvelope.event;
                            const errorOutput = this.config.createErrorOutput(err.message, this.getNextOutputId());
                            outputReporter(errorOutput);
                            failureReported = true;
                        }
                        case commandsAndEvents_1.DiagnosticsProducedType:
                            {
                                const diags = eventEnvelope.event;
                                diagnostics.push(...((_c = diags.diagnostics) !== null && _c !== void 0 ? _c : []));
                                reportDiagnostics();
                            }
                            break;
                        case commandsAndEvents_1.StandardErrorValueProducedType:
                        case commandsAndEvents_1.StandardOutputValueProducedType:
                            {
                                const disp = eventEnvelope.event;
                                const stream = eventEnvelope.eventType === commandsAndEvents_1.StandardErrorValueProducedType ? 'stderr' : 'stdout';
                                const output = this.displayEventToCellOutput(disp, stream);
                                if (output) {
                                    outputReporter(output);
                                }
                            }
                            break;
                        case commandsAndEvents_1.DisplayedValueProducedType:
                        case commandsAndEvents_1.DisplayedValueUpdatedType:
                        case commandsAndEvents_1.ReturnValueProducedType:
                            {
                                const disp = eventEnvelope.event;
                                const output = this.displayEventToCellOutput(disp);
                                if (output) {
                                    outputReporter(output);
                                }
                            }
                            break;
                    }
                }).catch(e => {
                    // only report a failure if it's not a `CommandFailed` event from above (which has already called `reject()`)
                    if (!failureReported) {
                        const errorMessage = typeof (e === null || e === void 0 ? void 0 : e.message) === 'string' ? e.message : '' + e;
                        const errorOutput = this.config.createErrorOutput(errorMessage, this.getNextOutputId());
                        outputReporter(errorOutput);
                        reject(e);
                    }
                });
            }
            catch (e) {
                reject(e);
            }
        });
    }
    completion(kernelName, code, line, character) {
        return __awaiter(this, void 0, void 0, function* () {
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.RequestCompletionsType, {
                code: code,
                linePosition: {
                    line,
                    character
                },
                targetKernelName: kernelName
            });
            let result = yield this.submitCommandAndGetResult(command, commandsAndEvents_1.CompletionsProducedType, true);
            if (result === undefined) {
                result = {
                    completions: []
                };
            }
            return result;
        });
    }
    hover(language, code, line, character) {
        return __awaiter(this, void 0, void 0, function* () {
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.RequestHoverTextType, {
                code: code,
                linePosition: {
                    line: line,
                    character: character,
                },
                targetKernelName: language
            });
            let result = yield this.submitCommandAndGetResult(command, commandsAndEvents_1.HoverTextProducedType, true);
            if (result === undefined) {
                result = {
                    content: []
                };
            }
            return result;
        });
    }
    signatureHelp(language, code, line, character) {
        return __awaiter(this, void 0, void 0, function* () {
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.RequestSignatureHelpType, {
                code,
                linePosition: {
                    line,
                    character
                },
                targetKernelName: language
            });
            let result = yield this.submitCommandAndGetResult(command, commandsAndEvents_1.SignatureHelpProducedType, true);
            if (result === undefined) {
                result = {
                    activeParameterIndex: 0,
                    activeSignatureIndex: 0,
                    signatures: []
                };
            }
            return result;
        });
    }
    getDiagnostics(kernelName, code) {
        return __awaiter(this, void 0, void 0, function* () {
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.RequestDiagnosticsType, {
                code,
                targetKernelName: kernelName
            });
            let diagsProduced = yield this.submitCommandAndGetResult(command, commandsAndEvents_1.DiagnosticsProducedType, true);
            if (diagsProduced === undefined) {
                return [];
            }
            return diagsProduced.diagnostics;
        });
    }
    submitCode(command, observer) {
        return __awaiter(this, void 0, void 0, function* () {
            if (command.commandType !== commandsAndEvents_1.SubmitCodeType) {
                throw new Error(`Commandm ust be SubmitCpde.`);
            }
            let disposable = this.subscribeToKernelTokenEvents(command.getOrCreateToken(), observer);
            try {
                yield this.submitCommand(command);
            }
            catch (error) {
                return Promise.reject(error);
            }
            return disposable;
        });
    }
    requestValueInfos(kernelName) {
        return __awaiter(this, void 0, void 0, function* () {
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.RequestValueInfosType, {
                targetKernelName: kernelName,
                mimeType: "text/plain+summary"
            });
            const result = yield (this.submitCommandAndGetResult(command, commandsAndEvents_1.ValueInfosProducedType));
            return result;
        });
    }
    requestValue(valueName, kernelName) {
        return __awaiter(this, void 0, void 0, function* () {
            const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.RequestValueType, {
                name: valueName,
                mimeType: 'text/plain',
                targetKernelName: kernelName,
            });
            const result = yield this.submitCommandAndGetResult(command, commandsAndEvents_1.ValueProducedType);
            return result;
        });
    }
    cancel() {
        const command = new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.CancelType, {});
        return this.submitCommand(command);
    }
    dispose() {
        this.config.channel.sender.send(new commandsAndEvents_1.KernelCommandEnvelope(commandsAndEvents_1.QuitType, {}));
        this.config.channel.dispose();
        for (let disposable of this.disposables) {
            disposable();
        }
    }
    registerForDisposal(disposable) {
        this.disposables.push(disposable);
    }
    submitCommandAndGetResult(command, expectedEventType, eventIsOptional = false) {
        return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
            let handled = false;
            const token = command.getOrCreateToken();
            const rootToken = commandsAndEvents_1.KernelCommandEnvelope.getRootToken(token);
            let disposable = this.subscribeToKernelTokenEvents(rootToken, eventEnvelope => {
                var _a, _b;
                if ((_a = eventEnvelope.command) === null || _a === void 0 ? void 0 : _a.hasSameRootCommandAs(command)) {
                    let isRootCommand = ((_b = eventEnvelope.command) === null || _b === void 0 ? void 0 : _b.getToken()) === rootToken;
                    switch (eventEnvelope.eventType) {
                        case commandsAndEvents_1.CommandFailedType:
                            if (!handled && isRootCommand) {
                                handled = true;
                                let err = eventEnvelope.event;
                                reject(err);
                                disposable.dispose();
                            }
                            break;
                        case commandsAndEvents_1.CommandSucceededType:
                            if (!handled && isRootCommand) {
                                handled = true;
                                if (eventIsOptional) {
                                    resolve(undefined);
                                }
                                else {
                                    reject('Command was handled before reporting expected result.');
                                }
                                disposable.dispose();
                            }
                            break;
                        default:
                            if (eventEnvelope.eventType === expectedEventType) {
                                handled = true;
                                let event = eventEnvelope.event;
                                resolve(event);
                                disposable.dispose();
                            }
                            break;
                    }
                }
            });
            yield this.config.channel.sender.send(command);
        }));
    }
    submitCommand(command) {
        return new Promise((resolve, reject) => {
            let failureReported = false;
            const token = command.getOrCreateToken();
            let disposable = this.subscribeToKernelTokenEvents(token, eventEnvelope => {
                var _a, _b;
                switch (eventEnvelope.eventType) {
                    case commandsAndEvents_1.CommandFailedType:
                        let err = eventEnvelope.event;
                        failureReported = true;
                        if (((_a = eventEnvelope.command) === null || _a === void 0 ? void 0 : _a.getToken()) === token) {
                            disposable.dispose();
                            reject(err);
                        }
                        break;
                    case commandsAndEvents_1.CommandSucceededType:
                        if (((_b = eventEnvelope.command) === null || _b === void 0 ? void 0 : _b.getToken()) === token) {
                            disposable.dispose();
                            resolve();
                        }
                        break;
                    default:
                        break;
                }
            });
            try {
                this.config.channel.sender
                    .send(command)
                    .catch(e => {
                    // only report a failure if it's not a `CommandFailed` event from above (which has already called `reject()`)
                    if (!failureReported) {
                        reject(e);
                    }
                });
            }
            catch (error) {
                reject(error);
            }
        });
    }
    subscribeToKernelTokenEvents(commandToken, observer) {
        var _a;
        const token = commandsAndEvents_1.KernelCommandEnvelope.getRootToken(commandToken);
        if (!this.tokenEventObservers.get(token)) {
            this.tokenEventObservers.set(token, []);
        }
        (_a = this.tokenEventObservers.get(token)) === null || _a === void 0 ? void 0 : _a.push(observer);
        return {
            dispose: () => {
                let listeners = this.tokenEventObservers.get(token);
                if (listeners) {
                    let i = listeners.indexOf(observer);
                    if (i >= 0) {
                        listeners.splice(i, 1);
                    }
                    if (listeners.length === 0) {
                        this.tokenEventObservers.delete(token);
                    }
                }
            }
        };
    }
    eventListener(eventEnvelope) {
        var _a;
        let token = (_a = eventEnvelope.command) === null || _a === void 0 ? void 0 : _a.getToken();
        if (token) {
            if (token.startsWith("deferredCommand::")) {
                switch (eventEnvelope.eventType) {
                    case commandsAndEvents_1.DisplayedValueProducedType:
                    case commandsAndEvents_1.DisplayedValueUpdatedType:
                    case commandsAndEvents_1.ReturnValueProducedType:
                        let disp = eventEnvelope.event;
                        let output = this.displayEventToCellOutput(disp);
                        if (output) {
                            this.deferredOutput.push(output);
                        }
                        break;
                }
            }
            else {
                const tokenParts = token.split('.');
                for (let i = tokenParts.length; i >= 1; i--) {
                    const candidateToken = tokenParts.slice(0, i).join('.');
                    let listeners = this.tokenEventObservers.get(candidateToken);
                    if (listeners) {
                        for (let listener of listeners) {
                            listener(eventEnvelope);
                        }
                    }
                }
            }
        }
    }
    displayEventToCellOutput(disp, stream) {
        var _a;
        const encoder = new TextEncoder();
        const outputItems = [];
        if (disp.formattedValues && disp.formattedValues.length > 0) {
            for (let formatted of disp.formattedValues) {
                if (!formatted.suppressDisplay) {
                    let data = this.IsEncodedMimeType(formatted.mimeType)
                        ? Buffer.from(formatted.value, 'base64')
                        : encoder.encode(formatted.value);
                    const outputItem = {
                        mime: formatted.mimeType,
                        data
                    };
                    if (stream) {
                        outputItem.stream = stream;
                    }
                    outputItems.push(outputItem);
                }
            }
        }
        if (outputItems.length === 0) {
            return null;
        }
        else {
            const outputId = (_a = disp.valueId) !== null && _a !== void 0 ? _a : this.getNextOutputId();
            const output = (0, utilities_1.createOutput)(outputItems, outputId);
            return output;
        }
    }
    IsEncodedMimeType(mimeType) {
        const encdodedMimetypes = new Set(["image/png", "image/jpeg", "image/gif"]);
        return encdodedMimetypes.has(mimeType);
    }
    resetExecutionCount() {
        this.nextExecutionCount = 1;
    }
    getNextExecutionCount() {
        const next = this.nextExecutionCount;
        this.nextExecutionCount++;
        return next;
    }
    getNextOutputId() {
        return (this.nextOutputId++).toString();
    }
}
exports.InteractiveClient = InteractiveClient;
//# sourceMappingURL=interactiveClient.js.map