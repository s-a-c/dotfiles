"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.KernelInvocationContext = void 0;
const rxjs = require("rxjs");
const commandsAndEvents = require("./commandsAndEvents");
const kernel_1 = require("./kernel");
const promiseCompletionSource_1 = require("./promiseCompletionSource");
class KernelInvocationContext {
    constructor(kernelCommandInvocation) {
        this._childCommands = [];
        this._eventSubject = new rxjs.Subject();
        this._isComplete = false;
        this._handlingKernel = null;
        this._completionSource = new promiseCompletionSource_1.PromiseCompletionSource();
        this._commandEnvelope = kernelCommandInvocation;
    }
    get handlingKernel() {
        return this._handlingKernel;
    }
    ;
    get kernelEvents() {
        return this._eventSubject.asObservable();
    }
    ;
    set handlingKernel(value) {
        this._handlingKernel = value;
    }
    get promise() {
        return this._completionSource.promise;
    }
    static getOrCreateAmbientContext(command) {
        let current = KernelInvocationContext._current;
        if (!current || current._isComplete) {
            command.getOrCreateToken();
            KernelInvocationContext._current = new KernelInvocationContext(command);
        }
        else {
            if (!commandsAndEvents.KernelCommandEnvelope.areCommandsTheSame(command, current._commandEnvelope)) {
                const found = current._childCommands.includes(command);
                if (!found) {
                    if (command.parentCommand === null || command.parentCommand === undefined) {
                        command.setParent(current._commandEnvelope);
                    }
                    current._childCommands.push(command);
                }
            }
        }
        return KernelInvocationContext._current;
    }
    static get current() { return this._current; }
    get command() { return this._commandEnvelope.command; }
    get commandEnvelope() { return this._commandEnvelope; }
    complete(command) {
        if (commandsAndEvents.KernelCommandEnvelope.areCommandsTheSame(command, this._commandEnvelope)) {
            this._isComplete = true;
            let succeeded = {};
            let eventEnvelope = new commandsAndEvents.KernelEventEnvelope(commandsAndEvents.CommandSucceededType, succeeded, this._commandEnvelope);
            this.internalPublish(eventEnvelope);
            this._completionSource.resolve();
        }
        else {
            let pos = this._childCommands.indexOf(command);
            delete this._childCommands[pos];
        }
    }
    fail(message) {
        // The C# code accepts a message and/or an exception. Do we need to add support
        // for exceptions? (The TS CommandFailed interface doesn't have a place for it right now.)
        this._isComplete = true;
        let failed = { message: message !== null && message !== void 0 ? message : "Command Failed" };
        let eventEnvelope = new commandsAndEvents.KernelEventEnvelope(commandsAndEvents.CommandFailedType, failed, this._commandEnvelope);
        this.internalPublish(eventEnvelope);
        this._completionSource.resolve();
    }
    publish(kernelEvent) {
        if (!this._isComplete) {
            this.internalPublish(kernelEvent);
        }
    }
    internalPublish(kernelEvent) {
        if (!kernelEvent.command) {
            kernelEvent.command = this._commandEnvelope;
        }
        let command = kernelEvent.command;
        if (this.handlingKernel) {
            const kernelUri = (0, kernel_1.getKernelUri)(this.handlingKernel);
            if (!kernelEvent.routingSlip.contains(kernelUri)) {
                kernelEvent.routingSlip.stamp(kernelUri);
                kernelEvent.routingSlip; //?
            }
            else {
                "should not be here"; //?
            }
        }
        else {
            kernelEvent; //?
        }
        this._commandEnvelope; //?
        if (command === null ||
            command === undefined ||
            commandsAndEvents.KernelCommandEnvelope.areCommandsTheSame(command, this._commandEnvelope) ||
            this._childCommands.includes(command)) {
            this._eventSubject.next(kernelEvent);
        }
        else if (command.isSelforDescendantOf(this._commandEnvelope)) {
            this._eventSubject.next(kernelEvent);
        }
        else if (command.hasSameRootCommandAs(this._commandEnvelope)) {
            this._eventSubject.next(kernelEvent);
        }
    }
    isParentOfCommand(commandEnvelope) {
        const childFound = this._childCommands.includes(commandEnvelope);
        return childFound;
    }
    dispose() {
        if (!this._isComplete) {
            this.complete(this._commandEnvelope);
        }
        KernelInvocationContext._current = null;
    }
}
exports.KernelInvocationContext = KernelInvocationContext;
KernelInvocationContext._current = null;
//# sourceMappingURL=kernelInvocationContext.js.map