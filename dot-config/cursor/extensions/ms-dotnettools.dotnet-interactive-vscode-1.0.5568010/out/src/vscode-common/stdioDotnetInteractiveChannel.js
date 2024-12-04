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
exports.StdioDotnetInteractiveChannel = void 0;
const cp = require("child_process");
const commandsAndEvents_1 = require("./polyglot-notebooks/commandsAndEvents");
const lineReader_1 = require("./lineReader");
const utilities_1 = require("./utilities");
const connection_1 = require("./polyglot-notebooks/connection");
const rxjs_1 = require("rxjs");
const logger_1 = require("./polyglot-notebooks/logger");
class StdioDotnetInteractiveChannel {
    constructor(notebookPath, processStart, diagnosticChannel, processExited) {
        this.diagnosticChannel = diagnosticChannel;
        this.processExited = processExited;
        this.notifyOnExit = true;
        this.pingTimer = null;
        this._receiverSubject = new rxjs_1.Subject();
        this._sender = connection_1.KernelCommandAndEventSender.FromFunction(envelope => {
            this.writeToProcessStdin(envelope.toJson());
        });
        this._receiver = connection_1.KernelCommandAndEventReceiver.FromObservable(this._receiverSubject);
        // prepare root event handler
        this.lineReader = new lineReader_1.LineReader();
        this.lineReader.subscribe(line => this.handleLine(line));
        this.childProcess = null;
        // prepare one-time ready event
        this.readyPromise = new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
            let args = processStart.args;
            // launch the process
            this.diagnosticChannel.appendLine(`Starting kernel for '${notebookPath}' using: ${processStart.command} ${args.join(' ')}`);
            const processEnv = Object.assign(Object.assign({}, process.env), processStart.env);
            let childProcess = cp.spawn(processStart.command, args, { cwd: processStart.workingDirectory, env: processEnv });
            let pid = childProcess.pid;
            this.childProcess = childProcess;
            this.diagnosticChannel.appendLine(`Kernel for '${notebookPath}' started (${childProcess.pid}).`);
            childProcess.on('exit', (code, signal) => {
                const message = `Kernel for '${notebookPath}' ended (${pid})`;
                const messageCodeSuffix = (code && code !== 0)
                    ? ` with code ${code}`
                    : '';
                const messageSignalSuffix = signal
                    ? ` with signal ${signal}`
                    : '';
                const fullMessage = `${message}${messageCodeSuffix}${messageSignalSuffix}.`;
                this.diagnosticChannel.appendLine(fullMessage);
                if (this.notifyOnExit) {
                    this.processExited(pid, code, signal);
                }
            });
            childProcess.stdout.on('data', data => this.lineReader.onData(data));
            childProcess.stderr.on('data', data => this.diagnosticChannel.appendLine(`kernel (${pid}) stderr: ${data.toString('utf-8')}`));
            const readySubscriber = this.subscribeToKernelEvents(eventEnvelope => {
                if (eventEnvelope.eventType === commandsAndEvents_1.KernelReadyType) {
                    readySubscriber.dispose();
                    resolve((eventEnvelope.event));
                }
            });
        }));
    }
    get sender() {
        return this._sender;
    }
    get receiver() {
        return this._receiver;
    }
    handleLine(line) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const garbage = (0, utilities_1.parse)(line);
            }
            catch (e) {
                const x = e;
            }
            const envelope = (0, utilities_1.parse)(line);
            logger_1.Logger.default.info(`envelope received from stdio: ${JSON.stringify(envelope)}`);
            if ((0, connection_1.isKernelEventEnvelopeModel)(envelope)) {
                switch (envelope.eventType) {
                    case commandsAndEvents_1.CommandFailedType:
                    case commandsAndEvents_1.CommandSucceededType:
                        if (this.pingTimer) {
                            clearInterval(this.pingTimer);
                            this.pingTimer = null;
                        }
                        break;
                }
                const event = commandsAndEvents_1.KernelEventEnvelope.fromJson(envelope);
                this._receiverSubject.next(event);
            }
            else if ((0, connection_1.isKernelCommandEnvelopeModel)(envelope)) {
                // TODO: pass in context with shortcut methods for publish, etc.
                // TODO: wrap and return succeed/failed
                // TODO: publish succeeded
                // TODO: publish failed
                const command = commandsAndEvents_1.KernelCommandEnvelope.fromJson(envelope);
                this._receiverSubject.next(command);
            }
        });
    }
    subscribeToKernelEvents(observer) {
        let sub = this._receiverSubject.subscribe({
            next: (envelope) => {
                if ((0, connection_1.isKernelEventEnvelope)(envelope)) {
                    observer(envelope);
                }
            }
        });
        return {
            dispose: () => {
                sub.unsubscribe();
            }
        };
    }
    writeToProcessStdin(content) {
        if ((0, utilities_1.isNotNull)(this.childProcess)) {
            let str = (0, utilities_1.stringify)(content);
            // send the command or event
            this.childProcess.stdin.write(str + '\n');
            // Start ping the timer
            // ====================
            // On Windows in some cases the STDIN reader on the server side will appear to "hang" when trying
            // to call `TextReader.ReadLineAsync()` on some long-running commands and this is ultimately by
            // design.
            //
            // https://docs.microsoft.com/en-us/dotnet/api/system.console.in?view=net-6.0#remarks
            //
            // > Read operations on the standard input stream execute synchronously. That is, they block until
            // > the specified read operation has completed. This is true even if an asynchronous method, such
            // > as ReadLineAsync, is called on the TextReader object returned by the In property.
            //
            // This behavior is also present in the native `PeekConsoleInput` and `PeekConsoleInputW` functions
            // so we can't solve this by using pinvoke.
            //
            // To work around this, only when starting a `SubmitCode` command and only on Windows we periodically
            // ping the server with a single newline character.  This is enough to break the read hang, but
            // doesn't negatively impact the command parsing or execution.  To prevent spamming the server,
            // this timer is only active until the command succeeds or fails.
            if (process.platform === 'win32' && this.pingTimer === null && (0, connection_1.isKernelCommandEnvelopeModel)(content)) {
                if (content.commandType === commandsAndEvents_1.SubmitCodeType) {
                    this.pingTimer = setInterval(() => {
                        if (this.childProcess) {
                            this.childProcess.stdin.write('\n');
                        }
                    }, 500);
                }
            }
        }
        else {
            throw new Error('Kernel process is `null`.');
        }
    }
    waitForReady() {
        return this.readyPromise;
    }
    dispose() {
        this.notifyOnExit = false;
        if (this.pingTimer) {
            clearInterval(this.pingTimer);
            this.pingTimer = null;
        }
        this.childProcess = null;
    }
}
exports.StdioDotnetInteractiveChannel = StdioDotnetInteractiveChannel;
//# sourceMappingURL=stdioDotnetInteractiveChannel.js.map