"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Config = void 0;
const constants_1 = require("./constants");
/**
 * The Config class.
 *
 * @class
 * @classdesc The class that represents the configuration of the extension.
 * @export
 * @public
 * @property {WorkspaceConfiguration} config - The workspace configuration
 * @property {string[]} include - The files to include
 * @property {string[]} exclude - The files to exclude
 * @property {string[]} watch - The files to watch
 * @example
 * const config = new Config(workspace.getConfiguration());
 * console.log(config.include);
 * console.log(config.exclude);
 */
class Config {
    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
    /**
     * Constructor for the Config class.
     *
     * @constructor
     * @param {WorkspaceConfiguration} config - The workspace configuration
     * @public
     * @memberof Config
     */
    constructor(config) {
        this.config = config;
        this.alias = config.get('files.alias') ?? constants_1.ALIAS;
        this.extension = config.get('files.extension') ?? constants_1.EXTENSION;
        this.showType = config.get('files.showType') ?? constants_1.SHOW_TYPE;
        this.include = config.get('files.include') ?? constants_1.INCLUDE;
        this.exclude = config.get('files.exclude') ?? constants_1.EXCLUDE;
        this.watch = config.get('files.watch') ?? constants_1.WATCH;
        this.showPath = config.get('files.showPath') ?? constants_1.SHOW_PATH;
        this.turbo = config.get('server.turbo') ?? constants_1.TURBO;
        this.experimentalHttps =
            config.get('server.experimentalHttps') ?? constants_1.EXPERIMENTAL_HTTPS;
    }
}
exports.Config = Config;
//# sourceMappingURL=config.js.map