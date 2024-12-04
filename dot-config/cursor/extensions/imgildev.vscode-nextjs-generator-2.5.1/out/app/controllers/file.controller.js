"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FileController = void 0;
const helpers_1 = require("../helpers");
/**
 * The FileController class.
 *
 * @class
 * @classdesc The class that represents the example controller.
 * @export
 * @public
 * @property {Config} config - The configuration
 * @example
 * const controller = new FileController(config);
 */
class FileController {
    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
    /**
     * Constructor for the FileController class.
     *
     * @constructor
     * @param {Config} config - The configuration
     * @public
     * @memberof FileController
     */
    constructor(config) {
        this.config = config;
    }
    // -----------------------------------------------------------------
    // Methods
    // -----------------------------------------------------------------
    // Public methods
    /**
     * Creates a new class.
     *
     * @function newClass
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newClass();
     *
     * @returns {Promise<void>} - No return value
     */
    async newClass(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        // Get the type
        let type = await (0, helpers_1.getName)('Type class name', 'E.g. class, interface, type, enum...', (type) => {
            if (!/[a-z]+/.test(type)) {
                return 'Invalid format!';
            }
            return;
        });
        if (!type) {
            return;
        }
        // Get the class name
        const className = await (0, helpers_1.getName)('Name', 'E.g. User, Role, Post...', (name) => {
            if (!/^[A-Z][A-Za-z]{2,}$/.test(name)) {
                return 'Invalid format! Entity names MUST be declared in PascalCase.';
            }
            return;
        });
        if (!className) {
            return;
        }
        const content = `export default ${type} ${className}${(0, helpers_1.titleize)(type)} {
\t// ... your code goes here
}
`;
        if (this.config.showType) {
            type += '.';
        }
        else {
            type = '';
        }
        const filename = `${(0, helpers_1.dasherize)(className)}.${type}${this.config.extension}`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new component.
     *
     * @function newComponent
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newComponent();
     *
     * @returns {Promise<void>} - No return value
     */
    async newComponent(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        // Get the function name
        const functionName = await (0, helpers_1.getName)('Component Name', 'E.g. Title, Header, Main, Footer...', (name) => {
            if (!/^[A-Z][A-Za-z]{2,}$/.test(name)) {
                return 'Invalid format! Entity names MUST be declared in PascalCase.';
            }
            return;
        });
        if (!functionName) {
            return;
        }
        const content = `interface ${functionName}Props {
\tchildren: React.ReactNode;
}

export function ${functionName}({ children }: ${functionName}Props) {
\treturn (
\t\t<>
\t\t\t<h1>${functionName}</h1>
\t\t\t{children}
\t\t</>
\t);
}
`;
        let type = '';
        if (this.config.showType) {
            type = 'component.';
        }
        const filename = `${(0, helpers_1.dasherize)(functionName)}.${type}tsx`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new layout.
     *
     * @function newLayout
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newLayout();
     *
     * @returns {Promise<void>} - No return value
     */
    async newLayout(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        const content = `import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
\ttitle: 'Create Next App',
\tdescription: 'Create Next App with TypeScript, Tailwind CSS, NextAuth, Prisma, tRPC, and more.',
}

export default function Layout({
\tchildren,
}: {
\tchildren: React.ReactNode
}) {
\treturn (
\t\t<html lang="en">
\t\t\t<body className={inter.className}>{children}</body>
\t\t</html>
\t)
}
`;
        const filename = `layout.tsx`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new loading component.
     *
     * @function newLoading
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newLoading();
     *
     * @returns {Promise<void>} - No return value
     */
    async newLoading(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        const content = `export default function Loading() {
\treturn <p>Loading...</p>
}
`;
        const filename = `loading.tsx`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new page.
     *
     * @function newPage
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newPage();
     *
     * @returns {Promise<void>} - No return value
     */
    async newPage(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        const content = `'use client'

interface Props {
\tparams: {
\t\tid: string;
\t};
}

export default function Page({ params }: Props) {
\tconst { id } = params;

\treturn (
\t\t<>
\t\t\t<h1>Page { id }</h1>
\t\t\t<p>Page content</p>
\t\t</>
\t);
}
`;
        const filename = `page.tsx`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new auth.
     *
     * @function newNextAuth
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newNextAuth();
     *
     * @returns {Promise<void>} - No return value
     */
    async newNextAuth(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        const content = `import NextAuth from 'next-auth';

export const authOptions = {
\tproviders: [
\t\t// Providers...
\t],
};

export default NextAuth(authOptions);
`;
        const filename = `[...nextauth].${this.config.extension}`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new tRPC router.
     *
     * @function newTRPCRouter
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newTRPCRouter();
     *
     * @returns {Promise<void>} - No return value
     */
    async newTRPCRouter(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        // Get the entity name
        let entityName = await (0, helpers_1.getName)('Router name', 'E.g. user, subscription, auth...', (text) => {
            if (!/^[a-z][\w-]+$/.test(text)) {
                return 'Invalid format! Entity names MUST be declared in camelCase.';
            }
            return;
        });
        if (!entityName) {
            return;
        }
        const content = `import { z } from 'zod';

import {
\tcreateTRPCRouter,
\t// protectedProcedure,
\tpublicProcedure,
} from '${this.config.alias}/server/api/trpc';

export const ${entityName}Router = createTRPCRouter({
\t// prefix: t.procedure.input(callable).query(async (args) => handler(args)),
});
`;
        let type = '';
        if (this.config.showType) {
            type = 'router.';
        }
        const filename = `${(0, helpers_1.dasherize)(entityName)}.${type}${this.config.extension}`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
    /**
     * Creates a new tRPC controller.
     *
     * @function newTRPCController
     * @param {Uri} [path] - The path to the folder
     * @public
     * @async
     * @memberof FileController
     * @example
     * await controller.newTRPCController();
     *
     * @returns {Promise<void>} - No return value
     */
    async newTRPCController(path) {
        // Get the relative path
        const folderPath = path ? await (0, helpers_1.getRelativePath)(path.path) : '';
        // Get the path to the folder
        const folder = await (0, helpers_1.getPath)('Folder name', 'Folder name. E.g. src, app...', folderPath, (path) => {
            if (!/^(?!\/)[^\sÀ-ÿ]+?$/.test(path)) {
                return 'The folder name must be a valid name';
            }
            return;
        });
        if (!folder) {
            return;
        }
        // Get the entity name
        let entityName = await (0, helpers_1.getName)('Controller name', 'E.g. user, subscription, auth...', (text) => {
            if (!/^[a-z][\w-]+$/.test(text)) {
                return 'Invalid format! Entity names MUST be declared in camelCase.';
            }
            return;
        });
        if (!entityName) {
            return;
        }
        const content = `import { TRPCError } from '@trpc/server';
import { z, ZodError } from 'zod';

import {
\tcreateTRPCRouter,
\t// protectedProcedure,
\tpublicProcedure,
} from '${this.config.alias}/server/api/trpc';

export const getAll = async () => {
\ttry {
\t\t// ... your code goes here
\t} catch (error) {
\t\tif (error instanceof ZodError) {
\t\t\tthrow new TRPCError({
\t\t\t\tcode: 'BAD_REQUEST',
\t\t\t\tmessage: error.message,
\t\t\t});
\t\t}

\t\tif (error instanceof TRPCError) {
\t\t\tif (error.code === 'UNAUTHORIZED') {
\t\t\t\tthrow new TRPCError({
\t\t\t\t\tcode: 'UNAUTHORIZED',
\t\t\t\t\tmessage: 'Unauthorized',
\t\t\t\t});
\t\t\t}

\t\t\tthrow new TRPCError({
\t\t\t\tcode: 'INTERNAL_SERVER_ERROR',
\t\t\t\tmessage: error.message,
\t\t\t});
\t\t}
\t}
};
`;
        let type = '';
        if (this.config.showType) {
            type = 'controller.';
        }
        const filename = `${(0, helpers_1.dasherize)(entityName)}.${type}${this.config.extension}`;
        (0, helpers_1.saveFile)(folder, filename, content);
    }
}
exports.FileController = FileController;
//# sourceMappingURL=file.controller.js.map