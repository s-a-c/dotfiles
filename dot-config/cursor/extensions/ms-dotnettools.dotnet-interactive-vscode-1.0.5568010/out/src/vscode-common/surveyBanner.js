"use strict";
// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
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
exports.SurveyBanner = exports.BannerType = exports.ExperimentNotebookSurveyStateKeys = exports.InsidersNotebookSurveyStateKeys = void 0;
const vscode_1 = require("vscode");
const vscodeUtilities_1 = require("./vscodeUtilities");
var InsidersNotebookSurveyStateKeys;
(function (InsidersNotebookSurveyStateKeys) {
    InsidersNotebookSurveyStateKeys["ShowBanner"] = "ShowInsidersNotebookSurveyBanner";
    InsidersNotebookSurveyStateKeys["ExecutionCount"] = "DS_InsidersNotebookExecutionCount";
})(InsidersNotebookSurveyStateKeys = exports.InsidersNotebookSurveyStateKeys || (exports.InsidersNotebookSurveyStateKeys = {}));
var ExperimentNotebookSurveyStateKeys;
(function (ExperimentNotebookSurveyStateKeys) {
    ExperimentNotebookSurveyStateKeys["ShowBanner"] = "ShowExperimentNotebookSurveyBanner";
    ExperimentNotebookSurveyStateKeys["ExecutionCount"] = "DS_ExperimentNotebookExecutionCount";
})(ExperimentNotebookSurveyStateKeys = exports.ExperimentNotebookSurveyStateKeys || (exports.ExperimentNotebookSurveyStateKeys = {}));
var DSSurveyLabelIndex;
(function (DSSurveyLabelIndex) {
    DSSurveyLabelIndex[DSSurveyLabelIndex["Yes"] = 0] = "Yes";
    DSSurveyLabelIndex[DSSurveyLabelIndex["No"] = 1] = "No";
})(DSSurveyLabelIndex || (DSSurveyLabelIndex = {}));
var BannerType;
(function (BannerType) {
    BannerType[BannerType["InsidersNotebookSurvey"] = 0] = "InsidersNotebookSurvey";
    BannerType[BannerType["ExperimentNotebookSurvey"] = 1] = "ExperimentNotebookSurvey";
})(BannerType = exports.BannerType || (exports.BannerType = {}));
const isCodeSpace = vscode_1.env.uiKind === vscode_1.UIKind.Web;
const MillisecondsInADay = 1000 * 60 * 60 * 24;
/**
 * Puts up a survey banner after a certain number of notebook executions. The survey will only show after 10 minutes have passed to prevent it from showing up immediately.
 */
