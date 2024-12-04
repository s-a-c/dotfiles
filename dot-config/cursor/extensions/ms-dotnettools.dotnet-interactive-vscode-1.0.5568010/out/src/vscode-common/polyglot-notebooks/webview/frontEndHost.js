"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.createHost = void 0;
const compositeKernel_1 = require("../compositeKernel");
const javascriptKernel_1 = require("../javascriptKernel");
const logger_1 = require("../logger");
const kernelHost_1 = require("../kernelHost");
const connection = require("../connection");
const commandsAndEvents = require("../commandsAndEvents");
function createHost(global, compositeKernelName, configureRequire, logMessage, localToRemote, remoteToLocal, onReady) {
    logger_1.Logger.configure(compositeKernelName, logMessage);
    global.interactive = {};
    configureRequire(global.interactive);
    const compositeKernel = new compositeKernel_1.CompositeKernel(compositeKernelName);
    const kernelHost = new kernelHost_1.KernelHost(compositeKernel, connection.KernelCommandAndEventSender.FromObserver(localToRemote), connection.KernelCommandAndEventReceiver.FromObservable(remoteToLocal), `kernel://${compositeKernelName}`);
    kernelHost.defaultConnector.receiver.subscribe({
        next: (envelope) => {
            if (connection.isKernelEventEnvelope(envelope) && envelope.eventType === commandsAndEvents.KernelInfoProducedType) {
                const kernelInfoProduced = envelope.event;
                connection.ensureOrUpdateProxyForKernelInfo(kernelInfoProduced.kernelInfo, compositeKernel);
            }
        }
    });
    // use composite kernel as root
    global.kernel = {
        get root() {
            return compositeKernel;
        }
    };
    global.sendSendValueCommand = (form) => {
        let formValues = {};
        for (var i = 0; i < form.elements.length; i++) {
            var e = form.elements[i];
            if (e.name && e.name !== '') {
                let name = e.name.replace('-', '');
                formValues[name] = e.value;
            }
        }
        let command = {
            formattedValue: {
                mimeType: 'application/json',
                value: JSON.stringify(formValues)
            },
            name: form.id,
            targetKernelName: '.NET'
        };
        let envelope = new commandsAndEvents.KernelCommandEnvelope(commandsAndEvents.SendValueType, command);
        form.remove();
        compositeKernel.send(envelope);
    };
    global[compositeKernelName] = {
        compositeKernel,
        kernelHost,
    };
    const jsKernel = new javascriptKernel_1.JavascriptKernel();
    compositeKernel.add(jsKernel, ["js"]);
    kernelHost.connect();
    onReady();
}
exports.createHost = createHost;
//# sourceMappingURL=frontEndHost.js.map