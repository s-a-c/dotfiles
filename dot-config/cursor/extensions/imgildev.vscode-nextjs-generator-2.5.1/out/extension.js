"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode = require("vscode");
const configs_1 = require("./app/configs");
const controllers_1 = require("./app/controllers");
const providers_1 = require("./app/providers");
function activate(context) {
    // The code you place here will be executed every time your command is executed
    let resource;
    // Get the resource for the workspace
    if (vscode.workspace.workspaceFolders) {
        resource = vscode.workspace.workspaceFolders[0];
    }
    // -----------------------------------------------------------------
    // Initialize the extension
    // -----------------------------------------------------------------
    // Get the configuration for the extension
    const config = new configs_1.Config(vscode.workspace.getConfiguration(configs_1.EXTENSION_ID, resource));
    // -----------------------------------------------------------------
    // Register FileController and commands
    // -----------------------------------------------------------------
    // Create a new FileController
    const fileController = new controllers_1.FileController(config);
    const disposableFileClass = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.class`, (args) => fileController.newClass(args));
    const disposableFileComponent = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.component`, (args) => fileController.newComponent(args));
    const disposableFileLayout = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.layout`, (args) => fileController.newLayout(args));
    const disposableFileLoading = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.loading`, (args) => fileController.newLoading(args));
    const disposableFilePage = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.page`, (args) => fileController.newPage(args));
    const disposableFileNextAuth = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.nextauth`, (args) => fileController.newNextAuth(args));
    const disposableFileTRPCRouter = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.trpc.router`, (args) => fileController.newTRPCRouter(args));
    const disposableFileTRPCController = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.file.trpc.controller`, (args) => fileController.newTRPCController(args));
    // -----------------------------------------------------------------
    // Register TerminalController and commands
    // -----------------------------------------------------------------
    // Create a new TerminalController
    const terminalController = new controllers_1.TerminalController(config);
    const disposableTerminalNewProject = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.project`, () => terminalController.newProject());
    const disposableTerminalStart = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.start`, () => terminalController.start());
    const disposableTerminalPrismaDbExecute = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.db.execute`, () => terminalController.prismaExecute());
    const disposableTerminalPrismaDbPull = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.db.pull`, () => terminalController.prismaPull());
    const disposableTerminalPrismaDbPush = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.db.push`, () => terminalController.prismaPush());
    const disposableTerminalPrismaDbSeed = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.db.seed`, () => terminalController.prismaSeed());
    const disposableTerminalPrismaFormat = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.format`, () => terminalController.prismaFormat());
    const disposableTerminalPrismaGenerate = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.generate`, () => terminalController.prismaGenerate());
    const disposableTerminalPrismaInit = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.init`, () => terminalController.prismaInit());
    const disposableTerminalPrismaMigrateDeploy = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.migrate.deploy`, () => terminalController.prismaMigrateDeploy());
    const disposableTerminalPrismaMigrateDev = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.migrate.dev`, () => terminalController.prismaMigrateDev());
    const disposableTerminalPrismaMigrateReset = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.migrate.reset`, () => terminalController.prismaMigrateReset());
    const disposableTerminalPrismaMigrateStatus = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.migrate.status`, () => terminalController.prismaMigrateStatus());
    const disposableTerminalPrismaStudio = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.studio`, () => terminalController.prismaStudio());
    const disposableTerminalPrismaValidate = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.prisma.validate`, () => terminalController.prismaValidate());
    const disposableTerminalDrizzleGenerate = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.generate`, () => terminalController.drizzleGenerate());
    const disposableTerminalDrizzlePull = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.pull`, () => terminalController.drizzlePull());
    const disposableTerminalDrizzlePush = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.push`, () => terminalController.drizzlePush());
    const disposableTerminalDrizzleDrop = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.drop`, () => terminalController.drizzleDrop());
    const disposableTerminalDrizzleUp = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.up`, () => terminalController.drizzleUp());
    const disposableTerminalDrizzleCkeck = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.check`, () => terminalController.drizzleCkeck());
    const disposableTerminalDrizzleStudio = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.terminal.drizzle.studio`, () => terminalController.drizzleStudio());
    // -----------------------------------------------------------------
    // Register TransformController and commands
    // -----------------------------------------------------------------
    // Create a new TransformController
    const transformController = new controllers_1.TransformController();
    const disposableEditorJson2Ts = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.editor.json.ts`, () => transformController.json2ts());
    const disposableEditorJson2Zod = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.editor.json.zod`, () => transformController.json2zod());
    // -----------------------------------------------------------------
    // Register ListFilesController
    // -----------------------------------------------------------------
    // Create a new ListFilesController
    const listFilesController = new controllers_1.ListFilesController(config);
    const disposableListOpenFile = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.list.openFile`, (uri) => listFilesController.openFile(uri));
    const disposableListGotoLine = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.list.gotoLine`, (uri, line) => listFilesController.gotoLine(uri, line));
    // -----------------------------------------------------------------
    // Register ListFilesProvider and list commands
    // -----------------------------------------------------------------
    // Create a new ListFilesProvider
    const listFilesProvider = new providers_1.ListFilesProvider(listFilesController);
    // Register the list provider
    const disposableListFilesTreeView = vscode.window.createTreeView(`${configs_1.EXTENSION_ID}.listFilesView`, {
        treeDataProvider: listFilesProvider,
        showCollapseAll: true,
    });
    const disposableRefreshListFiles = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.listFiles.refresh`, () => listFilesProvider.refresh());
    // -----------------------------------------------------------------
    // Register ListRoutesProvider and list commands
    // -----------------------------------------------------------------
    // Create a new ListRoutesProvider
    const listRoutesProvider = new providers_1.ListRoutesProvider();
    // Register the list provider
    const disposableListRoutesTreeView = vscode.window.createTreeView(`${configs_1.EXTENSION_ID}.listRoutesView`, {
        treeDataProvider: listRoutesProvider,
        showCollapseAll: true,
    });
    const disposableRefreshListRoutes = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.listRoutes.refresh`, () => listRoutesProvider.refresh());
    // -----------------------------------------------------------------
    // Register ListComponentsProvider and list commands
    // -----------------------------------------------------------------
    // Create a new ListComponentsProvider
    const listComponentsProvider = new providers_1.ListComponentsProvider();
    // Register the list provider
    const disposableListComponentsTreeView = vscode.window.createTreeView(`${configs_1.EXTENSION_ID}.listComponentsView`, {
        treeDataProvider: listComponentsProvider,
        showCollapseAll: true,
    });
    const disposableRefreshListComponents = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.listComponents.refresh`, () => listComponentsProvider.refresh());
    // -----------------------------------------------------------------
    // Register ListHooksProvider and list commands
    // -----------------------------------------------------------------
    // Create a new ListHooksProvider
    const listHooksProvider = new providers_1.ListHooksProvider();
    // Register the list provider
    const disposableListHooksTreeView = vscode.window.createTreeView(`${configs_1.EXTENSION_ID}.listHooksView`, {
        treeDataProvider: listHooksProvider,
        showCollapseAll: true,
    });
    const disposableRefreshListHooks = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.listHooks.refresh`, () => listHooksProvider.refresh());
    // -----------------------------------------------------------------
    // Register ListFilesProvider and ListMethodsProvider events
    // -----------------------------------------------------------------
    vscode.workspace.onDidCreateFiles(() => {
        listFilesProvider.refresh();
        listRoutesProvider.refresh();
        listComponentsProvider.refresh();
        listHooksProvider.refresh();
    });
    vscode.workspace.onDidSaveTextDocument(() => {
        listFilesProvider.refresh();
        listRoutesProvider.refresh();
        listComponentsProvider.refresh();
        listHooksProvider.refresh();
    });
    // -----------------------------------------------------------------
    // Register FeedbackProvider and Feedback commands
    // -----------------------------------------------------------------
    // Create a new FeedbackProvider
    const feedbackProvider = new providers_1.FeedbackProvider(new controllers_1.FeedbackController());
    // Register the feedback provider
    const disposableFeedbackTreeView = vscode.window.createTreeView(`${configs_1.EXTENSION_ID}.feedbackView`, {
        treeDataProvider: feedbackProvider,
    });
    // Register the commands
    const disposableFeedbackAboutUs = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.feedback.aboutUs`, () => feedbackProvider.controller.aboutUs());
    const disposableFeedbackReportIssues = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.feedback.reportIssues`, () => feedbackProvider.controller.reportIssues());
    const disposableFeedbackRateUs = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.feedback.rateUs`, () => feedbackProvider.controller.rateUs());
    const disposableFeedbackSupportUs = vscode.commands.registerCommand(`${configs_1.EXTENSION_ID}.feedback.supportUs`, () => feedbackProvider.controller.supportUs());
    context.subscriptions.push(disposableFileClass, disposableFileComponent, disposableFileLayout, disposableFileLoading, disposableFilePage, disposableFileNextAuth, disposableFileTRPCRouter, disposableFileTRPCController, disposableTerminalNewProject, disposableTerminalStart, disposableTerminalPrismaDbExecute, disposableTerminalPrismaDbPull, disposableTerminalPrismaDbPush, disposableTerminalPrismaDbSeed, disposableTerminalPrismaFormat, disposableTerminalPrismaGenerate, disposableTerminalPrismaInit, disposableTerminalPrismaMigrateDeploy, disposableTerminalPrismaMigrateDev, disposableTerminalPrismaMigrateReset, disposableTerminalPrismaMigrateStatus, disposableTerminalPrismaStudio, disposableTerminalPrismaValidate, disposableTerminalDrizzleGenerate, disposableTerminalDrizzlePull, disposableTerminalDrizzlePush, disposableTerminalDrizzleDrop, disposableTerminalDrizzleUp, disposableTerminalDrizzleCkeck, disposableTerminalDrizzleStudio, disposableEditorJson2Ts, disposableEditorJson2Zod, disposableListOpenFile, disposableListGotoLine, disposableListFilesTreeView, disposableRefreshListFiles, disposableListRoutesTreeView, disposableRefreshListRoutes, disposableListComponentsTreeView, disposableRefreshListComponents, disposableListHooksTreeView, disposableRefreshListHooks, disposableFeedbackTreeView, disposableFeedbackAboutUs, disposableFeedbackReportIssues, disposableFeedbackRateUs, disposableFeedbackSupportUs);
}
exports.activate = activate;
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map