"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TerminalStatus = exports.SampleFile = exports.Sample = exports.SampleFolder = exports.ModuleSource = exports.JobStatus = exports.DashboardStatus = void 0;
var DashboardStatus;
(function (DashboardStatus) {
    DashboardStatus[DashboardStatus["Stopped"] = 0] = "Stopped";
    DashboardStatus[DashboardStatus["Started"] = 1] = "Started";
    DashboardStatus[DashboardStatus["StartFailed"] = 2] = "StartFailed";
    DashboardStatus[DashboardStatus["Starting"] = 3] = "Starting";
    DashboardStatus[DashboardStatus["Debugging"] = 4] = "Debugging";
})(DashboardStatus = exports.DashboardStatus || (exports.DashboardStatus = {}));
var JobStatus;
(function (JobStatus) {
    JobStatus[JobStatus["Queued"] = 0] = "Queued";
    JobStatus[JobStatus["Running"] = 1] = "Running";
    JobStatus[JobStatus["Completed"] = 2] = "Completed";
    JobStatus[JobStatus["Failed"] = 3] = "Failed";
    JobStatus[JobStatus["WaitingOnFeedback"] = 4] = "WaitingOnFeedback";
    JobStatus[JobStatus["Canceled"] = 5] = "Canceled";
    JobStatus[JobStatus["Canceling"] = 6] = "Canceling";
    JobStatus[JobStatus["Historical"] = 7] = "Historical";
    JobStatus[JobStatus["Active"] = 8] = "Active";
})(JobStatus = exports.JobStatus || (exports.JobStatus = {}));
var ModuleSource;
(function (ModuleSource) {
    ModuleSource[ModuleSource["Local"] = 0] = "Local";
    ModuleSource[ModuleSource["Gallery"] = 1] = "Gallery";
})(ModuleSource = exports.ModuleSource || (exports.ModuleSource = {}));
class SampleFolder {
    constructor(name, path) {
        this.name = name;
        this.path = path;
    }
}
exports.SampleFolder = SampleFolder;
class Sample {
    constructor(title, description, version, files, url) {
        this.title = title;
        this.description = description;
        this.version = version;
        this.files = files;
        this.url = url;
    }
}
exports.Sample = Sample;
class SampleFile {
    constructor(file, content) {
        this.fileName = file;
        this.content = content;
    }
}
exports.SampleFile = SampleFile;
var TerminalStatus;
(function (TerminalStatus) {
    TerminalStatus[TerminalStatus["Connecting"] = 0] = "Connecting";
    TerminalStatus[TerminalStatus["Connected"] = 1] = "Connected";
    TerminalStatus[TerminalStatus["Idle"] = 2] = "Idle";
    TerminalStatus[TerminalStatus["Terminated"] = 3] = "Terminated";
})(TerminalStatus = exports.TerminalStatus || (exports.TerminalStatus = {}));
//# sourceMappingURL=types.js.map