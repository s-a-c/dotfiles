"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeserializeNumberLiterals = exports.Deserialize = exports.SerializeNumberLiterals = exports.Serialize = exports.extractHostAndNomalize = exports.Connector = exports.updateKernelInfo = exports.isKernelInfoForProxy = exports.ensureOrUpdateProxyForKernelInfo = exports.registerForKernelInfoUpdates = exports.isArrayOfString = exports.isSetOfString = exports.KernelCommandAndEventSender = exports.KernelCommandAndEventReceiver = exports.isKernelEventEnvelopeModel = exports.isKernelEventEnvelope = exports.isKernelCommandEnvelopeModel = exports.isKernelCommandEnvelope = void 0;
const rxjs = require("rxjs");
const commandsAndEvents = require("./commandsAndEvents");
const logger_1 = require("./logger");
function isKernelCommandEnvelope(commandOrEvent) {
    return commandOrEvent.commandType !== undefined;
}
exports.isKernelCommandEnvelope = isKernelCommandEnvelope;
function isKernelCommandEnvelopeModel(commandOrEvent) {
    return commandOrEvent.commandType !== undefined;
}
exports.isKernelCommandEnvelopeModel = isKernelCommandEnvelopeModel;
function isKernelEventEnvelope(commandOrEvent) {
    return commandOrEvent.eventType !== undefined;
}
exports.isKernelEventEnvelope = isKernelEventEnvelope;
function isKernelEventEnvelopeModel(commandOrEvent) {
    return commandOrEvent.eventType !== undefined;
}
exports.isKernelEventEnvelopeModel = isKernelEventEnvelopeModel;
class KernelCommandAndEventReceiver {
    constructor(observer) {
        this._disposables = [];
        this._observable = observer;
    }
    subscribe(observer) {
        return this._observable.subscribe(observer);
    }
    dispose() {
        for (let disposable of this._disposables) {
            disposable.dispose();
        }
    }
    static FromObservable(observable) {
        return new KernelCommandAndEventReceiver(observable);
    }
    static FromEventListener(args) {
        let subject = new rxjs.Subject();
        const listener = (e) => {
            let mapped = args.map(e);
            subject.next(mapped);
        };
        args.eventTarget.addEventListener(args.event, listener);
        const ret = new KernelCommandAndEventReceiver(subject);
        ret._disposables.push({
            dispose: () => {
                args.eventTarget.removeEventListener(args.event, listener);
            }
        });
        args.eventTarget.removeEventListener(args.event, listener);
        return ret;
    }
}
exports.KernelCommandAndEventReceiver = KernelCommandAndEventReceiver;
function isObservable(source) {
    return source.next !== undefined;
}
class KernelCommandAndEventSender {
    constructor() {
    }
    send(kernelCommandOrEventEnvelope) {
        if (this._sender) {
            try {
                const clone = kernelCommandOrEventEnvelope.clone();
                if (typeof this._sender === "function") {
                    this._sender(clone);
                }
                else if (isObservable(this._sender)) {
                    if (isKernelCommandEnvelope(kernelCommandOrEventEnvelope)) {
                        this._sender.next(clone);
                    }
                    else {
                        this._sender.next(clone);
                    }
                }
                else {
                    return Promise.reject(new Error("Sender is not set"));
                }
            }
            catch (error) {
                return Promise.reject(error);
            }
            return Promise.resolve();
        }
        return Promise.reject(new Error("Sender is not set"));
    }
    static FromObserver(observer) {
        const sender = new KernelCommandAndEventSender();
        sender._sender = observer;
        return sender;
    }
    static FromFunction(send) {
        const sender = new KernelCommandAndEventSender();
        sender._sender = send;
        return sender;
    }
}
exports.KernelCommandAndEventSender = KernelCommandAndEventSender;
function isSetOfString(collection) {
    return typeof (collection) !== typeof (new Set());
}
exports.isSetOfString = isSetOfString;
function isArrayOfString(collection) {
    return Array.isArray(collection) && collection.length > 0 && typeof (collection[0]) === typeof ("");
}
exports.isArrayOfString = isArrayOfString;
const onKernelInfoUpdates = [];
function registerForKernelInfoUpdates(callback) {
    onKernelInfoUpdates.push(callback);
}
exports.registerForKernelInfoUpdates = registerForKernelInfoUpdates;
function notifyOfKernelInfoUpdates(compositeKernel) {
    for (const updater of onKernelInfoUpdates) {
        updater(compositeKernel);
    }
}
function ensureOrUpdateProxyForKernelInfo(kernelInfo, compositeKernel) {
    if (kernelInfo.isProxy) {
        const host = extractHostAndNomalize(kernelInfo.remoteUri);
        if (host === extractHostAndNomalize(compositeKernel.kernelInfo.uri)) {
            logger_1.Logger.default.warn(`skippin creation of proxy for a proxy kernel : [${JSON.stringify(kernelInfo)}]`);
            return;
        }
    }
    const uriToLookup = kernelInfo.isProxy ? kernelInfo.remoteUri : kernelInfo.uri;
    if (uriToLookup) {
        let kernel = compositeKernel.findKernelByUri(uriToLookup);
        if (!kernel) {
            // add
            if (compositeKernel.host) {
                logger_1.Logger.default.info(`creating proxy for uri[${uriToLookup}]with info ${JSON.stringify(kernelInfo)}`);
                // check for clash with `kernelInfo.localName`
                kernel = compositeKernel.host.connectProxyKernel(kernelInfo.localName, uriToLookup, kernelInfo.aliases);
                updateKernelInfo(kernel.kernelInfo, kernelInfo);
            }
            else {
                throw new Error('no kernel host found');
            }
        }
        else {
            logger_1.Logger.default.info(`patching proxy for uri[${uriToLookup}]with info ${JSON.stringify(kernelInfo)} `);
        }
        if (kernel.kernelInfo.isProxy) {
            // patch
            updateKernelInfo(kernel.kernelInfo, kernelInfo);
        }
        notifyOfKernelInfoUpdates(compositeKernel);
    }
}
exports.ensureOrUpdateProxyForKernelInfo = ensureOrUpdateProxyForKernelInfo;
function isKernelInfoForProxy(kernelInfo) {
    return kernelInfo.isProxy;
}
exports.isKernelInfoForProxy = isKernelInfoForProxy;
function updateKernelInfo(destination, source) {
    var _a, _b;
    destination.languageName = (_a = source.languageName) !== null && _a !== void 0 ? _a : destination.languageName;
    destination.languageVersion = (_b = source.languageVersion) !== null && _b !== void 0 ? _b : destination.languageVersion;
    destination.displayName = source.displayName;
    destination.isComposite = source.isComposite;
    if (destination.description === undefined || destination.description === null || destination.description.match(/^\s*$/)) {
        destination.description = source.description;
    }
    if (source.displayName) {
        destination.displayName = source.displayName;
    }
    const supportedCommands = new Set();
    if (!destination.supportedKernelCommands) {
        destination.supportedKernelCommands = [];
    }
    for (const supportedCommand of destination.supportedKernelCommands) {
        supportedCommands.add(supportedCommand.name);
    }
    for (const supportedCommand of source.supportedKernelCommands) {
        if (!supportedCommands.has(supportedCommand.name)) {
            supportedCommands.add(supportedCommand.name);
            destination.supportedKernelCommands.push(supportedCommand);
        }
    }
}
exports.updateKernelInfo = updateKernelInfo;
class Connector {
    constructor(configuration) {
        this._remoteUris = new Set();
        this._receiver = configuration.receiver;
        this._sender = configuration.sender;
        if (configuration.remoteUris) {
            for (const remoteUri of configuration.remoteUris) {
                const uri = extractHostAndNomalize(remoteUri);
                if (uri) {
                    this._remoteUris.add(uri);
                }
            }
        }
        this._listener = this._receiver.subscribe({
            next: (kernelCommandOrEventEnvelope) => {
                var _a;
                if (isKernelEventEnvelope(kernelCommandOrEventEnvelope)) {
                    if (kernelCommandOrEventEnvelope.eventType === commandsAndEvents.KernelInfoProducedType) {
                        const event = kernelCommandOrEventEnvelope.event;
                        if (!event.kernelInfo.remoteUri) {
                            const uri = extractHostAndNomalize(event.kernelInfo.uri);
                            if (uri) {
                                this._remoteUris.add(uri);
                            }
                        }
                    }
                    const eventRoutingSlip = kernelCommandOrEventEnvelope.routingSlip.toArray();
                    if (((_a = eventRoutingSlip.length) !== null && _a !== void 0 ? _a : 0) > 0) {
                        const eventOrigin = eventRoutingSlip[0];
                        const uri = extractHostAndNomalize(eventOrigin);
                        if (uri) {
                            this._remoteUris.add(uri);
                        }
                    }
                }
            }
        });
    }
    get remoteHostUris() {
        return Array.from(this._remoteUris.values());
    }
    get sender() {
        return this._sender;
    }
    get receiver() {
        return this._receiver;
    }
    addRemoteHostUri(remoteUri) {
        const uri = extractHostAndNomalize(remoteUri);
        if (uri) {
            this._remoteUris.add(uri);
        }
    }
    canReach(remoteUri) {
        const host = extractHostAndNomalize(remoteUri); //?
        if (host) {
            return this._remoteUris.has(host);
        }
        return false;
    }
    dispose() {
        this._listener.unsubscribe();
    }
}
exports.Connector = Connector;
function extractHostAndNomalize(kernelUri) {
    var _a;
    const filter = /(?<host>.+:\/\/[^\/]+)(\/[^\/])*/gi;
    const match = filter.exec(kernelUri); //?
    if ((_a = match === null || match === void 0 ? void 0 : match.groups) === null || _a === void 0 ? void 0 : _a.host) {
        const host = match.groups.host;
        return host; //?
    }
    return "";
}
exports.extractHostAndNomalize = extractHostAndNomalize;
function Serialize(source) {
    return JSON.stringify(source, function (key, value) {
        //handling NaN, Infinity and -Infinity
        const processed = SerializeNumberLiterals(value);
        return processed;
    });
}
exports.Serialize = Serialize;
function SerializeNumberLiterals(value) {
    if (value !== value) {
        return "NaN";
    }
    else if (value === Infinity) {
        return "Infinity";
    }
    else if (value === -Infinity) {
        return "-Infinity";
    }
    return value;
}
exports.SerializeNumberLiterals = SerializeNumberLiterals;
function Deserialize(json) {
    return JSON.parse(json, function (key, value) {
        //handling NaN, Infinity and -Infinity
        const deserialized = DeserializeNumberLiterals(value);
        return deserialized;
    });
}
exports.Deserialize = Deserialize;
function DeserializeNumberLiterals(value) {
    if (value === "NaN") {
        return NaN;
    }
    else if (value === "Infinity") {
        return Infinity;
    }
    else if (value === "-Infinity") {
        return -Infinity;
    }
    return value;
}
exports.DeserializeNumberLiterals = DeserializeNumberLiterals;
//# sourceMappingURL=connection.js.map