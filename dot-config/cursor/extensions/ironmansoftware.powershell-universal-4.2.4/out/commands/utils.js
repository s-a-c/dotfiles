"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tmpdir = void 0;
const os = require('os');
const path = require('path');
function tmpdir() {
    if (os.platform() === 'win32') {
        return path.join(os.userInfo().homedir, "AppData", "Local", "Temp");
    }
    else {
        return os.tmpdir();
    }
}
exports.tmpdir = tmpdir;
//# sourceMappingURL=utils.js.map