class SurveyBanner {
    constructor(persistentState, disposables) {
        this.persistentState = persistentState;
        this.disposables = disposables;
        this.disabledInCurrentSession = false;
        this.bannerLabels = [
            this.translate('survey.yes', "Yes, take me to the survey"),
            this.translate('survey.no', "No")
        ];
        this.showBannerState = new Map();
        this.NotebookExecutionThreshold = 250; // Cell executions before showing survey
        this.setPersistentState(BannerType.InsidersNotebookSurvey, InsidersNotebookSurveyStateKeys.ShowBanner);
        this.setPersistentState(BannerType.ExperimentNotebookSurvey, ExperimentNotebookSurveyStateKeys.ShowBanner);
        // Change the surveyDelay flag after 10 minutes
        const timer = setTimeout(() => {
            SurveyBanner.surveyDelay = true;
        }, 10 * 60 * 1000);
        this.disposables.push(new vscode_1.Disposable(() => clearTimeout(timer)));
        this.activate();
    }
    dispose() {
        for (const disposable of this.disposables) {
            disposable.dispose();
        }
    }
    isEnabled(type) {
        switch (type) {
            case BannerType.InsidersNotebookSurvey:
                if (!(0, vscodeUtilities_1.isStableBuild)()) {
                    return this.isEnabledInternal(type);
                }
                break;
            case BannerType.ExperimentNotebookSurvey:
                if ((0, vscodeUtilities_1.isStableBuild)()) {
                    return this.isEnabledInternal(type);
                }
                break;
            default:
                return false;
        }
        return false;
    }
    isEnabledInternal(type) {
        var _a;
        if (vscode_1.env.uiKind !== vscode_1.UIKind.Desktop) {
            return false;
        }
        const value = (_a = this.showBannerState.get(type)) === null || _a === void 0 ? void 0 : _a.get(InsidersNotebookSurveyStateKeys.ShowBanner);
        if (!(value === null || value === void 0 ? void 0 : value.expiry)) {
            return true;
        }
        return value.expiry < Date.now();
    }
    activate() {
        this.onDidChangeNotebookCellExecutionStateHandler = vscode_1.workspace.onDidChangeNotebookDocument(this.onDidChangeNotebookCellExecutionState, this, this.disposables);
    }
    showBanner(type) {
        var _a;
        return __awaiter(this, void 0, void 0, function* () {
            const show = this.shouldShowBanner(type);
            (_a = this.onDidChangeNotebookCellExecutionStateHandler) === null || _a === void 0 ? void 0 : _a.dispose();
            if (!show) {
                return;
            }
            // Disable for the current session.
            this.disabledInCurrentSession = true;
            const response = yield vscode_1.window.showInformationMessage(this.getBannerMessage(type), ...this.bannerLabels);
            switch (response) {
                case this.bannerLabels[DSSurveyLabelIndex.Yes]: {
                    yield this.launchSurvey(type);
                    yield this.disable(DSSurveyLabelIndex.Yes, type);
                    break;
                }
                // Treat clicking on x as equivalent to clicking No
                default: {
                    yield this.disable(DSSurveyLabelIndex.No, type);
                    break;
                }
            }
        });
    }
    shouldShowBanner(type) {
        if (isCodeSpace ||
            !this.isEnabled(type) ||
            this.disabledInCurrentSession ||
            !SurveyBanner.surveyDelay) {
            return false;
        }
        const executionCount = this.getExecutionCount(type);
        return executionCount >= this.NotebookExecutionThreshold;
    }
    setPersistentState(type, val) {
        this.showBannerState.set(type, this.persistentState);
    }
    launchSurvey(type) {
        return __awaiter(this, void 0, void 0, function* () {
            vscode_1.env.openExternal(vscode_1.Uri.parse(this.getSurveyLink(type)));
        });
    }
    disable(answer, type) {
        return __awaiter(this, void 0, void 0, function* () {
            let monthsTillNextPrompt = answer === DSSurveyLabelIndex.Yes ? 6 : 4;
            const key = type === BannerType.InsidersNotebookSurvey ? InsidersNotebookSurveyStateKeys.ShowBanner : ExperimentNotebookSurveyStateKeys.ShowBanner;
            if (monthsTillNextPrompt) {
                yield this.persistentState.update(key, {
                    expiry: monthsTillNextPrompt * 31 * MillisecondsInADay + Date.now(),
                    data: true
                });
            }
        });
    }
    // Handle when a cell finishes execution
    onDidChangeNotebookCellExecutionState(cellStateChange) {
        return __awaiter(this, void 0, void 0, function* () {
            // TODO: Enure you check the notebook type is jupyter or dib
            if (!isSupportedNotebook(cellStateChange.notebook.metadata)) {
                return;
            }
            // If cell has moved to executing, update the execution count
            if (cellStateChange.cellChanges.some(cell => { var _a, _b; return (_b = (_a = cell.executionSummary) === null || _a === void 0 ? void 0 : _a.timing) === null || _b === void 0 ? void 0 : _b.startTime; })) {
                void this.updateStateAndShowBanner(InsidersNotebookSurveyStateKeys.ExecutionCount, BannerType.InsidersNotebookSurvey);
                void this.updateStateAndShowBanner(ExperimentNotebookSurveyStateKeys.ExecutionCount, BannerType.ExperimentNotebookSurvey);
            }
        });
    }
    getExecutionCount(type) {
        switch (type) {
            case BannerType.InsidersNotebookSurvey:
                return this.persistentState.get(InsidersNotebookSurveyStateKeys.ExecutionCount, 0);
            case BannerType.ExperimentNotebookSurvey:
                return this.persistentState.get(ExperimentNotebookSurveyStateKeys.ExecutionCount, 0);
            default:
                return -1;
        }
    }
    updateStateAndShowBanner(val, banner) {
        var _a, _b;
        return __awaiter(this, void 0, void 0, function* () {
            const key = banner === BannerType.InsidersNotebookSurvey ? InsidersNotebookSurveyStateKeys.ExecutionCount : ExperimentNotebookSurveyStateKeys.ExecutionCount;
            const value = ((_a = this.showBannerState.get(banner)) === null || _a === void 0 ? void 0 : _a.get(key, 0)) || 0;
            yield this.persistentState.update(key, value + 1);
            if (!this.shouldShowBanner(banner)) {
                return;
            }
            (_b = this.onDidChangeNotebookCellExecutionStateHandler) === null || _b === void 0 ? void 0 : _b.dispose();
            void this.showBanner(banner);
        });
    }
    getBannerMessage(type) {
        switch (type) {
            case BannerType.InsidersNotebookSurvey:
            case BannerType.ExperimentNotebookSurvey:
                // TODO: LOCALIZE (message in banner for user)
                return this.translate('survey.message', "We would love to hear your feedback on the notebooks experience! Please take a few minutes to give feedback on using Polyglot Notebooks");
            default:
                return '';
        }
    }
    getSurveyLink(type) {
        switch (type) {
            case BannerType.InsidersNotebookSurvey:
            case BannerType.ExperimentNotebookSurvey:
                return 'https://aka.ms/polyglotnotebooksurvey';
            default:
                return '';
        }
    }
    translate(key, fallback) {
        const translation = vscode_1.l10n.t(key);
        return translation === key ? fallback : translation;
    }
}
exports.SurveyBanner = SurveyBanner;
SurveyBanner.surveyDelay = false;
function isSupportedNotebook(notebookMedata) {
    return notebookMedata && notebookMedata.polyglot_notebook;
}
//# sourceMappingURL=surveyBanner.js.map