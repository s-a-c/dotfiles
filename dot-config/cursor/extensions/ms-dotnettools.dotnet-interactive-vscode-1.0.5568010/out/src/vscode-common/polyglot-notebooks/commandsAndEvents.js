"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.KernelEventEnvelope = exports.KernelCommandEnvelope = void 0;
const routingslip_1 = require("./routingslip");
__exportStar(require("./contracts"), exports);
const uuid = require("uuid");
function toBase64String(value) {
    const wnd = (globalThis.window);
    if (wnd) {
        return wnd.btoa(String.fromCharCode(...value));
    }
    else {
        return Buffer.from(value).toString('base64');
    }
}
class KernelCommandEnvelope {
    constructor(commandType, command) {
        this.commandType = commandType;
        this.command = command;
        this._childCommandCounter = 1;
        this._routingSlip = new routingslip_1.CommandRoutingSlip();
    }
    get routingSlip() {
        return this._routingSlip;
    }
    get parentCommand() {
        return this._parentCommand;
    }
    static isKernelCommandEnvelopeModel(arg) {
        return !arg.getOrCreateToken;
    }
    setParent(parentCommand) {
        if (this._parentCommand && this._parentCommand !== parentCommand) {
            throw new Error("Parent cannot be changed.");
        }
        if ((this._token !== undefined && this._token !== null) &&
            ((parentCommand === null || parentCommand === void 0 ? void 0 : parentCommand._token) !== undefined && (parentCommand === null || parentCommand === void 0 ? void 0 : parentCommand._token) !== null) &&
            KernelCommandEnvelope.getRootToken(this._token) !== KernelCommandEnvelope.getRootToken(parentCommand._token)) {
            throw new Error("Token of parented command cannot be changed.");
        }
        if (this._parentCommand === null || this._parentCommand === undefined) {
            {
                // todo: do we need to override the token? Should this throw if parenting happens after token is set?
                if (this._token) {
                    this._token = undefined;
                }
                this._parentCommand = parentCommand;
                this.getOrCreateToken();
            }
        }
    }
    static areCommandsTheSame(envelope1, envelope2) {
        envelope1; //?
        envelope2; //?
        envelope1 === envelope2; //?
        // reference equality
        if (envelope1 === envelope2) {
            return true;
        }
        // commandType equality
        const sameCommandType = (envelope1 === null || envelope1 === void 0 ? void 0 : envelope1.commandType) === (envelope2 === null || envelope2 === void 0 ? void 0 : envelope2.commandType); //?
        if (!sameCommandType) {
            return false;
        }
        // both must have tokens
        if ((!(envelope1 === null || envelope1 === void 0 ? void 0 : envelope1._token)) || (!(envelope2 === null || envelope2 === void 0 ? void 0 : envelope2._token))) {
            return false;
        }
        // token equality
        const sameToken = (envelope1 === null || envelope1 === void 0 ? void 0 : envelope1._token) === (envelope2 === null || envelope2 === void 0 ? void 0 : envelope2._token); //?
        if (!sameToken) {
            return false;
        }
        return true;
    }
    getOrCreateToken() {
        if (this._token) {
            return this._token;
        }
        if (this._parentCommand) {
            this._token = `${this._parentCommand.getOrCreateToken()}.${this._parentCommand.getNextChildToken()}`;
            return this._token;
        }
        const guidBytes = uuid.parse(uuid.v4());
        const data = new Uint8Array(guidBytes);
        this._token = toBase64String(data);
        // this._token = `${KernelCommandEnvelope._counter++}`;
        return this._token;
    }
    getToken() {
        if (this._token) {
            return this._token;
        }
        throw new Error('token not set');
    }
    isSelforDescendantOf(otherCommand) {
        const otherToken = otherCommand._token;
        const thisToken = this._token;
        if (thisToken && otherToken) {
            return thisToken.startsWith(otherToken);
        }
        throw new Error('both commands must have tokens');
    }
    hasSameRootCommandAs(otherCommand) {
        const otherToken = otherCommand._token;
        const thisToken = this._token;
        if (thisToken && otherToken) {
            const otherRootToken = KernelCommandEnvelope.getRootToken(otherToken);
            const thisRootToken = KernelCommandEnvelope.getRootToken(thisToken);
            return thisRootToken === otherRootToken;
        }
        throw new Error('both commands must have tokens');
    }
    static getRootToken(token) {
        const parts = token.split('.');
        return parts[0];
    }
    toJson() {
        const model = {
            commandType: this.commandType,
            command: this.command,
            routingSlip: this._routingSlip.toArray(),
            token: this.getOrCreateToken()
        };
        return model;
    }
    static fromJson(model) {
        const command = new KernelCommandEnvelope(model.commandType, model.command);
        command._routingSlip = routingslip_1.CommandRoutingSlip.fromUris(model.routingSlip || []);
        command._token = model.token;
        return command;
    }
    clone() {
        return KernelCommandEnvelope.fromJson(this.toJson());
    }
    getNextChildToken() {
        return this._childCommandCounter++;
    }
}
exports.KernelCommandEnvelope = KernelCommandEnvelope;
KernelCommandEnvelope._counter = 1;
class KernelEventEnvelope {
    constructor(eventType, event, command) {
        this.eventType = eventType;
        this.event = event;
        this.command = command;
        this._routingSlip = new routingslip_1.EventRoutingSlip();
    }
    get routingSlip() {
        return this._routingSlip;
    }
    toJson() {
        var _a;
        const model = {
            eventType: this.eventType,
            event: this.event,
            command: (_a = this.command) === null || _a === void 0 ? void 0 : _a.toJson(),
            routingSlip: this._routingSlip.toArray()
        };
        return model;
    }
    static fromJson(model) {
        const event = new KernelEventEnvelope(model.eventType, model.event, model.command ? KernelCommandEnvelope.fromJson(model.command) : undefined);
        event._routingSlip = routingslip_1.EventRoutingSlip.fromUris(model.routingSlip || []);
        return event;
    }
    clone() {
        return KernelEventEnvelope.fromJson(this.toJson());
    }
}
exports.KernelEventEnvelope = KernelEventEnvelope;
//# sourceMappingURL=commandsAndEvents.js.map