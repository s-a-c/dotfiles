"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
Object.defineProperty(exports, "__esModule", { value: true });
exports.InsertTextFormat = exports.ValueProducedType = exports.ValueInfosProducedType = exports.StandardOutputValueProducedType = exports.StandardErrorValueProducedType = exports.SignatureHelpProducedType = exports.ReturnValueProducedType = exports.ProjectOpenedType = exports.PackageAddedType = exports.KernelReadyType = exports.KernelInfoProducedType = exports.KernelExtensionLoadedType = exports.InputsProducedType = exports.InputProducedType = exports.IncompleteCodeSubmissionReceivedType = exports.HoverTextProducedType = exports.ErrorProducedType = exports.DocumentOpenedType = exports.DisplayedValueUpdatedType = exports.DisplayedValueProducedType = exports.DiagnosticsProducedType = exports.CompletionsProducedType = exports.CompleteCodeSubmissionReceivedType = exports.CommandSucceededType = exports.CommandFailedType = exports.CodeSubmissionReceivedType = exports.AssemblyProducedType = exports.UpdateDisplayedValueType = exports.SubmitCodeType = exports.SendValueType = exports.SendEditableCodeType = exports.RequestValueInfosType = exports.RequestValueType = exports.RequestSignatureHelpType = exports.RequestKernelInfoType = exports.RequestInputsType = exports.RequestInputType = exports.RequestHoverTextType = exports.RequestDiagnosticsType = exports.RequestCompletionsType = exports.QuitType = exports.OpenProjectType = exports.OpenDocumentType = exports.ImportDocumentType = exports.DisplayValueType = exports.DisplayErrorType = exports.CompileProjectType = exports.CancelType = exports.AddPackageSourceType = exports.AddPackageType = void 0;
exports.RequestType = exports.DocumentSerializationType = exports.DiagnosticSeverity = void 0;
// Generated TypeScript interfaces and types.
// --------------------------------------------- Kernel Commands
exports.AddPackageType = "AddPackage";
exports.AddPackageSourceType = "AddPackageSource";
exports.CancelType = "Cancel";
exports.CompileProjectType = "CompileProject";
exports.DisplayErrorType = "DisplayError";
exports.DisplayValueType = "DisplayValue";
exports.ImportDocumentType = "ImportDocument";
exports.OpenDocumentType = "OpenDocument";
exports.OpenProjectType = "OpenProject";
exports.QuitType = "Quit";
exports.RequestCompletionsType = "RequestCompletions";
exports.RequestDiagnosticsType = "RequestDiagnostics";
exports.RequestHoverTextType = "RequestHoverText";
exports.RequestInputType = "RequestInput";
exports.RequestInputsType = "RequestInputs";
exports.RequestKernelInfoType = "RequestKernelInfo";
exports.RequestSignatureHelpType = "RequestSignatureHelp";
exports.RequestValueType = "RequestValue";
exports.RequestValueInfosType = "RequestValueInfos";
exports.SendEditableCodeType = "SendEditableCode";
exports.SendValueType = "SendValue";
exports.SubmitCodeType = "SubmitCode";
exports.UpdateDisplayedValueType = "UpdateDisplayedValue";
// --------------------------------------------- Kernel events
exports.AssemblyProducedType = "AssemblyProduced";
exports.CodeSubmissionReceivedType = "CodeSubmissionReceived";
exports.CommandFailedType = "CommandFailed";
exports.CommandSucceededType = "CommandSucceeded";
exports.CompleteCodeSubmissionReceivedType = "CompleteCodeSubmissionReceived";
exports.CompletionsProducedType = "CompletionsProduced";
exports.DiagnosticsProducedType = "DiagnosticsProduced";
exports.DisplayedValueProducedType = "DisplayedValueProduced";
exports.DisplayedValueUpdatedType = "DisplayedValueUpdated";
exports.DocumentOpenedType = "DocumentOpened";
exports.ErrorProducedType = "ErrorProduced";
exports.HoverTextProducedType = "HoverTextProduced";
exports.IncompleteCodeSubmissionReceivedType = "IncompleteCodeSubmissionReceived";
exports.InputProducedType = "InputProduced";
exports.InputsProducedType = "InputsProduced";
exports.KernelExtensionLoadedType = "KernelExtensionLoaded";
exports.KernelInfoProducedType = "KernelInfoProduced";
exports.KernelReadyType = "KernelReady";
exports.PackageAddedType = "PackageAdded";
exports.ProjectOpenedType = "ProjectOpened";
exports.ReturnValueProducedType = "ReturnValueProduced";
exports.SignatureHelpProducedType = "SignatureHelpProduced";
exports.StandardErrorValueProducedType = "StandardErrorValueProduced";
exports.StandardOutputValueProducedType = "StandardOutputValueProduced";
exports.ValueInfosProducedType = "ValueInfosProduced";
exports.ValueProducedType = "ValueProduced";
var InsertTextFormat;
(function (InsertTextFormat) {
    InsertTextFormat["PlainText"] = "plaintext";
    InsertTextFormat["Snippet"] = "snippet";
})(InsertTextFormat = exports.InsertTextFormat || (exports.InsertTextFormat = {}));
var DiagnosticSeverity;
(function (DiagnosticSeverity) {
    DiagnosticSeverity["Hidden"] = "hidden";
    DiagnosticSeverity["Info"] = "info";
    DiagnosticSeverity["Warning"] = "warning";
    DiagnosticSeverity["Error"] = "error";
})(DiagnosticSeverity = exports.DiagnosticSeverity || (exports.DiagnosticSeverity = {}));
var DocumentSerializationType;
(function (DocumentSerializationType) {
    DocumentSerializationType["Dib"] = "dib";
    DocumentSerializationType["Ipynb"] = "ipynb";
})(DocumentSerializationType = exports.DocumentSerializationType || (exports.DocumentSerializationType = {}));
var RequestType;
(function (RequestType) {
    RequestType["Parse"] = "parse";
    RequestType["Serialize"] = "serialize";
})(RequestType = exports.RequestType || (exports.RequestType = {}));
//# sourceMappingURL=contracts.js.map