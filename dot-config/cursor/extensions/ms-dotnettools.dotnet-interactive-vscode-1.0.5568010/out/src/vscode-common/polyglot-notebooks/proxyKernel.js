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
exports.ProxyKernel = void 0;
const commandsAndEvents = require("./commandsAndEvents");
const logger_1 = require("./logger");
const kernel_1 = require("./kernel");
const connection = require("./connection");
const promiseCompletionSource_1 = require("./promiseCompletionSource");
class ProxyKernel extends kernel_1.Kernel {
    constructor(name, _sender, _receiver, languageName, languageVersion) {
        super(name, languageName, languageVersion);
        this.name = name;
        this._sender = _sender;
        this._receiver = _receiver;
        this.kernelInfo.isProxy = true;
    }
    getCommandHandler(commandType) {
        return {
            commandType,
            handle: (invocation) => {
                return this._commandHandler(invocation);
            }
        };
    }
    delegatePublication(envelope, invocationContext) {
        let alreadyBeenSeen = false;
        const kernelUri = (0, kernel_1.getKernelUri)(this);
        if (kernelUri && !envelope.routingSlip.contains(kernelUri)) {
            envelope.routingSlip.stamp(kernelUri);
        }
        else {
            alreadyBeenSeen = true;
        }
        if (this.hasSameOrigin(envelope)) {
            if (!alreadyBeenSeen) {
                invocationContext.publish(envelope);
            }
        }
    }
    hasSameOrigin(envelope) {
        var _a, _b, _c;
        let commandOriginUri = (_c = (_b = (_a = envelope.command) === null || _a === void 0 ? void 0 : _a.command) === null || _b === void 0 ? void 0 : _b.originUri) !== null && _c !== void 0 ? _c : this.kernelInfo.uri;
        if (commandOriginUri === this.kernelInfo.uri) {
            return true;
        }
        return commandOriginUri === null;
    }
    updateKernelInfoFromEvent(kernelInfoProduced) {
        connection.updateKernelInfo(this.kernelInfo, kernelInfoProduced.kernelInfo);
    }
    _commandHandler(commandInvocation) {
        var _a, _b;
        var _c, _d;
        return __awaiter(this, void 0, void 0, function* () {
            const commandToken = commandInvocation.commandEnvelope.getOrCreateToken();
            const completionSource = new promiseCompletionSource_1.PromiseCompletionSource();
            // fix : is this the right way? We are trying to avoid forwarding events we just did forward
            let eventSubscription = this._receiver.subscribe({
                next: (envelope) => {
                    var _a, _b, _c;
                    if (connection.isKernelEventEnvelope(envelope)) {
                        if (envelope.eventType === commandsAndEvents.KernelInfoProducedType &&
                            (envelope.command === null || envelope.command === undefined)) {
                            const kernelInfoProduced = envelope.event;
                            kernelInfoProduced.kernelInfo; //?
                            this.kernelInfo; //?
                            if (kernelInfoProduced.kernelInfo.uri === this.kernelInfo.remoteUri) {
                                this.updateKernelInfoFromEvent(kernelInfoProduced);
                                const event = new commandsAndEvents.KernelEventEnvelope(commandsAndEvents.KernelInfoProducedType, { kernelInfo: this.kernelInfo });
                                this.publishEvent(event);
                            }
                        }
                        else if (envelope.command.getToken() === commandToken) {
                            logger_1.Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] processing event, envelopeToken=${envelope.command.getToken()}, commandToken=${commandToken}`);
                            logger_1.Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] processing event, ${JSON.stringify(envelope)}`);
                            try {
                                const original = [...(_b = (_a = commandInvocation.commandEnvelope) === null || _a === void 0 ? void 0 : _a.routingSlip.toArray()) !== null && _b !== void 0 ? _b : []];
                                commandInvocation.commandEnvelope.routingSlip.continueWith(envelope.command.routingSlip);
                                //envelope.command!.routingSlip = [...commandInvocation.commandEnvelope.routingSlip ?? []];//?
                                logger_1.Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, command routingSlip :${original}] has changed to: ${JSON.stringify((_c = commandInvocation.commandEnvelope.routingSlip) !== null && _c !== void 0 ? _c : [])}`);
                            }
                            catch (e) {
                                logger_1.Logger.default.error(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, error ${e === null || e === void 0 ? void 0 : e.message}`);
                            }
                            switch (envelope.eventType) {
                                case commandsAndEvents.KernelInfoProducedType:
                                    {
                                        const kernelInfoProduced = envelope.event;
                                        if (kernelInfoProduced.kernelInfo.uri === this.kernelInfo.remoteUri) {
                                            this.updateKernelInfoFromEvent(kernelInfoProduced);
                                            const event = new commandsAndEvents.KernelEventEnvelope(commandsAndEvents.KernelInfoProducedType, { kernelInfo: this.kernelInfo }, commandInvocation.commandEnvelope);
                                            event.routingSlip.continueWith(envelope.routingSlip);
                                            this.delegatePublication(event, commandInvocation.context);
                                            this.delegatePublication(envelope, commandInvocation.context);
                                        }
                                        else {
                                            this.delegatePublication(envelope, commandInvocation.context);
                                        }
                                    }
                                    break;
                                case commandsAndEvents.CommandFailedType:
                                case commandsAndEvents.CommandSucceededType:
                                    logger_1.Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] finished, token=${envelope.command.getToken()}, commandToken=${commandToken}`);
                                    if (envelope.command.getToken() === commandToken) {
                                        logger_1.Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] resolving promise, envelopeToken=${envelope.command.getToken()}, commandToken=${commandToken}`);
                                        completionSource.resolve(envelope);
                                    }
                                    else {
                                        logger_1.Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] not resolving promise, envelopeToken=${envelope.command.getToken()}, commandToken=${commandToken}`);
                                        this.delegatePublication(envelope, commandInvocation.context);
                                    }
                                    break;
                                default:
                                    this.delegatePublication(envelope, commandInvocation.context);
                                    break;
                            }
                        }
                    }
                }
            });
            try {
                if (!commandInvocation.commandEnvelope.command.destinationUri || !commandInvocation.commandEnvelope.command.originUri) {
                    (_a = (_c = commandInvocation.commandEnvelope.command).originUri) !== null && _a !== void 0 ? _a : (_c.originUri = this.kernelInfo.uri);
                    (_b = (_d = commandInvocation.commandEnvelope.command).destinationUri) !== null && _b !== void 0 ? _b : (_d.destinationUri = this.kernelInfo.remoteUri);
                }
                commandInvocation.commandEnvelope.routingSlip; //?
                if (commandInvocation.commandEnvelope.commandType === commandsAndEvents.RequestKernelInfoType) {
                    const destinationUri = this.kernelInfo.remoteUri;
                    if (commandInvocation.commandEnvelope.routingSlip.contains(destinationUri, true)) {
                        return Promise.resolve();
                    }
                }
                logger_1.Logger.default.info(`proxy ${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] forwarding command ${commandInvocation.commandEnvelope.commandType} to ${commandInvocation.commandEnvelope.command.destinationUri}`);
                this._sender.send(commandInvocation.commandEnvelope);
                logger_1.Logger.default.info(`proxy ${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] about to await with token ${commandToken}`);
                const enventEnvelope = yield completionSource.promise;
                if (enventEnvelope.eventType === commandsAndEvents.CommandFailedType) {
                    commandInvocation.context.fail(enventEnvelope.event.message);
                }
                logger_1.Logger.default.info(`proxy ${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] done awaiting with token ${commandToken}}`);
            }
            catch (e) {
                commandInvocation.context.fail(e.message);
            }
            finally {
                eventSubscription.unsubscribe();
            }
        });
    }
}
exports.ProxyKernel = ProxyKernel;
//# sourceMappingURL=proxyKernel.js.map