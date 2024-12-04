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
const mysql_engine_1 = require("../../../database-engines/mysql-engine");
const mysql_1 = require("@testcontainers/mysql");
describe('MySQL Tests', () => {
    it('mysql: should return correct foreign key definitions', async () => {
        const container = await new mysql_1.MySqlContainer().start();
        let sequelize = new sequelize_1.Sequelize(container.getDatabase(), container.getUsername(), container.getUserPassword(), {
            dialect: 'mysql',
            port: container.getPort(),
            host: container.getHost(),
            dialectModule: require('mysql2'),
            logging: false
        });
        await sequelize.query(`
        CREATE TABLE ParentTable (
            id INT PRIMARY KEY AUTO_INCREMENT
        )
    `);
        await sequelize.query(`
        CREATE TABLE ChildTable (
            id INT PRIMARY KEY AUTO_INCREMENT,
            parentId INT,
            FOREIGN KEY (parentId) REFERENCES ParentTable(id)
        )
    `);
        const mysql = new mysql_engine_1.MysqlEngine(sequelize);
        const columns = await mysql.getColumns('ChildTable');
        const foreignKeyColumn = columns.find(column => column.name === 'parentId');
        assert.strictEqual(foreignKeyColumn?.foreignKey?.table, 'ParentTable');
    })
        .timeout(30000);
    describe('MysqlEngine Tests', () => {
        let mysql;
        before(async function () {
            this.timeout(30000);
            const container = await new mysql_1.MySqlContainer().start();
            let sequelize = new sequelize_1.Sequelize(container.getDatabase(), container.getUsername(), container.getUserPassword(), {
                dialect: 'mysql',
                port: container.getPort(),
                host: container.getHost(),
                dialectModule: require('mysql2'),
                logging: false
            });
            await sequelize.authenticate();
            mysql = new mysql_engine_1.MysqlEngine(sequelize);
            const ok = await mysql.isOkay();
            assert.strictEqual(ok, true);
            await mysql.sequelize?.query(`
            CREATE TABLE users (
                id INT PRIMARY KEY AUTO_INCREMENT,
                name varchar(255),
                age INT
            )
        `);
        });
        it('should return correct table names', async () => {
            await mysql.sequelize?.query(`
            CREATE TABLE products (
                id INT PRIMARY KEY,
                name varchar(255),
                price INT
            )
        `);
            const tables = await mysql.getTables();
            assert.deepStrictEqual(tables, ['products', 'users']);
        });
        it('should return correct column definitions', async () => {
            const columns = await mysql.getColumns('users');
            assert.deepStrictEqual(columns, [
                { name: 'id', type: 'int', isPrimaryKey: true, isOptional: false, foreignKey: undefined },
                { name: 'name', type: 'varchar(255)', isPrimaryKey: false, isOptional: true, foreignKey: undefined },
                { name: 'age', type: 'int', isPrimaryKey: false, isOptional: true, foreignKey: undefined }
            ]);
        });
        it('should return correct total rows', async () => {
            await mysql.sequelize?.query(`
            INSERT INTO users (name, age) VALUES
            ('John', 30),
            ('Jane', 25),
            ('Bob', 40)
        `);
            const totalRows = await mysql.getTotalRows('users', []);
            assert.strictEqual(totalRows, 3);
        });
        it('should return correct rows', async () => {
            await mysql.sequelize?.query(`
            INSERT INTO users (name, age) VALUES
            ('John', 30),
            ('Jane', 25),
            ('Bob', 40)
        `);
            const rows = await mysql.getRows('users', [], 2, 0);
            assert.deepStrictEqual(rows?.rows, [
                { id: 1, name: 'John', age: 30 },
                { id: 2, name: 'Jane', age: 25 }
            ]);
        });
        it('should return correct table creation SQL', async () => {
            const creationSql = (await mysql.getTableCreationSql('users'))
                .replace(/`/g, '')
                .replace(/\n|\t/g, '')
                .replace(/\s+/g, ' ')
                .trim();
            assert.strictEqual(creationSql, 'CREATE TABLE users ( id int NOT NULL AUTO_INCREMENT, name varchar(255) DEFAULT NULL, age int DEFAULT NULL, PRIMARY KEY (id) ) ENGINE = InnoDB AUTO_INCREMENT = 7 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci');
        });
    }).timeout(30000);
});
//# sourceMappingURL=mysql.test.js.map