"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FeedbackController = void 0;
const vscode_1 = require("vscode");
const configs_1 = require("../configs");
/**
 * The FeedbackController class.
 *
 * @class
 * @classdesc The class that represents the feedback controller.
 * @export
 * @public
 * @example
 * const controller = new FeedbackController();
 */
class FeedbackController {
    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
    /**
     * Constructor for the FeedbackController class.
     *
     * @constructor
     * @public
     * @memberof FeedbackController
     */
    constructor() { }
    // -----------------------------------------------------------------
    // Methods
    // -----------------------------------------------------------------
    // Public methods
    /**
     * The aboutUs method.
     *
     * @function aboutUs
     * @public
     * @memberof FeedbackController
     *
     * @returns {void} - No return value
     */
    aboutUs() {
        vscode_1.env.openExternal(vscode_1.Uri.parse(configs_1.EXTENSION_HOMEPAGE_URL));
    }
    /**
     * The reportIssues method.
     *
     * @function reportIssues
     * @public
     * @memberof FeedbackController
     *
     * @returns {void} - No return value
     */
    reportIssues() {
        vscode_1.env.openExternal(vscode_1.Uri.parse(configs_1.EXTENSION_BUGS_URL));
    }
    /**
     * The rateUs method.
     *
     * @function rateUs
     * @public
     * @memberof FeedbackController
     *
     * @returns {void} - No return value
     */
    rateUs() {
        vscode_1.env.openExternal(vscode_1.Uri.parse(`${configs_1.EXTENSION_MARKETPLACE_URL}&ssr=false#review-details`));
    }
    /**
     * The supportUs method.
     *
     * @function supportUs
     * @public
     * @async
     * @memberof FeedbackController
     *
     * @returns {Promise<void>} - The promise that resolves with no value
     */
    async supportUs() {
        // Create the actions
        const actions = [
            { title: 'Become a Sponsor' },
            { title: 'Donate via PayPal' },
        ];
        // Show the message
        const option = await vscode_1.window.showInformationMessage(`Although ${configs_1.EXTENSION_NAME} is offered at no cost, your support is
        deeply appreciated if you find it beneficial. Thank you for considering!`, ...actions);
        // Handle the actions
        switch (option?.title) {
            case actions[0].title:
                vscode_1.env.openExternal(vscode_1.Uri.parse(configs_1.EXTENSION_SPONSOR_URL));
                break;
            case actions[1].title:
                vscode_1.env.openExternal(vscode_1.Uri.parse(configs_1.EXTENSION_PAYPAL_URL));
                break;
        }
    }
}
exports.FeedbackController = FeedbackController;
//# sourceMappingURL=feedback.controller.js.map