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
exports.QuickScriptService = void 0;
const container_1 = require("../container");
class QuickScriptService {
    initialize() {
        return __awaiter(this, void 0, void 0, function* () {
            var scripts = container_1.Container.context.globalState.get("quick-scripts");
            if (!scripts) {
                yield container_1.Container.context.globalState.update("quick-scripts", []);
            }
        });
    }
    getScripts() {
        return container_1.Container.context.globalState.get("quick-scripts");
    }
    getScript(name) {
        var scripts = container_1.Container.context.globalState.get("quick-scripts");
        return scripts.find(m => m.Name === name);
    }
    removeScript(name) {
        return __awaiter(this, void 0, void 0, function* () {
            var scripts = container_1.Container.context.globalState.get("quick-scripts");
            scripts = scripts.filter(x => x.Name !== name);
            yield container_1.Container.context.globalState.update("quick-scripts", scripts);
        });
    }
    setScript(name, fileName) {
        return __awaiter(this, void 0, void 0, function* () {
            var scripts = container_1.Container.context.globalState.get("quick-scripts");
            var script = scripts.find(x => x === name);
            if (script)
                return;
            scripts.push({
                Name: name,
                File: fileName
            });
            yield container_1.Container.context.globalState.update("quick-scripts", scripts);
        });
    }
}
exports.QuickScriptService = QuickScriptService;
//# sourceMappingURL=quickScriptService.js.map