"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
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
exports.wat2wasm = exports.wasm2wat = exports.writeFile = exports.readWasm = exports.readFile = exports.getPhysicalPath = void 0;
const vscode_1 = require("vscode");
const fs = __importStar(require("fs"));
const wabt_1 = require("@wasmer/wabt");
const wabt_2 = require("@wasmer/wabt/src/bindings/wabt/wabt");
const util_1 = require("util");
const wabt = wabt_1.bindings.wabt();
/**
 * @param uri - path to the file.
 */
function getPhysicalPath(uri) {
    if (uri.scheme === "wasm-preview") {
        return uri.with({ scheme: "file" }).fsPath;
    }
    return uri.fsPath;
}
exports.getPhysicalPath = getPhysicalPath;
function readFile(uri) {
    const filepath = getPhysicalPath(uri);
    return new Promise((resolve, reject) => {
        fs.readFile(filepath, { encoding: null }, (err, data) => {
            if (err) {
                return reject(err);
            }
            resolve(data);
        });
    });
}
exports.readFile = readFile;
function readWasm(uri) {
    if (uri.scheme !== "wasm-preview") {
        return;
    }
    return readFile(uri);
}
exports.readWasm = readWasm;
function writeFile(uri, content) {
    const filepath = getPhysicalPath(uri);
    return new Promise((resolve, reject) => {
        fs.writeFile(filepath, content, (err) => {
            if (err) {
                return reject(err);
            }
            resolve();
        });
    });
}
exports.writeFile = writeFile;
const WABT_FEATURES = wabt_2.WASM_FEATURE_ANNOTATIONS |
    wabt_2.WASM_FEATURE_BULK_MEMORY |
    wabt_2.WASM_FEATURE_EXCEPTIONS |
    wabt_2.WASM_FEATURE_GC |
    wabt_2.WASM_FEATURE_MULTI_VALUE |
    wabt_2.WASM_FEATURE_MUTABLE_GLOBALS |
    wabt_2.WASM_FEATURE_REFERENCE_TYPES |
    wabt_2.WASM_FEATURE_SAT_FLOAT_TO_INT |
    wabt_2.WASM_FEATURE_SIGN_EXTENSION |
    wabt_2.WASM_FEATURE_SIMD |
    wabt_2.WASM_FEATURE_TAIL_CALL |
    wabt_2.WASM_FEATURE_THREADS;
const encoder = new util_1.TextEncoder();
const decoder = new util_1.TextDecoder();
function wasm2wat(content) {
    return __awaiter(this, void 0, void 0, function* () {
        const result = (yield wabt).wasm2wat(content, WABT_FEATURES);
        switch (result.tag) {
            case "ok":
                return result.val;
            case "err":
                vscode_1.window.showErrorMessage(`Error while reading the Wasm: ${result.val}`);
        }
    });
}
exports.wasm2wat = wasm2wat;
function wat2wasm(content) {
    return __awaiter(this, void 0, void 0, function* () {
        const wat = decoder.decode(content);
        const result = (yield wabt).wat2wasm(wat, WABT_FEATURES);
        switch (result.tag) {
            case "ok":
                return Buffer.from(result.val);
            case "err":
                vscode_1.window.showErrorMessage(result.val);
        }
    });
}
exports.wat2wasm = wat2wasm;
//# sourceMappingURL=utils.js.map