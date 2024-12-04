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
const assert = __importStar(require("assert"));
const sequelize_1 = require("sequelize");
const sql_1 = require("../../../services/sql");
describe('SqliteService Tests', () => {
    let sequelize;
    beforeEach(async () => {
        sequelize = new sequelize_1.Sequelize({ dialect: 'sqlite', logging: false });
        await sequelize.authenticate();
    });
    afterEach(async () => {
        await sequelize.close();
    });
    it('ensures buildWhereClause returns empty arrays when whereClause is undefined', () => {
        const { where, replacements } = sql_1.SqlService.buildWhereClause('sqlite', [], '`', undefined);
        assert.deepStrictEqual(where, []);
        assert.deepStrictEqual(replacements, []);
    });
    it('ensures buildWhereClause returns correct arrays when whereClause is defined', () => {
        const whereClause = { name: 'John', age: 30 };
        const columns = [{
                name: 'name',
                type: 'text',
                isPrimaryKey: false,
                isOptional: true,
            }, {
                name: 'age',
                type: 'integer',
                isPrimaryKey: false,
                isOptional: true,
            }];
        const { where, replacements } = sql_1.SqlService.buildWhereClause('sqlite', columns, '`', whereClause);
        assert.deepStrictEqual(where, ['`name` LIKE ?', '`age` LIKE ?']);
        assert.deepStrictEqual(replacements, ['%John%', '%30%']);
    });
    it('ensures getRows returns correct rows and sql when sequelize is not null', async () => {
        await sequelize.query(`
			CREATE TABLE users (
				id INTEGER PRIMARY KEY,
				name TEXT,
				age INTEGER
			)
		`);
        await sequelize.query(`
			INSERT INTO users (name, age) VALUES
			('John', 30),
			('Jane', 25),
			('Bob', 40)
		`);
        const whereClause = { name: 'J' };
        const columns = [{
                name: 'name',
                type: 'text',
                isPrimaryKey: false,
                isOptional: true,
            }, {
                name: 'age',
                type: 'integer',
                isPrimaryKey: false,
                isOptional: true,
            }];
        const result = await sql_1.SqlService.getRows('sqlite', sequelize, 'users', columns, 2, 0, whereClause);
        assert.deepStrictEqual(result?.rows, [
            { id: 1, name: 'John', age: 30 },
            { id: 2, name: 'Jane', age: 25 }
        ]);
        assert.strictEqual(result?.sql, "Executing (default): SELECT * FROM `users` WHERE `name` LIKE '%J%' LIMIT 2");
    });
    it('ensures initializePaginationFor returns null when sequelize is null', async () => {
        const result = await sql_1.SqlService.getTotalRows('sqlite', null, 'users', []);
        assert.strictEqual(result, undefined);
    });
    it('ensures initializePaginationFor returns correct pagination data when sequelize is not null', async () => {
        await sequelize.query(`
			CREATE TABLE users (
				id INTEGER PRIMARY KEY,
				name TEXT,
				age INTEGER
			)
		`);
        await sequelize.query(`
			INSERT INTO users (name, age) VALUES
			('John', 30),
			('Jane', 25),
			('Bob', 40)
		`);
        const result = await sql_1.SqlService.getTotalRows('sqlite', sequelize, 'users', []);
        assert.equal(result, 3);
    });
});
//# sourceMappingURL=sql.test.js.map