
declare global {
  import Parser from "web-tree-sitter";
  import { GetGhTokenArgs } from "./protocol/ide";
  declare global {
    interface Window {
      ide?: "vscode";
      windowId: string;
      serverUrl: string;
      vscMachineId: string;
      vscMediaUrl: string;
      fullColorTheme?: {
        rules?: {
          token?: string;
          foreground?: string;
        }[];
      };
      colorThemeName?: string;
      workspacePaths?: string[];
      postIntellijMessage?: (
        messageType: string,
        data: any,
        messageIde: string,
      ) => void;
    }
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ChunkWithoutID {
    content: string;
    startLine: number;
    endLine: number;
    signature?: string;
    otherMetadata?: { [key: string]: any };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface Chunk extends ChunkWithoutID {
    digest: string;
    filepath: string;
    index: number; // Index of the chunk in the document at filepath
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface IndexingProgressUpdate {
    progress: number;
    desc: string;
    shouldClearIndexes?: boolean;
    status:
      | "loading"
      | "indexing"
      | "done"
      | "failed"
      | "paused"
      | "disabled"
      | "cancelled";
    debugInfo?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // This is more or less a V2 of IndexingProgressUpdate for docs etc.
  export interface IndexingStatus {
    id: string;
    type: "docs";
    progress: number;
    description: string;
    status: "indexing" | "complete" | "paused" | "failed" | "aborted" | "pending";
    embeddingsProviderId: string;
    isReindexing?: boolean;
    debugInfo?: string;
    title: string;
    icon?: string;
    url?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export type PromptTemplateFunction = (
    history: ChatMessage[],
    otherData: Record<string, string>,
  ) => string | ChatMessage[];
<<<<<<< HEAD

  export type PromptTemplate = string | PromptTemplateFunction;

  export interface ILLM extends LLMOptions {
    get providerName(): string;

    uniqueId: string;
    model: string;

=======
  
  export type PromptTemplate = string | PromptTemplateFunction;
  
  export interface ILLM extends LLMOptions {
    get providerName(): string;
  
    uniqueId: string;
    model: string;
  
>>>>>>> origin/develop
    title?: string;
    systemMessage?: string;
    contextLength: number;
    maxStopWords?: number;
    completionOptions: CompletionOptions;
    requestOptions?: RequestOptions;
    promptTemplates?: Record<string, PromptTemplate>;
    templateMessages?: (messages: ChatMessage[]) => string;
    llmLogger?: ILLMLogger;
    llmRequestHook?: (model: string, prompt: string) => any;
    apiKey?: string;
    apiBase?: string;
    cacheBehavior?: CacheBehavior;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    deployment?: string;
    apiVersion?: string;
    apiType?: string;
    region?: string;
    projectId?: string;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    // Embedding options
    embeddingId: string;
    maxEmbeddingChunkSize: number;
    maxEmbeddingBatchSize: number;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    complete(
      prompt: string,
      signal: AbortSignal,
      options?: LLMFullCompletionOptions,
    ): Promise<string>;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    streamComplete(
      prompt: string,
      signal: AbortSignal,
      options?: LLMFullCompletionOptions,
    ): AsyncGenerator<string, PromptLog>;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    streamFim(
      prefix: string,
      suffix: string,
      signal: AbortSignal,
      options?: LLMFullCompletionOptions,
    ): AsyncGenerator<string, PromptLog>;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    streamChat(
      messages: ChatMessage[],
      signal: AbortSignal,
      options?: LLMFullCompletionOptions,
    ): AsyncGenerator<ChatMessage, PromptLog>;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    chat(
      messages: ChatMessage[],
      signal: AbortSignal,
      options?: LLMFullCompletionOptions,
    ): Promise<ChatMessage>;
<<<<<<< HEAD

    embed(chunks: string[]): Promise<number[][]>;

    rerank(query: string, chunks: Chunk[]): Promise<number[]>;

    countTokens(text: string): number;

    supportsImages(): boolean;

    supportsCompletions(): boolean;

    supportsPrefill(): boolean;

    supportsFim(): boolean;

    listModels(): Promise<string[]>;

=======
  
    embed(chunks: string[]): Promise<number[][]>;
  
    rerank(query: string, chunks: Chunk[]): Promise<number[]>;
  
    countTokens(text: string): number;
  
    supportsImages(): boolean;
  
    supportsCompletions(): boolean;
  
    supportsPrefill(): boolean;
  
    supportsFim(): boolean;
  
    listModels(): Promise<string[]>;
  
>>>>>>> origin/develop
    renderPromptTemplate(
      template: PromptTemplate,
      history: ChatMessage[],
      otherData: Record<string, string>,
      canPutWordsInModelsMouth?: boolean,
    ): string | ChatMessage[];
  }
<<<<<<< HEAD

  export type ContextProviderType = "normal" | "query" | "submenu";

=======
  
  export type ContextProviderType = "normal" | "query" | "submenu";
  
>>>>>>> origin/develop
  export interface ContextProviderDescription {
    title: ContextProviderName;
    displayTitle: string;
    description: string;
    renderInlineAs?: string;
    type: ContextProviderType;
    dependsOnIndexing?: boolean;
  }
<<<<<<< HEAD

  export type FetchFunction = (url: string | URL, init?: any) => Promise<any>;

=======
  
  export type FetchFunction = (url: string | URL, init?: any) => Promise<any>;
  
>>>>>>> origin/develop
  export interface ContextProviderExtras {
    config: ContinueConfig;
    fullInput: string;
    embeddingsProvider: ILLM;
    reranker: ILLM | undefined;
    llm: ILLM;
    ide: IDE;
    selectedCode: RangeInFile[];
    fetch: FetchFunction;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LoadSubmenuItemsArgs {
    config: ContinueConfig;
    ide: IDE;
    fetch: FetchFunction;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface CustomContextProvider {
    title: string;
    displayTitle?: string;
    description?: string;
    renderInlineAs?: string;
    type?: ContextProviderType;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    getContextItems(
      query: string,
      extras: ContextProviderExtras,
    ): Promise<ContextItem[]>;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    loadSubmenuItems?: (
      args: LoadSubmenuItemsArgs,
    ) => Promise<ContextSubmenuItem[]>;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ContextSubmenuItem {
    id: string;
    title: string;
    description: string;
    icon?: string;
    metadata?: any;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface SiteIndexingConfig {
    title: string;
    startUrl: string;
    maxDepth?: number;
    faviconUrl?: string;
  }
<<<<<<< HEAD

  export interface IContextProvider {
    get description(): ContextProviderDescription;

=======
  
  export interface IContextProvider {
    get description(): ContextProviderDescription;
  
>>>>>>> origin/develop
    getContextItems(
      query: string,
      extras: ContextProviderExtras,
    ): Promise<ContextItem[]>;
<<<<<<< HEAD

    loadSubmenuItems(args: LoadSubmenuItemsArgs): Promise<ContextSubmenuItem[]>;
  }

=======
  
    loadSubmenuItems(args: LoadSubmenuItemsArgs): Promise<ContextSubmenuItem[]>;
  }
  
>>>>>>> origin/develop
  export interface Session {
    sessionId: string;
    title: string;
    workspaceDirectory: string;
    history: ChatHistoryItem[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface SessionMetadata {
    sessionId: string;
    title: string;
    dateCreated: string;
    workspaceDirectory: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface RangeInFile {
    filepath: string;
    range: Range;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface Location {
    filepath: string;
    position: Position;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface FileWithContents {
    filepath: string;
    contents: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface Range {
    start: Position;
    end: Position;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface Position {
    line: number;
    character: number;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface FileEdit {
    filepath: string;
    range: Range;
    replacement: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ContinueError {
    title: string;
    message: string;
  }
<<<<<<< HEAD

  export interface CompletionOptions extends BaseCompletionOptions {
    model: string;
  }

  export type ChatMessageRole = "user" | "assistant" | "system" | "tool";

=======
  
  export interface CompletionOptions extends BaseCompletionOptions {
    model: string;
  }
  
  export type ChatMessageRole = "user" | "assistant" | "system" | "tool";
  
>>>>>>> origin/develop
  export interface MessagePart {
    type: "text" | "imageUrl";
    text?: string;
    imageUrl?: { url: string };
  }
<<<<<<< HEAD

  export type MessageContent = string | MessagePart[];

=======
  
  export type MessageContent = string | MessagePart[];
  
>>>>>>> origin/develop
  export interface ToolCall {
    id: string;
    type: "function";
    function: {
      name: string;
      arguments: string;
    };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ToolCallDelta {
    id?: string;
    type?: "function";
    function?: {
      name?: string;
      arguments?: string;
    };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ToolResultChatMessage {
    role: "tool";
    content: string;
    toolCallId: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface UserChatMessage {
    role: "user";
    content: MessageContent;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface AssistantChatMessage {
    role: "assistant";
    content: MessageContent;
    toolCalls?: ToolCallDelta[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface SystemChatMessage {
    role: "system";
    content: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export type ChatMessage =
    | UserChatMessage
    | AssistantChatMessage
    | SystemChatMessage
    | ToolResultChatMessage;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ContextItemId {
    providerTitle: string;
    itemId: string;
  }
<<<<<<< HEAD

  export type ContextItemUriTypes = "file" | "url";

=======
  
  export type ContextItemUriTypes = "file" | "url";
  
>>>>>>> origin/develop
  export interface ContextItemUri {
    type: ContextItemUriTypes;
    value: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ContextItem {
    content: string;
    name: string;
    description: string;
    editing?: boolean;
    editable?: boolean;
    icon?: string;
    uri?: ContextItemUri;
    hidden?: boolean;
  }
<<<<<<< HEAD

  export interface ContextItemWithId extends ContextItem {
    id: ContextItemId;
  }

=======
  
  export interface ContextItemWithId extends ContextItem {
    id: ContextItemId;
  }
  
>>>>>>> origin/develop
  export interface InputModifiers {
    useCodebase: boolean;
    noContext: boolean;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface SymbolWithRange extends RangeInFile {
    name: string;
    type: Parser.SyntaxNode["type"];
    content: string;
  }
<<<<<<< HEAD

  export type FileSymbolMap = Record<string, SymbolWithRange[]>;

=======
  
  export type FileSymbolMap = Record<string, SymbolWithRange[]>;
  
>>>>>>> origin/develop
  export interface PromptLog {
    modelTitle: string;
    completionOptions: CompletionOptions;
    prompt: string;
    completion: string;
  }
<<<<<<< HEAD

  type MessageModes = "chat" | "edit";

=======
  
  type MessageModes = "chat" | "edit";
  
>>>>>>> origin/develop
  export type ToolStatus =
    | "generating"
    | "generated"
    | "calling"
    | "done"
    | "errored"
    | "canceled";
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // Will exist only on "assistant" messages with tool calls
  interface ToolCallState {
    toolCallId: string;
    toolCall: ToolCall;
    status: ToolStatus;
    parsedArgs: any;
    output?: ContextItem[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ChatHistoryItem {
    message: ChatMessage;
    contextItems: ContextItemWithId[];
    editorState?: any;
    modifiers?: InputModifiers;
    promptLogs?: PromptLog[];
    toolCallState?: ToolCallState;
    isGatheringContext?: boolean;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMFullCompletionOptions extends BaseCompletionOptions {
    log?: boolean;
    model?: string;
  }
<<<<<<< HEAD

  export type ToastType = "info" | "error" | "warning";

=======
  
  export type ToastType = "info" | "error" | "warning";
  
>>>>>>> origin/develop
  export interface LLMInteractionBase {
    interactionId: string;
    timestamp: number;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMInteractionStartChat extends LLMInteractionBase {
    kind: "startChat";
    messages: ChatMessage[];
    options: CompletionOptions;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMInteractionStartComplete extends LLMInteractionBase {
    kind: "startComplete";
    prompt: string;
    options: CompletionOptions;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMInteractionStartFim extends LLMInteractionBase {
    kind: "startFim";
    prefix: string;
    suffix: string;
    options: CompletionOptions;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMInteractionChunk extends LLMInteractionBase {
    kind: "chunk";
    chunk: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMInteractionMessage extends LLMInteractionBase {
    kind: "message";
    message: ChatMessage;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface LLMInteractionEnd extends LLMInteractionBase {
    promptTokens: number;
    generatedTokens: number;
    thinkingTokens: number;
  }
<<<<<<< HEAD

  export interface LLMInteractionSuccess extends LLMInteractionEnd {
    kind: "success";
  }

  export interface LLMInteractionCancel extends LLMInteractionEnd {
    kind: "cancel";
  }

=======
  
  export interface LLMInteractionSuccess extends LLMInteractionEnd {
    kind: "success";
  }
  
  export interface LLMInteractionCancel extends LLMInteractionEnd {
    kind: "cancel";
  }
  
>>>>>>> origin/develop
  export interface LLMInteractionError extends LLMInteractionEnd {
    kind: "error";
    name: string;
    message: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export type LLMInteractionItem =
    | LLMInteractionStartChat
    | LLMInteractionStartComplete
    | LLMInteractionStartFim
    | LLMInteractionChunk
    | LLMInteractionMessage
    | LLMInteractionSuccess
    | LLMInteractionCancel
    | LLMInteractionError;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // When we log a LLM interaction, we want to add the interactionId and timestamp
  // in the logger code, so we need a type that omits these members from *each*
  // member of the union. This can be done by using the distributive behavior of
  // conditional types in Typescript.
  //
  // www.typescriptlang.org/docs/handbook/2/conditional-types.html#distributive-conditional-types
  // https://stackoverflow.com/questions/57103834/typescript-omit-a-property-from-all-interfaces-in-a-union-but-keep-the-union-s
  type DistributiveOmit<T, K extends PropertyKey> = T extends unknown
    ? Omit<T, K>
    : never;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export type LLMInteractionItemDetails = DistributiveOmit<
    LLMInteractionItem,
    "interactionId" | "timestamp"
  >;
<<<<<<< HEAD

  export interface ILLMInteractionLog {
    logItem(item: LLMInteractionItemDetails): void;
  }

  export interface ILLMLogger {
    createInteractionLog(): ILLMInteractionLog;
  }

  export interface LLMOptions {
    model: string;

=======
  
  export interface ILLMInteractionLog {
    logItem(item: LLMInteractionItemDetails): void;
  }
  
  export interface ILLMLogger {
    createInteractionLog(): ILLMInteractionLog;
  }
  
  export interface LLMOptions {
    model: string;
  
>>>>>>> origin/develop
    title?: string;
    uniqueId?: string;
    systemMessage?: string;
    contextLength?: number;
    maxStopWords?: number;
    completionOptions?: CompletionOptions;
    requestOptions?: RequestOptions;
    template?: TemplateType;
    promptTemplates?: Record<string, PromptTemplate>;
    templateMessages?: (messages: ChatMessage[]) => string;
    logger?: ILLMLogger;
    llmRequestHook?: (model: string, prompt: string) => any;
    apiKey?: string;
    aiGatewaySlug?: string;
    apiBase?: string;
    cacheBehavior?: CacheBehavior;
<<<<<<< HEAD

    useLegacyCompletionsEndpoint?: boolean;

=======
  
    useLegacyCompletionsEndpoint?: boolean;
  
>>>>>>> origin/develop
    // Embedding options
    embeddingId?: string;
    maxEmbeddingChunkSize?: number;
    maxEmbeddingBatchSize?: number;
<<<<<<< HEAD

    // Cloudflare options
    accountId?: string;

=======
  
    // Cloudflare options
    accountId?: string;
  
>>>>>>> origin/develop
    // Azure options
    deployment?: string;
    apiVersion?: string;
    apiType?: string;
<<<<<<< HEAD

    // AWS options
    profile?: string;
    modelArn?: string;

    // AWS and GCP Options
    region?: string;

    // GCP Options
    capabilities?: ModelCapability;

    // GCP and Watsonx Options
    projectId?: string;

    // IBM watsonx Options
    deploymentId?: string;
  }

=======
  
    // AWS options
    profile?: string;
    modelArn?: string;
  
    // AWS and GCP Options
    region?: string;
  
    // GCP Options
    capabilities?: ModelCapability;
  
    // GCP and Watsonx Options
    projectId?: string;
  
    // IBM watsonx Options
    deploymentId?: string;
  }
  
>>>>>>> origin/develop
  type RequireAtLeastOne<T, Keys extends keyof T = keyof T> = Pick<
    T,
    Exclude<keyof T, Keys>
  > &
    {
      [K in Keys]-?: Required<Pick<T, K>> & Partial<Pick<T, Exclude<Keys, K>>>;
    }[Keys];
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface CustomLLMWithOptionals {
    options: LLMOptions;
    streamCompletion?: (
      prompt: string,
      signal: AbortSignal,
      options: CompletionOptions,
      fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>,
    ) => AsyncGenerator<string>;
    streamChat?: (
      messages: ChatMessage[],
      signal: AbortSignal,
      options: CompletionOptions,
      fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>,
    ) => AsyncGenerator<string>;
    listModels?: (
      fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>,
    ) => Promise<string[]>;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  /**
   * The LLM interface requires you to specify either `streamCompletion` or `streamChat` (or both).
   */
  export type CustomLLM = RequireAtLeastOne<
    CustomLLMWithOptionals,
    "streamCompletion" | "streamChat"
  >;
<<<<<<< HEAD

  // IDE

  export type DiffLineType = "new" | "old" | "same";

=======
  
  // IDE
  
  export type DiffLineType = "new" | "old" | "same";
  
>>>>>>> origin/develop
  export interface DiffLine {
    type: DiffLineType;
    line: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export class Problem {
    filepath: string;
    range: Range;
    message: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export class Thread {
    name: string;
    id: number;
  }
<<<<<<< HEAD

  export type IdeType = "vscode" | "jetbrains";

=======
  
  export type IdeType = "vscode" | "jetbrains";
  
>>>>>>> origin/develop
  export interface IdeInfo {
    ideType: IdeType;
    name: string;
    version: string;
    remoteName: string;
    extensionVersion: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface BranchAndDir {
    branch: string;
    directory: string;
  }
<<<<<<< HEAD

  export interface IndexTag extends BranchAndDir {
    artifactId: string;
  }

=======
  
  export interface IndexTag extends BranchAndDir {
    artifactId: string;
  }
  
>>>>>>> origin/develop
  export enum FileType {
    Unkown = 0,
    File = 1,
    Directory = 2,
    SymbolicLink = 64,
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface IdeSettings {
    remoteConfigServerUrl: string | undefined;
    remoteConfigSyncPeriod: number;
    userToken: string;
    pauseCodebaseIndexOnStart: boolean;
  }
<<<<<<< HEAD

  export interface IDE {
    getIdeInfo(): Promise<IdeInfo>;

    getIdeSettings(): Promise<IdeSettings>;

    getDiff(includeUnstaged: boolean): Promise<string[]>;

    getClipboardContent(): Promise<{ text: string; copiedAt: string }>;

    isTelemetryEnabled(): Promise<boolean>;

    getUniqueId(): Promise<string>;

    getTerminalContents(): Promise<string>;

    getDebugLocals(threadIndex: number): Promise<string>;

=======
  
  export interface IDE {
    getIdeInfo(): Promise<IdeInfo>;
  
    getIdeSettings(): Promise<IdeSettings>;
  
    getDiff(includeUnstaged: boolean): Promise<string[]>;
  
    getClipboardContent(): Promise<{ text: string; copiedAt: string }>;
  
    isTelemetryEnabled(): Promise<boolean>;
  
    getUniqueId(): Promise<string>;
  
    getTerminalContents(): Promise<string>;
  
    getDebugLocals(threadIndex: number): Promise<string>;
  
>>>>>>> origin/develop
    getTopLevelCallStackSources(
      threadIndex: number,
      stackDepth: number,
    ): Promise<string[]>;
<<<<<<< HEAD

    getAvailableThreads(): Promise<Thread[]>;

    getWorkspaceDirs(): Promise<string[]>;

    getWorkspaceConfigs(): Promise<ContinueRcJson[]>;

    fileExists(filepath: string): Promise<boolean>;

    writeFile(path: string, contents: string): Promise<void>;

    showVirtualFile(title: string, contents: string): Promise<void>;
    openFile(path: string): Promise<void>;

    openUrl(url: string): Promise<void>;

    runCommand(command: string): Promise<void>;

    saveFile(filepath: string): Promise<void>;

    readFile(filepath: string): Promise<string>;

    readRangeInFile(filepath: string, range: Range): Promise<string>;

=======
  
    getAvailableThreads(): Promise<Thread[]>;
  
    getWorkspaceDirs(): Promise<string[]>;
  
    getWorkspaceConfigs(): Promise<ContinueRcJson[]>;
  
    fileExists(filepath: string): Promise<boolean>;
  
    writeFile(path: string, contents: string): Promise<void>;
  
    showVirtualFile(title: string, contents: string): Promise<void>;
    openFile(path: string): Promise<void>;
  
    openUrl(url: string): Promise<void>;
  
    runCommand(command: string): Promise<void>;
  
    saveFile(filepath: string): Promise<void>;
  
    readFile(filepath: string): Promise<string>;
  
    readRangeInFile(filepath: string, range: Range): Promise<string>;
  
>>>>>>> origin/develop
    showLines(
      filepath: string,
      startLine: number,
      endLine: number,
    ): Promise<void>;
    getOpenFiles(): Promise<string[]>;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    getCurrentFile(): Promise<
      | undefined
      | {
          isUntitled: boolean;
          path: string;
          contents: string;
        }
    >;
<<<<<<< HEAD

    getPinnedFiles(): Promise<string[]>;

    getSearchResults(query: string): Promise<string>;

    subprocess(command: string, cwd?: string): Promise<[string, string]>;

    getProblems(filepath?: string | undefined): Promise<Problem[]>;

    getBranch(dir: string): Promise<string>;

    getTags(artifactId: string): Promise<IndexTag[]>;

    getRepoName(dir: string): Promise<string | undefined>;

=======
  
    getPinnedFiles(): Promise<string[]>;
  
    getSearchResults(query: string): Promise<string>;
  
    subprocess(command: string, cwd?: string): Promise<[string, string]>;
  
    getProblems(filepath?: string | undefined): Promise<Problem[]>;
  
    getBranch(dir: string): Promise<string>;
  
    getTags(artifactId: string): Promise<IndexTag[]>;
  
    getRepoName(dir: string): Promise<string | undefined>;
  
>>>>>>> origin/develop
    showToast(
      type: ToastType,
      message: string,
      ...otherParams: any[]
    ): Promise<any>;
<<<<<<< HEAD

    getGitRootPath(dir: string): Promise<string | undefined>;

    listDir(dir: string): Promise<[string, FileType][]>;

    getLastModified(files: string[]): Promise<{ [path: string]: number }>;

    getGitHubAuthToken(args: GetGhTokenArgs): Promise<string | undefined>;

    // LSP
    gotoDefinition(location: Location): Promise<RangeInFile[]>;

    // Callbacks
    onDidChangeActiveTextEditor(callback: (filepath: string) => void): void;
  }

  // Slash Commands

=======
  
    getGitRootPath(dir: string): Promise<string | undefined>;
  
    listDir(dir: string): Promise<[string, FileType][]>;
  
    getLastModified(files: string[]): Promise<{ [path: string]: number }>;
  
    getGitHubAuthToken(args: GetGhTokenArgs): Promise<string | undefined>;
  
    // LSP
    gotoDefinition(location: Location): Promise<RangeInFile[]>;
  
    // Callbacks
    onDidChangeActiveTextEditor(callback: (filepath: string) => void): void;
  }
  
  // Slash Commands
  
>>>>>>> origin/develop
  export interface ContinueSDK {
    ide: IDE;
    llm: ILLM;
    addContextItem: (item: ContextItemWithId) => void;
    history: ChatMessage[];
    input: string;
    params?: { [key: string]: any } | undefined;
    contextItems: ContextItemWithId[];
    selectedCode: RangeInFile[];
    config: ContinueConfig;
    fetch: FetchFunction;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface SlashCommand {
    name: string;
    description: string;
    params?: { [key: string]: any };
    run: (sdk: ContinueSDK) => AsyncGenerator<string | undefined>;
  }
<<<<<<< HEAD

  // Config

=======
  
  // Config
  
>>>>>>> origin/develop
  type StepName =
    | "AnswerQuestionChroma"
    | "GenerateShellCommandStep"
    | "EditHighlightedCodeStep"
    | "ShareSessionStep"
    | "CommentCodeStep"
    | "ClearHistoryStep"
    | "StackOverflowStep"
    | "OpenConfigStep"
    | "GenerateShellCommandStep"
    | "DraftIssueStep";
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  type ContextProviderName =
    | "diff"
    | "terminal"
    | "debugger"
    | "open"
    | "google"
    | "search"
    | "tree"
    | "http"
    | "codebase"
    | "problems"
    | "folder"
    | "jira"
    | "postgres"
    | "database"
    | "code"
    | "docs"
    | "gitlab-mr"
    | "os"
    | "currentFile"
    | "greptile"
    | "outline"
    | "continue-proxy"
    | "highlights"
    | "file"
    | "issue"
    | "repo-map"
    | "url"
    | string;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  type TemplateType =
    | "llama2"
    | "alpaca"
    | "zephyr"
    | "phi2"
    | "phind"
    | "anthropic"
    | "chatml"
    | "none"
    | "openchat"
    | "deepseek"
    | "xwin-coder"
    | "neural-chat"
    | "codellama-70b"
    | "llava"
    | "gemma"
    | "granite"
    | "llama3"
    | "codestral";
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface RequestOptions {
    timeout?: number;
    verifySsl?: boolean;
    caBundlePath?: string | string[];
    proxy?: string;
    headers?: { [key: string]: string };
    extraBodyProperties?: { [key: string]: any };
    noProxy?: string[];
    clientCertificate?: ClientCertificateOptions;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface CacheBehavior {
    cacheSystemMessage?: boolean;
    cacheConversation?: boolean;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ClientCertificateOptions {
    cert: string;
    key: string;
    passphrase?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface StepWithParams {
    name: StepName;
    params: { [key: string]: any };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ContextProviderWithParams {
    name: ContextProviderName;
    params: { [key: string]: any };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface SlashCommandDescription {
    name: string;
    description: string;
    params?: { [key: string]: any };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface CustomCommand {
    name: string;
    prompt: string;
    description: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface Prediction {
    type: "content";
    content:
      | string
      | {
          type: "text";
          text: string;
        }[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ToolExtras {
    ide: IDE;
    llm: ILLM;
    fetch: FetchFunction;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface Tool {
    type: "function";
    function: {
      name: string;
      description?: string;
      parameters?: Record<string, any>;
      strict?: boolean | null;
    };
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    displayTitle: string;
    wouldLikeTo: string;
    readonly: boolean;
    uri?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface BaseCompletionOptions {
    temperature?: number;
    topP?: number;
    topK?: number;
    minP?: number;
    presencePenalty?: number;
    frequencyPenalty?: number;
    mirostat?: number;
    stop?: string[];
    maxTokens?: number;
    numThreads?: number;
    useMmap?: boolean;
    keepAlive?: number;
    numGpu?: number;
    raw?: boolean;
    stream?: boolean;
    prediction?: Prediction;
    tools?: Tool[];
  }
<<<<<<< HEAD

  export interface ModelCapability {
    uploadImage?: boolean;
  }

=======
  
  export interface ModelCapability {
    uploadImage?: boolean;
  }
  
>>>>>>> origin/develop
  export interface ModelDescription {
    title: string;
    provider: string;
    model: string;
    apiKey?: string;
    apiBase?: string;
    contextLength?: number;
    maxStopWords?: number;
    template?: TemplateType;
    completionOptions?: BaseCompletionOptions;
    systemMessage?: string;
    requestOptions?: RequestOptions;
    promptTemplates?: { [key: string]: string };
    capabilities?: ModelCapability;
    cacheBehavior?: CacheBehavior;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface JSONEmbedOptions {
    apiBase?: string;
    apiKey?: string;
    model?: string;
    deployment?: string;
    apiType?: string;
    apiVersion?: string;
    requestOptions?: RequestOptions;
    maxChunkSize?: number;
    maxBatchSize?: number;
    // AWS options
    profile?: string;
<<<<<<< HEAD

    // AWS and GCP Options
    region?: string;

    // GCP and Watsonx Options
    projectId?: string;
  }

  export interface EmbeddingsProviderDescription extends EmbedOptions {
    provider: string;
  }

=======
  
    // AWS and GCP Options
    region?: string;
  
    // GCP and Watsonx Options
    projectId?: string;
  }
  
  export interface EmbeddingsProviderDescription extends EmbedOptions {
    provider: string;
  }
  
>>>>>>> origin/develop
  export interface RerankerDescription {
    name: string;
    params?: { [key: string]: any };
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface TabAutocompleteOptions {
    disable: boolean;
    maxPromptTokens: number;
    debounceDelay: number;
    maxSuffixPercentage: number;
    prefixPercentage: number;
    transform?: boolean;
    template?: string;
    multilineCompletions: "always" | "never" | "auto";
    slidingWindowPrefixPercentage: number;
    slidingWindowSize: number;
    useCache: boolean;
    onlyMyCode: boolean;
    useRecentlyEdited: boolean;
    disableInFiles?: string[];
    useImports?: boolean;
    showWhateverWeHaveAtXMs?: number;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface StdioOptions {
    type: "stdio";
    command: string;
    args: string[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface WebSocketOptions {
    type: "websocket";
    url: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface SSEOptions {
    type: "sse";
    url: string;
  }
<<<<<<< HEAD

  type TransportOptions = StdioOptions | WebSocketOptions | SSEOptions;

  export interface MCPOptions {
    transport: TransportOptions;
  }

=======
  
  type TransportOptions = StdioOptions | WebSocketOptions | SSEOptions;
  
  export interface MCPOptions {
    transport: TransportOptions;
  }
  
>>>>>>> origin/develop
  export interface ContinueUIConfig {
    codeBlockToolbarPosition?: "top" | "bottom";
    fontSize?: number;
    displayRawMarkdown?: boolean;
    showChatScrollbar?: boolean;
    codeWrap?: boolean;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface ContextMenuConfig {
    comment?: string;
    docstring?: string;
    fix?: string;
    optimize?: string;
    fixGrammar?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface ExperimentalModelRoles {
    inlineEdit?: string;
    applyCodeBlock?: string;
    repoMapFileSelection?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export type ApplyStateStatus =
    | "streaming" // Changes are being applied to the file
    | "done" // All changes have been applied, awaiting user to accept/reject
    | "closed"; // All changes have been applied. Note that for new files, we immediately set the status to "closed"
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface ApplyState {
    streamId: string;
    status?: ApplyStateStatus;
    numDiffs?: number;
    filepath?: string;
    fileContent?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface RangeInFileWithContents {
    filepath: string;
    range: {
      start: { line: number; character: number };
      end: { line: number; character: number };
    };
    contents: string;
  }
<<<<<<< HEAD

  export type CodeToEdit = RangeInFileWithContents | FileWithContents;

=======
  
  export type CodeToEdit = RangeInFileWithContents | FileWithContents;
  
>>>>>>> origin/develop
  /**
   * Represents the configuration for a quick action in the Code Lens.
   * Quick actions are custom commands that can be added to function and class declarations.
   */
  interface QuickActionConfig {
    /**
     * The title of the quick action that will display in the Code Lens.
     */
    title: string;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    /**
     * The prompt that will be sent to the model when the quick action is invoked,
     * with the function or class body concatenated.
     */
    prompt: string;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    /**
     * If `true`, the result of the quick action will be sent to the chat panel.
     * If `false`, the streamed result will be inserted into the document.
     *
     * Defaults to `false`.
     */
    sendToChat: boolean;
  }
<<<<<<< HEAD

  export type DefaultContextProvider = ContextProviderWithParams & {
    query?: string;
  };

=======
  
  export type DefaultContextProvider = ContextProviderWithParams & {
    query?: string;
  };
  
>>>>>>> origin/develop
  interface ExperimentalConfig {
    contextMenuPrompts?: ContextMenuConfig;
    modelRoles?: ExperimentalModelRoles;
    defaultContext?: DefaultContextProvider[];
    promptPath?: string;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    /**
     * Quick actions are a way to add custom commands to the Code Lens of
     * function and class declarations.
     */
    quickActions?: QuickActionConfig[];
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    /**
     * Automatically read LLM chat responses aloud using system TTS models
     */
    readResponseTTS?: boolean;
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
    /**
     * If set to true, we will attempt to pull down and install an instance of Chromium
     * that is compatible with the current version of Puppeteer.
     * This is needed to crawl a large number of documentation sites that are dynamically rendered.
     */
    useChromiumForDocsCrawling?: boolean;
    useTools?: boolean;
    modelContextProtocolServers?: MCPOptions[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  interface AnalyticsConfig {
    type: string;
    url?: string;
    clientKey?: string;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // config.json
  export interface SerializedContinueConfig {
    env?: string[];
    allowAnonymousTelemetry?: boolean;
    models: ModelDescription[];
    systemMessage?: string;
    completionOptions?: BaseCompletionOptions;
    requestOptions?: RequestOptions;
    slashCommands?: SlashCommandDescription[];
    customCommands?: CustomCommand[];
    contextProviders?: ContextProviderWithParams[];
    disableIndexing?: boolean;
    disableSessionTitles?: boolean;
    userToken?: string;
    embeddingsProvider?: EmbeddingsProviderDescription;
    tabAutocompleteModel?: ModelDescription | ModelDescription[];
    tabAutocompleteOptions?: Partial<TabAutocompleteOptions>;
    ui?: ContinueUIConfig;
    reranker?: RerankerDescription;
    experimental?: ExperimentalConfig;
    analytics?: AnalyticsConfig;
    docs?: SiteIndexingConfig[];
  }
<<<<<<< HEAD

  export type ConfigMergeType = "merge" | "overwrite";

  export type ContinueRcJson = Partial<SerializedContinueConfig> & {
    mergeBehavior: ConfigMergeType;
  };

=======
  
  export type ConfigMergeType = "merge" | "overwrite";
  
  export type ContinueRcJson = Partial<SerializedContinueConfig> & {
    mergeBehavior: ConfigMergeType;
  };
  
>>>>>>> origin/develop
  // config.ts - give users simplified interfaces
  export interface Config {
    /** If set to true, Continue will collect anonymous usage data to improve the product. If set to false, we will collect nothing. Read here to learn more: https://docs.continue.dev/telemetry */
    allowAnonymousTelemetry?: boolean;
    /** Each entry in this array will originally be a ModelDescription, the same object from your config.json, but you may add CustomLLMs.
     * A CustomLLM requires you only to define an AsyncGenerator that calls the LLM and yields string updates. You can choose to define either `streamCompletion` or `streamChat` (or both).
     * Continue will do the rest of the work to construct prompt templates, handle context items, prune context, etc.
     */
    models: (CustomLLM | ModelDescription)[];
    /** A system message to be followed by all of your models */
    systemMessage?: string;
    /** The default completion options for all models */
    completionOptions?: BaseCompletionOptions;
    /** Request options that will be applied to all models and context providers */
    requestOptions?: RequestOptions;
    /** The list of slash commands that will be available in the sidebar */
    slashCommands?: SlashCommand[];
    /** Each entry in this array will originally be a ContextProviderWithParams, the same object from your config.json, but you may add CustomContextProviders.
     * A CustomContextProvider requires you only to define a title and getContextItems function. When you type '@title <query>', Continue will call `getContextItems(query)`.
     */
    contextProviders?: (CustomContextProvider | ContextProviderWithParams)[];
    /** If set to true, Continue will not index your codebase for retrieval */
    disableIndexing?: boolean;
    /** If set to true, Continue will not make extra requests to the LLM to generate a summary title of each session. */
    disableSessionTitles?: boolean;
    /** An optional token to identify a user. Not used by Continue unless you write custom coniguration that requires such a token */
    userToken?: string;
    /** The provider used to calculate embeddings. If left empty, Continue will use transformers.js to calculate the embeddings with all-MiniLM-L6-v2 */
    embeddingsProvider?: EmbeddingsProviderDescription | ILLM;
    /** The model that Continue will use for tab autocompletions. */
    tabAutocompleteModel?:
      | CustomLLM
      | ModelDescription
      | (CustomLLM | ModelDescription)[];
    /** Options for tab autocomplete */
    tabAutocompleteOptions?: Partial<TabAutocompleteOptions>;
    /** UI styles customization */
    ui?: ContinueUIConfig;
    /** Options for the reranker */
    reranker?: RerankerDescription | ILLM;
    /** Experimental configuration */
    experimental?: ExperimentalConfig;
    /** Analytics configuration */
    analytics?: AnalyticsConfig;
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // in the actual Continue source code
  export interface ContinueConfig {
    allowAnonymousTelemetry?: boolean;
    models: ILLM[];
    systemMessage?: string;
    completionOptions?: BaseCompletionOptions;
    requestOptions?: RequestOptions;
    slashCommands?: SlashCommand[];
    contextProviders?: IContextProvider[];
    disableSessionTitles?: boolean;
    disableIndexing?: boolean;
    userToken?: string;
    embeddingsProvider: ILLM;
    tabAutocompleteModels?: ILLM[];
    tabAutocompleteOptions?: Partial<TabAutocompleteOptions>;
    ui?: ContinueUIConfig;
    reranker?: ILLM;
    experimental?: ExperimentalConfig;
    analytics?: AnalyticsConfig;
    docs?: SiteIndexingConfig[];
    tools: Tool[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export interface BrowserSerializedContinueConfig {
    allowAnonymousTelemetry?: boolean;
    models: ModelDescription[];
    systemMessage?: string;
    completionOptions?: BaseCompletionOptions;
    requestOptions?: RequestOptions;
    slashCommands?: SlashCommandDescription[];
    contextProviders?: ContextProviderDescription[];
    disableIndexing?: boolean;
    disableSessionTitles?: boolean;
    userToken?: string;
    embeddingsProvider?: string;
    ui?: ContinueUIConfig;
    reranker?: RerankerDescription;
    experimental?: ExperimentalConfig;
    analytics?: AnalyticsConfig;
    docs?: SiteIndexingConfig[];
    tools: Tool[];
  }
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  // DOCS SUGGESTIONS AND PACKAGE INFO
  export interface FilePathAndName {
    path: string;
    name: string;
  }
<<<<<<< HEAD

  export interface PackageFilePathAndName extends FilePathAndName {
    packageRegistry: string; // e.g. npm, pypi
  }

=======
  
  export interface PackageFilePathAndName extends FilePathAndName {
    packageRegistry: string; // e.g. npm, pypi
  }
  
>>>>>>> origin/develop
  export type ParsedPackageInfo = {
    name: string;
    packageFile: PackageFilePathAndName;
    language: string;
    version: string;
  };
<<<<<<< HEAD

=======
  
>>>>>>> origin/develop
  export type PackageDetails = {
    docsLink?: string;
    docsLinkWarning?: string;
    title?: string;
    description?: string;
    repo?: string;
    license?: string;
  };
<<<<<<< HEAD

  export type PackageDetailsSuccess = PackageDetails & {
    docsLink: string;
  };

=======
  
  export type PackageDetailsSuccess = PackageDetails & {
    docsLink: string;
  };
  
>>>>>>> origin/develop
  export type PackageDocsResult = {
    packageInfo: ParsedPackageInfo;
  } & (
    | { error: string; details?: never }
    | { details: PackageDetailsSuccess; error?: never }
  );
}

export {};
