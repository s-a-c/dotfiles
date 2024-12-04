"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
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
exports.HeaderFilter = exports.FilterButtonWidth = void 0;
exports.withNullAsUndefined = withNullAsUndefined;
const dom_1 = require("../dom");
const dataProvider_1 = require("../dataProvider");
require("./headerFilter.css");
const locConstants_1 = require("../../../../common/locConstants");
const ShowFilterText = locConstants_1.locConstants.queryResult.showFilter;
exports.FilterButtonWidth = 34;
class HeaderFilter {
    constructor() {
        this.onFilterApplied = new Slick.Event();
        this.onCommand = new Slick.Event();
        this.enabled = true;
        this.activePopup = null;
        this.handler = new Slick.EventHandler();
        this.columnButtonMapping = new Map();
    }
    init(grid) {
        this.grid = grid;
        this.handler
            .subscribe(this.grid.onHeaderCellRendered, (e, args) => this.handleHeaderCellRendered(e, args))
            .subscribe(this.grid.onBeforeHeaderCellDestroy, (e, args) => this.handleBeforeHeaderCellDestroy(e, args));
        // .subscribe(this.grid.onClick, (e: DOMEvent) => this.handleBodyMouseDown(e as MouseEvent))
        // .subscribe(this.grid.onColumnsResized, () => this.columnsResized());
        // addEventListener('click', e => this.handleBodyMouseDown(e));
        // this.disposableStore.add(addDisposableListener(document.body, 'keydown', e => this.handleKeyDown(e)));
    }
    destroy() {
        this.handler.unsubscribeAll();
    }
    handleHeaderCellRendered(_e, args) {
        var _a, _b;
        const column = args.column;
        if (column.filterable === false) {
            return;
        }
        if (args.node.classList.contains("slick-header-with-filter")) {
            // the the filter button has already being added to the header
            return;
        }
        // The default sorting feature is triggered by clicking on the column header, but that is conflicting with query editor grid,
        // For query editor grid when column header is clicked, the entire column will be selected.
        // If the column is not defined as sortable because of the above reason, we will add the sort indicator here.
        if (column.sortable !== true) {
            args.node.classList.add("slick-header-sortable");
            (0, dom_1.append)(args.node, (0, dom_1.$)("span.slick-sort-indicator"));
        }
        args.node.classList.add("slick-header-with-filter");
        const $el = jQuery(`<button tabindex="-1" id="anchor-btn" aria-label="${ShowFilterText}" title="${ShowFilterText}"></button>`)
            .addClass("slick-header-menubutton")
            .data("column", column);
        if ((_a = column.filterValues) === null || _a === void 0 ? void 0 : _a.length) {
            this.setButtonImage($el, ((_b = column.filterValues) === null || _b === void 0 ? void 0 : _b.length) > 0);
        }
        $el.on("click", (e) => __awaiter(this, void 0, void 0, function* () {
            e.stopPropagation();
            e.preventDefault();
            this.showFilter($el[0]);
        }));
        $el.appendTo(args.node);
        //@ts-ignore
        this.columnButtonMapping[column.id] = $el[0];
    }
    showFilter(filterButton) {
        let $menuButton;
        const target = withNullAsUndefined(filterButton);
        if (target) {
            $menuButton = jQuery(target);
            this.columnDef = $menuButton.data("column");
        }
        // Check if the active popup is for the same button
        if (this.activePopup) {
            const isSameButton = this.activePopup.data("button") === filterButton;
            // close the popup and reset activePopup
            this.activePopup.fadeOut();
            this.activePopup = null;
            if (isSameButton) {
                return; // Exit since we're just closing the popup for the same button
            }
        }
        // Proceed to open the new popup for the clicked column
        const offset = jQuery(filterButton).offset();
        const $popup = jQuery('<div id="popup-menu">' +
            `<button id="sort-ascending" type="button" icon="slick-header-menuicon.ascending" class="sort-btn">${locConstants_1.locConstants.queryResult.sortAscending}</button>` +
            `<button id="sort-descending" type="button" icon="slick-header-menuicon.descending" class="sort-btn">${locConstants_1.locConstants.queryResult.sortDescending}</button>` +
            `<button id="close-popup" type="button" class="sort-btn">${locConstants_1.locConstants.queryResult.close}</button>` +
            "</div>");
        if (offset) {
            $popup.css({
                top: offset.top + ($menuButton === null || $menuButton === void 0 ? void 0 : $menuButton.outerHeight()), // Position below the button
                left: offset.left, // Align left edges
            });
        }
        // Append and show the new popup
        $popup.appendTo(document.body);
        openPopup($popup);
        // Store the clicked button reference with the popup, so we can check it later
        $popup.data("button", filterButton);
        // Set the new popup as the active popup
        this.activePopup = $popup;
        // Add event listeners for closing or interacting with the popup
        jQuery(document).on("click", (e) => {
            const $target = jQuery(e.target);
            // If the clicked target is not the button or the menu, close the menu
            if (!$target.closest("#anchor-btn").length &&
                !$target.closest("#popup-menu").length) {
                this.activePopup.fadeOut();
                this.activePopup = null;
            }
        });
        // Close the pop-up when the close-popup button is clicked
        jQuery(document).on("click", "#close-popup", () => {
            closePopup($popup);
            this.activePopup = null;
        });
        // Sorting button click handlers
        jQuery(document).on("click", "#sort-ascending", (_e) => {
            void this.handleMenuItemClick("sort-asc", this.columnDef);
            closePopup($popup);
            this.activePopup = null;
        });
        jQuery(document).on("click", "#sort-descending", (_e) => {
            void this.handleMenuItemClick("sort-desc", this.columnDef);
            closePopup($popup);
            this.activePopup = null;
        });
        function closePopup($popup) {
            $popup.fadeOut();
        }
        function openPopup($popup) {
            $popup.fadeIn();
        }
    }
    handleMenuItemClick(command, columnDef) {
        return __awaiter(this, void 0, void 0, function* () {
            const dataView = this.grid.getData();
            if (command === "sort-asc" || command === "sort-desc") {
                this.grid.setSortColumn(columnDef.id, command === "sort-asc");
            }
            if ((0, dataProvider_1.instanceOfIDisposableDataProvider)(dataView) &&
                (command === "sort-asc" || command === "sort-desc")) {
                yield dataView.sort({
                    grid: this.grid,
                    multiColumnSort: false,
                    sortCol: this.columnDef,
                    sortAsc: command === "sort-asc",
                });
                this.grid.invalidateAllRows();
                this.grid.updateRowCount();
                this.grid.render();
            }
            this.onCommand.notify({
                grid: this.grid,
                column: columnDef,
                command: command,
            });
            this.setFocusToColumn(columnDef);
        });
    }
    handleBeforeHeaderCellDestroy(_e, args) {
        jQuery(args.node).find(".slick-header-menubutton").remove();
    }
    setFocusToColumn(columnDef) {
        if (this.grid.getDataLength() > 0) {
            const column = this.grid
                .getColumns()
                .findIndex((col) => col.id === columnDef.id);
            if (column >= 0) {
                this.grid.setActiveCell(0, column);
            }
        }
    }
    setButtonImage($el, filtered) {
        const element = $el.get(0);
        if (element) {
            if (filtered) {
                element.className += " filtered";
            }
            else {
                const classList = element.classList;
                if (classList.contains("filtered")) {
                    classList.remove("filtered");
                }
            }
        }
    }
}
exports.HeaderFilter = HeaderFilter;
/**
 * Converts null to undefined, passes all other values through.
 */
function withNullAsUndefined(x) {
    return x === null ? undefined : x;
}

//# sourceMappingURL=headerFilter.plugin.js.map
