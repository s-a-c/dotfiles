"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Performance = exports.Job = exports.Session = exports.CustomTreeView = exports.CustomTreeItem = exports.PSNamespace = exports.PSProperty = exports.PSField = exports.PSMethod = exports.PSType = exports.PSAssembly = exports.Certificate = exports.FunctionDefinition = exports.ReferenceLocation = exports.Hover = exports.RefactorProperty = exports.RefactorType = exports.RefactoringProperty = exports.RefactorRequest = exports.TextPosition = exports.TextEditorState = exports.TextEditType = exports.RefactorInfo = exports.RefactorTextEdit = void 0;
class RefactorTextEdit {
}
exports.RefactorTextEdit = RefactorTextEdit;
class RefactorInfo {
}
exports.RefactorInfo = RefactorInfo;
var TextEditType;
(function (TextEditType) {
    TextEditType[TextEditType["none"] = 0] = "none";
    TextEditType[TextEditType["replace"] = 1] = "replace";
    TextEditType[TextEditType["newFile"] = 2] = "newFile";
    TextEditType[TextEditType["insert"] = 3] = "insert";
})(TextEditType = exports.TextEditType || (exports.TextEditType = {}));
class TextEditorState {
}
exports.TextEditorState = TextEditorState;
class TextPosition {
}
exports.TextPosition = TextPosition;
class RefactorRequest {
}
exports.RefactorRequest = RefactorRequest;
class RefactoringProperty {
}
exports.RefactoringProperty = RefactoringProperty;
var RefactorType;
(function (RefactorType) {
    RefactorType[RefactorType["extractFile"] = 0] = "extractFile";
    RefactorType[RefactorType["exportModuleMember"] = 1] = "exportModuleMember";
    RefactorType[RefactorType["convertToSplat"] = 2] = "convertToSplat";
    RefactorType[RefactorType["extractFunction"] = 3] = "extractFunction";
    RefactorType[RefactorType["convertToMultiLine"] = 4] = "convertToMultiLine";
    RefactorType[RefactorType["generateFunctionFromUsage"] = 5] = "generateFunctionFromUsage";
    RefactorType[RefactorType["introduceVariableForSubstring"] = 6] = "introduceVariableForSubstring";
    RefactorType[RefactorType["wrapDotNetMethod"] = 7] = "wrapDotNetMethod";
    RefactorType[RefactorType["reorder"] = 8] = "reorder";
    RefactorType[RefactorType["SplitPipe"] = 9] = "SplitPipe";
    RefactorType[RefactorType["IntroduceUsingNamespace"] = 10] = "IntroduceUsingNamespace";
    RefactorType[RefactorType["ConvertToPSItem"] = 11] = "ConvertToPSItem";
    RefactorType[RefactorType["ConvertToDollarUnder"] = 12] = "ConvertToDollarUnder";
    RefactorType[RefactorType["GenerateProxyFunction"] = 13] = "GenerateProxyFunction";
    RefactorType[RefactorType["ExtractVariable"] = 14] = "ExtractVariable";
})(RefactorType = exports.RefactorType || (exports.RefactorType = {}));
var RefactorProperty;
(function (RefactorProperty) {
    RefactorProperty[RefactorProperty["fileName"] = 0] = "fileName";
    RefactorProperty[RefactorProperty["name"] = 1] = "name";
})(RefactorProperty = exports.RefactorProperty || (exports.RefactorProperty = {}));
class Hover {
}
exports.Hover = Hover;
class ReferenceLocation {
}
exports.ReferenceLocation = ReferenceLocation;
class FunctionDefinition {
}
exports.FunctionDefinition = FunctionDefinition;
class Certificate {
}
exports.Certificate = Certificate;
class PSAssembly {
}
exports.PSAssembly = PSAssembly;
class PSType {
}
exports.PSType = PSType;
class PSMethod {
}
exports.PSMethod = PSMethod;
class PSField {
}
exports.PSField = PSField;
class PSProperty {
}
exports.PSProperty = PSProperty;
class PSNamespace {
}
exports.PSNamespace = PSNamespace;
class CustomTreeItem {
}
exports.CustomTreeItem = CustomTreeItem;
class CustomTreeView {
}
exports.CustomTreeView = CustomTreeView;
class Session {
}
exports.Session = Session;
class Job {
}
exports.Job = Job;
class Performance {
}
exports.Performance = Performance;
//# sourceMappingURL=types.js.map