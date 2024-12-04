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
const postgres_engine_1 = require("../../../database-engines/postgres-engine");
const postgresql_1 = require("@testcontainers/postgresql");
/**
 * We use a predefined image like this because docker image download can be ery very slow, hence
 * on new computer/initial setup when the image is not already existing, it takes a very long time
 * to run this test. Using a predefined image name like this makes it possible to us to manually
 * download the image (e.g. using `docker run ...`) to ensure it exists in the system before running the test.
 */
const dockerImage = 'postgres:13.3-alpine';
describe('PostgreSQL Tests', () => {
    it('postgres: should return correct foreign key definitions', async () => {
        const container = await new postgresql_1.PostgreSqlContainer(dockerImage).start();
        let sequelize = new sequelize_1.Sequelize(container.getDatabase(), container.getUsername(), container.getPassword(), {
            dialect: 'postgres',
            port: container.getPort(),
            host: container.getHost(),
            logging: false
        });
        await sequelize.query(`
        CREATE TABLE ParentTable (
            id SERIAL PRIMARY KEY
        )
    `);
        await sequelize.query(`
        CREATE TABLE ChildTable (
            id SERIAL PRIMARY KEY,
            parentId INT,
            FOREIGN KEY (parentId) REFERENCES ParentTable(id)
        )
    `);
        const postgres = new postgres_engine_1.PostgresEngine(sequelize);
        const columns = await postgres.getColumns('ChildTable');
        const foreignKeyColumn = columns.find(column => column.name === 'parentid');
        assert.strictEqual(foreignKeyColumn?.foreignKey?.table, 'parenttable');
    })
        .timeout(30000);
    describe('PostgresEngine Tests', () => {
        let postgres;
        before(async function () {
            this.timeout(30000);
            const container = await new postgresql_1.PostgreSqlContainer(dockerImage).start();
            let sequelize = new sequelize_1.Sequelize(container.getDatabase(), container.getUsername(), container.getPassword(), {
                dialect: 'postgres',
                port: container.getPort(),
                host: container.getHost(),
                logging: false
            });
            await sequelize.authenticate();
            postgres = new postgres_engine_1.PostgresEngine(sequelize);
            const ok = await postgres.isOkay();
            assert.strictEqual(ok, true);
            await postgres.sequelize?.query(`
            CREATE TABLE users (
                id SERIAL PRIMARY KEY,
                name varchar(255),
                age INT
            )
        `);
        });
        it('should return correct table names', async () => {
            await postgres.sequelize?.query(`
            CREATE TABLE products (
                id SERIAL PRIMARY KEY,
                name varchar(255),
                price INT
            )
        `);
            const tables = await postgres.getTables();
            assert.deepStrictEqual(tables.sort(), ['products', 'users']);
        });
        it('should return correct column definitions', async () => {
            const columns = await postgres.getColumns('users');
            assert.deepStrictEqual(columns, [
                { name: 'id', type: 'integer', isPrimaryKey: false, isOptional: false, foreignKey: undefined },
                { name: 'name', type: 'character varying', isPrimaryKey: false, isOptional: false, foreignKey: undefined },
                { name: 'age', type: 'integer', isPrimaryKey: false, isOptional: false, foreignKey: undefined }
            ]);
        });
        it('should return correct total rows', async () => {
            await postgres.sequelize?.query(`
            INSERT INTO users (name, age) VALUES
            ('John', 30),
            ('Jane', 25),
            ('Bob', 40)
        `);
            const totalRows = await postgres.getTotalRows('users', []);
            assert.strictEqual(totalRows, 3);
        });
        it('should return correct rows', async () => {
            await postgres.sequelize?.query(`
            INSERT INTO users (name, age) VALUES
            ('John', 30),
            ('Jane', 25),
            ('Bob', 40)
        `);
            const rows = await postgres.getRows('users', [], 2, 0);
            assert.deepStrictEqual(rows?.rows, [
                { id: 1, name: 'John', age: 30 },
                { id: 2, name: 'Jane', age: 25 }
            ]);
        });
        it('should return correct table creation SQL', async () => {
            const creationSql = (await postgres.getTableCreationSql('users'))
                .replace(/"/g, '')
                .replace(/\n|\t/g, '')
                .replace(/\s+/g, ' ')
                .trim();
            assert.strictEqual(creationSql, 'CREATE TABLE users (id integer, name character varying(255), age integer);');
        });
        it('should filter values in uuid and integer column types', async () => {
            await postgres.sequelize?.query(`
					CREATE TABLE test_table (
						id SERIAL PRIMARY KEY,
						uuid_col UUID,
						int_col INT
					)
				`);
            const uuid1 = '33e09dc0-838e-4584-bc22-8de273c4f1c9';
            const uuid2 = '3314dc82-2989-4133-8108-ee9b0ba475b9';
            await postgres.sequelize?.query(`
		INSERT INTO test_table (uuid_col, int_col) VALUES
		('${uuid1}', 100),
		('${uuid2}', 200)
	`);
            const integerFilteredRows = await postgres.getRows('test_table', [
                { name: 'uuid_col', type: 'uuid', isPrimaryKey: false, isOptional: true },
                { name: 'int_col', type: 'int4', isPrimaryKey: false, isOptional: true }
            ], 10, 0, { int_col: 20 });
            assert.strictEqual(integerFilteredRows?.rows.length, 1);
            assert.strictEqual(integerFilteredRows?.rows[0].int_col, 200);
        });
        it('should filter values in timestamp column types', async () => {
            await postgres.sequelize?.query(`
				CREATE TABLE timestamp_test (
					id SERIAL PRIMARY KEY,
					created_at TIMESTAMP
				)
			`);
            await postgres.sequelize?.query(`
				INSERT INTO timestamp_test (created_at) VALUES
				('2024-10-14 10:00:00'),
				('2024-10-14 12:00:00')
			`);
            const timestampFilteredRows = await postgres.getRows('timestamp_test', [
                { name: 'created_at', type: 'timestamp', isPrimaryKey: false, isOptional: true }
            ], 10, 0, { created_at: '2024-10-14 10:00:00' });
            assert.strictEqual(timestampFilteredRows?.rows.length, 1);
            assert.strictEqual(timestampFilteredRows?.rows[0].created_at.toISOString(), new Date('2024-10-14 10:00:00').toISOString());
        });
    }).timeout(30000);
});
//# sourceMappingURL=postgres.test.js.map