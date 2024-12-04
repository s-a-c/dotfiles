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
exports.trackJob = void 0;
const container_1 = require("./container");
const types_1 = require("./types");
const vscode = require("vscode");
const settings_1 = require("./settings");
exports.trackJob = (id) => {
    var lastStatus = types_1.JobStatus.Queued;
    const token = setInterval(() => __awaiter(void 0, void 0, void 0, function* () {
        const job = yield container_1.Container.universal.getJob(id);
        var result = '';
        if (job.status === types_1.JobStatus.Canceled) {
            clearInterval(token);
            result = yield vscode.window.showWarningMessage(`Job ${id} canceled.`, "View Job");
        }
        if (job.status === types_1.JobStatus.Failed) {
            clearInterval(token);
            result = yield vscode.window.showErrorMessage(`Job ${id} failed.`, "View Job");
        }
        if (job.status === types_1.JobStatus.Completed) {
            clearInterval(token);
            result = yield vscode.window.showInformationMessage(`Job ${id} succeeded.`, "View Job");
        }
        if (job.status === types_1.JobStatus.WaitingOnFeedback && lastStatus != types_1.JobStatus.WaitingOnFeedback) {
            result = yield vscode.window.showInformationMessage(`Job ${id} is waiting on feedback.`, "View Job");
        }
        if (result === "View Job") {
            const settings = settings_1.load();
            vscode.env.openExternal(vscode.Uri.parse(`${settings.url}/admin/automation/jobs/${id}`));
        }
        lastStatus = job.status;
    }), 1000);
};
//# sourceMappingURL=job-tracker.js.map