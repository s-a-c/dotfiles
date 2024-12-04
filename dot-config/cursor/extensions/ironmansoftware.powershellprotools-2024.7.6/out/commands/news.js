'use strict';
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
exports.notifyAboutNews = exports.NewsTreeViewCommands = void 0;
const vscode = require("vscode");
const axios_1 = require("axios");
const settings_1 = require("../settings");
class NewsTreeViewCommands {
    register(context) {
        context.subscriptions.push(this.Open());
    }
    Open() {
        return vscode.commands.registerCommand('newsView.open', (url) => __awaiter(this, void 0, void 0, function* () {
            vscode.env.openExternal(vscode.Uri.parse(url));
        }));
    }
}
exports.NewsTreeViewCommands = NewsTreeViewCommands;
function notifyAboutNews(context) {
    return __awaiter(this, void 0, void 0, function* () {
        var settings = (0, settings_1.load)();
        if (settings.disableNewsNotification) {
            return;
        }
        var result = yield (0, axios_1.default)({ url: 'https://www.ironmansoftware.com/news/api' });
        var news = result.data;
        if (news.length > 0) {
            var latestNews = news[0];
            var id = context.globalState.get("PSPNewsId");
            if (id == latestNews.id) {
                return;
            }
            vscode.window.showInformationMessage("Ironman Software News - " + latestNews.title + " - " + latestNews.description, "View").then((result) => {
                if (result == "View") {
                    vscode.env.openExternal(vscode.Uri.parse(latestNews.url));
                    context.globalState.update("PSPNewsId", latestNews.id);
                }
            });
        }
    });
}
exports.notifyAboutNews = notifyAboutNews;
//# sourceMappingURL=news.js.map