"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConfigFileProvider = void 0;
const vscode = __importStar(require("vscode"));
const sqlite_engine_1 = require("../database-engines/sqlite-engine");
const config_service_1 = require("../services/config-service");
const string_1 = require("../services/string");
const mysql_engine_1 = require("../database-engines/mysql-engine");
const sequelize_connector_1 = require("../services/sequelize-connector");
const postgres_engine_1 = require("../database-engines/postgres-engine");
const mssql_engine_1 = require("../database-engines/mssql-engine");
const fs_1 = require("fs");
const config_error_service_1 = require("../services/config-error-service");
exports.ConfigFileProvider = {
    name: 'Config File',
    type: 'sqlite',
    id: 'config-file-provider',
    description: 'Databases defined in your config file',
    engine: undefined,
    cache: undefined,
    async boot() {
        this.cache = undefined;
        this.engine = undefined;
    },
    async canBeUsedInCurrentWorkspace() {
        const configContent = await (0, config_service_1.getConfigFileContent)();
        if (!configContent)
            return false;
        if (!configContent.length)
            return false;
        if (!this.cache)
            this.cache = [];
        for (const config of configContent) {
            if (config.type === 'sqlite') {
                const connection = await sqliteConfigResolver(config);
                if (connection)
                    this.cache.push(connection);
            }
            const requiresName = config.type === 'mysql' || config.type === 'mariadb' || config.type === 'postgres' || config.type === 'mssql';
            if (requiresName && !config.name) {
                return await reportNameError(config);
            }
            if (config.type === 'mysql' || config.type === 'mariadb') {
                const connection = await mysqlConfigResolver(config);
                if (connection)
                    this.cache.push(connection);
            }
            if (config.type === 'postgres') {
                const connection = await postgresConfigResolver(config);
                if (connection)
                    this.cache.push(connection);
            }
            if (config.type === 'mssql') {
                const connection = await mssqlConfigResolver(config);
                if (connection)
                    this.cache.push(connection);
            }
        }
        return this.cache.length > 0;
    },
    async getDatabaseEngine(option) {
        if (option) {
            const matchedOption = this.cache?.find((cache) => cache.id === option.option.id);
            if (!matchedOption) {
                await vscode.window.showErrorMessage(`Could not find option with id ${option.option.id}`);
                return;
            }
            this.engine = matchedOption.engine;
        }
        return this.engine;
    }
};
async function reportNameError(config) {
    let typeName;
    switch (config.type) {
        case 'mysql':
            typeName = 'MySQL';
            break;
        case 'mariadb':
            typeName = 'MariaDB';
            break;
        case 'postgres':
            typeName = 'Postgres';
            break;
        case 'mssql':
            typeName = 'MSSQL';
            break;
    }
    await vscode.window.showErrorMessage(`The ${typeName} config file entry ${config.name || ''} does not have a name.`);
    return false;
}
async function mssqlConfigResolver(mssqlConfig) {
    const connection = await (0, sequelize_connector_1.getConnectionFor)('mssql', mssqlConfig.host, mssqlConfig.port, mssqlConfig.username, mssqlConfig.password, mssqlConfig.database, false);
    if (!connection)
        return;
    const engine = new mssql_engine_1.MssqlEngine(connection);
    const isOkay = (await engine.isOkay());
    if (!isOkay || !engine.sequelize) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)(`The MSSQL connection ${mssqlConfig.name || ''} specified in your config file is not valid.`, mssqlConfig);
        return;
    }
    return {
        id: mssqlConfig.name,
        description: mssqlConfig.name,
        engine: engine
    };
}
async function sqliteConfigResolver(sqliteConnection) {
    if (!(0, fs_1.existsSync)(sqliteConnection.path)) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)(`A path to an SQLite database file specified in your config file is not valid: ${sqliteConnection.path}`, sqliteConnection);
        return Promise.resolve(undefined);
    }
    const engine = new sqlite_engine_1.SqliteEngine(sqliteConnection.path);
    const isOkay = (await engine.isOkay());
    if (!isOkay || !engine.sequelize) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)('The SQLite database specified in your config file is not valid.', sqliteConnection);
        return;
    }
    else {
        return {
            id: sqliteConnection.path,
            details: sqliteConnection.path,
            description: (0, string_1.brief)(sqliteConnection.path),
            engine: engine
        };
    }
}
async function mysqlConfigResolver(mysqlConfig) {
    const connection = await (0, sequelize_connector_1.getConnectionFor)('mysql', mysqlConfig.host, mysqlConfig.port, mysqlConfig.username, mysqlConfig.password, mysqlConfig.database, false);
    if (!connection) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)(`The MySQL connection ${mysqlConfig.name || ''} specified in your config file is not valid.`, mysqlConfig);
        return;
    }
    const engine = new mysql_engine_1.MysqlEngine(connection);
    const isOkay = (await engine.isOkay());
    if (!isOkay || !engine.sequelize) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)(`The MySQL connection ${mysqlConfig.name || ''} specified in your config file is not valid.`, mysqlConfig);
        return;
    }
    return {
        id: mysqlConfig.name,
        description: mysqlConfig.name,
        engine: engine
    };
}
async function postgresConfigResolver(postgresConfig) {
    const connection = await (0, sequelize_connector_1.getConnectionFor)('postgres', postgresConfig.host, postgresConfig.port, postgresConfig.username, postgresConfig.password, postgresConfig.database, false);
    if (!connection) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)(`The Postgres connection ${postgresConfig.name || ''} specified in your config file is not valid.`, postgresConfig);
        return;
    }
    const engine = new postgres_engine_1.PostgresEngine(connection);
    const isOkay = (await engine.isOkay());
    if (!isOkay || !engine.sequelize) {
        await (0, config_error_service_1.showErrorWithConfigFileButton)(`The Postgres connection ${postgresConfig.name || ''} specified in your config file is not valid.`, postgresConfig);
        return;
    }
    return {
        id: postgresConfig.name,
        description: postgresConfig.name,
        engine: engine
    };
}
//# sourceMappingURL=config-file-provider.js.map