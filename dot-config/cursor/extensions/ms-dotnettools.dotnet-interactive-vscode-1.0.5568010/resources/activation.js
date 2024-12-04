/******************************************************************************
Copyright (c) Microsoft Corporation.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
***************************************************************************** */
/* global Reflect, Promise */

var extendStatics = function(d, b) {
    extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
    return extendStatics(d, b);
};

function __extends(d, b) {
    if (typeof b !== "function" && b !== null)
        throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
    extendStatics(d, b);
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
}

function __awaiter(thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
}

function __values(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
}

function __read(o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
}

function __spreadArray(to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
}

var LIB;(()=>{var t={470:t=>{function e(t){if("string"!=typeof t)throw new TypeError("Path must be a string. Received "+JSON.stringify(t))}function r(t,e){for(var r,n="",o=0,i=-1,a=0,h=0;h<=t.length;++h){if(h<t.length)r=t.charCodeAt(h);else {if(47===r)break;r=47;}if(47===r){if(i===h-1||1===a);else if(i!==h-1&&2===a){if(n.length<2||2!==o||46!==n.charCodeAt(n.length-1)||46!==n.charCodeAt(n.length-2))if(n.length>2){var s=n.lastIndexOf("/");if(s!==n.length-1){-1===s?(n="",o=0):o=(n=n.slice(0,s)).length-1-n.lastIndexOf("/"),i=h,a=0;continue}}else if(2===n.length||1===n.length){n="",o=0,i=h,a=0;continue}e&&(n.length>0?n+="/..":n="..",o=2);}else n.length>0?n+="/"+t.slice(i+1,h):n=t.slice(i+1,h),o=h-i-1;i=h,a=0;}else 46===r&&-1!==a?++a:a=-1;}return n}var n={resolve:function(){for(var t,n="",o=!1,i=arguments.length-1;i>=-1&&!o;i--){var a;i>=0?a=arguments[i]:(void 0===t&&(t=process.cwd()),a=t),e(a),0!==a.length&&(n=a+"/"+n,o=47===a.charCodeAt(0));}return n=r(n,!o),o?n.length>0?"/"+n:"/":n.length>0?n:"."},normalize:function(t){if(e(t),0===t.length)return ".";var n=47===t.charCodeAt(0),o=47===t.charCodeAt(t.length-1);return 0!==(t=r(t,!n)).length||n||(t="."),t.length>0&&o&&(t+="/"),n?"/"+t:t},isAbsolute:function(t){return e(t),t.length>0&&47===t.charCodeAt(0)},join:function(){if(0===arguments.length)return ".";for(var t,r=0;r<arguments.length;++r){var o=arguments[r];e(o),o.length>0&&(void 0===t?t=o:t+="/"+o);}return void 0===t?".":n.normalize(t)},relative:function(t,r){if(e(t),e(r),t===r)return "";if((t=n.resolve(t))===(r=n.resolve(r)))return "";for(var o=1;o<t.length&&47===t.charCodeAt(o);++o);for(var i=t.length,a=i-o,h=1;h<r.length&&47===r.charCodeAt(h);++h);for(var s=r.length-h,c=a<s?a:s,f=-1,u=0;u<=c;++u){if(u===c){if(s>c){if(47===r.charCodeAt(h+u))return r.slice(h+u+1);if(0===u)return r.slice(h+u)}else a>c&&(47===t.charCodeAt(o+u)?f=u:0===u&&(f=0));break}var l=t.charCodeAt(o+u);if(l!==r.charCodeAt(h+u))break;47===l&&(f=u);}var p="";for(u=o+f+1;u<=i;++u)u!==i&&47!==t.charCodeAt(u)||(0===p.length?p+="..":p+="/..");return p.length>0?p+r.slice(h+f):(h+=f,47===r.charCodeAt(h)&&++h,r.slice(h))},_makeLong:function(t){return t},dirname:function(t){if(e(t),0===t.length)return ".";for(var r=t.charCodeAt(0),n=47===r,o=-1,i=!0,a=t.length-1;a>=1;--a)if(47===(r=t.charCodeAt(a))){if(!i){o=a;break}}else i=!1;return -1===o?n?"/":".":n&&1===o?"//":t.slice(0,o)},basename:function(t,r){if(void 0!==r&&"string"!=typeof r)throw new TypeError('"ext" argument must be a string');e(t);var n,o=0,i=-1,a=!0;if(void 0!==r&&r.length>0&&r.length<=t.length){if(r.length===t.length&&r===t)return "";var h=r.length-1,s=-1;for(n=t.length-1;n>=0;--n){var c=t.charCodeAt(n);if(47===c){if(!a){o=n+1;break}}else -1===s&&(a=!1,s=n+1),h>=0&&(c===r.charCodeAt(h)?-1==--h&&(i=n):(h=-1,i=s));}return o===i?i=s:-1===i&&(i=t.length),t.slice(o,i)}for(n=t.length-1;n>=0;--n)if(47===t.charCodeAt(n)){if(!a){o=n+1;break}}else -1===i&&(a=!1,i=n+1);return -1===i?"":t.slice(o,i)},extname:function(t){e(t);for(var r=-1,n=0,o=-1,i=!0,a=0,h=t.length-1;h>=0;--h){var s=t.charCodeAt(h);if(47!==s)-1===o&&(i=!1,o=h+1),46===s?-1===r?r=h:1!==a&&(a=1):-1!==r&&(a=-1);else if(!i){n=h+1;break}}return -1===r||-1===o||0===a||1===a&&r===o-1&&r===n+1?"":t.slice(r,o)},format:function(t){if(null===t||"object"!=typeof t)throw new TypeError('The "pathObject" argument must be of type Object. Received type '+typeof t);return function(t,e){var r=e.dir||e.root,n=e.base||(e.name||"")+(e.ext||"");return r?r===e.root?r+n:r+"/"+n:n}(0,t)},parse:function(t){e(t);var r={root:"",dir:"",base:"",ext:"",name:""};if(0===t.length)return r;var n,o=t.charCodeAt(0),i=47===o;i?(r.root="/",n=1):n=0;for(var a=-1,h=0,s=-1,c=!0,f=t.length-1,u=0;f>=n;--f)if(47!==(o=t.charCodeAt(f)))-1===s&&(c=!1,s=f+1),46===o?-1===a?a=f:1!==u&&(u=1):-1!==a&&(u=-1);else if(!c){h=f+1;break}return -1===a||-1===s||0===u||1===u&&a===s-1&&a===h+1?-1!==s&&(r.base=r.name=0===h&&i?t.slice(1,s):t.slice(h,s)):(0===h&&i?(r.name=t.slice(1,a),r.base=t.slice(1,s)):(r.name=t.slice(h,a),r.base=t.slice(h,s)),r.ext=t.slice(a,s)),h>0?r.dir=t.slice(0,h-1):i&&(r.dir="/"),r},sep:"/",delimiter:":",win32:null,posix:null};n.posix=n,t.exports=n;}},e={};function r(n){var o=e[n];if(void 0!==o)return o.exports;var i=e[n]={exports:{}};return t[n](i,i.exports,r),i.exports}r.d=(t,e)=>{for(var n in e)r.o(e,n)&&!r.o(t,n)&&Object.defineProperty(t,n,{enumerable:!0,get:e[n]});},r.o=(t,e)=>Object.prototype.hasOwnProperty.call(t,e),r.r=t=>{"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(t,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(t,"__esModule",{value:!0});};var n={};(()=>{var t;if(r.r(n),r.d(n,{URI:()=>p,Utils:()=>_}),"object"==typeof process)t="win32"===process.platform;else if("object"==typeof navigator){var e=navigator.userAgent;t=e.indexOf("Windows")>=0;}var o,i,a=(o=function(t,e){return o=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(t,e){t.__proto__=e;}||function(t,e){for(var r in e)Object.prototype.hasOwnProperty.call(e,r)&&(t[r]=e[r]);},o(t,e)},function(t,e){if("function"!=typeof e&&null!==e)throw new TypeError("Class extends value "+String(e)+" is not a constructor or null");function r(){this.constructor=t;}o(t,e),t.prototype=null===e?Object.create(e):(r.prototype=e.prototype,new r);}),h=/^\w[\w\d+.-]*$/,s=/^\//,c=/^\/\//,f="",u="/",l=/^(([^:/?#]+?):)?(\/\/([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/,p=function(){function e(t,e,r,n,o,i){void 0===i&&(i=!1),"object"==typeof t?(this.scheme=t.scheme||f,this.authority=t.authority||f,this.path=t.path||f,this.query=t.query||f,this.fragment=t.fragment||f):(this.scheme=function(t,e){return t||e?t:"file"}(t,i),this.authority=e||f,this.path=function(t,e){switch(t){case"https":case"http":case"file":e?e[0]!==u&&(e=u+e):e=u;}return e}(this.scheme,r||f),this.query=n||f,this.fragment=o||f,function(t,e){if(!t.scheme&&e)throw new Error('[UriError]: Scheme is missing: {scheme: "", authority: "'.concat(t.authority,'", path: "').concat(t.path,'", query: "').concat(t.query,'", fragment: "').concat(t.fragment,'"}'));if(t.scheme&&!h.test(t.scheme))throw new Error("[UriError]: Scheme contains illegal characters.");if(t.path)if(t.authority){if(!s.test(t.path))throw new Error('[UriError]: If a URI contains an authority component, then the path component must either be empty or begin with a slash ("/") character')}else if(c.test(t.path))throw new Error('[UriError]: If a URI does not contain an authority component, then the path cannot begin with two slash characters ("//")')}(this,i));}return e.isUri=function(t){return t instanceof e||!!t&&"string"==typeof t.authority&&"string"==typeof t.fragment&&"string"==typeof t.path&&"string"==typeof t.query&&"string"==typeof t.scheme&&"string"==typeof t.fsPath&&"function"==typeof t.with&&"function"==typeof t.toString},Object.defineProperty(e.prototype,"fsPath",{get:function(){return b(this,!1)},enumerable:!1,configurable:!0}),e.prototype.with=function(t){if(!t)return this;var e=t.scheme,r=t.authority,n=t.path,o=t.query,i=t.fragment;return void 0===e?e=this.scheme:null===e&&(e=f),void 0===r?r=this.authority:null===r&&(r=f),void 0===n?n=this.path:null===n&&(n=f),void 0===o?o=this.query:null===o&&(o=f),void 0===i?i=this.fragment:null===i&&(i=f),e===this.scheme&&r===this.authority&&n===this.path&&o===this.query&&i===this.fragment?this:new d(e,r,n,o,i)},e.parse=function(t,e){void 0===e&&(e=!1);var r=l.exec(t);return r?new d(r[2]||f,x(r[4]||f),x(r[5]||f),x(r[7]||f),x(r[9]||f),e):new d(f,f,f,f,f)},e.file=function(e){var r=f;if(t&&(e=e.replace(/\\/g,u)),e[0]===u&&e[1]===u){var n=e.indexOf(u,2);-1===n?(r=e.substring(2),e=u):(r=e.substring(2,n),e=e.substring(n)||u);}return new d("file",r,e,f,f)},e.from=function(t){return new d(t.scheme,t.authority,t.path,t.query,t.fragment)},e.prototype.toString=function(t){return void 0===t&&(t=!1),C(this,t)},e.prototype.toJSON=function(){return this},e.revive=function(t){if(t){if(t instanceof e)return t;var r=new d(t);return r._formatted=t.external,r._fsPath=t._sep===g?t.fsPath:null,r}return t},e}(),g=t?1:void 0,d=function(t){function e(){var e=null!==t&&t.apply(this,arguments)||this;return e._formatted=null,e._fsPath=null,e}return a(e,t),Object.defineProperty(e.prototype,"fsPath",{get:function(){return this._fsPath||(this._fsPath=b(this,!1)),this._fsPath},enumerable:!1,configurable:!0}),e.prototype.toString=function(t){return void 0===t&&(t=!1),t?C(this,!0):(this._formatted||(this._formatted=C(this,!1)),this._formatted)},e.prototype.toJSON=function(){var t={$mid:1};return this._fsPath&&(t.fsPath=this._fsPath,t._sep=g),this._formatted&&(t.external=this._formatted),this.path&&(t.path=this.path),this.scheme&&(t.scheme=this.scheme),this.authority&&(t.authority=this.authority),this.query&&(t.query=this.query),this.fragment&&(t.fragment=this.fragment),t},e}(p),v=((i={})[58]="%3A",i[47]="%2F",i[63]="%3F",i[35]="%23",i[91]="%5B",i[93]="%5D",i[64]="%40",i[33]="%21",i[36]="%24",i[38]="%26",i[39]="%27",i[40]="%28",i[41]="%29",i[42]="%2A",i[43]="%2B",i[44]="%2C",i[59]="%3B",i[61]="%3D",i[32]="%20",i);function y(t,e){for(var r=void 0,n=-1,o=0;o<t.length;o++){var i=t.charCodeAt(o);if(i>=97&&i<=122||i>=65&&i<=90||i>=48&&i<=57||45===i||46===i||95===i||126===i||e&&47===i)-1!==n&&(r+=encodeURIComponent(t.substring(n,o)),n=-1),void 0!==r&&(r+=t.charAt(o));else {void 0===r&&(r=t.substr(0,o));var a=v[i];void 0!==a?(-1!==n&&(r+=encodeURIComponent(t.substring(n,o)),n=-1),r+=a):-1===n&&(n=o);}}return -1!==n&&(r+=encodeURIComponent(t.substring(n))),void 0!==r?r:t}function m(t){for(var e=void 0,r=0;r<t.length;r++){var n=t.charCodeAt(r);35===n||63===n?(void 0===e&&(e=t.substr(0,r)),e+=v[n]):void 0!==e&&(e+=t[r]);}return void 0!==e?e:t}function b(e,r){var n;return n=e.authority&&e.path.length>1&&"file"===e.scheme?"//".concat(e.authority).concat(e.path):47===e.path.charCodeAt(0)&&(e.path.charCodeAt(1)>=65&&e.path.charCodeAt(1)<=90||e.path.charCodeAt(1)>=97&&e.path.charCodeAt(1)<=122)&&58===e.path.charCodeAt(2)?r?e.path.substr(1):e.path[1].toLowerCase()+e.path.substr(2):e.path,t&&(n=n.replace(/\//g,"\\")),n}function C(t,e){var r=e?m:y,n="",o=t.scheme,i=t.authority,a=t.path,h=t.query,s=t.fragment;if(o&&(n+=o,n+=":"),(i||"file"===o)&&(n+=u,n+=u),i){var c=i.indexOf("@");if(-1!==c){var f=i.substr(0,c);i=i.substr(c+1),-1===(c=f.indexOf(":"))?n+=r(f,!1):(n+=r(f.substr(0,c),!1),n+=":",n+=r(f.substr(c+1),!1)),n+="@";}-1===(c=(i=i.toLowerCase()).indexOf(":"))?n+=r(i,!1):(n+=r(i.substr(0,c),!1),n+=i.substr(c));}if(a){if(a.length>=3&&47===a.charCodeAt(0)&&58===a.charCodeAt(2))(l=a.charCodeAt(1))>=65&&l<=90&&(a="/".concat(String.fromCharCode(l+32),":").concat(a.substr(3)));else if(a.length>=2&&58===a.charCodeAt(1)){var l;(l=a.charCodeAt(0))>=65&&l<=90&&(a="".concat(String.fromCharCode(l+32),":").concat(a.substr(2)));}n+=r(a,!0);}return h&&(n+="?",n+=r(h,!1)),s&&(n+="#",n+=e?s:y(s,!1)),n}function A(t){try{return decodeURIComponent(t)}catch(e){return t.length>3?t.substr(0,3)+A(t.substr(3)):t}}var w=/(%[0-9A-Za-z][0-9A-Za-z])+/g;function x(t){return t.match(w)?t.replace(w,(function(t){return A(t)})):t}var _,O=r(470),P=function(t,e,r){if(r||2===arguments.length)for(var n,o=0,i=e.length;o<i;o++)!n&&o in e||(n||(n=Array.prototype.slice.call(e,0,o)),n[o]=e[o]);return t.concat(n||Array.prototype.slice.call(e))},j=O.posix||O,U="/";!function(t){t.joinPath=function(t){for(var e=[],r=1;r<arguments.length;r++)e[r-1]=arguments[r];return t.with({path:j.join.apply(j,P([t.path],e,!1))})},t.resolvePath=function(t){for(var e=[],r=1;r<arguments.length;r++)e[r-1]=arguments[r];var n=t.path,o=!1;n[0]!==U&&(n=U+n,o=!0);var i=j.resolve.apply(j,P([n],e,!1));return o&&i[0]===U&&!t.authority&&(i=i.substring(1)),t.with({path:i})},t.dirname=function(t){if(0===t.path.length||t.path===U)return t;var e=j.dirname(t.path);return 1===e.length&&46===e.charCodeAt(0)&&(e=""),t.with({path:e})},t.basename=function(t){return j.basename(t.path)},t.extname=function(t){return j.extname(t.path)};}(_||(_={}));})(),LIB=n;})();const{URI,Utils}=LIB;

// Copyright (c) .NET Foundation and contributors. All rights reserved.
function createKernelUri(kernelUri) {
    const uri = URI.parse(kernelUri);
    uri.authority;
    uri.path;
    let absoluteUri = `${uri.scheme}://${uri.authority}${uri.path || "/"}`;
    return absoluteUri;
}
function createKernelUriWithQuery(kernelUri) {
    const uri = URI.parse(kernelUri);
    uri.authority;
    uri.path;
    let absoluteUri = `${uri.scheme}://${uri.authority}${uri.path || "/"}`;
    if (uri.query) {
        absoluteUri += `?${uri.query}`;
    }
    return absoluteUri;
}
function getTag(kernelUri) {
    const uri = URI.parse(kernelUri);
    if (uri.query) { //?
        const parts = uri.query.split("tag=");
        if (parts.length > 1) {
            return parts[1];
        }
    }
    return undefined;
}
function createRoutingSlip(kernelUris) {
    return Array.from(new Set(kernelUris.map(e => createKernelUriWithQuery(e))));
}
function routingSlipStartsWith(thisKernelUris, otherKernelUris) {
    let startsWith = true;
    if (otherKernelUris.length > 0 && thisKernelUris.length >= otherKernelUris.length) {
        for (let i = 0; i < otherKernelUris.length; i++) {
            if (createKernelUri(otherKernelUris[i]) !== createKernelUri(thisKernelUris[i])) {
                startsWith = false;
                break;
            }
        }
    }
    else {
        startsWith = false;
    }
    return startsWith;
}
function routingSlipContains(routingSlip, kernelUri, ignoreQuery = false) {
    const normalizedUri = ignoreQuery ? createKernelUri(kernelUri) : createKernelUriWithQuery(kernelUri);
    return routingSlip.find(e => normalizedUri === (!ignoreQuery ? createKernelUriWithQuery(e) : createKernelUri(e))) !== undefined;
}
class RoutingSlip {
    constructor() {
        this._uris = [];
    }
    get uris() {
        return this._uris;
    }
    set uris(value) {
        this._uris = value;
    }
    contains(kernelUri, ignoreQuery = false) {
        return routingSlipContains(this._uris, kernelUri, ignoreQuery);
    }
    startsWith(other) {
        if (other instanceof Array) {
            return routingSlipStartsWith(this._uris, other);
        }
        else {
            return routingSlipStartsWith(this._uris, other._uris);
        }
    }
    continueWith(other) {
        let otherUris = (other instanceof Array ? other : other._uris) || [];
        if (otherUris.length > 0) {
            if (routingSlipStartsWith(otherUris, this._uris)) {
                otherUris = otherUris.slice(this._uris.length);
            }
        }
        for (let i = 0; i < otherUris.length; i++) {
            if (!this.contains(otherUris[i])) {
                this._uris.push(otherUris[i]);
            }
            else {
                throw new Error(`The uri ${otherUris[i]} is already in the routing slip [${this._uris}], cannot continue with routing slip [${otherUris}]`);
            }
        }
    }
    toArray() {
        return [...this._uris];
    }
}
class CommandRoutingSlip extends RoutingSlip {
    constructor() {
        super();
    }
    static fromUris(uris) {
        const routingSlip = new CommandRoutingSlip();
        routingSlip.uris = uris;
        return routingSlip;
    }
    stampAsArrived(kernelUri) {
        this.stampAs(kernelUri, "arrived");
    }
    stamp(kernelUri) {
        this.stampAs(kernelUri);
    }
    stampAs(kernelUri, tag) {
        if (tag) {
            const absoluteUriWithQuery = `${createKernelUri(kernelUri)}?tag=${tag}`;
            const absoluteUriWithoutQuery = createKernelUri(kernelUri);
            if (this.uris.find(e => e.startsWith(absoluteUriWithoutQuery))) {
                throw new Error(`The uri ${absoluteUriWithQuery} is already in the routing slip [${this.uris}]`);
            }
            else {
                this.uris.push(absoluteUriWithQuery);
            }
        }
        else {
            const absoluteUriWithQuery = `${createKernelUri(kernelUri)}?tag=arrived`;
            const absoluteUriWithoutQuery = createKernelUri(kernelUri);
            if (!this.uris.find(e => e.startsWith(absoluteUriWithQuery))) {
                throw new Error(`The uri ${absoluteUriWithQuery} is not in the routing slip [${this.uris}]`);
            }
            else if (this.uris.find(e => e === absoluteUriWithoutQuery)) {
                throw new Error(`The uri ${absoluteUriWithoutQuery} is already in the routing slip [${this.uris}]`);
            }
            else {
                this.uris.push(absoluteUriWithoutQuery);
            }
        }
    }
}
class EventRoutingSlip extends RoutingSlip {
    constructor() {
        super();
    }
    static fromUris(uris) {
        const routingSlip = new EventRoutingSlip();
        routingSlip.uris = uris;
        return routingSlip;
    }
    stamp(kernelUri) {
        const normalizedUri = createKernelUriWithQuery(kernelUri);
        const canAdd = !this.uris.find(e => createKernelUriWithQuery(e) === normalizedUri);
        if (canAdd) {
            this.uris.push(normalizedUri);
            this.uris;
        }
        else {
            throw new Error(`The uri ${normalizedUri} is already in the routing slip [${this.uris}]`);
        }
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// Generated TypeScript interfaces and types.
// --------------------------------------------- Kernel Commands
const AddPackageType = "AddPackage";
const AddPackageSourceType = "AddPackageSource";
const CancelType = "Cancel";
const CompileProjectType = "CompileProject";
const DisplayErrorType = "DisplayError";
const DisplayValueType = "DisplayValue";
const ImportDocumentType = "ImportDocument";
const OpenDocumentType = "OpenDocument";
const OpenProjectType = "OpenProject";
const QuitType = "Quit";
const RequestCompletionsType = "RequestCompletions";
const RequestDiagnosticsType = "RequestDiagnostics";
const RequestHoverTextType = "RequestHoverText";
const RequestInputType = "RequestInput";
const RequestInputsType = "RequestInputs";
const RequestKernelInfoType = "RequestKernelInfo";
const RequestSignatureHelpType = "RequestSignatureHelp";
const RequestValueType = "RequestValue";
const RequestValueInfosType = "RequestValueInfos";
const SendEditableCodeType = "SendEditableCode";
const SendValueType = "SendValue";
const SubmitCodeType = "SubmitCode";
const UpdateDisplayedValueType = "UpdateDisplayedValue";
// --------------------------------------------- Kernel events
const AssemblyProducedType = "AssemblyProduced";
const CodeSubmissionReceivedType = "CodeSubmissionReceived";
const CommandFailedType = "CommandFailed";
const CommandSucceededType = "CommandSucceeded";
const CompleteCodeSubmissionReceivedType = "CompleteCodeSubmissionReceived";
const CompletionsProducedType = "CompletionsProduced";
const DiagnosticsProducedType = "DiagnosticsProduced";
const DisplayedValueProducedType = "DisplayedValueProduced";
const DisplayedValueUpdatedType = "DisplayedValueUpdated";
const DocumentOpenedType = "DocumentOpened";
const ErrorProducedType = "ErrorProduced";
const HoverTextProducedType = "HoverTextProduced";
const IncompleteCodeSubmissionReceivedType = "IncompleteCodeSubmissionReceived";
const InputProducedType = "InputProduced";
const InputsProducedType = "InputsProduced";
const KernelExtensionLoadedType = "KernelExtensionLoaded";
const KernelInfoProducedType = "KernelInfoProduced";
const KernelReadyType = "KernelReady";
const PackageAddedType = "PackageAdded";
const ProjectOpenedType = "ProjectOpened";
const ReturnValueProducedType = "ReturnValueProduced";
const SignatureHelpProducedType = "SignatureHelpProduced";
const StandardErrorValueProducedType = "StandardErrorValueProduced";
const StandardOutputValueProducedType = "StandardOutputValueProduced";
const ValueInfosProducedType = "ValueInfosProduced";
const ValueProducedType = "ValueProduced";
var InsertTextFormat;
(function (InsertTextFormat) {
    InsertTextFormat["PlainText"] = "plaintext";
    InsertTextFormat["Snippet"] = "snippet";
})(InsertTextFormat || (InsertTextFormat = {}));
var DiagnosticSeverity;
(function (DiagnosticSeverity) {
    DiagnosticSeverity["Hidden"] = "hidden";
    DiagnosticSeverity["Info"] = "info";
    DiagnosticSeverity["Warning"] = "warning";
    DiagnosticSeverity["Error"] = "error";
})(DiagnosticSeverity || (DiagnosticSeverity = {}));
var DocumentSerializationType;
(function (DocumentSerializationType) {
    DocumentSerializationType["Dib"] = "dib";
    DocumentSerializationType["Ipynb"] = "ipynb";
})(DocumentSerializationType || (DocumentSerializationType = {}));
var RequestType;
(function (RequestType) {
    RequestType["Parse"] = "parse";
    RequestType["Serialize"] = "serialize";
})(RequestType || (RequestType = {}));

// Unique ID creation requires a high quality random # generator. In the browser we therefore
// require the crypto API and do not support built-in fallback to lower quality random number
// generators (like Math.random()).
var getRandomValues;
var rnds8 = new Uint8Array(16);
function rng() {
  // lazy load so that environments that need to polyfill have a chance to do so
  if (!getRandomValues) {
    // getRandomValues needs to be invoked in a context where "this" is a Crypto implementation. Also,
    // find the complete implementation of crypto (msCrypto) on IE11.
    getRandomValues = typeof crypto !== 'undefined' && crypto.getRandomValues && crypto.getRandomValues.bind(crypto) || typeof msCrypto !== 'undefined' && typeof msCrypto.getRandomValues === 'function' && msCrypto.getRandomValues.bind(msCrypto);

    if (!getRandomValues) {
      throw new Error('crypto.getRandomValues() not supported. See https://github.com/uuidjs/uuid#getrandomvalues-not-supported');
    }
  }

  return getRandomValues(rnds8);
}

var REGEX = /^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}|00000000-0000-0000-0000-000000000000)$/i;

function validate(uuid) {
  return typeof uuid === 'string' && REGEX.test(uuid);
}

/**
 * Convert array of 16 byte values to UUID string format of the form:
 * XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 */

var byteToHex = [];

for (var i = 0; i < 256; ++i) {
  byteToHex.push((i + 0x100).toString(16).substr(1));
}

function stringify(arr) {
  var offset = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
  // Note: Be careful editing this code!  It's been tuned for performance
  // and works in ways you may not expect. See https://github.com/uuidjs/uuid/pull/434
  var uuid = (byteToHex[arr[offset + 0]] + byteToHex[arr[offset + 1]] + byteToHex[arr[offset + 2]] + byteToHex[arr[offset + 3]] + '-' + byteToHex[arr[offset + 4]] + byteToHex[arr[offset + 5]] + '-' + byteToHex[arr[offset + 6]] + byteToHex[arr[offset + 7]] + '-' + byteToHex[arr[offset + 8]] + byteToHex[arr[offset + 9]] + '-' + byteToHex[arr[offset + 10]] + byteToHex[arr[offset + 11]] + byteToHex[arr[offset + 12]] + byteToHex[arr[offset + 13]] + byteToHex[arr[offset + 14]] + byteToHex[arr[offset + 15]]).toLowerCase(); // Consistency check for valid UUID.  If this throws, it's likely due to one
  // of the following:
  // - One or more input array values don't map to a hex octet (leading to
  // "undefined" in the uuid)
  // - Invalid input values for the RFC `version` or `variant` fields

  if (!validate(uuid)) {
    throw TypeError('Stringified UUID is invalid');
  }

  return uuid;
}

function parse(uuid) {
  if (!validate(uuid)) {
    throw TypeError('Invalid UUID');
  }

  var v;
  var arr = new Uint8Array(16); // Parse ########-....-....-....-............

  arr[0] = (v = parseInt(uuid.slice(0, 8), 16)) >>> 24;
  arr[1] = v >>> 16 & 0xff;
  arr[2] = v >>> 8 & 0xff;
  arr[3] = v & 0xff; // Parse ........-####-....-....-............

  arr[4] = (v = parseInt(uuid.slice(9, 13), 16)) >>> 8;
  arr[5] = v & 0xff; // Parse ........-....-####-....-............

  arr[6] = (v = parseInt(uuid.slice(14, 18), 16)) >>> 8;
  arr[7] = v & 0xff; // Parse ........-....-....-####-............

  arr[8] = (v = parseInt(uuid.slice(19, 23), 16)) >>> 8;
  arr[9] = v & 0xff; // Parse ........-....-....-....-############
  // (Use "/" to avoid 32-bit truncation when bit-shifting high-order bytes)

  arr[10] = (v = parseInt(uuid.slice(24, 36), 16)) / 0x10000000000 & 0xff;
  arr[11] = v / 0x100000000 & 0xff;
  arr[12] = v >>> 24 & 0xff;
  arr[13] = v >>> 16 & 0xff;
  arr[14] = v >>> 8 & 0xff;
  arr[15] = v & 0xff;
  return arr;
}

function v4(options, buf, offset) {
  options = options || {};
  var rnds = options.random || (options.rng || rng)(); // Per 4.4, set bits for version and `clock_seq_hi_and_reserved`

  rnds[6] = rnds[6] & 0x0f | 0x40;
  rnds[8] = rnds[8] & 0x3f | 0x80; // Copy bytes to buffer, if provided

  if (buf) {
    offset = offset || 0;

    for (var i = 0; i < 16; ++i) {
      buf[offset + i] = rnds[i];
    }

    return buf;
  }

  return stringify(rnds);
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
function toBase64String(value) {
    const wnd = (globalThis.window);
    if (wnd) {
        return wnd.btoa(String.fromCharCode(...value));
    }
    else {
        return Buffer.from(value).toString('base64');
    }
}
class KernelCommandEnvelope {
    constructor(commandType, command) {
        this.commandType = commandType;
        this.command = command;
        this._childCommandCounter = 1;
        this._routingSlip = new CommandRoutingSlip();
    }
    get routingSlip() {
        return this._routingSlip;
    }
    get parentCommand() {
        return this._parentCommand;
    }
    static isKernelCommandEnvelopeModel(arg) {
        return !arg.getOrCreateToken;
    }
    setParent(parentCommand) {
        if (this._parentCommand && this._parentCommand !== parentCommand) {
            throw new Error("Parent cannot be changed.");
        }
        if ((this._token !== undefined && this._token !== null) &&
            ((parentCommand === null || parentCommand === void 0 ? void 0 : parentCommand._token) !== undefined && (parentCommand === null || parentCommand === void 0 ? void 0 : parentCommand._token) !== null) &&
            KernelCommandEnvelope.getRootToken(this._token) !== KernelCommandEnvelope.getRootToken(parentCommand._token)) {
            throw new Error("Token of parented command cannot be changed.");
        }
        if (this._parentCommand === null || this._parentCommand === undefined) {
            {
                // todo: do we need to override the token? Should this throw if parenting happens after token is set?
                if (this._token) {
                    this._token = undefined;
                }
                this._parentCommand = parentCommand;
                this.getOrCreateToken();
            }
        }
    }
    static areCommandsTheSame(envelope1, envelope2) {
        // reference equality
        if (envelope1 === envelope2) {
            return true;
        }
        // commandType equality
        const sameCommandType = (envelope1 === null || envelope1 === void 0 ? void 0 : envelope1.commandType) === (envelope2 === null || envelope2 === void 0 ? void 0 : envelope2.commandType); //?
        if (!sameCommandType) {
            return false;
        }
        // both must have tokens
        if ((!(envelope1 === null || envelope1 === void 0 ? void 0 : envelope1._token)) || (!(envelope2 === null || envelope2 === void 0 ? void 0 : envelope2._token))) {
            return false;
        }
        // token equality
        const sameToken = (envelope1 === null || envelope1 === void 0 ? void 0 : envelope1._token) === (envelope2 === null || envelope2 === void 0 ? void 0 : envelope2._token); //?
        if (!sameToken) {
            return false;
        }
        return true;
    }
    getOrCreateToken() {
        if (this._token) {
            return this._token;
        }
        if (this._parentCommand) {
            this._token = `${this._parentCommand.getOrCreateToken()}.${this._parentCommand.getNextChildToken()}`;
            return this._token;
        }
        const guidBytes = parse(v4());
        const data = new Uint8Array(guidBytes);
        this._token = toBase64String(data);
        // this._token = `${KernelCommandEnvelope._counter++}`;
        return this._token;
    }
    getToken() {
        if (this._token) {
            return this._token;
        }
        throw new Error('token not set');
    }
    isSelforDescendantOf(otherCommand) {
        const otherToken = otherCommand._token;
        const thisToken = this._token;
        if (thisToken && otherToken) {
            return thisToken.startsWith(otherToken);
        }
        throw new Error('both commands must have tokens');
    }
    hasSameRootCommandAs(otherCommand) {
        const otherToken = otherCommand._token;
        const thisToken = this._token;
        if (thisToken && otherToken) {
            const otherRootToken = KernelCommandEnvelope.getRootToken(otherToken);
            const thisRootToken = KernelCommandEnvelope.getRootToken(thisToken);
            return thisRootToken === otherRootToken;
        }
        throw new Error('both commands must have tokens');
    }
    static getRootToken(token) {
        const parts = token.split('.');
        return parts[0];
    }
    toJson() {
        const model = {
            commandType: this.commandType,
            command: this.command,
            routingSlip: this._routingSlip.toArray(),
            token: this.getOrCreateToken()
        };
        return model;
    }
    static fromJson(model) {
        const command = new KernelCommandEnvelope(model.commandType, model.command);
        command._routingSlip = CommandRoutingSlip.fromUris(model.routingSlip || []);
        command._token = model.token;
        return command;
    }
    clone() {
        return KernelCommandEnvelope.fromJson(this.toJson());
    }
    getNextChildToken() {
        return this._childCommandCounter++;
    }
}
KernelCommandEnvelope._counter = 1;
class KernelEventEnvelope {
    constructor(eventType, event, command) {
        this.eventType = eventType;
        this.event = event;
        this.command = command;
        this._routingSlip = new EventRoutingSlip();
    }
    get routingSlip() {
        return this._routingSlip;
    }
    toJson() {
        var _a;
        const model = {
            eventType: this.eventType,
            event: this.event,
            command: (_a = this.command) === null || _a === void 0 ? void 0 : _a.toJson(),
            routingSlip: this._routingSlip.toArray()
        };
        return model;
    }
    static fromJson(model) {
        const event = new KernelEventEnvelope(model.eventType, model.event, model.command ? KernelCommandEnvelope.fromJson(model.command) : undefined);
        event._routingSlip = EventRoutingSlip.fromUris(model.routingSlip || []);
        return event;
    }
    clone() {
        return KernelEventEnvelope.fromJson(this.toJson());
    }
}

function isFunction(value) {
    return typeof value === 'function';
}

function createErrorClass(createImpl) {
    var _super = function (instance) {
        Error.call(instance);
        instance.stack = new Error().stack;
    };
    var ctorFunc = createImpl(_super);
    ctorFunc.prototype = Object.create(Error.prototype);
    ctorFunc.prototype.constructor = ctorFunc;
    return ctorFunc;
}

var UnsubscriptionError = createErrorClass(function (_super) {
    return function UnsubscriptionErrorImpl(errors) {
        _super(this);
        this.message = errors
            ? errors.length + " errors occurred during unsubscription:\n" + errors.map(function (err, i) { return i + 1 + ") " + err.toString(); }).join('\n  ')
            : '';
        this.name = 'UnsubscriptionError';
        this.errors = errors;
    };
});

function arrRemove(arr, item) {
    if (arr) {
        var index = arr.indexOf(item);
        0 <= index && arr.splice(index, 1);
    }
}

var Subscription = (function () {
    function Subscription(initialTeardown) {
        this.initialTeardown = initialTeardown;
        this.closed = false;
        this._parentage = null;
        this._finalizers = null;
    }
    Subscription.prototype.unsubscribe = function () {
        var e_1, _a, e_2, _b;
        var errors;
        if (!this.closed) {
            this.closed = true;
            var _parentage = this._parentage;
            if (_parentage) {
                this._parentage = null;
                if (Array.isArray(_parentage)) {
                    try {
                        for (var _parentage_1 = __values(_parentage), _parentage_1_1 = _parentage_1.next(); !_parentage_1_1.done; _parentage_1_1 = _parentage_1.next()) {
                            var parent_1 = _parentage_1_1.value;
                            parent_1.remove(this);
                        }
                    }
                    catch (e_1_1) { e_1 = { error: e_1_1 }; }
                    finally {
                        try {
                            if (_parentage_1_1 && !_parentage_1_1.done && (_a = _parentage_1.return)) _a.call(_parentage_1);
                        }
                        finally { if (e_1) throw e_1.error; }
                    }
                }
                else {
                    _parentage.remove(this);
                }
            }
            var initialFinalizer = this.initialTeardown;
            if (isFunction(initialFinalizer)) {
                try {
                    initialFinalizer();
                }
                catch (e) {
                    errors = e instanceof UnsubscriptionError ? e.errors : [e];
                }
            }
            var _finalizers = this._finalizers;
            if (_finalizers) {
                this._finalizers = null;
                try {
                    for (var _finalizers_1 = __values(_finalizers), _finalizers_1_1 = _finalizers_1.next(); !_finalizers_1_1.done; _finalizers_1_1 = _finalizers_1.next()) {
                        var finalizer = _finalizers_1_1.value;
                        try {
                            execFinalizer(finalizer);
                        }
                        catch (err) {
                            errors = errors !== null && errors !== void 0 ? errors : [];
                            if (err instanceof UnsubscriptionError) {
                                errors = __spreadArray(__spreadArray([], __read(errors)), __read(err.errors));
                            }
                            else {
                                errors.push(err);
                            }
                        }
                    }
                }
                catch (e_2_1) { e_2 = { error: e_2_1 }; }
                finally {
                    try {
                        if (_finalizers_1_1 && !_finalizers_1_1.done && (_b = _finalizers_1.return)) _b.call(_finalizers_1);
                    }
                    finally { if (e_2) throw e_2.error; }
                }
            }
            if (errors) {
                throw new UnsubscriptionError(errors);
            }
        }
    };
    Subscription.prototype.add = function (teardown) {
        var _a;
        if (teardown && teardown !== this) {
            if (this.closed) {
                execFinalizer(teardown);
            }
            else {
                if (teardown instanceof Subscription) {
                    if (teardown.closed || teardown._hasParent(this)) {
                        return;
                    }
                    teardown._addParent(this);
                }
                (this._finalizers = (_a = this._finalizers) !== null && _a !== void 0 ? _a : []).push(teardown);
            }
        }
    };
    Subscription.prototype._hasParent = function (parent) {
        var _parentage = this._parentage;
        return _parentage === parent || (Array.isArray(_parentage) && _parentage.includes(parent));
    };
    Subscription.prototype._addParent = function (parent) {
        var _parentage = this._parentage;
        this._parentage = Array.isArray(_parentage) ? (_parentage.push(parent), _parentage) : _parentage ? [_parentage, parent] : parent;
    };
    Subscription.prototype._removeParent = function (parent) {
        var _parentage = this._parentage;
        if (_parentage === parent) {
            this._parentage = null;
        }
        else if (Array.isArray(_parentage)) {
            arrRemove(_parentage, parent);
        }
    };
    Subscription.prototype.remove = function (teardown) {
        var _finalizers = this._finalizers;
        _finalizers && arrRemove(_finalizers, teardown);
        if (teardown instanceof Subscription) {
            teardown._removeParent(this);
        }
    };
    Subscription.EMPTY = (function () {
        var empty = new Subscription();
        empty.closed = true;
        return empty;
    })();
    return Subscription;
}());
var EMPTY_SUBSCRIPTION = Subscription.EMPTY;
function isSubscription(value) {
    return (value instanceof Subscription ||
        (value && 'closed' in value && isFunction(value.remove) && isFunction(value.add) && isFunction(value.unsubscribe)));
}
function execFinalizer(finalizer) {
    if (isFunction(finalizer)) {
        finalizer();
    }
    else {
        finalizer.unsubscribe();
    }
}

var config = {
    onUnhandledError: null,
    onStoppedNotification: null,
    Promise: undefined,
    useDeprecatedSynchronousErrorHandling: false,
    useDeprecatedNextContext: false,
};

var timeoutProvider = {
    setTimeout: function (handler, timeout) {
        var args = [];
        for (var _i = 2; _i < arguments.length; _i++) {
            args[_i - 2] = arguments[_i];
        }
        var delegate = timeoutProvider.delegate;
        if (delegate === null || delegate === void 0 ? void 0 : delegate.setTimeout) {
            return delegate.setTimeout.apply(delegate, __spreadArray([handler, timeout], __read(args)));
        }
        return setTimeout.apply(void 0, __spreadArray([handler, timeout], __read(args)));
    },
    clearTimeout: function (handle) {
        var delegate = timeoutProvider.delegate;
        return ((delegate === null || delegate === void 0 ? void 0 : delegate.clearTimeout) || clearTimeout)(handle);
    },
    delegate: undefined,
};

function reportUnhandledError(err) {
    timeoutProvider.setTimeout(function () {
        {
            throw err;
        }
    });
}

function noop() { }

var context = null;
function errorContext(cb) {
    if (config.useDeprecatedSynchronousErrorHandling) {
        var isRoot = !context;
        if (isRoot) {
            context = { errorThrown: false, error: null };
        }
        cb();
        if (isRoot) {
            var _a = context, errorThrown = _a.errorThrown, error = _a.error;
            context = null;
            if (errorThrown) {
                throw error;
            }
        }
    }
    else {
        cb();
    }
}

var Subscriber = (function (_super) {
    __extends(Subscriber, _super);
    function Subscriber(destination) {
        var _this = _super.call(this) || this;
        _this.isStopped = false;
        if (destination) {
            _this.destination = destination;
            if (isSubscription(destination)) {
                destination.add(_this);
            }
        }
        else {
            _this.destination = EMPTY_OBSERVER;
        }
        return _this;
    }
    Subscriber.create = function (next, error, complete) {
        return new SafeSubscriber(next, error, complete);
    };
    Subscriber.prototype.next = function (value) {
        if (this.isStopped) ;
        else {
            this._next(value);
        }
    };
    Subscriber.prototype.error = function (err) {
        if (this.isStopped) ;
        else {
            this.isStopped = true;
            this._error(err);
        }
    };
    Subscriber.prototype.complete = function () {
        if (this.isStopped) ;
        else {
            this.isStopped = true;
            this._complete();
        }
    };
    Subscriber.prototype.unsubscribe = function () {
        if (!this.closed) {
            this.isStopped = true;
            _super.prototype.unsubscribe.call(this);
            this.destination = null;
        }
    };
    Subscriber.prototype._next = function (value) {
        this.destination.next(value);
    };
    Subscriber.prototype._error = function (err) {
        try {
            this.destination.error(err);
        }
        finally {
            this.unsubscribe();
        }
    };
    Subscriber.prototype._complete = function () {
        try {
            this.destination.complete();
        }
        finally {
            this.unsubscribe();
        }
    };
    return Subscriber;
}(Subscription));
var _bind = Function.prototype.bind;
function bind(fn, thisArg) {
    return _bind.call(fn, thisArg);
}
var ConsumerObserver = (function () {
    function ConsumerObserver(partialObserver) {
        this.partialObserver = partialObserver;
    }
    ConsumerObserver.prototype.next = function (value) {
        var partialObserver = this.partialObserver;
        if (partialObserver.next) {
            try {
                partialObserver.next(value);
            }
            catch (error) {
                handleUnhandledError(error);
            }
        }
    };
    ConsumerObserver.prototype.error = function (err) {
        var partialObserver = this.partialObserver;
        if (partialObserver.error) {
            try {
                partialObserver.error(err);
            }
            catch (error) {
                handleUnhandledError(error);
            }
        }
        else {
            handleUnhandledError(err);
        }
    };
    ConsumerObserver.prototype.complete = function () {
        var partialObserver = this.partialObserver;
        if (partialObserver.complete) {
            try {
                partialObserver.complete();
            }
            catch (error) {
                handleUnhandledError(error);
            }
        }
    };
    return ConsumerObserver;
}());
var SafeSubscriber = (function (_super) {
    __extends(SafeSubscriber, _super);
    function SafeSubscriber(observerOrNext, error, complete) {
        var _this = _super.call(this) || this;
        var partialObserver;
        if (isFunction(observerOrNext) || !observerOrNext) {
            partialObserver = {
                next: (observerOrNext !== null && observerOrNext !== void 0 ? observerOrNext : undefined),
                error: error !== null && error !== void 0 ? error : undefined,
                complete: complete !== null && complete !== void 0 ? complete : undefined,
            };
        }
        else {
            var context_1;
            if (_this && config.useDeprecatedNextContext) {
                context_1 = Object.create(observerOrNext);
                context_1.unsubscribe = function () { return _this.unsubscribe(); };
                partialObserver = {
                    next: observerOrNext.next && bind(observerOrNext.next, context_1),
                    error: observerOrNext.error && bind(observerOrNext.error, context_1),
                    complete: observerOrNext.complete && bind(observerOrNext.complete, context_1),
                };
            }
            else {
                partialObserver = observerOrNext;
            }
        }
        _this.destination = new ConsumerObserver(partialObserver);
        return _this;
    }
    return SafeSubscriber;
}(Subscriber));
function handleUnhandledError(error) {
    {
        reportUnhandledError(error);
    }
}
function defaultErrorHandler(err) {
    throw err;
}
var EMPTY_OBSERVER = {
    closed: true,
    next: noop,
    error: defaultErrorHandler,
    complete: noop,
};

var observable = (function () { return (typeof Symbol === 'function' && Symbol.observable) || '@@observable'; })();

function identity(x) {
    return x;
}

function pipeFromArray(fns) {
    if (fns.length === 0) {
        return identity;
    }
    if (fns.length === 1) {
        return fns[0];
    }
    return function piped(input) {
        return fns.reduce(function (prev, fn) { return fn(prev); }, input);
    };
}

var Observable = (function () {
    function Observable(subscribe) {
        if (subscribe) {
            this._subscribe = subscribe;
        }
    }
    Observable.prototype.lift = function (operator) {
        var observable = new Observable();
        observable.source = this;
        observable.operator = operator;
        return observable;
    };
    Observable.prototype.subscribe = function (observerOrNext, error, complete) {
        var _this = this;
        var subscriber = isSubscriber(observerOrNext) ? observerOrNext : new SafeSubscriber(observerOrNext, error, complete);
        errorContext(function () {
            var _a = _this, operator = _a.operator, source = _a.source;
            subscriber.add(operator
                ?
                    operator.call(subscriber, source)
                : source
                    ?
                        _this._subscribe(subscriber)
                    :
                        _this._trySubscribe(subscriber));
        });
        return subscriber;
    };
    Observable.prototype._trySubscribe = function (sink) {
        try {
            return this._subscribe(sink);
        }
        catch (err) {
            sink.error(err);
        }
    };
    Observable.prototype.forEach = function (next, promiseCtor) {
        var _this = this;
        promiseCtor = getPromiseCtor(promiseCtor);
        return new promiseCtor(function (resolve, reject) {
            var subscriber = new SafeSubscriber({
                next: function (value) {
                    try {
                        next(value);
                    }
                    catch (err) {
                        reject(err);
                        subscriber.unsubscribe();
                    }
                },
                error: reject,
                complete: resolve,
            });
            _this.subscribe(subscriber);
        });
    };
    Observable.prototype._subscribe = function (subscriber) {
        var _a;
        return (_a = this.source) === null || _a === void 0 ? void 0 : _a.subscribe(subscriber);
    };
    Observable.prototype[observable] = function () {
        return this;
    };
    Observable.prototype.pipe = function () {
        var operations = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            operations[_i] = arguments[_i];
        }
        return pipeFromArray(operations)(this);
    };
    Observable.prototype.toPromise = function (promiseCtor) {
        var _this = this;
        promiseCtor = getPromiseCtor(promiseCtor);
        return new promiseCtor(function (resolve, reject) {
            var value;
            _this.subscribe(function (x) { return (value = x); }, function (err) { return reject(err); }, function () { return resolve(value); });
        });
    };
    Observable.create = function (subscribe) {
        return new Observable(subscribe);
    };
    return Observable;
}());
function getPromiseCtor(promiseCtor) {
    var _a;
    return (_a = promiseCtor !== null && promiseCtor !== void 0 ? promiseCtor : config.Promise) !== null && _a !== void 0 ? _a : Promise;
}
function isObserver(value) {
    return value && isFunction(value.next) && isFunction(value.error) && isFunction(value.complete);
}
function isSubscriber(value) {
    return (value && value instanceof Subscriber) || (isObserver(value) && isSubscription(value));
}

function hasLift(source) {
    return isFunction(source === null || source === void 0 ? void 0 : source.lift);
}
function operate(init) {
    return function (source) {
        if (hasLift(source)) {
            return source.lift(function (liftedSource) {
                try {
                    return init(liftedSource, this);
                }
                catch (err) {
                    this.error(err);
                }
            });
        }
        throw new TypeError('Unable to lift unknown Observable type');
    };
}

function createOperatorSubscriber(destination, onNext, onComplete, onError, onFinalize) {
    return new OperatorSubscriber(destination, onNext, onComplete, onError, onFinalize);
}
var OperatorSubscriber = (function (_super) {
    __extends(OperatorSubscriber, _super);
    function OperatorSubscriber(destination, onNext, onComplete, onError, onFinalize, shouldUnsubscribe) {
        var _this = _super.call(this, destination) || this;
        _this.onFinalize = onFinalize;
        _this.shouldUnsubscribe = shouldUnsubscribe;
        _this._next = onNext
            ? function (value) {
                try {
                    onNext(value);
                }
                catch (err) {
                    destination.error(err);
                }
            }
            : _super.prototype._next;
        _this._error = onError
            ? function (err) {
                try {
                    onError(err);
                }
                catch (err) {
                    destination.error(err);
                }
                finally {
                    this.unsubscribe();
                }
            }
            : _super.prototype._error;
        _this._complete = onComplete
            ? function () {
                try {
                    onComplete();
                }
                catch (err) {
                    destination.error(err);
                }
                finally {
                    this.unsubscribe();
                }
            }
            : _super.prototype._complete;
        return _this;
    }
    OperatorSubscriber.prototype.unsubscribe = function () {
        var _a;
        if (!this.shouldUnsubscribe || this.shouldUnsubscribe()) {
            var closed_1 = this.closed;
            _super.prototype.unsubscribe.call(this);
            !closed_1 && ((_a = this.onFinalize) === null || _a === void 0 ? void 0 : _a.call(this));
        }
    };
    return OperatorSubscriber;
}(Subscriber));

var ObjectUnsubscribedError = createErrorClass(function (_super) {
    return function ObjectUnsubscribedErrorImpl() {
        _super(this);
        this.name = 'ObjectUnsubscribedError';
        this.message = 'object unsubscribed';
    };
});

var Subject = (function (_super) {
    __extends(Subject, _super);
    function Subject() {
        var _this = _super.call(this) || this;
        _this.closed = false;
        _this.currentObservers = null;
        _this.observers = [];
        _this.isStopped = false;
        _this.hasError = false;
        _this.thrownError = null;
        return _this;
    }
    Subject.prototype.lift = function (operator) {
        var subject = new AnonymousSubject(this, this);
        subject.operator = operator;
        return subject;
    };
    Subject.prototype._throwIfClosed = function () {
        if (this.closed) {
            throw new ObjectUnsubscribedError();
        }
    };
    Subject.prototype.next = function (value) {
        var _this = this;
        errorContext(function () {
            var e_1, _a;
            _this._throwIfClosed();
            if (!_this.isStopped) {
                if (!_this.currentObservers) {
                    _this.currentObservers = Array.from(_this.observers);
                }
                try {
                    for (var _b = __values(_this.currentObservers), _c = _b.next(); !_c.done; _c = _b.next()) {
                        var observer = _c.value;
                        observer.next(value);
                    }
                }
                catch (e_1_1) { e_1 = { error: e_1_1 }; }
                finally {
                    try {
                        if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
                    }
                    finally { if (e_1) throw e_1.error; }
                }
            }
        });
    };
    Subject.prototype.error = function (err) {
        var _this = this;
        errorContext(function () {
            _this._throwIfClosed();
            if (!_this.isStopped) {
                _this.hasError = _this.isStopped = true;
                _this.thrownError = err;
                var observers = _this.observers;
                while (observers.length) {
                    observers.shift().error(err);
                }
            }
        });
    };
    Subject.prototype.complete = function () {
        var _this = this;
        errorContext(function () {
            _this._throwIfClosed();
            if (!_this.isStopped) {
                _this.isStopped = true;
                var observers = _this.observers;
                while (observers.length) {
                    observers.shift().complete();
                }
            }
        });
    };
    Subject.prototype.unsubscribe = function () {
        this.isStopped = this.closed = true;
        this.observers = this.currentObservers = null;
    };
    Object.defineProperty(Subject.prototype, "observed", {
        get: function () {
            var _a;
            return ((_a = this.observers) === null || _a === void 0 ? void 0 : _a.length) > 0;
        },
        enumerable: false,
        configurable: true
    });
    Subject.prototype._trySubscribe = function (subscriber) {
        this._throwIfClosed();
        return _super.prototype._trySubscribe.call(this, subscriber);
    };
    Subject.prototype._subscribe = function (subscriber) {
        this._throwIfClosed();
        this._checkFinalizedStatuses(subscriber);
        return this._innerSubscribe(subscriber);
    };
    Subject.prototype._innerSubscribe = function (subscriber) {
        var _this = this;
        var _a = this, hasError = _a.hasError, isStopped = _a.isStopped, observers = _a.observers;
        if (hasError || isStopped) {
            return EMPTY_SUBSCRIPTION;
        }
        this.currentObservers = null;
        observers.push(subscriber);
        return new Subscription(function () {
            _this.currentObservers = null;
            arrRemove(observers, subscriber);
        });
    };
    Subject.prototype._checkFinalizedStatuses = function (subscriber) {
        var _a = this, hasError = _a.hasError, thrownError = _a.thrownError, isStopped = _a.isStopped;
        if (hasError) {
            subscriber.error(thrownError);
        }
        else if (isStopped) {
            subscriber.complete();
        }
    };
    Subject.prototype.asObservable = function () {
        var observable = new Observable();
        observable.source = this;
        return observable;
    };
    Subject.create = function (destination, source) {
        return new AnonymousSubject(destination, source);
    };
    return Subject;
}(Observable));
var AnonymousSubject = (function (_super) {
    __extends(AnonymousSubject, _super);
    function AnonymousSubject(destination, source) {
        var _this = _super.call(this) || this;
        _this.destination = destination;
        _this.source = source;
        return _this;
    }
    AnonymousSubject.prototype.next = function (value) {
        var _a, _b;
        (_b = (_a = this.destination) === null || _a === void 0 ? void 0 : _a.next) === null || _b === void 0 ? void 0 : _b.call(_a, value);
    };
    AnonymousSubject.prototype.error = function (err) {
        var _a, _b;
        (_b = (_a = this.destination) === null || _a === void 0 ? void 0 : _a.error) === null || _b === void 0 ? void 0 : _b.call(_a, err);
    };
    AnonymousSubject.prototype.complete = function () {
        var _a, _b;
        (_b = (_a = this.destination) === null || _a === void 0 ? void 0 : _a.complete) === null || _b === void 0 ? void 0 : _b.call(_a);
    };
    AnonymousSubject.prototype._subscribe = function (subscriber) {
        var _a, _b;
        return (_b = (_a = this.source) === null || _a === void 0 ? void 0 : _a.subscribe(subscriber)) !== null && _b !== void 0 ? _b : EMPTY_SUBSCRIPTION;
    };
    return AnonymousSubject;
}(Subject));

function map(project, thisArg) {
    return operate(function (source, subscriber) {
        var index = 0;
        source.subscribe(createOperatorSubscriber(subscriber, function (value) {
            subscriber.next(project.call(thisArg, value, index++));
        }));
    });
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
function isPromiseCompletionSource(obj) {
    return obj.promise
        && obj.resolve
        && obj.reject;
}
class PromiseCompletionSource {
    constructor() {
        this._resolve = () => { };
        this._reject = () => { };
        this.promise = new Promise((resolve, reject) => {
            this._resolve = resolve;
            this._reject = reject;
        });
    }
    resolve(value) {
        this._resolve(value);
    }
    reject(reason) {
        this._reject(reason);
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class KernelInvocationContext {
    constructor(kernelCommandInvocation) {
        this._childCommands = [];
        this._eventSubject = new Subject();
        this._isComplete = false;
        this._handlingKernel = null;
        this._completionSource = new PromiseCompletionSource();
        this._commandEnvelope = kernelCommandInvocation;
    }
    get handlingKernel() {
        return this._handlingKernel;
    }
    ;
    get kernelEvents() {
        return this._eventSubject.asObservable();
    }
    ;
    set handlingKernel(value) {
        this._handlingKernel = value;
    }
    get promise() {
        return this._completionSource.promise;
    }
    static getOrCreateAmbientContext(command) {
        let current = KernelInvocationContext._current;
        if (!current || current._isComplete) {
            command.getOrCreateToken();
            KernelInvocationContext._current = new KernelInvocationContext(command);
        }
        else {
            if (!KernelCommandEnvelope.areCommandsTheSame(command, current._commandEnvelope)) {
                const found = current._childCommands.includes(command);
                if (!found) {
                    if (command.parentCommand === null || command.parentCommand === undefined) {
                        command.setParent(current._commandEnvelope);
                    }
                    current._childCommands.push(command);
                }
            }
        }
        return KernelInvocationContext._current;
    }
    static get current() { return this._current; }
    get command() { return this._commandEnvelope.command; }
    get commandEnvelope() { return this._commandEnvelope; }
    complete(command) {
        if (KernelCommandEnvelope.areCommandsTheSame(command, this._commandEnvelope)) {
            this._isComplete = true;
            let succeeded = {};
            let eventEnvelope = new KernelEventEnvelope(CommandSucceededType, succeeded, this._commandEnvelope);
            this.internalPublish(eventEnvelope);
            this._completionSource.resolve();
        }
        else {
            let pos = this._childCommands.indexOf(command);
            delete this._childCommands[pos];
        }
    }
    fail(message) {
        // The C# code accepts a message and/or an exception. Do we need to add support
        // for exceptions? (The TS CommandFailed interface doesn't have a place for it right now.)
        this._isComplete = true;
        let failed = { message: message !== null && message !== void 0 ? message : "Command Failed" };
        let eventEnvelope = new KernelEventEnvelope(CommandFailedType, failed, this._commandEnvelope);
        this.internalPublish(eventEnvelope);
        this._completionSource.resolve();
    }
    publish(kernelEvent) {
        if (!this._isComplete) {
            this.internalPublish(kernelEvent);
        }
    }
    internalPublish(kernelEvent) {
        if (!kernelEvent.command) {
            kernelEvent.command = this._commandEnvelope;
        }
        let command = kernelEvent.command;
        if (this.handlingKernel) {
            const kernelUri = getKernelUri(this.handlingKernel);
            if (!kernelEvent.routingSlip.contains(kernelUri)) {
                kernelEvent.routingSlip.stamp(kernelUri);
                kernelEvent.routingSlip; //?
            }
        }
        this._commandEnvelope; //?
        if (command === null ||
            command === undefined ||
            KernelCommandEnvelope.areCommandsTheSame(command, this._commandEnvelope) ||
            this._childCommands.includes(command)) {
            this._eventSubject.next(kernelEvent);
        }
        else if (command.isSelforDescendantOf(this._commandEnvelope)) {
            this._eventSubject.next(kernelEvent);
        }
        else if (command.hasSameRootCommandAs(this._commandEnvelope)) {
            this._eventSubject.next(kernelEvent);
        }
    }
    isParentOfCommand(commandEnvelope) {
        const childFound = this._childCommands.includes(commandEnvelope);
        return childFound;
    }
    dispose() {
        if (!this._isComplete) {
            this.complete(this._commandEnvelope);
        }
        KernelInvocationContext._current = null;
    }
}
KernelInvocationContext._current = null;

// Copyright (c) .NET Foundation and contributors. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
var LogLevel;
(function (LogLevel) {
    LogLevel[LogLevel["Info"] = 0] = "Info";
    LogLevel[LogLevel["Warn"] = 1] = "Warn";
    LogLevel[LogLevel["Error"] = 2] = "Error";
    LogLevel[LogLevel["None"] = 3] = "None";
})(LogLevel || (LogLevel = {}));
class Logger {
    constructor(source, write) {
        this.source = source;
        this.write = write;
    }
    info(message) {
        this.write({ logLevel: LogLevel.Info, source: this.source, message });
    }
    warn(message) {
        this.write({ logLevel: LogLevel.Warn, source: this.source, message });
    }
    error(message) {
        this.write({ logLevel: LogLevel.Error, source: this.source, message });
    }
    static configure(source, writer) {
        const logger = new Logger(source, writer);
        Logger._default = logger;
    }
    static get default() {
        if (Logger._default) {
            return Logger._default;
        }
        throw new Error('No logger has been configured for this context');
    }
}
Logger._default = new Logger('default', (_entry) => { });

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class KernelScheduler {
    constructor() {
        this._operationQueue = [];
        this._mustTrampoline = (_c) => false;
    }
    setMustTrampoline(predicate) {
        this._mustTrampoline = predicate !== null && predicate !== void 0 ? predicate : ((_c) => false);
    }
    cancelCurrentOperation() {
        var _a;
        (_a = this._inFlightOperation) === null || _a === void 0 ? void 0 : _a.promiseCompletionSource.reject(new Error("Operation cancelled"));
    }
    runAsync(value, executor) {
        const operation = {
            value,
            executor,
            promiseCompletionSource: new PromiseCompletionSource(),
        };
        const mustTrampoline = this._mustTrampoline(value);
        if (this._inFlightOperation && !mustTrampoline) {
            Logger.default.info(`kernelScheduler: starting immediate execution of ${JSON.stringify(operation.value)}`);
            // invoke immediately
            return operation.executor(operation.value)
                .then(() => {
                Logger.default.info(`kernelScheduler: immediate execution completed: ${JSON.stringify(operation.value)}`);
                operation.promiseCompletionSource.resolve();
            })
                .catch(e => {
                Logger.default.info(`kernelScheduler: immediate execution failed: ${JSON.stringify(e)} - ${JSON.stringify(operation.value)}`);
                operation.promiseCompletionSource.reject(e);
            });
        }
        Logger.default.info(`kernelScheduler: scheduling execution of ${JSON.stringify(operation.value)}`);
        this._operationQueue.push(operation);
        if (this._operationQueue.length === 1) {
            setTimeout(() => {
                this.executeNextCommand();
            }, 0);
        }
        return operation.promiseCompletionSource.promise;
    }
    executeNextCommand() {
        const nextOperation = this._operationQueue.length > 0 ? this._operationQueue[0] : undefined;
        if (nextOperation) {
            this._inFlightOperation = nextOperation;
            Logger.default.info(`kernelScheduler: starting scheduled execution of ${JSON.stringify(nextOperation.value)}`);
            nextOperation.executor(nextOperation.value)
                .then(() => {
                this._inFlightOperation = undefined;
                Logger.default.info(`kernelScheduler: completing inflight operation: success ${JSON.stringify(nextOperation.value)}`);
                nextOperation.promiseCompletionSource.resolve();
            })
                .catch(e => {
                this._inFlightOperation = undefined;
                Logger.default.info(`kernelScheduler: completing inflight operation: failure ${JSON.stringify(e)} - ${JSON.stringify(nextOperation.value)}`);
                nextOperation.promiseCompletionSource.reject(e);
            })
                .finally(() => {
                this._inFlightOperation = undefined;
                setTimeout(() => {
                    this._operationQueue.shift();
                    this.executeNextCommand();
                }, 0);
            });
        }
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class Kernel {
    constructor(name, languageName, languageVersion, displayName) {
        this.name = name;
        this._commandHandlers = new Map();
        this._eventSubject = new Subject();
        this.rootKernel = this;
        this.parentKernel = null;
        this._scheduler = null;
        this._kernelInfo = {
            isProxy: false,
            isComposite: false,
            localName: name,
            languageName: languageName,
            aliases: [],
            uri: createKernelUri(`kernel://local/${name}`),
            languageVersion: languageVersion,
            displayName: displayName !== null && displayName !== void 0 ? displayName : name,
            supportedKernelCommands: []
        };
        this._internalRegisterCommandHandler({
            commandType: RequestKernelInfoType, handle: (invocation) => __awaiter(this, void 0, void 0, function* () {
                yield this.handleRequestKernelInfo(invocation);
            })
        });
    }
    get kernelInfo() {
        return this._kernelInfo;
    }
    get kernelEvents() {
        return this._eventSubject.asObservable();
    }
    handleRequestKernelInfo(invocation) {
        return __awaiter(this, void 0, void 0, function* () {
            const eventEnvelope = new KernelEventEnvelope(KernelInfoProducedType, { kernelInfo: this._kernelInfo }, invocation.commandEnvelope); //?
            invocation.context.publish(eventEnvelope);
            return Promise.resolve();
        });
    }
    getScheduler() {
        var _a, _b;
        if (!this._scheduler) {
            this._scheduler = (_b = (_a = this.parentKernel) === null || _a === void 0 ? void 0 : _a.getScheduler()) !== null && _b !== void 0 ? _b : new KernelScheduler();
        }
        return this._scheduler;
    }
    static get current() {
        if (KernelInvocationContext.current) {
            return KernelInvocationContext.current.handlingKernel;
        }
        return null;
    }
    static get root() {
        if (Kernel.current) {
            return Kernel.current.rootKernel;
        }
        return null;
    }
    // Is it worth us going to efforts to ensure that the Promise returned here accurately reflects
    // the command's progress? The only thing that actually calls this is the kernel channel, through
    // the callback set up by attachKernelToChannel, and the callback is expected to return void, so
    // nothing is ever going to look at the promise we return here.
    send(commandEnvelopeOrModel) {
        return __awaiter(this, void 0, void 0, function* () {
            let commandEnvelope = commandEnvelopeOrModel;
            if (KernelCommandEnvelope.isKernelCommandEnvelopeModel(commandEnvelopeOrModel)) {
                Logger.default.warn(`Converting command envelope model to command envelope for backawards compatibility.`);
                commandEnvelope = KernelCommandEnvelope.fromJson(commandEnvelopeOrModel);
            }
            const context = KernelInvocationContext.getOrCreateAmbientContext(commandEnvelope);
            if (context.commandEnvelope) {
                if (!KernelCommandEnvelope.areCommandsTheSame(context.commandEnvelope, commandEnvelope)) {
                    commandEnvelope.setParent(context.commandEnvelope);
                }
            }
            const kernelUri = getKernelUri(this);
            if (!commandEnvelope.routingSlip.contains(kernelUri)) {
                commandEnvelope.routingSlip.stampAsArrived(kernelUri);
            }
            else {
                Logger.default.warn(`Trying to stamp ${commandEnvelope.commandType} as arrived but uri ${kernelUri} is already present.`);
            }
            commandEnvelope.routingSlip; //?
            return this.getScheduler().runAsync(commandEnvelope, (value) => this.executeCommand(value).finally(() => {
                if (!commandEnvelope.routingSlip.contains(kernelUri)) {
                    commandEnvelope.routingSlip.stamp(kernelUri);
                }
                else {
                    Logger.default.warn(`Trying to stamp ${commandEnvelope.commandType} as completed but uri ${kernelUri} is already present.`);
                }
            }));
        });
    }
    executeCommand(commandEnvelope) {
        return __awaiter(this, void 0, void 0, function* () {
            let context = KernelInvocationContext.getOrCreateAmbientContext(commandEnvelope);
            let previousHandlingKernel = context.handlingKernel;
            try {
                yield this.handleCommand(commandEnvelope);
            }
            catch (e) {
                context.fail((e === null || e === void 0 ? void 0 : e.message) || JSON.stringify(e));
            }
            finally {
                context.handlingKernel = previousHandlingKernel;
            }
        });
    }
    getCommandHandler(commandType) {
        return this._commandHandlers.get(commandType);
    }
    handleCommand(commandEnvelope) {
        return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
            let context = KernelInvocationContext.getOrCreateAmbientContext(commandEnvelope);
            const previoudHendlingKernel = context.handlingKernel;
            context.handlingKernel = this;
            let isRootCommand = KernelCommandEnvelope.areCommandsTheSame(context.commandEnvelope, commandEnvelope);
            let eventSubscription = undefined; //?
            if (isRootCommand) {
                const kernelType = (this.kernelInfo.isProxy ? "proxy" : "") + (this.kernelInfo.isComposite ? "composite" : "");
                Logger.default.info(`kernel ${this.name} of type ${kernelType} subscribing to context events`);
                eventSubscription = context.kernelEvents.pipe(map(e => {
                    var _a;
                    const message = `kernel ${this.name} of type ${kernelType} saw event ${e.eventType} with token ${(_a = e.command) === null || _a === void 0 ? void 0 : _a.getToken()}`;
                    Logger.default.info(message);
                    const kernelUri = getKernelUri(this);
                    if (!e.routingSlip.contains(kernelUri)) {
                        e.routingSlip.stamp(kernelUri);
                    }
                    return e;
                }))
                    .subscribe(this.publishEvent.bind(this));
            }
            let handler = this.getCommandHandler(commandEnvelope.commandType);
            if (handler) {
                try {
                    Logger.default.info(`kernel ${this.name} about to handle command: ${JSON.stringify(commandEnvelope)}`);
                    yield handler.handle({ commandEnvelope: commandEnvelope, context });
                    context.complete(commandEnvelope);
                    context.handlingKernel = previoudHendlingKernel;
                    if (isRootCommand) {
                        eventSubscription === null || eventSubscription === void 0 ? void 0 : eventSubscription.unsubscribe();
                        context.dispose();
                    }
                    Logger.default.info(`kernel ${this.name} done handling command: ${JSON.stringify(commandEnvelope)}`);
                    resolve();
                }
                catch (e) {
                    context.fail((e === null || e === void 0 ? void 0 : e.message) || JSON.stringify(e));
                    context.handlingKernel = previoudHendlingKernel;
                    if (isRootCommand) {
                        eventSubscription === null || eventSubscription === void 0 ? void 0 : eventSubscription.unsubscribe();
                        context.dispose();
                    }
                    reject(e);
                }
            }
            else {
                // hack like there is no tomorrow
                const shouldNoop = this.shouldNoopCommand(commandEnvelope, context);
                if (shouldNoop) {
                    context.complete(commandEnvelope);
                }
                context.handlingKernel = previoudHendlingKernel;
                if (isRootCommand) {
                    eventSubscription === null || eventSubscription === void 0 ? void 0 : eventSubscription.unsubscribe();
                    context.dispose();
                }
                if (!shouldNoop) {
                    reject(new Error(`No handler found for command type ${commandEnvelope.commandType}`));
                }
                else {
                    Logger.default.warn(`kernel ${this.name} done noop handling command: ${JSON.stringify(commandEnvelope)}`);
                    resolve();
                }
            }
        }));
    }
    shouldNoopCommand(commandEnvelope, context) {
        let shouldNoop = false;
        switch (commandEnvelope.commandType) {
            case RequestCompletionsType:
            case RequestSignatureHelpType:
            case RequestDiagnosticsType:
            case RequestHoverTextType:
                shouldNoop = true;
                break;
            default:
                shouldNoop = false;
                break;
        }
        return shouldNoop;
    }
    subscribeToKernelEvents(observer) {
        const sub = this._eventSubject.subscribe(observer);
        return {
            dispose: () => { sub.unsubscribe(); }
        };
    }
    canHandle(commandEnvelope) {
        if (commandEnvelope.command.targetKernelName && commandEnvelope.command.targetKernelName !== this.name) {
            return false;
        }
        if (commandEnvelope.command.destinationUri) {
            const normalizedUri = createKernelUri(commandEnvelope.command.destinationUri);
            if (this.kernelInfo.uri !== normalizedUri) {
                return false;
            }
        }
        return this.supportsCommand(commandEnvelope.commandType);
    }
    supportsCommand(commandType) {
        return this._commandHandlers.has(commandType);
    }
    registerCommandHandler(handler) {
        // When a registration already existed, we want to overwrite it because we want users to
        // be able to develop handlers iteratively, and it would be unhelpful for handler registration
        // for any particular command to be cumulative.
        var _a;
        const shouldNotify = !this._commandHandlers.has(handler.commandType);
        this._internalRegisterCommandHandler(handler);
        if (shouldNotify) {
            const event = {
                kernelInfo: this._kernelInfo,
            };
            const envelope = new KernelEventEnvelope(KernelInfoProducedType, event, (_a = KernelInvocationContext.current) === null || _a === void 0 ? void 0 : _a.commandEnvelope);
            envelope.routingSlip.stamp(getKernelUri(this));
            const context = KernelInvocationContext.current;
            if (context) {
                envelope.command = context.commandEnvelope;
                context.publish(envelope);
            }
            else {
                this.publishEvent(envelope);
            }
        }
    }
    _internalRegisterCommandHandler(handler) {
        this._commandHandlers.set(handler.commandType, handler);
        this._kernelInfo.supportedKernelCommands = Array.from(this._commandHandlers.keys()).map(commandName => ({ name: commandName }));
    }
    getHandlingKernel(commandEnvelope, context) {
        if (this.canHandle(commandEnvelope)) {
            return this;
        }
        else {
            context === null || context === void 0 ? void 0 : context.fail(`Command ${commandEnvelope.commandType} is not supported by Kernel ${this.name}`);
            return null;
        }
    }
    publishEvent(kernelEvent) {
        this._eventSubject.next(kernelEvent);
    }
}
function submitCommandAndGetResult(kernel, commandEnvelope, expectedEventType) {
    return __awaiter(this, void 0, void 0, function* () {
        let completionSource = new PromiseCompletionSource();
        let handled = false;
        let disposable = kernel.subscribeToKernelEvents(eventEnvelope => {
            var _a;
            if (((_a = eventEnvelope.command) === null || _a === void 0 ? void 0 : _a.getToken()) === commandEnvelope.getToken()) {
                switch (eventEnvelope.eventType) {
                    case CommandFailedType:
                        if (!handled) {
                            handled = true;
                            let err = eventEnvelope.event; //?
                            completionSource.reject(err);
                        }
                        break;
                    case CommandSucceededType:
                        if (KernelCommandEnvelope.areCommandsTheSame(eventEnvelope.command, commandEnvelope)) {
                            if (!handled) { //? ($ ? eventEnvelope : {})
                                handled = true;
                                completionSource.reject('Command was handled before reporting expected result.');
                            }
                            break;
                        }
                    default:
                        if (eventEnvelope.eventType === expectedEventType) {
                            handled = true;
                            let event = eventEnvelope.event; //? ($ ? eventEnvelope : {})
                            completionSource.resolve(event);
                        }
                        break;
                }
            }
        });
        try {
            yield kernel.send(commandEnvelope);
        }
        finally {
            disposable.dispose();
        }
        return completionSource.promise;
    });
}
function getKernelUri(kernel) {
    var _a;
    return (_a = kernel.kernelInfo.uri) !== null && _a !== void 0 ? _a : `kernel://local/${kernel.kernelInfo.localName}`;
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class CompositeKernel extends Kernel {
    constructor(name) {
        super(name);
        this._host = null;
        this._defaultKernelNamesByCommandType = new Map();
        this.kernelInfo.isComposite = true;
        this._childKernels = new KernelCollection(this);
    }
    get childKernels() {
        return Array.from(this._childKernels);
    }
    get host() {
        return this._host;
    }
    set host(host) {
        this._host = host;
        if (this._host) {
            this.kernelInfo.uri = this._host.uri;
            this._childKernels.notifyThatHostWasSet();
        }
    }
    handleRequestKernelInfo(invocation) {
        return __awaiter(this, void 0, void 0, function* () {
            const eventEnvelope = new KernelEventEnvelope(KernelInfoProducedType, { kernelInfo: this.kernelInfo }, invocation.commandEnvelope); //?
            invocation.context.publish(eventEnvelope);
            for (let kernel of this._childKernels) {
                if (kernel.supportsCommand(invocation.commandEnvelope.commandType)) {
                    const childCommand = new KernelCommandEnvelope(RequestKernelInfoType, {
                        targetKernelName: kernel.kernelInfo.localName
                    });
                    childCommand.setParent(invocation.commandEnvelope);
                    childCommand.routingSlip.continueWith(invocation.commandEnvelope.routingSlip);
                    yield kernel.handleCommand(childCommand);
                }
            }
        });
    }
    add(kernel, aliases) {
        if (!kernel) {
            throw new Error("kernel cannot be null or undefined");
        }
        if (!this.defaultKernelName) {
            // default to first kernel
            this.defaultKernelName = kernel.name;
        }
        kernel.parentKernel = this;
        kernel.rootKernel = this.rootKernel;
        kernel.kernelEvents.subscribe({
            next: (event) => {
                const kernelUri = getKernelUri(this);
                if (!event.routingSlip.contains(kernelUri)) {
                    event.routingSlip.stamp(kernelUri);
                }
                this.publishEvent(event);
            }
        });
        if (aliases) {
            let set = new Set(aliases);
            if (kernel.kernelInfo.aliases) {
                for (let alias in kernel.kernelInfo.aliases) {
                    set.add(alias);
                }
            }
            kernel.kernelInfo.aliases = Array.from(set);
        }
        this._childKernels.add(kernel, aliases);
        const invocationContext = KernelInvocationContext.current;
        if (invocationContext) {
            invocationContext.commandEnvelope;
            const event = new KernelEventEnvelope(KernelInfoProducedType, {
                kernelInfo: kernel.kernelInfo
            }, invocationContext.commandEnvelope);
            invocationContext.publish(event);
        }
        else {
            const event = new KernelEventEnvelope(KernelInfoProducedType, {
                kernelInfo: kernel.kernelInfo
            });
            this.publishEvent(event);
        }
    }
    findKernelByUri(uri) {
        const normalized = createKernelUri(uri);
        if (this.kernelInfo.uri === normalized) {
            return this;
        }
        return this._childKernels.tryGetByUri(normalized);
    }
    findKernelByName(name) {
        if (this.kernelInfo.localName === name || this.kernelInfo.aliases.find(a => a === name)) {
            return this;
        }
        return this._childKernels.tryGetByAlias(name);
    }
    findKernels(predicate) {
        var results = [];
        if (predicate(this)) {
            results.push(this);
        }
        for (let kernel of this.childKernels) {
            if (predicate(kernel)) {
                results.push(kernel);
            }
        }
        return results;
    }
    findKernel(predicate) {
        if (predicate(this)) {
            return this;
        }
        return this.childKernels.find(predicate);
    }
    setDefaultTargetKernelNameForCommand(commandType, kernelName) {
        this._defaultKernelNamesByCommandType.set(commandType, kernelName);
    }
    handleCommand(commandEnvelope) {
        var _a;
        const invocationContext = KernelInvocationContext.current;
        let kernel = commandEnvelope.command.targetKernelName === this.name
            ? this
            : this.getHandlingKernel(commandEnvelope, invocationContext);
        const previusoHandlingKernel = (_a = invocationContext === null || invocationContext === void 0 ? void 0 : invocationContext.handlingKernel) !== null && _a !== void 0 ? _a : null;
        if (kernel === this) {
            if (invocationContext !== null) {
                invocationContext.handlingKernel = kernel;
            }
            return super.handleCommand(commandEnvelope).finally(() => {
                if (invocationContext !== null) {
                    invocationContext.handlingKernel = previusoHandlingKernel;
                }
            });
        }
        else if (kernel) {
            if (invocationContext !== null) {
                invocationContext.handlingKernel = kernel;
            }
            const kernelUri = getKernelUri(kernel);
            if (!commandEnvelope.routingSlip.contains(kernelUri)) {
                commandEnvelope.routingSlip.stampAsArrived(kernelUri);
            }
            else {
                Logger.default.warn(`Trying to stamp ${commandEnvelope.commandType} as arrived but uri ${kernelUri} is already present.`);
            }
            return kernel.handleCommand(commandEnvelope).finally(() => {
                if (invocationContext !== null) {
                    invocationContext.handlingKernel = previusoHandlingKernel;
                }
                if (!commandEnvelope.routingSlip.contains(kernelUri)) {
                    commandEnvelope.routingSlip.stamp(kernelUri);
                }
                else {
                    Logger.default.warn(`Trying to stamp ${commandEnvelope.commandType} as completed but uri ${kernelUri} is already present.`);
                }
            });
        }
        if (invocationContext !== null) {
            invocationContext.handlingKernel = previusoHandlingKernel;
        }
        return Promise.reject(new Error("Kernel not found: " + commandEnvelope.command.targetKernelName));
    }
    getHandlingKernel(commandEnvelope, context) {
        var _a, _b, _c, _d, _e;
        let kernel = null;
        if (commandEnvelope.command.destinationUri) {
            const normalized = createKernelUri(commandEnvelope.command.destinationUri);
            kernel = (_a = this._childKernels.tryGetByUri(normalized)) !== null && _a !== void 0 ? _a : null;
            if (kernel) {
                return kernel;
            }
        }
        let targetKernelName = commandEnvelope.command.targetKernelName;
        if (targetKernelName === undefined || targetKernelName === null) {
            if (this.canHandle(commandEnvelope)) {
                return this;
            }
            targetKernelName = (_b = this._defaultKernelNamesByCommandType.get(commandEnvelope.commandType)) !== null && _b !== void 0 ? _b : this.defaultKernelName;
        }
        if (targetKernelName !== undefined && targetKernelName !== null) {
            kernel = (_c = this._childKernels.tryGetByAlias(targetKernelName)) !== null && _c !== void 0 ? _c : null;
        }
        if (targetKernelName && !kernel) {
            const errorMessage = `Kernel not found: ${targetKernelName}`;
            Logger.default.error(errorMessage);
            throw new Error(errorMessage);
        }
        if (!kernel) {
            if (this._childKernels.count === 1) {
                kernel = (_d = this._childKernels.single()) !== null && _d !== void 0 ? _d : null;
            }
        }
        if (!kernel) {
            kernel = (_e = context === null || context === void 0 ? void 0 : context.handlingKernel) !== null && _e !== void 0 ? _e : null;
        }
        return kernel !== null && kernel !== void 0 ? kernel : this;
    }
}
class KernelCollection {
    constructor(compositeKernel) {
        this._kernels = [];
        this._nameAndAliasesByKernel = new Map();
        this._kernelsByNameOrAlias = new Map();
        this._kernelsByLocalUri = new Map();
        this._kernelsByRemoteUri = new Map();
        this._compositeKernel = compositeKernel;
    }
    [Symbol.iterator]() {
        let counter = 0;
        return {
            next: () => {
                return {
                    value: this._kernels[counter++],
                    done: counter > this._kernels.length
                };
            }
        };
    }
    single() {
        return this._kernels.length === 1 ? this._kernels[0] : undefined;
    }
    add(kernel, aliases) {
        if (this._kernelsByNameOrAlias.has(kernel.name)) {
            throw new Error(`kernel with name ${kernel.name} already exists`);
        }
        this.updateKernelInfoAndIndex(kernel, aliases);
        this._kernels.push(kernel);
    }
    get count() {
        return this._kernels.length;
    }
    updateKernelInfoAndIndex(kernel, aliases) {
        var _a, _b;
        if (aliases) {
            for (let alias of aliases) {
                if (this._kernelsByNameOrAlias.has(alias)) {
                    throw new Error(`kernel with alias ${alias} already exists`);
                }
            }
        }
        if (!this._nameAndAliasesByKernel.has(kernel)) {
            let set = new Set();
            for (let alias of kernel.kernelInfo.aliases) {
                set.add(alias);
            }
            kernel.kernelInfo.aliases = Array.from(set);
            set.add(kernel.kernelInfo.localName);
            this._nameAndAliasesByKernel.set(kernel, set);
        }
        if (aliases) {
            for (let alias of aliases) {
                this._nameAndAliasesByKernel.get(kernel).add(alias);
            }
        }
        (_a = this._nameAndAliasesByKernel.get(kernel)) === null || _a === void 0 ? void 0 : _a.forEach(alias => {
            this._kernelsByNameOrAlias.set(alias, kernel);
        });
        let baseUri = ((_b = this._compositeKernel.host) === null || _b === void 0 ? void 0 : _b.uri) || this._compositeKernel.kernelInfo.uri;
        if (!baseUri.endsWith("/")) {
            baseUri += "/";
        }
        kernel.kernelInfo.uri = createKernelUri(`${baseUri}${kernel.kernelInfo.localName}`);
        this._kernelsByLocalUri.set(kernel.kernelInfo.uri, kernel);
        if (kernel.kernelInfo.isProxy) {
            this._kernelsByRemoteUri.set(kernel.kernelInfo.remoteUri, kernel);
        }
    }
    tryGetByAlias(alias) {
        return this._kernelsByNameOrAlias.get(alias);
    }
    tryGetByUri(uri) {
        let kernel = this._kernelsByLocalUri.get(uri) || this._kernelsByRemoteUri.get(uri);
        return kernel;
    }
    notifyThatHostWasSet() {
        for (let kernel of this._kernels) {
            this.updateKernelInfoAndIndex(kernel);
        }
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
function isKernelCommandEnvelope(commandOrEvent) {
    return commandOrEvent.commandType !== undefined;
}
function isKernelCommandEnvelopeModel(commandOrEvent) {
    return commandOrEvent.commandType !== undefined;
}
function isKernelEventEnvelope(commandOrEvent) {
    return commandOrEvent.eventType !== undefined;
}
function isKernelEventEnvelopeModel(commandOrEvent) {
    return commandOrEvent.eventType !== undefined;
}
class KernelCommandAndEventReceiver {
    constructor(observer) {
        this._disposables = [];
        this._observable = observer;
    }
    subscribe(observer) {
        return this._observable.subscribe(observer);
    }
    dispose() {
        for (let disposable of this._disposables) {
            disposable.dispose();
        }
    }
    static FromObservable(observable) {
        return new KernelCommandAndEventReceiver(observable);
    }
    static FromEventListener(args) {
        let subject = new Subject();
        const listener = (e) => {
            let mapped = args.map(e);
            subject.next(mapped);
        };
        args.eventTarget.addEventListener(args.event, listener);
        const ret = new KernelCommandAndEventReceiver(subject);
        ret._disposables.push({
            dispose: () => {
                args.eventTarget.removeEventListener(args.event, listener);
            }
        });
        args.eventTarget.removeEventListener(args.event, listener);
        return ret;
    }
}
function isObservable(source) {
    return source.next !== undefined;
}
class KernelCommandAndEventSender {
    constructor() {
    }
    send(kernelCommandOrEventEnvelope) {
        if (this._sender) {
            try {
                const clone = kernelCommandOrEventEnvelope.clone();
                if (typeof this._sender === "function") {
                    this._sender(clone);
                }
                else if (isObservable(this._sender)) {
                    if (isKernelCommandEnvelope(kernelCommandOrEventEnvelope)) {
                        this._sender.next(clone);
                    }
                    else {
                        this._sender.next(clone);
                    }
                }
                else {
                    return Promise.reject(new Error("Sender is not set"));
                }
            }
            catch (error) {
                return Promise.reject(error);
            }
            return Promise.resolve();
        }
        return Promise.reject(new Error("Sender is not set"));
    }
    static FromObserver(observer) {
        const sender = new KernelCommandAndEventSender();
        sender._sender = observer;
        return sender;
    }
    static FromFunction(send) {
        const sender = new KernelCommandAndEventSender();
        sender._sender = send;
        return sender;
    }
}
function isSetOfString(collection) {
    return typeof (collection) !== typeof (new Set());
}
function isArrayOfString(collection) {
    return Array.isArray(collection) && collection.length > 0 && typeof (collection[0]) === typeof ("");
}
const onKernelInfoUpdates = [];
function registerForKernelInfoUpdates(callback) {
    onKernelInfoUpdates.push(callback);
}
function notifyOfKernelInfoUpdates(compositeKernel) {
    for (const updater of onKernelInfoUpdates) {
        updater(compositeKernel);
    }
}
function ensureOrUpdateProxyForKernelInfo(kernelInfo, compositeKernel) {
    if (kernelInfo.isProxy) {
        const host = extractHostAndNomalize(kernelInfo.remoteUri);
        if (host === extractHostAndNomalize(compositeKernel.kernelInfo.uri)) {
            Logger.default.warn(`skippin creation of proxy for a proxy kernel : [${JSON.stringify(kernelInfo)}]`);
            return;
        }
    }
    const uriToLookup = kernelInfo.isProxy ? kernelInfo.remoteUri : kernelInfo.uri;
    if (uriToLookup) {
        let kernel = compositeKernel.findKernelByUri(uriToLookup);
        if (!kernel) {
            // add
            if (compositeKernel.host) {
                Logger.default.info(`creating proxy for uri[${uriToLookup}]with info ${JSON.stringify(kernelInfo)}`);
                // check for clash with `kernelInfo.localName`
                kernel = compositeKernel.host.connectProxyKernel(kernelInfo.localName, uriToLookup, kernelInfo.aliases);
                updateKernelInfo(kernel.kernelInfo, kernelInfo);
            }
            else {
                throw new Error('no kernel host found');
            }
        }
        else {
            Logger.default.info(`patching proxy for uri[${uriToLookup}]with info ${JSON.stringify(kernelInfo)} `);
        }
        if (kernel.kernelInfo.isProxy) {
            // patch
            updateKernelInfo(kernel.kernelInfo, kernelInfo);
        }
        notifyOfKernelInfoUpdates(compositeKernel);
    }
}
function isKernelInfoForProxy(kernelInfo) {
    return kernelInfo.isProxy;
}
function updateKernelInfo(destination, source) {
    var _a, _b;
    destination.languageName = (_a = source.languageName) !== null && _a !== void 0 ? _a : destination.languageName;
    destination.languageVersion = (_b = source.languageVersion) !== null && _b !== void 0 ? _b : destination.languageVersion;
    destination.displayName = source.displayName;
    destination.isComposite = source.isComposite;
    if (destination.description === undefined || destination.description === null || destination.description.match(/^\s*$/)) {
        destination.description = source.description;
    }
    if (source.displayName) {
        destination.displayName = source.displayName;
    }
    const supportedCommands = new Set();
    if (!destination.supportedKernelCommands) {
        destination.supportedKernelCommands = [];
    }
    for (const supportedCommand of destination.supportedKernelCommands) {
        supportedCommands.add(supportedCommand.name);
    }
    for (const supportedCommand of source.supportedKernelCommands) {
        if (!supportedCommands.has(supportedCommand.name)) {
            supportedCommands.add(supportedCommand.name);
            destination.supportedKernelCommands.push(supportedCommand);
        }
    }
}
class Connector {
    constructor(configuration) {
        this._remoteUris = new Set();
        this._receiver = configuration.receiver;
        this._sender = configuration.sender;
        if (configuration.remoteUris) {
            for (const remoteUri of configuration.remoteUris) {
                const uri = extractHostAndNomalize(remoteUri);
                if (uri) {
                    this._remoteUris.add(uri);
                }
            }
        }
        this._listener = this._receiver.subscribe({
            next: (kernelCommandOrEventEnvelope) => {
                var _a;
                if (isKernelEventEnvelope(kernelCommandOrEventEnvelope)) {
                    if (kernelCommandOrEventEnvelope.eventType === KernelInfoProducedType) {
                        const event = kernelCommandOrEventEnvelope.event;
                        if (!event.kernelInfo.remoteUri) {
                            const uri = extractHostAndNomalize(event.kernelInfo.uri);
                            if (uri) {
                                this._remoteUris.add(uri);
                            }
                        }
                    }
                    const eventRoutingSlip = kernelCommandOrEventEnvelope.routingSlip.toArray();
                    if (((_a = eventRoutingSlip.length) !== null && _a !== void 0 ? _a : 0) > 0) {
                        const eventOrigin = eventRoutingSlip[0];
                        const uri = extractHostAndNomalize(eventOrigin);
                        if (uri) {
                            this._remoteUris.add(uri);
                        }
                    }
                }
            }
        });
    }
    get remoteHostUris() {
        return Array.from(this._remoteUris.values());
    }
    get sender() {
        return this._sender;
    }
    get receiver() {
        return this._receiver;
    }
    addRemoteHostUri(remoteUri) {
        const uri = extractHostAndNomalize(remoteUri);
        if (uri) {
            this._remoteUris.add(uri);
        }
    }
    canReach(remoteUri) {
        const host = extractHostAndNomalize(remoteUri); //?
        if (host) {
            return this._remoteUris.has(host);
        }
        return false;
    }
    dispose() {
        this._listener.unsubscribe();
    }
}
function extractHostAndNomalize(kernelUri) {
    var _a;
    const filter = /(?<host>.+:\/\/[^\/]+)(\/[^\/])*/gi;
    const match = filter.exec(kernelUri); //?
    if ((_a = match === null || match === void 0 ? void 0 : match.groups) === null || _a === void 0 ? void 0 : _a.host) {
        const host = match.groups.host;
        return host; //?
    }
    return "";
}
function Serialize(source) {
    return JSON.stringify(source, function (key, value) {
        //handling NaN, Infinity and -Infinity
        const processed = SerializeNumberLiterals(value);
        return processed;
    });
}
function SerializeNumberLiterals(value) {
    if (value !== value) {
        return "NaN";
    }
    else if (value === Infinity) {
        return "Infinity";
    }
    else if (value === -Infinity) {
        return "-Infinity";
    }
    return value;
}
function Deserialize(json) {
    return JSON.parse(json, function (key, value) {
        //handling NaN, Infinity and -Infinity
        const deserialized = DeserializeNumberLiterals(value);
        return deserialized;
    });
}
function DeserializeNumberLiterals(value) {
    if (value === "NaN") {
        return NaN;
    }
    else if (value === "Infinity") {
        return Infinity;
    }
    else if (value === "-Infinity") {
        return -Infinity;
    }
    return value;
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class ConsoleCapture {
    constructor() {
        this.originalConsole = console;
        console = this;
    }
    set kernelInvocationContext(value) {
        this._kernelInvocationContext = value;
    }
    assert(value, message, ...optionalParams) {
        this.originalConsole.assert(value, message, optionalParams);
    }
    clear() {
        this.originalConsole.clear();
    }
    count(label) {
        this.originalConsole.count(label);
    }
    countReset(label) {
        this.originalConsole.countReset(label);
    }
    debug(message, ...optionalParams) {
        this.originalConsole.debug(message, optionalParams);
    }
    dir(obj, options) {
        this.originalConsole.dir(obj, options);
    }
    dirxml(...data) {
        this.originalConsole.dirxml(data);
    }
    error(message, ...optionalParams) {
        this.redirectAndPublish(this.originalConsole.error, ...[message, ...optionalParams]);
    }
    group(...label) {
        this.originalConsole.group(label);
    }
    groupCollapsed(...label) {
        this.originalConsole.groupCollapsed(label);
    }
    groupEnd() {
        this.originalConsole.groupEnd();
    }
    info(message, ...optionalParams) {
        this.redirectAndPublish(this.originalConsole.info, ...[message, ...optionalParams]);
    }
    log(message, ...optionalParams) {
        this.redirectAndPublish(this.originalConsole.log, ...[message, ...optionalParams]);
    }
    table(tabularData, properties) {
        this.originalConsole.table(tabularData, properties);
    }
    time(label) {
        this.originalConsole.time(label);
    }
    timeEnd(label) {
        this.originalConsole.timeEnd(label);
    }
    timeLog(label, ...data) {
        this.originalConsole.timeLog(label, data);
    }
    timeStamp(label) {
        this.originalConsole.timeStamp(label);
    }
    trace(message, ...optionalParams) {
        this.redirectAndPublish(this.originalConsole.trace, ...[message, ...optionalParams]);
    }
    warn(message, ...optionalParams) {
        this.originalConsole.warn(message, optionalParams);
    }
    profile(label) {
        this.originalConsole.profile(label);
    }
    profileEnd(label) {
        this.originalConsole.profileEnd(label);
    }
    dispose() {
        console = this.originalConsole;
    }
    redirectAndPublish(target, ...args) {
        if (this._kernelInvocationContext) {
            for (const arg of args) {
                let mimeType;
                let value;
                if (typeof arg !== 'object' && !Array.isArray(arg)) {
                    mimeType = 'text/plain';
                    value = arg === null || arg === void 0 ? void 0 : arg.toString();
                }
                else {
                    mimeType = 'application/json';
                    value = Serialize(arg);
                }
                const displayedValue = {
                    formattedValues: [
                        {
                            mimeType,
                            value,
                            suppressDisplay: false
                        }
                    ]
                };
                const eventEnvelope = new KernelEventEnvelope(DisplayedValueProducedType, displayedValue, this._kernelInvocationContext.commandEnvelope);
                this._kernelInvocationContext.publish(eventEnvelope);
            }
        }
        if (target) {
            target(...args);
        }
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class ProxyKernel extends Kernel {
    constructor(name, _sender, _receiver, languageName, languageVersion) {
        super(name, languageName, languageVersion);
        this.name = name;
        this._sender = _sender;
        this._receiver = _receiver;
        this.kernelInfo.isProxy = true;
    }
    getCommandHandler(commandType) {
        return {
            commandType,
            handle: (invocation) => {
                return this._commandHandler(invocation);
            }
        };
    }
    delegatePublication(envelope, invocationContext) {
        let alreadyBeenSeen = false;
        const kernelUri = getKernelUri(this);
        if (kernelUri && !envelope.routingSlip.contains(kernelUri)) {
            envelope.routingSlip.stamp(kernelUri);
        }
        else {
            alreadyBeenSeen = true;
        }
        if (this.hasSameOrigin(envelope)) {
            if (!alreadyBeenSeen) {
                invocationContext.publish(envelope);
            }
        }
    }
    hasSameOrigin(envelope) {
        var _a, _b, _c;
        let commandOriginUri = (_c = (_b = (_a = envelope.command) === null || _a === void 0 ? void 0 : _a.command) === null || _b === void 0 ? void 0 : _b.originUri) !== null && _c !== void 0 ? _c : this.kernelInfo.uri;
        if (commandOriginUri === this.kernelInfo.uri) {
            return true;
        }
        return commandOriginUri === null;
    }
    updateKernelInfoFromEvent(kernelInfoProduced) {
        updateKernelInfo(this.kernelInfo, kernelInfoProduced.kernelInfo);
    }
    _commandHandler(commandInvocation) {
        var _a, _b;
        var _c, _d;
        return __awaiter(this, void 0, void 0, function* () {
            const commandToken = commandInvocation.commandEnvelope.getOrCreateToken();
            const completionSource = new PromiseCompletionSource();
            // fix : is this the right way? We are trying to avoid forwarding events we just did forward
            let eventSubscription = this._receiver.subscribe({
                next: (envelope) => {
                    var _a, _b, _c;
                    if (isKernelEventEnvelope(envelope)) {
                        if (envelope.eventType === KernelInfoProducedType &&
                            (envelope.command === null || envelope.command === undefined)) {
                            const kernelInfoProduced = envelope.event;
                            kernelInfoProduced.kernelInfo; //?
                            this.kernelInfo; //?
                            if (kernelInfoProduced.kernelInfo.uri === this.kernelInfo.remoteUri) {
                                this.updateKernelInfoFromEvent(kernelInfoProduced);
                                const event = new KernelEventEnvelope(KernelInfoProducedType, { kernelInfo: this.kernelInfo });
                                this.publishEvent(event);
                            }
                        }
                        else if (envelope.command.getToken() === commandToken) {
                            Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] processing event, envelopeToken=${envelope.command.getToken()}, commandToken=${commandToken}`);
                            Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] processing event, ${JSON.stringify(envelope)}`);
                            try {
                                const original = [...(_b = (_a = commandInvocation.commandEnvelope) === null || _a === void 0 ? void 0 : _a.routingSlip.toArray()) !== null && _b !== void 0 ? _b : []];
                                commandInvocation.commandEnvelope.routingSlip.continueWith(envelope.command.routingSlip);
                                //envelope.command!.routingSlip = [...commandInvocation.commandEnvelope.routingSlip ?? []];//?
                                Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, command routingSlip :${original}] has changed to: ${JSON.stringify((_c = commandInvocation.commandEnvelope.routingSlip) !== null && _c !== void 0 ? _c : [])}`);
                            }
                            catch (e) {
                                Logger.default.error(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, error ${e === null || e === void 0 ? void 0 : e.message}`);
                            }
                            switch (envelope.eventType) {
                                case KernelInfoProducedType:
                                    {
                                        const kernelInfoProduced = envelope.event;
                                        if (kernelInfoProduced.kernelInfo.uri === this.kernelInfo.remoteUri) {
                                            this.updateKernelInfoFromEvent(kernelInfoProduced);
                                            const event = new KernelEventEnvelope(KernelInfoProducedType, { kernelInfo: this.kernelInfo }, commandInvocation.commandEnvelope);
                                            event.routingSlip.continueWith(envelope.routingSlip);
                                            this.delegatePublication(event, commandInvocation.context);
                                            this.delegatePublication(envelope, commandInvocation.context);
                                        }
                                        else {
                                            this.delegatePublication(envelope, commandInvocation.context);
                                        }
                                    }
                                    break;
                                case CommandFailedType:
                                case CommandSucceededType:
                                    Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] finished, token=${envelope.command.getToken()}, commandToken=${commandToken}`);
                                    if (envelope.command.getToken() === commandToken) {
                                        Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] resolving promise, envelopeToken=${envelope.command.getToken()}, commandToken=${commandToken}`);
                                        completionSource.resolve(envelope);
                                    }
                                    else {
                                        Logger.default.info(`proxy name=${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] not resolving promise, envelopeToken=${envelope.command.getToken()}, commandToken=${commandToken}`);
                                        this.delegatePublication(envelope, commandInvocation.context);
                                    }
                                    break;
                                default:
                                    this.delegatePublication(envelope, commandInvocation.context);
                                    break;
                            }
                        }
                    }
                }
            });
            try {
                if (!commandInvocation.commandEnvelope.command.destinationUri || !commandInvocation.commandEnvelope.command.originUri) {
                    (_a = (_c = commandInvocation.commandEnvelope.command).originUri) !== null && _a !== void 0 ? _a : (_c.originUri = this.kernelInfo.uri);
                    (_b = (_d = commandInvocation.commandEnvelope.command).destinationUri) !== null && _b !== void 0 ? _b : (_d.destinationUri = this.kernelInfo.remoteUri);
                }
                commandInvocation.commandEnvelope.routingSlip; //?
                if (commandInvocation.commandEnvelope.commandType === RequestKernelInfoType) {
                    const destinationUri = this.kernelInfo.remoteUri;
                    if (commandInvocation.commandEnvelope.routingSlip.contains(destinationUri, true)) {
                        return Promise.resolve();
                    }
                }
                Logger.default.info(`proxy ${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] forwarding command ${commandInvocation.commandEnvelope.commandType} to ${commandInvocation.commandEnvelope.command.destinationUri}`);
                this._sender.send(commandInvocation.commandEnvelope);
                Logger.default.info(`proxy ${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] about to await with token ${commandToken}`);
                const enventEnvelope = yield completionSource.promise;
                if (enventEnvelope.eventType === CommandFailedType) {
                    commandInvocation.context.fail(enventEnvelope.event.message);
                }
                Logger.default.info(`proxy ${this.name}[local uri:${this.kernelInfo.uri}, remote uri:${this.kernelInfo.remoteUri}] done awaiting with token ${commandToken}}`);
            }
            catch (e) {
                commandInvocation.context.fail(e.message);
            }
            finally {
                eventSubscription.unsubscribe();
            }
        });
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class KernelHost {
    constructor(kernel, sender, receiver, hostUri) {
        this._remoteUriToKernel = new Map();
        this._uriToKernel = new Map();
        this._kernelToKernelInfo = new Map();
        this._connectors = [];
        this._kernel = kernel;
        this._uri = createKernelUri(hostUri || "kernel://vscode");
        this._kernel.host = this;
        this._scheduler = new KernelScheduler();
        this._scheduler.setMustTrampoline((c => {
            return (c.commandType === RequestInputType) || (c.commandType === SendEditableCodeType);
        }));
        this._defaultConnector = new Connector({ sender, receiver });
        this._connectors.push(this._defaultConnector);
    }
    get defaultConnector() {
        return this._defaultConnector;
    }
    get uri() {
        return this._uri;
    }
    get kernel() {
        return this._kernel;
    }
    tryGetKernelByRemoteUri(remoteUri) {
        return this._remoteUriToKernel.get(remoteUri);
    }
    trygetKernelByOriginUri(originUri) {
        return this._uriToKernel.get(originUri);
    }
    tryGetKernelInfo(kernel) {
        return this._kernelToKernelInfo.get(kernel);
    }
    addKernelInfo(kernel, kernelInfo) {
        kernelInfo.uri = createKernelUri(`${this._uri}${kernel.name}`);
        this._kernelToKernelInfo.set(kernel, kernelInfo);
        this._uriToKernel.set(kernelInfo.uri, kernel);
    }
    getKernel(kernelCommandEnvelope) {
        var _a;
        const uriToLookup = (_a = kernelCommandEnvelope.command.destinationUri) !== null && _a !== void 0 ? _a : kernelCommandEnvelope.command.originUri;
        let kernel = undefined;
        if (uriToLookup) {
            kernel = this._kernel.findKernelByUri(uriToLookup);
        }
        if (!kernel) {
            if (kernelCommandEnvelope.command.targetKernelName) {
                kernel = this._kernel.findKernelByName(kernelCommandEnvelope.command.targetKernelName);
            }
        }
        kernel !== null && kernel !== void 0 ? kernel : (kernel = this._kernel);
        Logger.default.info(`Using Kernel ${kernel.name}`);
        return kernel;
    }
    connectProxyKernelOnDefaultConnector(localName, remoteKernelUri, aliases) {
        return this.connectProxyKernelOnConnector(localName, this._defaultConnector.sender, this._defaultConnector.receiver, remoteKernelUri, aliases);
    }
    tryAddConnector(connector) {
        if (!connector.remoteUris) {
            this._connectors.push(new Connector(connector));
            return true;
        }
        else {
            const found = connector.remoteUris.find(uri => this._connectors.find(c => c.canReach(uri)));
            if (!found) {
                this._connectors.push(new Connector(connector));
                return true;
            }
            return false;
        }
    }
    tryRemoveConnector(connector) {
        if (!connector.remoteUris) {
            for (let uri of connector.remoteUris) {
                const index = this._connectors.findIndex(c => c.canReach(uri));
                if (index >= 0) {
                    this._connectors.splice(index, 1);
                }
            }
            return true;
        }
        else {
            return false;
        }
    }
    connectProxyKernel(localName, remoteKernelUri, aliases) {
        this._connectors; //?
        const connector = this._connectors.find(c => c.canReach(remoteKernelUri));
        if (!connector) {
            throw new Error(`Cannot find connector to reach ${remoteKernelUri}`);
        }
        let kernel = new ProxyKernel(localName, connector.sender, connector.receiver);
        kernel.kernelInfo.remoteUri = remoteKernelUri;
        this._kernel.add(kernel, aliases);
        return kernel;
    }
    connectProxyKernelOnConnector(localName, sender, receiver, remoteKernelUri, aliases) {
        let kernel = new ProxyKernel(localName, sender, receiver);
        kernel.kernelInfo.remoteUri = remoteKernelUri;
        this._kernel.add(kernel, aliases);
        return kernel;
    }
    tryGetConnector(remoteUri) {
        return this._connectors.find(c => c.canReach(remoteUri));
    }
    connect() {
        return __awaiter(this, void 0, void 0, function* () {
            this._kernel.subscribeToKernelEvents(e => {
                Logger.default.info(`KernelHost forwarding event: ${JSON.stringify(e)}`);
                this._defaultConnector.sender.send(e);
            });
            this._defaultConnector.receiver.subscribe({
                next: (kernelCommandOrEventEnvelope) => {
                    if (isKernelCommandEnvelope(kernelCommandOrEventEnvelope)) {
                        Logger.default.info(`KernelHost dispacthing command: ${JSON.stringify(kernelCommandOrEventEnvelope)}`);
                        this._scheduler.runAsync(kernelCommandOrEventEnvelope, commandEnvelope => {
                            const kernel = this._kernel;
                            return kernel.send(commandEnvelope);
                        });
                    }
                }
            });
            const kernelInfos = [this._kernel.kernelInfo, ...Array.from(this._kernel.childKernels.map(k => k.kernelInfo).filter(ki => ki.isProxy === false))];
            const kernekReady = {
                kernelInfos: kernelInfos
            };
            const event = new KernelEventEnvelope(KernelReadyType, kernekReady);
            event.routingSlip.stamp(this._kernel.kernelInfo.uri);
            yield this._defaultConnector.sender.send(event);
            return kernekReady;
        });
    }
    getKernelInfos() {
        let kernelInfos = [this._kernel.kernelInfo];
        for (let kernel of this._kernel.childKernels) {
            kernelInfos.push(kernel.kernelInfo);
        }
        return kernelInfos;
    }
    getKernelInfoProduced() {
        let events = Array.from(this.getKernelInfos().map(kernelInfo => {
            const event = new KernelEventEnvelope(KernelInfoProducedType, { kernelInfo: kernelInfo });
            event.routingSlip.stamp(kernelInfo.uri);
            return event;
        }));
        return events;
    }
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.

var polyglotNotebooksApi = /*#__PURE__*/Object.freeze({
    __proto__: null,
    CompositeKernel: CompositeKernel,
    isKernelCommandEnvelope: isKernelCommandEnvelope,
    isKernelCommandEnvelopeModel: isKernelCommandEnvelopeModel,
    isKernelEventEnvelope: isKernelEventEnvelope,
    isKernelEventEnvelopeModel: isKernelEventEnvelopeModel,
    KernelCommandAndEventReceiver: KernelCommandAndEventReceiver,
    KernelCommandAndEventSender: KernelCommandAndEventSender,
    isSetOfString: isSetOfString,
    isArrayOfString: isArrayOfString,
    registerForKernelInfoUpdates: registerForKernelInfoUpdates,
    ensureOrUpdateProxyForKernelInfo: ensureOrUpdateProxyForKernelInfo,
    isKernelInfoForProxy: isKernelInfoForProxy,
    updateKernelInfo: updateKernelInfo,
    Connector: Connector,
    extractHostAndNomalize: extractHostAndNomalize,
    Serialize: Serialize,
    SerializeNumberLiterals: SerializeNumberLiterals,
    Deserialize: Deserialize,
    DeserializeNumberLiterals: DeserializeNumberLiterals,
    ConsoleCapture: ConsoleCapture,
    AddPackageType: AddPackageType,
    AddPackageSourceType: AddPackageSourceType,
    CancelType: CancelType,
    CompileProjectType: CompileProjectType,
    DisplayErrorType: DisplayErrorType,
    DisplayValueType: DisplayValueType,
    ImportDocumentType: ImportDocumentType,
    OpenDocumentType: OpenDocumentType,
    OpenProjectType: OpenProjectType,
    QuitType: QuitType,
    RequestCompletionsType: RequestCompletionsType,
    RequestDiagnosticsType: RequestDiagnosticsType,
    RequestHoverTextType: RequestHoverTextType,
    RequestInputType: RequestInputType,
    RequestInputsType: RequestInputsType,
    RequestKernelInfoType: RequestKernelInfoType,
    RequestSignatureHelpType: RequestSignatureHelpType,
    RequestValueType: RequestValueType,
    RequestValueInfosType: RequestValueInfosType,
    SendEditableCodeType: SendEditableCodeType,
    SendValueType: SendValueType,
    SubmitCodeType: SubmitCodeType,
    UpdateDisplayedValueType: UpdateDisplayedValueType,
    AssemblyProducedType: AssemblyProducedType,
    CodeSubmissionReceivedType: CodeSubmissionReceivedType,
    CommandFailedType: CommandFailedType,
    CommandSucceededType: CommandSucceededType,
    CompleteCodeSubmissionReceivedType: CompleteCodeSubmissionReceivedType,
    CompletionsProducedType: CompletionsProducedType,
    DiagnosticsProducedType: DiagnosticsProducedType,
    DisplayedValueProducedType: DisplayedValueProducedType,
    DisplayedValueUpdatedType: DisplayedValueUpdatedType,
    DocumentOpenedType: DocumentOpenedType,
    ErrorProducedType: ErrorProducedType,
    HoverTextProducedType: HoverTextProducedType,
    IncompleteCodeSubmissionReceivedType: IncompleteCodeSubmissionReceivedType,
    InputProducedType: InputProducedType,
    InputsProducedType: InputsProducedType,
    KernelExtensionLoadedType: KernelExtensionLoadedType,
    KernelInfoProducedType: KernelInfoProducedType,
    KernelReadyType: KernelReadyType,
    PackageAddedType: PackageAddedType,
    ProjectOpenedType: ProjectOpenedType,
    ReturnValueProducedType: ReturnValueProducedType,
    SignatureHelpProducedType: SignatureHelpProducedType,
    StandardErrorValueProducedType: StandardErrorValueProducedType,
    StandardOutputValueProducedType: StandardOutputValueProducedType,
    ValueInfosProducedType: ValueInfosProducedType,
    ValueProducedType: ValueProducedType,
    get InsertTextFormat () { return InsertTextFormat; },
    get DiagnosticSeverity () { return DiagnosticSeverity; },
    get DocumentSerializationType () { return DocumentSerializationType; },
    get RequestType () { return RequestType; },
    KernelCommandEnvelope: KernelCommandEnvelope,
    KernelEventEnvelope: KernelEventEnvelope,
    Kernel: Kernel,
    submitCommandAndGetResult: submitCommandAndGetResult,
    getKernelUri: getKernelUri,
    KernelHost: KernelHost,
    KernelInvocationContext: KernelInvocationContext,
    KernelScheduler: KernelScheduler,
    get LogLevel () { return LogLevel; },
    Logger: Logger,
    isPromiseCompletionSource: isPromiseCompletionSource,
    PromiseCompletionSource: PromiseCompletionSource,
    ProxyKernel: ProxyKernel,
    createKernelUri: createKernelUri,
    createKernelUriWithQuery: createKernelUriWithQuery,
    getTag: getTag,
    createRoutingSlip: createRoutingSlip,
    RoutingSlip: RoutingSlip,
    CommandRoutingSlip: CommandRoutingSlip,
    EventRoutingSlip: EventRoutingSlip
});

// Copyright (c) .NET Foundation and contributors. All rights reserved.
class JavascriptKernel extends Kernel {
    constructor(name) {
        super(name !== null && name !== void 0 ? name : "javascript", "JavaScript");
        this.kernelInfo.displayName = `${this.kernelInfo.localName} - ${this.kernelInfo.languageName}`;
        this.kernelInfo.description = `Run JavaScript code`;
        this.suppressedLocals = new Set(this.allLocalVariableNames());
        this.registerCommandHandler({ commandType: SubmitCodeType, handle: invocation => this.handleSubmitCode(invocation) });
        this.registerCommandHandler({ commandType: RequestValueInfosType, handle: invocation => this.handleRequestValueInfos(invocation) });
        this.registerCommandHandler({ commandType: RequestValueType, handle: invocation => this.handleRequestValue(invocation) });
        this.registerCommandHandler({ commandType: SendValueType, handle: invocation => this.handleSendValue(invocation) });
        this.capture = new ConsoleCapture();
    }
    handleSendValue(invocation) {
        const sendValue = invocation.commandEnvelope.command;
        if (sendValue.formattedValue) {
            switch (sendValue.formattedValue.mimeType) {
                case 'application/json':
                    globalThis[sendValue.name] = Deserialize(sendValue.formattedValue.value);
                    break;
                default:
                    globalThis[sendValue.name] = sendValue.formattedValue.value;
                    break;
            }
            return Promise.resolve();
        }
        throw new Error("formattedValue is required");
    }
    handleSubmitCode(invocation) {
        const _super = Object.create(null, {
            kernelInfo: { get: () => super.kernelInfo }
        });
        return __awaiter(this, void 0, void 0, function* () {
            const submitCode = invocation.commandEnvelope.command;
            const code = submitCode.code;
            _super.kernelInfo.localName; //?
            _super.kernelInfo.uri; //?
            _super.kernelInfo.remoteUri; //?
            const codeSubmissionReceivedEvent = new KernelEventEnvelope(CodeSubmissionReceivedType, { code }, invocation.commandEnvelope);
            invocation.context.publish(codeSubmissionReceivedEvent);
            invocation.context.commandEnvelope.routingSlip; //?
            this.capture.kernelInvocationContext = invocation.context;
            let result = undefined;
            try {
                const AsyncFunction = eval(`Object.getPrototypeOf(async function(){}).constructor`);
                const evaluator = AsyncFunction("console", "polyglotNotebooks", code);
                result = yield evaluator(this.capture, polyglotNotebooksApi);
                if (result !== undefined) {
                    const formattedValue = formatValue(result, 'application/json');
                    const event = {
                        formattedValues: [formattedValue]
                    };
                    const returnValueProducedEvent = new KernelEventEnvelope(ReturnValueProducedType, event, invocation.commandEnvelope);
                    invocation.context.publish(returnValueProducedEvent);
                }
            }
            catch (e) {
                throw e; //?
            }
            finally {
                this.capture.kernelInvocationContext = undefined;
            }
        });
    }
    handleRequestValueInfos(invocation) {
        const valueInfos = [];
        this.allLocalVariableNames().filter(v => !this.suppressedLocals.has(v)).forEach(v => {
            const variableValue = this.getLocalVariable(v);
            try {
                const valueInfo = {
                    name: v,
                    typeName: getType(variableValue),
                    formattedValue: formatValue(variableValue, "text/plain"),
                    preferredMimeTypes: []
                };
                valueInfos.push(valueInfo);
            }
            catch (e) {
                Logger.default.error(`error formatting value ${v} : ${e}`);
            }
        });
        const event = {
            valueInfos
        };
        const valueInfosProducedEvent = new KernelEventEnvelope(ValueInfosProducedType, event, invocation.commandEnvelope);
        invocation.context.publish(valueInfosProducedEvent);
        return Promise.resolve();
    }
    handleRequestValue(invocation) {
        const requestValue = invocation.commandEnvelope.command;
        const rawValue = this.getLocalVariable(requestValue.name);
        const formattedValue = formatValue(rawValue, requestValue.mimeType || 'application/json');
        Logger.default.info(`returning ${JSON.stringify(formattedValue)} for ${requestValue.name}`);
        const event = {
            name: requestValue.name,
            formattedValue
        };
        const valueProducedEvent = new KernelEventEnvelope(ValueProducedType, event, invocation.commandEnvelope);
        invocation.context.publish(valueProducedEvent);
        return Promise.resolve();
    }
    allLocalVariableNames() {
        const result = [];
        try {
            for (const key in globalThis) {
                try {
                    if (typeof globalThis[key] !== 'function') {
                        result.push(key);
                    }
                }
                catch (e) {
                    Logger.default.error(`error getting value for ${key} : ${e}`);
                }
            }
        }
        catch (e) {
            Logger.default.error(`error scanning globla variables : ${e}`);
        }
        return result;
    }
    getLocalVariable(name) {
        return globalThis[name];
    }
}
function formatValue(arg, mimeType) {
    let value;
    switch (mimeType) {
        case 'text/plain':
            value = (arg === null || arg === void 0 ? void 0 : arg.toString()) || 'undefined';
            if (Array.isArray(arg)) {
                value = `[${value}]`;
            }
            break;
        case 'application/json':
            value = Serialize(arg);
            break;
        default:
            throw new Error(`unsupported mime type: ${mimeType}`);
    }
    return {
        mimeType,
        value,
        suppressDisplay: false
    };
}
function getType(arg) {
    let type = arg ? typeof (arg) : ""; //?
    if (Array.isArray(arg)) {
        type = `${typeof (arg[0])}[]`; //?
    }
    if (arg === Infinity || arg === -Infinity || (arg !== arg)) {
        type = "number";
    }
    return type; //?
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
function createHost(global, compositeKernelName, configureRequire, logMessage, localToRemote, remoteToLocal, onReady) {
    Logger.configure(compositeKernelName, logMessage);
    global.interactive = {};
    configureRequire(global.interactive);
    const compositeKernel = new CompositeKernel(compositeKernelName);
    const kernelHost = new KernelHost(compositeKernel, KernelCommandAndEventSender.FromObserver(localToRemote), KernelCommandAndEventReceiver.FromObservable(remoteToLocal), `kernel://${compositeKernelName}`);
    kernelHost.defaultConnector.receiver.subscribe({
        next: (envelope) => {
            if (isKernelEventEnvelope(envelope) && envelope.eventType === KernelInfoProducedType) {
                const kernelInfoProduced = envelope.event;
                ensureOrUpdateProxyForKernelInfo(kernelInfoProduced.kernelInfo, compositeKernel);
            }
        }
    });
    // use composite kernel as root
    global.kernel = {
        get root() {
            return compositeKernel;
        }
    };
    global.sendSendValueCommand = (form) => {
        let formValues = {};
        for (var i = 0; i < form.elements.length; i++) {
            var e = form.elements[i];
            if (e.name && e.name !== '') {
                let name = e.name.replace('-', '');
                formValues[name] = e.value;
            }
        }
        let command = {
            formattedValue: {
                mimeType: 'application/json',
                value: JSON.stringify(formValues)
            },
            name: form.id,
            targetKernelName: '.NET'
        };
        let envelope = new KernelCommandEnvelope(SendValueType, command);
        form.remove();
        compositeKernel.send(envelope);
    };
    global[compositeKernelName] = {
        compositeKernel,
        kernelHost,
    };
    const jsKernel = new JavascriptKernel();
    compositeKernel.add(jsKernel, ["js"]);
    kernelHost.connect();
    onReady();
}

// Copyright (c) .NET Foundation and contributors. All rights reserved.
function activate(context) {
    configure(window, context);
    Logger.default.info(`set up 'webview' host module complete`);
}
function configure(global, context) {
    if (!global) {
        global = window;
    }
    const remoteToLocal = new Subject();
    const localToRemote = new Subject();
    localToRemote.subscribe({
        next: envelope => {
            const envelopeJson = envelope.toJson();
            context.postKernelMessage({ envelope: envelopeJson });
        }
    });
    const webViewId = v4();
    context.onDidReceiveKernelMessage((arg) => {
        var _a;
        if (arg.envelope && arg.webViewId === webViewId) {
            const envelope = (arg.envelope);
            if (isKernelEventEnvelopeModel(envelope)) {
                Logger.default.info(`channel got ${envelope.eventType} with token ${(_a = envelope.command) === null || _a === void 0 ? void 0 : _a.token}`);
                const event = KernelEventEnvelope.fromJson(envelope);
                remoteToLocal.next(event);
            }
            else {
                const command = KernelCommandEnvelope.fromJson(envelope);
                remoteToLocal.next(command);
            }
        }
        else if (arg.webViewId === webViewId) {
            const kernelHost = (global['webview'].kernelHost);
            if (kernelHost) {
                switch (arg.preloadCommand) {
                    case '#!connect': {
                        Logger.default.info(`connecting to kernels from extension host`);
                        const kernelInfos = (arg.kernelInfos);
                        for (const kernelInfo of kernelInfos) {
                            const remoteUri = kernelInfo.isProxy ? kernelInfo.remoteUri : kernelInfo.uri;
                            if (!kernelHost.tryGetConnector(remoteUri)) {
                                kernelHost.defaultConnector.addRemoteHostUri(remoteUri);
                            }
                            ensureOrUpdateProxyForKernelInfo(kernelInfo, kernelHost.kernel);
                        }
                    }
                }
            }
        }
    });
    createHost(global, 'webview', configureRequire, entry => {
        context.postKernelMessage({ logEntry: entry });
    }, localToRemote, remoteToLocal, () => {
        const kernelInfos = (global['webview'].kernelHost).getKernelInfos();
        const hostUri = (global['webview'].kernelHost).uri;
        context.postKernelMessage({ preloadCommand: '#!connect', kernelInfos, hostUri, webViewId });
    });
}
function configureRequire(interactive) {
    if ((typeof (require) !== typeof (Function)) || (typeof (require.config) !== typeof (Function))) {
        let require_script = document.createElement('script');
        require_script.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.6/require.min.js');
        require_script.setAttribute('type', 'text/javascript');
        require_script.onload = function () {
            interactive.configureRequire = (confing) => {
                return require.config(confing) || require;
            };
        };
        document.getElementsByTagName('head')[0].appendChild(require_script);
    }
    else {
        interactive.configureRequire = (confing) => {
            return require.config(confing) || require;
        };
    }
}

export { activate };
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYWN0aXZhdGlvbi5qcyIsInNvdXJjZXMiOlsiLi4vbm9kZV9tb2R1bGVzL3ZzY29kZS11cmkvbGliL2VzbS9pbmRleC5qcyIsIi4uL3NyYy9yb3V0aW5nc2xpcC50cyIsIi4uL3NyYy9jb250cmFjdHMudHMiLCIuLi9ub2RlX21vZHVsZXMvdXVpZC9kaXN0L2VzbS1icm93c2VyL3JuZy5qcyIsIi4uL25vZGVfbW9kdWxlcy91dWlkL2Rpc3QvZXNtLWJyb3dzZXIvcmVnZXguanMiLCIuLi9ub2RlX21vZHVsZXMvdXVpZC9kaXN0L2VzbS1icm93c2VyL3ZhbGlkYXRlLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3V1aWQvZGlzdC9lc20tYnJvd3Nlci9zdHJpbmdpZnkuanMiLCIuLi9ub2RlX21vZHVsZXMvdXVpZC9kaXN0L2VzbS1icm93c2VyL3BhcnNlLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3V1aWQvZGlzdC9lc20tYnJvd3Nlci92NC5qcyIsIi4uL3NyYy9jb21tYW5kc0FuZEV2ZW50cy50cyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC91dGlsL2lzRnVuY3Rpb24uanMiLCIuLi9ub2RlX21vZHVsZXMvcnhqcy9kaXN0L2VzbTUvaW50ZXJuYWwvdXRpbC9jcmVhdGVFcnJvckNsYXNzLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3J4anMvZGlzdC9lc201L2ludGVybmFsL3V0aWwvVW5zdWJzY3JpcHRpb25FcnJvci5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC91dGlsL2FyclJlbW92ZS5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC9TdWJzY3JpcHRpb24uanMiLCIuLi9ub2RlX21vZHVsZXMvcnhqcy9kaXN0L2VzbTUvaW50ZXJuYWwvY29uZmlnLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3J4anMvZGlzdC9lc201L2ludGVybmFsL3NjaGVkdWxlci90aW1lb3V0UHJvdmlkZXIuanMiLCIuLi9ub2RlX21vZHVsZXMvcnhqcy9kaXN0L2VzbTUvaW50ZXJuYWwvdXRpbC9yZXBvcnRVbmhhbmRsZWRFcnJvci5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC91dGlsL25vb3AuanMiLCIuLi9ub2RlX21vZHVsZXMvcnhqcy9kaXN0L2VzbTUvaW50ZXJuYWwvdXRpbC9lcnJvckNvbnRleHQuanMiLCIuLi9ub2RlX21vZHVsZXMvcnhqcy9kaXN0L2VzbTUvaW50ZXJuYWwvU3Vic2NyaWJlci5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC9zeW1ib2wvb2JzZXJ2YWJsZS5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC91dGlsL2lkZW50aXR5LmpzIiwiLi4vbm9kZV9tb2R1bGVzL3J4anMvZGlzdC9lc201L2ludGVybmFsL3V0aWwvcGlwZS5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC9PYnNlcnZhYmxlLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3J4anMvZGlzdC9lc201L2ludGVybmFsL3V0aWwvbGlmdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC9vcGVyYXRvcnMvT3BlcmF0b3JTdWJzY3JpYmVyLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3J4anMvZGlzdC9lc201L2ludGVybmFsL3V0aWwvT2JqZWN0VW5zdWJzY3JpYmVkRXJyb3IuanMiLCIuLi9ub2RlX21vZHVsZXMvcnhqcy9kaXN0L2VzbTUvaW50ZXJuYWwvU3ViamVjdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9yeGpzL2Rpc3QvZXNtNS9pbnRlcm5hbC9vcGVyYXRvcnMvbWFwLmpzIiwiLi4vc3JjL3Byb21pc2VDb21wbGV0aW9uU291cmNlLnRzIiwiLi4vc3JjL2tlcm5lbEludm9jYXRpb25Db250ZXh0LnRzIiwiLi4vc3JjL2xvZ2dlci50cyIsIi4uL3NyYy9rZXJuZWxTY2hlZHVsZXIudHMiLCIuLi9zcmMva2VybmVsLnRzIiwiLi4vc3JjL2NvbXBvc2l0ZUtlcm5lbC50cyIsIi4uL3NyYy9jb25uZWN0aW9uLnRzIiwiLi4vc3JjL2NvbnNvbGVDYXB0dXJlLnRzIiwiLi4vc3JjL3Byb3h5S2VybmVsLnRzIiwiLi4vc3JjL2tlcm5lbEhvc3QudHMiLCIuLi9zcmMvYXBpLnRzIiwiLi4vc3JjL2phdmFzY3JpcHRLZXJuZWwudHMiLCIuLi9zcmMvd2Vidmlldy9mcm9udEVuZEhvc3QudHMiLCIuLi9zcmMvd2Vidmlldy9hY3RpdmF0aW9uLnRzIl0sInNvdXJjZXNDb250ZW50IjpbInZhciBMSUI7KCgpPT57XCJ1c2Ugc3RyaWN0XCI7dmFyIHQ9ezQ3MDp0PT57ZnVuY3Rpb24gZSh0KXtpZihcInN0cmluZ1wiIT10eXBlb2YgdCl0aHJvdyBuZXcgVHlwZUVycm9yKFwiUGF0aCBtdXN0IGJlIGEgc3RyaW5nLiBSZWNlaXZlZCBcIitKU09OLnN0cmluZ2lmeSh0KSl9ZnVuY3Rpb24gcih0LGUpe2Zvcih2YXIgcixuPVwiXCIsbz0wLGk9LTEsYT0wLGg9MDtoPD10Lmxlbmd0aDsrK2gpe2lmKGg8dC5sZW5ndGgpcj10LmNoYXJDb2RlQXQoaCk7ZWxzZXtpZig0Nz09PXIpYnJlYWs7cj00N31pZig0Nz09PXIpe2lmKGk9PT1oLTF8fDE9PT1hKTtlbHNlIGlmKGkhPT1oLTEmJjI9PT1hKXtpZihuLmxlbmd0aDwyfHwyIT09b3x8NDYhPT1uLmNoYXJDb2RlQXQobi5sZW5ndGgtMSl8fDQ2IT09bi5jaGFyQ29kZUF0KG4ubGVuZ3RoLTIpKWlmKG4ubGVuZ3RoPjIpe3ZhciBzPW4ubGFzdEluZGV4T2YoXCIvXCIpO2lmKHMhPT1uLmxlbmd0aC0xKXstMT09PXM/KG49XCJcIixvPTApOm89KG49bi5zbGljZSgwLHMpKS5sZW5ndGgtMS1uLmxhc3RJbmRleE9mKFwiL1wiKSxpPWgsYT0wO2NvbnRpbnVlfX1lbHNlIGlmKDI9PT1uLmxlbmd0aHx8MT09PW4ubGVuZ3RoKXtuPVwiXCIsbz0wLGk9aCxhPTA7Y29udGludWV9ZSYmKG4ubGVuZ3RoPjA/bis9XCIvLi5cIjpuPVwiLi5cIixvPTIpfWVsc2Ugbi5sZW5ndGg+MD9uKz1cIi9cIit0LnNsaWNlKGkrMSxoKTpuPXQuc2xpY2UoaSsxLGgpLG89aC1pLTE7aT1oLGE9MH1lbHNlIDQ2PT09ciYmLTEhPT1hPysrYTphPS0xfXJldHVybiBufXZhciBuPXtyZXNvbHZlOmZ1bmN0aW9uKCl7Zm9yKHZhciB0LG49XCJcIixvPSExLGk9YXJndW1lbnRzLmxlbmd0aC0xO2k+PS0xJiYhbztpLS0pe3ZhciBhO2k+PTA/YT1hcmd1bWVudHNbaV06KHZvaWQgMD09PXQmJih0PXByb2Nlc3MuY3dkKCkpLGE9dCksZShhKSwwIT09YS5sZW5ndGgmJihuPWErXCIvXCIrbixvPTQ3PT09YS5jaGFyQ29kZUF0KDApKX1yZXR1cm4gbj1yKG4sIW8pLG8/bi5sZW5ndGg+MD9cIi9cIituOlwiL1wiOm4ubGVuZ3RoPjA/bjpcIi5cIn0sbm9ybWFsaXplOmZ1bmN0aW9uKHQpe2lmKGUodCksMD09PXQubGVuZ3RoKXJldHVyblwiLlwiO3ZhciBuPTQ3PT09dC5jaGFyQ29kZUF0KDApLG89NDc9PT10LmNoYXJDb2RlQXQodC5sZW5ndGgtMSk7cmV0dXJuIDAhPT0odD1yKHQsIW4pKS5sZW5ndGh8fG58fCh0PVwiLlwiKSx0Lmxlbmd0aD4wJiZvJiYodCs9XCIvXCIpLG4/XCIvXCIrdDp0fSxpc0Fic29sdXRlOmZ1bmN0aW9uKHQpe3JldHVybiBlKHQpLHQubGVuZ3RoPjAmJjQ3PT09dC5jaGFyQ29kZUF0KDApfSxqb2luOmZ1bmN0aW9uKCl7aWYoMD09PWFyZ3VtZW50cy5sZW5ndGgpcmV0dXJuXCIuXCI7Zm9yKHZhciB0LHI9MDtyPGFyZ3VtZW50cy5sZW5ndGg7KytyKXt2YXIgbz1hcmd1bWVudHNbcl07ZShvKSxvLmxlbmd0aD4wJiYodm9pZCAwPT09dD90PW86dCs9XCIvXCIrbyl9cmV0dXJuIHZvaWQgMD09PXQ/XCIuXCI6bi5ub3JtYWxpemUodCl9LHJlbGF0aXZlOmZ1bmN0aW9uKHQscil7aWYoZSh0KSxlKHIpLHQ9PT1yKXJldHVyblwiXCI7aWYoKHQ9bi5yZXNvbHZlKHQpKT09PShyPW4ucmVzb2x2ZShyKSkpcmV0dXJuXCJcIjtmb3IodmFyIG89MTtvPHQubGVuZ3RoJiY0Nz09PXQuY2hhckNvZGVBdChvKTsrK28pO2Zvcih2YXIgaT10Lmxlbmd0aCxhPWktbyxoPTE7aDxyLmxlbmd0aCYmNDc9PT1yLmNoYXJDb2RlQXQoaCk7KytoKTtmb3IodmFyIHM9ci5sZW5ndGgtaCxjPWE8cz9hOnMsZj0tMSx1PTA7dTw9YzsrK3Upe2lmKHU9PT1jKXtpZihzPmMpe2lmKDQ3PT09ci5jaGFyQ29kZUF0KGgrdSkpcmV0dXJuIHIuc2xpY2UoaCt1KzEpO2lmKDA9PT11KXJldHVybiByLnNsaWNlKGgrdSl9ZWxzZSBhPmMmJig0Nz09PXQuY2hhckNvZGVBdChvK3UpP2Y9dTowPT09dSYmKGY9MCkpO2JyZWFrfXZhciBsPXQuY2hhckNvZGVBdChvK3UpO2lmKGwhPT1yLmNoYXJDb2RlQXQoaCt1KSlicmVhazs0Nz09PWwmJihmPXUpfXZhciBwPVwiXCI7Zm9yKHU9bytmKzE7dTw9aTsrK3UpdSE9PWkmJjQ3IT09dC5jaGFyQ29kZUF0KHUpfHwoMD09PXAubGVuZ3RoP3ArPVwiLi5cIjpwKz1cIi8uLlwiKTtyZXR1cm4gcC5sZW5ndGg+MD9wK3Iuc2xpY2UoaCtmKTooaCs9Ziw0Nz09PXIuY2hhckNvZGVBdChoKSYmKytoLHIuc2xpY2UoaCkpfSxfbWFrZUxvbmc6ZnVuY3Rpb24odCl7cmV0dXJuIHR9LGRpcm5hbWU6ZnVuY3Rpb24odCl7aWYoZSh0KSwwPT09dC5sZW5ndGgpcmV0dXJuXCIuXCI7Zm9yKHZhciByPXQuY2hhckNvZGVBdCgwKSxuPTQ3PT09cixvPS0xLGk9ITAsYT10Lmxlbmd0aC0xO2E+PTE7LS1hKWlmKDQ3PT09KHI9dC5jaGFyQ29kZUF0KGEpKSl7aWYoIWkpe289YTticmVha319ZWxzZSBpPSExO3JldHVybi0xPT09bz9uP1wiL1wiOlwiLlwiOm4mJjE9PT1vP1wiLy9cIjp0LnNsaWNlKDAsbyl9LGJhc2VuYW1lOmZ1bmN0aW9uKHQscil7aWYodm9pZCAwIT09ciYmXCJzdHJpbmdcIiE9dHlwZW9mIHIpdGhyb3cgbmV3IFR5cGVFcnJvcignXCJleHRcIiBhcmd1bWVudCBtdXN0IGJlIGEgc3RyaW5nJyk7ZSh0KTt2YXIgbixvPTAsaT0tMSxhPSEwO2lmKHZvaWQgMCE9PXImJnIubGVuZ3RoPjAmJnIubGVuZ3RoPD10Lmxlbmd0aCl7aWYoci5sZW5ndGg9PT10Lmxlbmd0aCYmcj09PXQpcmV0dXJuXCJcIjt2YXIgaD1yLmxlbmd0aC0xLHM9LTE7Zm9yKG49dC5sZW5ndGgtMTtuPj0wOy0tbil7dmFyIGM9dC5jaGFyQ29kZUF0KG4pO2lmKDQ3PT09Yyl7aWYoIWEpe289bisxO2JyZWFrfX1lbHNlLTE9PT1zJiYoYT0hMSxzPW4rMSksaD49MCYmKGM9PT1yLmNoYXJDb2RlQXQoaCk/LTE9PS0taCYmKGk9bik6KGg9LTEsaT1zKSl9cmV0dXJuIG89PT1pP2k9czotMT09PWkmJihpPXQubGVuZ3RoKSx0LnNsaWNlKG8saSl9Zm9yKG49dC5sZW5ndGgtMTtuPj0wOy0tbilpZig0Nz09PXQuY2hhckNvZGVBdChuKSl7aWYoIWEpe289bisxO2JyZWFrfX1lbHNlLTE9PT1pJiYoYT0hMSxpPW4rMSk7cmV0dXJuLTE9PT1pP1wiXCI6dC5zbGljZShvLGkpfSxleHRuYW1lOmZ1bmN0aW9uKHQpe2UodCk7Zm9yKHZhciByPS0xLG49MCxvPS0xLGk9ITAsYT0wLGg9dC5sZW5ndGgtMTtoPj0wOy0taCl7dmFyIHM9dC5jaGFyQ29kZUF0KGgpO2lmKDQ3IT09cyktMT09PW8mJihpPSExLG89aCsxKSw0Nj09PXM/LTE9PT1yP3I9aDoxIT09YSYmKGE9MSk6LTEhPT1yJiYoYT0tMSk7ZWxzZSBpZighaSl7bj1oKzE7YnJlYWt9fXJldHVybi0xPT09cnx8LTE9PT1vfHwwPT09YXx8MT09PWEmJnI9PT1vLTEmJnI9PT1uKzE/XCJcIjp0LnNsaWNlKHIsbyl9LGZvcm1hdDpmdW5jdGlvbih0KXtpZihudWxsPT09dHx8XCJvYmplY3RcIiE9dHlwZW9mIHQpdGhyb3cgbmV3IFR5cGVFcnJvcignVGhlIFwicGF0aE9iamVjdFwiIGFyZ3VtZW50IG11c3QgYmUgb2YgdHlwZSBPYmplY3QuIFJlY2VpdmVkIHR5cGUgJyt0eXBlb2YgdCk7cmV0dXJuIGZ1bmN0aW9uKHQsZSl7dmFyIHI9ZS5kaXJ8fGUucm9vdCxuPWUuYmFzZXx8KGUubmFtZXx8XCJcIikrKGUuZXh0fHxcIlwiKTtyZXR1cm4gcj9yPT09ZS5yb290P3IrbjpyK1wiL1wiK246bn0oMCx0KX0scGFyc2U6ZnVuY3Rpb24odCl7ZSh0KTt2YXIgcj17cm9vdDpcIlwiLGRpcjpcIlwiLGJhc2U6XCJcIixleHQ6XCJcIixuYW1lOlwiXCJ9O2lmKDA9PT10Lmxlbmd0aClyZXR1cm4gcjt2YXIgbixvPXQuY2hhckNvZGVBdCgwKSxpPTQ3PT09bztpPyhyLnJvb3Q9XCIvXCIsbj0xKTpuPTA7Zm9yKHZhciBhPS0xLGg9MCxzPS0xLGM9ITAsZj10Lmxlbmd0aC0xLHU9MDtmPj1uOy0tZilpZig0NyE9PShvPXQuY2hhckNvZGVBdChmKSkpLTE9PT1zJiYoYz0hMSxzPWYrMSksNDY9PT1vPy0xPT09YT9hPWY6MSE9PXUmJih1PTEpOi0xIT09YSYmKHU9LTEpO2Vsc2UgaWYoIWMpe2g9ZisxO2JyZWFrfXJldHVybi0xPT09YXx8LTE9PT1zfHwwPT09dXx8MT09PXUmJmE9PT1zLTEmJmE9PT1oKzE/LTEhPT1zJiYoci5iYXNlPXIubmFtZT0wPT09aCYmaT90LnNsaWNlKDEscyk6dC5zbGljZShoLHMpKTooMD09PWgmJmk/KHIubmFtZT10LnNsaWNlKDEsYSksci5iYXNlPXQuc2xpY2UoMSxzKSk6KHIubmFtZT10LnNsaWNlKGgsYSksci5iYXNlPXQuc2xpY2UoaCxzKSksci5leHQ9dC5zbGljZShhLHMpKSxoPjA/ci5kaXI9dC5zbGljZSgwLGgtMSk6aSYmKHIuZGlyPVwiL1wiKSxyfSxzZXA6XCIvXCIsZGVsaW1pdGVyOlwiOlwiLHdpbjMyOm51bGwscG9zaXg6bnVsbH07bi5wb3NpeD1uLHQuZXhwb3J0cz1ufX0sZT17fTtmdW5jdGlvbiByKG4pe3ZhciBvPWVbbl07aWYodm9pZCAwIT09bylyZXR1cm4gby5leHBvcnRzO3ZhciBpPWVbbl09e2V4cG9ydHM6e319O3JldHVybiB0W25dKGksaS5leHBvcnRzLHIpLGkuZXhwb3J0c31yLmQ9KHQsZSk9Pntmb3IodmFyIG4gaW4gZSlyLm8oZSxuKSYmIXIubyh0LG4pJiZPYmplY3QuZGVmaW5lUHJvcGVydHkodCxuLHtlbnVtZXJhYmxlOiEwLGdldDplW25dfSl9LHIubz0odCxlKT0+T2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKHQsZSksci5yPXQ9PntcInVuZGVmaW5lZFwiIT10eXBlb2YgU3ltYm9sJiZTeW1ib2wudG9TdHJpbmdUYWcmJk9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0LFN5bWJvbC50b1N0cmluZ1RhZyx7dmFsdWU6XCJNb2R1bGVcIn0pLE9iamVjdC5kZWZpbmVQcm9wZXJ0eSh0LFwiX19lc01vZHVsZVwiLHt2YWx1ZTohMH0pfTt2YXIgbj17fTsoKCk9Pnt2YXIgdDtpZihyLnIobiksci5kKG4se1VSSTooKT0+cCxVdGlsczooKT0+X30pLFwib2JqZWN0XCI9PXR5cGVvZiBwcm9jZXNzKXQ9XCJ3aW4zMlwiPT09cHJvY2Vzcy5wbGF0Zm9ybTtlbHNlIGlmKFwib2JqZWN0XCI9PXR5cGVvZiBuYXZpZ2F0b3Ipe3ZhciBlPW5hdmlnYXRvci51c2VyQWdlbnQ7dD1lLmluZGV4T2YoXCJXaW5kb3dzXCIpPj0wfXZhciBvLGksYT0obz1mdW5jdGlvbih0LGUpe3JldHVybiBvPU9iamVjdC5zZXRQcm90b3R5cGVPZnx8e19fcHJvdG9fXzpbXX1pbnN0YW5jZW9mIEFycmF5JiZmdW5jdGlvbih0LGUpe3QuX19wcm90b19fPWV9fHxmdW5jdGlvbih0LGUpe2Zvcih2YXIgciBpbiBlKU9iamVjdC5wcm90b3R5cGUuaGFzT3duUHJvcGVydHkuY2FsbChlLHIpJiYodFtyXT1lW3JdKX0sbyh0LGUpfSxmdW5jdGlvbih0LGUpe2lmKFwiZnVuY3Rpb25cIiE9dHlwZW9mIGUmJm51bGwhPT1lKXRocm93IG5ldyBUeXBlRXJyb3IoXCJDbGFzcyBleHRlbmRzIHZhbHVlIFwiK1N0cmluZyhlKStcIiBpcyBub3QgYSBjb25zdHJ1Y3RvciBvciBudWxsXCIpO2Z1bmN0aW9uIHIoKXt0aGlzLmNvbnN0cnVjdG9yPXR9byh0LGUpLHQucHJvdG90eXBlPW51bGw9PT1lP09iamVjdC5jcmVhdGUoZSk6KHIucHJvdG90eXBlPWUucHJvdG90eXBlLG5ldyByKX0pLGg9L15cXHdbXFx3XFxkKy4tXSokLyxzPS9eXFwvLyxjPS9eXFwvXFwvLyxmPVwiXCIsdT1cIi9cIixsPS9eKChbXjovPyNdKz8pOik/KFxcL1xcLyhbXi8/I10qKSk/KFtePyNdKikoXFw/KFteI10qKSk/KCMoLiopKT8vLHA9ZnVuY3Rpb24oKXtmdW5jdGlvbiBlKHQsZSxyLG4sbyxpKXt2b2lkIDA9PT1pJiYoaT0hMSksXCJvYmplY3RcIj09dHlwZW9mIHQ/KHRoaXMuc2NoZW1lPXQuc2NoZW1lfHxmLHRoaXMuYXV0aG9yaXR5PXQuYXV0aG9yaXR5fHxmLHRoaXMucGF0aD10LnBhdGh8fGYsdGhpcy5xdWVyeT10LnF1ZXJ5fHxmLHRoaXMuZnJhZ21lbnQ9dC5mcmFnbWVudHx8Zik6KHRoaXMuc2NoZW1lPWZ1bmN0aW9uKHQsZSl7cmV0dXJuIHR8fGU/dDpcImZpbGVcIn0odCxpKSx0aGlzLmF1dGhvcml0eT1lfHxmLHRoaXMucGF0aD1mdW5jdGlvbih0LGUpe3N3aXRjaCh0KXtjYXNlXCJodHRwc1wiOmNhc2VcImh0dHBcIjpjYXNlXCJmaWxlXCI6ZT9lWzBdIT09dSYmKGU9dStlKTplPXV9cmV0dXJuIGV9KHRoaXMuc2NoZW1lLHJ8fGYpLHRoaXMucXVlcnk9bnx8Zix0aGlzLmZyYWdtZW50PW98fGYsZnVuY3Rpb24odCxlKXtpZighdC5zY2hlbWUmJmUpdGhyb3cgbmV3IEVycm9yKCdbVXJpRXJyb3JdOiBTY2hlbWUgaXMgbWlzc2luZzoge3NjaGVtZTogXCJcIiwgYXV0aG9yaXR5OiBcIicuY29uY2F0KHQuYXV0aG9yaXR5LCdcIiwgcGF0aDogXCInKS5jb25jYXQodC5wYXRoLCdcIiwgcXVlcnk6IFwiJykuY29uY2F0KHQucXVlcnksJ1wiLCBmcmFnbWVudDogXCInKS5jb25jYXQodC5mcmFnbWVudCwnXCJ9JykpO2lmKHQuc2NoZW1lJiYhaC50ZXN0KHQuc2NoZW1lKSl0aHJvdyBuZXcgRXJyb3IoXCJbVXJpRXJyb3JdOiBTY2hlbWUgY29udGFpbnMgaWxsZWdhbCBjaGFyYWN0ZXJzLlwiKTtpZih0LnBhdGgpaWYodC5hdXRob3JpdHkpe2lmKCFzLnRlc3QodC5wYXRoKSl0aHJvdyBuZXcgRXJyb3IoJ1tVcmlFcnJvcl06IElmIGEgVVJJIGNvbnRhaW5zIGFuIGF1dGhvcml0eSBjb21wb25lbnQsIHRoZW4gdGhlIHBhdGggY29tcG9uZW50IG11c3QgZWl0aGVyIGJlIGVtcHR5IG9yIGJlZ2luIHdpdGggYSBzbGFzaCAoXCIvXCIpIGNoYXJhY3RlcicpfWVsc2UgaWYoYy50ZXN0KHQucGF0aCkpdGhyb3cgbmV3IEVycm9yKCdbVXJpRXJyb3JdOiBJZiBhIFVSSSBkb2VzIG5vdCBjb250YWluIGFuIGF1dGhvcml0eSBjb21wb25lbnQsIHRoZW4gdGhlIHBhdGggY2Fubm90IGJlZ2luIHdpdGggdHdvIHNsYXNoIGNoYXJhY3RlcnMgKFwiLy9cIiknKX0odGhpcyxpKSl9cmV0dXJuIGUuaXNVcmk9ZnVuY3Rpb24odCl7cmV0dXJuIHQgaW5zdGFuY2VvZiBlfHwhIXQmJlwic3RyaW5nXCI9PXR5cGVvZiB0LmF1dGhvcml0eSYmXCJzdHJpbmdcIj09dHlwZW9mIHQuZnJhZ21lbnQmJlwic3RyaW5nXCI9PXR5cGVvZiB0LnBhdGgmJlwic3RyaW5nXCI9PXR5cGVvZiB0LnF1ZXJ5JiZcInN0cmluZ1wiPT10eXBlb2YgdC5zY2hlbWUmJlwic3RyaW5nXCI9PXR5cGVvZiB0LmZzUGF0aCYmXCJmdW5jdGlvblwiPT10eXBlb2YgdC53aXRoJiZcImZ1bmN0aW9uXCI9PXR5cGVvZiB0LnRvU3RyaW5nfSxPYmplY3QuZGVmaW5lUHJvcGVydHkoZS5wcm90b3R5cGUsXCJmc1BhdGhcIix7Z2V0OmZ1bmN0aW9uKCl7cmV0dXJuIGIodGhpcywhMSl9LGVudW1lcmFibGU6ITEsY29uZmlndXJhYmxlOiEwfSksZS5wcm90b3R5cGUud2l0aD1mdW5jdGlvbih0KXtpZighdClyZXR1cm4gdGhpczt2YXIgZT10LnNjaGVtZSxyPXQuYXV0aG9yaXR5LG49dC5wYXRoLG89dC5xdWVyeSxpPXQuZnJhZ21lbnQ7cmV0dXJuIHZvaWQgMD09PWU/ZT10aGlzLnNjaGVtZTpudWxsPT09ZSYmKGU9Ziksdm9pZCAwPT09cj9yPXRoaXMuYXV0aG9yaXR5Om51bGw9PT1yJiYocj1mKSx2b2lkIDA9PT1uP249dGhpcy5wYXRoOm51bGw9PT1uJiYobj1mKSx2b2lkIDA9PT1vP289dGhpcy5xdWVyeTpudWxsPT09byYmKG89Ziksdm9pZCAwPT09aT9pPXRoaXMuZnJhZ21lbnQ6bnVsbD09PWkmJihpPWYpLGU9PT10aGlzLnNjaGVtZSYmcj09PXRoaXMuYXV0aG9yaXR5JiZuPT09dGhpcy5wYXRoJiZvPT09dGhpcy5xdWVyeSYmaT09PXRoaXMuZnJhZ21lbnQ/dGhpczpuZXcgZChlLHIsbixvLGkpfSxlLnBhcnNlPWZ1bmN0aW9uKHQsZSl7dm9pZCAwPT09ZSYmKGU9ITEpO3ZhciByPWwuZXhlYyh0KTtyZXR1cm4gcj9uZXcgZChyWzJdfHxmLHgocls0XXx8ZikseChyWzVdfHxmKSx4KHJbN118fGYpLHgocls5XXx8ZiksZSk6bmV3IGQoZixmLGYsZixmKX0sZS5maWxlPWZ1bmN0aW9uKGUpe3ZhciByPWY7aWYodCYmKGU9ZS5yZXBsYWNlKC9cXFxcL2csdSkpLGVbMF09PT11JiZlWzFdPT09dSl7dmFyIG49ZS5pbmRleE9mKHUsMik7LTE9PT1uPyhyPWUuc3Vic3RyaW5nKDIpLGU9dSk6KHI9ZS5zdWJzdHJpbmcoMixuKSxlPWUuc3Vic3RyaW5nKG4pfHx1KX1yZXR1cm4gbmV3IGQoXCJmaWxlXCIscixlLGYsZil9LGUuZnJvbT1mdW5jdGlvbih0KXtyZXR1cm4gbmV3IGQodC5zY2hlbWUsdC5hdXRob3JpdHksdC5wYXRoLHQucXVlcnksdC5mcmFnbWVudCl9LGUucHJvdG90eXBlLnRvU3RyaW5nPWZ1bmN0aW9uKHQpe3JldHVybiB2b2lkIDA9PT10JiYodD0hMSksQyh0aGlzLHQpfSxlLnByb3RvdHlwZS50b0pTT049ZnVuY3Rpb24oKXtyZXR1cm4gdGhpc30sZS5yZXZpdmU9ZnVuY3Rpb24odCl7aWYodCl7aWYodCBpbnN0YW5jZW9mIGUpcmV0dXJuIHQ7dmFyIHI9bmV3IGQodCk7cmV0dXJuIHIuX2Zvcm1hdHRlZD10LmV4dGVybmFsLHIuX2ZzUGF0aD10Ll9zZXA9PT1nP3QuZnNQYXRoOm51bGwscn1yZXR1cm4gdH0sZX0oKSxnPXQ/MTp2b2lkIDAsZD1mdW5jdGlvbih0KXtmdW5jdGlvbiBlKCl7dmFyIGU9bnVsbCE9PXQmJnQuYXBwbHkodGhpcyxhcmd1bWVudHMpfHx0aGlzO3JldHVybiBlLl9mb3JtYXR0ZWQ9bnVsbCxlLl9mc1BhdGg9bnVsbCxlfXJldHVybiBhKGUsdCksT2JqZWN0LmRlZmluZVByb3BlcnR5KGUucHJvdG90eXBlLFwiZnNQYXRoXCIse2dldDpmdW5jdGlvbigpe3JldHVybiB0aGlzLl9mc1BhdGh8fCh0aGlzLl9mc1BhdGg9Yih0aGlzLCExKSksdGhpcy5fZnNQYXRofSxlbnVtZXJhYmxlOiExLGNvbmZpZ3VyYWJsZTohMH0pLGUucHJvdG90eXBlLnRvU3RyaW5nPWZ1bmN0aW9uKHQpe3JldHVybiB2b2lkIDA9PT10JiYodD0hMSksdD9DKHRoaXMsITApOih0aGlzLl9mb3JtYXR0ZWR8fCh0aGlzLl9mb3JtYXR0ZWQ9Qyh0aGlzLCExKSksdGhpcy5fZm9ybWF0dGVkKX0sZS5wcm90b3R5cGUudG9KU09OPWZ1bmN0aW9uKCl7dmFyIHQ9eyRtaWQ6MX07cmV0dXJuIHRoaXMuX2ZzUGF0aCYmKHQuZnNQYXRoPXRoaXMuX2ZzUGF0aCx0Ll9zZXA9ZyksdGhpcy5fZm9ybWF0dGVkJiYodC5leHRlcm5hbD10aGlzLl9mb3JtYXR0ZWQpLHRoaXMucGF0aCYmKHQucGF0aD10aGlzLnBhdGgpLHRoaXMuc2NoZW1lJiYodC5zY2hlbWU9dGhpcy5zY2hlbWUpLHRoaXMuYXV0aG9yaXR5JiYodC5hdXRob3JpdHk9dGhpcy5hdXRob3JpdHkpLHRoaXMucXVlcnkmJih0LnF1ZXJ5PXRoaXMucXVlcnkpLHRoaXMuZnJhZ21lbnQmJih0LmZyYWdtZW50PXRoaXMuZnJhZ21lbnQpLHR9LGV9KHApLHY9KChpPXt9KVs1OF09XCIlM0FcIixpWzQ3XT1cIiUyRlwiLGlbNjNdPVwiJTNGXCIsaVszNV09XCIlMjNcIixpWzkxXT1cIiU1QlwiLGlbOTNdPVwiJTVEXCIsaVs2NF09XCIlNDBcIixpWzMzXT1cIiUyMVwiLGlbMzZdPVwiJTI0XCIsaVszOF09XCIlMjZcIixpWzM5XT1cIiUyN1wiLGlbNDBdPVwiJTI4XCIsaVs0MV09XCIlMjlcIixpWzQyXT1cIiUyQVwiLGlbNDNdPVwiJTJCXCIsaVs0NF09XCIlMkNcIixpWzU5XT1cIiUzQlwiLGlbNjFdPVwiJTNEXCIsaVszMl09XCIlMjBcIixpKTtmdW5jdGlvbiB5KHQsZSl7Zm9yKHZhciByPXZvaWQgMCxuPS0xLG89MDtvPHQubGVuZ3RoO28rKyl7dmFyIGk9dC5jaGFyQ29kZUF0KG8pO2lmKGk+PTk3JiZpPD0xMjJ8fGk+PTY1JiZpPD05MHx8aT49NDgmJmk8PTU3fHw0NT09PWl8fDQ2PT09aXx8OTU9PT1pfHwxMjY9PT1pfHxlJiY0Nz09PWkpLTEhPT1uJiYocis9ZW5jb2RlVVJJQ29tcG9uZW50KHQuc3Vic3RyaW5nKG4sbykpLG49LTEpLHZvaWQgMCE9PXImJihyKz10LmNoYXJBdChvKSk7ZWxzZXt2b2lkIDA9PT1yJiYocj10LnN1YnN0cigwLG8pKTt2YXIgYT12W2ldO3ZvaWQgMCE9PWE/KC0xIT09biYmKHIrPWVuY29kZVVSSUNvbXBvbmVudCh0LnN1YnN0cmluZyhuLG8pKSxuPS0xKSxyKz1hKTotMT09PW4mJihuPW8pfX1yZXR1cm4tMSE9PW4mJihyKz1lbmNvZGVVUklDb21wb25lbnQodC5zdWJzdHJpbmcobikpKSx2b2lkIDAhPT1yP3I6dH1mdW5jdGlvbiBtKHQpe2Zvcih2YXIgZT12b2lkIDAscj0wO3I8dC5sZW5ndGg7cisrKXt2YXIgbj10LmNoYXJDb2RlQXQocik7MzU9PT1ufHw2Mz09PW4/KHZvaWQgMD09PWUmJihlPXQuc3Vic3RyKDAscikpLGUrPXZbbl0pOnZvaWQgMCE9PWUmJihlKz10W3JdKX1yZXR1cm4gdm9pZCAwIT09ZT9lOnR9ZnVuY3Rpb24gYihlLHIpe3ZhciBuO3JldHVybiBuPWUuYXV0aG9yaXR5JiZlLnBhdGgubGVuZ3RoPjEmJlwiZmlsZVwiPT09ZS5zY2hlbWU/XCIvL1wiLmNvbmNhdChlLmF1dGhvcml0eSkuY29uY2F0KGUucGF0aCk6NDc9PT1lLnBhdGguY2hhckNvZGVBdCgwKSYmKGUucGF0aC5jaGFyQ29kZUF0KDEpPj02NSYmZS5wYXRoLmNoYXJDb2RlQXQoMSk8PTkwfHxlLnBhdGguY2hhckNvZGVBdCgxKT49OTcmJmUucGF0aC5jaGFyQ29kZUF0KDEpPD0xMjIpJiY1OD09PWUucGF0aC5jaGFyQ29kZUF0KDIpP3I/ZS5wYXRoLnN1YnN0cigxKTplLnBhdGhbMV0udG9Mb3dlckNhc2UoKStlLnBhdGguc3Vic3RyKDIpOmUucGF0aCx0JiYobj1uLnJlcGxhY2UoL1xcLy9nLFwiXFxcXFwiKSksbn1mdW5jdGlvbiBDKHQsZSl7dmFyIHI9ZT9tOnksbj1cIlwiLG89dC5zY2hlbWUsaT10LmF1dGhvcml0eSxhPXQucGF0aCxoPXQucXVlcnkscz10LmZyYWdtZW50O2lmKG8mJihuKz1vLG4rPVwiOlwiKSwoaXx8XCJmaWxlXCI9PT1vKSYmKG4rPXUsbis9dSksaSl7dmFyIGM9aS5pbmRleE9mKFwiQFwiKTtpZigtMSE9PWMpe3ZhciBmPWkuc3Vic3RyKDAsYyk7aT1pLnN1YnN0cihjKzEpLC0xPT09KGM9Zi5pbmRleE9mKFwiOlwiKSk/bis9cihmLCExKToobis9cihmLnN1YnN0cigwLGMpLCExKSxuKz1cIjpcIixuKz1yKGYuc3Vic3RyKGMrMSksITEpKSxuKz1cIkBcIn0tMT09PShjPShpPWkudG9Mb3dlckNhc2UoKSkuaW5kZXhPZihcIjpcIikpP24rPXIoaSwhMSk6KG4rPXIoaS5zdWJzdHIoMCxjKSwhMSksbis9aS5zdWJzdHIoYykpfWlmKGEpe2lmKGEubGVuZ3RoPj0zJiY0Nz09PWEuY2hhckNvZGVBdCgwKSYmNTg9PT1hLmNoYXJDb2RlQXQoMikpKGw9YS5jaGFyQ29kZUF0KDEpKT49NjUmJmw8PTkwJiYoYT1cIi9cIi5jb25jYXQoU3RyaW5nLmZyb21DaGFyQ29kZShsKzMyKSxcIjpcIikuY29uY2F0KGEuc3Vic3RyKDMpKSk7ZWxzZSBpZihhLmxlbmd0aD49MiYmNTg9PT1hLmNoYXJDb2RlQXQoMSkpe3ZhciBsOyhsPWEuY2hhckNvZGVBdCgwKSk+PTY1JiZsPD05MCYmKGE9XCJcIi5jb25jYXQoU3RyaW5nLmZyb21DaGFyQ29kZShsKzMyKSxcIjpcIikuY29uY2F0KGEuc3Vic3RyKDIpKSl9bis9cihhLCEwKX1yZXR1cm4gaCYmKG4rPVwiP1wiLG4rPXIoaCwhMSkpLHMmJihuKz1cIiNcIixuKz1lP3M6eShzLCExKSksbn1mdW5jdGlvbiBBKHQpe3RyeXtyZXR1cm4gZGVjb2RlVVJJQ29tcG9uZW50KHQpfWNhdGNoKGUpe3JldHVybiB0Lmxlbmd0aD4zP3Quc3Vic3RyKDAsMykrQSh0LnN1YnN0cigzKSk6dH19dmFyIHc9LyglWzAtOUEtWmEtel1bMC05QS1aYS16XSkrL2c7ZnVuY3Rpb24geCh0KXtyZXR1cm4gdC5tYXRjaCh3KT90LnJlcGxhY2UodywoZnVuY3Rpb24odCl7cmV0dXJuIEEodCl9KSk6dH12YXIgXyxPPXIoNDcwKSxQPWZ1bmN0aW9uKHQsZSxyKXtpZihyfHwyPT09YXJndW1lbnRzLmxlbmd0aClmb3IodmFyIG4sbz0wLGk9ZS5sZW5ndGg7bzxpO28rKykhbiYmbyBpbiBlfHwobnx8KG49QXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwoZSwwLG8pKSxuW29dPWVbb10pO3JldHVybiB0LmNvbmNhdChufHxBcnJheS5wcm90b3R5cGUuc2xpY2UuY2FsbChlKSl9LGo9Ty5wb3NpeHx8TyxVPVwiL1wiOyFmdW5jdGlvbih0KXt0LmpvaW5QYXRoPWZ1bmN0aW9uKHQpe2Zvcih2YXIgZT1bXSxyPTE7cjxhcmd1bWVudHMubGVuZ3RoO3IrKyllW3ItMV09YXJndW1lbnRzW3JdO3JldHVybiB0LndpdGgoe3BhdGg6ai5qb2luLmFwcGx5KGosUChbdC5wYXRoXSxlLCExKSl9KX0sdC5yZXNvbHZlUGF0aD1mdW5jdGlvbih0KXtmb3IodmFyIGU9W10scj0xO3I8YXJndW1lbnRzLmxlbmd0aDtyKyspZVtyLTFdPWFyZ3VtZW50c1tyXTt2YXIgbj10LnBhdGgsbz0hMTtuWzBdIT09VSYmKG49VStuLG89ITApO3ZhciBpPWoucmVzb2x2ZS5hcHBseShqLFAoW25dLGUsITEpKTtyZXR1cm4gbyYmaVswXT09PVUmJiF0LmF1dGhvcml0eSYmKGk9aS5zdWJzdHJpbmcoMSkpLHQud2l0aCh7cGF0aDppfSl9LHQuZGlybmFtZT1mdW5jdGlvbih0KXtpZigwPT09dC5wYXRoLmxlbmd0aHx8dC5wYXRoPT09VSlyZXR1cm4gdDt2YXIgZT1qLmRpcm5hbWUodC5wYXRoKTtyZXR1cm4gMT09PWUubGVuZ3RoJiY0Nj09PWUuY2hhckNvZGVBdCgwKSYmKGU9XCJcIiksdC53aXRoKHtwYXRoOmV9KX0sdC5iYXNlbmFtZT1mdW5jdGlvbih0KXtyZXR1cm4gai5iYXNlbmFtZSh0LnBhdGgpfSx0LmV4dG5hbWU9ZnVuY3Rpb24odCl7cmV0dXJuIGouZXh0bmFtZSh0LnBhdGgpfX0oX3x8KF89e30pKX0pKCksTElCPW59KSgpO2V4cG9ydCBjb25zdHtVUkksVXRpbHN9PUxJQjtcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPWluZGV4LmpzLm1hcCIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tICcuL2NvbW1hbmRzQW5kRXZlbnRzJztcclxuaW1wb3J0IHsgVVJJIH0gZnJvbSAndnNjb2RlLXVyaSc7XHJcbmltcG9ydCB7IEtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUsIGlzS2VybmVsQ29tbWFuZEVudmVsb3BlIH0gZnJvbSAnLi9jb25uZWN0aW9uJztcclxuXHJcblxyXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlS2VybmVsVXJpKGtlcm5lbFVyaTogc3RyaW5nKTogc3RyaW5nIHtcclxuICAgIGNvbnN0IHVyaSA9IFVSSS5wYXJzZShrZXJuZWxVcmkpO1xyXG4gICAgdXJpLmF1dGhvcml0eTtcclxuICAgIHVyaS5wYXRoO1xyXG4gICAgbGV0IGFic29sdXRlVXJpID0gYCR7dXJpLnNjaGVtZX06Ly8ke3VyaS5hdXRob3JpdHl9JHt1cmkucGF0aCB8fCBcIi9cIn1gO1xyXG4gICAgcmV0dXJuIGFic29sdXRlVXJpO1xyXG59XHJcblxyXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlS2VybmVsVXJpV2l0aFF1ZXJ5KGtlcm5lbFVyaTogc3RyaW5nKTogc3RyaW5nIHtcclxuICAgIGNvbnN0IHVyaSA9IFVSSS5wYXJzZShrZXJuZWxVcmkpO1xyXG4gICAgdXJpLmF1dGhvcml0eTtcclxuICAgIHVyaS5wYXRoO1xyXG4gICAgbGV0IGFic29sdXRlVXJpID0gYCR7dXJpLnNjaGVtZX06Ly8ke3VyaS5hdXRob3JpdHl9JHt1cmkucGF0aCB8fCBcIi9cIn1gO1xyXG4gICAgaWYgKHVyaS5xdWVyeSkge1xyXG4gICAgICAgIGFic29sdXRlVXJpICs9IGA/JHt1cmkucXVlcnl9YDtcclxuICAgIH1cclxuICAgIHJldHVybiBhYnNvbHV0ZVVyaTtcclxufVxyXG5leHBvcnQgZnVuY3Rpb24gZ2V0VGFnKGtlcm5lbFVyaTogc3RyaW5nKTogc3RyaW5nIHwgdW5kZWZpbmVkIHtcclxuICAgIGNvbnN0IHVyaSA9IFVSSS5wYXJzZShrZXJuZWxVcmkpO1xyXG4gICAgaWYgKHVyaS5xdWVyeSkgey8vP1xyXG4gICAgICAgIGNvbnN0IHBhcnRzID0gdXJpLnF1ZXJ5LnNwbGl0KFwidGFnPVwiKTtcclxuICAgICAgICBpZiAocGFydHMubGVuZ3RoID4gMSkge1xyXG4gICAgICAgICAgICByZXR1cm4gcGFydHNbMV07XHJcbiAgICAgICAgfVxyXG4gICAgfVxyXG4gICAgcmV0dXJuIHVuZGVmaW5lZDtcclxufVxyXG5cclxuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZVJvdXRpbmdTbGlwKGtlcm5lbFVyaXM6IHN0cmluZ1tdKTogc3RyaW5nW10ge1xyXG4gICAgcmV0dXJuIEFycmF5LmZyb20obmV3IFNldChrZXJuZWxVcmlzLm1hcChlID0+IGNyZWF0ZUtlcm5lbFVyaVdpdGhRdWVyeShlKSkpKTtcclxufVxyXG5cclxuZnVuY3Rpb24gcm91dGluZ1NsaXBTdGFydHNXaXRoKHRoaXNLZXJuZWxVcmlzOiBzdHJpbmdbXSwgb3RoZXJLZXJuZWxVcmlzOiBzdHJpbmdbXSk6IGJvb2xlYW4ge1xyXG4gICAgbGV0IHN0YXJ0c1dpdGggPSB0cnVlO1xyXG5cclxuICAgIGlmIChvdGhlcktlcm5lbFVyaXMubGVuZ3RoID4gMCAmJiB0aGlzS2VybmVsVXJpcy5sZW5ndGggPj0gb3RoZXJLZXJuZWxVcmlzLmxlbmd0aCkge1xyXG4gICAgICAgIGZvciAobGV0IGkgPSAwOyBpIDwgb3RoZXJLZXJuZWxVcmlzLmxlbmd0aDsgaSsrKSB7XHJcbiAgICAgICAgICAgIGlmIChjcmVhdGVLZXJuZWxVcmkob3RoZXJLZXJuZWxVcmlzW2ldKSAhPT0gY3JlYXRlS2VybmVsVXJpKHRoaXNLZXJuZWxVcmlzW2ldKSkge1xyXG4gICAgICAgICAgICAgICAgc3RhcnRzV2l0aCA9IGZhbHNlO1xyXG4gICAgICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcbiAgICB9XHJcbiAgICBlbHNlIHtcclxuICAgICAgICBzdGFydHNXaXRoID0gZmFsc2U7XHJcbiAgICB9XHJcblxyXG4gICAgcmV0dXJuIHN0YXJ0c1dpdGg7XHJcbn1cclxuXHJcbmZ1bmN0aW9uIHJvdXRpbmdTbGlwQ29udGFpbnMocm91dGluZ1NsaXA6IHN0cmluZ1tdLCBrZXJuZWxVcmk6IHN0cmluZywgaWdub3JlUXVlcnk6IGJvb2xlYW4gPSBmYWxzZSk6IGJvb2xlYW4ge1xyXG4gICAgY29uc3Qgbm9ybWFsaXplZFVyaSA9IGlnbm9yZVF1ZXJ5ID8gY3JlYXRlS2VybmVsVXJpKGtlcm5lbFVyaSkgOiBjcmVhdGVLZXJuZWxVcmlXaXRoUXVlcnkoa2VybmVsVXJpKTtcclxuICAgIHJldHVybiByb3V0aW5nU2xpcC5maW5kKGUgPT4gbm9ybWFsaXplZFVyaSA9PT0gKCFpZ25vcmVRdWVyeSA/IGNyZWF0ZUtlcm5lbFVyaVdpdGhRdWVyeShlKSA6IGNyZWF0ZUtlcm5lbFVyaShlKSkpICE9PSB1bmRlZmluZWQ7XHJcbn1cclxuXHJcbmV4cG9ydCBhYnN0cmFjdCBjbGFzcyBSb3V0aW5nU2xpcCB7XHJcbiAgICBwcml2YXRlIF91cmlzOiBzdHJpbmdbXSA9IFtdO1xyXG5cclxuICAgIHByb3RlY3RlZCBnZXQgdXJpcygpOiBzdHJpbmdbXSB7XHJcbiAgICAgICAgcmV0dXJuIHRoaXMuX3VyaXM7XHJcbiAgICB9XHJcblxyXG4gICAgcHJvdGVjdGVkIHNldCB1cmlzKHZhbHVlOiBzdHJpbmdbXSkge1xyXG4gICAgICAgIHRoaXMuX3VyaXMgPSB2YWx1ZTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgY29udGFpbnMoa2VybmVsVXJpOiBzdHJpbmcsIGlnbm9yZVF1ZXJ5OiBib29sZWFuID0gZmFsc2UpOiBib29sZWFuIHtcclxuICAgICAgICByZXR1cm4gcm91dGluZ1NsaXBDb250YWlucyh0aGlzLl91cmlzLCBrZXJuZWxVcmksIGlnbm9yZVF1ZXJ5KTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgc3RhcnRzV2l0aChvdGhlcjogc3RyaW5nW10gfCBSb3V0aW5nU2xpcCk6IGJvb2xlYW4ge1xyXG4gICAgICAgIGlmIChvdGhlciBpbnN0YW5jZW9mIEFycmF5KSB7XHJcbiAgICAgICAgICAgIHJldHVybiByb3V0aW5nU2xpcFN0YXJ0c1dpdGgodGhpcy5fdXJpcywgb3RoZXIpO1xyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIHJldHVybiByb3V0aW5nU2xpcFN0YXJ0c1dpdGgodGhpcy5fdXJpcywgb3RoZXIuX3VyaXMpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgY29udGludWVXaXRoKG90aGVyOiBzdHJpbmdbXSB8IFJvdXRpbmdTbGlwKTogdm9pZCB7XHJcbiAgICAgICAgbGV0IG90aGVyVXJpcyA9IChvdGhlciBpbnN0YW5jZW9mIEFycmF5ID8gb3RoZXIgOiBvdGhlci5fdXJpcykgfHwgW107XHJcbiAgICAgICAgaWYgKG90aGVyVXJpcy5sZW5ndGggPiAwKSB7XHJcbiAgICAgICAgICAgIGlmIChyb3V0aW5nU2xpcFN0YXJ0c1dpdGgob3RoZXJVcmlzLCB0aGlzLl91cmlzKSkge1xyXG4gICAgICAgICAgICAgICAgb3RoZXJVcmlzID0gb3RoZXJVcmlzLnNsaWNlKHRoaXMuX3VyaXMubGVuZ3RoKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgZm9yIChsZXQgaSA9IDA7IGkgPCBvdGhlclVyaXMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgICAgICAgaWYgKCF0aGlzLmNvbnRhaW5zKG90aGVyVXJpc1tpXSkpIHtcclxuICAgICAgICAgICAgICAgIHRoaXMuX3VyaXMucHVzaChvdGhlclVyaXNbaV0pO1xyXG4gICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKGBUaGUgdXJpICR7b3RoZXJVcmlzW2ldfSBpcyBhbHJlYWR5IGluIHRoZSByb3V0aW5nIHNsaXAgWyR7dGhpcy5fdXJpc31dLCBjYW5ub3QgY29udGludWUgd2l0aCByb3V0aW5nIHNsaXAgWyR7b3RoZXJVcmlzfV1gKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgdG9BcnJheSgpOiBzdHJpbmdbXSB7XHJcbiAgICAgICAgcmV0dXJuIFsuLi50aGlzLl91cmlzXTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgYWJzdHJhY3Qgc3RhbXAoa2VybmVsVXJpOiBzdHJpbmcpOiB2b2lkO1xyXG59XHJcblxyXG5leHBvcnQgY2xhc3MgQ29tbWFuZFJvdXRpbmdTbGlwIGV4dGVuZHMgUm91dGluZ1NsaXAge1xyXG4gICAgY29uc3RydWN0b3IoKSB7XHJcbiAgICAgICAgc3VwZXIoKTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgc3RhdGljIGZyb21VcmlzKHVyaXM6IHN0cmluZ1tdKTogQ29tbWFuZFJvdXRpbmdTbGlwIHtcclxuICAgICAgICBjb25zdCByb3V0aW5nU2xpcCA9IG5ldyBDb21tYW5kUm91dGluZ1NsaXAoKTtcclxuICAgICAgICByb3V0aW5nU2xpcC51cmlzID0gdXJpcztcclxuICAgICAgICByZXR1cm4gcm91dGluZ1NsaXA7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHN0YW1wQXNBcnJpdmVkKGtlcm5lbFVyaTogc3RyaW5nKTogdm9pZCB7XHJcbiAgICAgICAgdGhpcy5zdGFtcEFzKGtlcm5lbFVyaSwgXCJhcnJpdmVkXCIpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBvdmVycmlkZSBzdGFtcChrZXJuZWxVcmk6IHN0cmluZyk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMuc3RhbXBBcyhrZXJuZWxVcmkpO1xyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgc3RhbXBBcyhrZXJuZWxVcmk6IHN0cmluZywgdGFnPzogc3RyaW5nKTogdm9pZCB7XHJcbiAgICAgICAgaWYgKHRhZykge1xyXG4gICAgICAgICAgICBjb25zdCBhYnNvbHV0ZVVyaVdpdGhRdWVyeSA9IGAke2NyZWF0ZUtlcm5lbFVyaShrZXJuZWxVcmkpfT90YWc9JHt0YWd9YDtcclxuICAgICAgICAgICAgY29uc3QgYWJzb2x1dGVVcmlXaXRob3V0UXVlcnkgPSBjcmVhdGVLZXJuZWxVcmkoa2VybmVsVXJpKTtcclxuICAgICAgICAgICAgaWYgKHRoaXMudXJpcy5maW5kKGUgPT4gZS5zdGFydHNXaXRoKGFic29sdXRlVXJpV2l0aG91dFF1ZXJ5KSkpIHtcclxuICAgICAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihgVGhlIHVyaSAke2Fic29sdXRlVXJpV2l0aFF1ZXJ5fSBpcyBhbHJlYWR5IGluIHRoZSByb3V0aW5nIHNsaXAgWyR7dGhpcy51cmlzfV1gKTtcclxuICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgIHRoaXMudXJpcy5wdXNoKGFic29sdXRlVXJpV2l0aFF1ZXJ5KTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIGNvbnN0IGFic29sdXRlVXJpV2l0aFF1ZXJ5ID0gYCR7Y3JlYXRlS2VybmVsVXJpKGtlcm5lbFVyaSl9P3RhZz1hcnJpdmVkYDtcclxuICAgICAgICAgICAgY29uc3QgYWJzb2x1dGVVcmlXaXRob3V0UXVlcnkgPSBjcmVhdGVLZXJuZWxVcmkoa2VybmVsVXJpKTtcclxuICAgICAgICAgICAgaWYgKCF0aGlzLnVyaXMuZmluZChlID0+IGUuc3RhcnRzV2l0aChhYnNvbHV0ZVVyaVdpdGhRdWVyeSkpKSB7XHJcbiAgICAgICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYFRoZSB1cmkgJHthYnNvbHV0ZVVyaVdpdGhRdWVyeX0gaXMgbm90IGluIHRoZSByb3V0aW5nIHNsaXAgWyR7dGhpcy51cmlzfV1gKTtcclxuICAgICAgICAgICAgfSBlbHNlIGlmICh0aGlzLnVyaXMuZmluZChlID0+IGUgPT09IGFic29sdXRlVXJpV2l0aG91dFF1ZXJ5KSkge1xyXG4gICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKGBUaGUgdXJpICR7YWJzb2x1dGVVcmlXaXRob3V0UXVlcnl9IGlzIGFscmVhZHkgaW4gdGhlIHJvdXRpbmcgc2xpcCBbJHt0aGlzLnVyaXN9XWApO1xyXG4gICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgdGhpcy51cmlzLnB1c2goYWJzb2x1dGVVcmlXaXRob3V0UXVlcnkpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfVxyXG4gICAgfVxyXG59XHJcblxyXG5leHBvcnQgY2xhc3MgRXZlbnRSb3V0aW5nU2xpcCBleHRlbmRzIFJvdXRpbmdTbGlwIHtcclxuICAgIGNvbnN0cnVjdG9yKCkge1xyXG4gICAgICAgIHN1cGVyKCk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHN0YXRpYyBmcm9tVXJpcyh1cmlzOiBzdHJpbmdbXSk6IEV2ZW50Um91dGluZ1NsaXAge1xyXG4gICAgICAgIGNvbnN0IHJvdXRpbmdTbGlwID0gbmV3IEV2ZW50Um91dGluZ1NsaXAoKTtcclxuICAgICAgICByb3V0aW5nU2xpcC51cmlzID0gdXJpcztcclxuICAgICAgICByZXR1cm4gcm91dGluZ1NsaXA7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIG92ZXJyaWRlIHN0YW1wKGtlcm5lbFVyaTogc3RyaW5nKTogdm9pZCB7XHJcbiAgICAgICAgY29uc3Qgbm9ybWFsaXplZFVyaSA9IGNyZWF0ZUtlcm5lbFVyaVdpdGhRdWVyeShrZXJuZWxVcmkpO1xyXG4gICAgICAgIGNvbnN0IGNhbkFkZCA9ICF0aGlzLnVyaXMuZmluZChlID0+IGNyZWF0ZUtlcm5lbFVyaVdpdGhRdWVyeShlKSA9PT0gbm9ybWFsaXplZFVyaSk7XHJcbiAgICAgICAgaWYgKGNhbkFkZCkge1xyXG4gICAgICAgICAgICB0aGlzLnVyaXMucHVzaChub3JtYWxpemVkVXJpKTtcclxuICAgICAgICAgICAgdGhpcy51cmlzO1xyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihgVGhlIHVyaSAke25vcm1hbGl6ZWRVcml9IGlzIGFscmVhZHkgaW4gdGhlIHJvdXRpbmcgc2xpcCBbJHt0aGlzLnVyaXN9XWApO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxufSIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG4vLyBHZW5lcmF0ZWQgVHlwZVNjcmlwdCBpbnRlcmZhY2VzIGFuZCB0eXBlcy5cclxuXHJcbi8vIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBLZXJuZWwgQ29tbWFuZHNcclxuXHJcbmV4cG9ydCBjb25zdCBBZGRQYWNrYWdlVHlwZSA9IFwiQWRkUGFja2FnZVwiO1xyXG5leHBvcnQgY29uc3QgQWRkUGFja2FnZVNvdXJjZVR5cGUgPSBcIkFkZFBhY2thZ2VTb3VyY2VcIjtcclxuZXhwb3J0IGNvbnN0IENhbmNlbFR5cGUgPSBcIkNhbmNlbFwiO1xyXG5leHBvcnQgY29uc3QgQ29tcGlsZVByb2plY3RUeXBlID0gXCJDb21waWxlUHJvamVjdFwiO1xyXG5leHBvcnQgY29uc3QgRGlzcGxheUVycm9yVHlwZSA9IFwiRGlzcGxheUVycm9yXCI7XHJcbmV4cG9ydCBjb25zdCBEaXNwbGF5VmFsdWVUeXBlID0gXCJEaXNwbGF5VmFsdWVcIjtcclxuZXhwb3J0IGNvbnN0IEltcG9ydERvY3VtZW50VHlwZSA9IFwiSW1wb3J0RG9jdW1lbnRcIjtcclxuZXhwb3J0IGNvbnN0IE9wZW5Eb2N1bWVudFR5cGUgPSBcIk9wZW5Eb2N1bWVudFwiO1xyXG5leHBvcnQgY29uc3QgT3BlblByb2plY3RUeXBlID0gXCJPcGVuUHJvamVjdFwiO1xyXG5leHBvcnQgY29uc3QgUXVpdFR5cGUgPSBcIlF1aXRcIjtcclxuZXhwb3J0IGNvbnN0IFJlcXVlc3RDb21wbGV0aW9uc1R5cGUgPSBcIlJlcXVlc3RDb21wbGV0aW9uc1wiO1xyXG5leHBvcnQgY29uc3QgUmVxdWVzdERpYWdub3N0aWNzVHlwZSA9IFwiUmVxdWVzdERpYWdub3N0aWNzXCI7XHJcbmV4cG9ydCBjb25zdCBSZXF1ZXN0SG92ZXJUZXh0VHlwZSA9IFwiUmVxdWVzdEhvdmVyVGV4dFwiO1xyXG5leHBvcnQgY29uc3QgUmVxdWVzdElucHV0VHlwZSA9IFwiUmVxdWVzdElucHV0XCI7XHJcbmV4cG9ydCBjb25zdCBSZXF1ZXN0SW5wdXRzVHlwZSA9IFwiUmVxdWVzdElucHV0c1wiO1xyXG5leHBvcnQgY29uc3QgUmVxdWVzdEtlcm5lbEluZm9UeXBlID0gXCJSZXF1ZXN0S2VybmVsSW5mb1wiO1xyXG5leHBvcnQgY29uc3QgUmVxdWVzdFNpZ25hdHVyZUhlbHBUeXBlID0gXCJSZXF1ZXN0U2lnbmF0dXJlSGVscFwiO1xyXG5leHBvcnQgY29uc3QgUmVxdWVzdFZhbHVlVHlwZSA9IFwiUmVxdWVzdFZhbHVlXCI7XHJcbmV4cG9ydCBjb25zdCBSZXF1ZXN0VmFsdWVJbmZvc1R5cGUgPSBcIlJlcXVlc3RWYWx1ZUluZm9zXCI7XHJcbmV4cG9ydCBjb25zdCBTZW5kRWRpdGFibGVDb2RlVHlwZSA9IFwiU2VuZEVkaXRhYmxlQ29kZVwiO1xyXG5leHBvcnQgY29uc3QgU2VuZFZhbHVlVHlwZSA9IFwiU2VuZFZhbHVlXCI7XHJcbmV4cG9ydCBjb25zdCBTdWJtaXRDb2RlVHlwZSA9IFwiU3VibWl0Q29kZVwiO1xyXG5leHBvcnQgY29uc3QgVXBkYXRlRGlzcGxheWVkVmFsdWVUeXBlID0gXCJVcGRhdGVEaXNwbGF5ZWRWYWx1ZVwiO1xyXG5cclxuZXhwb3J0IHR5cGUgS2VybmVsQ29tbWFuZFR5cGUgPVxyXG4gICAgICB0eXBlb2YgQWRkUGFja2FnZVR5cGVcclxuICAgIHwgdHlwZW9mIEFkZFBhY2thZ2VTb3VyY2VUeXBlXHJcbiAgICB8IHR5cGVvZiBDYW5jZWxUeXBlXHJcbiAgICB8IHR5cGVvZiBDb21waWxlUHJvamVjdFR5cGVcclxuICAgIHwgdHlwZW9mIERpc3BsYXlFcnJvclR5cGVcclxuICAgIHwgdHlwZW9mIERpc3BsYXlWYWx1ZVR5cGVcclxuICAgIHwgdHlwZW9mIEltcG9ydERvY3VtZW50VHlwZVxyXG4gICAgfCB0eXBlb2YgT3BlbkRvY3VtZW50VHlwZVxyXG4gICAgfCB0eXBlb2YgT3BlblByb2plY3RUeXBlXHJcbiAgICB8IHR5cGVvZiBRdWl0VHlwZVxyXG4gICAgfCB0eXBlb2YgUmVxdWVzdENvbXBsZXRpb25zVHlwZVxyXG4gICAgfCB0eXBlb2YgUmVxdWVzdERpYWdub3N0aWNzVHlwZVxyXG4gICAgfCB0eXBlb2YgUmVxdWVzdEhvdmVyVGV4dFR5cGVcclxuICAgIHwgdHlwZW9mIFJlcXVlc3RJbnB1dFR5cGVcclxuICAgIHwgdHlwZW9mIFJlcXVlc3RJbnB1dHNUeXBlXHJcbiAgICB8IHR5cGVvZiBSZXF1ZXN0S2VybmVsSW5mb1R5cGVcclxuICAgIHwgdHlwZW9mIFJlcXVlc3RTaWduYXR1cmVIZWxwVHlwZVxyXG4gICAgfCB0eXBlb2YgUmVxdWVzdFZhbHVlVHlwZVxyXG4gICAgfCB0eXBlb2YgUmVxdWVzdFZhbHVlSW5mb3NUeXBlXHJcbiAgICB8IHR5cGVvZiBTZW5kRWRpdGFibGVDb2RlVHlwZVxyXG4gICAgfCB0eXBlb2YgU2VuZFZhbHVlVHlwZVxyXG4gICAgfCB0eXBlb2YgU3VibWl0Q29kZVR5cGVcclxuICAgIHwgdHlwZW9mIFVwZGF0ZURpc3BsYXllZFZhbHVlVHlwZTtcclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgQWRkUGFja2FnZSBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgcGFja2FnZU5hbWU6IHN0cmluZztcclxuICAgIHBhY2thZ2VWZXJzaW9uOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgS2VybmVsQ29tbWFuZCB7XHJcbiAgICBkZXN0aW5hdGlvblVyaT86IHN0cmluZztcclxuICAgIG9yaWdpblVyaT86IHN0cmluZztcclxuICAgIHRhcmdldEtlcm5lbE5hbWU/OiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgQWRkUGFja2FnZVNvdXJjZSBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgcGFja2FnZVNvdXJjZTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIENhbmNlbCBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIENvbXBpbGVQcm9qZWN0IGV4dGVuZHMgS2VybmVsQ29tbWFuZCB7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgRGlzcGxheUVycm9yIGV4dGVuZHMgS2VybmVsQ29tbWFuZCB7XHJcbiAgICBtZXNzYWdlOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgRGlzcGxheVZhbHVlIGV4dGVuZHMgS2VybmVsQ29tbWFuZCB7XHJcbiAgICBmb3JtYXR0ZWRWYWx1ZTogRm9ybWF0dGVkVmFsdWU7XHJcbiAgICB2YWx1ZUlkOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgSW1wb3J0RG9jdW1lbnQgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIGZpbGU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBPcGVuRG9jdW1lbnQgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIHJlZ2lvbk5hbWU/OiBzdHJpbmc7XHJcbiAgICByZWxhdGl2ZUZpbGVQYXRoOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgT3BlblByb2plY3QgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIHByb2plY3Q6IFByb2plY3Q7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgUXVpdCBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFJlcXVlc3RDb21wbGV0aW9ucyBleHRlbmRzIExhbmd1YWdlU2VydmljZUNvbW1hbmQge1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIExhbmd1YWdlU2VydmljZUNvbW1hbmQgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIGNvZGU6IHN0cmluZztcclxuICAgIGxpbmVQb3NpdGlvbjogTGluZVBvc2l0aW9uO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFJlcXVlc3REaWFnbm9zdGljcyBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgY29kZTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFJlcXVlc3RIb3ZlclRleHQgZXh0ZW5kcyBMYW5ndWFnZVNlcnZpY2VDb21tYW5kIHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBSZXF1ZXN0SW5wdXQgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIHR5cGU6IHN0cmluZztcclxuICAgIGlzUGFzc3dvcmQ6IGJvb2xlYW47XHJcbiAgICBwYXJhbWV0ZXJOYW1lOiBzdHJpbmc7XHJcbiAgICBwcm9tcHQ6IHN0cmluZztcclxuICAgIHNhdmVBczogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFJlcXVlc3RJbnB1dHMgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIGlucHV0czogQXJyYXk8SW5wdXREZXNjcmlwdGlvbj47XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgUmVxdWVzdEtlcm5lbEluZm8gZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBSZXF1ZXN0U2lnbmF0dXJlSGVscCBleHRlbmRzIExhbmd1YWdlU2VydmljZUNvbW1hbmQge1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFJlcXVlc3RWYWx1ZSBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgbWltZVR5cGU6IHN0cmluZztcclxuICAgIG5hbWU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBSZXF1ZXN0VmFsdWVJbmZvcyBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgbWltZVR5cGU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBTZW5kRWRpdGFibGVDb2RlIGV4dGVuZHMgS2VybmVsQ29tbWFuZCB7XHJcbiAgICBjb2RlOiBzdHJpbmc7XHJcbiAgICBpbnNlcnRBdFBvc2l0aW9uPzogbnVtYmVyO1xyXG4gICAga2VybmVsTmFtZTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFNlbmRWYWx1ZSBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgZm9ybWF0dGVkVmFsdWU6IEZvcm1hdHRlZFZhbHVlO1xyXG4gICAgbmFtZTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFN1Ym1pdENvZGUgZXh0ZW5kcyBLZXJuZWxDb21tYW5kIHtcclxuICAgIGNvZGU6IHN0cmluZztcclxuICAgIHBhcmFtZXRlcnM/OiB7IFtrZXk6IHN0cmluZ106IHN0cmluZzsgfTtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBVcGRhdGVEaXNwbGF5ZWRWYWx1ZSBleHRlbmRzIEtlcm5lbENvbW1hbmQge1xyXG4gICAgZm9ybWF0dGVkVmFsdWU6IEZvcm1hdHRlZFZhbHVlO1xyXG4gICAgdmFsdWVJZDogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEtlcm5lbEV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBEaXNwbGF5RWxlbWVudCBleHRlbmRzIEludGVyYWN0aXZlRG9jdW1lbnRPdXRwdXRFbGVtZW50IHtcclxuICAgIGRhdGE6IHsgW2tleTogc3RyaW5nXTogYW55OyB9O1xyXG4gICAgbWV0YWRhdGE6IHsgW2tleTogc3RyaW5nXTogYW55OyB9O1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEludGVyYWN0aXZlRG9jdW1lbnRPdXRwdXRFbGVtZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBSZXR1cm5WYWx1ZUVsZW1lbnQgZXh0ZW5kcyBJbnRlcmFjdGl2ZURvY3VtZW50T3V0cHV0RWxlbWVudCB7XHJcbiAgICBkYXRhOiB7IFtrZXk6IHN0cmluZ106IGFueTsgfTtcclxuICAgIGV4ZWN1dGlvbk9yZGVyOiBudW1iZXI7XHJcbiAgICBtZXRhZGF0YTogeyBba2V5OiBzdHJpbmddOiBhbnk7IH07XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgVGV4dEVsZW1lbnQgZXh0ZW5kcyBJbnRlcmFjdGl2ZURvY3VtZW50T3V0cHV0RWxlbWVudCB7XHJcbiAgICBuYW1lOiBzdHJpbmc7XHJcbiAgICB0ZXh0OiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgRXJyb3JFbGVtZW50IGV4dGVuZHMgSW50ZXJhY3RpdmVEb2N1bWVudE91dHB1dEVsZW1lbnQge1xyXG4gICAgZXJyb3JOYW1lOiBzdHJpbmc7XHJcbiAgICBlcnJvclZhbHVlOiBzdHJpbmc7XHJcbiAgICBzdGFja1RyYWNlOiBBcnJheTxzdHJpbmc+O1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIERvY3VtZW50S2VybmVsSW5mbyB7XHJcbiAgICBhbGlhc2VzOiBBcnJheTxzdHJpbmc+O1xyXG4gICAgbGFuZ3VhZ2VOYW1lPzogc3RyaW5nO1xyXG4gICAgbmFtZTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIE5vdGVib29rUGFyc2VSZXF1ZXN0IGV4dGVuZHMgTm90ZWJvb2tQYXJzZU9yU2VyaWFsaXplUmVxdWVzdCB7XHJcbiAgICByYXdEYXRhOiBVaW50OEFycmF5O1xyXG4gICAgdHlwZTogUmVxdWVzdFR5cGU7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgTm90ZWJvb2tQYXJzZU9yU2VyaWFsaXplUmVxdWVzdCB7XHJcbiAgICBkZWZhdWx0TGFuZ3VhZ2U6IHN0cmluZztcclxuICAgIGlkOiBzdHJpbmc7XHJcbiAgICBzZXJpYWxpemF0aW9uVHlwZTogRG9jdW1lbnRTZXJpYWxpemF0aW9uVHlwZTtcclxuICAgIHR5cGU6IFJlcXVlc3RUeXBlO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIE5vdGVib29rU2VyaWFsaXplUmVxdWVzdCBleHRlbmRzIE5vdGVib29rUGFyc2VPclNlcmlhbGl6ZVJlcXVlc3Qge1xyXG4gICAgZG9jdW1lbnQ6IEludGVyYWN0aXZlRG9jdW1lbnQ7XHJcbiAgICBuZXdMaW5lOiBzdHJpbmc7XHJcbiAgICB0eXBlOiBSZXF1ZXN0VHlwZTtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBOb3RlYm9va1BhcnNlUmVzcG9uc2UgZXh0ZW5kcyBOb3RlYm9va1BhcnNlclNlcnZlclJlc3BvbnNlIHtcclxuICAgIGRvY3VtZW50OiBJbnRlcmFjdGl2ZURvY3VtZW50O1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIE5vdGVib29rUGFyc2VyU2VydmVyUmVzcG9uc2Uge1xyXG4gICAgaWQ6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBOb3RlYm9va1NlcmlhbGl6ZVJlc3BvbnNlIGV4dGVuZHMgTm90ZWJvb2tQYXJzZXJTZXJ2ZXJSZXNwb25zZSB7XHJcbiAgICByYXdEYXRhOiBVaW50OEFycmF5O1xyXG59XHJcblxyXG4vLyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gS2VybmVsIGV2ZW50c1xyXG5cclxuZXhwb3J0IGNvbnN0IEFzc2VtYmx5UHJvZHVjZWRUeXBlID0gXCJBc3NlbWJseVByb2R1Y2VkXCI7XHJcbmV4cG9ydCBjb25zdCBDb2RlU3VibWlzc2lvblJlY2VpdmVkVHlwZSA9IFwiQ29kZVN1Ym1pc3Npb25SZWNlaXZlZFwiO1xyXG5leHBvcnQgY29uc3QgQ29tbWFuZEZhaWxlZFR5cGUgPSBcIkNvbW1hbmRGYWlsZWRcIjtcclxuZXhwb3J0IGNvbnN0IENvbW1hbmRTdWNjZWVkZWRUeXBlID0gXCJDb21tYW5kU3VjY2VlZGVkXCI7XHJcbmV4cG9ydCBjb25zdCBDb21wbGV0ZUNvZGVTdWJtaXNzaW9uUmVjZWl2ZWRUeXBlID0gXCJDb21wbGV0ZUNvZGVTdWJtaXNzaW9uUmVjZWl2ZWRcIjtcclxuZXhwb3J0IGNvbnN0IENvbXBsZXRpb25zUHJvZHVjZWRUeXBlID0gXCJDb21wbGV0aW9uc1Byb2R1Y2VkXCI7XHJcbmV4cG9ydCBjb25zdCBEaWFnbm9zdGljc1Byb2R1Y2VkVHlwZSA9IFwiRGlhZ25vc3RpY3NQcm9kdWNlZFwiO1xyXG5leHBvcnQgY29uc3QgRGlzcGxheWVkVmFsdWVQcm9kdWNlZFR5cGUgPSBcIkRpc3BsYXllZFZhbHVlUHJvZHVjZWRcIjtcclxuZXhwb3J0IGNvbnN0IERpc3BsYXllZFZhbHVlVXBkYXRlZFR5cGUgPSBcIkRpc3BsYXllZFZhbHVlVXBkYXRlZFwiO1xyXG5leHBvcnQgY29uc3QgRG9jdW1lbnRPcGVuZWRUeXBlID0gXCJEb2N1bWVudE9wZW5lZFwiO1xyXG5leHBvcnQgY29uc3QgRXJyb3JQcm9kdWNlZFR5cGUgPSBcIkVycm9yUHJvZHVjZWRcIjtcclxuZXhwb3J0IGNvbnN0IEhvdmVyVGV4dFByb2R1Y2VkVHlwZSA9IFwiSG92ZXJUZXh0UHJvZHVjZWRcIjtcclxuZXhwb3J0IGNvbnN0IEluY29tcGxldGVDb2RlU3VibWlzc2lvblJlY2VpdmVkVHlwZSA9IFwiSW5jb21wbGV0ZUNvZGVTdWJtaXNzaW9uUmVjZWl2ZWRcIjtcclxuZXhwb3J0IGNvbnN0IElucHV0UHJvZHVjZWRUeXBlID0gXCJJbnB1dFByb2R1Y2VkXCI7XHJcbmV4cG9ydCBjb25zdCBJbnB1dHNQcm9kdWNlZFR5cGUgPSBcIklucHV0c1Byb2R1Y2VkXCI7XHJcbmV4cG9ydCBjb25zdCBLZXJuZWxFeHRlbnNpb25Mb2FkZWRUeXBlID0gXCJLZXJuZWxFeHRlbnNpb25Mb2FkZWRcIjtcclxuZXhwb3J0IGNvbnN0IEtlcm5lbEluZm9Qcm9kdWNlZFR5cGUgPSBcIktlcm5lbEluZm9Qcm9kdWNlZFwiO1xyXG5leHBvcnQgY29uc3QgS2VybmVsUmVhZHlUeXBlID0gXCJLZXJuZWxSZWFkeVwiO1xyXG5leHBvcnQgY29uc3QgUGFja2FnZUFkZGVkVHlwZSA9IFwiUGFja2FnZUFkZGVkXCI7XHJcbmV4cG9ydCBjb25zdCBQcm9qZWN0T3BlbmVkVHlwZSA9IFwiUHJvamVjdE9wZW5lZFwiO1xyXG5leHBvcnQgY29uc3QgUmV0dXJuVmFsdWVQcm9kdWNlZFR5cGUgPSBcIlJldHVyblZhbHVlUHJvZHVjZWRcIjtcclxuZXhwb3J0IGNvbnN0IFNpZ25hdHVyZUhlbHBQcm9kdWNlZFR5cGUgPSBcIlNpZ25hdHVyZUhlbHBQcm9kdWNlZFwiO1xyXG5leHBvcnQgY29uc3QgU3RhbmRhcmRFcnJvclZhbHVlUHJvZHVjZWRUeXBlID0gXCJTdGFuZGFyZEVycm9yVmFsdWVQcm9kdWNlZFwiO1xyXG5leHBvcnQgY29uc3QgU3RhbmRhcmRPdXRwdXRWYWx1ZVByb2R1Y2VkVHlwZSA9IFwiU3RhbmRhcmRPdXRwdXRWYWx1ZVByb2R1Y2VkXCI7XHJcbmV4cG9ydCBjb25zdCBWYWx1ZUluZm9zUHJvZHVjZWRUeXBlID0gXCJWYWx1ZUluZm9zUHJvZHVjZWRcIjtcclxuZXhwb3J0IGNvbnN0IFZhbHVlUHJvZHVjZWRUeXBlID0gXCJWYWx1ZVByb2R1Y2VkXCI7XHJcblxyXG5leHBvcnQgdHlwZSBLZXJuZWxFdmVudFR5cGUgPVxyXG4gICAgICB0eXBlb2YgQXNzZW1ibHlQcm9kdWNlZFR5cGVcclxuICAgIHwgdHlwZW9mIENvZGVTdWJtaXNzaW9uUmVjZWl2ZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBDb21tYW5kRmFpbGVkVHlwZVxyXG4gICAgfCB0eXBlb2YgQ29tbWFuZFN1Y2NlZWRlZFR5cGVcclxuICAgIHwgdHlwZW9mIENvbXBsZXRlQ29kZVN1Ym1pc3Npb25SZWNlaXZlZFR5cGVcclxuICAgIHwgdHlwZW9mIENvbXBsZXRpb25zUHJvZHVjZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBEaWFnbm9zdGljc1Byb2R1Y2VkVHlwZVxyXG4gICAgfCB0eXBlb2YgRGlzcGxheWVkVmFsdWVQcm9kdWNlZFR5cGVcclxuICAgIHwgdHlwZW9mIERpc3BsYXllZFZhbHVlVXBkYXRlZFR5cGVcclxuICAgIHwgdHlwZW9mIERvY3VtZW50T3BlbmVkVHlwZVxyXG4gICAgfCB0eXBlb2YgRXJyb3JQcm9kdWNlZFR5cGVcclxuICAgIHwgdHlwZW9mIEhvdmVyVGV4dFByb2R1Y2VkVHlwZVxyXG4gICAgfCB0eXBlb2YgSW5jb21wbGV0ZUNvZGVTdWJtaXNzaW9uUmVjZWl2ZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBJbnB1dFByb2R1Y2VkVHlwZVxyXG4gICAgfCB0eXBlb2YgSW5wdXRzUHJvZHVjZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBLZXJuZWxFeHRlbnNpb25Mb2FkZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBLZXJuZWxJbmZvUHJvZHVjZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBLZXJuZWxSZWFkeVR5cGVcclxuICAgIHwgdHlwZW9mIFBhY2thZ2VBZGRlZFR5cGVcclxuICAgIHwgdHlwZW9mIFByb2plY3RPcGVuZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBSZXR1cm5WYWx1ZVByb2R1Y2VkVHlwZVxyXG4gICAgfCB0eXBlb2YgU2lnbmF0dXJlSGVscFByb2R1Y2VkVHlwZVxyXG4gICAgfCB0eXBlb2YgU3RhbmRhcmRFcnJvclZhbHVlUHJvZHVjZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBTdGFuZGFyZE91dHB1dFZhbHVlUHJvZHVjZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBWYWx1ZUluZm9zUHJvZHVjZWRUeXBlXHJcbiAgICB8IHR5cGVvZiBWYWx1ZVByb2R1Y2VkVHlwZTtcclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgQXNzZW1ibHlQcm9kdWNlZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIGFzc2VtYmx5OiBCYXNlNjRFbmNvZGVkQXNzZW1ibHk7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgQ29kZVN1Ym1pc3Npb25SZWNlaXZlZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIGNvZGU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBDb21tYW5kRmFpbGVkIGV4dGVuZHMgS2VybmVsQ29tbWFuZENvbXBsZXRpb25FdmVudCB7XHJcbiAgICBtZXNzYWdlOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgS2VybmVsQ29tbWFuZENvbXBsZXRpb25FdmVudCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIGV4ZWN1dGlvbk9yZGVyPzogbnVtYmVyO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIENvbW1hbmRTdWNjZWVkZWQgZXh0ZW5kcyBLZXJuZWxDb21tYW5kQ29tcGxldGlvbkV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBDb21wbGV0ZUNvZGVTdWJtaXNzaW9uUmVjZWl2ZWQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBjb2RlOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgQ29tcGxldGlvbnNQcm9kdWNlZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIGNvbXBsZXRpb25zOiBBcnJheTxDb21wbGV0aW9uSXRlbT47XHJcbiAgICBsaW5lUG9zaXRpb25TcGFuPzogTGluZVBvc2l0aW9uU3BhbjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBEaWFnbm9zdGljc1Byb2R1Y2VkIGV4dGVuZHMgS2VybmVsRXZlbnQge1xyXG4gICAgZGlhZ25vc3RpY3M6IEFycmF5PERpYWdub3N0aWM+O1xyXG4gICAgZm9ybWF0dGVkRGlhZ25vc3RpY3M6IEFycmF5PEZvcm1hdHRlZFZhbHVlPjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBEaXNwbGF5ZWRWYWx1ZVByb2R1Y2VkIGV4dGVuZHMgRGlzcGxheUV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBEaXNwbGF5RXZlbnQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBmb3JtYXR0ZWRWYWx1ZXM6IEFycmF5PEZvcm1hdHRlZFZhbHVlPjtcclxuICAgIHZhbHVlSWQ/OiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgRGlzcGxheWVkVmFsdWVVcGRhdGVkIGV4dGVuZHMgRGlzcGxheUV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBEb2N1bWVudE9wZW5lZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIGNvbnRlbnQ6IHN0cmluZztcclxuICAgIHJlZ2lvbk5hbWU/OiBzdHJpbmc7XHJcbiAgICByZWxhdGl2ZUZpbGVQYXRoOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgRXJyb3JQcm9kdWNlZCBleHRlbmRzIERpc3BsYXlFdmVudCB7XHJcbiAgICBtZXNzYWdlOiBzdHJpbmc7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgSG92ZXJUZXh0UHJvZHVjZWQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBjb250ZW50OiBBcnJheTxGb3JtYXR0ZWRWYWx1ZT47XHJcbiAgICBsaW5lUG9zaXRpb25TcGFuPzogTGluZVBvc2l0aW9uU3BhbjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBJbmNvbXBsZXRlQ29kZVN1Ym1pc3Npb25SZWNlaXZlZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBJbnB1dFByb2R1Y2VkIGV4dGVuZHMgS2VybmVsRXZlbnQge1xyXG4gICAgdmFsdWU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBJbnB1dHNQcm9kdWNlZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIHZhbHVlczogeyBba2V5OiBzdHJpbmddOiBzdHJpbmc7IH07XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgS2VybmVsRXh0ZW5zaW9uTG9hZGVkIGV4dGVuZHMgS2VybmVsRXZlbnQge1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEtlcm5lbEluZm9Qcm9kdWNlZCBleHRlbmRzIEtlcm5lbEV2ZW50IHtcclxuICAgIGtlcm5lbEluZm86IEtlcm5lbEluZm87XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgS2VybmVsUmVhZHkgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBrZXJuZWxJbmZvczogQXJyYXk8S2VybmVsSW5mbz47XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgUGFja2FnZUFkZGVkIGV4dGVuZHMgS2VybmVsRXZlbnQge1xyXG4gICAgcGFja2FnZVJlZmVyZW5jZTogUmVzb2x2ZWRQYWNrYWdlUmVmZXJlbmNlO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFByb2plY3RPcGVuZWQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBwcm9qZWN0SXRlbXM6IEFycmF5PFByb2plY3RJdGVtPjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBSZXR1cm5WYWx1ZVByb2R1Y2VkIGV4dGVuZHMgRGlzcGxheUV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBTaWduYXR1cmVIZWxwUHJvZHVjZWQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBhY3RpdmVQYXJhbWV0ZXJJbmRleDogbnVtYmVyO1xyXG4gICAgYWN0aXZlU2lnbmF0dXJlSW5kZXg6IG51bWJlcjtcclxuICAgIHNpZ25hdHVyZXM6IEFycmF5PFNpZ25hdHVyZUluZm9ybWF0aW9uPjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBTdGFuZGFyZEVycm9yVmFsdWVQcm9kdWNlZCBleHRlbmRzIERpc3BsYXlFdmVudCB7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgU3RhbmRhcmRPdXRwdXRWYWx1ZVByb2R1Y2VkIGV4dGVuZHMgRGlzcGxheUV2ZW50IHtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBWYWx1ZUluZm9zUHJvZHVjZWQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICB2YWx1ZUluZm9zOiBBcnJheTxLZXJuZWxWYWx1ZUluZm8+O1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFZhbHVlUHJvZHVjZWQgZXh0ZW5kcyBLZXJuZWxFdmVudCB7XHJcbiAgICBmb3JtYXR0ZWRWYWx1ZTogRm9ybWF0dGVkVmFsdWU7XHJcbiAgICBuYW1lOiBzdHJpbmc7XHJcbn1cclxuXHJcbi8vIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBSZXF1aXJlZCBUeXBlc1xyXG5cclxuZXhwb3J0IGludGVyZmFjZSBCYXNlNjRFbmNvZGVkQXNzZW1ibHkge1xyXG4gICAgdmFsdWU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBDb21wbGV0aW9uSXRlbSB7XHJcbiAgICBkaXNwbGF5VGV4dDogc3RyaW5nO1xyXG4gICAgZG9jdW1lbnRhdGlvbjogc3RyaW5nO1xyXG4gICAgZmlsdGVyVGV4dDogc3RyaW5nO1xyXG4gICAgaW5zZXJ0VGV4dDogc3RyaW5nO1xyXG4gICAgaW5zZXJ0VGV4dEZvcm1hdD86IEluc2VydFRleHRGb3JtYXQ7XHJcbiAgICBraW5kOiBzdHJpbmc7XHJcbiAgICBzb3J0VGV4dDogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgZW51bSBJbnNlcnRUZXh0Rm9ybWF0IHtcclxuICAgIFBsYWluVGV4dCA9IFwicGxhaW50ZXh0XCIsXHJcbiAgICBTbmlwcGV0ID0gXCJzbmlwcGV0XCIsXHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgRGlhZ25vc3RpYyB7XHJcbiAgICBjb2RlOiBzdHJpbmc7XHJcbiAgICBsaW5lUG9zaXRpb25TcGFuOiBMaW5lUG9zaXRpb25TcGFuO1xyXG4gICAgbWVzc2FnZTogc3RyaW5nO1xyXG4gICAgc2V2ZXJpdHk6IERpYWdub3N0aWNTZXZlcml0eTtcclxufVxyXG5cclxuZXhwb3J0IGVudW0gRGlhZ25vc3RpY1NldmVyaXR5IHtcclxuICAgIEhpZGRlbiA9IFwiaGlkZGVuXCIsXHJcbiAgICBJbmZvID0gXCJpbmZvXCIsXHJcbiAgICBXYXJuaW5nID0gXCJ3YXJuaW5nXCIsXHJcbiAgICBFcnJvciA9IFwiZXJyb3JcIixcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBMaW5lUG9zaXRpb25TcGFuIHtcclxuICAgIGVuZDogTGluZVBvc2l0aW9uO1xyXG4gICAgc3RhcnQ6IExpbmVQb3NpdGlvbjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBMaW5lUG9zaXRpb24ge1xyXG4gICAgY2hhcmFjdGVyOiBudW1iZXI7XHJcbiAgICBsaW5lOiBudW1iZXI7XHJcbn1cclxuXHJcbmV4cG9ydCBlbnVtIERvY3VtZW50U2VyaWFsaXphdGlvblR5cGUge1xyXG4gICAgRGliID0gXCJkaWJcIixcclxuICAgIElweW5iID0gXCJpcHluYlwiLFxyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEZvcm1hdHRlZFZhbHVlIHtcclxuICAgIG1pbWVUeXBlOiBzdHJpbmc7XHJcbiAgICBzdXBwcmVzc0Rpc3BsYXk6IGJvb2xlYW47XHJcbiAgICB2YWx1ZTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIElucHV0RGVzY3JpcHRpb24ge1xyXG4gICAgbmFtZTogc3RyaW5nO1xyXG4gICAgcHJvbXB0OiBzdHJpbmc7XHJcbiAgICBzYXZlQXM6IHN0cmluZztcclxuICAgIHR5cGU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBJbnRlcmFjdGl2ZURvY3VtZW50IHtcclxuICAgIGVsZW1lbnRzOiBBcnJheTxJbnRlcmFjdGl2ZURvY3VtZW50RWxlbWVudD47XHJcbiAgICBtZXRhZGF0YTogeyBba2V5OiBzdHJpbmddOiBhbnk7IH07XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgSW50ZXJhY3RpdmVEb2N1bWVudEVsZW1lbnQge1xyXG4gICAgY29udGVudHM6IHN0cmluZztcclxuICAgIGV4ZWN1dGlvbk9yZGVyOiBudW1iZXI7XHJcbiAgICBpZD86IHN0cmluZztcclxuICAgIGtlcm5lbE5hbWU/OiBzdHJpbmc7XHJcbiAgICBtZXRhZGF0YT86IHsgW2tleTogc3RyaW5nXTogYW55OyB9O1xyXG4gICAgb3V0cHV0czogQXJyYXk8SW50ZXJhY3RpdmVEb2N1bWVudE91dHB1dEVsZW1lbnQ+O1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEtlcm5lbEluZm8ge1xyXG4gICAgYWxpYXNlczogQXJyYXk8c3RyaW5nPjtcclxuICAgIGRlc2NyaXB0aW9uPzogc3RyaW5nO1xyXG4gICAgZGlzcGxheU5hbWU6IHN0cmluZztcclxuICAgIGlzQ29tcG9zaXRlOiBib29sZWFuO1xyXG4gICAgaXNQcm94eTogYm9vbGVhbjtcclxuICAgIGxhbmd1YWdlTmFtZT86IHN0cmluZztcclxuICAgIGxhbmd1YWdlVmVyc2lvbj86IHN0cmluZztcclxuICAgIGxvY2FsTmFtZTogc3RyaW5nO1xyXG4gICAgcmVtb3RlVXJpPzogc3RyaW5nO1xyXG4gICAgc3VwcG9ydGVkS2VybmVsQ29tbWFuZHM6IEFycmF5PEtlcm5lbENvbW1hbmRJbmZvPjtcclxuICAgIHVyaTogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEtlcm5lbENvbW1hbmRJbmZvIHtcclxuICAgIG5hbWU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBLZXJuZWxWYWx1ZUluZm8ge1xyXG4gICAgZm9ybWF0dGVkVmFsdWU6IEZvcm1hdHRlZFZhbHVlO1xyXG4gICAgbmFtZTogc3RyaW5nO1xyXG4gICAgcHJlZmVycmVkTWltZVR5cGVzOiBBcnJheTxzdHJpbmc+O1xyXG4gICAgdHlwZU5hbWU6IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBQcm9qZWN0IHtcclxuICAgIGZpbGVzOiBBcnJheTxQcm9qZWN0RmlsZT47XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgUHJvamVjdEZpbGUge1xyXG4gICAgY29udGVudDogc3RyaW5nO1xyXG4gICAgcmVsYXRpdmVGaWxlUGF0aDogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIFByb2plY3RJdGVtIHtcclxuICAgIHJlZ2lvbk5hbWVzOiBBcnJheTxzdHJpbmc+O1xyXG4gICAgcmVnaW9uc0NvbnRlbnQ6IHsgW2tleTogc3RyaW5nXTogc3RyaW5nOyB9O1xyXG4gICAgcmVsYXRpdmVGaWxlUGF0aDogc3RyaW5nO1xyXG59XHJcblxyXG5leHBvcnQgZW51bSBSZXF1ZXN0VHlwZSB7XHJcbiAgICBQYXJzZSA9IFwicGFyc2VcIixcclxuICAgIFNlcmlhbGl6ZSA9IFwic2VyaWFsaXplXCIsXHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgUmVzb2x2ZWRQYWNrYWdlUmVmZXJlbmNlIGV4dGVuZHMgUGFja2FnZVJlZmVyZW5jZSB7XHJcbiAgICBhc3NlbWJseVBhdGhzOiBBcnJheTxzdHJpbmc+O1xyXG4gICAgcGFja2FnZVJvb3Q6IHN0cmluZztcclxuICAgIHByb2JpbmdQYXRoczogQXJyYXk8c3RyaW5nPjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBQYWNrYWdlUmVmZXJlbmNlIHtcclxuICAgIGlzUGFja2FnZVZlcnNpb25TcGVjaWZpZWQ6IGJvb2xlYW47XHJcbiAgICBwYWNrYWdlTmFtZTogc3RyaW5nO1xyXG4gICAgcGFja2FnZVZlcnNpb246IHN0cmluZztcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBTaWduYXR1cmVJbmZvcm1hdGlvbiB7XHJcbiAgICBkb2N1bWVudGF0aW9uOiBGb3JtYXR0ZWRWYWx1ZTtcclxuICAgIGxhYmVsOiBzdHJpbmc7XHJcbiAgICBwYXJhbWV0ZXJzOiBBcnJheTxQYXJhbWV0ZXJJbmZvcm1hdGlvbj47XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgUGFyYW1ldGVySW5mb3JtYXRpb24ge1xyXG4gICAgZG9jdW1lbnRhdGlvbjogRm9ybWF0dGVkVmFsdWU7XHJcbiAgICBsYWJlbDogc3RyaW5nO1xyXG59XHJcblxyXG4iLCIvLyBVbmlxdWUgSUQgY3JlYXRpb24gcmVxdWlyZXMgYSBoaWdoIHF1YWxpdHkgcmFuZG9tICMgZ2VuZXJhdG9yLiBJbiB0aGUgYnJvd3NlciB3ZSB0aGVyZWZvcmVcbi8vIHJlcXVpcmUgdGhlIGNyeXB0byBBUEkgYW5kIGRvIG5vdCBzdXBwb3J0IGJ1aWx0LWluIGZhbGxiYWNrIHRvIGxvd2VyIHF1YWxpdHkgcmFuZG9tIG51bWJlclxuLy8gZ2VuZXJhdG9ycyAobGlrZSBNYXRoLnJhbmRvbSgpKS5cbnZhciBnZXRSYW5kb21WYWx1ZXM7XG52YXIgcm5kczggPSBuZXcgVWludDhBcnJheSgxNik7XG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBybmcoKSB7XG4gIC8vIGxhenkgbG9hZCBzbyB0aGF0IGVudmlyb25tZW50cyB0aGF0IG5lZWQgdG8gcG9seWZpbGwgaGF2ZSBhIGNoYW5jZSB0byBkbyBzb1xuICBpZiAoIWdldFJhbmRvbVZhbHVlcykge1xuICAgIC8vIGdldFJhbmRvbVZhbHVlcyBuZWVkcyB0byBiZSBpbnZva2VkIGluIGEgY29udGV4dCB3aGVyZSBcInRoaXNcIiBpcyBhIENyeXB0byBpbXBsZW1lbnRhdGlvbi4gQWxzbyxcbiAgICAvLyBmaW5kIHRoZSBjb21wbGV0ZSBpbXBsZW1lbnRhdGlvbiBvZiBjcnlwdG8gKG1zQ3J5cHRvKSBvbiBJRTExLlxuICAgIGdldFJhbmRvbVZhbHVlcyA9IHR5cGVvZiBjcnlwdG8gIT09ICd1bmRlZmluZWQnICYmIGNyeXB0by5nZXRSYW5kb21WYWx1ZXMgJiYgY3J5cHRvLmdldFJhbmRvbVZhbHVlcy5iaW5kKGNyeXB0bykgfHwgdHlwZW9mIG1zQ3J5cHRvICE9PSAndW5kZWZpbmVkJyAmJiB0eXBlb2YgbXNDcnlwdG8uZ2V0UmFuZG9tVmFsdWVzID09PSAnZnVuY3Rpb24nICYmIG1zQ3J5cHRvLmdldFJhbmRvbVZhbHVlcy5iaW5kKG1zQ3J5cHRvKTtcblxuICAgIGlmICghZ2V0UmFuZG9tVmFsdWVzKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoJ2NyeXB0by5nZXRSYW5kb21WYWx1ZXMoKSBub3Qgc3VwcG9ydGVkLiBTZWUgaHR0cHM6Ly9naXRodWIuY29tL3V1aWRqcy91dWlkI2dldHJhbmRvbXZhbHVlcy1ub3Qtc3VwcG9ydGVkJyk7XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIGdldFJhbmRvbVZhbHVlcyhybmRzOCk7XG59IiwiZXhwb3J0IGRlZmF1bHQgL14oPzpbMC05YS1mXXs4fS1bMC05YS1mXXs0fS1bMS01XVswLTlhLWZdezN9LVs4OWFiXVswLTlhLWZdezN9LVswLTlhLWZdezEyfXwwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApJC9pOyIsImltcG9ydCBSRUdFWCBmcm9tICcuL3JlZ2V4LmpzJztcblxuZnVuY3Rpb24gdmFsaWRhdGUodXVpZCkge1xuICByZXR1cm4gdHlwZW9mIHV1aWQgPT09ICdzdHJpbmcnICYmIFJFR0VYLnRlc3QodXVpZCk7XG59XG5cbmV4cG9ydCBkZWZhdWx0IHZhbGlkYXRlOyIsImltcG9ydCB2YWxpZGF0ZSBmcm9tICcuL3ZhbGlkYXRlLmpzJztcbi8qKlxuICogQ29udmVydCBhcnJheSBvZiAxNiBieXRlIHZhbHVlcyB0byBVVUlEIHN0cmluZyBmb3JtYXQgb2YgdGhlIGZvcm06XG4gKiBYWFhYWFhYWC1YWFhYLVhYWFgtWFhYWC1YWFhYWFhYWFhYWFhcbiAqL1xuXG52YXIgYnl0ZVRvSGV4ID0gW107XG5cbmZvciAodmFyIGkgPSAwOyBpIDwgMjU2OyArK2kpIHtcbiAgYnl0ZVRvSGV4LnB1c2goKGkgKyAweDEwMCkudG9TdHJpbmcoMTYpLnN1YnN0cigxKSk7XG59XG5cbmZ1bmN0aW9uIHN0cmluZ2lmeShhcnIpIHtcbiAgdmFyIG9mZnNldCA9IGFyZ3VtZW50cy5sZW5ndGggPiAxICYmIGFyZ3VtZW50c1sxXSAhPT0gdW5kZWZpbmVkID8gYXJndW1lbnRzWzFdIDogMDtcbiAgLy8gTm90ZTogQmUgY2FyZWZ1bCBlZGl0aW5nIHRoaXMgY29kZSEgIEl0J3MgYmVlbiB0dW5lZCBmb3IgcGVyZm9ybWFuY2VcbiAgLy8gYW5kIHdvcmtzIGluIHdheXMgeW91IG1heSBub3QgZXhwZWN0LiBTZWUgaHR0cHM6Ly9naXRodWIuY29tL3V1aWRqcy91dWlkL3B1bGwvNDM0XG4gIHZhciB1dWlkID0gKGJ5dGVUb0hleFthcnJbb2Zmc2V0ICsgMF1dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxXV0gKyBieXRlVG9IZXhbYXJyW29mZnNldCArIDJdXSArIGJ5dGVUb0hleFthcnJbb2Zmc2V0ICsgM11dICsgJy0nICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyA0XV0gKyBieXRlVG9IZXhbYXJyW29mZnNldCArIDVdXSArICctJyArIGJ5dGVUb0hleFthcnJbb2Zmc2V0ICsgNl1dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyA3XV0gKyAnLScgKyBieXRlVG9IZXhbYXJyW29mZnNldCArIDhdXSArIGJ5dGVUb0hleFthcnJbb2Zmc2V0ICsgOV1dICsgJy0nICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxMF1dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxMV1dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxMl1dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxM11dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxNF1dICsgYnl0ZVRvSGV4W2FycltvZmZzZXQgKyAxNV1dKS50b0xvd2VyQ2FzZSgpOyAvLyBDb25zaXN0ZW5jeSBjaGVjayBmb3IgdmFsaWQgVVVJRC4gIElmIHRoaXMgdGhyb3dzLCBpdCdzIGxpa2VseSBkdWUgdG8gb25lXG4gIC8vIG9mIHRoZSBmb2xsb3dpbmc6XG4gIC8vIC0gT25lIG9yIG1vcmUgaW5wdXQgYXJyYXkgdmFsdWVzIGRvbid0IG1hcCB0byBhIGhleCBvY3RldCAobGVhZGluZyB0b1xuICAvLyBcInVuZGVmaW5lZFwiIGluIHRoZSB1dWlkKVxuICAvLyAtIEludmFsaWQgaW5wdXQgdmFsdWVzIGZvciB0aGUgUkZDIGB2ZXJzaW9uYCBvciBgdmFyaWFudGAgZmllbGRzXG5cbiAgaWYgKCF2YWxpZGF0ZSh1dWlkKSkge1xuICAgIHRocm93IFR5cGVFcnJvcignU3RyaW5naWZpZWQgVVVJRCBpcyBpbnZhbGlkJyk7XG4gIH1cblxuICByZXR1cm4gdXVpZDtcbn1cblxuZXhwb3J0IGRlZmF1bHQgc3RyaW5naWZ5OyIsImltcG9ydCB2YWxpZGF0ZSBmcm9tICcuL3ZhbGlkYXRlLmpzJztcblxuZnVuY3Rpb24gcGFyc2UodXVpZCkge1xuICBpZiAoIXZhbGlkYXRlKHV1aWQpKSB7XG4gICAgdGhyb3cgVHlwZUVycm9yKCdJbnZhbGlkIFVVSUQnKTtcbiAgfVxuXG4gIHZhciB2O1xuICB2YXIgYXJyID0gbmV3IFVpbnQ4QXJyYXkoMTYpOyAvLyBQYXJzZSAjIyMjIyMjIy0uLi4uLS4uLi4tLi4uLi0uLi4uLi4uLi4uLi5cblxuICBhcnJbMF0gPSAodiA9IHBhcnNlSW50KHV1aWQuc2xpY2UoMCwgOCksIDE2KSkgPj4+IDI0O1xuICBhcnJbMV0gPSB2ID4+PiAxNiAmIDB4ZmY7XG4gIGFyclsyXSA9IHYgPj4+IDggJiAweGZmO1xuICBhcnJbM10gPSB2ICYgMHhmZjsgLy8gUGFyc2UgLi4uLi4uLi4tIyMjIy0uLi4uLS4uLi4tLi4uLi4uLi4uLi4uXG5cbiAgYXJyWzRdID0gKHYgPSBwYXJzZUludCh1dWlkLnNsaWNlKDksIDEzKSwgMTYpKSA+Pj4gODtcbiAgYXJyWzVdID0gdiAmIDB4ZmY7IC8vIFBhcnNlIC4uLi4uLi4uLS4uLi4tIyMjIy0uLi4uLS4uLi4uLi4uLi4uLlxuXG4gIGFycls2XSA9ICh2ID0gcGFyc2VJbnQodXVpZC5zbGljZSgxNCwgMTgpLCAxNikpID4+PiA4O1xuICBhcnJbN10gPSB2ICYgMHhmZjsgLy8gUGFyc2UgLi4uLi4uLi4tLi4uLi0uLi4uLSMjIyMtLi4uLi4uLi4uLi4uXG5cbiAgYXJyWzhdID0gKHYgPSBwYXJzZUludCh1dWlkLnNsaWNlKDE5LCAyMyksIDE2KSkgPj4+IDg7XG4gIGFycls5XSA9IHYgJiAweGZmOyAvLyBQYXJzZSAuLi4uLi4uLi0uLi4uLS4uLi4tLi4uLi0jIyMjIyMjIyMjIyNcbiAgLy8gKFVzZSBcIi9cIiB0byBhdm9pZCAzMi1iaXQgdHJ1bmNhdGlvbiB3aGVuIGJpdC1zaGlmdGluZyBoaWdoLW9yZGVyIGJ5dGVzKVxuXG4gIGFyclsxMF0gPSAodiA9IHBhcnNlSW50KHV1aWQuc2xpY2UoMjQsIDM2KSwgMTYpKSAvIDB4MTAwMDAwMDAwMDAgJiAweGZmO1xuICBhcnJbMTFdID0gdiAvIDB4MTAwMDAwMDAwICYgMHhmZjtcbiAgYXJyWzEyXSA9IHYgPj4+IDI0ICYgMHhmZjtcbiAgYXJyWzEzXSA9IHYgPj4+IDE2ICYgMHhmZjtcbiAgYXJyWzE0XSA9IHYgPj4+IDggJiAweGZmO1xuICBhcnJbMTVdID0gdiAmIDB4ZmY7XG4gIHJldHVybiBhcnI7XG59XG5cbmV4cG9ydCBkZWZhdWx0IHBhcnNlOyIsImltcG9ydCBybmcgZnJvbSAnLi9ybmcuanMnO1xuaW1wb3J0IHN0cmluZ2lmeSBmcm9tICcuL3N0cmluZ2lmeS5qcyc7XG5cbmZ1bmN0aW9uIHY0KG9wdGlvbnMsIGJ1Ziwgb2Zmc2V0KSB7XG4gIG9wdGlvbnMgPSBvcHRpb25zIHx8IHt9O1xuICB2YXIgcm5kcyA9IG9wdGlvbnMucmFuZG9tIHx8IChvcHRpb25zLnJuZyB8fCBybmcpKCk7IC8vIFBlciA0LjQsIHNldCBiaXRzIGZvciB2ZXJzaW9uIGFuZCBgY2xvY2tfc2VxX2hpX2FuZF9yZXNlcnZlZGBcblxuICBybmRzWzZdID0gcm5kc1s2XSAmIDB4MGYgfCAweDQwO1xuICBybmRzWzhdID0gcm5kc1s4XSAmIDB4M2YgfCAweDgwOyAvLyBDb3B5IGJ5dGVzIHRvIGJ1ZmZlciwgaWYgcHJvdmlkZWRcblxuICBpZiAoYnVmKSB7XG4gICAgb2Zmc2V0ID0gb2Zmc2V0IHx8IDA7XG5cbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IDE2OyArK2kpIHtcbiAgICAgIGJ1ZltvZmZzZXQgKyBpXSA9IHJuZHNbaV07XG4gICAgfVxuXG4gICAgcmV0dXJuIGJ1ZjtcbiAgfVxuXG4gIHJldHVybiBzdHJpbmdpZnkocm5kcyk7XG59XG5cbmV4cG9ydCBkZWZhdWx0IHY0OyIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG5pbXBvcnQgKiBhcyBjb250cmFjdHMgZnJvbSBcIi4vY29udHJhY3RzXCI7XHJcbmltcG9ydCB7IENvbW1hbmRSb3V0aW5nU2xpcCwgRXZlbnRSb3V0aW5nU2xpcCB9IGZyb20gXCIuL3JvdXRpbmdzbGlwXCI7XHJcbmV4cG9ydCAqIGZyb20gXCIuL2NvbnRyYWN0c1wiO1xyXG5pbXBvcnQgKiBhcyB1dWlkIGZyb20gXCJ1dWlkXCI7XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIERvY3VtZW50S2VybmVsSW5mb0NvbGxlY3Rpb24ge1xyXG4gICAgZGVmYXVsdEtlcm5lbE5hbWU6IHN0cmluZztcclxuICAgIGl0ZW1zOiBjb250cmFjdHMuRG9jdW1lbnRLZXJuZWxJbmZvW107XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgS2VybmVsRXZlbnRFbnZlbG9wZU1vZGVsIHtcclxuICAgIGV2ZW50VHlwZTogY29udHJhY3RzLktlcm5lbEV2ZW50VHlwZTtcclxuICAgIGV2ZW50OiBjb250cmFjdHMuS2VybmVsRXZlbnQ7XHJcbiAgICBjb21tYW5kPzogS2VybmVsQ29tbWFuZEVudmVsb3BlTW9kZWw7XHJcbiAgICByb3V0aW5nU2xpcD86IHN0cmluZ1tdO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEtlcm5lbENvbW1hbmRFbnZlbG9wZU1vZGVsIHtcclxuICAgIHRva2VuPzogc3RyaW5nO1xyXG4gICAgY29tbWFuZFR5cGU6IGNvbnRyYWN0cy5LZXJuZWxDb21tYW5kVHlwZTtcclxuICAgIGNvbW1hbmQ6IGNvbnRyYWN0cy5LZXJuZWxDb21tYW5kO1xyXG4gICAgcm91dGluZ1NsaXA/OiBzdHJpbmdbXTtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBLZXJuZWxFdmVudEVudmVsb3BlT2JzZXJ2ZXIge1xyXG4gICAgKGV2ZW50RW52ZWxvcGU6IEtlcm5lbEV2ZW50RW52ZWxvcGUpOiB2b2lkO1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIEtlcm5lbENvbW1hbmRFbnZlbG9wZUhhbmRsZXIge1xyXG4gICAgKGV2ZW50RW52ZWxvcGU6IEtlcm5lbENvbW1hbmRFbnZlbG9wZSk6IFByb21pc2U8dm9pZD47XHJcbn1cclxuXHJcbmZ1bmN0aW9uIHRvQmFzZTY0U3RyaW5nKHZhbHVlOiBVaW50OEFycmF5KTogc3RyaW5nIHtcclxuICAgIGNvbnN0IHduZCA9IDxhbnk+KGdsb2JhbFRoaXMud2luZG93KTtcclxuICAgIGlmICh3bmQpIHtcclxuICAgICAgICByZXR1cm4gd25kLmJ0b2EoU3RyaW5nLmZyb21DaGFyQ29kZSguLi52YWx1ZSkpO1xyXG4gICAgfSBlbHNlIHtcclxuICAgICAgICByZXR1cm4gQnVmZmVyLmZyb20odmFsdWUpLnRvU3RyaW5nKCdiYXNlNjQnKTtcclxuICAgIH1cclxufVxyXG5leHBvcnQgY2xhc3MgS2VybmVsQ29tbWFuZEVudmVsb3BlIHtcclxuXHJcbiAgICBwcml2YXRlIF9jaGlsZENvbW1hbmRDb3VudGVyOiBudW1iZXIgPSAxO1xyXG4gICAgcHJpdmF0ZSBfcm91dGluZ1NsaXA6IENvbW1hbmRSb3V0aW5nU2xpcCA9IG5ldyBDb21tYW5kUm91dGluZ1NsaXAoKTtcclxuICAgIHByaXZhdGUgX3Rva2VuPzogc3RyaW5nO1xyXG4gICAgcHJpdmF0ZSBfcGFyZW50Q29tbWFuZD86IEtlcm5lbENvbW1hbmRFbnZlbG9wZTtcclxuXHJcbiAgICBjb25zdHJ1Y3RvcihcclxuICAgICAgICBwdWJsaWMgY29tbWFuZFR5cGU6IGNvbnRyYWN0cy5LZXJuZWxDb21tYW5kVHlwZSxcclxuICAgICAgICBwdWJsaWMgY29tbWFuZDogY29udHJhY3RzLktlcm5lbENvbW1hbmQpIHtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0IHJvdXRpbmdTbGlwKCk6IENvbW1hbmRSb3V0aW5nU2xpcCB7XHJcbiAgICAgICAgcmV0dXJuIHRoaXMuX3JvdXRpbmdTbGlwO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBnZXQgcGFyZW50Q29tbWFuZCgpOiBLZXJuZWxDb21tYW5kRW52ZWxvcGUgfCB1bmRlZmluZWQge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9wYXJlbnRDb21tYW5kO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBzdGF0aWMgaXNLZXJuZWxDb21tYW5kRW52ZWxvcGVNb2RlbChhcmc6IEtlcm5lbENvbW1hbmRFbnZlbG9wZSB8IEtlcm5lbENvbW1hbmRFbnZlbG9wZU1vZGVsKTogYXJnIGlzIEtlcm5lbENvbW1hbmRFbnZlbG9wZU1vZGVsIHtcclxuICAgICAgICByZXR1cm4gISg8YW55PmFyZykuZ2V0T3JDcmVhdGVUb2tlbjtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgc2V0UGFyZW50KHBhcmVudENvbW1hbmQ6IEtlcm5lbENvbW1hbmRFbnZlbG9wZSB8IHVuZGVmaW5lZCkge1xyXG4gICAgICAgIGlmICh0aGlzLl9wYXJlbnRDb21tYW5kICYmIHRoaXMuX3BhcmVudENvbW1hbmQgIT09IHBhcmVudENvbW1hbmQpIHtcclxuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwiUGFyZW50IGNhbm5vdCBiZSBjaGFuZ2VkLlwiKTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmICgodGhpcy5fdG9rZW4gIT09IHVuZGVmaW5lZCAmJiB0aGlzLl90b2tlbiAhPT0gbnVsbCkgJiZcclxuICAgICAgICAgICAgKHBhcmVudENvbW1hbmQ/Ll90b2tlbiAhPT0gdW5kZWZpbmVkICYmIHBhcmVudENvbW1hbmQ/Ll90b2tlbiAhPT0gbnVsbCkgJiZcclxuICAgICAgICAgICAgS2VybmVsQ29tbWFuZEVudmVsb3BlLmdldFJvb3RUb2tlbih0aGlzLl90b2tlbikgIT09IEtlcm5lbENvbW1hbmRFbnZlbG9wZS5nZXRSb290VG9rZW4ocGFyZW50Q29tbWFuZC5fdG9rZW4pXHJcbiAgICAgICAgKSB7XHJcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihcIlRva2VuIG9mIHBhcmVudGVkIGNvbW1hbmQgY2Fubm90IGJlIGNoYW5nZWQuXCIpO1xyXG4gICAgICAgIH1cclxuICAgICAgICBpZiAodGhpcy5fcGFyZW50Q29tbWFuZCA9PT0gbnVsbCB8fCB0aGlzLl9wYXJlbnRDb21tYW5kID09PSB1bmRlZmluZWQpIHtcclxuICAgICAgICAgICAge1xyXG4gICAgICAgICAgICAgICAgLy8gdG9kbzogZG8gd2UgbmVlZCB0byBvdmVycmlkZSB0aGUgdG9rZW4/IFNob3VsZCB0aGlzIHRocm93IGlmIHBhcmVudGluZyBoYXBwZW5zIGFmdGVyIHRva2VuIGlzIHNldD9cclxuICAgICAgICAgICAgICAgIGlmICh0aGlzLl90b2tlbikge1xyXG4gICAgICAgICAgICAgICAgICAgIHRoaXMuX3Rva2VuID0gdW5kZWZpbmVkO1xyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgdGhpcy5fcGFyZW50Q29tbWFuZCA9IHBhcmVudENvbW1hbmQ7XHJcbiAgICAgICAgICAgICAgICB0aGlzLmdldE9yQ3JlYXRlVG9rZW4oKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuXHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHN0YXRpYyBhcmVDb21tYW5kc1RoZVNhbWUoZW52ZWxvcGUxOiBLZXJuZWxDb21tYW5kRW52ZWxvcGUsIGVudmVsb3BlMjogS2VybmVsQ29tbWFuZEVudmVsb3BlKTogYm9vbGVhbiB7XHJcbiAgICAgICAgZW52ZWxvcGUxOy8vP1xyXG4gICAgICAgIGVudmVsb3BlMjsvLz9cclxuICAgICAgICBlbnZlbG9wZTEgPT09IGVudmVsb3BlMjsvLz9cclxuXHJcbiAgICAgICAgLy8gcmVmZXJlbmNlIGVxdWFsaXR5XHJcbiAgICAgICAgaWYgKGVudmVsb3BlMSA9PT0gZW52ZWxvcGUyKSB7XHJcbiAgICAgICAgICAgIHJldHVybiB0cnVlO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgLy8gY29tbWFuZFR5cGUgZXF1YWxpdHlcclxuICAgICAgICBjb25zdCBzYW1lQ29tbWFuZFR5cGUgPSBlbnZlbG9wZTE/LmNvbW1hbmRUeXBlID09PSBlbnZlbG9wZTI/LmNvbW1hbmRUeXBlOyAvLz9cclxuICAgICAgICBpZiAoIXNhbWVDb21tYW5kVHlwZSkge1xyXG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICAvLyBib3RoIG11c3QgaGF2ZSB0b2tlbnNcclxuICAgICAgICBpZiAoKCFlbnZlbG9wZTE/Ll90b2tlbikgfHwgKCFlbnZlbG9wZTI/Ll90b2tlbikpIHtcclxuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgLy8gdG9rZW4gZXF1YWxpdHlcclxuICAgICAgICBjb25zdCBzYW1lVG9rZW4gPSBlbnZlbG9wZTE/Ll90b2tlbiA9PT0gZW52ZWxvcGUyPy5fdG9rZW47IC8vP1xyXG4gICAgICAgIGlmICghc2FtZVRva2VuKSB7XHJcbiAgICAgICAgICAgIHJldHVybiBmYWxzZTtcclxuICAgICAgICB9XHJcbiAgICAgICAgcmV0dXJuIHRydWU7XHJcbiAgICB9XHJcblxyXG4gICAgc3RhdGljIF9jb3VudGVyID0gMTtcclxuICAgIHB1YmxpYyBnZXRPckNyZWF0ZVRva2VuKCk6IHN0cmluZyB7XHJcbiAgICAgICAgaWYgKHRoaXMuX3Rva2VuKSB7XHJcbiAgICAgICAgICAgIHJldHVybiB0aGlzLl90b2tlbjtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmICh0aGlzLl9wYXJlbnRDb21tYW5kKSB7XHJcbiAgICAgICAgICAgIHRoaXMuX3Rva2VuID0gYCR7dGhpcy5fcGFyZW50Q29tbWFuZC5nZXRPckNyZWF0ZVRva2VuKCl9LiR7dGhpcy5fcGFyZW50Q29tbWFuZC5nZXROZXh0Q2hpbGRUb2tlbigpfWA7XHJcbiAgICAgICAgICAgIHJldHVybiB0aGlzLl90b2tlbjtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGNvbnN0IGd1aWRCeXRlcyA9IHV1aWQucGFyc2UodXVpZC52NCgpKTtcclxuICAgICAgICBjb25zdCBkYXRhID0gbmV3IFVpbnQ4QXJyYXkoZ3VpZEJ5dGVzKTtcclxuICAgICAgICB0aGlzLl90b2tlbiA9IHRvQmFzZTY0U3RyaW5nKGRhdGEpO1xyXG5cclxuICAgICAgICAvLyB0aGlzLl90b2tlbiA9IGAke0tlcm5lbENvbW1hbmRFbnZlbG9wZS5fY291bnRlcisrfWA7XHJcblxyXG4gICAgICAgIHJldHVybiB0aGlzLl90b2tlbjtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0VG9rZW4oKTogc3RyaW5nIHtcclxuICAgICAgICBpZiAodGhpcy5fdG9rZW4pIHtcclxuICAgICAgICAgICAgcmV0dXJuIHRoaXMuX3Rva2VuO1xyXG4gICAgICAgIH1cclxuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ3Rva2VuIG5vdCBzZXQnKTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgaXNTZWxmb3JEZXNjZW5kYW50T2Yob3RoZXJDb21tYW5kOiBLZXJuZWxDb21tYW5kRW52ZWxvcGUpIHtcclxuICAgICAgICBjb25zdCBvdGhlclRva2VuID0gb3RoZXJDb21tYW5kLl90b2tlbjtcclxuICAgICAgICBjb25zdCB0aGlzVG9rZW4gPSB0aGlzLl90b2tlbjtcclxuICAgICAgICBpZiAodGhpc1Rva2VuICYmIG90aGVyVG9rZW4pIHtcclxuICAgICAgICAgICAgcmV0dXJuIHRoaXNUb2tlbi5zdGFydHNXaXRoKG90aGVyVG9rZW4hKTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIHRocm93IG5ldyBFcnJvcignYm90aCBjb21tYW5kcyBtdXN0IGhhdmUgdG9rZW5zJyk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGhhc1NhbWVSb290Q29tbWFuZEFzKG90aGVyQ29tbWFuZDogS2VybmVsQ29tbWFuZEVudmVsb3BlKSB7XHJcbiAgICAgICAgY29uc3Qgb3RoZXJUb2tlbiA9IG90aGVyQ29tbWFuZC5fdG9rZW47XHJcbiAgICAgICAgY29uc3QgdGhpc1Rva2VuID0gdGhpcy5fdG9rZW47XHJcbiAgICAgICAgaWYgKHRoaXNUb2tlbiAmJiBvdGhlclRva2VuKSB7XHJcbiAgICAgICAgICAgIGNvbnN0IG90aGVyUm9vdFRva2VuID0gS2VybmVsQ29tbWFuZEVudmVsb3BlLmdldFJvb3RUb2tlbihvdGhlclRva2VuKTtcclxuICAgICAgICAgICAgY29uc3QgdGhpc1Jvb3RUb2tlbiA9IEtlcm5lbENvbW1hbmRFbnZlbG9wZS5nZXRSb290VG9rZW4odGhpc1Rva2VuKTtcclxuICAgICAgICAgICAgcmV0dXJuIHRoaXNSb290VG9rZW4gPT09IG90aGVyUm9vdFRva2VuO1xyXG4gICAgICAgIH1cclxuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ2JvdGggY29tbWFuZHMgbXVzdCBoYXZlIHRva2VucycpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBzdGF0aWMgZ2V0Um9vdFRva2VuKHRva2VuOiBzdHJpbmcpOiBzdHJpbmcge1xyXG4gICAgICAgIGNvbnN0IHBhcnRzID0gdG9rZW4uc3BsaXQoJy4nKTtcclxuICAgICAgICByZXR1cm4gcGFydHNbMF07XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHRvSnNvbigpOiBLZXJuZWxDb21tYW5kRW52ZWxvcGVNb2RlbCB7XHJcbiAgICAgICAgY29uc3QgbW9kZWw6IEtlcm5lbENvbW1hbmRFbnZlbG9wZU1vZGVsID0ge1xyXG4gICAgICAgICAgICBjb21tYW5kVHlwZTogdGhpcy5jb21tYW5kVHlwZSxcclxuICAgICAgICAgICAgY29tbWFuZDogdGhpcy5jb21tYW5kLFxyXG4gICAgICAgICAgICByb3V0aW5nU2xpcDogdGhpcy5fcm91dGluZ1NsaXAudG9BcnJheSgpLFxyXG4gICAgICAgICAgICB0b2tlbjogdGhpcy5nZXRPckNyZWF0ZVRva2VuKClcclxuICAgICAgICB9O1xyXG5cclxuICAgICAgICByZXR1cm4gbW9kZWw7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHN0YXRpYyBmcm9tSnNvbihtb2RlbDogS2VybmVsQ29tbWFuZEVudmVsb3BlTW9kZWwpOiBLZXJuZWxDb21tYW5kRW52ZWxvcGUge1xyXG4gICAgICAgIGNvbnN0IGNvbW1hbmQgPSBuZXcgS2VybmVsQ29tbWFuZEVudmVsb3BlKG1vZGVsLmNvbW1hbmRUeXBlLCBtb2RlbC5jb21tYW5kKTtcclxuICAgICAgICBjb21tYW5kLl9yb3V0aW5nU2xpcCA9IENvbW1hbmRSb3V0aW5nU2xpcC5mcm9tVXJpcyhtb2RlbC5yb3V0aW5nU2xpcCB8fCBbXSk7XHJcbiAgICAgICAgY29tbWFuZC5fdG9rZW4gPSBtb2RlbC50b2tlbjtcclxuICAgICAgICByZXR1cm4gY29tbWFuZDtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgY2xvbmUoKTogS2VybmVsQ29tbWFuZEVudmVsb3BlIHtcclxuICAgICAgICByZXR1cm4gS2VybmVsQ29tbWFuZEVudmVsb3BlLmZyb21Kc29uKHRoaXMudG9Kc29uKCkpO1xyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgZ2V0TmV4dENoaWxkVG9rZW4oKTogbnVtYmVyIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fY2hpbGRDb21tYW5kQ291bnRlcisrO1xyXG4gICAgfVxyXG59XHJcblxyXG5leHBvcnQgY2xhc3MgS2VybmVsRXZlbnRFbnZlbG9wZSB7XHJcbiAgICBwcml2YXRlIF9yb3V0aW5nU2xpcDogRXZlbnRSb3V0aW5nU2xpcCA9IG5ldyBFdmVudFJvdXRpbmdTbGlwKCk7XHJcbiAgICBjb25zdHJ1Y3RvcihcclxuICAgICAgICBwdWJsaWMgZXZlbnRUeXBlOiBjb250cmFjdHMuS2VybmVsRXZlbnRUeXBlLFxyXG4gICAgICAgIHB1YmxpYyBldmVudDogY29udHJhY3RzLktlcm5lbEV2ZW50LFxyXG4gICAgICAgIHB1YmxpYyBjb21tYW5kPzogS2VybmVsQ29tbWFuZEVudmVsb3BlKSB7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGdldCByb3V0aW5nU2xpcCgpOiBFdmVudFJvdXRpbmdTbGlwIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fcm91dGluZ1NsaXA7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHRvSnNvbigpOiBLZXJuZWxFdmVudEVudmVsb3BlTW9kZWwge1xyXG4gICAgICAgIGNvbnN0IG1vZGVsOiBLZXJuZWxFdmVudEVudmVsb3BlTW9kZWwgPSB7XHJcbiAgICAgICAgICAgIGV2ZW50VHlwZTogdGhpcy5ldmVudFR5cGUsXHJcbiAgICAgICAgICAgIGV2ZW50OiB0aGlzLmV2ZW50LFxyXG4gICAgICAgICAgICBjb21tYW5kOiB0aGlzLmNvbW1hbmQ/LnRvSnNvbigpLFxyXG4gICAgICAgICAgICByb3V0aW5nU2xpcDogdGhpcy5fcm91dGluZ1NsaXAudG9BcnJheSgpXHJcbiAgICAgICAgfTtcclxuXHJcbiAgICAgICAgcmV0dXJuIG1vZGVsO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBzdGF0aWMgZnJvbUpzb24obW9kZWw6IEtlcm5lbEV2ZW50RW52ZWxvcGVNb2RlbCk6IEtlcm5lbEV2ZW50RW52ZWxvcGUge1xyXG4gICAgICAgIGNvbnN0IGV2ZW50ID0gbmV3IEtlcm5lbEV2ZW50RW52ZWxvcGUoXHJcbiAgICAgICAgICAgIG1vZGVsLmV2ZW50VHlwZSxcclxuICAgICAgICAgICAgbW9kZWwuZXZlbnQsXHJcbiAgICAgICAgICAgIG1vZGVsLmNvbW1hbmQgPyBLZXJuZWxDb21tYW5kRW52ZWxvcGUuZnJvbUpzb24obW9kZWwuY29tbWFuZCkgOiB1bmRlZmluZWQpO1xyXG4gICAgICAgIGV2ZW50Ll9yb3V0aW5nU2xpcCA9IEV2ZW50Um91dGluZ1NsaXAuZnJvbVVyaXMobW9kZWwucm91dGluZ1NsaXAgfHwgW11cclxuICAgICAgICApO1xyXG4gICAgICAgIHJldHVybiBldmVudDtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgY2xvbmUoKTogS2VybmVsRXZlbnRFbnZlbG9wZSB7XHJcbiAgICAgICAgcmV0dXJuIEtlcm5lbEV2ZW50RW52ZWxvcGUuZnJvbUpzb24odGhpcy50b0pzb24oKSk7XHJcbiAgICB9XHJcbn1cclxuIiwiZXhwb3J0IGZ1bmN0aW9uIGlzRnVuY3Rpb24odmFsdWUpIHtcbiAgICByZXR1cm4gdHlwZW9mIHZhbHVlID09PSAnZnVuY3Rpb24nO1xufVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9aXNGdW5jdGlvbi5qcy5tYXAiLCJleHBvcnQgZnVuY3Rpb24gY3JlYXRlRXJyb3JDbGFzcyhjcmVhdGVJbXBsKSB7XG4gICAgdmFyIF9zdXBlciA9IGZ1bmN0aW9uIChpbnN0YW5jZSkge1xuICAgICAgICBFcnJvci5jYWxsKGluc3RhbmNlKTtcbiAgICAgICAgaW5zdGFuY2Uuc3RhY2sgPSBuZXcgRXJyb3IoKS5zdGFjaztcbiAgICB9O1xuICAgIHZhciBjdG9yRnVuYyA9IGNyZWF0ZUltcGwoX3N1cGVyKTtcbiAgICBjdG9yRnVuYy5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKEVycm9yLnByb3RvdHlwZSk7XG4gICAgY3RvckZ1bmMucHJvdG90eXBlLmNvbnN0cnVjdG9yID0gY3RvckZ1bmM7XG4gICAgcmV0dXJuIGN0b3JGdW5jO1xufVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9Y3JlYXRlRXJyb3JDbGFzcy5qcy5tYXAiLCJpbXBvcnQgeyBjcmVhdGVFcnJvckNsYXNzIH0gZnJvbSAnLi9jcmVhdGVFcnJvckNsYXNzJztcbmV4cG9ydCB2YXIgVW5zdWJzY3JpcHRpb25FcnJvciA9IGNyZWF0ZUVycm9yQ2xhc3MoZnVuY3Rpb24gKF9zdXBlcikge1xuICAgIHJldHVybiBmdW5jdGlvbiBVbnN1YnNjcmlwdGlvbkVycm9ySW1wbChlcnJvcnMpIHtcbiAgICAgICAgX3N1cGVyKHRoaXMpO1xuICAgICAgICB0aGlzLm1lc3NhZ2UgPSBlcnJvcnNcbiAgICAgICAgICAgID8gZXJyb3JzLmxlbmd0aCArIFwiIGVycm9ycyBvY2N1cnJlZCBkdXJpbmcgdW5zdWJzY3JpcHRpb246XFxuXCIgKyBlcnJvcnMubWFwKGZ1bmN0aW9uIChlcnIsIGkpIHsgcmV0dXJuIGkgKyAxICsgXCIpIFwiICsgZXJyLnRvU3RyaW5nKCk7IH0pLmpvaW4oJ1xcbiAgJylcbiAgICAgICAgICAgIDogJyc7XG4gICAgICAgIHRoaXMubmFtZSA9ICdVbnN1YnNjcmlwdGlvbkVycm9yJztcbiAgICAgICAgdGhpcy5lcnJvcnMgPSBlcnJvcnM7XG4gICAgfTtcbn0pO1xuLy8jIHNvdXJjZU1hcHBpbmdVUkw9VW5zdWJzY3JpcHRpb25FcnJvci5qcy5tYXAiLCJleHBvcnQgZnVuY3Rpb24gYXJyUmVtb3ZlKGFyciwgaXRlbSkge1xuICAgIGlmIChhcnIpIHtcbiAgICAgICAgdmFyIGluZGV4ID0gYXJyLmluZGV4T2YoaXRlbSk7XG4gICAgICAgIDAgPD0gaW5kZXggJiYgYXJyLnNwbGljZShpbmRleCwgMSk7XG4gICAgfVxufVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9YXJyUmVtb3ZlLmpzLm1hcCIsImltcG9ydCB7IF9fcmVhZCwgX19zcHJlYWRBcnJheSwgX192YWx1ZXMgfSBmcm9tIFwidHNsaWJcIjtcbmltcG9ydCB7IGlzRnVuY3Rpb24gfSBmcm9tICcuL3V0aWwvaXNGdW5jdGlvbic7XG5pbXBvcnQgeyBVbnN1YnNjcmlwdGlvbkVycm9yIH0gZnJvbSAnLi91dGlsL1Vuc3Vic2NyaXB0aW9uRXJyb3InO1xuaW1wb3J0IHsgYXJyUmVtb3ZlIH0gZnJvbSAnLi91dGlsL2FyclJlbW92ZSc7XG52YXIgU3Vic2NyaXB0aW9uID0gKGZ1bmN0aW9uICgpIHtcbiAgICBmdW5jdGlvbiBTdWJzY3JpcHRpb24oaW5pdGlhbFRlYXJkb3duKSB7XG4gICAgICAgIHRoaXMuaW5pdGlhbFRlYXJkb3duID0gaW5pdGlhbFRlYXJkb3duO1xuICAgICAgICB0aGlzLmNsb3NlZCA9IGZhbHNlO1xuICAgICAgICB0aGlzLl9wYXJlbnRhZ2UgPSBudWxsO1xuICAgICAgICB0aGlzLl9maW5hbGl6ZXJzID0gbnVsbDtcbiAgICB9XG4gICAgU3Vic2NyaXB0aW9uLnByb3RvdHlwZS51bnN1YnNjcmliZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIGVfMSwgX2EsIGVfMiwgX2I7XG4gICAgICAgIHZhciBlcnJvcnM7XG4gICAgICAgIGlmICghdGhpcy5jbG9zZWQpIHtcbiAgICAgICAgICAgIHRoaXMuY2xvc2VkID0gdHJ1ZTtcbiAgICAgICAgICAgIHZhciBfcGFyZW50YWdlID0gdGhpcy5fcGFyZW50YWdlO1xuICAgICAgICAgICAgaWYgKF9wYXJlbnRhZ2UpIHtcbiAgICAgICAgICAgICAgICB0aGlzLl9wYXJlbnRhZ2UgPSBudWxsO1xuICAgICAgICAgICAgICAgIGlmIChBcnJheS5pc0FycmF5KF9wYXJlbnRhZ2UpKSB7XG4gICAgICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBmb3IgKHZhciBfcGFyZW50YWdlXzEgPSBfX3ZhbHVlcyhfcGFyZW50YWdlKSwgX3BhcmVudGFnZV8xXzEgPSBfcGFyZW50YWdlXzEubmV4dCgpOyAhX3BhcmVudGFnZV8xXzEuZG9uZTsgX3BhcmVudGFnZV8xXzEgPSBfcGFyZW50YWdlXzEubmV4dCgpKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFyIHBhcmVudF8xID0gX3BhcmVudGFnZV8xXzEudmFsdWU7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFyZW50XzEucmVtb3ZlKHRoaXMpO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIGNhdGNoIChlXzFfMSkgeyBlXzEgPSB7IGVycm9yOiBlXzFfMSB9OyB9XG4gICAgICAgICAgICAgICAgICAgIGZpbmFsbHkge1xuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoX3BhcmVudGFnZV8xXzEgJiYgIV9wYXJlbnRhZ2VfMV8xLmRvbmUgJiYgKF9hID0gX3BhcmVudGFnZV8xLnJldHVybikpIF9hLmNhbGwoX3BhcmVudGFnZV8xKTtcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgIGZpbmFsbHkgeyBpZiAoZV8xKSB0aHJvdyBlXzEuZXJyb3I7IH1cbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgX3BhcmVudGFnZS5yZW1vdmUodGhpcyk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgdmFyIGluaXRpYWxGaW5hbGl6ZXIgPSB0aGlzLmluaXRpYWxUZWFyZG93bjtcbiAgICAgICAgICAgIGlmIChpc0Z1bmN0aW9uKGluaXRpYWxGaW5hbGl6ZXIpKSB7XG4gICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgaW5pdGlhbEZpbmFsaXplcigpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBjYXRjaCAoZSkge1xuICAgICAgICAgICAgICAgICAgICBlcnJvcnMgPSBlIGluc3RhbmNlb2YgVW5zdWJzY3JpcHRpb25FcnJvciA/IGUuZXJyb3JzIDogW2VdO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHZhciBfZmluYWxpemVycyA9IHRoaXMuX2ZpbmFsaXplcnM7XG4gICAgICAgICAgICBpZiAoX2ZpbmFsaXplcnMpIHtcbiAgICAgICAgICAgICAgICB0aGlzLl9maW5hbGl6ZXJzID0gbnVsbDtcbiAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICBmb3IgKHZhciBfZmluYWxpemVyc18xID0gX192YWx1ZXMoX2ZpbmFsaXplcnMpLCBfZmluYWxpemVyc18xXzEgPSBfZmluYWxpemVyc18xLm5leHQoKTsgIV9maW5hbGl6ZXJzXzFfMS5kb25lOyBfZmluYWxpemVyc18xXzEgPSBfZmluYWxpemVyc18xLm5leHQoKSkge1xuICAgICAgICAgICAgICAgICAgICAgICAgdmFyIGZpbmFsaXplciA9IF9maW5hbGl6ZXJzXzFfMS52YWx1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZXhlY0ZpbmFsaXplcihmaW5hbGl6ZXIpO1xuICAgICAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICAgICAgY2F0Y2ggKGVycikge1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVycm9ycyA9IGVycm9ycyAhPT0gbnVsbCAmJiBlcnJvcnMgIT09IHZvaWQgMCA/IGVycm9ycyA6IFtdO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChlcnIgaW5zdGFuY2VvZiBVbnN1YnNjcmlwdGlvbkVycm9yKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVycm9ycyA9IF9fc3ByZWFkQXJyYXkoX19zcHJlYWRBcnJheShbXSwgX19yZWFkKGVycm9ycykpLCBfX3JlYWQoZXJyLmVycm9ycykpO1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZXJyb3JzLnB1c2goZXJyKTtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgY2F0Y2ggKGVfMl8xKSB7IGVfMiA9IHsgZXJyb3I6IGVfMl8xIH07IH1cbiAgICAgICAgICAgICAgICBmaW5hbGx5IHtcbiAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChfZmluYWxpemVyc18xXzEgJiYgIV9maW5hbGl6ZXJzXzFfMS5kb25lICYmIChfYiA9IF9maW5hbGl6ZXJzXzEucmV0dXJuKSkgX2IuY2FsbChfZmluYWxpemVyc18xKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBmaW5hbGx5IHsgaWYgKGVfMikgdGhyb3cgZV8yLmVycm9yOyB9XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKGVycm9ycykge1xuICAgICAgICAgICAgICAgIHRocm93IG5ldyBVbnN1YnNjcmlwdGlvbkVycm9yKGVycm9ycyk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9O1xuICAgIFN1YnNjcmlwdGlvbi5wcm90b3R5cGUuYWRkID0gZnVuY3Rpb24gKHRlYXJkb3duKSB7XG4gICAgICAgIHZhciBfYTtcbiAgICAgICAgaWYgKHRlYXJkb3duICYmIHRlYXJkb3duICE9PSB0aGlzKSB7XG4gICAgICAgICAgICBpZiAodGhpcy5jbG9zZWQpIHtcbiAgICAgICAgICAgICAgICBleGVjRmluYWxpemVyKHRlYXJkb3duKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGVsc2Uge1xuICAgICAgICAgICAgICAgIGlmICh0ZWFyZG93biBpbnN0YW5jZW9mIFN1YnNjcmlwdGlvbikge1xuICAgICAgICAgICAgICAgICAgICBpZiAodGVhcmRvd24uY2xvc2VkIHx8IHRlYXJkb3duLl9oYXNQYXJlbnQodGhpcykpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICB0ZWFyZG93bi5fYWRkUGFyZW50KHRoaXMpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAodGhpcy5fZmluYWxpemVycyA9IChfYSA9IHRoaXMuX2ZpbmFsaXplcnMpICE9PSBudWxsICYmIF9hICE9PSB2b2lkIDAgPyBfYSA6IFtdKS5wdXNoKHRlYXJkb3duKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgIH07XG4gICAgU3Vic2NyaXB0aW9uLnByb3RvdHlwZS5faGFzUGFyZW50ID0gZnVuY3Rpb24gKHBhcmVudCkge1xuICAgICAgICB2YXIgX3BhcmVudGFnZSA9IHRoaXMuX3BhcmVudGFnZTtcbiAgICAgICAgcmV0dXJuIF9wYXJlbnRhZ2UgPT09IHBhcmVudCB8fCAoQXJyYXkuaXNBcnJheShfcGFyZW50YWdlKSAmJiBfcGFyZW50YWdlLmluY2x1ZGVzKHBhcmVudCkpO1xuICAgIH07XG4gICAgU3Vic2NyaXB0aW9uLnByb3RvdHlwZS5fYWRkUGFyZW50ID0gZnVuY3Rpb24gKHBhcmVudCkge1xuICAgICAgICB2YXIgX3BhcmVudGFnZSA9IHRoaXMuX3BhcmVudGFnZTtcbiAgICAgICAgdGhpcy5fcGFyZW50YWdlID0gQXJyYXkuaXNBcnJheShfcGFyZW50YWdlKSA/IChfcGFyZW50YWdlLnB1c2gocGFyZW50KSwgX3BhcmVudGFnZSkgOiBfcGFyZW50YWdlID8gW19wYXJlbnRhZ2UsIHBhcmVudF0gOiBwYXJlbnQ7XG4gICAgfTtcbiAgICBTdWJzY3JpcHRpb24ucHJvdG90eXBlLl9yZW1vdmVQYXJlbnQgPSBmdW5jdGlvbiAocGFyZW50KSB7XG4gICAgICAgIHZhciBfcGFyZW50YWdlID0gdGhpcy5fcGFyZW50YWdlO1xuICAgICAgICBpZiAoX3BhcmVudGFnZSA9PT0gcGFyZW50KSB7XG4gICAgICAgICAgICB0aGlzLl9wYXJlbnRhZ2UgPSBudWxsO1xuICAgICAgICB9XG4gICAgICAgIGVsc2UgaWYgKEFycmF5LmlzQXJyYXkoX3BhcmVudGFnZSkpIHtcbiAgICAgICAgICAgIGFyclJlbW92ZShfcGFyZW50YWdlLCBwYXJlbnQpO1xuICAgICAgICB9XG4gICAgfTtcbiAgICBTdWJzY3JpcHRpb24ucHJvdG90eXBlLnJlbW92ZSA9IGZ1bmN0aW9uICh0ZWFyZG93bikge1xuICAgICAgICB2YXIgX2ZpbmFsaXplcnMgPSB0aGlzLl9maW5hbGl6ZXJzO1xuICAgICAgICBfZmluYWxpemVycyAmJiBhcnJSZW1vdmUoX2ZpbmFsaXplcnMsIHRlYXJkb3duKTtcbiAgICAgICAgaWYgKHRlYXJkb3duIGluc3RhbmNlb2YgU3Vic2NyaXB0aW9uKSB7XG4gICAgICAgICAgICB0ZWFyZG93bi5fcmVtb3ZlUGFyZW50KHRoaXMpO1xuICAgICAgICB9XG4gICAgfTtcbiAgICBTdWJzY3JpcHRpb24uRU1QVFkgPSAoZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgZW1wdHkgPSBuZXcgU3Vic2NyaXB0aW9uKCk7XG4gICAgICAgIGVtcHR5LmNsb3NlZCA9IHRydWU7XG4gICAgICAgIHJldHVybiBlbXB0eTtcbiAgICB9KSgpO1xuICAgIHJldHVybiBTdWJzY3JpcHRpb247XG59KCkpO1xuZXhwb3J0IHsgU3Vic2NyaXB0aW9uIH07XG5leHBvcnQgdmFyIEVNUFRZX1NVQlNDUklQVElPTiA9IFN1YnNjcmlwdGlvbi5FTVBUWTtcbmV4cG9ydCBmdW5jdGlvbiBpc1N1YnNjcmlwdGlvbih2YWx1ZSkge1xuICAgIHJldHVybiAodmFsdWUgaW5zdGFuY2VvZiBTdWJzY3JpcHRpb24gfHxcbiAgICAgICAgKHZhbHVlICYmICdjbG9zZWQnIGluIHZhbHVlICYmIGlzRnVuY3Rpb24odmFsdWUucmVtb3ZlKSAmJiBpc0Z1bmN0aW9uKHZhbHVlLmFkZCkgJiYgaXNGdW5jdGlvbih2YWx1ZS51bnN1YnNjcmliZSkpKTtcbn1cbmZ1bmN0aW9uIGV4ZWNGaW5hbGl6ZXIoZmluYWxpemVyKSB7XG4gICAgaWYgKGlzRnVuY3Rpb24oZmluYWxpemVyKSkge1xuICAgICAgICBmaW5hbGl6ZXIoKTtcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICAgIGZpbmFsaXplci51bnN1YnNjcmliZSgpO1xuICAgIH1cbn1cbi8vIyBzb3VyY2VNYXBwaW5nVVJMPVN1YnNjcmlwdGlvbi5qcy5tYXAiLCJleHBvcnQgdmFyIGNvbmZpZyA9IHtcbiAgICBvblVuaGFuZGxlZEVycm9yOiBudWxsLFxuICAgIG9uU3RvcHBlZE5vdGlmaWNhdGlvbjogbnVsbCxcbiAgICBQcm9taXNlOiB1bmRlZmluZWQsXG4gICAgdXNlRGVwcmVjYXRlZFN5bmNocm9ub3VzRXJyb3JIYW5kbGluZzogZmFsc2UsXG4gICAgdXNlRGVwcmVjYXRlZE5leHRDb250ZXh0OiBmYWxzZSxcbn07XG4vLyMgc291cmNlTWFwcGluZ1VSTD1jb25maWcuanMubWFwIiwiaW1wb3J0IHsgX19yZWFkLCBfX3NwcmVhZEFycmF5IH0gZnJvbSBcInRzbGliXCI7XG5leHBvcnQgdmFyIHRpbWVvdXRQcm92aWRlciA9IHtcbiAgICBzZXRUaW1lb3V0OiBmdW5jdGlvbiAoaGFuZGxlciwgdGltZW91dCkge1xuICAgICAgICB2YXIgYXJncyA9IFtdO1xuICAgICAgICBmb3IgKHZhciBfaSA9IDI7IF9pIDwgYXJndW1lbnRzLmxlbmd0aDsgX2krKykge1xuICAgICAgICAgICAgYXJnc1tfaSAtIDJdID0gYXJndW1lbnRzW19pXTtcbiAgICAgICAgfVxuICAgICAgICB2YXIgZGVsZWdhdGUgPSB0aW1lb3V0UHJvdmlkZXIuZGVsZWdhdGU7XG4gICAgICAgIGlmIChkZWxlZ2F0ZSA9PT0gbnVsbCB8fCBkZWxlZ2F0ZSA9PT0gdm9pZCAwID8gdm9pZCAwIDogZGVsZWdhdGUuc2V0VGltZW91dCkge1xuICAgICAgICAgICAgcmV0dXJuIGRlbGVnYXRlLnNldFRpbWVvdXQuYXBwbHkoZGVsZWdhdGUsIF9fc3ByZWFkQXJyYXkoW2hhbmRsZXIsIHRpbWVvdXRdLCBfX3JlYWQoYXJncykpKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gc2V0VGltZW91dC5hcHBseSh2b2lkIDAsIF9fc3ByZWFkQXJyYXkoW2hhbmRsZXIsIHRpbWVvdXRdLCBfX3JlYWQoYXJncykpKTtcbiAgICB9LFxuICAgIGNsZWFyVGltZW91dDogZnVuY3Rpb24gKGhhbmRsZSkge1xuICAgICAgICB2YXIgZGVsZWdhdGUgPSB0aW1lb3V0UHJvdmlkZXIuZGVsZWdhdGU7XG4gICAgICAgIHJldHVybiAoKGRlbGVnYXRlID09PSBudWxsIHx8IGRlbGVnYXRlID09PSB2b2lkIDAgPyB2b2lkIDAgOiBkZWxlZ2F0ZS5jbGVhclRpbWVvdXQpIHx8IGNsZWFyVGltZW91dCkoaGFuZGxlKTtcbiAgICB9LFxuICAgIGRlbGVnYXRlOiB1bmRlZmluZWQsXG59O1xuLy8jIHNvdXJjZU1hcHBpbmdVUkw9dGltZW91dFByb3ZpZGVyLmpzLm1hcCIsImltcG9ydCB7IGNvbmZpZyB9IGZyb20gJy4uL2NvbmZpZyc7XG5pbXBvcnQgeyB0aW1lb3V0UHJvdmlkZXIgfSBmcm9tICcuLi9zY2hlZHVsZXIvdGltZW91dFByb3ZpZGVyJztcbmV4cG9ydCBmdW5jdGlvbiByZXBvcnRVbmhhbmRsZWRFcnJvcihlcnIpIHtcbiAgICB0aW1lb3V0UHJvdmlkZXIuc2V0VGltZW91dChmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBvblVuaGFuZGxlZEVycm9yID0gY29uZmlnLm9uVW5oYW5kbGVkRXJyb3I7XG4gICAgICAgIGlmIChvblVuaGFuZGxlZEVycm9yKSB7XG4gICAgICAgICAgICBvblVuaGFuZGxlZEVycm9yKGVycik7XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICB0aHJvdyBlcnI7XG4gICAgICAgIH1cbiAgICB9KTtcbn1cbi8vIyBzb3VyY2VNYXBwaW5nVVJMPXJlcG9ydFVuaGFuZGxlZEVycm9yLmpzLm1hcCIsImV4cG9ydCBmdW5jdGlvbiBub29wKCkgeyB9XG4vLyMgc291cmNlTWFwcGluZ1VSTD1ub29wLmpzLm1hcCIsImltcG9ydCB7IGNvbmZpZyB9IGZyb20gJy4uL2NvbmZpZyc7XG52YXIgY29udGV4dCA9IG51bGw7XG5leHBvcnQgZnVuY3Rpb24gZXJyb3JDb250ZXh0KGNiKSB7XG4gICAgaWYgKGNvbmZpZy51c2VEZXByZWNhdGVkU3luY2hyb25vdXNFcnJvckhhbmRsaW5nKSB7XG4gICAgICAgIHZhciBpc1Jvb3QgPSAhY29udGV4dDtcbiAgICAgICAgaWYgKGlzUm9vdCkge1xuICAgICAgICAgICAgY29udGV4dCA9IHsgZXJyb3JUaHJvd246IGZhbHNlLCBlcnJvcjogbnVsbCB9O1xuICAgICAgICB9XG4gICAgICAgIGNiKCk7XG4gICAgICAgIGlmIChpc1Jvb3QpIHtcbiAgICAgICAgICAgIHZhciBfYSA9IGNvbnRleHQsIGVycm9yVGhyb3duID0gX2EuZXJyb3JUaHJvd24sIGVycm9yID0gX2EuZXJyb3I7XG4gICAgICAgICAgICBjb250ZXh0ID0gbnVsbDtcbiAgICAgICAgICAgIGlmIChlcnJvclRocm93bikge1xuICAgICAgICAgICAgICAgIHRocm93IGVycm9yO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgfVxuICAgIGVsc2Uge1xuICAgICAgICBjYigpO1xuICAgIH1cbn1cbmV4cG9ydCBmdW5jdGlvbiBjYXB0dXJlRXJyb3IoZXJyKSB7XG4gICAgaWYgKGNvbmZpZy51c2VEZXByZWNhdGVkU3luY2hyb25vdXNFcnJvckhhbmRsaW5nICYmIGNvbnRleHQpIHtcbiAgICAgICAgY29udGV4dC5lcnJvclRocm93biA9IHRydWU7XG4gICAgICAgIGNvbnRleHQuZXJyb3IgPSBlcnI7XG4gICAgfVxufVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9ZXJyb3JDb250ZXh0LmpzLm1hcCIsImltcG9ydCB7IF9fZXh0ZW5kcyB9IGZyb20gXCJ0c2xpYlwiO1xuaW1wb3J0IHsgaXNGdW5jdGlvbiB9IGZyb20gJy4vdXRpbC9pc0Z1bmN0aW9uJztcbmltcG9ydCB7IGlzU3Vic2NyaXB0aW9uLCBTdWJzY3JpcHRpb24gfSBmcm9tICcuL1N1YnNjcmlwdGlvbic7XG5pbXBvcnQgeyBjb25maWcgfSBmcm9tICcuL2NvbmZpZyc7XG5pbXBvcnQgeyByZXBvcnRVbmhhbmRsZWRFcnJvciB9IGZyb20gJy4vdXRpbC9yZXBvcnRVbmhhbmRsZWRFcnJvcic7XG5pbXBvcnQgeyBub29wIH0gZnJvbSAnLi91dGlsL25vb3AnO1xuaW1wb3J0IHsgbmV4dE5vdGlmaWNhdGlvbiwgZXJyb3JOb3RpZmljYXRpb24sIENPTVBMRVRFX05PVElGSUNBVElPTiB9IGZyb20gJy4vTm90aWZpY2F0aW9uRmFjdG9yaWVzJztcbmltcG9ydCB7IHRpbWVvdXRQcm92aWRlciB9IGZyb20gJy4vc2NoZWR1bGVyL3RpbWVvdXRQcm92aWRlcic7XG5pbXBvcnQgeyBjYXB0dXJlRXJyb3IgfSBmcm9tICcuL3V0aWwvZXJyb3JDb250ZXh0JztcbnZhciBTdWJzY3JpYmVyID0gKGZ1bmN0aW9uIChfc3VwZXIpIHtcbiAgICBfX2V4dGVuZHMoU3Vic2NyaWJlciwgX3N1cGVyKTtcbiAgICBmdW5jdGlvbiBTdWJzY3JpYmVyKGRlc3RpbmF0aW9uKSB7XG4gICAgICAgIHZhciBfdGhpcyA9IF9zdXBlci5jYWxsKHRoaXMpIHx8IHRoaXM7XG4gICAgICAgIF90aGlzLmlzU3RvcHBlZCA9IGZhbHNlO1xuICAgICAgICBpZiAoZGVzdGluYXRpb24pIHtcbiAgICAgICAgICAgIF90aGlzLmRlc3RpbmF0aW9uID0gZGVzdGluYXRpb247XG4gICAgICAgICAgICBpZiAoaXNTdWJzY3JpcHRpb24oZGVzdGluYXRpb24pKSB7XG4gICAgICAgICAgICAgICAgZGVzdGluYXRpb24uYWRkKF90aGlzKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgIF90aGlzLmRlc3RpbmF0aW9uID0gRU1QVFlfT0JTRVJWRVI7XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIF90aGlzO1xuICAgIH1cbiAgICBTdWJzY3JpYmVyLmNyZWF0ZSA9IGZ1bmN0aW9uIChuZXh0LCBlcnJvciwgY29tcGxldGUpIHtcbiAgICAgICAgcmV0dXJuIG5ldyBTYWZlU3Vic2NyaWJlcihuZXh0LCBlcnJvciwgY29tcGxldGUpO1xuICAgIH07XG4gICAgU3Vic2NyaWJlci5wcm90b3R5cGUubmV4dCA9IGZ1bmN0aW9uICh2YWx1ZSkge1xuICAgICAgICBpZiAodGhpcy5pc1N0b3BwZWQpIHtcbiAgICAgICAgICAgIGhhbmRsZVN0b3BwZWROb3RpZmljYXRpb24obmV4dE5vdGlmaWNhdGlvbih2YWx1ZSksIHRoaXMpO1xuICAgICAgICB9XG4gICAgICAgIGVsc2Uge1xuICAgICAgICAgICAgdGhpcy5fbmV4dCh2YWx1ZSk7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIFN1YnNjcmliZXIucHJvdG90eXBlLmVycm9yID0gZnVuY3Rpb24gKGVycikge1xuICAgICAgICBpZiAodGhpcy5pc1N0b3BwZWQpIHtcbiAgICAgICAgICAgIGhhbmRsZVN0b3BwZWROb3RpZmljYXRpb24oZXJyb3JOb3RpZmljYXRpb24oZXJyKSwgdGhpcyk7XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICB0aGlzLmlzU3RvcHBlZCA9IHRydWU7XG4gICAgICAgICAgICB0aGlzLl9lcnJvcihlcnIpO1xuICAgICAgICB9XG4gICAgfTtcbiAgICBTdWJzY3JpYmVyLnByb3RvdHlwZS5jb21wbGV0ZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgaWYgKHRoaXMuaXNTdG9wcGVkKSB7XG4gICAgICAgICAgICBoYW5kbGVTdG9wcGVkTm90aWZpY2F0aW9uKENPTVBMRVRFX05PVElGSUNBVElPTiwgdGhpcyk7XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICB0aGlzLmlzU3RvcHBlZCA9IHRydWU7XG4gICAgICAgICAgICB0aGlzLl9jb21wbGV0ZSgpO1xuICAgICAgICB9XG4gICAgfTtcbiAgICBTdWJzY3JpYmVyLnByb3RvdHlwZS51bnN1YnNjcmliZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgaWYgKCF0aGlzLmNsb3NlZCkge1xuICAgICAgICAgICAgdGhpcy5pc1N0b3BwZWQgPSB0cnVlO1xuICAgICAgICAgICAgX3N1cGVyLnByb3RvdHlwZS51bnN1YnNjcmliZS5jYWxsKHRoaXMpO1xuICAgICAgICAgICAgdGhpcy5kZXN0aW5hdGlvbiA9IG51bGw7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIFN1YnNjcmliZXIucHJvdG90eXBlLl9uZXh0ID0gZnVuY3Rpb24gKHZhbHVlKSB7XG4gICAgICAgIHRoaXMuZGVzdGluYXRpb24ubmV4dCh2YWx1ZSk7XG4gICAgfTtcbiAgICBTdWJzY3JpYmVyLnByb3RvdHlwZS5fZXJyb3IgPSBmdW5jdGlvbiAoZXJyKSB7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICB0aGlzLmRlc3RpbmF0aW9uLmVycm9yKGVycik7XG4gICAgICAgIH1cbiAgICAgICAgZmluYWxseSB7XG4gICAgICAgICAgICB0aGlzLnVuc3Vic2NyaWJlKCk7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIFN1YnNjcmliZXIucHJvdG90eXBlLl9jb21wbGV0ZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgIHRoaXMuZGVzdGluYXRpb24uY29tcGxldGUoKTtcbiAgICAgICAgfVxuICAgICAgICBmaW5hbGx5IHtcbiAgICAgICAgICAgIHRoaXMudW5zdWJzY3JpYmUoKTtcbiAgICAgICAgfVxuICAgIH07XG4gICAgcmV0dXJuIFN1YnNjcmliZXI7XG59KFN1YnNjcmlwdGlvbikpO1xuZXhwb3J0IHsgU3Vic2NyaWJlciB9O1xudmFyIF9iaW5kID0gRnVuY3Rpb24ucHJvdG90eXBlLmJpbmQ7XG5mdW5jdGlvbiBiaW5kKGZuLCB0aGlzQXJnKSB7XG4gICAgcmV0dXJuIF9iaW5kLmNhbGwoZm4sIHRoaXNBcmcpO1xufVxudmFyIENvbnN1bWVyT2JzZXJ2ZXIgPSAoZnVuY3Rpb24gKCkge1xuICAgIGZ1bmN0aW9uIENvbnN1bWVyT2JzZXJ2ZXIocGFydGlhbE9ic2VydmVyKSB7XG4gICAgICAgIHRoaXMucGFydGlhbE9ic2VydmVyID0gcGFydGlhbE9ic2VydmVyO1xuICAgIH1cbiAgICBDb25zdW1lck9ic2VydmVyLnByb3RvdHlwZS5uZXh0ID0gZnVuY3Rpb24gKHZhbHVlKSB7XG4gICAgICAgIHZhciBwYXJ0aWFsT2JzZXJ2ZXIgPSB0aGlzLnBhcnRpYWxPYnNlcnZlcjtcbiAgICAgICAgaWYgKHBhcnRpYWxPYnNlcnZlci5uZXh0KSB7XG4gICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgIHBhcnRpYWxPYnNlcnZlci5uZXh0KHZhbHVlKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGNhdGNoIChlcnJvcikge1xuICAgICAgICAgICAgICAgIGhhbmRsZVVuaGFuZGxlZEVycm9yKGVycm9yKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgIH07XG4gICAgQ29uc3VtZXJPYnNlcnZlci5wcm90b3R5cGUuZXJyb3IgPSBmdW5jdGlvbiAoZXJyKSB7XG4gICAgICAgIHZhciBwYXJ0aWFsT2JzZXJ2ZXIgPSB0aGlzLnBhcnRpYWxPYnNlcnZlcjtcbiAgICAgICAgaWYgKHBhcnRpYWxPYnNlcnZlci5lcnJvcikge1xuICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICBwYXJ0aWFsT2JzZXJ2ZXIuZXJyb3IoZXJyKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGNhdGNoIChlcnJvcikge1xuICAgICAgICAgICAgICAgIGhhbmRsZVVuaGFuZGxlZEVycm9yKGVycm9yKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgIGhhbmRsZVVuaGFuZGxlZEVycm9yKGVycik7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIENvbnN1bWVyT2JzZXJ2ZXIucHJvdG90eXBlLmNvbXBsZXRlID0gZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgcGFydGlhbE9ic2VydmVyID0gdGhpcy5wYXJ0aWFsT2JzZXJ2ZXI7XG4gICAgICAgIGlmIChwYXJ0aWFsT2JzZXJ2ZXIuY29tcGxldGUpIHtcbiAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgcGFydGlhbE9ic2VydmVyLmNvbXBsZXRlKCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBjYXRjaCAoZXJyb3IpIHtcbiAgICAgICAgICAgICAgICBoYW5kbGVVbmhhbmRsZWRFcnJvcihlcnJvcik7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9O1xuICAgIHJldHVybiBDb25zdW1lck9ic2VydmVyO1xufSgpKTtcbnZhciBTYWZlU3Vic2NyaWJlciA9IChmdW5jdGlvbiAoX3N1cGVyKSB7XG4gICAgX19leHRlbmRzKFNhZmVTdWJzY3JpYmVyLCBfc3VwZXIpO1xuICAgIGZ1bmN0aW9uIFNhZmVTdWJzY3JpYmVyKG9ic2VydmVyT3JOZXh0LCBlcnJvciwgY29tcGxldGUpIHtcbiAgICAgICAgdmFyIF90aGlzID0gX3N1cGVyLmNhbGwodGhpcykgfHwgdGhpcztcbiAgICAgICAgdmFyIHBhcnRpYWxPYnNlcnZlcjtcbiAgICAgICAgaWYgKGlzRnVuY3Rpb24ob2JzZXJ2ZXJPck5leHQpIHx8ICFvYnNlcnZlck9yTmV4dCkge1xuICAgICAgICAgICAgcGFydGlhbE9ic2VydmVyID0ge1xuICAgICAgICAgICAgICAgIG5leHQ6IChvYnNlcnZlck9yTmV4dCAhPT0gbnVsbCAmJiBvYnNlcnZlck9yTmV4dCAhPT0gdm9pZCAwID8gb2JzZXJ2ZXJPck5leHQgOiB1bmRlZmluZWQpLFxuICAgICAgICAgICAgICAgIGVycm9yOiBlcnJvciAhPT0gbnVsbCAmJiBlcnJvciAhPT0gdm9pZCAwID8gZXJyb3IgOiB1bmRlZmluZWQsXG4gICAgICAgICAgICAgICAgY29tcGxldGU6IGNvbXBsZXRlICE9PSBudWxsICYmIGNvbXBsZXRlICE9PSB2b2lkIDAgPyBjb21wbGV0ZSA6IHVuZGVmaW5lZCxcbiAgICAgICAgICAgIH07XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICB2YXIgY29udGV4dF8xO1xuICAgICAgICAgICAgaWYgKF90aGlzICYmIGNvbmZpZy51c2VEZXByZWNhdGVkTmV4dENvbnRleHQpIHtcbiAgICAgICAgICAgICAgICBjb250ZXh0XzEgPSBPYmplY3QuY3JlYXRlKG9ic2VydmVyT3JOZXh0KTtcbiAgICAgICAgICAgICAgICBjb250ZXh0XzEudW5zdWJzY3JpYmUgPSBmdW5jdGlvbiAoKSB7IHJldHVybiBfdGhpcy51bnN1YnNjcmliZSgpOyB9O1xuICAgICAgICAgICAgICAgIHBhcnRpYWxPYnNlcnZlciA9IHtcbiAgICAgICAgICAgICAgICAgICAgbmV4dDogb2JzZXJ2ZXJPck5leHQubmV4dCAmJiBiaW5kKG9ic2VydmVyT3JOZXh0Lm5leHQsIGNvbnRleHRfMSksXG4gICAgICAgICAgICAgICAgICAgIGVycm9yOiBvYnNlcnZlck9yTmV4dC5lcnJvciAmJiBiaW5kKG9ic2VydmVyT3JOZXh0LmVycm9yLCBjb250ZXh0XzEpLFxuICAgICAgICAgICAgICAgICAgICBjb21wbGV0ZTogb2JzZXJ2ZXJPck5leHQuY29tcGxldGUgJiYgYmluZChvYnNlcnZlck9yTmV4dC5jb21wbGV0ZSwgY29udGV4dF8xKSxcbiAgICAgICAgICAgICAgICB9O1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgZWxzZSB7XG4gICAgICAgICAgICAgICAgcGFydGlhbE9ic2VydmVyID0gb2JzZXJ2ZXJPck5leHQ7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgX3RoaXMuZGVzdGluYXRpb24gPSBuZXcgQ29uc3VtZXJPYnNlcnZlcihwYXJ0aWFsT2JzZXJ2ZXIpO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuICAgIHJldHVybiBTYWZlU3Vic2NyaWJlcjtcbn0oU3Vic2NyaWJlcikpO1xuZXhwb3J0IHsgU2FmZVN1YnNjcmliZXIgfTtcbmZ1bmN0aW9uIGhhbmRsZVVuaGFuZGxlZEVycm9yKGVycm9yKSB7XG4gICAgaWYgKGNvbmZpZy51c2VEZXByZWNhdGVkU3luY2hyb25vdXNFcnJvckhhbmRsaW5nKSB7XG4gICAgICAgIGNhcHR1cmVFcnJvcihlcnJvcik7XG4gICAgfVxuICAgIGVsc2Uge1xuICAgICAgICByZXBvcnRVbmhhbmRsZWRFcnJvcihlcnJvcik7XG4gICAgfVxufVxuZnVuY3Rpb24gZGVmYXVsdEVycm9ySGFuZGxlcihlcnIpIHtcbiAgICB0aHJvdyBlcnI7XG59XG5mdW5jdGlvbiBoYW5kbGVTdG9wcGVkTm90aWZpY2F0aW9uKG5vdGlmaWNhdGlvbiwgc3Vic2NyaWJlcikge1xuICAgIHZhciBvblN0b3BwZWROb3RpZmljYXRpb24gPSBjb25maWcub25TdG9wcGVkTm90aWZpY2F0aW9uO1xuICAgIG9uU3RvcHBlZE5vdGlmaWNhdGlvbiAmJiB0aW1lb3V0UHJvdmlkZXIuc2V0VGltZW91dChmdW5jdGlvbiAoKSB7IHJldHVybiBvblN0b3BwZWROb3RpZmljYXRpb24obm90aWZpY2F0aW9uLCBzdWJzY3JpYmVyKTsgfSk7XG59XG5leHBvcnQgdmFyIEVNUFRZX09CU0VSVkVSID0ge1xuICAgIGNsb3NlZDogdHJ1ZSxcbiAgICBuZXh0OiBub29wLFxuICAgIGVycm9yOiBkZWZhdWx0RXJyb3JIYW5kbGVyLFxuICAgIGNvbXBsZXRlOiBub29wLFxufTtcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPVN1YnNjcmliZXIuanMubWFwIiwiZXhwb3J0IHZhciBvYnNlcnZhYmxlID0gKGZ1bmN0aW9uICgpIHsgcmV0dXJuICh0eXBlb2YgU3ltYm9sID09PSAnZnVuY3Rpb24nICYmIFN5bWJvbC5vYnNlcnZhYmxlKSB8fCAnQEBvYnNlcnZhYmxlJzsgfSkoKTtcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPW9ic2VydmFibGUuanMubWFwIiwiZXhwb3J0IGZ1bmN0aW9uIGlkZW50aXR5KHgpIHtcbiAgICByZXR1cm4geDtcbn1cbi8vIyBzb3VyY2VNYXBwaW5nVVJMPWlkZW50aXR5LmpzLm1hcCIsImltcG9ydCB7IGlkZW50aXR5IH0gZnJvbSAnLi9pZGVudGl0eSc7XG5leHBvcnQgZnVuY3Rpb24gcGlwZSgpIHtcbiAgICB2YXIgZm5zID0gW107XG4gICAgZm9yICh2YXIgX2kgPSAwOyBfaSA8IGFyZ3VtZW50cy5sZW5ndGg7IF9pKyspIHtcbiAgICAgICAgZm5zW19pXSA9IGFyZ3VtZW50c1tfaV07XG4gICAgfVxuICAgIHJldHVybiBwaXBlRnJvbUFycmF5KGZucyk7XG59XG5leHBvcnQgZnVuY3Rpb24gcGlwZUZyb21BcnJheShmbnMpIHtcbiAgICBpZiAoZm5zLmxlbmd0aCA9PT0gMCkge1xuICAgICAgICByZXR1cm4gaWRlbnRpdHk7XG4gICAgfVxuICAgIGlmIChmbnMubGVuZ3RoID09PSAxKSB7XG4gICAgICAgIHJldHVybiBmbnNbMF07XG4gICAgfVxuICAgIHJldHVybiBmdW5jdGlvbiBwaXBlZChpbnB1dCkge1xuICAgICAgICByZXR1cm4gZm5zLnJlZHVjZShmdW5jdGlvbiAocHJldiwgZm4pIHsgcmV0dXJuIGZuKHByZXYpOyB9LCBpbnB1dCk7XG4gICAgfTtcbn1cbi8vIyBzb3VyY2VNYXBwaW5nVVJMPXBpcGUuanMubWFwIiwiaW1wb3J0IHsgU2FmZVN1YnNjcmliZXIsIFN1YnNjcmliZXIgfSBmcm9tICcuL1N1YnNjcmliZXInO1xuaW1wb3J0IHsgaXNTdWJzY3JpcHRpb24gfSBmcm9tICcuL1N1YnNjcmlwdGlvbic7XG5pbXBvcnQgeyBvYnNlcnZhYmxlIGFzIFN5bWJvbF9vYnNlcnZhYmxlIH0gZnJvbSAnLi9zeW1ib2wvb2JzZXJ2YWJsZSc7XG5pbXBvcnQgeyBwaXBlRnJvbUFycmF5IH0gZnJvbSAnLi91dGlsL3BpcGUnO1xuaW1wb3J0IHsgY29uZmlnIH0gZnJvbSAnLi9jb25maWcnO1xuaW1wb3J0IHsgaXNGdW5jdGlvbiB9IGZyb20gJy4vdXRpbC9pc0Z1bmN0aW9uJztcbmltcG9ydCB7IGVycm9yQ29udGV4dCB9IGZyb20gJy4vdXRpbC9lcnJvckNvbnRleHQnO1xudmFyIE9ic2VydmFibGUgPSAoZnVuY3Rpb24gKCkge1xuICAgIGZ1bmN0aW9uIE9ic2VydmFibGUoc3Vic2NyaWJlKSB7XG4gICAgICAgIGlmIChzdWJzY3JpYmUpIHtcbiAgICAgICAgICAgIHRoaXMuX3N1YnNjcmliZSA9IHN1YnNjcmliZTtcbiAgICAgICAgfVxuICAgIH1cbiAgICBPYnNlcnZhYmxlLnByb3RvdHlwZS5saWZ0ID0gZnVuY3Rpb24gKG9wZXJhdG9yKSB7XG4gICAgICAgIHZhciBvYnNlcnZhYmxlID0gbmV3IE9ic2VydmFibGUoKTtcbiAgICAgICAgb2JzZXJ2YWJsZS5zb3VyY2UgPSB0aGlzO1xuICAgICAgICBvYnNlcnZhYmxlLm9wZXJhdG9yID0gb3BlcmF0b3I7XG4gICAgICAgIHJldHVybiBvYnNlcnZhYmxlO1xuICAgIH07XG4gICAgT2JzZXJ2YWJsZS5wcm90b3R5cGUuc3Vic2NyaWJlID0gZnVuY3Rpb24gKG9ic2VydmVyT3JOZXh0LCBlcnJvciwgY29tcGxldGUpIHtcbiAgICAgICAgdmFyIF90aGlzID0gdGhpcztcbiAgICAgICAgdmFyIHN1YnNjcmliZXIgPSBpc1N1YnNjcmliZXIob2JzZXJ2ZXJPck5leHQpID8gb2JzZXJ2ZXJPck5leHQgOiBuZXcgU2FmZVN1YnNjcmliZXIob2JzZXJ2ZXJPck5leHQsIGVycm9yLCBjb21wbGV0ZSk7XG4gICAgICAgIGVycm9yQ29udGV4dChmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICB2YXIgX2EgPSBfdGhpcywgb3BlcmF0b3IgPSBfYS5vcGVyYXRvciwgc291cmNlID0gX2Euc291cmNlO1xuICAgICAgICAgICAgc3Vic2NyaWJlci5hZGQob3BlcmF0b3JcbiAgICAgICAgICAgICAgICA/XG4gICAgICAgICAgICAgICAgICAgIG9wZXJhdG9yLmNhbGwoc3Vic2NyaWJlciwgc291cmNlKVxuICAgICAgICAgICAgICAgIDogc291cmNlXG4gICAgICAgICAgICAgICAgICAgID9cbiAgICAgICAgICAgICAgICAgICAgICAgIF90aGlzLl9zdWJzY3JpYmUoc3Vic2NyaWJlcilcbiAgICAgICAgICAgICAgICAgICAgOlxuICAgICAgICAgICAgICAgICAgICAgICAgX3RoaXMuX3RyeVN1YnNjcmliZShzdWJzY3JpYmVyKSk7XG4gICAgICAgIH0pO1xuICAgICAgICByZXR1cm4gc3Vic2NyaWJlcjtcbiAgICB9O1xuICAgIE9ic2VydmFibGUucHJvdG90eXBlLl90cnlTdWJzY3JpYmUgPSBmdW5jdGlvbiAoc2luaykge1xuICAgICAgICB0cnkge1xuICAgICAgICAgICAgcmV0dXJuIHRoaXMuX3N1YnNjcmliZShzaW5rKTtcbiAgICAgICAgfVxuICAgICAgICBjYXRjaCAoZXJyKSB7XG4gICAgICAgICAgICBzaW5rLmVycm9yKGVycik7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIE9ic2VydmFibGUucHJvdG90eXBlLmZvckVhY2ggPSBmdW5jdGlvbiAobmV4dCwgcHJvbWlzZUN0b3IpIHtcbiAgICAgICAgdmFyIF90aGlzID0gdGhpcztcbiAgICAgICAgcHJvbWlzZUN0b3IgPSBnZXRQcm9taXNlQ3Rvcihwcm9taXNlQ3Rvcik7XG4gICAgICAgIHJldHVybiBuZXcgcHJvbWlzZUN0b3IoZnVuY3Rpb24gKHJlc29sdmUsIHJlamVjdCkge1xuICAgICAgICAgICAgdmFyIHN1YnNjcmliZXIgPSBuZXcgU2FmZVN1YnNjcmliZXIoe1xuICAgICAgICAgICAgICAgIG5leHQ6IGZ1bmN0aW9uICh2YWx1ZSkge1xuICAgICAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICAgICAgbmV4dCh2YWx1ZSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgY2F0Y2ggKGVycikge1xuICAgICAgICAgICAgICAgICAgICAgICAgcmVqZWN0KGVycik7XG4gICAgICAgICAgICAgICAgICAgICAgICBzdWJzY3JpYmVyLnVuc3Vic2NyaWJlKCk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICAgIGVycm9yOiByZWplY3QsXG4gICAgICAgICAgICAgICAgY29tcGxldGU6IHJlc29sdmUsXG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIF90aGlzLnN1YnNjcmliZShzdWJzY3JpYmVyKTtcbiAgICAgICAgfSk7XG4gICAgfTtcbiAgICBPYnNlcnZhYmxlLnByb3RvdHlwZS5fc3Vic2NyaWJlID0gZnVuY3Rpb24gKHN1YnNjcmliZXIpIHtcbiAgICAgICAgdmFyIF9hO1xuICAgICAgICByZXR1cm4gKF9hID0gdGhpcy5zb3VyY2UpID09PSBudWxsIHx8IF9hID09PSB2b2lkIDAgPyB2b2lkIDAgOiBfYS5zdWJzY3JpYmUoc3Vic2NyaWJlcik7XG4gICAgfTtcbiAgICBPYnNlcnZhYmxlLnByb3RvdHlwZVtTeW1ib2xfb2JzZXJ2YWJsZV0gPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgIHJldHVybiB0aGlzO1xuICAgIH07XG4gICAgT2JzZXJ2YWJsZS5wcm90b3R5cGUucGlwZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIG9wZXJhdGlvbnMgPSBbXTtcbiAgICAgICAgZm9yICh2YXIgX2kgPSAwOyBfaSA8IGFyZ3VtZW50cy5sZW5ndGg7IF9pKyspIHtcbiAgICAgICAgICAgIG9wZXJhdGlvbnNbX2ldID0gYXJndW1lbnRzW19pXTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gcGlwZUZyb21BcnJheShvcGVyYXRpb25zKSh0aGlzKTtcbiAgICB9O1xuICAgIE9ic2VydmFibGUucHJvdG90eXBlLnRvUHJvbWlzZSA9IGZ1bmN0aW9uIChwcm9taXNlQ3Rvcikge1xuICAgICAgICB2YXIgX3RoaXMgPSB0aGlzO1xuICAgICAgICBwcm9taXNlQ3RvciA9IGdldFByb21pc2VDdG9yKHByb21pc2VDdG9yKTtcbiAgICAgICAgcmV0dXJuIG5ldyBwcm9taXNlQ3RvcihmdW5jdGlvbiAocmVzb2x2ZSwgcmVqZWN0KSB7XG4gICAgICAgICAgICB2YXIgdmFsdWU7XG4gICAgICAgICAgICBfdGhpcy5zdWJzY3JpYmUoZnVuY3Rpb24gKHgpIHsgcmV0dXJuICh2YWx1ZSA9IHgpOyB9LCBmdW5jdGlvbiAoZXJyKSB7IHJldHVybiByZWplY3QoZXJyKTsgfSwgZnVuY3Rpb24gKCkgeyByZXR1cm4gcmVzb2x2ZSh2YWx1ZSk7IH0pO1xuICAgICAgICB9KTtcbiAgICB9O1xuICAgIE9ic2VydmFibGUuY3JlYXRlID0gZnVuY3Rpb24gKHN1YnNjcmliZSkge1xuICAgICAgICByZXR1cm4gbmV3IE9ic2VydmFibGUoc3Vic2NyaWJlKTtcbiAgICB9O1xuICAgIHJldHVybiBPYnNlcnZhYmxlO1xufSgpKTtcbmV4cG9ydCB7IE9ic2VydmFibGUgfTtcbmZ1bmN0aW9uIGdldFByb21pc2VDdG9yKHByb21pc2VDdG9yKSB7XG4gICAgdmFyIF9hO1xuICAgIHJldHVybiAoX2EgPSBwcm9taXNlQ3RvciAhPT0gbnVsbCAmJiBwcm9taXNlQ3RvciAhPT0gdm9pZCAwID8gcHJvbWlzZUN0b3IgOiBjb25maWcuUHJvbWlzZSkgIT09IG51bGwgJiYgX2EgIT09IHZvaWQgMCA/IF9hIDogUHJvbWlzZTtcbn1cbmZ1bmN0aW9uIGlzT2JzZXJ2ZXIodmFsdWUpIHtcbiAgICByZXR1cm4gdmFsdWUgJiYgaXNGdW5jdGlvbih2YWx1ZS5uZXh0KSAmJiBpc0Z1bmN0aW9uKHZhbHVlLmVycm9yKSAmJiBpc0Z1bmN0aW9uKHZhbHVlLmNvbXBsZXRlKTtcbn1cbmZ1bmN0aW9uIGlzU3Vic2NyaWJlcih2YWx1ZSkge1xuICAgIHJldHVybiAodmFsdWUgJiYgdmFsdWUgaW5zdGFuY2VvZiBTdWJzY3JpYmVyKSB8fCAoaXNPYnNlcnZlcih2YWx1ZSkgJiYgaXNTdWJzY3JpcHRpb24odmFsdWUpKTtcbn1cbi8vIyBzb3VyY2VNYXBwaW5nVVJMPU9ic2VydmFibGUuanMubWFwIiwiaW1wb3J0IHsgaXNGdW5jdGlvbiB9IGZyb20gJy4vaXNGdW5jdGlvbic7XG5leHBvcnQgZnVuY3Rpb24gaGFzTGlmdChzb3VyY2UpIHtcbiAgICByZXR1cm4gaXNGdW5jdGlvbihzb3VyY2UgPT09IG51bGwgfHwgc291cmNlID09PSB2b2lkIDAgPyB2b2lkIDAgOiBzb3VyY2UubGlmdCk7XG59XG5leHBvcnQgZnVuY3Rpb24gb3BlcmF0ZShpbml0KSB7XG4gICAgcmV0dXJuIGZ1bmN0aW9uIChzb3VyY2UpIHtcbiAgICAgICAgaWYgKGhhc0xpZnQoc291cmNlKSkge1xuICAgICAgICAgICAgcmV0dXJuIHNvdXJjZS5saWZ0KGZ1bmN0aW9uIChsaWZ0ZWRTb3VyY2UpIHtcbiAgICAgICAgICAgICAgICB0cnkge1xuICAgICAgICAgICAgICAgICAgICByZXR1cm4gaW5pdChsaWZ0ZWRTb3VyY2UsIHRoaXMpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBjYXRjaCAoZXJyKSB7XG4gICAgICAgICAgICAgICAgICAgIHRoaXMuZXJyb3IoZXJyKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfVxuICAgICAgICB0aHJvdyBuZXcgVHlwZUVycm9yKCdVbmFibGUgdG8gbGlmdCB1bmtub3duIE9ic2VydmFibGUgdHlwZScpO1xuICAgIH07XG59XG4vLyMgc291cmNlTWFwcGluZ1VSTD1saWZ0LmpzLm1hcCIsImltcG9ydCB7IF9fZXh0ZW5kcyB9IGZyb20gXCJ0c2xpYlwiO1xuaW1wb3J0IHsgU3Vic2NyaWJlciB9IGZyb20gJy4uL1N1YnNjcmliZXInO1xuZXhwb3J0IGZ1bmN0aW9uIGNyZWF0ZU9wZXJhdG9yU3Vic2NyaWJlcihkZXN0aW5hdGlvbiwgb25OZXh0LCBvbkNvbXBsZXRlLCBvbkVycm9yLCBvbkZpbmFsaXplKSB7XG4gICAgcmV0dXJuIG5ldyBPcGVyYXRvclN1YnNjcmliZXIoZGVzdGluYXRpb24sIG9uTmV4dCwgb25Db21wbGV0ZSwgb25FcnJvciwgb25GaW5hbGl6ZSk7XG59XG52YXIgT3BlcmF0b3JTdWJzY3JpYmVyID0gKGZ1bmN0aW9uIChfc3VwZXIpIHtcbiAgICBfX2V4dGVuZHMoT3BlcmF0b3JTdWJzY3JpYmVyLCBfc3VwZXIpO1xuICAgIGZ1bmN0aW9uIE9wZXJhdG9yU3Vic2NyaWJlcihkZXN0aW5hdGlvbiwgb25OZXh0LCBvbkNvbXBsZXRlLCBvbkVycm9yLCBvbkZpbmFsaXplLCBzaG91bGRVbnN1YnNjcmliZSkge1xuICAgICAgICB2YXIgX3RoaXMgPSBfc3VwZXIuY2FsbCh0aGlzLCBkZXN0aW5hdGlvbikgfHwgdGhpcztcbiAgICAgICAgX3RoaXMub25GaW5hbGl6ZSA9IG9uRmluYWxpemU7XG4gICAgICAgIF90aGlzLnNob3VsZFVuc3Vic2NyaWJlID0gc2hvdWxkVW5zdWJzY3JpYmU7XG4gICAgICAgIF90aGlzLl9uZXh0ID0gb25OZXh0XG4gICAgICAgICAgICA/IGZ1bmN0aW9uICh2YWx1ZSkge1xuICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgIG9uTmV4dCh2YWx1ZSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIGNhdGNoIChlcnIpIHtcbiAgICAgICAgICAgICAgICAgICAgZGVzdGluYXRpb24uZXJyb3IoZXJyKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICA6IF9zdXBlci5wcm90b3R5cGUuX25leHQ7XG4gICAgICAgIF90aGlzLl9lcnJvciA9IG9uRXJyb3JcbiAgICAgICAgICAgID8gZnVuY3Rpb24gKGVycikge1xuICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgIG9uRXJyb3IoZXJyKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgY2F0Y2ggKGVycikge1xuICAgICAgICAgICAgICAgICAgICBkZXN0aW5hdGlvbi5lcnJvcihlcnIpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBmaW5hbGx5IHtcbiAgICAgICAgICAgICAgICAgICAgdGhpcy51bnN1YnNjcmliZSgpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIDogX3N1cGVyLnByb3RvdHlwZS5fZXJyb3I7XG4gICAgICAgIF90aGlzLl9jb21wbGV0ZSA9IG9uQ29tcGxldGVcbiAgICAgICAgICAgID8gZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgIG9uQ29tcGxldGUoKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgY2F0Y2ggKGVycikge1xuICAgICAgICAgICAgICAgICAgICBkZXN0aW5hdGlvbi5lcnJvcihlcnIpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICBmaW5hbGx5IHtcbiAgICAgICAgICAgICAgICAgICAgdGhpcy51bnN1YnNjcmliZSgpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIDogX3N1cGVyLnByb3RvdHlwZS5fY29tcGxldGU7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG4gICAgT3BlcmF0b3JTdWJzY3JpYmVyLnByb3RvdHlwZS51bnN1YnNjcmliZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgdmFyIF9hO1xuICAgICAgICBpZiAoIXRoaXMuc2hvdWxkVW5zdWJzY3JpYmUgfHwgdGhpcy5zaG91bGRVbnN1YnNjcmliZSgpKSB7XG4gICAgICAgICAgICB2YXIgY2xvc2VkXzEgPSB0aGlzLmNsb3NlZDtcbiAgICAgICAgICAgIF9zdXBlci5wcm90b3R5cGUudW5zdWJzY3JpYmUuY2FsbCh0aGlzKTtcbiAgICAgICAgICAgICFjbG9zZWRfMSAmJiAoKF9hID0gdGhpcy5vbkZpbmFsaXplKSA9PT0gbnVsbCB8fCBfYSA9PT0gdm9pZCAwID8gdm9pZCAwIDogX2EuY2FsbCh0aGlzKSk7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIHJldHVybiBPcGVyYXRvclN1YnNjcmliZXI7XG59KFN1YnNjcmliZXIpKTtcbmV4cG9ydCB7IE9wZXJhdG9yU3Vic2NyaWJlciB9O1xuLy8jIHNvdXJjZU1hcHBpbmdVUkw9T3BlcmF0b3JTdWJzY3JpYmVyLmpzLm1hcCIsImltcG9ydCB7IGNyZWF0ZUVycm9yQ2xhc3MgfSBmcm9tICcuL2NyZWF0ZUVycm9yQ2xhc3MnO1xuZXhwb3J0IHZhciBPYmplY3RVbnN1YnNjcmliZWRFcnJvciA9IGNyZWF0ZUVycm9yQ2xhc3MoZnVuY3Rpb24gKF9zdXBlcikge1xuICAgIHJldHVybiBmdW5jdGlvbiBPYmplY3RVbnN1YnNjcmliZWRFcnJvckltcGwoKSB7XG4gICAgICAgIF9zdXBlcih0aGlzKTtcbiAgICAgICAgdGhpcy5uYW1lID0gJ09iamVjdFVuc3Vic2NyaWJlZEVycm9yJztcbiAgICAgICAgdGhpcy5tZXNzYWdlID0gJ29iamVjdCB1bnN1YnNjcmliZWQnO1xuICAgIH07XG59KTtcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPU9iamVjdFVuc3Vic2NyaWJlZEVycm9yLmpzLm1hcCIsImltcG9ydCB7IF9fZXh0ZW5kcywgX192YWx1ZXMgfSBmcm9tIFwidHNsaWJcIjtcbmltcG9ydCB7IE9ic2VydmFibGUgfSBmcm9tICcuL09ic2VydmFibGUnO1xuaW1wb3J0IHsgU3Vic2NyaXB0aW9uLCBFTVBUWV9TVUJTQ1JJUFRJT04gfSBmcm9tICcuL1N1YnNjcmlwdGlvbic7XG5pbXBvcnQgeyBPYmplY3RVbnN1YnNjcmliZWRFcnJvciB9IGZyb20gJy4vdXRpbC9PYmplY3RVbnN1YnNjcmliZWRFcnJvcic7XG5pbXBvcnQgeyBhcnJSZW1vdmUgfSBmcm9tICcuL3V0aWwvYXJyUmVtb3ZlJztcbmltcG9ydCB7IGVycm9yQ29udGV4dCB9IGZyb20gJy4vdXRpbC9lcnJvckNvbnRleHQnO1xudmFyIFN1YmplY3QgPSAoZnVuY3Rpb24gKF9zdXBlcikge1xuICAgIF9fZXh0ZW5kcyhTdWJqZWN0LCBfc3VwZXIpO1xuICAgIGZ1bmN0aW9uIFN1YmplY3QoKSB7XG4gICAgICAgIHZhciBfdGhpcyA9IF9zdXBlci5jYWxsKHRoaXMpIHx8IHRoaXM7XG4gICAgICAgIF90aGlzLmNsb3NlZCA9IGZhbHNlO1xuICAgICAgICBfdGhpcy5jdXJyZW50T2JzZXJ2ZXJzID0gbnVsbDtcbiAgICAgICAgX3RoaXMub2JzZXJ2ZXJzID0gW107XG4gICAgICAgIF90aGlzLmlzU3RvcHBlZCA9IGZhbHNlO1xuICAgICAgICBfdGhpcy5oYXNFcnJvciA9IGZhbHNlO1xuICAgICAgICBfdGhpcy50aHJvd25FcnJvciA9IG51bGw7XG4gICAgICAgIHJldHVybiBfdGhpcztcbiAgICB9XG4gICAgU3ViamVjdC5wcm90b3R5cGUubGlmdCA9IGZ1bmN0aW9uIChvcGVyYXRvcikge1xuICAgICAgICB2YXIgc3ViamVjdCA9IG5ldyBBbm9ueW1vdXNTdWJqZWN0KHRoaXMsIHRoaXMpO1xuICAgICAgICBzdWJqZWN0Lm9wZXJhdG9yID0gb3BlcmF0b3I7XG4gICAgICAgIHJldHVybiBzdWJqZWN0O1xuICAgIH07XG4gICAgU3ViamVjdC5wcm90b3R5cGUuX3Rocm93SWZDbG9zZWQgPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgIGlmICh0aGlzLmNsb3NlZCkge1xuICAgICAgICAgICAgdGhyb3cgbmV3IE9iamVjdFVuc3Vic2NyaWJlZEVycm9yKCk7XG4gICAgICAgIH1cbiAgICB9O1xuICAgIFN1YmplY3QucHJvdG90eXBlLm5leHQgPSBmdW5jdGlvbiAodmFsdWUpIHtcbiAgICAgICAgdmFyIF90aGlzID0gdGhpcztcbiAgICAgICAgZXJyb3JDb250ZXh0KGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgIHZhciBlXzEsIF9hO1xuICAgICAgICAgICAgX3RoaXMuX3Rocm93SWZDbG9zZWQoKTtcbiAgICAgICAgICAgIGlmICghX3RoaXMuaXNTdG9wcGVkKSB7XG4gICAgICAgICAgICAgICAgaWYgKCFfdGhpcy5jdXJyZW50T2JzZXJ2ZXJzKSB7XG4gICAgICAgICAgICAgICAgICAgIF90aGlzLmN1cnJlbnRPYnNlcnZlcnMgPSBBcnJheS5mcm9tKF90aGlzLm9ic2VydmVycyk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgICAgIGZvciAodmFyIF9iID0gX192YWx1ZXMoX3RoaXMuY3VycmVudE9ic2VydmVycyksIF9jID0gX2IubmV4dCgpOyAhX2MuZG9uZTsgX2MgPSBfYi5uZXh0KCkpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHZhciBvYnNlcnZlciA9IF9jLnZhbHVlO1xuICAgICAgICAgICAgICAgICAgICAgICAgb2JzZXJ2ZXIubmV4dCh2YWx1ZSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgY2F0Y2ggKGVfMV8xKSB7IGVfMSA9IHsgZXJyb3I6IGVfMV8xIH07IH1cbiAgICAgICAgICAgICAgICBmaW5hbGx5IHtcbiAgICAgICAgICAgICAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmIChfYyAmJiAhX2MuZG9uZSAmJiAoX2EgPSBfYi5yZXR1cm4pKSBfYS5jYWxsKF9iKTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBmaW5hbGx5IHsgaWYgKGVfMSkgdGhyb3cgZV8xLmVycm9yOyB9XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICB9O1xuICAgIFN1YmplY3QucHJvdG90eXBlLmVycm9yID0gZnVuY3Rpb24gKGVycikge1xuICAgICAgICB2YXIgX3RoaXMgPSB0aGlzO1xuICAgICAgICBlcnJvckNvbnRleHQoZnVuY3Rpb24gKCkge1xuICAgICAgICAgICAgX3RoaXMuX3Rocm93SWZDbG9zZWQoKTtcbiAgICAgICAgICAgIGlmICghX3RoaXMuaXNTdG9wcGVkKSB7XG4gICAgICAgICAgICAgICAgX3RoaXMuaGFzRXJyb3IgPSBfdGhpcy5pc1N0b3BwZWQgPSB0cnVlO1xuICAgICAgICAgICAgICAgIF90aGlzLnRocm93bkVycm9yID0gZXJyO1xuICAgICAgICAgICAgICAgIHZhciBvYnNlcnZlcnMgPSBfdGhpcy5vYnNlcnZlcnM7XG4gICAgICAgICAgICAgICAgd2hpbGUgKG9ic2VydmVycy5sZW5ndGgpIHtcbiAgICAgICAgICAgICAgICAgICAgb2JzZXJ2ZXJzLnNoaWZ0KCkuZXJyb3IoZXJyKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgIH07XG4gICAgU3ViamVjdC5wcm90b3R5cGUuY29tcGxldGUgPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBfdGhpcyA9IHRoaXM7XG4gICAgICAgIGVycm9yQ29udGV4dChmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICBfdGhpcy5fdGhyb3dJZkNsb3NlZCgpO1xuICAgICAgICAgICAgaWYgKCFfdGhpcy5pc1N0b3BwZWQpIHtcbiAgICAgICAgICAgICAgICBfdGhpcy5pc1N0b3BwZWQgPSB0cnVlO1xuICAgICAgICAgICAgICAgIHZhciBvYnNlcnZlcnMgPSBfdGhpcy5vYnNlcnZlcnM7XG4gICAgICAgICAgICAgICAgd2hpbGUgKG9ic2VydmVycy5sZW5ndGgpIHtcbiAgICAgICAgICAgICAgICAgICAgb2JzZXJ2ZXJzLnNoaWZ0KCkuY29tcGxldGUoKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgIH07XG4gICAgU3ViamVjdC5wcm90b3R5cGUudW5zdWJzY3JpYmUgPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgIHRoaXMuaXNTdG9wcGVkID0gdGhpcy5jbG9zZWQgPSB0cnVlO1xuICAgICAgICB0aGlzLm9ic2VydmVycyA9IHRoaXMuY3VycmVudE9ic2VydmVycyA9IG51bGw7XG4gICAgfTtcbiAgICBPYmplY3QuZGVmaW5lUHJvcGVydHkoU3ViamVjdC5wcm90b3R5cGUsIFwib2JzZXJ2ZWRcIiwge1xuICAgICAgICBnZXQ6IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgIHZhciBfYTtcbiAgICAgICAgICAgIHJldHVybiAoKF9hID0gdGhpcy5vYnNlcnZlcnMpID09PSBudWxsIHx8IF9hID09PSB2b2lkIDAgPyB2b2lkIDAgOiBfYS5sZW5ndGgpID4gMDtcbiAgICAgICAgfSxcbiAgICAgICAgZW51bWVyYWJsZTogZmFsc2UsXG4gICAgICAgIGNvbmZpZ3VyYWJsZTogdHJ1ZVxuICAgIH0pO1xuICAgIFN1YmplY3QucHJvdG90eXBlLl90cnlTdWJzY3JpYmUgPSBmdW5jdGlvbiAoc3Vic2NyaWJlcikge1xuICAgICAgICB0aGlzLl90aHJvd0lmQ2xvc2VkKCk7XG4gICAgICAgIHJldHVybiBfc3VwZXIucHJvdG90eXBlLl90cnlTdWJzY3JpYmUuY2FsbCh0aGlzLCBzdWJzY3JpYmVyKTtcbiAgICB9O1xuICAgIFN1YmplY3QucHJvdG90eXBlLl9zdWJzY3JpYmUgPSBmdW5jdGlvbiAoc3Vic2NyaWJlcikge1xuICAgICAgICB0aGlzLl90aHJvd0lmQ2xvc2VkKCk7XG4gICAgICAgIHRoaXMuX2NoZWNrRmluYWxpemVkU3RhdHVzZXMoc3Vic2NyaWJlcik7XG4gICAgICAgIHJldHVybiB0aGlzLl9pbm5lclN1YnNjcmliZShzdWJzY3JpYmVyKTtcbiAgICB9O1xuICAgIFN1YmplY3QucHJvdG90eXBlLl9pbm5lclN1YnNjcmliZSA9IGZ1bmN0aW9uIChzdWJzY3JpYmVyKSB7XG4gICAgICAgIHZhciBfdGhpcyA9IHRoaXM7XG4gICAgICAgIHZhciBfYSA9IHRoaXMsIGhhc0Vycm9yID0gX2EuaGFzRXJyb3IsIGlzU3RvcHBlZCA9IF9hLmlzU3RvcHBlZCwgb2JzZXJ2ZXJzID0gX2Eub2JzZXJ2ZXJzO1xuICAgICAgICBpZiAoaGFzRXJyb3IgfHwgaXNTdG9wcGVkKSB7XG4gICAgICAgICAgICByZXR1cm4gRU1QVFlfU1VCU0NSSVBUSU9OO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuY3VycmVudE9ic2VydmVycyA9IG51bGw7XG4gICAgICAgIG9ic2VydmVycy5wdXNoKHN1YnNjcmliZXIpO1xuICAgICAgICByZXR1cm4gbmV3IFN1YnNjcmlwdGlvbihmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICBfdGhpcy5jdXJyZW50T2JzZXJ2ZXJzID0gbnVsbDtcbiAgICAgICAgICAgIGFyclJlbW92ZShvYnNlcnZlcnMsIHN1YnNjcmliZXIpO1xuICAgICAgICB9KTtcbiAgICB9O1xuICAgIFN1YmplY3QucHJvdG90eXBlLl9jaGVja0ZpbmFsaXplZFN0YXR1c2VzID0gZnVuY3Rpb24gKHN1YnNjcmliZXIpIHtcbiAgICAgICAgdmFyIF9hID0gdGhpcywgaGFzRXJyb3IgPSBfYS5oYXNFcnJvciwgdGhyb3duRXJyb3IgPSBfYS50aHJvd25FcnJvciwgaXNTdG9wcGVkID0gX2EuaXNTdG9wcGVkO1xuICAgICAgICBpZiAoaGFzRXJyb3IpIHtcbiAgICAgICAgICAgIHN1YnNjcmliZXIuZXJyb3IodGhyb3duRXJyb3IpO1xuICAgICAgICB9XG4gICAgICAgIGVsc2UgaWYgKGlzU3RvcHBlZCkge1xuICAgICAgICAgICAgc3Vic2NyaWJlci5jb21wbGV0ZSgpO1xuICAgICAgICB9XG4gICAgfTtcbiAgICBTdWJqZWN0LnByb3RvdHlwZS5hc09ic2VydmFibGUgPSBmdW5jdGlvbiAoKSB7XG4gICAgICAgIHZhciBvYnNlcnZhYmxlID0gbmV3IE9ic2VydmFibGUoKTtcbiAgICAgICAgb2JzZXJ2YWJsZS5zb3VyY2UgPSB0aGlzO1xuICAgICAgICByZXR1cm4gb2JzZXJ2YWJsZTtcbiAgICB9O1xuICAgIFN1YmplY3QuY3JlYXRlID0gZnVuY3Rpb24gKGRlc3RpbmF0aW9uLCBzb3VyY2UpIHtcbiAgICAgICAgcmV0dXJuIG5ldyBBbm9ueW1vdXNTdWJqZWN0KGRlc3RpbmF0aW9uLCBzb3VyY2UpO1xuICAgIH07XG4gICAgcmV0dXJuIFN1YmplY3Q7XG59KE9ic2VydmFibGUpKTtcbmV4cG9ydCB7IFN1YmplY3QgfTtcbnZhciBBbm9ueW1vdXNTdWJqZWN0ID0gKGZ1bmN0aW9uIChfc3VwZXIpIHtcbiAgICBfX2V4dGVuZHMoQW5vbnltb3VzU3ViamVjdCwgX3N1cGVyKTtcbiAgICBmdW5jdGlvbiBBbm9ueW1vdXNTdWJqZWN0KGRlc3RpbmF0aW9uLCBzb3VyY2UpIHtcbiAgICAgICAgdmFyIF90aGlzID0gX3N1cGVyLmNhbGwodGhpcykgfHwgdGhpcztcbiAgICAgICAgX3RoaXMuZGVzdGluYXRpb24gPSBkZXN0aW5hdGlvbjtcbiAgICAgICAgX3RoaXMuc291cmNlID0gc291cmNlO1xuICAgICAgICByZXR1cm4gX3RoaXM7XG4gICAgfVxuICAgIEFub255bW91c1N1YmplY3QucHJvdG90eXBlLm5leHQgPSBmdW5jdGlvbiAodmFsdWUpIHtcbiAgICAgICAgdmFyIF9hLCBfYjtcbiAgICAgICAgKF9iID0gKF9hID0gdGhpcy5kZXN0aW5hdGlvbikgPT09IG51bGwgfHwgX2EgPT09IHZvaWQgMCA/IHZvaWQgMCA6IF9hLm5leHQpID09PSBudWxsIHx8IF9iID09PSB2b2lkIDAgPyB2b2lkIDAgOiBfYi5jYWxsKF9hLCB2YWx1ZSk7XG4gICAgfTtcbiAgICBBbm9ueW1vdXNTdWJqZWN0LnByb3RvdHlwZS5lcnJvciA9IGZ1bmN0aW9uIChlcnIpIHtcbiAgICAgICAgdmFyIF9hLCBfYjtcbiAgICAgICAgKF9iID0gKF9hID0gdGhpcy5kZXN0aW5hdGlvbikgPT09IG51bGwgfHwgX2EgPT09IHZvaWQgMCA/IHZvaWQgMCA6IF9hLmVycm9yKSA9PT0gbnVsbCB8fCBfYiA9PT0gdm9pZCAwID8gdm9pZCAwIDogX2IuY2FsbChfYSwgZXJyKTtcbiAgICB9O1xuICAgIEFub255bW91c1N1YmplY3QucHJvdG90eXBlLmNvbXBsZXRlID0gZnVuY3Rpb24gKCkge1xuICAgICAgICB2YXIgX2EsIF9iO1xuICAgICAgICAoX2IgPSAoX2EgPSB0aGlzLmRlc3RpbmF0aW9uKSA9PT0gbnVsbCB8fCBfYSA9PT0gdm9pZCAwID8gdm9pZCAwIDogX2EuY29tcGxldGUpID09PSBudWxsIHx8IF9iID09PSB2b2lkIDAgPyB2b2lkIDAgOiBfYi5jYWxsKF9hKTtcbiAgICB9O1xuICAgIEFub255bW91c1N1YmplY3QucHJvdG90eXBlLl9zdWJzY3JpYmUgPSBmdW5jdGlvbiAoc3Vic2NyaWJlcikge1xuICAgICAgICB2YXIgX2EsIF9iO1xuICAgICAgICByZXR1cm4gKF9iID0gKF9hID0gdGhpcy5zb3VyY2UpID09PSBudWxsIHx8IF9hID09PSB2b2lkIDAgPyB2b2lkIDAgOiBfYS5zdWJzY3JpYmUoc3Vic2NyaWJlcikpICE9PSBudWxsICYmIF9iICE9PSB2b2lkIDAgPyBfYiA6IEVNUFRZX1NVQlNDUklQVElPTjtcbiAgICB9O1xuICAgIHJldHVybiBBbm9ueW1vdXNTdWJqZWN0O1xufShTdWJqZWN0KSk7XG5leHBvcnQgeyBBbm9ueW1vdXNTdWJqZWN0IH07XG4vLyMgc291cmNlTWFwcGluZ1VSTD1TdWJqZWN0LmpzLm1hcCIsImltcG9ydCB7IG9wZXJhdGUgfSBmcm9tICcuLi91dGlsL2xpZnQnO1xuaW1wb3J0IHsgY3JlYXRlT3BlcmF0b3JTdWJzY3JpYmVyIH0gZnJvbSAnLi9PcGVyYXRvclN1YnNjcmliZXInO1xuZXhwb3J0IGZ1bmN0aW9uIG1hcChwcm9qZWN0LCB0aGlzQXJnKSB7XG4gICAgcmV0dXJuIG9wZXJhdGUoZnVuY3Rpb24gKHNvdXJjZSwgc3Vic2NyaWJlcikge1xuICAgICAgICB2YXIgaW5kZXggPSAwO1xuICAgICAgICBzb3VyY2Uuc3Vic2NyaWJlKGNyZWF0ZU9wZXJhdG9yU3Vic2NyaWJlcihzdWJzY3JpYmVyLCBmdW5jdGlvbiAodmFsdWUpIHtcbiAgICAgICAgICAgIHN1YnNjcmliZXIubmV4dChwcm9qZWN0LmNhbGwodGhpc0FyZywgdmFsdWUsIGluZGV4KyspKTtcbiAgICAgICAgfSkpO1xuICAgIH0pO1xufVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9bWFwLmpzLm1hcCIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG5leHBvcnQgZnVuY3Rpb24gaXNQcm9taXNlQ29tcGxldGlvblNvdXJjZTxUPihvYmo6IGFueSk6IG9iaiBpcyBQcm9taXNlQ29tcGxldGlvblNvdXJjZTxUPiB7XHJcbiAgICByZXR1cm4gb2JqLnByb21pc2VcclxuICAgICAgICAmJiBvYmoucmVzb2x2ZVxyXG4gICAgICAgICYmIG9iai5yZWplY3Q7XHJcbn1cclxuXHJcbmV4cG9ydCBjbGFzcyBQcm9taXNlQ29tcGxldGlvblNvdXJjZTxUPiB7XHJcbiAgICBwcml2YXRlIF9yZXNvbHZlOiAodmFsdWU6IFQpID0+IHZvaWQgPSAoKSA9PiB7IH07XHJcbiAgICBwcml2YXRlIF9yZWplY3Q6IChyZWFzb246IGFueSkgPT4gdm9pZCA9ICgpID0+IHsgfTtcclxuICAgIHJlYWRvbmx5IHByb21pc2U6IFByb21pc2U8VD47XHJcblxyXG4gICAgY29uc3RydWN0b3IoKSB7XHJcbiAgICAgICAgdGhpcy5wcm9taXNlID0gbmV3IFByb21pc2U8VD4oKHJlc29sdmUsIHJlamVjdCkgPT4ge1xyXG4gICAgICAgICAgICB0aGlzLl9yZXNvbHZlID0gcmVzb2x2ZTtcclxuICAgICAgICAgICAgdGhpcy5fcmVqZWN0ID0gcmVqZWN0O1xyXG4gICAgICAgIH0pO1xyXG4gICAgfVxyXG5cclxuICAgIHJlc29sdmUodmFsdWU6IFQpIHtcclxuICAgICAgICB0aGlzLl9yZXNvbHZlKHZhbHVlKTtcclxuICAgIH1cclxuXHJcbiAgICByZWplY3QocmVhc29uOiBhbnkpIHtcclxuICAgICAgICB0aGlzLl9yZWplY3QocmVhc29uKTtcclxuICAgIH1cclxufVxyXG4iLCIvLyBDb3B5cmlnaHQgKGMpIC5ORVQgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzLiBBbGwgcmlnaHRzIHJlc2VydmVkLlxyXG4vLyBMaWNlbnNlZCB1bmRlciB0aGUgTUlUIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIGZpbGUgaW4gdGhlIHByb2plY3Qgcm9vdCBmb3IgZnVsbCBsaWNlbnNlIGluZm9ybWF0aW9uLlxyXG5cclxuaW1wb3J0ICogYXMgcnhqcyBmcm9tIFwicnhqc1wiO1xyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tIFwiLi9jb21tYW5kc0FuZEV2ZW50c1wiO1xyXG5pbXBvcnQgeyBEaXNwb3NhYmxlIH0gZnJvbSBcIi4vZGlzcG9zYWJsZXNcIjtcclxuaW1wb3J0IHsgZ2V0S2VybmVsVXJpLCBLZXJuZWwgfSBmcm9tIFwiLi9rZXJuZWxcIjtcclxuaW1wb3J0IHsgUHJvbWlzZUNvbXBsZXRpb25Tb3VyY2UgfSBmcm9tIFwiLi9wcm9taXNlQ29tcGxldGlvblNvdXJjZVwiO1xyXG5cclxuXHJcbmV4cG9ydCBjbGFzcyBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dCBpbXBsZW1lbnRzIERpc3Bvc2FibGUge1xyXG5cclxuICAgIGNvbnN0cnVjdG9yKGtlcm5lbENvbW1hbmRJbnZvY2F0aW9uOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUpIHtcclxuICAgICAgICB0aGlzLl9jb21tYW5kRW52ZWxvcGUgPSBrZXJuZWxDb21tYW5kSW52b2NhdGlvbjtcclxuICAgIH1cclxuXHJcbiAgICBwcml2YXRlIHN0YXRpYyBfY3VycmVudDogS2VybmVsSW52b2NhdGlvbkNvbnRleHQgfCBudWxsID0gbnVsbDtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX2NvbW1hbmRFbnZlbG9wZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlO1xyXG4gICAgcHJpdmF0ZSByZWFkb25seSBfY2hpbGRDb21tYW5kczogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlW10gPSBbXTtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX2V2ZW50U3ViamVjdDogcnhqcy5TdWJqZWN0PGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGU+ID0gbmV3IHJ4anMuU3ViamVjdDxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlPigpO1xyXG5cclxuICAgIHByaXZhdGUgX2lzQ29tcGxldGUgPSBmYWxzZTtcclxuICAgIHByaXZhdGUgX2hhbmRsaW5nS2VybmVsOiBLZXJuZWwgfCBudWxsID0gbnVsbDtcclxuICAgIHByaXZhdGUgX2NvbXBsZXRpb25Tb3VyY2UgPSBuZXcgUHJvbWlzZUNvbXBsZXRpb25Tb3VyY2U8dm9pZD4oKTtcclxuXHJcbiAgICBwdWJsaWMgZ2V0IGhhbmRsaW5nS2VybmVsKCkge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9oYW5kbGluZ0tlcm5lbDtcclxuICAgIH07XHJcblxyXG4gICAgcHVibGljIGdldCBrZXJuZWxFdmVudHMoKTogcnhqcy5PYnNlcnZhYmxlPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGU+IHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fZXZlbnRTdWJqZWN0LmFzT2JzZXJ2YWJsZSgpO1xyXG4gICAgfTtcclxuXHJcbiAgICBwdWJsaWMgc2V0IGhhbmRsaW5nS2VybmVsKHZhbHVlOiBLZXJuZWwgfCBudWxsKSB7XHJcbiAgICAgICAgdGhpcy5faGFuZGxpbmdLZXJuZWwgPSB2YWx1ZTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0IHByb21pc2UoKTogdm9pZCB8IFByb21pc2VMaWtlPHZvaWQ+IHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fY29tcGxldGlvblNvdXJjZS5wcm9taXNlO1xyXG4gICAgfVxyXG5cclxuICAgIHN0YXRpYyBnZXRPckNyZWF0ZUFtYmllbnRDb250ZXh0KGNvbW1hbmQ6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSk6IEtlcm5lbEludm9jYXRpb25Db250ZXh0IHtcclxuICAgICAgICBsZXQgY3VycmVudCA9IEtlcm5lbEludm9jYXRpb25Db250ZXh0Ll9jdXJyZW50O1xyXG4gICAgICAgIGlmICghY3VycmVudCB8fCBjdXJyZW50Ll9pc0NvbXBsZXRlKSB7XHJcbiAgICAgICAgICAgIGNvbW1hbmQuZ2V0T3JDcmVhdGVUb2tlbigpO1xyXG4gICAgICAgICAgICBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5fY3VycmVudCA9IG5ldyBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dChjb21tYW5kKTtcclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICBpZiAoIWNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZS5hcmVDb21tYW5kc1RoZVNhbWUoY29tbWFuZCwgY3VycmVudC5fY29tbWFuZEVudmVsb3BlKSkge1xyXG4gICAgICAgICAgICAgICAgY29uc3QgZm91bmQgPSBjdXJyZW50Ll9jaGlsZENvbW1hbmRzLmluY2x1ZGVzKGNvbW1hbmQpO1xyXG4gICAgICAgICAgICAgICAgaWYgKCFmb3VuZCkge1xyXG4gICAgICAgICAgICAgICAgICAgIGlmIChjb21tYW5kLnBhcmVudENvbW1hbmQgPT09IG51bGwgfHwgY29tbWFuZC5wYXJlbnRDb21tYW5kID09PSB1bmRlZmluZWQpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgY29tbWFuZC5zZXRQYXJlbnQoY3VycmVudC5fY29tbWFuZEVudmVsb3BlKTtcclxuICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgY3VycmVudC5fY2hpbGRDb21tYW5kcy5wdXNoKGNvbW1hbmQpO1xyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICByZXR1cm4gS2VybmVsSW52b2NhdGlvbkNvbnRleHQuX2N1cnJlbnQhO1xyXG4gICAgfVxyXG5cclxuICAgIHN0YXRpYyBnZXQgY3VycmVudCgpOiBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dCB8IG51bGwgeyByZXR1cm4gdGhpcy5fY3VycmVudDsgfVxyXG4gICAgZ2V0IGNvbW1hbmQoKTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZCB7IHJldHVybiB0aGlzLl9jb21tYW5kRW52ZWxvcGUuY29tbWFuZDsgfVxyXG4gICAgZ2V0IGNvbW1hbmRFbnZlbG9wZSgpOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUgeyByZXR1cm4gdGhpcy5fY29tbWFuZEVudmVsb3BlOyB9XHJcblxyXG4gICAgY29tcGxldGUoY29tbWFuZDogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlKSB7XHJcbiAgICAgICAgaWYgKGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZS5hcmVDb21tYW5kc1RoZVNhbWUoY29tbWFuZCwgdGhpcy5fY29tbWFuZEVudmVsb3BlKSkge1xyXG4gICAgICAgICAgICB0aGlzLl9pc0NvbXBsZXRlID0gdHJ1ZTtcclxuICAgICAgICAgICAgbGV0IHN1Y2NlZWRlZDogY29tbWFuZHNBbmRFdmVudHMuQ29tbWFuZFN1Y2NlZWRlZCA9IHt9O1xyXG4gICAgICAgICAgICBsZXQgZXZlbnRFbnZlbG9wZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZSA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKFxyXG4gICAgICAgICAgICAgICAgY29tbWFuZHNBbmRFdmVudHMuQ29tbWFuZFN1Y2NlZWRlZFR5cGUsXHJcbiAgICAgICAgICAgICAgICBzdWNjZWVkZWQsXHJcbiAgICAgICAgICAgICAgICB0aGlzLl9jb21tYW5kRW52ZWxvcGVcclxuICAgICAgICAgICAgKTtcclxuXHJcbiAgICAgICAgICAgIHRoaXMuaW50ZXJuYWxQdWJsaXNoKGV2ZW50RW52ZWxvcGUpO1xyXG4gICAgICAgICAgICB0aGlzLl9jb21wbGV0aW9uU291cmNlLnJlc29sdmUoKTtcclxuICAgICAgICB9XHJcbiAgICAgICAgZWxzZSB7XHJcbiAgICAgICAgICAgIGxldCBwb3MgPSB0aGlzLl9jaGlsZENvbW1hbmRzLmluZGV4T2YoY29tbWFuZCk7XHJcbiAgICAgICAgICAgIGRlbGV0ZSB0aGlzLl9jaGlsZENvbW1hbmRzW3Bvc107XHJcbiAgICAgICAgfVxyXG4gICAgfVxyXG5cclxuICAgIGZhaWwobWVzc2FnZT86IHN0cmluZykge1xyXG4gICAgICAgIC8vIFRoZSBDIyBjb2RlIGFjY2VwdHMgYSBtZXNzYWdlIGFuZC9vciBhbiBleGNlcHRpb24uIERvIHdlIG5lZWQgdG8gYWRkIHN1cHBvcnRcclxuICAgICAgICAvLyBmb3IgZXhjZXB0aW9ucz8gKFRoZSBUUyBDb21tYW5kRmFpbGVkIGludGVyZmFjZSBkb2Vzbid0IGhhdmUgYSBwbGFjZSBmb3IgaXQgcmlnaHQgbm93LilcclxuICAgICAgICB0aGlzLl9pc0NvbXBsZXRlID0gdHJ1ZTtcclxuICAgICAgICBsZXQgZmFpbGVkOiBjb21tYW5kc0FuZEV2ZW50cy5Db21tYW5kRmFpbGVkID0geyBtZXNzYWdlOiBtZXNzYWdlID8/IFwiQ29tbWFuZCBGYWlsZWRcIiB9O1xyXG4gICAgICAgIGxldCBldmVudEVudmVsb3BlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlID0gbmV3IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUoXHJcbiAgICAgICAgICAgIGNvbW1hbmRzQW5kRXZlbnRzLkNvbW1hbmRGYWlsZWRUeXBlLFxyXG4gICAgICAgICAgICBmYWlsZWQsXHJcbiAgICAgICAgICAgIHRoaXMuX2NvbW1hbmRFbnZlbG9wZVxyXG4gICAgICAgICk7XHJcblxyXG4gICAgICAgIHRoaXMuaW50ZXJuYWxQdWJsaXNoKGV2ZW50RW52ZWxvcGUpO1xyXG4gICAgICAgIHRoaXMuX2NvbXBsZXRpb25Tb3VyY2UucmVzb2x2ZSgpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1Ymxpc2goa2VybmVsRXZlbnQ6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUpIHtcclxuICAgICAgICBpZiAoIXRoaXMuX2lzQ29tcGxldGUpIHtcclxuICAgICAgICAgICAgdGhpcy5pbnRlcm5hbFB1Ymxpc2goa2VybmVsRXZlbnQpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICBwcml2YXRlIGludGVybmFsUHVibGlzaChrZXJuZWxFdmVudDogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZSkge1xyXG4gICAgICAgIGlmICgha2VybmVsRXZlbnQuY29tbWFuZCkge1xyXG4gICAgICAgICAgICBrZXJuZWxFdmVudC5jb21tYW5kID0gdGhpcy5fY29tbWFuZEVudmVsb3BlO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgbGV0IGNvbW1hbmQgPSBrZXJuZWxFdmVudC5jb21tYW5kO1xyXG5cclxuICAgICAgICBpZiAodGhpcy5oYW5kbGluZ0tlcm5lbCkge1xyXG4gICAgICAgICAgICBjb25zdCBrZXJuZWxVcmkgPSBnZXRLZXJuZWxVcmkodGhpcy5oYW5kbGluZ0tlcm5lbCk7XHJcbiAgICAgICAgICAgIGlmICgha2VybmVsRXZlbnQucm91dGluZ1NsaXAuY29udGFpbnMoa2VybmVsVXJpKSkge1xyXG4gICAgICAgICAgICAgICAga2VybmVsRXZlbnQucm91dGluZ1NsaXAuc3RhbXAoa2VybmVsVXJpKTtcclxuICAgICAgICAgICAgICAgIGtlcm5lbEV2ZW50LnJvdXRpbmdTbGlwOy8vP1xyXG4gICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgXCJzaG91bGQgbm90IGJlIGhlcmVcIjsvLz9cclxuICAgICAgICAgICAgfVxyXG5cclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICBrZXJuZWxFdmVudDsvLz9cclxuICAgICAgICB9XHJcbiAgICAgICAgdGhpcy5fY29tbWFuZEVudmVsb3BlOy8vP1xyXG4gICAgICAgIGlmIChjb21tYW5kID09PSBudWxsIHx8XHJcbiAgICAgICAgICAgIGNvbW1hbmQgPT09IHVuZGVmaW5lZCB8fFxyXG4gICAgICAgICAgICBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUuYXJlQ29tbWFuZHNUaGVTYW1lKGNvbW1hbmQhLCB0aGlzLl9jb21tYW5kRW52ZWxvcGUpIHx8XHJcbiAgICAgICAgICAgIHRoaXMuX2NoaWxkQ29tbWFuZHMuaW5jbHVkZXMoY29tbWFuZCEpKSB7XHJcbiAgICAgICAgICAgIHRoaXMuX2V2ZW50U3ViamVjdC5uZXh0KGtlcm5lbEV2ZW50KTtcclxuICAgICAgICB9IGVsc2UgaWYgKGNvbW1hbmQuaXNTZWxmb3JEZXNjZW5kYW50T2YodGhpcy5fY29tbWFuZEVudmVsb3BlKSkge1xyXG4gICAgICAgICAgICB0aGlzLl9ldmVudFN1YmplY3QubmV4dChrZXJuZWxFdmVudCk7XHJcbiAgICAgICAgfSBlbHNlIGlmIChjb21tYW5kLmhhc1NhbWVSb290Q29tbWFuZEFzKHRoaXMuX2NvbW1hbmRFbnZlbG9wZSkpIHtcclxuICAgICAgICAgICAgdGhpcy5fZXZlbnRTdWJqZWN0Lm5leHQoa2VybmVsRXZlbnQpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICBpc1BhcmVudE9mQ29tbWFuZChjb21tYW5kRW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSk6IGJvb2xlYW4ge1xyXG4gICAgICAgIGNvbnN0IGNoaWxkRm91bmQgPSB0aGlzLl9jaGlsZENvbW1hbmRzLmluY2x1ZGVzKGNvbW1hbmRFbnZlbG9wZSk7XHJcbiAgICAgICAgcmV0dXJuIGNoaWxkRm91bmQ7XHJcbiAgICB9XHJcblxyXG4gICAgZGlzcG9zZSgpIHtcclxuICAgICAgICBpZiAoIXRoaXMuX2lzQ29tcGxldGUpIHtcclxuICAgICAgICAgICAgdGhpcy5jb21wbGV0ZSh0aGlzLl9jb21tYW5kRW52ZWxvcGUpO1xyXG4gICAgICAgIH1cclxuICAgICAgICBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5fY3VycmVudCA9IG51bGw7XHJcbiAgICB9XHJcbn1cclxuIiwiLy8gQ29weXJpZ2h0IChjKSAuTkVUIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC5cclxuLy8gTGljZW5zZWQgdW5kZXIgdGhlIE1JVCBsaWNlbnNlLiBTZWUgTElDRU5TRSBmaWxlIGluIHRoZSBwcm9qZWN0IHJvb3QgZm9yIGZ1bGwgbGljZW5zZSBpbmZvcm1hdGlvbi5cclxuXHJcbmV4cG9ydCBlbnVtIExvZ0xldmVsIHtcclxuICAgIEluZm8gPSAwLFxyXG4gICAgV2FybiA9IDEsXHJcbiAgICBFcnJvciA9IDIsXHJcbiAgICBOb25lID0gMyxcclxufVxyXG5cclxuZXhwb3J0IHR5cGUgTG9nRW50cnkgPSB7XHJcbiAgICBsb2dMZXZlbDogTG9nTGV2ZWw7XHJcbiAgICBzb3VyY2U6IHN0cmluZztcclxuICAgIG1lc3NhZ2U6IHN0cmluZztcclxufTtcclxuXHJcbmV4cG9ydCBjbGFzcyBMb2dnZXIge1xyXG5cclxuICAgIHByaXZhdGUgc3RhdGljIF9kZWZhdWx0OiBMb2dnZXIgPSBuZXcgTG9nZ2VyKCdkZWZhdWx0JywgKF9lbnRyeTogTG9nRW50cnkpID0+IHsgfSk7XHJcblxyXG4gICAgcHJpdmF0ZSBjb25zdHJ1Y3Rvcihwcml2YXRlIHJlYWRvbmx5IHNvdXJjZTogc3RyaW5nLCByZWFkb25seSB3cml0ZTogKGVudHJ5OiBMb2dFbnRyeSkgPT4gdm9pZCkge1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBpbmZvKG1lc3NhZ2U6IHN0cmluZyk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMud3JpdGUoeyBsb2dMZXZlbDogTG9nTGV2ZWwuSW5mbywgc291cmNlOiB0aGlzLnNvdXJjZSwgbWVzc2FnZSB9KTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgd2FybihtZXNzYWdlOiBzdHJpbmcpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLndyaXRlKHsgbG9nTGV2ZWw6IExvZ0xldmVsLldhcm4sIHNvdXJjZTogdGhpcy5zb3VyY2UsIG1lc3NhZ2UgfSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGVycm9yKG1lc3NhZ2U6IHN0cmluZyk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMud3JpdGUoeyBsb2dMZXZlbDogTG9nTGV2ZWwuRXJyb3IsIHNvdXJjZTogdGhpcy5zb3VyY2UsIG1lc3NhZ2UgfSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHN0YXRpYyBjb25maWd1cmUoc291cmNlOiBzdHJpbmcsIHdyaXRlcjogKGVudHJ5OiBMb2dFbnRyeSkgPT4gdm9pZCkge1xyXG4gICAgICAgIGNvbnN0IGxvZ2dlciA9IG5ldyBMb2dnZXIoc291cmNlLCB3cml0ZXIpO1xyXG4gICAgICAgIExvZ2dlci5fZGVmYXVsdCA9IGxvZ2dlcjtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgc3RhdGljIGdldCBkZWZhdWx0KCk6IExvZ2dlciB7XHJcbiAgICAgICAgaWYgKExvZ2dlci5fZGVmYXVsdCkge1xyXG4gICAgICAgICAgICByZXR1cm4gTG9nZ2VyLl9kZWZhdWx0O1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdObyBsb2dnZXIgaGFzIGJlZW4gY29uZmlndXJlZCBmb3IgdGhpcyBjb250ZXh0Jyk7XHJcbiAgICB9XHJcbn1cclxuIiwiLy8gQ29weXJpZ2h0IChjKSAuTkVUIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC5cclxuLy8gTGljZW5zZWQgdW5kZXIgdGhlIE1JVCBsaWNlbnNlLiBTZWUgTElDRU5TRSBmaWxlIGluIHRoZSBwcm9qZWN0IHJvb3QgZm9yIGZ1bGwgbGljZW5zZSBpbmZvcm1hdGlvbi5cclxuXHJcbmltcG9ydCB7IExvZ2dlciB9IGZyb20gXCIuL2xvZ2dlclwiO1xyXG5pbXBvcnQgeyBQcm9taXNlQ29tcGxldGlvblNvdXJjZSB9IGZyb20gXCIuL3Byb21pc2VDb21wbGV0aW9uU291cmNlXCI7XHJcblxyXG5pbnRlcmZhY2UgU2NoZWR1bGVyT3BlcmF0aW9uPFQ+IHtcclxuICAgIHZhbHVlOiBUO1xyXG4gICAgZXhlY3V0b3I6ICh2YWx1ZTogVCkgPT4gUHJvbWlzZTx2b2lkPjtcclxuICAgIHByb21pc2VDb21wbGV0aW9uU291cmNlOiBQcm9taXNlQ29tcGxldGlvblNvdXJjZTx2b2lkPjtcclxufVxyXG5cclxuZXhwb3J0IGNsYXNzIEtlcm5lbFNjaGVkdWxlcjxUPiB7XHJcbiAgICBzZXRNdXN0VHJhbXBvbGluZShwcmVkaWNhdGU6IChjOiBUKSA9PiBib29sZWFuKSB7XHJcbiAgICAgICAgdGhpcy5fbXVzdFRyYW1wb2xpbmUgPSBwcmVkaWNhdGUgPz8gKChfYykgPT4gZmFsc2UpO1xyXG4gICAgfVxyXG4gICAgcHJpdmF0ZSBfb3BlcmF0aW9uUXVldWU6IEFycmF5PFNjaGVkdWxlck9wZXJhdGlvbjxUPj4gPSBbXTtcclxuICAgIHByaXZhdGUgX2luRmxpZ2h0T3BlcmF0aW9uPzogU2NoZWR1bGVyT3BlcmF0aW9uPFQ+O1xyXG4gICAgcHJpdmF0ZSBfbXVzdFRyYW1wb2xpbmU6IChjOiBUKSA9PiBib29sZWFuO1xyXG4gICAgY29uc3RydWN0b3IoKSB7XHJcbiAgICAgICAgdGhpcy5fbXVzdFRyYW1wb2xpbmUgPSAoX2MpID0+IGZhbHNlO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBjYW5jZWxDdXJyZW50T3BlcmF0aW9uKCk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMuX2luRmxpZ2h0T3BlcmF0aW9uPy5wcm9taXNlQ29tcGxldGlvblNvdXJjZS5yZWplY3QobmV3IEVycm9yKFwiT3BlcmF0aW9uIGNhbmNlbGxlZFwiKSk7XHJcbiAgICB9XHJcblxyXG4gICAgcnVuQXN5bmModmFsdWU6IFQsIGV4ZWN1dG9yOiAodmFsdWU6IFQpID0+IFByb21pc2U8dm9pZD4pOiBQcm9taXNlPHZvaWQ+IHtcclxuICAgICAgICBjb25zdCBvcGVyYXRpb24gPSB7XHJcbiAgICAgICAgICAgIHZhbHVlLFxyXG4gICAgICAgICAgICBleGVjdXRvcixcclxuICAgICAgICAgICAgcHJvbWlzZUNvbXBsZXRpb25Tb3VyY2U6IG5ldyBQcm9taXNlQ29tcGxldGlvblNvdXJjZTx2b2lkPigpLFxyXG4gICAgICAgIH07XHJcblxyXG4gICAgICAgIGNvbnN0IG11c3RUcmFtcG9saW5lID0gdGhpcy5fbXVzdFRyYW1wb2xpbmUodmFsdWUpO1xyXG5cclxuICAgICAgICBpZiAodGhpcy5faW5GbGlnaHRPcGVyYXRpb24gJiYgIW11c3RUcmFtcG9saW5lKSB7XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYGtlcm5lbFNjaGVkdWxlcjogc3RhcnRpbmcgaW1tZWRpYXRlIGV4ZWN1dGlvbiBvZiAke0pTT04uc3RyaW5naWZ5KG9wZXJhdGlvbi52YWx1ZSl9YCk7XHJcblxyXG4gICAgICAgICAgICAvLyBpbnZva2UgaW1tZWRpYXRlbHlcclxuICAgICAgICAgICAgcmV0dXJuIG9wZXJhdGlvbi5leGVjdXRvcihvcGVyYXRpb24udmFsdWUpXHJcbiAgICAgICAgICAgICAgICAudGhlbigoKSA9PiB7XHJcbiAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhga2VybmVsU2NoZWR1bGVyOiBpbW1lZGlhdGUgZXhlY3V0aW9uIGNvbXBsZXRlZDogJHtKU09OLnN0cmluZ2lmeShvcGVyYXRpb24udmFsdWUpfWApO1xyXG4gICAgICAgICAgICAgICAgICAgIG9wZXJhdGlvbi5wcm9taXNlQ29tcGxldGlvblNvdXJjZS5yZXNvbHZlKCk7XHJcbiAgICAgICAgICAgICAgICB9KVxyXG4gICAgICAgICAgICAgICAgLmNhdGNoKGUgPT4ge1xyXG4gICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYGtlcm5lbFNjaGVkdWxlcjogaW1tZWRpYXRlIGV4ZWN1dGlvbiBmYWlsZWQ6ICR7SlNPTi5zdHJpbmdpZnkoZSl9IC0gJHtKU09OLnN0cmluZ2lmeShvcGVyYXRpb24udmFsdWUpfWApO1xyXG4gICAgICAgICAgICAgICAgICAgIG9wZXJhdGlvbi5wcm9taXNlQ29tcGxldGlvblNvdXJjZS5yZWplY3QoZSk7XHJcbiAgICAgICAgICAgICAgICB9KTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYGtlcm5lbFNjaGVkdWxlcjogc2NoZWR1bGluZyBleGVjdXRpb24gb2YgJHtKU09OLnN0cmluZ2lmeShvcGVyYXRpb24udmFsdWUpfWApO1xyXG4gICAgICAgIHRoaXMuX29wZXJhdGlvblF1ZXVlLnB1c2gob3BlcmF0aW9uKTtcclxuICAgICAgICBpZiAodGhpcy5fb3BlcmF0aW9uUXVldWUubGVuZ3RoID09PSAxKSB7XHJcbiAgICAgICAgICAgIHNldFRpbWVvdXQoKCkgPT4ge1xyXG4gICAgICAgICAgICAgICAgdGhpcy5leGVjdXRlTmV4dENvbW1hbmQoKTtcclxuICAgICAgICAgICAgfSwgMCk7XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICByZXR1cm4gb3BlcmF0aW9uLnByb21pc2VDb21wbGV0aW9uU291cmNlLnByb21pc2U7XHJcbiAgICB9XHJcblxyXG4gICAgcHJpdmF0ZSBleGVjdXRlTmV4dENvbW1hbmQoKTogdm9pZCB7XHJcbiAgICAgICAgY29uc3QgbmV4dE9wZXJhdGlvbiA9IHRoaXMuX29wZXJhdGlvblF1ZXVlLmxlbmd0aCA+IDAgPyB0aGlzLl9vcGVyYXRpb25RdWV1ZVswXSA6IHVuZGVmaW5lZDtcclxuICAgICAgICBpZiAobmV4dE9wZXJhdGlvbikge1xyXG4gICAgICAgICAgICB0aGlzLl9pbkZsaWdodE9wZXJhdGlvbiA9IG5leHRPcGVyYXRpb247XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYGtlcm5lbFNjaGVkdWxlcjogc3RhcnRpbmcgc2NoZWR1bGVkIGV4ZWN1dGlvbiBvZiAke0pTT04uc3RyaW5naWZ5KG5leHRPcGVyYXRpb24udmFsdWUpfWApO1xyXG4gICAgICAgICAgICBuZXh0T3BlcmF0aW9uLmV4ZWN1dG9yKG5leHRPcGVyYXRpb24udmFsdWUpXHJcbiAgICAgICAgICAgICAgICAudGhlbigoKSA9PiB7XHJcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5faW5GbGlnaHRPcGVyYXRpb24gPSB1bmRlZmluZWQ7XHJcbiAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhga2VybmVsU2NoZWR1bGVyOiBjb21wbGV0aW5nIGluZmxpZ2h0IG9wZXJhdGlvbjogc3VjY2VzcyAke0pTT04uc3RyaW5naWZ5KG5leHRPcGVyYXRpb24udmFsdWUpfWApO1xyXG4gICAgICAgICAgICAgICAgICAgIG5leHRPcGVyYXRpb24ucHJvbWlzZUNvbXBsZXRpb25Tb3VyY2UucmVzb2x2ZSgpO1xyXG4gICAgICAgICAgICAgICAgfSlcclxuICAgICAgICAgICAgICAgIC5jYXRjaChlID0+IHtcclxuICAgICAgICAgICAgICAgICAgICB0aGlzLl9pbkZsaWdodE9wZXJhdGlvbiA9IHVuZGVmaW5lZDtcclxuICAgICAgICAgICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC5pbmZvKGBrZXJuZWxTY2hlZHVsZXI6IGNvbXBsZXRpbmcgaW5mbGlnaHQgb3BlcmF0aW9uOiBmYWlsdXJlICR7SlNPTi5zdHJpbmdpZnkoZSl9IC0gJHtKU09OLnN0cmluZ2lmeShuZXh0T3BlcmF0aW9uLnZhbHVlKX1gKTtcclxuICAgICAgICAgICAgICAgICAgICBuZXh0T3BlcmF0aW9uLnByb21pc2VDb21wbGV0aW9uU291cmNlLnJlamVjdChlKTtcclxuICAgICAgICAgICAgICAgIH0pXHJcbiAgICAgICAgICAgICAgICAuZmluYWxseSgoKSA9PiB7XHJcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5faW5GbGlnaHRPcGVyYXRpb24gPSB1bmRlZmluZWQ7XHJcbiAgICAgICAgICAgICAgICAgICAgc2V0VGltZW91dCgoKSA9PiB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuX29wZXJhdGlvblF1ZXVlLnNoaWZ0KCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuZXhlY3V0ZU5leHRDb21tYW5kKCk7XHJcbiAgICAgICAgICAgICAgICAgICAgfSwgMCk7XHJcbiAgICAgICAgICAgICAgICB9KTtcclxuICAgICAgICB9XHJcbiAgICB9XHJcbn1cclxuIiwiLy8gQ29weXJpZ2h0IChjKSAuTkVUIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC5cclxuLy8gTGljZW5zZWQgdW5kZXIgdGhlIE1JVCBsaWNlbnNlLiBTZWUgTElDRU5TRSBmaWxlIGluIHRoZSBwcm9qZWN0IHJvb3QgZm9yIGZ1bGwgbGljZW5zZSBpbmZvcm1hdGlvbi5cclxuXHJcbmltcG9ydCB7IEtlcm5lbEludm9jYXRpb25Db250ZXh0IH0gZnJvbSBcIi4va2VybmVsSW52b2NhdGlvbkNvbnRleHRcIjtcclxuaW1wb3J0ICogYXMgY29tbWFuZHNBbmRFdmVudHMgZnJvbSBcIi4vY29tbWFuZHNBbmRFdmVudHNcIjtcclxuaW1wb3J0IHsgTG9nZ2VyIH0gZnJvbSBcIi4vbG9nZ2VyXCI7XHJcbmltcG9ydCB7IENvbXBvc2l0ZUtlcm5lbCB9IGZyb20gXCIuL2NvbXBvc2l0ZUtlcm5lbFwiO1xyXG5pbXBvcnQgeyBLZXJuZWxTY2hlZHVsZXIgfSBmcm9tIFwiLi9rZXJuZWxTY2hlZHVsZXJcIjtcclxuaW1wb3J0IHsgUHJvbWlzZUNvbXBsZXRpb25Tb3VyY2UgfSBmcm9tIFwiLi9wcm9taXNlQ29tcGxldGlvblNvdXJjZVwiO1xyXG5pbXBvcnQgKiBhcyBkaXNwb3NhYmxlcyBmcm9tIFwiLi9kaXNwb3NhYmxlc1wiO1xyXG5pbXBvcnQgKiBhcyByb3V0aW5nc2xpcCBmcm9tIFwiLi9yb3V0aW5nc2xpcFwiO1xyXG5pbXBvcnQgKiBhcyByeGpzIGZyb20gXCJyeGpzXCI7XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIElLZXJuZWxDb21tYW5kSW52b2NhdGlvbiB7XHJcbiAgICBjb21tYW5kRW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZTtcclxuICAgIGNvbnRleHQ6IEtlcm5lbEludm9jYXRpb25Db250ZXh0O1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIElLZXJuZWxDb21tYW5kSGFuZGxlciB7XHJcbiAgICBjb21tYW5kVHlwZTogc3RyaW5nO1xyXG4gICAgaGFuZGxlOiAoY29tbWFuZEludm9jYXRpb246IElLZXJuZWxDb21tYW5kSW52b2NhdGlvbikgPT4gUHJvbWlzZTx2b2lkPjtcclxufVxyXG5cclxuZXhwb3J0IGludGVyZmFjZSBJS2VybmVsRXZlbnRPYnNlcnZlciB7XHJcbiAgICAoa2VybmVsRXZlbnQ6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUpOiB2b2lkO1xyXG59XHJcblxyXG5leHBvcnQgY2xhc3MgS2VybmVsIHtcclxuICAgIHByaXZhdGUgX2tlcm5lbEluZm86IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm87XHJcbiAgICBwcml2YXRlIF9jb21tYW5kSGFuZGxlcnMgPSBuZXcgTWFwPHN0cmluZywgSUtlcm5lbENvbW1hbmRIYW5kbGVyPigpO1xyXG4gICAgcHJpdmF0ZSBfZXZlbnRTdWJqZWN0ID0gbmV3IHJ4anMuU3ViamVjdDxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlPigpO1xyXG4gICAgcHVibGljIHJvb3RLZXJuZWw6IEtlcm5lbCA9IHRoaXM7XHJcbiAgICBwdWJsaWMgcGFyZW50S2VybmVsOiBDb21wb3NpdGVLZXJuZWwgfCBudWxsID0gbnVsbDtcclxuICAgIHByaXZhdGUgX3NjaGVkdWxlcj86IEtlcm5lbFNjaGVkdWxlcjxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGU+IHwgbnVsbCA9IG51bGw7XHJcblxyXG4gICAgcHVibGljIGdldCBrZXJuZWxJbmZvKCk6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm8ge1xyXG5cclxuICAgICAgICByZXR1cm4gdGhpcy5fa2VybmVsSW5mbztcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0IGtlcm5lbEV2ZW50cygpOiByeGpzLk9ic2VydmFibGU8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZT4ge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9ldmVudFN1YmplY3QuYXNPYnNlcnZhYmxlKCk7XHJcbiAgICB9XHJcblxyXG4gICAgY29uc3RydWN0b3IocmVhZG9ubHkgbmFtZTogc3RyaW5nLCBsYW5ndWFnZU5hbWU/OiBzdHJpbmcsIGxhbmd1YWdlVmVyc2lvbj86IHN0cmluZywgZGlzcGxheU5hbWU/OiBzdHJpbmcpIHtcclxuICAgICAgICB0aGlzLl9rZXJuZWxJbmZvID0ge1xyXG4gICAgICAgICAgICBpc1Byb3h5OiBmYWxzZSxcclxuICAgICAgICAgICAgaXNDb21wb3NpdGU6IGZhbHNlLFxyXG4gICAgICAgICAgICBsb2NhbE5hbWU6IG5hbWUsXHJcbiAgICAgICAgICAgIGxhbmd1YWdlTmFtZTogbGFuZ3VhZ2VOYW1lLFxyXG4gICAgICAgICAgICBhbGlhc2VzOiBbXSxcclxuICAgICAgICAgICAgdXJpOiByb3V0aW5nc2xpcC5jcmVhdGVLZXJuZWxVcmkoYGtlcm5lbDovL2xvY2FsLyR7bmFtZX1gKSxcclxuICAgICAgICAgICAgbGFuZ3VhZ2VWZXJzaW9uOiBsYW5ndWFnZVZlcnNpb24sXHJcbiAgICAgICAgICAgIGRpc3BsYXlOYW1lOiBkaXNwbGF5TmFtZSA/PyBuYW1lLFxyXG4gICAgICAgICAgICBzdXBwb3J0ZWRLZXJuZWxDb21tYW5kczogW11cclxuICAgICAgICB9O1xyXG4gICAgICAgIHRoaXMuX2ludGVybmFsUmVnaXN0ZXJDb21tYW5kSGFuZGxlcih7XHJcbiAgICAgICAgICAgIGNvbW1hbmRUeXBlOiBjb21tYW5kc0FuZEV2ZW50cy5SZXF1ZXN0S2VybmVsSW5mb1R5cGUsIGhhbmRsZTogYXN5bmMgaW52b2NhdGlvbiA9PiB7XHJcbiAgICAgICAgICAgICAgICBhd2FpdCB0aGlzLmhhbmRsZVJlcXVlc3RLZXJuZWxJbmZvKGludm9jYXRpb24pO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHJvdGVjdGVkIGFzeW5jIGhhbmRsZVJlcXVlc3RLZXJuZWxJbmZvKGludm9jYXRpb246IElLZXJuZWxDb21tYW5kSW52b2NhdGlvbik6IFByb21pc2U8dm9pZD4ge1xyXG4gICAgICAgIGNvbnN0IGV2ZW50RW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZShcclxuICAgICAgICAgICAgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkVHlwZSxcclxuICAgICAgICAgICAgPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZD57IGtlcm5lbEluZm86IHRoaXMuX2tlcm5lbEluZm8gfSxcclxuICAgICAgICAgICAgaW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGVcclxuICAgICAgICApOy8vP1xyXG5cclxuICAgICAgICBpbnZvY2F0aW9uLmNvbnRleHQucHVibGlzaChldmVudEVudmVsb3BlKTtcclxuICAgICAgICByZXR1cm4gUHJvbWlzZS5yZXNvbHZlKCk7XHJcbiAgICB9XHJcblxyXG4gICAgcHJpdmF0ZSBnZXRTY2hlZHVsZXIoKTogS2VybmVsU2NoZWR1bGVyPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZT4ge1xyXG4gICAgICAgIGlmICghdGhpcy5fc2NoZWR1bGVyKSB7XHJcbiAgICAgICAgICAgIHRoaXMuX3NjaGVkdWxlciA9IHRoaXMucGFyZW50S2VybmVsPy5nZXRTY2hlZHVsZXIoKSA/PyBuZXcgS2VybmVsU2NoZWR1bGVyPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZT4oKTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIHJldHVybiB0aGlzLl9zY2hlZHVsZXI7XHJcbiAgICB9XHJcblxyXG4gICAgc3RhdGljIGdldCBjdXJyZW50KCk6IEtlcm5lbCB8IG51bGwge1xyXG4gICAgICAgIGlmIChLZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5jdXJyZW50KSB7XHJcbiAgICAgICAgICAgIHJldHVybiBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5jdXJyZW50LmhhbmRsaW5nS2VybmVsO1xyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4gbnVsbDtcclxuICAgIH1cclxuXHJcbiAgICBzdGF0aWMgZ2V0IHJvb3QoKTogS2VybmVsIHwgbnVsbCB7XHJcbiAgICAgICAgaWYgKEtlcm5lbC5jdXJyZW50KSB7XHJcbiAgICAgICAgICAgIHJldHVybiBLZXJuZWwuY3VycmVudC5yb290S2VybmVsO1xyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4gbnVsbDtcclxuICAgIH1cclxuXHJcbiAgICAvLyBJcyBpdCB3b3J0aCB1cyBnb2luZyB0byBlZmZvcnRzIHRvIGVuc3VyZSB0aGF0IHRoZSBQcm9taXNlIHJldHVybmVkIGhlcmUgYWNjdXJhdGVseSByZWZsZWN0c1xyXG4gICAgLy8gdGhlIGNvbW1hbmQncyBwcm9ncmVzcz8gVGhlIG9ubHkgdGhpbmcgdGhhdCBhY3R1YWxseSBjYWxscyB0aGlzIGlzIHRoZSBrZXJuZWwgY2hhbm5lbCwgdGhyb3VnaFxyXG4gICAgLy8gdGhlIGNhbGxiYWNrIHNldCB1cCBieSBhdHRhY2hLZXJuZWxUb0NoYW5uZWwsIGFuZCB0aGUgY2FsbGJhY2sgaXMgZXhwZWN0ZWQgdG8gcmV0dXJuIHZvaWQsIHNvXHJcbiAgICAvLyBub3RoaW5nIGlzIGV2ZXIgZ29pbmcgdG8gbG9vayBhdCB0aGUgcHJvbWlzZSB3ZSByZXR1cm4gaGVyZS5cclxuICAgIGFzeW5jIHNlbmQoY29tbWFuZEVudmVsb3BlT3JNb2RlbDogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlIHwgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlTW9kZWwpOiBQcm9taXNlPHZvaWQ+IHtcclxuICAgICAgICBsZXQgY29tbWFuZEVudmVsb3BlID0gPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZT5jb21tYW5kRW52ZWxvcGVPck1vZGVsO1xyXG5cclxuICAgICAgICBpZiAoY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlLmlzS2VybmVsQ29tbWFuZEVudmVsb3BlTW9kZWwoY29tbWFuZEVudmVsb3BlT3JNb2RlbCkpIHtcclxuICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQud2FybihgQ29udmVydGluZyBjb21tYW5kIGVudmVsb3BlIG1vZGVsIHRvIGNvbW1hbmQgZW52ZWxvcGUgZm9yIGJhY2thd2FyZHMgY29tcGF0aWJpbGl0eS5gKTtcclxuICAgICAgICAgICAgY29tbWFuZEVudmVsb3BlID0gY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlLmZyb21Kc29uKGNvbW1hbmRFbnZlbG9wZU9yTW9kZWwpO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgY29uc3QgY29udGV4dCA9IEtlcm5lbEludm9jYXRpb25Db250ZXh0LmdldE9yQ3JlYXRlQW1iaWVudENvbnRleHQoY29tbWFuZEVudmVsb3BlKTtcclxuICAgICAgICBpZiAoY29udGV4dC5jb21tYW5kRW52ZWxvcGUpIHtcclxuICAgICAgICAgICAgaWYgKCFjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUuYXJlQ29tbWFuZHNUaGVTYW1lKGNvbnRleHQuY29tbWFuZEVudmVsb3BlLCBjb21tYW5kRW52ZWxvcGUpKSB7XHJcbiAgICAgICAgICAgICAgICBjb21tYW5kRW52ZWxvcGUuc2V0UGFyZW50KGNvbnRleHQuY29tbWFuZEVudmVsb3BlKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgICAgICBjb25zdCBrZXJuZWxVcmkgPSBnZXRLZXJuZWxVcmkodGhpcyk7XHJcbiAgICAgICAgaWYgKCFjb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAuY29udGFpbnMoa2VybmVsVXJpKSkge1xyXG4gICAgICAgICAgICBjb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAuc3RhbXBBc0Fycml2ZWQoa2VybmVsVXJpKTtcclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC53YXJuKGBUcnlpbmcgdG8gc3RhbXAgJHtjb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGV9IGFzIGFycml2ZWQgYnV0IHVyaSAke2tlcm5lbFVyaX0gaXMgYWxyZWFkeSBwcmVzZW50LmApO1xyXG4gICAgICAgIH1cclxuICAgICAgICBjb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXA7Ly8/XHJcblxyXG4gICAgICAgIHJldHVybiB0aGlzLmdldFNjaGVkdWxlcigpLnJ1bkFzeW5jKGNvbW1hbmRFbnZlbG9wZSwgKHZhbHVlKSA9PiB0aGlzLmV4ZWN1dGVDb21tYW5kKHZhbHVlKS5maW5hbGx5KCgpID0+IHtcclxuICAgICAgICAgICAgaWYgKCFjb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAuY29udGFpbnMoa2VybmVsVXJpKSkge1xyXG4gICAgICAgICAgICAgICAgY29tbWFuZEVudmVsb3BlLnJvdXRpbmdTbGlwLnN0YW1wKGtlcm5lbFVyaSk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgZWxzZSB7XHJcbiAgICAgICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC53YXJuKGBUcnlpbmcgdG8gc3RhbXAgJHtjb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGV9IGFzIGNvbXBsZXRlZCBidXQgdXJpICR7a2VybmVsVXJpfSBpcyBhbHJlYWR5IHByZXNlbnQuYCk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9KSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHJpdmF0ZSBhc3luYyBleGVjdXRlQ29tbWFuZChjb21tYW5kRW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSk6IFByb21pc2U8dm9pZD4ge1xyXG4gICAgICAgIGxldCBjb250ZXh0ID0gS2VybmVsSW52b2NhdGlvbkNvbnRleHQuZ2V0T3JDcmVhdGVBbWJpZW50Q29udGV4dChjb21tYW5kRW52ZWxvcGUpO1xyXG4gICAgICAgIGxldCBwcmV2aW91c0hhbmRsaW5nS2VybmVsID0gY29udGV4dC5oYW5kbGluZ0tlcm5lbDtcclxuXHJcbiAgICAgICAgdHJ5IHtcclxuICAgICAgICAgICAgYXdhaXQgdGhpcy5oYW5kbGVDb21tYW5kKGNvbW1hbmRFbnZlbG9wZSk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGNhdGNoIChlKSB7XHJcbiAgICAgICAgICAgIGNvbnRleHQuZmFpbCgoPGFueT5lKT8ubWVzc2FnZSB8fCBKU09OLnN0cmluZ2lmeShlKSk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGZpbmFsbHkge1xyXG4gICAgICAgICAgICBjb250ZXh0LmhhbmRsaW5nS2VybmVsID0gcHJldmlvdXNIYW5kbGluZ0tlcm5lbDtcclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgZ2V0Q29tbWFuZEhhbmRsZXIoY29tbWFuZFR5cGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRUeXBlKTogSUtlcm5lbENvbW1hbmRIYW5kbGVyIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fY29tbWFuZEhhbmRsZXJzLmdldChjb21tYW5kVHlwZSk7XHJcbiAgICB9XHJcblxyXG4gICAgaGFuZGxlQ29tbWFuZChjb21tYW5kRW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSk6IFByb21pc2U8dm9pZD4ge1xyXG4gICAgICAgIHJldHVybiBuZXcgUHJvbWlzZTx2b2lkPihhc3luYyAocmVzb2x2ZSwgcmVqZWN0KSA9PiB7XHJcbiAgICAgICAgICAgIGxldCBjb250ZXh0ID0gS2VybmVsSW52b2NhdGlvbkNvbnRleHQuZ2V0T3JDcmVhdGVBbWJpZW50Q29udGV4dChjb21tYW5kRW52ZWxvcGUpO1xyXG5cclxuICAgICAgICAgICAgY29uc3QgcHJldmlvdWRIZW5kbGluZ0tlcm5lbCA9IGNvbnRleHQuaGFuZGxpbmdLZXJuZWw7XHJcbiAgICAgICAgICAgIGNvbnRleHQuaGFuZGxpbmdLZXJuZWwgPSB0aGlzO1xyXG4gICAgICAgICAgICBsZXQgaXNSb290Q29tbWFuZCA9IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZS5hcmVDb21tYW5kc1RoZVNhbWUoY29udGV4dC5jb21tYW5kRW52ZWxvcGUsIGNvbW1hbmRFbnZlbG9wZSk7XHJcblxyXG4gICAgICAgICAgICBsZXQgZXZlbnRTdWJzY3JpcHRpb246IHJ4anMuU3Vic2NyaXB0aW9uIHwgdW5kZWZpbmVkID0gdW5kZWZpbmVkOy8vP1xyXG5cclxuICAgICAgICAgICAgaWYgKGlzUm9vdENvbW1hbmQpIHtcclxuICAgICAgICAgICAgICAgIGNvbnN0IGtlcm5lbFR5cGUgPSAodGhpcy5rZXJuZWxJbmZvLmlzUHJveHkgPyBcInByb3h5XCIgOiBcIlwiKSArICh0aGlzLmtlcm5lbEluZm8uaXNDb21wb3NpdGUgPyBcImNvbXBvc2l0ZVwiIDogXCJcIik7XHJcbiAgICAgICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC5pbmZvKGBrZXJuZWwgJHt0aGlzLm5hbWV9IG9mIHR5cGUgJHtrZXJuZWxUeXBlfSBzdWJzY3JpYmluZyB0byBjb250ZXh0IGV2ZW50c2ApO1xyXG4gICAgICAgICAgICAgICAgZXZlbnRTdWJzY3JpcHRpb24gPSBjb250ZXh0Lmtlcm5lbEV2ZW50cy5waXBlKHJ4anMubWFwKGUgPT4ge1xyXG4gICAgICAgICAgICAgICAgICAgIGNvbnN0IG1lc3NhZ2UgPSBga2VybmVsICR7dGhpcy5uYW1lfSBvZiB0eXBlICR7a2VybmVsVHlwZX0gc2F3IGV2ZW50ICR7ZS5ldmVudFR5cGV9IHdpdGggdG9rZW4gJHtlLmNvbW1hbmQ/LmdldFRva2VuKCl9YDtcclxuICAgICAgICAgICAgICAgICAgICBtZXNzYWdlOy8vP1xyXG4gICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8obWVzc2FnZSk7XHJcbiAgICAgICAgICAgICAgICAgICAgY29uc3Qga2VybmVsVXJpID0gZ2V0S2VybmVsVXJpKHRoaXMpO1xyXG4gICAgICAgICAgICAgICAgICAgIGlmICghZS5yb3V0aW5nU2xpcC5jb250YWlucyhrZXJuZWxVcmkpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGUucm91dGluZ1NsaXAuc3RhbXAoa2VybmVsVXJpKTtcclxuICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBcInNob3VsZCBub3QgZ2V0IGhlcmVcIjsvLz9cclxuICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGU7XHJcbiAgICAgICAgICAgICAgICB9KSlcclxuICAgICAgICAgICAgICAgICAgICAuc3Vic2NyaWJlKHRoaXMucHVibGlzaEV2ZW50LmJpbmQodGhpcykpO1xyXG4gICAgICAgICAgICB9XHJcblxyXG4gICAgICAgICAgICBsZXQgaGFuZGxlciA9IHRoaXMuZ2V0Q29tbWFuZEhhbmRsZXIoY29tbWFuZEVudmVsb3BlLmNvbW1hbmRUeXBlKTtcclxuICAgICAgICAgICAgaWYgKGhhbmRsZXIpIHtcclxuICAgICAgICAgICAgICAgIHRyeSB7XHJcbiAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhga2VybmVsICR7dGhpcy5uYW1lfSBhYm91dCB0byBoYW5kbGUgY29tbWFuZDogJHtKU09OLnN0cmluZ2lmeShjb21tYW5kRW52ZWxvcGUpfWApO1xyXG4gICAgICAgICAgICAgICAgICAgIGF3YWl0IGhhbmRsZXIuaGFuZGxlKHsgY29tbWFuZEVudmVsb3BlOiBjb21tYW5kRW52ZWxvcGUsIGNvbnRleHQgfSk7XHJcbiAgICAgICAgICAgICAgICAgICAgY29udGV4dC5jb21wbGV0ZShjb21tYW5kRW52ZWxvcGUpO1xyXG4gICAgICAgICAgICAgICAgICAgIGNvbnRleHQuaGFuZGxpbmdLZXJuZWwgPSBwcmV2aW91ZEhlbmRsaW5nS2VybmVsO1xyXG4gICAgICAgICAgICAgICAgICAgIGlmIChpc1Jvb3RDb21tYW5kKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGV2ZW50U3Vic2NyaXB0aW9uPy51bnN1YnNjcmliZSgpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb250ZXh0LmRpc3Bvc2UoKTtcclxuICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhga2VybmVsICR7dGhpcy5uYW1lfSBkb25lIGhhbmRsaW5nIGNvbW1hbmQ6ICR7SlNPTi5zdHJpbmdpZnkoY29tbWFuZEVudmVsb3BlKX1gKTtcclxuICAgICAgICAgICAgICAgICAgICByZXNvbHZlKCk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICBjYXRjaCAoZSkge1xyXG4gICAgICAgICAgICAgICAgICAgIGNvbnRleHQuZmFpbCgoPGFueT5lKT8ubWVzc2FnZSB8fCBKU09OLnN0cmluZ2lmeShlKSk7XHJcbiAgICAgICAgICAgICAgICAgICAgY29udGV4dC5oYW5kbGluZ0tlcm5lbCA9IHByZXZpb3VkSGVuZGxpbmdLZXJuZWw7XHJcbiAgICAgICAgICAgICAgICAgICAgaWYgKGlzUm9vdENvbW1hbmQpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgZXZlbnRTdWJzY3JpcHRpb24/LnVuc3Vic2NyaWJlKCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRleHQuZGlzcG9zZSgpO1xyXG4gICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICByZWplY3QoZSk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgICAgICAvLyBoYWNrIGxpa2UgdGhlcmUgaXMgbm8gdG9tb3Jyb3dcclxuICAgICAgICAgICAgICAgIGNvbnN0IHNob3VsZE5vb3AgPSB0aGlzLnNob3VsZE5vb3BDb21tYW5kKGNvbW1hbmRFbnZlbG9wZSwgY29udGV4dCk7XHJcbiAgICAgICAgICAgICAgICBpZiAoc2hvdWxkTm9vcCkge1xyXG4gICAgICAgICAgICAgICAgICAgIGNvbnRleHQuY29tcGxldGUoY29tbWFuZEVudmVsb3BlKTtcclxuICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgIGNvbnRleHQuaGFuZGxpbmdLZXJuZWwgPSBwcmV2aW91ZEhlbmRsaW5nS2VybmVsO1xyXG4gICAgICAgICAgICAgICAgaWYgKGlzUm9vdENvbW1hbmQpIHtcclxuICAgICAgICAgICAgICAgICAgICBldmVudFN1YnNjcmlwdGlvbj8udW5zdWJzY3JpYmUoKTtcclxuICAgICAgICAgICAgICAgICAgICBjb250ZXh0LmRpc3Bvc2UoKTtcclxuICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgIGlmICghc2hvdWxkTm9vcCkge1xyXG4gICAgICAgICAgICAgICAgICAgIHJlamVjdChuZXcgRXJyb3IoYE5vIGhhbmRsZXIgZm91bmQgZm9yIGNvbW1hbmQgdHlwZSAke2NvbW1hbmRFbnZlbG9wZS5jb21tYW5kVHlwZX1gKSk7XHJcbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0Lndhcm4oYGtlcm5lbCAke3RoaXMubmFtZX0gZG9uZSBub29wIGhhbmRsaW5nIGNvbW1hbmQ6ICR7SlNPTi5zdHJpbmdpZnkoY29tbWFuZEVudmVsb3BlKX1gKTtcclxuICAgICAgICAgICAgICAgICAgICByZXNvbHZlKCk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9KTtcclxuICAgIH1cclxuICAgIHByaXZhdGUgc2hvdWxkTm9vcENvbW1hbmQoY29tbWFuZEVudmVsb3BlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUsIGNvbnRleHQ6IEtlcm5lbEludm9jYXRpb25Db250ZXh0KTogYm9vbGVhbiB7XHJcblxyXG4gICAgICAgIGxldCBzaG91bGROb29wID0gZmFsc2U7XHJcbiAgICAgICAgc3dpdGNoIChjb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGUpIHtcclxuICAgICAgICAgICAgY2FzZSBjb21tYW5kc0FuZEV2ZW50cy5SZXF1ZXN0Q29tcGxldGlvbnNUeXBlOlxyXG4gICAgICAgICAgICBjYXNlIGNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3RTaWduYXR1cmVIZWxwVHlwZTpcclxuICAgICAgICAgICAgY2FzZSBjb21tYW5kc0FuZEV2ZW50cy5SZXF1ZXN0RGlhZ25vc3RpY3NUeXBlOlxyXG4gICAgICAgICAgICBjYXNlIGNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3RIb3ZlclRleHRUeXBlOlxyXG4gICAgICAgICAgICAgICAgc2hvdWxkTm9vcCA9IHRydWU7XHJcbiAgICAgICAgICAgICAgICBicmVhaztcclxuICAgICAgICAgICAgZGVmYXVsdDpcclxuICAgICAgICAgICAgICAgIHNob3VsZE5vb3AgPSBmYWxzZTtcclxuICAgICAgICAgICAgICAgIGJyZWFrO1xyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4gc2hvdWxkTm9vcDtcclxuICAgIH1cclxuXHJcbiAgICBzdWJzY3JpYmVUb0tlcm5lbEV2ZW50cyhvYnNlcnZlcjogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZU9ic2VydmVyKTogZGlzcG9zYWJsZXMuRGlzcG9zYWJsZVN1YnNjcmlwdGlvbiB7XHJcbiAgICAgICAgY29uc3Qgc3ViID0gdGhpcy5fZXZlbnRTdWJqZWN0LnN1YnNjcmliZShvYnNlcnZlcik7XHJcblxyXG4gICAgICAgIHJldHVybiB7XHJcbiAgICAgICAgICAgIGRpc3Bvc2U6ICgpID0+IHsgc3ViLnVuc3Vic2NyaWJlKCk7IH1cclxuICAgICAgICB9O1xyXG4gICAgfVxyXG5cclxuICAgIHByb3RlY3RlZCBjYW5IYW5kbGUoY29tbWFuZEVudmVsb3BlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUpIHtcclxuICAgICAgICBpZiAoY29tbWFuZEVudmVsb3BlLmNvbW1hbmQudGFyZ2V0S2VybmVsTmFtZSAmJiBjb21tYW5kRW52ZWxvcGUuY29tbWFuZC50YXJnZXRLZXJuZWxOYW1lICE9PSB0aGlzLm5hbWUpIHtcclxuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xyXG5cclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmIChjb21tYW5kRW52ZWxvcGUuY29tbWFuZC5kZXN0aW5hdGlvblVyaSkge1xyXG4gICAgICAgICAgICBjb25zdCBub3JtYWxpemVkVXJpID0gcm91dGluZ3NsaXAuY3JlYXRlS2VybmVsVXJpKGNvbW1hbmRFbnZlbG9wZS5jb21tYW5kLmRlc3RpbmF0aW9uVXJpKTtcclxuICAgICAgICAgICAgaWYgKHRoaXMua2VybmVsSW5mby51cmkgIT09IG5vcm1hbGl6ZWRVcmkpIHtcclxuICAgICAgICAgICAgICAgIHJldHVybiBmYWxzZTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgcmV0dXJuIHRoaXMuc3VwcG9ydHNDb21tYW5kKGNvbW1hbmRFbnZlbG9wZS5jb21tYW5kVHlwZSk7XHJcbiAgICB9XHJcblxyXG4gICAgc3VwcG9ydHNDb21tYW5kKGNvbW1hbmRUeXBlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kVHlwZSk6IGJvb2xlYW4ge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9jb21tYW5kSGFuZGxlcnMuaGFzKGNvbW1hbmRUeXBlKTtcclxuICAgIH1cclxuXHJcbiAgICByZWdpc3RlckNvbW1hbmRIYW5kbGVyKGhhbmRsZXI6IElLZXJuZWxDb21tYW5kSGFuZGxlcik6IHZvaWQge1xyXG4gICAgICAgIC8vIFdoZW4gYSByZWdpc3RyYXRpb24gYWxyZWFkeSBleGlzdGVkLCB3ZSB3YW50IHRvIG92ZXJ3cml0ZSBpdCBiZWNhdXNlIHdlIHdhbnQgdXNlcnMgdG9cclxuICAgICAgICAvLyBiZSBhYmxlIHRvIGRldmVsb3AgaGFuZGxlcnMgaXRlcmF0aXZlbHksIGFuZCBpdCB3b3VsZCBiZSB1bmhlbHBmdWwgZm9yIGhhbmRsZXIgcmVnaXN0cmF0aW9uXHJcbiAgICAgICAgLy8gZm9yIGFueSBwYXJ0aWN1bGFyIGNvbW1hbmQgdG8gYmUgY3VtdWxhdGl2ZS5cclxuXHJcbiAgICAgICAgY29uc3Qgc2hvdWxkTm90aWZ5ID0gIXRoaXMuX2NvbW1hbmRIYW5kbGVycy5oYXMoaGFuZGxlci5jb21tYW5kVHlwZSk7XHJcbiAgICAgICAgdGhpcy5faW50ZXJuYWxSZWdpc3RlckNvbW1hbmRIYW5kbGVyKGhhbmRsZXIpO1xyXG4gICAgICAgIGlmIChzaG91bGROb3RpZnkpIHtcclxuICAgICAgICAgICAgY29uc3QgZXZlbnQ6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZCA9IHtcclxuICAgICAgICAgICAgICAgIGtlcm5lbEluZm86IHRoaXMuX2tlcm5lbEluZm8sXHJcbiAgICAgICAgICAgIH07XHJcbiAgICAgICAgICAgIGNvbnN0IGVudmVsb3BlID0gbmV3IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUoXHJcbiAgICAgICAgICAgICAgICBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvUHJvZHVjZWRUeXBlLFxyXG4gICAgICAgICAgICAgICAgZXZlbnQsXHJcbiAgICAgICAgICAgICAgICBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5jdXJyZW50Py5jb21tYW5kRW52ZWxvcGVcclxuICAgICAgICAgICAgKTtcclxuXHJcbiAgICAgICAgICAgIGVudmVsb3BlLnJvdXRpbmdTbGlwLnN0YW1wKGdldEtlcm5lbFVyaSh0aGlzKSk7XHJcbiAgICAgICAgICAgIGNvbnN0IGNvbnRleHQgPSBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5jdXJyZW50O1xyXG5cclxuICAgICAgICAgICAgaWYgKGNvbnRleHQpIHtcclxuICAgICAgICAgICAgICAgIGVudmVsb3BlLmNvbW1hbmQgPSBjb250ZXh0LmNvbW1hbmRFbnZlbG9wZTtcclxuXHJcbiAgICAgICAgICAgICAgICBjb250ZXh0LnB1Ymxpc2goZW52ZWxvcGUpO1xyXG4gICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgdGhpcy5wdWJsaXNoRXZlbnQoZW52ZWxvcGUpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfVxyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgX2ludGVybmFsUmVnaXN0ZXJDb21tYW5kSGFuZGxlcihoYW5kbGVyOiBJS2VybmVsQ29tbWFuZEhhbmRsZXIpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLl9jb21tYW5kSGFuZGxlcnMuc2V0KGhhbmRsZXIuY29tbWFuZFR5cGUsIGhhbmRsZXIpO1xyXG4gICAgICAgIHRoaXMuX2tlcm5lbEluZm8uc3VwcG9ydGVkS2VybmVsQ29tbWFuZHMgPSBBcnJheS5mcm9tKHRoaXMuX2NvbW1hbmRIYW5kbGVycy5rZXlzKCkpLm1hcChjb21tYW5kTmFtZSA9PiAoeyBuYW1lOiBjb21tYW5kTmFtZSB9KSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHJvdGVjdGVkIGdldEhhbmRsaW5nS2VybmVsKGNvbW1hbmRFbnZlbG9wZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlLCBjb250ZXh0PzogS2VybmVsSW52b2NhdGlvbkNvbnRleHQgfCBudWxsKTogS2VybmVsIHwgbnVsbCB7XHJcbiAgICAgICAgaWYgKHRoaXMuY2FuSGFuZGxlKGNvbW1hbmRFbnZlbG9wZSkpIHtcclxuICAgICAgICAgICAgcmV0dXJuIHRoaXM7XHJcbiAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgY29udGV4dD8uZmFpbChgQ29tbWFuZCAke2NvbW1hbmRFbnZlbG9wZS5jb21tYW5kVHlwZX0gaXMgbm90IHN1cHBvcnRlZCBieSBLZXJuZWwgJHt0aGlzLm5hbWV9YCk7XHJcbiAgICAgICAgICAgIHJldHVybiBudWxsO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICBwcm90ZWN0ZWQgcHVibGlzaEV2ZW50KGtlcm5lbEV2ZW50OiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKSB7XHJcbiAgICAgICAgdGhpcy5fZXZlbnRTdWJqZWN0Lm5leHQoa2VybmVsRXZlbnQpO1xyXG4gICAgfVxyXG59XHJcblxyXG5leHBvcnQgYXN5bmMgZnVuY3Rpb24gc3VibWl0Q29tbWFuZEFuZEdldFJlc3VsdDxURXZlbnQgZXh0ZW5kcyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudD4oa2VybmVsOiBLZXJuZWwsIGNvbW1hbmRFbnZlbG9wZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlLCBleHBlY3RlZEV2ZW50VHlwZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRUeXBlKTogUHJvbWlzZTxURXZlbnQ+IHtcclxuICAgIGxldCBjb21wbGV0aW9uU291cmNlID0gbmV3IFByb21pc2VDb21wbGV0aW9uU291cmNlPFRFdmVudD4oKTtcclxuICAgIGxldCBoYW5kbGVkID0gZmFsc2U7XHJcbiAgICBsZXQgZGlzcG9zYWJsZSA9IGtlcm5lbC5zdWJzY3JpYmVUb0tlcm5lbEV2ZW50cyhldmVudEVudmVsb3BlID0+IHtcclxuICAgICAgICBpZiAoZXZlbnRFbnZlbG9wZS5jb21tYW5kPy5nZXRUb2tlbigpID09PSBjb21tYW5kRW52ZWxvcGUuZ2V0VG9rZW4oKSkge1xyXG4gICAgICAgICAgICBzd2l0Y2ggKGV2ZW50RW52ZWxvcGUuZXZlbnRUeXBlKSB7XHJcbiAgICAgICAgICAgICAgICBjYXNlIGNvbW1hbmRzQW5kRXZlbnRzLkNvbW1hbmRGYWlsZWRUeXBlOlxyXG4gICAgICAgICAgICAgICAgICAgIGlmICghaGFuZGxlZCkge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBoYW5kbGVkID0gdHJ1ZTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgbGV0IGVyciA9IDxjb21tYW5kc0FuZEV2ZW50cy5Db21tYW5kRmFpbGVkPmV2ZW50RW52ZWxvcGUuZXZlbnQ7Ly8/XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGNvbXBsZXRpb25Tb3VyY2UucmVqZWN0KGVycik7XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xyXG4gICAgICAgICAgICAgICAgY2FzZSBjb21tYW5kc0FuZEV2ZW50cy5Db21tYW5kU3VjY2VlZGVkVHlwZTpcclxuICAgICAgICAgICAgICAgICAgICBpZiAoY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlLmFyZUNvbW1hbmRzVGhlU2FtZShldmVudEVudmVsb3BlLmNvbW1hbmQhLCBjb21tYW5kRW52ZWxvcGUpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghaGFuZGxlZCkgey8vPyAoJCA/IGV2ZW50RW52ZWxvcGUgOiB7fSlcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZWQgPSB0cnVlO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29tcGxldGlvblNvdXJjZS5yZWplY3QoJ0NvbW1hbmQgd2FzIGhhbmRsZWQgYmVmb3JlIHJlcG9ydGluZyBleHBlY3RlZCByZXN1bHQuJyk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgZGVmYXVsdDpcclxuICAgICAgICAgICAgICAgICAgICBpZiAoZXZlbnRFbnZlbG9wZS5ldmVudFR5cGUgPT09IGV4cGVjdGVkRXZlbnRUeXBlKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGhhbmRsZWQgPSB0cnVlO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgZXZlbnQgPSA8VEV2ZW50PmV2ZW50RW52ZWxvcGUuZXZlbnQ7Ly8/ICgkID8gZXZlbnRFbnZlbG9wZSA6IHt9KVxyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb21wbGV0aW9uU291cmNlLnJlc29sdmUoZXZlbnQpO1xyXG4gICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICBicmVhaztcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgIH0pO1xyXG5cclxuICAgIHRyeSB7XHJcbiAgICAgICAgYXdhaXQga2VybmVsLnNlbmQoY29tbWFuZEVudmVsb3BlKTtcclxuICAgIH1cclxuICAgIGZpbmFsbHkge1xyXG4gICAgICAgIGRpc3Bvc2FibGUuZGlzcG9zZSgpO1xyXG4gICAgfVxyXG5cclxuICAgIHJldHVybiBjb21wbGV0aW9uU291cmNlLnByb21pc2U7XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBnZXRLZXJuZWxVcmkoa2VybmVsOiBLZXJuZWwpOiBzdHJpbmcge1xyXG4gICAgcmV0dXJuIGtlcm5lbC5rZXJuZWxJbmZvLnVyaSA/PyBga2VybmVsOi8vbG9jYWwvJHtrZXJuZWwua2VybmVsSW5mby5sb2NhbE5hbWV9YDtcclxufSIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG5pbXBvcnQgKiBhcyByb3V0aW5nc2xpcCBmcm9tIFwiLi9yb3V0aW5nc2xpcFwiO1xyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tIFwiLi9jb21tYW5kc0FuZEV2ZW50c1wiO1xyXG5pbXBvcnQgeyBnZXRLZXJuZWxVcmksIElLZXJuZWxDb21tYW5kSW52b2NhdGlvbiwgS2VybmVsIH0gZnJvbSBcIi4va2VybmVsXCI7XHJcbmltcG9ydCB7IEtlcm5lbEhvc3QgfSBmcm9tIFwiLi9rZXJuZWxIb3N0XCI7XHJcbmltcG9ydCB7IEtlcm5lbEludm9jYXRpb25Db250ZXh0IH0gZnJvbSBcIi4va2VybmVsSW52b2NhdGlvbkNvbnRleHRcIjtcclxuaW1wb3J0IHsgTG9nZ2VyIH0gZnJvbSBcIi4vbG9nZ2VyXCI7XHJcblxyXG5leHBvcnQgY2xhc3MgQ29tcG9zaXRlS2VybmVsIGV4dGVuZHMgS2VybmVsIHtcclxuICAgIHByaXZhdGUgX2hvc3Q6IEtlcm5lbEhvc3QgfCBudWxsID0gbnVsbDtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX2RlZmF1bHRLZXJuZWxOYW1lc0J5Q29tbWFuZFR5cGU6IE1hcDxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kVHlwZSwgc3RyaW5nPiA9IG5ldyBNYXAoKTtcclxuXHJcbiAgICBkZWZhdWx0S2VybmVsTmFtZTogc3RyaW5nIHwgdW5kZWZpbmVkO1xyXG4gICAgcHJpdmF0ZSBfY2hpbGRLZXJuZWxzOiBLZXJuZWxDb2xsZWN0aW9uO1xyXG5cclxuICAgIGNvbnN0cnVjdG9yKG5hbWU6IHN0cmluZykge1xyXG4gICAgICAgIHN1cGVyKG5hbWUpO1xyXG4gICAgICAgIHRoaXMua2VybmVsSW5mby5pc0NvbXBvc2l0ZSA9IHRydWU7XHJcbiAgICAgICAgdGhpcy5fY2hpbGRLZXJuZWxzID0gbmV3IEtlcm5lbENvbGxlY3Rpb24odGhpcyk7XHJcbiAgICB9XHJcblxyXG4gICAgZ2V0IGNoaWxkS2VybmVscygpIHtcclxuICAgICAgICByZXR1cm4gQXJyYXkuZnJvbSh0aGlzLl9jaGlsZEtlcm5lbHMpO1xyXG4gICAgfVxyXG5cclxuICAgIGdldCBob3N0KCk6IEtlcm5lbEhvc3QgfCBudWxsIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5faG9zdDtcclxuICAgIH1cclxuXHJcbiAgICBzZXQgaG9zdChob3N0OiBLZXJuZWxIb3N0IHwgbnVsbCkge1xyXG4gICAgICAgIHRoaXMuX2hvc3QgPSBob3N0O1xyXG4gICAgICAgIGlmICh0aGlzLl9ob3N0KSB7XHJcbiAgICAgICAgICAgIHRoaXMua2VybmVsSW5mby51cmkgPSB0aGlzLl9ob3N0LnVyaTtcclxuICAgICAgICAgICAgdGhpcy5fY2hpbGRLZXJuZWxzLm5vdGlmeVRoYXRIb3N0V2FzU2V0KCk7XHJcbiAgICAgICAgfVxyXG4gICAgfVxyXG5cclxuICAgIHByb3RlY3RlZCBvdmVycmlkZSBhc3luYyBoYW5kbGVSZXF1ZXN0S2VybmVsSW5mbyhpbnZvY2F0aW9uOiBJS2VybmVsQ29tbWFuZEludm9jYXRpb24pOiBQcm9taXNlPHZvaWQ+IHtcclxuXHJcbiAgICAgICAgY29uc3QgZXZlbnRFbnZlbG9wZSA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKFxyXG4gICAgICAgICAgICBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvUHJvZHVjZWRUeXBlLFxyXG4gICAgICAgICAgICA8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkPnsga2VybmVsSW5mbzogdGhpcy5rZXJuZWxJbmZvIH0sXHJcbiAgICAgICAgICAgIGludm9jYXRpb24uY29tbWFuZEVudmVsb3BlXHJcbiAgICAgICAgKTsvLz9cclxuXHJcbiAgICAgICAgaW52b2NhdGlvbi5jb250ZXh0LnB1Ymxpc2goZXZlbnRFbnZlbG9wZSk7XHJcblxyXG4gICAgICAgIGZvciAobGV0IGtlcm5lbCBvZiB0aGlzLl9jaGlsZEtlcm5lbHMpIHtcclxuICAgICAgICAgICAgaWYgKGtlcm5lbC5zdXBwb3J0c0NvbW1hbmQoaW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGUpKSB7XHJcbiAgICAgICAgICAgICAgICBjb25zdCBjaGlsZENvbW1hbmQgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlKFxyXG4gICAgICAgICAgICAgICAgICAgIGNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3RLZXJuZWxJbmZvVHlwZSxcclxuICAgICAgICAgICAgICAgICAgICB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHRhcmdldEtlcm5lbE5hbWU6IGtlcm5lbC5rZXJuZWxJbmZvLmxvY2FsTmFtZVxyXG4gICAgICAgICAgICAgICAgICAgIH0pO1xyXG4gICAgICAgICAgICAgICAgY2hpbGRDb21tYW5kLnNldFBhcmVudChpbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZSk7XHJcbiAgICAgICAgICAgICAgICBjaGlsZENvbW1hbmQucm91dGluZ1NsaXAuY29udGludWVXaXRoKGludm9jYXRpb24uY29tbWFuZEVudmVsb3BlLnJvdXRpbmdTbGlwKTtcclxuICAgICAgICAgICAgICAgIGF3YWl0IGtlcm5lbC5oYW5kbGVDb21tYW5kKGNoaWxkQ29tbWFuZCk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgYWRkKGtlcm5lbDogS2VybmVsLCBhbGlhc2VzPzogc3RyaW5nW10pIHtcclxuICAgICAgICBpZiAoIWtlcm5lbCkge1xyXG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXCJrZXJuZWwgY2Fubm90IGJlIG51bGwgb3IgdW5kZWZpbmVkXCIpO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgaWYgKCF0aGlzLmRlZmF1bHRLZXJuZWxOYW1lKSB7XHJcbiAgICAgICAgICAgIC8vIGRlZmF1bHQgdG8gZmlyc3Qga2VybmVsXHJcbiAgICAgICAgICAgIHRoaXMuZGVmYXVsdEtlcm5lbE5hbWUgPSBrZXJuZWwubmFtZTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGtlcm5lbC5wYXJlbnRLZXJuZWwgPSB0aGlzO1xyXG4gICAgICAgIGtlcm5lbC5yb290S2VybmVsID0gdGhpcy5yb290S2VybmVsO1xyXG4gICAgICAgIGtlcm5lbC5rZXJuZWxFdmVudHMuc3Vic2NyaWJlKHtcclxuICAgICAgICAgICAgbmV4dDogKGV2ZW50KSA9PiB7XHJcbiAgICAgICAgICAgICAgICBldmVudDsvLz9cclxuICAgICAgICAgICAgICAgIGNvbnN0IGtlcm5lbFVyaSA9IGdldEtlcm5lbFVyaSh0aGlzKTtcclxuICAgICAgICAgICAgICAgIGlmICghZXZlbnQucm91dGluZ1NsaXAuY29udGFpbnMoa2VybmVsVXJpKSkge1xyXG4gICAgICAgICAgICAgICAgICAgIGV2ZW50LnJvdXRpbmdTbGlwLnN0YW1wKGtlcm5lbFVyaSk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICBldmVudDsvLz9cclxuICAgICAgICAgICAgICAgIHRoaXMucHVibGlzaEV2ZW50KGV2ZW50KTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH0pO1xyXG5cclxuICAgICAgICBpZiAoYWxpYXNlcykge1xyXG4gICAgICAgICAgICBsZXQgc2V0ID0gbmV3IFNldChhbGlhc2VzKTtcclxuXHJcbiAgICAgICAgICAgIGlmIChrZXJuZWwua2VybmVsSW5mby5hbGlhc2VzKSB7XHJcbiAgICAgICAgICAgICAgICBmb3IgKGxldCBhbGlhcyBpbiBrZXJuZWwua2VybmVsSW5mby5hbGlhc2VzKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgc2V0LmFkZChhbGlhcyk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuXHJcbiAgICAgICAgICAgIGtlcm5lbC5rZXJuZWxJbmZvLmFsaWFzZXMgPSBBcnJheS5mcm9tKHNldCk7XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICB0aGlzLl9jaGlsZEtlcm5lbHMuYWRkKGtlcm5lbCwgYWxpYXNlcyk7XHJcblxyXG4gICAgICAgIGNvbnN0IGludm9jYXRpb25Db250ZXh0ID0gS2VybmVsSW52b2NhdGlvbkNvbnRleHQuY3VycmVudDtcclxuXHJcbiAgICAgICAgaWYgKGludm9jYXRpb25Db250ZXh0KSB7XHJcbiAgICAgICAgICAgIGludm9jYXRpb25Db250ZXh0LmNvbW1hbmRFbnZlbG9wZTtcclxuICAgICAgICAgICAgY29uc3QgZXZlbnQgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZShcclxuICAgICAgICAgICAgICAgIGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZFR5cGUsXHJcbiAgICAgICAgICAgICAgICA8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkPntcclxuICAgICAgICAgICAgICAgICAgICBrZXJuZWxJbmZvOiBrZXJuZWwua2VybmVsSW5mb1xyXG4gICAgICAgICAgICAgICAgfSxcclxuICAgICAgICAgICAgICAgIGludm9jYXRpb25Db250ZXh0LmNvbW1hbmRFbnZlbG9wZVxyXG4gICAgICAgICAgICApO1xyXG4gICAgICAgICAgICBpbnZvY2F0aW9uQ29udGV4dC5wdWJsaXNoKGV2ZW50KTtcclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICBjb25zdCBldmVudCA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKFxyXG4gICAgICAgICAgICAgICAgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkVHlwZSxcclxuICAgICAgICAgICAgICAgIDxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvUHJvZHVjZWQ+e1xyXG4gICAgICAgICAgICAgICAgICAgIGtlcm5lbEluZm86IGtlcm5lbC5rZXJuZWxJbmZvXHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICk7XHJcbiAgICAgICAgICAgIHRoaXMucHVibGlzaEV2ZW50KGV2ZW50KTtcclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgZmluZEtlcm5lbEJ5VXJpKHVyaTogc3RyaW5nKTogS2VybmVsIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICBjb25zdCBub3JtYWxpemVkID0gcm91dGluZ3NsaXAuY3JlYXRlS2VybmVsVXJpKHVyaSk7XHJcbiAgICAgICAgaWYgKHRoaXMua2VybmVsSW5mby51cmkgPT09IG5vcm1hbGl6ZWQpIHtcclxuICAgICAgICAgICAgcmV0dXJuIHRoaXM7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHJldHVybiB0aGlzLl9jaGlsZEtlcm5lbHMudHJ5R2V0QnlVcmkobm9ybWFsaXplZCk7XHJcbiAgICB9XHJcblxyXG4gICAgZmluZEtlcm5lbEJ5TmFtZShuYW1lOiBzdHJpbmcpOiBLZXJuZWwgfCB1bmRlZmluZWQge1xyXG4gICAgICAgIGlmICh0aGlzLmtlcm5lbEluZm8ubG9jYWxOYW1lID09PSBuYW1lIHx8IHRoaXMua2VybmVsSW5mby5hbGlhc2VzLmZpbmQoYSA9PiBhID09PSBuYW1lKSkge1xyXG4gICAgICAgICAgICByZXR1cm4gdGhpcztcclxuICAgICAgICB9XHJcbiAgICAgICAgcmV0dXJuIHRoaXMuX2NoaWxkS2VybmVscy50cnlHZXRCeUFsaWFzKG5hbWUpO1xyXG4gICAgfVxyXG5cclxuICAgIGZpbmRLZXJuZWxzKHByZWRpY2F0ZTogKGtlcm5lbDogS2VybmVsKSA9PiBib29sZWFuKTogS2VybmVsW10ge1xyXG4gICAgICAgIHZhciByZXN1bHRzOiBLZXJuZWxbXSA9IFtdO1xyXG4gICAgICAgIGlmIChwcmVkaWNhdGUodGhpcykpIHtcclxuICAgICAgICAgICAgcmVzdWx0cy5wdXNoKHRoaXMpO1xyXG4gICAgICAgIH1cclxuICAgICAgICBmb3IgKGxldCBrZXJuZWwgb2YgdGhpcy5jaGlsZEtlcm5lbHMpIHtcclxuICAgICAgICAgICAgaWYgKHByZWRpY2F0ZShrZXJuZWwpKSB7XHJcbiAgICAgICAgICAgICAgICByZXN1bHRzLnB1c2goa2VybmVsKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4gcmVzdWx0cztcclxuICAgIH1cclxuXHJcbiAgICBmaW5kS2VybmVsKHByZWRpY2F0ZTogKGtlcm5lbDogS2VybmVsKSA9PiBib29sZWFuKTogS2VybmVsIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICBpZiAocHJlZGljYXRlKHRoaXMpKSB7XHJcbiAgICAgICAgICAgIHJldHVybiB0aGlzO1xyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4gdGhpcy5jaGlsZEtlcm5lbHMuZmluZChwcmVkaWNhdGUpO1xyXG4gICAgfVxyXG5cclxuICAgIHNldERlZmF1bHRUYXJnZXRLZXJuZWxOYW1lRm9yQ29tbWFuZChjb21tYW5kVHlwZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZFR5cGUsIGtlcm5lbE5hbWU6IHN0cmluZykge1xyXG4gICAgICAgIHRoaXMuX2RlZmF1bHRLZXJuZWxOYW1lc0J5Q29tbWFuZFR5cGUuc2V0KGNvbW1hbmRUeXBlLCBrZXJuZWxOYW1lKTtcclxuICAgIH1cclxuICAgIG92ZXJyaWRlIGhhbmRsZUNvbW1hbmQoY29tbWFuZEVudmVsb3BlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGUpOiBQcm9taXNlPHZvaWQ+IHtcclxuICAgICAgICBjb25zdCBpbnZvY2F0aW9uQ29udGV4dCA9IEtlcm5lbEludm9jYXRpb25Db250ZXh0LmN1cnJlbnQ7XHJcblxyXG4gICAgICAgIGxldCBrZXJuZWwgPSBjb21tYW5kRW52ZWxvcGUuY29tbWFuZC50YXJnZXRLZXJuZWxOYW1lID09PSB0aGlzLm5hbWVcclxuICAgICAgICAgICAgPyB0aGlzXHJcbiAgICAgICAgICAgIDogdGhpcy5nZXRIYW5kbGluZ0tlcm5lbChjb21tYW5kRW52ZWxvcGUsIGludm9jYXRpb25Db250ZXh0KTtcclxuXHJcblxyXG4gICAgICAgIGNvbnN0IHByZXZpdXNvSGFuZGxpbmdLZXJuZWwgPSBpbnZvY2F0aW9uQ29udGV4dD8uaGFuZGxpbmdLZXJuZWwgPz8gbnVsbDtcclxuXHJcbiAgICAgICAgaWYgKGtlcm5lbCA9PT0gdGhpcykge1xyXG4gICAgICAgICAgICBpZiAoaW52b2NhdGlvbkNvbnRleHQgIT09IG51bGwpIHtcclxuICAgICAgICAgICAgICAgIGludm9jYXRpb25Db250ZXh0LmhhbmRsaW5nS2VybmVsID0ga2VybmVsO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIHJldHVybiBzdXBlci5oYW5kbGVDb21tYW5kKGNvbW1hbmRFbnZlbG9wZSkuZmluYWxseSgoKSA9PiB7XHJcbiAgICAgICAgICAgICAgICBpZiAoaW52b2NhdGlvbkNvbnRleHQgIT09IG51bGwpIHtcclxuICAgICAgICAgICAgICAgICAgICBpbnZvY2F0aW9uQ29udGV4dC5oYW5kbGluZ0tlcm5lbCA9IHByZXZpdXNvSGFuZGxpbmdLZXJuZWw7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH0pO1xyXG4gICAgICAgIH0gZWxzZSBpZiAoa2VybmVsKSB7XHJcbiAgICAgICAgICAgIGlmIChpbnZvY2F0aW9uQ29udGV4dCAhPT0gbnVsbCkge1xyXG4gICAgICAgICAgICAgICAgaW52b2NhdGlvbkNvbnRleHQuaGFuZGxpbmdLZXJuZWwgPSBrZXJuZWw7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgY29uc3Qga2VybmVsVXJpID0gZ2V0S2VybmVsVXJpKGtlcm5lbCk7XHJcbiAgICAgICAgICAgIGlmICghY29tbWFuZEVudmVsb3BlLnJvdXRpbmdTbGlwLmNvbnRhaW5zKGtlcm5lbFVyaSkpIHtcclxuICAgICAgICAgICAgICAgIGNvbW1hbmRFbnZlbG9wZS5yb3V0aW5nU2xpcC5zdGFtcEFzQXJyaXZlZChrZXJuZWxVcmkpO1xyXG4gICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQud2FybihgVHJ5aW5nIHRvIHN0YW1wICR7Y29tbWFuZEVudmVsb3BlLmNvbW1hbmRUeXBlfSBhcyBhcnJpdmVkIGJ1dCB1cmkgJHtrZXJuZWxVcml9IGlzIGFscmVhZHkgcHJlc2VudC5gKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICByZXR1cm4ga2VybmVsLmhhbmRsZUNvbW1hbmQoY29tbWFuZEVudmVsb3BlKS5maW5hbGx5KCgpID0+IHtcclxuICAgICAgICAgICAgICAgIGlmIChpbnZvY2F0aW9uQ29udGV4dCAhPT0gbnVsbCkge1xyXG4gICAgICAgICAgICAgICAgICAgIGludm9jYXRpb25Db250ZXh0LmhhbmRsaW5nS2VybmVsID0gcHJldml1c29IYW5kbGluZ0tlcm5lbDtcclxuICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgIGlmICghY29tbWFuZEVudmVsb3BlLnJvdXRpbmdTbGlwLmNvbnRhaW5zKGtlcm5lbFVyaSkpIHtcclxuICAgICAgICAgICAgICAgICAgICBjb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAuc3RhbXAoa2VybmVsVXJpKTtcclxuICAgICAgICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQud2FybihgVHJ5aW5nIHRvIHN0YW1wICR7Y29tbWFuZEVudmVsb3BlLmNvbW1hbmRUeXBlfSBhcyBjb21wbGV0ZWQgYnV0IHVyaSAke2tlcm5lbFVyaX0gaXMgYWxyZWFkeSBwcmVzZW50LmApO1xyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9KTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmIChpbnZvY2F0aW9uQ29udGV4dCAhPT0gbnVsbCkge1xyXG4gICAgICAgICAgICBpbnZvY2F0aW9uQ29udGV4dC5oYW5kbGluZ0tlcm5lbCA9IHByZXZpdXNvSGFuZGxpbmdLZXJuZWw7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHJldHVybiBQcm9taXNlLnJlamVjdChuZXcgRXJyb3IoXCJLZXJuZWwgbm90IGZvdW5kOiBcIiArIGNvbW1hbmRFbnZlbG9wZS5jb21tYW5kLnRhcmdldEtlcm5lbE5hbWUpKTtcclxuICAgIH1cclxuXHJcbiAgICBvdmVycmlkZSBnZXRIYW5kbGluZ0tlcm5lbChjb21tYW5kRW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSwgY29udGV4dD86IEtlcm5lbEludm9jYXRpb25Db250ZXh0IHwgbnVsbCk6IEtlcm5lbCB8IG51bGwge1xyXG5cclxuICAgICAgICBsZXQga2VybmVsOiBLZXJuZWwgfCBudWxsID0gbnVsbDtcclxuICAgICAgICBpZiAoY29tbWFuZEVudmVsb3BlLmNvbW1hbmQuZGVzdGluYXRpb25VcmkpIHtcclxuICAgICAgICAgICAgY29uc3Qgbm9ybWFsaXplZCA9IHJvdXRpbmdzbGlwLmNyZWF0ZUtlcm5lbFVyaShjb21tYW5kRW52ZWxvcGUuY29tbWFuZC5kZXN0aW5hdGlvblVyaSk7XHJcbiAgICAgICAgICAgIGtlcm5lbCA9IHRoaXMuX2NoaWxkS2VybmVscy50cnlHZXRCeVVyaShub3JtYWxpemVkKSA/PyBudWxsO1xyXG4gICAgICAgICAgICBpZiAoa2VybmVsKSB7XHJcbiAgICAgICAgICAgICAgICByZXR1cm4ga2VybmVsO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICBsZXQgdGFyZ2V0S2VybmVsTmFtZSA9IGNvbW1hbmRFbnZlbG9wZS5jb21tYW5kLnRhcmdldEtlcm5lbE5hbWU7XHJcblxyXG4gICAgICAgIGlmICh0YXJnZXRLZXJuZWxOYW1lID09PSB1bmRlZmluZWQgfHwgdGFyZ2V0S2VybmVsTmFtZSA9PT0gbnVsbCkge1xyXG4gICAgICAgICAgICBpZiAodGhpcy5jYW5IYW5kbGUoY29tbWFuZEVudmVsb3BlKSkge1xyXG4gICAgICAgICAgICAgICAgcmV0dXJuIHRoaXM7XHJcbiAgICAgICAgICAgIH1cclxuXHJcbiAgICAgICAgICAgIHRhcmdldEtlcm5lbE5hbWUgPSB0aGlzLl9kZWZhdWx0S2VybmVsTmFtZXNCeUNvbW1hbmRUeXBlLmdldChjb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGUpID8/IHRoaXMuZGVmYXVsdEtlcm5lbE5hbWU7XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICBpZiAodGFyZ2V0S2VybmVsTmFtZSAhPT0gdW5kZWZpbmVkICYmIHRhcmdldEtlcm5lbE5hbWUgIT09IG51bGwpIHtcclxuICAgICAgICAgICAga2VybmVsID0gdGhpcy5fY2hpbGRLZXJuZWxzLnRyeUdldEJ5QWxpYXModGFyZ2V0S2VybmVsTmFtZSkgPz8gbnVsbDtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmICh0YXJnZXRLZXJuZWxOYW1lICYmICFrZXJuZWwpIHtcclxuICAgICAgICAgICAgY29uc3QgZXJyb3JNZXNzYWdlID0gYEtlcm5lbCBub3QgZm91bmQ6ICR7dGFyZ2V0S2VybmVsTmFtZX1gO1xyXG4gICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC5lcnJvcihlcnJvck1lc3NhZ2UpO1xyXG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoZXJyb3JNZXNzYWdlKTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmICgha2VybmVsKSB7XHJcblxyXG4gICAgICAgICAgICBpZiAodGhpcy5fY2hpbGRLZXJuZWxzLmNvdW50ID09PSAxKSB7XHJcbiAgICAgICAgICAgICAgICBrZXJuZWwgPSB0aGlzLl9jaGlsZEtlcm5lbHMuc2luZ2xlKCkgPz8gbnVsbDtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgaWYgKCFrZXJuZWwpIHtcclxuICAgICAgICAgICAga2VybmVsID0gY29udGV4dD8uaGFuZGxpbmdLZXJuZWwgPz8gbnVsbDtcclxuICAgICAgICB9XHJcbiAgICAgICAgcmV0dXJuIGtlcm5lbCA/PyB0aGlzO1xyXG5cclxuICAgIH1cclxufVxyXG5cclxuY2xhc3MgS2VybmVsQ29sbGVjdGlvbiBpbXBsZW1lbnRzIEl0ZXJhYmxlPEtlcm5lbD4ge1xyXG5cclxuICAgIHByaXZhdGUgX2NvbXBvc2l0ZUtlcm5lbDogQ29tcG9zaXRlS2VybmVsO1xyXG4gICAgcHJpdmF0ZSBfa2VybmVsczogS2VybmVsW10gPSBbXTtcclxuICAgIHByaXZhdGUgX25hbWVBbmRBbGlhc2VzQnlLZXJuZWw6IE1hcDxLZXJuZWwsIFNldDxzdHJpbmc+PiA9IG5ldyBNYXA8S2VybmVsLCBTZXQ8c3RyaW5nPj4oKTtcclxuICAgIHByaXZhdGUgX2tlcm5lbHNCeU5hbWVPckFsaWFzOiBNYXA8c3RyaW5nLCBLZXJuZWw+ID0gbmV3IE1hcDxzdHJpbmcsIEtlcm5lbD4oKTtcclxuICAgIHByaXZhdGUgX2tlcm5lbHNCeUxvY2FsVXJpOiBNYXA8c3RyaW5nLCBLZXJuZWw+ID0gbmV3IE1hcDxzdHJpbmcsIEtlcm5lbD4oKTtcclxuICAgIHByaXZhdGUgX2tlcm5lbHNCeVJlbW90ZVVyaTogTWFwPHN0cmluZywgS2VybmVsPiA9IG5ldyBNYXA8c3RyaW5nLCBLZXJuZWw+KCk7XHJcblxyXG4gICAgY29uc3RydWN0b3IoY29tcG9zaXRlS2VybmVsOiBDb21wb3NpdGVLZXJuZWwpIHtcclxuICAgICAgICB0aGlzLl9jb21wb3NpdGVLZXJuZWwgPSBjb21wb3NpdGVLZXJuZWw7XHJcbiAgICB9XHJcblxyXG4gICAgW1N5bWJvbC5pdGVyYXRvcl0oKTogSXRlcmF0b3I8S2VybmVsPiB7XHJcbiAgICAgICAgbGV0IGNvdW50ZXIgPSAwO1xyXG4gICAgICAgIHJldHVybiB7XHJcbiAgICAgICAgICAgIG5leHQ6ICgpID0+IHtcclxuICAgICAgICAgICAgICAgIHJldHVybiB7XHJcbiAgICAgICAgICAgICAgICAgICAgdmFsdWU6IHRoaXMuX2tlcm5lbHNbY291bnRlcisrXSxcclxuICAgICAgICAgICAgICAgICAgICBkb25lOiBjb3VudGVyID4gdGhpcy5fa2VybmVscy5sZW5ndGhcclxuICAgICAgICAgICAgICAgIH07XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9O1xyXG4gICAgfVxyXG5cclxuICAgIHNpbmdsZSgpOiBLZXJuZWwgfCB1bmRlZmluZWQge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9rZXJuZWxzLmxlbmd0aCA9PT0gMSA/IHRoaXMuX2tlcm5lbHNbMF0gOiB1bmRlZmluZWQ7XHJcbiAgICB9XHJcblxyXG5cclxuICAgIHB1YmxpYyBhZGQoa2VybmVsOiBLZXJuZWwsIGFsaWFzZXM/OiBzdHJpbmdbXSk6IHZvaWQge1xyXG4gICAgICAgIGlmICh0aGlzLl9rZXJuZWxzQnlOYW1lT3JBbGlhcy5oYXMoa2VybmVsLm5hbWUpKSB7XHJcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihga2VybmVsIHdpdGggbmFtZSAke2tlcm5lbC5uYW1lfSBhbHJlYWR5IGV4aXN0c2ApO1xyXG4gICAgICAgIH1cclxuICAgICAgICB0aGlzLnVwZGF0ZUtlcm5lbEluZm9BbmRJbmRleChrZXJuZWwsIGFsaWFzZXMpO1xyXG4gICAgICAgIHRoaXMuX2tlcm5lbHMucHVzaChrZXJuZWwpO1xyXG4gICAgfVxyXG5cclxuXHJcbiAgICBnZXQgY291bnQoKTogbnVtYmVyIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fa2VybmVscy5sZW5ndGg7XHJcbiAgICB9XHJcblxyXG4gICAgdXBkYXRlS2VybmVsSW5mb0FuZEluZGV4KGtlcm5lbDogS2VybmVsLCBhbGlhc2VzPzogc3RyaW5nW10pOiB2b2lkIHtcclxuXHJcbiAgICAgICAgaWYgKGFsaWFzZXMpIHtcclxuICAgICAgICAgICAgZm9yIChsZXQgYWxpYXMgb2YgYWxpYXNlcykge1xyXG4gICAgICAgICAgICAgICAgaWYgKHRoaXMuX2tlcm5lbHNCeU5hbWVPckFsaWFzLmhhcyhhbGlhcykpIHtcclxuICAgICAgICAgICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoYGtlcm5lbCB3aXRoIGFsaWFzICR7YWxpYXN9IGFscmVhZHkgZXhpc3RzYCk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmICghdGhpcy5fbmFtZUFuZEFsaWFzZXNCeUtlcm5lbC5oYXMoa2VybmVsKSkge1xyXG5cclxuICAgICAgICAgICAgbGV0IHNldCA9IG5ldyBTZXQ8c3RyaW5nPigpO1xyXG5cclxuICAgICAgICAgICAgZm9yIChsZXQgYWxpYXMgb2Yga2VybmVsLmtlcm5lbEluZm8uYWxpYXNlcykge1xyXG4gICAgICAgICAgICAgICAgc2V0LmFkZChhbGlhcyk7XHJcbiAgICAgICAgICAgIH1cclxuXHJcbiAgICAgICAgICAgIGtlcm5lbC5rZXJuZWxJbmZvLmFsaWFzZXMgPSBBcnJheS5mcm9tKHNldCk7XHJcblxyXG4gICAgICAgICAgICBzZXQuYWRkKGtlcm5lbC5rZXJuZWxJbmZvLmxvY2FsTmFtZSk7XHJcblxyXG4gICAgICAgICAgICB0aGlzLl9uYW1lQW5kQWxpYXNlc0J5S2VybmVsLnNldChrZXJuZWwsIHNldCk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGlmIChhbGlhc2VzKSB7XHJcbiAgICAgICAgICAgIGZvciAobGV0IGFsaWFzIG9mIGFsaWFzZXMpIHtcclxuICAgICAgICAgICAgICAgIHRoaXMuX25hbWVBbmRBbGlhc2VzQnlLZXJuZWwuZ2V0KGtlcm5lbCkhLmFkZChhbGlhcyk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIHRoaXMuX25hbWVBbmRBbGlhc2VzQnlLZXJuZWwuZ2V0KGtlcm5lbCk/LmZvckVhY2goYWxpYXMgPT4ge1xyXG4gICAgICAgICAgICB0aGlzLl9rZXJuZWxzQnlOYW1lT3JBbGlhcy5zZXQoYWxpYXMsIGtlcm5lbCk7XHJcbiAgICAgICAgfSk7XHJcblxyXG4gICAgICAgIGxldCBiYXNlVXJpID0gdGhpcy5fY29tcG9zaXRlS2VybmVsLmhvc3Q/LnVyaSB8fCB0aGlzLl9jb21wb3NpdGVLZXJuZWwua2VybmVsSW5mby51cmk7XHJcblxyXG4gICAgICAgIGlmICghYmFzZVVyaSEuZW5kc1dpdGgoXCIvXCIpKSB7XHJcbiAgICAgICAgICAgIGJhc2VVcmkgKz0gXCIvXCI7XHJcblxyXG4gICAgICAgIH1cclxuICAgICAgICBrZXJuZWwua2VybmVsSW5mby51cmkgPSByb3V0aW5nc2xpcC5jcmVhdGVLZXJuZWxVcmkoYCR7YmFzZVVyaX0ke2tlcm5lbC5rZXJuZWxJbmZvLmxvY2FsTmFtZX1gKTtcclxuICAgICAgICB0aGlzLl9rZXJuZWxzQnlMb2NhbFVyaS5zZXQoa2VybmVsLmtlcm5lbEluZm8udXJpLCBrZXJuZWwpO1xyXG5cclxuXHJcbiAgICAgICAgaWYgKGtlcm5lbC5rZXJuZWxJbmZvLmlzUHJveHkpIHtcclxuICAgICAgICAgICAgdGhpcy5fa2VybmVsc0J5UmVtb3RlVXJpLnNldChrZXJuZWwua2VybmVsSW5mby5yZW1vdGVVcmkhLCBrZXJuZWwpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgdHJ5R2V0QnlBbGlhcyhhbGlhczogc3RyaW5nKTogS2VybmVsIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fa2VybmVsc0J5TmFtZU9yQWxpYXMuZ2V0KGFsaWFzKTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgdHJ5R2V0QnlVcmkodXJpOiBzdHJpbmcpOiBLZXJuZWwgfCB1bmRlZmluZWQge1xyXG4gICAgICAgIGxldCBrZXJuZWwgPSB0aGlzLl9rZXJuZWxzQnlMb2NhbFVyaS5nZXQodXJpKSB8fCB0aGlzLl9rZXJuZWxzQnlSZW1vdGVVcmkuZ2V0KHVyaSk7XHJcbiAgICAgICAgcmV0dXJuIGtlcm5lbDtcclxuICAgIH1cclxuXHJcbiAgICBub3RpZnlUaGF0SG9zdFdhc1NldCgpIHtcclxuICAgICAgICBmb3IgKGxldCBrZXJuZWwgb2YgdGhpcy5fa2VybmVscykge1xyXG4gICAgICAgICAgICB0aGlzLnVwZGF0ZUtlcm5lbEluZm9BbmRJbmRleChrZXJuZWwpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxufVxyXG4iLCIvLyBDb3B5cmlnaHQgKGMpIC5ORVQgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzLiBBbGwgcmlnaHRzIHJlc2VydmVkLlxyXG4vLyBMaWNlbnNlZCB1bmRlciB0aGUgTUlUIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIGZpbGUgaW4gdGhlIHByb2plY3Qgcm9vdCBmb3IgZnVsbCBsaWNlbnNlIGluZm9ybWF0aW9uLlxyXG5cclxuaW1wb3J0ICogYXMgcnhqcyBmcm9tICdyeGpzJztcclxuaW1wb3J0IHsgQ29tcG9zaXRlS2VybmVsIH0gZnJvbSAnLi9jb21wb3NpdGVLZXJuZWwnO1xyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tICcuL2NvbW1hbmRzQW5kRXZlbnRzJztcclxuaW1wb3J0ICogYXMgZGlzcG9zYWJsZXMgZnJvbSAnLi9kaXNwb3NhYmxlcyc7XHJcbmltcG9ydCB7IERpc3Bvc2FibGUgfSBmcm9tICcuL2Rpc3Bvc2FibGVzJztcclxuaW1wb3J0IHsgTG9nZ2VyIH0gZnJvbSAnLi9sb2dnZXInO1xyXG5cclxuZXhwb3J0IHR5cGUgS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZSA9IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSB8IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGU7XHJcblxyXG5leHBvcnQgdHlwZSBLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlTW9kZWwgPSBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGVNb2RlbCB8IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGVNb2RlbDtcclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBpc0tlcm5lbENvbW1hbmRFbnZlbG9wZShjb21tYW5kT3JFdmVudDogS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZSk6IGNvbW1hbmRPckV2ZW50IGlzIGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSB7XHJcbiAgICByZXR1cm4gKDxhbnk+Y29tbWFuZE9yRXZlbnQpLmNvbW1hbmRUeXBlICE9PSB1bmRlZmluZWQ7XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBpc0tlcm5lbENvbW1hbmRFbnZlbG9wZU1vZGVsKGNvbW1hbmRPckV2ZW50OiBLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlTW9kZWwpOiBjb21tYW5kT3JFdmVudCBpcyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGVNb2RlbCB7XHJcbiAgICByZXR1cm4gKDxhbnk+Y29tbWFuZE9yRXZlbnQpLmNvbW1hbmRUeXBlICE9PSB1bmRlZmluZWQ7XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBpc0tlcm5lbEV2ZW50RW52ZWxvcGUoY29tbWFuZE9yRXZlbnQ6IEtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUpOiBjb21tYW5kT3JFdmVudCBpcyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlIHtcclxuICAgIHJldHVybiAoPGFueT5jb21tYW5kT3JFdmVudCkuZXZlbnRUeXBlICE9PSB1bmRlZmluZWQ7XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBpc0tlcm5lbEV2ZW50RW52ZWxvcGVNb2RlbChjb21tYW5kT3JFdmVudDogS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZU1vZGVsKTogY29tbWFuZE9yRXZlbnQgaXMgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZU1vZGVsIHtcclxuICAgIHJldHVybiAoPGFueT5jb21tYW5kT3JFdmVudCkuZXZlbnRUeXBlICE9PSB1bmRlZmluZWQ7XHJcbn1cclxuXHJcbmV4cG9ydCBpbnRlcmZhY2UgSUtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyIGV4dGVuZHMgcnhqcy5TdWJzY3JpYmFibGU8S2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZT4ge1xyXG59XHJcblxyXG5leHBvcnQgaW50ZXJmYWNlIElLZXJuZWxDb21tYW5kQW5kRXZlbnRTZW5kZXIge1xyXG4gICAgc2VuZChrZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlOiBLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlKTogUHJvbWlzZTx2b2lkPjtcclxufVxyXG5cclxuZXhwb3J0IGNsYXNzIEtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyIGltcGxlbWVudHMgSUtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyIHtcclxuICAgIHByaXZhdGUgX29ic2VydmFibGU6IHJ4anMuU3Vic2NyaWJhYmxlPEtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU+O1xyXG4gICAgcHJpdmF0ZSBfZGlzcG9zYWJsZXM6IGRpc3Bvc2FibGVzLkRpc3Bvc2FibGVbXSA9IFtdO1xyXG5cclxuICAgIHByaXZhdGUgY29uc3RydWN0b3Iob2JzZXJ2ZXI6IHJ4anMuT2JzZXJ2YWJsZTxLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlPikge1xyXG4gICAgICAgIHRoaXMuX29ic2VydmFibGUgPSBvYnNlcnZlcjtcclxuICAgIH1cclxuXHJcbiAgICBzdWJzY3JpYmUob2JzZXJ2ZXI6IFBhcnRpYWw8cnhqcy5PYnNlcnZlcjxLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlPj4pOiByeGpzLlVuc3Vic2NyaWJhYmxlIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fb2JzZXJ2YWJsZS5zdWJzY3JpYmUob2JzZXJ2ZXIpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBkaXNwb3NlKCk6IHZvaWQge1xyXG4gICAgICAgIGZvciAobGV0IGRpc3Bvc2FibGUgb2YgdGhpcy5fZGlzcG9zYWJsZXMpIHtcclxuICAgICAgICAgICAgZGlzcG9zYWJsZS5kaXNwb3NlKCk7XHJcbiAgICAgICAgfVxyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBzdGF0aWMgRnJvbU9ic2VydmFibGUob2JzZXJ2YWJsZTogcnhqcy5PYnNlcnZhYmxlPEtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU+KTogSUtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyIHtcclxuICAgICAgICByZXR1cm4gbmV3IEtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyKG9ic2VydmFibGUpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBzdGF0aWMgRnJvbUV2ZW50TGlzdGVuZXIoYXJnczogeyBtYXA6IChkYXRhOiBFdmVudCkgPT4gS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZSwgZXZlbnRUYXJnZXQ6IEV2ZW50VGFyZ2V0LCBldmVudDogc3RyaW5nIH0pOiBJS2VybmVsQ29tbWFuZEFuZEV2ZW50UmVjZWl2ZXIge1xyXG4gICAgICAgIGxldCBzdWJqZWN0ID0gbmV3IHJ4anMuU3ViamVjdDxLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlPigpO1xyXG4gICAgICAgIGNvbnN0IGxpc3RlbmVyID0gKGU6IEV2ZW50KSA9PiB7XHJcbiAgICAgICAgICAgIGxldCBtYXBwZWQgPSBhcmdzLm1hcChlKTtcclxuICAgICAgICAgICAgc3ViamVjdC5uZXh0KG1hcHBlZCk7XHJcbiAgICAgICAgfTtcclxuICAgICAgICBhcmdzLmV2ZW50VGFyZ2V0LmFkZEV2ZW50TGlzdGVuZXIoYXJncy5ldmVudCwgbGlzdGVuZXIpO1xyXG4gICAgICAgIGNvbnN0IHJldCA9IG5ldyBLZXJuZWxDb21tYW5kQW5kRXZlbnRSZWNlaXZlcihzdWJqZWN0KTtcclxuICAgICAgICByZXQuX2Rpc3Bvc2FibGVzLnB1c2goe1xyXG4gICAgICAgICAgICBkaXNwb3NlOiAoKSA9PiB7XHJcbiAgICAgICAgICAgICAgICBhcmdzLmV2ZW50VGFyZ2V0LnJlbW92ZUV2ZW50TGlzdGVuZXIoYXJncy5ldmVudCwgbGlzdGVuZXIpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfSk7XHJcbiAgICAgICAgYXJncy5ldmVudFRhcmdldC5yZW1vdmVFdmVudExpc3RlbmVyKGFyZ3MuZXZlbnQsIGxpc3RlbmVyKTtcclxuICAgICAgICByZXR1cm4gcmV0O1xyXG4gICAgfVxyXG59XHJcblxyXG5mdW5jdGlvbiBpc09ic2VydmFibGUoc291cmNlOiBhbnkpOiBzb3VyY2UgaXMgcnhqcy5PYnNlcnZlcjxLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlPiB7XHJcbiAgICByZXR1cm4gKDxhbnk+c291cmNlKS5uZXh0ICE9PSB1bmRlZmluZWQ7XHJcbn1cclxuXHJcbmV4cG9ydCBjbGFzcyBLZXJuZWxDb21tYW5kQW5kRXZlbnRTZW5kZXIgaW1wbGVtZW50cyBJS2VybmVsQ29tbWFuZEFuZEV2ZW50U2VuZGVyIHtcclxuICAgIHByaXZhdGUgX3NlbmRlcj86IHJ4anMuT2JzZXJ2ZXI8S2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZT4gfCAoKGtlcm5lbEV2ZW50RW52ZWxvcGU6IEtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUpID0+IHZvaWQpO1xyXG4gICAgcHJpdmF0ZSBjb25zdHJ1Y3RvcigpIHtcclxuICAgIH1cclxuICAgIHNlbmQoa2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZTogS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZSk6IFByb21pc2U8dm9pZD4ge1xyXG4gICAgICAgIGlmICh0aGlzLl9zZW5kZXIpIHtcclxuICAgICAgICAgICAgdHJ5IHtcclxuICAgICAgICAgICAgICAgIGNvbnN0IGNsb25lID0ga2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZS5jbG9uZSgpO1xyXG4gICAgICAgICAgICAgICAgaWYgKHR5cGVvZiB0aGlzLl9zZW5kZXIgPT09IFwiZnVuY3Rpb25cIikge1xyXG4gICAgICAgICAgICAgICAgICAgIHRoaXMuX3NlbmRlcihjbG9uZSk7XHJcbiAgICAgICAgICAgICAgICB9IGVsc2UgaWYgKGlzT2JzZXJ2YWJsZSh0aGlzLl9zZW5kZXIpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgaWYgKGlzS2VybmVsQ29tbWFuZEVudmVsb3BlKGtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuX3NlbmRlci5uZXh0KGNsb25lKTtcclxuICAgICAgICAgICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICB0aGlzLl9zZW5kZXIubmV4dChjbG9uZSk7XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgICAgICByZXR1cm4gUHJvbWlzZS5yZWplY3QobmV3IEVycm9yKFwiU2VuZGVyIGlzIG5vdCBzZXRcIikpO1xyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIGNhdGNoIChlcnJvcikge1xyXG4gICAgICAgICAgICAgICAgcmV0dXJuIFByb21pc2UucmVqZWN0KGVycm9yKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICByZXR1cm4gUHJvbWlzZS5yZXNvbHZlKCk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHJldHVybiBQcm9taXNlLnJlamVjdChuZXcgRXJyb3IoXCJTZW5kZXIgaXMgbm90IHNldFwiKSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHN0YXRpYyBGcm9tT2JzZXJ2ZXIob2JzZXJ2ZXI6IHJ4anMuT2JzZXJ2ZXI8S2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZT4pOiBJS2VybmVsQ29tbWFuZEFuZEV2ZW50U2VuZGVyIHtcclxuICAgICAgICBjb25zdCBzZW5kZXIgPSBuZXcgS2VybmVsQ29tbWFuZEFuZEV2ZW50U2VuZGVyKCk7XHJcbiAgICAgICAgc2VuZGVyLl9zZW5kZXIgPSBvYnNlcnZlcjtcclxuICAgICAgICByZXR1cm4gc2VuZGVyO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBzdGF0aWMgRnJvbUZ1bmN0aW9uKHNlbmQ6IChrZXJuZWxFdmVudEVudmVsb3BlOiBLZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlKSA9PiB2b2lkKTogSUtlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlciB7XHJcbiAgICAgICAgY29uc3Qgc2VuZGVyID0gbmV3IEtlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlcigpO1xyXG4gICAgICAgIHNlbmRlci5fc2VuZGVyID0gc2VuZDtcclxuICAgICAgICByZXR1cm4gc2VuZGVyO1xyXG4gICAgfVxyXG59XHJcblxyXG5leHBvcnQgZnVuY3Rpb24gaXNTZXRPZlN0cmluZyhjb2xsZWN0aW9uOiBhbnkpOiBjb2xsZWN0aW9uIGlzIFNldDxzdHJpbmc+IHtcclxuICAgIHJldHVybiB0eXBlb2YgKGNvbGxlY3Rpb24pICE9PSB0eXBlb2YgKG5ldyBTZXQ8c3RyaW5nPigpKTtcclxufVxyXG5cclxuZXhwb3J0IGZ1bmN0aW9uIGlzQXJyYXlPZlN0cmluZyhjb2xsZWN0aW9uOiBhbnkpOiBjb2xsZWN0aW9uIGlzIHN0cmluZ1tdIHtcclxuICAgIHJldHVybiBBcnJheS5pc0FycmF5KGNvbGxlY3Rpb24pICYmIGNvbGxlY3Rpb24ubGVuZ3RoID4gMCAmJiB0eXBlb2YgKGNvbGxlY3Rpb25bMF0pID09PSB0eXBlb2YgKFwiXCIpO1xyXG59XHJcblxyXG5jb25zdCBvbktlcm5lbEluZm9VcGRhdGVzOiAoKGNvbXBvc2l0ZUtlcm5lbDogQ29tcG9zaXRlS2VybmVsKSA9PiB2b2lkKVtdID0gW107XHJcbmV4cG9ydCBmdW5jdGlvbiByZWdpc3RlckZvcktlcm5lbEluZm9VcGRhdGVzKGNhbGxiYWNrOiAoY29tcG9zaXRlS2VybmVsOiBDb21wb3NpdGVLZXJuZWwpID0+IHZvaWQpIHtcclxuICAgIG9uS2VybmVsSW5mb1VwZGF0ZXMucHVzaChjYWxsYmFjayk7XHJcbn1cclxuZnVuY3Rpb24gbm90aWZ5T2ZLZXJuZWxJbmZvVXBkYXRlcyhjb21wb3NpdGVLZXJuZWw6IENvbXBvc2l0ZUtlcm5lbCkge1xyXG4gICAgZm9yIChjb25zdCB1cGRhdGVyIG9mIG9uS2VybmVsSW5mb1VwZGF0ZXMpIHtcclxuICAgICAgICB1cGRhdGVyKGNvbXBvc2l0ZUtlcm5lbCk7XHJcbiAgICB9XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBlbnN1cmVPclVwZGF0ZVByb3h5Rm9yS2VybmVsSW5mbyhrZXJuZWxJbmZvOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvLCBjb21wb3NpdGVLZXJuZWw6IENvbXBvc2l0ZUtlcm5lbCkge1xyXG4gICAgaWYgKGtlcm5lbEluZm8uaXNQcm94eSkge1xyXG4gICAgICAgIGNvbnN0IGhvc3QgPSBleHRyYWN0SG9zdEFuZE5vbWFsaXplKGtlcm5lbEluZm8ucmVtb3RlVXJpISk7XHJcbiAgICAgICAgaWYgKGhvc3QgPT09IGV4dHJhY3RIb3N0QW5kTm9tYWxpemUoY29tcG9zaXRlS2VybmVsLmtlcm5lbEluZm8udXJpKSkge1xyXG4gICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC53YXJuKGBza2lwcGluIGNyZWF0aW9uIG9mIHByb3h5IGZvciBhIHByb3h5IGtlcm5lbCA6IFske0pTT04uc3RyaW5naWZ5KGtlcm5lbEluZm8pfV1gKTtcclxuICAgICAgICAgICAgcmV0dXJuO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxuICAgIGNvbnN0IHVyaVRvTG9va3VwID0ga2VybmVsSW5mby5pc1Byb3h5ID8ga2VybmVsSW5mby5yZW1vdGVVcmkhIDoga2VybmVsSW5mby51cmk7XHJcbiAgICBpZiAodXJpVG9Mb29rdXApIHtcclxuICAgICAgICBsZXQga2VybmVsID0gY29tcG9zaXRlS2VybmVsLmZpbmRLZXJuZWxCeVVyaSh1cmlUb0xvb2t1cCk7XHJcbiAgICAgICAgaWYgKCFrZXJuZWwpIHtcclxuICAgICAgICAgICAgLy8gYWRkXHJcbiAgICAgICAgICAgIGlmIChjb21wb3NpdGVLZXJuZWwuaG9zdCkge1xyXG4gICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgY3JlYXRpbmcgcHJveHkgZm9yIHVyaVske3VyaVRvTG9va3VwfV13aXRoIGluZm8gJHtKU09OLnN0cmluZ2lmeShrZXJuZWxJbmZvKX1gKTtcclxuICAgICAgICAgICAgICAgIC8vIGNoZWNrIGZvciBjbGFzaCB3aXRoIGBrZXJuZWxJbmZvLmxvY2FsTmFtZWBcclxuICAgICAgICAgICAgICAgIGtlcm5lbCA9IGNvbXBvc2l0ZUtlcm5lbC5ob3N0LmNvbm5lY3RQcm94eUtlcm5lbChrZXJuZWxJbmZvLmxvY2FsTmFtZSwgdXJpVG9Mb29rdXAsIGtlcm5lbEluZm8uYWxpYXNlcyk7XHJcbiAgICAgICAgICAgICAgICB1cGRhdGVLZXJuZWxJbmZvKGtlcm5lbC5rZXJuZWxJbmZvLCBrZXJuZWxJbmZvKTtcclxuICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcignbm8ga2VybmVsIGhvc3QgZm91bmQnKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYHBhdGNoaW5nIHByb3h5IGZvciB1cmlbJHt1cmlUb0xvb2t1cH1dd2l0aCBpbmZvICR7SlNPTi5zdHJpbmdpZnkoa2VybmVsSW5mbyl9IGApO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgaWYgKGtlcm5lbC5rZXJuZWxJbmZvLmlzUHJveHkpIHtcclxuICAgICAgICAgICAgLy8gcGF0Y2hcclxuICAgICAgICAgICAgdXBkYXRlS2VybmVsSW5mbyhrZXJuZWwua2VybmVsSW5mbywga2VybmVsSW5mbyk7XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICBub3RpZnlPZktlcm5lbEluZm9VcGRhdGVzKGNvbXBvc2l0ZUtlcm5lbCk7XHJcbiAgICB9XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBpc0tlcm5lbEluZm9Gb3JQcm94eShrZXJuZWxJbmZvOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvKTogYm9vbGVhbiB7XHJcbiAgICByZXR1cm4ga2VybmVsSW5mby5pc1Byb3h5O1xyXG59XHJcblxyXG5leHBvcnQgZnVuY3Rpb24gdXBkYXRlS2VybmVsSW5mbyhkZXN0aW5hdGlvbjogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mbywgc291cmNlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvKSB7XHJcbiAgICBkZXN0aW5hdGlvbi5sYW5ndWFnZU5hbWUgPSBzb3VyY2UubGFuZ3VhZ2VOYW1lID8/IGRlc3RpbmF0aW9uLmxhbmd1YWdlTmFtZTtcclxuICAgIGRlc3RpbmF0aW9uLmxhbmd1YWdlVmVyc2lvbiA9IHNvdXJjZS5sYW5ndWFnZVZlcnNpb24gPz8gZGVzdGluYXRpb24ubGFuZ3VhZ2VWZXJzaW9uO1xyXG4gICAgZGVzdGluYXRpb24uZGlzcGxheU5hbWUgPSBzb3VyY2UuZGlzcGxheU5hbWU7XHJcbiAgICBkZXN0aW5hdGlvbi5pc0NvbXBvc2l0ZSA9IHNvdXJjZS5pc0NvbXBvc2l0ZTtcclxuXHJcbiAgICBpZiAoZGVzdGluYXRpb24uZGVzY3JpcHRpb24gPT09IHVuZGVmaW5lZCB8fCBkZXN0aW5hdGlvbi5kZXNjcmlwdGlvbiA9PT0gbnVsbCB8fCBkZXN0aW5hdGlvbi5kZXNjcmlwdGlvbi5tYXRjaCgvXlxccyokLykpIHtcclxuICAgICAgICBkZXN0aW5hdGlvbi5kZXNjcmlwdGlvbiA9IHNvdXJjZS5kZXNjcmlwdGlvbjtcclxuICAgIH1cclxuXHJcbiAgICBpZiAoc291cmNlLmRpc3BsYXlOYW1lKSB7XHJcbiAgICAgICAgZGVzdGluYXRpb24uZGlzcGxheU5hbWUgPSBzb3VyY2UuZGlzcGxheU5hbWU7XHJcbiAgICB9XHJcblxyXG4gICAgY29uc3Qgc3VwcG9ydGVkQ29tbWFuZHMgPSBuZXcgU2V0PHN0cmluZz4oKTtcclxuXHJcbiAgICBpZiAoIWRlc3RpbmF0aW9uLnN1cHBvcnRlZEtlcm5lbENvbW1hbmRzKSB7XHJcbiAgICAgICAgZGVzdGluYXRpb24uc3VwcG9ydGVkS2VybmVsQ29tbWFuZHMgPSBbXTtcclxuICAgIH1cclxuXHJcbiAgICBmb3IgKGNvbnN0IHN1cHBvcnRlZENvbW1hbmQgb2YgZGVzdGluYXRpb24uc3VwcG9ydGVkS2VybmVsQ29tbWFuZHMpIHtcclxuICAgICAgICBzdXBwb3J0ZWRDb21tYW5kcy5hZGQoc3VwcG9ydGVkQ29tbWFuZC5uYW1lKTtcclxuICAgIH1cclxuXHJcbiAgICBmb3IgKGNvbnN0IHN1cHBvcnRlZENvbW1hbmQgb2Ygc291cmNlLnN1cHBvcnRlZEtlcm5lbENvbW1hbmRzKSB7XHJcbiAgICAgICAgaWYgKCFzdXBwb3J0ZWRDb21tYW5kcy5oYXMoc3VwcG9ydGVkQ29tbWFuZC5uYW1lKSkge1xyXG4gICAgICAgICAgICBzdXBwb3J0ZWRDb21tYW5kcy5hZGQoc3VwcG9ydGVkQ29tbWFuZC5uYW1lKTtcclxuICAgICAgICAgICAgZGVzdGluYXRpb24uc3VwcG9ydGVkS2VybmVsQ29tbWFuZHMucHVzaChzdXBwb3J0ZWRDb21tYW5kKTtcclxuICAgICAgICB9XHJcbiAgICB9XHJcbn1cclxuXHJcbmV4cG9ydCBjbGFzcyBDb25uZWN0b3IgaW1wbGVtZW50cyBEaXNwb3NhYmxlIHtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX2xpc3RlbmVyOiByeGpzLlVuc3Vic2NyaWJhYmxlO1xyXG4gICAgcHJpdmF0ZSByZWFkb25seSBfcmVjZWl2ZXI6IElLZXJuZWxDb21tYW5kQW5kRXZlbnRSZWNlaXZlcjtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX3NlbmRlcjogSUtlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlcjtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX3JlbW90ZVVyaXM6IFNldDxzdHJpbmc+ID0gbmV3IFNldDxzdHJpbmc+KCk7XHJcblxyXG4gICAgcHVibGljIGdldCByZW1vdGVIb3N0VXJpcygpOiBzdHJpbmdbXSB7XHJcbiAgICAgICAgcmV0dXJuIEFycmF5LmZyb20odGhpcy5fcmVtb3RlVXJpcy52YWx1ZXMoKSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGdldCBzZW5kZXIoKTogSUtlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlciB7XHJcbiAgICAgICAgcmV0dXJuIHRoaXMuX3NlbmRlcjtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0IHJlY2VpdmVyKCk6IElLZXJuZWxDb21tYW5kQW5kRXZlbnRSZWNlaXZlciB7XHJcbiAgICAgICAgcmV0dXJuIHRoaXMuX3JlY2VpdmVyO1xyXG4gICAgfVxyXG5cclxuICAgIGNvbnN0cnVjdG9yKGNvbmZpZ3VyYXRpb246IHsgcmVjZWl2ZXI6IElLZXJuZWxDb21tYW5kQW5kRXZlbnRSZWNlaXZlciwgc2VuZGVyOiBJS2VybmVsQ29tbWFuZEFuZEV2ZW50U2VuZGVyLCByZW1vdGVVcmlzPzogc3RyaW5nW10gfSkge1xyXG4gICAgICAgIHRoaXMuX3JlY2VpdmVyID0gY29uZmlndXJhdGlvbi5yZWNlaXZlcjtcclxuICAgICAgICB0aGlzLl9zZW5kZXIgPSBjb25maWd1cmF0aW9uLnNlbmRlcjtcclxuICAgICAgICBpZiAoY29uZmlndXJhdGlvbi5yZW1vdGVVcmlzKSB7XHJcbiAgICAgICAgICAgIGZvciAoY29uc3QgcmVtb3RlVXJpIG9mIGNvbmZpZ3VyYXRpb24ucmVtb3RlVXJpcykge1xyXG4gICAgICAgICAgICAgICAgY29uc3QgdXJpID0gZXh0cmFjdEhvc3RBbmROb21hbGl6ZShyZW1vdGVVcmkpO1xyXG4gICAgICAgICAgICAgICAgaWYgKHVyaSkge1xyXG4gICAgICAgICAgICAgICAgICAgIHRoaXMuX3JlbW90ZVVyaXMuYWRkKHVyaSk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIHRoaXMuX2xpc3RlbmVyID0gdGhpcy5fcmVjZWl2ZXIuc3Vic2NyaWJlKHtcclxuICAgICAgICAgICAgbmV4dDogKGtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU6IEtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUpID0+IHtcclxuICAgICAgICAgICAgICAgIGlmIChpc0tlcm5lbEV2ZW50RW52ZWxvcGUoa2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZSkpIHtcclxuICAgICAgICAgICAgICAgICAgICBpZiAoa2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZS5ldmVudFR5cGUgPT09IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZFR5cGUpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgZXZlbnQgPSA8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkPmtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUuZXZlbnQ7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGlmICghZXZlbnQua2VybmVsSW5mby5yZW1vdGVVcmkpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IHVyaSA9IGV4dHJhY3RIb3N0QW5kTm9tYWxpemUoZXZlbnQua2VybmVsSW5mby51cmkhKTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmICh1cmkpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aGlzLl9yZW1vdGVVcmlzLmFkZCh1cmkpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgIGNvbnN0IGV2ZW50Um91dGluZ1NsaXAgPSBrZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlLnJvdXRpbmdTbGlwLnRvQXJyYXkoKTtcclxuICAgICAgICAgICAgICAgICAgICBpZiAoKGV2ZW50Um91dGluZ1NsaXAubGVuZ3RoID8/IDApID4gMCkge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBldmVudE9yaWdpbiA9IGV2ZW50Um91dGluZ1NsaXAhWzBdO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCB1cmkgPSBleHRyYWN0SG9zdEFuZE5vbWFsaXplKGV2ZW50T3JpZ2luKTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHVyaSkge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5fcmVtb3RlVXJpcy5hZGQodXJpKTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH0pO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBhZGRSZW1vdGVIb3N0VXJpKHJlbW90ZVVyaTogc3RyaW5nKSB7XHJcbiAgICAgICAgY29uc3QgdXJpID0gZXh0cmFjdEhvc3RBbmROb21hbGl6ZShyZW1vdGVVcmkpO1xyXG4gICAgICAgIGlmICh1cmkpIHtcclxuICAgICAgICAgICAgdGhpcy5fcmVtb3RlVXJpcy5hZGQodXJpKTtcclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGNhblJlYWNoKHJlbW90ZVVyaTogc3RyaW5nKTogYm9vbGVhbiB7XHJcbiAgICAgICAgY29uc3QgaG9zdCA9IGV4dHJhY3RIb3N0QW5kTm9tYWxpemUocmVtb3RlVXJpKTsvLz9cclxuICAgICAgICBpZiAoaG9zdCkge1xyXG4gICAgICAgICAgICByZXR1cm4gdGhpcy5fcmVtb3RlVXJpcy5oYXMoaG9zdCk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHJldHVybiBmYWxzZTtcclxuICAgIH1cclxuICAgIGRpc3Bvc2UoKTogdm9pZCB7XHJcbiAgICAgICAgdGhpcy5fbGlzdGVuZXIudW5zdWJzY3JpYmUoKTtcclxuICAgIH1cclxufVxyXG5cclxuZXhwb3J0IGZ1bmN0aW9uIGV4dHJhY3RIb3N0QW5kTm9tYWxpemUoa2VybmVsVXJpOiBzdHJpbmcpOiBzdHJpbmcge1xyXG4gICAgY29uc3QgZmlsdGVyOiBSZWdFeHAgPSAvKD88aG9zdD4uKzpcXC9cXC9bXlxcL10rKShcXC9bXlxcL10pKi9naTtcclxuICAgIGNvbnN0IG1hdGNoID0gZmlsdGVyLmV4ZWMoa2VybmVsVXJpKTsgLy8/XHJcbiAgICBpZiAobWF0Y2g/Lmdyb3Vwcz8uaG9zdCkge1xyXG4gICAgICAgIGNvbnN0IGhvc3QgPSBtYXRjaC5ncm91cHMuaG9zdDtcclxuICAgICAgICByZXR1cm4gaG9zdDsvLz9cclxuICAgIH1cclxuICAgIHJldHVybiBcIlwiO1xyXG59XHJcblxyXG5leHBvcnQgZnVuY3Rpb24gU2VyaWFsaXplPFQ+KHNvdXJjZTogVCk6IHN0cmluZyB7XHJcbiAgICByZXR1cm4gSlNPTi5zdHJpbmdpZnkoc291cmNlLCBmdW5jdGlvbiAoa2V5LCB2YWx1ZSkge1xyXG4gICAgICAgIC8vaGFuZGxpbmcgTmFOLCBJbmZpbml0eSBhbmQgLUluZmluaXR5XHJcbiAgICAgICAgY29uc3QgcHJvY2Vzc2VkID0gU2VyaWFsaXplTnVtYmVyTGl0ZXJhbHModmFsdWUpO1xyXG4gICAgICAgIHJldHVybiBwcm9jZXNzZWQ7XHJcbiAgICB9KTtcclxufVxyXG5cclxuZXhwb3J0IGZ1bmN0aW9uIFNlcmlhbGl6ZU51bWJlckxpdGVyYWxzKHZhbHVlOiBhbnkpOiBzdHJpbmcge1xyXG4gICAgaWYgKHZhbHVlICE9PSB2YWx1ZSkge1xyXG4gICAgICAgIHJldHVybiBcIk5hTlwiO1xyXG4gICAgfSBlbHNlIGlmICh2YWx1ZSA9PT0gSW5maW5pdHkpIHtcclxuICAgICAgICByZXR1cm4gXCJJbmZpbml0eVwiO1xyXG4gICAgfSBlbHNlIGlmICh2YWx1ZSA9PT0gLUluZmluaXR5KSB7XHJcbiAgICAgICAgcmV0dXJuIFwiLUluZmluaXR5XCI7XHJcbiAgICB9XHJcbiAgICByZXR1cm4gdmFsdWU7XHJcbn1cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBEZXNlcmlhbGl6ZShqc29uOiBzdHJpbmcpOiBhbnkge1xyXG4gICAgcmV0dXJuIEpTT04ucGFyc2UoanNvbiwgZnVuY3Rpb24gKGtleSwgdmFsdWUpIHtcclxuICAgICAgICAvL2hhbmRsaW5nIE5hTiwgSW5maW5pdHkgYW5kIC1JbmZpbml0eVxyXG4gICAgICAgIGNvbnN0IGRlc2VyaWFsaXplZCA9IERlc2VyaWFsaXplTnVtYmVyTGl0ZXJhbHModmFsdWUpO1xyXG4gICAgICAgIHJldHVybiBkZXNlcmlhbGl6ZWQ7XHJcbiAgICB9KTtcclxufVxyXG5cclxuXHJcbmV4cG9ydCBmdW5jdGlvbiBEZXNlcmlhbGl6ZU51bWJlckxpdGVyYWxzKHZhbHVlOiBhbnkpOiBhbnkge1xyXG4gICAgaWYgKHZhbHVlID09PSBcIk5hTlwiKSB7XHJcbiAgICAgICAgcmV0dXJuIE5hTjtcclxuICAgIH0gZWxzZSBpZiAodmFsdWUgPT09IFwiSW5maW5pdHlcIikge1xyXG4gICAgICAgIHJldHVybiBJbmZpbml0eTtcclxuICAgIH0gZWxzZSBpZiAodmFsdWUgPT09IFwiLUluZmluaXR5XCIpIHtcclxuICAgICAgICByZXR1cm4gLUluZmluaXR5O1xyXG4gICAgfVxyXG4gICAgcmV0dXJuIHZhbHVlO1xyXG59XHJcbiIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG5pbXBvcnQgKiBhcyB1dGlsIGZyb20gXCJ1dGlsXCI7XHJcbmltcG9ydCAqIGFzIGNvbm5lY3Rpb24gZnJvbSBcIi4vY29ubmVjdGlvblwiO1xyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tIFwiLi9jb21tYW5kc0FuZEV2ZW50c1wiO1xyXG5pbXBvcnQgeyBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dCB9IGZyb20gXCIuL2tlcm5lbEludm9jYXRpb25Db250ZXh0XCI7XHJcbmltcG9ydCAqIGFzIGRpc3Bvc2FibGVzIGZyb20gXCIuL2Rpc3Bvc2FibGVzXCI7XHJcblxyXG5leHBvcnQgY2xhc3MgQ29uc29sZUNhcHR1cmUgaW1wbGVtZW50cyBkaXNwb3NhYmxlcy5EaXNwb3NhYmxlIHtcclxuICAgIHByaXZhdGUgb3JpZ2luYWxDb25zb2xlOiBDb25zb2xlO1xyXG4gICAgcHJpdmF0ZSBfa2VybmVsSW52b2NhdGlvbkNvbnRleHQ6IEtlcm5lbEludm9jYXRpb25Db250ZXh0IHwgdW5kZWZpbmVkO1xyXG5cclxuICAgIGNvbnN0cnVjdG9yKCkge1xyXG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlID0gY29uc29sZTtcclxuICAgICAgICBjb25zb2xlID0gPENvbnNvbGU+PGFueT50aGlzO1xyXG4gICAgfVxyXG5cclxuICAgIHNldCBrZXJuZWxJbnZvY2F0aW9uQ29udGV4dCh2YWx1ZTogS2VybmVsSW52b2NhdGlvbkNvbnRleHQgfCB1bmRlZmluZWQpIHtcclxuICAgICAgICB0aGlzLl9rZXJuZWxJbnZvY2F0aW9uQ29udGV4dCA9IHZhbHVlO1xyXG4gICAgfVxyXG5cclxuICAgIGFzc2VydCh2YWx1ZTogYW55LCBtZXNzYWdlPzogc3RyaW5nLCAuLi5vcHRpb25hbFBhcmFtczogYW55W10pOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS5hc3NlcnQodmFsdWUsIG1lc3NhZ2UsIG9wdGlvbmFsUGFyYW1zKTtcclxuICAgIH1cclxuICAgIGNsZWFyKCk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlLmNsZWFyKCk7XHJcbiAgICB9XHJcbiAgICBjb3VudChsYWJlbD86IGFueSk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlLmNvdW50KGxhYmVsKTtcclxuICAgIH1cclxuICAgIGNvdW50UmVzZXQobGFiZWw/OiBzdHJpbmcpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS5jb3VudFJlc2V0KGxhYmVsKTtcclxuICAgIH1cclxuICAgIGRlYnVnKG1lc3NhZ2U/OiBhbnksIC4uLm9wdGlvbmFsUGFyYW1zOiBhbnlbXSk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlLmRlYnVnKG1lc3NhZ2UsIG9wdGlvbmFsUGFyYW1zKTtcclxuICAgIH1cclxuICAgIGRpcihvYmo6IGFueSwgb3B0aW9ucz86IHV0aWwuSW5zcGVjdE9wdGlvbnMpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS5kaXIob2JqLCBvcHRpb25zKTtcclxuICAgIH1cclxuICAgIGRpcnhtbCguLi5kYXRhOiBhbnlbXSk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlLmRpcnhtbChkYXRhKTtcclxuICAgIH1cclxuICAgIGVycm9yKG1lc3NhZ2U/OiBhbnksIC4uLm9wdGlvbmFsUGFyYW1zOiBhbnlbXSk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMucmVkaXJlY3RBbmRQdWJsaXNoKHRoaXMub3JpZ2luYWxDb25zb2xlLmVycm9yLCAuLi5bbWVzc2FnZSwgLi4ub3B0aW9uYWxQYXJhbXNdKTtcclxuICAgIH1cclxuXHJcbiAgICBncm91cCguLi5sYWJlbDogYW55W10pOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS5ncm91cChsYWJlbCk7XHJcbiAgICB9XHJcbiAgICBncm91cENvbGxhcHNlZCguLi5sYWJlbDogYW55W10pOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS5ncm91cENvbGxhcHNlZChsYWJlbCk7XHJcbiAgICB9XHJcbiAgICBncm91cEVuZCgpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS5ncm91cEVuZCgpO1xyXG4gICAgfVxyXG4gICAgaW5mbyhtZXNzYWdlPzogYW55LCAuLi5vcHRpb25hbFBhcmFtczogYW55W10pOiB2b2lkIHtcclxuICAgICAgICB0aGlzLnJlZGlyZWN0QW5kUHVibGlzaCh0aGlzLm9yaWdpbmFsQ29uc29sZS5pbmZvLCAuLi5bbWVzc2FnZSwgLi4ub3B0aW9uYWxQYXJhbXNdKTtcclxuICAgIH1cclxuICAgIGxvZyhtZXNzYWdlPzogYW55LCAuLi5vcHRpb25hbFBhcmFtczogYW55W10pOiB2b2lkIHtcclxuICAgICAgICB0aGlzLnJlZGlyZWN0QW5kUHVibGlzaCh0aGlzLm9yaWdpbmFsQ29uc29sZS5sb2csIC4uLlttZXNzYWdlLCAuLi5vcHRpb25hbFBhcmFtc10pO1xyXG4gICAgfVxyXG5cclxuICAgIHRhYmxlKHRhYnVsYXJEYXRhOiBhbnksIHByb3BlcnRpZXM/OiBzdHJpbmdbXSk6IHZvaWQge1xyXG4gICAgICAgIHRoaXMub3JpZ2luYWxDb25zb2xlLnRhYmxlKHRhYnVsYXJEYXRhLCBwcm9wZXJ0aWVzKTtcclxuICAgIH1cclxuICAgIHRpbWUobGFiZWw/OiBzdHJpbmcpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS50aW1lKGxhYmVsKTtcclxuICAgIH1cclxuICAgIHRpbWVFbmQobGFiZWw/OiBzdHJpbmcpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS50aW1lRW5kKGxhYmVsKTtcclxuICAgIH1cclxuICAgIHRpbWVMb2cobGFiZWw/OiBzdHJpbmcsIC4uLmRhdGE6IGFueVtdKTogdm9pZCB7XHJcbiAgICAgICAgdGhpcy5vcmlnaW5hbENvbnNvbGUudGltZUxvZyhsYWJlbCwgZGF0YSk7XHJcbiAgICB9XHJcbiAgICB0aW1lU3RhbXAobGFiZWw/OiBzdHJpbmcpOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS50aW1lU3RhbXAobGFiZWwpO1xyXG4gICAgfVxyXG4gICAgdHJhY2UobWVzc2FnZT86IGFueSwgLi4ub3B0aW9uYWxQYXJhbXM6IGFueVtdKTogdm9pZCB7XHJcbiAgICAgICAgdGhpcy5yZWRpcmVjdEFuZFB1Ymxpc2godGhpcy5vcmlnaW5hbENvbnNvbGUudHJhY2UsIC4uLlttZXNzYWdlLCAuLi5vcHRpb25hbFBhcmFtc10pO1xyXG4gICAgfVxyXG4gICAgd2FybihtZXNzYWdlPzogYW55LCAuLi5vcHRpb25hbFBhcmFtczogYW55W10pOiB2b2lkIHtcclxuICAgICAgICB0aGlzLm9yaWdpbmFsQ29uc29sZS53YXJuKG1lc3NhZ2UsIG9wdGlvbmFsUGFyYW1zKTtcclxuICAgIH1cclxuXHJcbiAgICBwcm9maWxlKGxhYmVsPzogc3RyaW5nKTogdm9pZCB7XHJcbiAgICAgICAgdGhpcy5vcmlnaW5hbENvbnNvbGUucHJvZmlsZShsYWJlbCk7XHJcbiAgICB9XHJcbiAgICBwcm9maWxlRW5kKGxhYmVsPzogc3RyaW5nKTogdm9pZCB7XHJcbiAgICAgICAgdGhpcy5vcmlnaW5hbENvbnNvbGUucHJvZmlsZUVuZChsYWJlbCk7XHJcbiAgICB9XHJcblxyXG4gICAgZGlzcG9zZSgpOiB2b2lkIHtcclxuICAgICAgICBjb25zb2xlID0gdGhpcy5vcmlnaW5hbENvbnNvbGU7XHJcbiAgICB9XHJcblxyXG4gICAgcHJpdmF0ZSByZWRpcmVjdEFuZFB1Ymxpc2godGFyZ2V0OiAoLi4uYXJnczogYW55W10pID0+IHZvaWQsIC4uLmFyZ3M6IGFueVtdKSB7XHJcbiAgICAgICAgaWYgKHRoaXMuX2tlcm5lbEludm9jYXRpb25Db250ZXh0KSB7XHJcbiAgICAgICAgICAgIGZvciAoY29uc3QgYXJnIG9mIGFyZ3MpIHtcclxuICAgICAgICAgICAgICAgIGxldCBtaW1lVHlwZTogc3RyaW5nO1xyXG4gICAgICAgICAgICAgICAgbGV0IHZhbHVlOiBzdHJpbmc7XHJcbiAgICAgICAgICAgICAgICBpZiAodHlwZW9mIGFyZyAhPT0gJ29iamVjdCcgJiYgIUFycmF5LmlzQXJyYXkoYXJnKSkge1xyXG4gICAgICAgICAgICAgICAgICAgIG1pbWVUeXBlID0gJ3RleHQvcGxhaW4nO1xyXG4gICAgICAgICAgICAgICAgICAgIHZhbHVlID0gYXJnPy50b1N0cmluZygpO1xyXG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgICAgICBtaW1lVHlwZSA9ICdhcHBsaWNhdGlvbi9qc29uJztcclxuICAgICAgICAgICAgICAgICAgICB2YWx1ZSA9IGNvbm5lY3Rpb24uU2VyaWFsaXplKGFyZyk7XHJcbiAgICAgICAgICAgICAgICB9XHJcblxyXG4gICAgICAgICAgICAgICAgY29uc3QgZGlzcGxheWVkVmFsdWU6IGNvbW1hbmRzQW5kRXZlbnRzLkRpc3BsYXllZFZhbHVlUHJvZHVjZWQgPSB7XHJcbiAgICAgICAgICAgICAgICAgICAgZm9ybWF0dGVkVmFsdWVzOiBbXHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIG1pbWVUeXBlLFxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdmFsdWUsXHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdXBwcmVzc0Rpc3BsYXk6IGZhbHNlXHJcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICBdXHJcbiAgICAgICAgICAgICAgICB9O1xyXG4gICAgICAgICAgICAgICAgY29uc3QgZXZlbnRFbnZlbG9wZSA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKFxyXG4gICAgICAgICAgICAgICAgICAgIGNvbW1hbmRzQW5kRXZlbnRzLkRpc3BsYXllZFZhbHVlUHJvZHVjZWRUeXBlLFxyXG4gICAgICAgICAgICAgICAgICAgIGRpc3BsYXllZFZhbHVlLFxyXG4gICAgICAgICAgICAgICAgICAgIHRoaXMuX2tlcm5lbEludm9jYXRpb25Db250ZXh0LmNvbW1hbmRFbnZlbG9wZVxyXG4gICAgICAgICAgICAgICAgKTtcclxuXHJcbiAgICAgICAgICAgICAgICB0aGlzLl9rZXJuZWxJbnZvY2F0aW9uQ29udGV4dC5wdWJsaXNoKGV2ZW50RW52ZWxvcGUpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGlmICh0YXJnZXQpIHtcclxuICAgICAgICAgICAgdGFyZ2V0KC4uLmFyZ3MpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxufSIsIi8vIENvcHlyaWdodCAoYykgLk5FVCBGb3VuZGF0aW9uIGFuZCBjb250cmlidXRvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuXHJcbi8vIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZS4gU2VlIExJQ0VOU0UgZmlsZSBpbiB0aGUgcHJvamVjdCByb290IGZvciBmdWxsIGxpY2Vuc2UgaW5mb3JtYXRpb24uXHJcblxyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tIFwiLi9jb21tYW5kc0FuZEV2ZW50c1wiO1xyXG5pbXBvcnQgeyBMb2dnZXIgfSBmcm9tIFwiLi9sb2dnZXJcIjtcclxuaW1wb3J0IHsgS2VybmVsLCBJS2VybmVsQ29tbWFuZEhhbmRsZXIsIElLZXJuZWxDb21tYW5kSW52b2NhdGlvbiwgZ2V0S2VybmVsVXJpIH0gZnJvbSBcIi4va2VybmVsXCI7XHJcbmltcG9ydCAqIGFzIGNvbm5lY3Rpb24gZnJvbSBcIi4vY29ubmVjdGlvblwiO1xyXG5pbXBvcnQgKiBhcyByb3V0aW5nU2xpcCBmcm9tIFwiLi9yb3V0aW5nc2xpcFwiO1xyXG5pbXBvcnQgeyBQcm9taXNlQ29tcGxldGlvblNvdXJjZSB9IGZyb20gXCIuL3Byb21pc2VDb21wbGV0aW9uU291cmNlXCI7XHJcbmltcG9ydCB7IEtlcm5lbEludm9jYXRpb25Db250ZXh0IH0gZnJvbSBcIi4va2VybmVsSW52b2NhdGlvbkNvbnRleHRcIjtcclxuXHJcbmV4cG9ydCBjbGFzcyBQcm94eUtlcm5lbCBleHRlbmRzIEtlcm5lbCB7XHJcblxyXG4gICAgY29uc3RydWN0b3Iob3ZlcnJpZGUgcmVhZG9ubHkgbmFtZTogc3RyaW5nLCBwcml2YXRlIHJlYWRvbmx5IF9zZW5kZXI6IGNvbm5lY3Rpb24uSUtlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlciwgcHJpdmF0ZSByZWFkb25seSBfcmVjZWl2ZXI6IGNvbm5lY3Rpb24uSUtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyLCBsYW5ndWFnZU5hbWU/OiBzdHJpbmcsIGxhbmd1YWdlVmVyc2lvbj86IHN0cmluZykge1xyXG4gICAgICAgIHN1cGVyKG5hbWUsIGxhbmd1YWdlTmFtZSwgbGFuZ3VhZ2VWZXJzaW9uKTtcclxuICAgICAgICB0aGlzLmtlcm5lbEluZm8uaXNQcm94eSA9IHRydWU7XHJcbiAgICB9XHJcblxyXG4gICAgb3ZlcnJpZGUgZ2V0Q29tbWFuZEhhbmRsZXIoY29tbWFuZFR5cGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRUeXBlKTogSUtlcm5lbENvbW1hbmRIYW5kbGVyIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICByZXR1cm4ge1xyXG4gICAgICAgICAgICBjb21tYW5kVHlwZSxcclxuICAgICAgICAgICAgaGFuZGxlOiAoaW52b2NhdGlvbikgPT4ge1xyXG4gICAgICAgICAgICAgICAgcmV0dXJuIHRoaXMuX2NvbW1hbmRIYW5kbGVyKGludm9jYXRpb24pO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfTtcclxuICAgIH1cclxuXHJcbiAgICBwcml2YXRlIGRlbGVnYXRlUHVibGljYXRpb24oZW52ZWxvcGU6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUsIGludm9jYXRpb25Db250ZXh0OiBLZXJuZWxJbnZvY2F0aW9uQ29udGV4dCk6IHZvaWQge1xyXG4gICAgICAgIGxldCBhbHJlYWR5QmVlblNlZW4gPSBmYWxzZTtcclxuICAgICAgICBjb25zdCBrZXJuZWxVcmkgPSBnZXRLZXJuZWxVcmkodGhpcyk7XHJcbiAgICAgICAgaWYgKGtlcm5lbFVyaSAmJiAhZW52ZWxvcGUucm91dGluZ1NsaXAuY29udGFpbnMoa2VybmVsVXJpKSkge1xyXG4gICAgICAgICAgICBlbnZlbG9wZS5yb3V0aW5nU2xpcC5zdGFtcChrZXJuZWxVcmkpO1xyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIGFscmVhZHlCZWVuU2VlbiA9IHRydWU7XHJcbiAgICAgICAgfVxyXG5cclxuICAgICAgICBpZiAodGhpcy5oYXNTYW1lT3JpZ2luKGVudmVsb3BlKSkge1xyXG4gICAgICAgICAgICBpZiAoIWFscmVhZHlCZWVuU2Vlbikge1xyXG4gICAgICAgICAgICAgICAgaW52b2NhdGlvbkNvbnRleHQucHVibGlzaChlbnZlbG9wZSk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgcHJpdmF0ZSBoYXNTYW1lT3JpZ2luKGVudmVsb3BlOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKTogYm9vbGVhbiB7XHJcbiAgICAgICAgbGV0IGNvbW1hbmRPcmlnaW5VcmkgPSBlbnZlbG9wZS5jb21tYW5kPy5jb21tYW5kPy5vcmlnaW5VcmkgPz8gdGhpcy5rZXJuZWxJbmZvLnVyaTtcclxuICAgICAgICBpZiAoY29tbWFuZE9yaWdpblVyaSA9PT0gdGhpcy5rZXJuZWxJbmZvLnVyaSkge1xyXG4gICAgICAgICAgICByZXR1cm4gdHJ1ZTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIHJldHVybiBjb21tYW5kT3JpZ2luVXJpID09PSBudWxsO1xyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgdXBkYXRlS2VybmVsSW5mb0Zyb21FdmVudChrZXJuZWxJbmZvUHJvZHVjZWQ6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZCkge1xyXG4gICAgICAgIGNvbm5lY3Rpb24udXBkYXRlS2VybmVsSW5mbyh0aGlzLmtlcm5lbEluZm8sIGtlcm5lbEluZm9Qcm9kdWNlZC5rZXJuZWxJbmZvKTtcclxuICAgIH1cclxuXHJcbiAgICBwcml2YXRlIGFzeW5jIF9jb21tYW5kSGFuZGxlcihjb21tYW5kSW52b2NhdGlvbjogSUtlcm5lbENvbW1hbmRJbnZvY2F0aW9uKTogUHJvbWlzZTx2b2lkPiB7XHJcbiAgICAgICAgY29uc3QgY29tbWFuZFRva2VuID0gY29tbWFuZEludm9jYXRpb24uY29tbWFuZEVudmVsb3BlLmdldE9yQ3JlYXRlVG9rZW4oKTtcclxuICAgICAgICBjb25zdCBjb21wbGV0aW9uU291cmNlID0gbmV3IFByb21pc2VDb21wbGV0aW9uU291cmNlPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGU+KCk7XHJcblxyXG4gICAgICAgIC8vIGZpeCA6IGlzIHRoaXMgdGhlIHJpZ2h0IHdheT8gV2UgYXJlIHRyeWluZyB0byBhdm9pZCBmb3J3YXJkaW5nIGV2ZW50cyB3ZSBqdXN0IGRpZCBmb3J3YXJkXHJcbiAgICAgICAgbGV0IGV2ZW50U3Vic2NyaXB0aW9uID0gdGhpcy5fcmVjZWl2ZXIuc3Vic2NyaWJlKHtcclxuICAgICAgICAgICAgbmV4dDogKGVudmVsb3BlKSA9PiB7XHJcbiAgICAgICAgICAgICAgICBpZiAoY29ubmVjdGlvbi5pc0tlcm5lbEV2ZW50RW52ZWxvcGUoZW52ZWxvcGUpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgaWYgKGVudmVsb3BlLmV2ZW50VHlwZSA9PT0gY29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkVHlwZSAmJlxyXG4gICAgICAgICAgICAgICAgICAgICAgICAoZW52ZWxvcGUuY29tbWFuZCA9PT0gbnVsbCB8fCBlbnZlbG9wZS5jb21tYW5kID09PSB1bmRlZmluZWQpKSB7XHJcblxyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBrZXJuZWxJbmZvUHJvZHVjZWQgPSA8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkPmVudmVsb3BlLmV2ZW50O1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBrZXJuZWxJbmZvUHJvZHVjZWQua2VybmVsSW5mbzsvLz9cclxuICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5rZXJuZWxJbmZvOy8vP1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoa2VybmVsSW5mb1Byb2R1Y2VkLmtlcm5lbEluZm8udXJpID09PSB0aGlzLmtlcm5lbEluZm8ucmVtb3RlVXJpKSB7XHJcblxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy51cGRhdGVLZXJuZWxJbmZvRnJvbUV2ZW50KGtlcm5lbEluZm9Qcm9kdWNlZCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBldmVudCA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZFR5cGUsIHsga2VybmVsSW5mbzogdGhpcy5rZXJuZWxJbmZvIH0pO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5wdWJsaXNoRXZlbnQoZXZlbnQpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgIGVsc2UgaWYgKGVudmVsb3BlLmNvbW1hbmQhLmdldFRva2VuKCkgPT09IGNvbW1hbmRUb2tlbikge1xyXG5cclxuICAgICAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgcHJveHkgbmFtZT0ke3RoaXMubmFtZX1bbG9jYWwgdXJpOiR7dGhpcy5rZXJuZWxJbmZvLnVyaX0sIHJlbW90ZSB1cmk6JHt0aGlzLmtlcm5lbEluZm8ucmVtb3RlVXJpfV0gcHJvY2Vzc2luZyBldmVudCwgZW52ZWxvcGVUb2tlbj0ke2VudmVsb3BlLmNvbW1hbmQhLmdldFRva2VuKCl9LCBjb21tYW5kVG9rZW49JHtjb21tYW5kVG9rZW59YCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYHByb3h5IG5hbWU9JHt0aGlzLm5hbWV9W2xvY2FsIHVyaToke3RoaXMua2VybmVsSW5mby51cml9LCByZW1vdGUgdXJpOiR7dGhpcy5rZXJuZWxJbmZvLnJlbW90ZVVyaX1dIHByb2Nlc3NpbmcgZXZlbnQsICR7SlNPTi5zdHJpbmdpZnkoZW52ZWxvcGUpfWApO1xyXG5cclxuICAgICAgICAgICAgICAgICAgICAgICAgdHJ5IHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbnN0IG9yaWdpbmFsID0gWy4uLmNvbW1hbmRJbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZT8ucm91dGluZ1NsaXAudG9BcnJheSgpID8/IFtdXTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbW1hbmRJbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZS5yb3V0aW5nU2xpcC5jb250aW51ZVdpdGgoZW52ZWxvcGUuY29tbWFuZCEucm91dGluZ1NsaXApO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgLy9lbnZlbG9wZS5jb21tYW5kIS5yb3V0aW5nU2xpcCA9IFsuLi5jb21tYW5kSW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAgPz8gW11dOy8vP1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgcHJveHkgbmFtZT0ke3RoaXMubmFtZX1bbG9jYWwgdXJpOiR7dGhpcy5rZXJuZWxJbmZvLnVyaX0sIGNvbW1hbmQgcm91dGluZ1NsaXAgOiR7b3JpZ2luYWx9XSBoYXMgY2hhbmdlZCB0bzogJHtKU09OLnN0cmluZ2lmeShjb21tYW5kSW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAgPz8gW10pfWApO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICB9IGNhdGNoIChlOiBhbnkpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmVycm9yKGBwcm94eSBuYW1lPSR7dGhpcy5uYW1lfVtsb2NhbCB1cmk6JHt0aGlzLmtlcm5lbEluZm8udXJpfSwgZXJyb3IgJHtlPy5tZXNzYWdlfWApO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICB9XHJcblxyXG4gICAgICAgICAgICAgICAgICAgICAgICBzd2l0Y2ggKGVudmVsb3BlLmV2ZW50VHlwZSkge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY2FzZSBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvUHJvZHVjZWRUeXBlOlxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3Qga2VybmVsSW5mb1Byb2R1Y2VkID0gPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZD5lbnZlbG9wZS5ldmVudDtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgKGtlcm5lbEluZm9Qcm9kdWNlZC5rZXJuZWxJbmZvLnVyaSA9PT0gdGhpcy5rZXJuZWxJbmZvLnJlbW90ZVVyaSkge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy51cGRhdGVLZXJuZWxJbmZvRnJvbUV2ZW50KGtlcm5lbEluZm9Qcm9kdWNlZCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBldmVudCA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKFxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEluZm9Qcm9kdWNlZFR5cGUsXHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgeyBrZXJuZWxJbmZvOiB0aGlzLmtlcm5lbEluZm8gfSxcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb21tYW5kSW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGVcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICk7XHJcblxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZXZlbnQucm91dGluZ1NsaXAuY29udGludWVXaXRoKGVudmVsb3BlLnJvdXRpbmdTbGlwKTtcclxuXHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aGlzLmRlbGVnYXRlUHVibGljYXRpb24oZXZlbnQsIGNvbW1hbmRJbnZvY2F0aW9uLmNvbnRleHQpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGhpcy5kZWxlZ2F0ZVB1YmxpY2F0aW9uKGVudmVsb3BlLCBjb21tYW5kSW52b2NhdGlvbi5jb250ZXh0KTtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuZGVsZWdhdGVQdWJsaWNhdGlvbihlbnZlbG9wZSwgY29tbWFuZEludm9jYXRpb24uY29udGV4dCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYXNlIGNvbW1hbmRzQW5kRXZlbnRzLkNvbW1hbmRGYWlsZWRUeXBlOlxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY2FzZSBjb21tYW5kc0FuZEV2ZW50cy5Db21tYW5kU3VjY2VlZGVkVHlwZTpcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC5pbmZvKGBwcm94eSBuYW1lPSR7dGhpcy5uYW1lfVtsb2NhbCB1cmk6JHt0aGlzLmtlcm5lbEluZm8udXJpfSwgcmVtb3RlIHVyaToke3RoaXMua2VybmVsSW5mby5yZW1vdGVVcml9XSBmaW5pc2hlZCwgdG9rZW49JHtlbnZlbG9wZS5jb21tYW5kIS5nZXRUb2tlbigpfSwgY29tbWFuZFRva2VuPSR7Y29tbWFuZFRva2VufWApO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlmIChlbnZlbG9wZS5jb21tYW5kIS5nZXRUb2tlbigpID09PSBjb21tYW5kVG9rZW4pIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgcHJveHkgbmFtZT0ke3RoaXMubmFtZX1bbG9jYWwgdXJpOiR7dGhpcy5rZXJuZWxJbmZvLnVyaX0sIHJlbW90ZSB1cmk6JHt0aGlzLmtlcm5lbEluZm8ucmVtb3RlVXJpfV0gcmVzb2x2aW5nIHByb21pc2UsIGVudmVsb3BlVG9rZW49JHtlbnZlbG9wZS5jb21tYW5kIS5nZXRUb2tlbigpfSwgY29tbWFuZFRva2VuPSR7Y29tbWFuZFRva2VufWApO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb21wbGV0aW9uU291cmNlLnJlc29sdmUoZW52ZWxvcGUpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYHByb3h5IG5hbWU9JHt0aGlzLm5hbWV9W2xvY2FsIHVyaToke3RoaXMua2VybmVsSW5mby51cml9LCByZW1vdGUgdXJpOiR7dGhpcy5rZXJuZWxJbmZvLnJlbW90ZVVyaX1dIG5vdCByZXNvbHZpbmcgcHJvbWlzZSwgZW52ZWxvcGVUb2tlbj0ke2VudmVsb3BlLmNvbW1hbmQhLmdldFRva2VuKCl9LCBjb21tYW5kVG9rZW49JHtjb21tYW5kVG9rZW59YCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRoaXMuZGVsZWdhdGVQdWJsaWNhdGlvbihlbnZlbG9wZSwgY29tbWFuZEludm9jYXRpb24uY29udGV4dCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJyZWFrO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVmYXVsdDpcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aGlzLmRlbGVnYXRlUHVibGljYXRpb24oZW52ZWxvcGUsIGNvbW1hbmRJbnZvY2F0aW9uLmNvbnRleHQpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJyZWFrO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfSk7XHJcblxyXG4gICAgICAgIHRyeSB7XHJcbiAgICAgICAgICAgIGlmICghY29tbWFuZEludm9jYXRpb24uY29tbWFuZEVudmVsb3BlLmNvbW1hbmQuZGVzdGluYXRpb25VcmkgfHwgIWNvbW1hbmRJbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZS5jb21tYW5kLm9yaWdpblVyaSkge1xyXG4gICAgICAgICAgICAgICAgY29tbWFuZEludm9jYXRpb24uY29tbWFuZEVudmVsb3BlLmNvbW1hbmQub3JpZ2luVXJpID8/PSB0aGlzLmtlcm5lbEluZm8udXJpO1xyXG4gICAgICAgICAgICAgICAgY29tbWFuZEludm9jYXRpb24uY29tbWFuZEVudmVsb3BlLmNvbW1hbmQuZGVzdGluYXRpb25VcmkgPz89IHRoaXMua2VybmVsSW5mby5yZW1vdGVVcmk7XHJcbiAgICAgICAgICAgIH1cclxuXHJcbiAgICAgICAgICAgIGNvbW1hbmRJbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZS5yb3V0aW5nU2xpcDsvLz9cclxuXHJcbiAgICAgICAgICAgIGlmIChjb21tYW5kSW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGUgPT09IGNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3RLZXJuZWxJbmZvVHlwZSkge1xyXG4gICAgICAgICAgICAgICAgY29uc3QgZGVzdGluYXRpb25VcmkgPSB0aGlzLmtlcm5lbEluZm8ucmVtb3RlVXJpITtcclxuICAgICAgICAgICAgICAgIGlmIChjb21tYW5kSW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXAuY29udGFpbnMoZGVzdGluYXRpb25VcmksIHRydWUpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIFByb21pc2UucmVzb2x2ZSgpO1xyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYHByb3h5ICR7dGhpcy5uYW1lfVtsb2NhbCB1cmk6JHt0aGlzLmtlcm5lbEluZm8udXJpfSwgcmVtb3RlIHVyaToke3RoaXMua2VybmVsSW5mby5yZW1vdGVVcml9XSBmb3J3YXJkaW5nIGNvbW1hbmQgJHtjb21tYW5kSW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUuY29tbWFuZFR5cGV9IHRvICR7Y29tbWFuZEludm9jYXRpb24uY29tbWFuZEVudmVsb3BlLmNvbW1hbmQuZGVzdGluYXRpb25Vcml9YCk7XHJcbiAgICAgICAgICAgIHRoaXMuX3NlbmRlci5zZW5kKGNvbW1hbmRJbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZSk7XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYHByb3h5ICR7dGhpcy5uYW1lfVtsb2NhbCB1cmk6JHt0aGlzLmtlcm5lbEluZm8udXJpfSwgcmVtb3RlIHVyaToke3RoaXMua2VybmVsSW5mby5yZW1vdGVVcml9XSBhYm91dCB0byBhd2FpdCB3aXRoIHRva2VuICR7Y29tbWFuZFRva2VufWApO1xyXG4gICAgICAgICAgICBjb25zdCBlbnZlbnRFbnZlbG9wZSA9IGF3YWl0IGNvbXBsZXRpb25Tb3VyY2UucHJvbWlzZTtcclxuICAgICAgICAgICAgaWYgKGVudmVudEVudmVsb3BlLmV2ZW50VHlwZSA9PT0gY29tbWFuZHNBbmRFdmVudHMuQ29tbWFuZEZhaWxlZFR5cGUpIHtcclxuICAgICAgICAgICAgICAgIGNvbW1hbmRJbnZvY2F0aW9uLmNvbnRleHQuZmFpbCgoPGNvbW1hbmRzQW5kRXZlbnRzLkNvbW1hbmRGYWlsZWQ+ZW52ZW50RW52ZWxvcGUuZXZlbnQpLm1lc3NhZ2UpO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYHByb3h5ICR7dGhpcy5uYW1lfVtsb2NhbCB1cmk6JHt0aGlzLmtlcm5lbEluZm8udXJpfSwgcmVtb3RlIHVyaToke3RoaXMua2VybmVsSW5mby5yZW1vdGVVcml9XSBkb25lIGF3YWl0aW5nIHdpdGggdG9rZW4gJHtjb21tYW5kVG9rZW59fWApO1xyXG4gICAgICAgIH1cclxuICAgICAgICBjYXRjaCAoZSkge1xyXG4gICAgICAgICAgICBjb21tYW5kSW52b2NhdGlvbi5jb250ZXh0LmZhaWwoKDxhbnk+ZSkubWVzc2FnZSk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGZpbmFsbHkge1xyXG4gICAgICAgICAgICBldmVudFN1YnNjcmlwdGlvbi51bnN1YnNjcmliZSgpO1xyXG4gICAgICAgIH1cclxuICAgIH1cclxufVxyXG4iLCIvLyBDb3B5cmlnaHQgKGMpIC5ORVQgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzLiBBbGwgcmlnaHRzIHJlc2VydmVkLlxyXG4vLyBMaWNlbnNlZCB1bmRlciB0aGUgTUlUIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIGZpbGUgaW4gdGhlIHByb2plY3Qgcm9vdCBmb3IgZnVsbCBsaWNlbnNlIGluZm9ybWF0aW9uLlxyXG5cclxuaW1wb3J0IHsgQ29tcG9zaXRlS2VybmVsIH0gZnJvbSAnLi9jb21wb3NpdGVLZXJuZWwnO1xyXG5pbXBvcnQgKiBhcyBjb21tYW5kc0FuZEV2ZW50cyBmcm9tICcuL2NvbW1hbmRzQW5kRXZlbnRzJztcclxuaW1wb3J0ICogYXMgY29ubmVjdGlvbiBmcm9tICcuL2Nvbm5lY3Rpb24nO1xyXG5pbXBvcnQgKiBhcyByb3V0aW5nU2xpcCBmcm9tICcuL3JvdXRpbmdzbGlwJztcclxuaW1wb3J0IHsgS2VybmVsIH0gZnJvbSAnLi9rZXJuZWwnO1xyXG5pbXBvcnQgeyBQcm94eUtlcm5lbCB9IGZyb20gJy4vcHJveHlLZXJuZWwnO1xyXG5pbXBvcnQgeyBMb2dnZXIgfSBmcm9tICcuL2xvZ2dlcic7XHJcbmltcG9ydCB7IEtlcm5lbFNjaGVkdWxlciB9IGZyb20gJy4va2VybmVsU2NoZWR1bGVyJztcclxuXHJcbmV4cG9ydCBjbGFzcyBLZXJuZWxIb3N0IHtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX3JlbW90ZVVyaVRvS2VybmVsID0gbmV3IE1hcDxzdHJpbmcsIEtlcm5lbD4oKTtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX3VyaVRvS2VybmVsID0gbmV3IE1hcDxzdHJpbmcsIEtlcm5lbD4oKTtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX2tlcm5lbFRvS2VybmVsSW5mbyA9IG5ldyBNYXA8S2VybmVsLCBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvPigpO1xyXG4gICAgcHJpdmF0ZSByZWFkb25seSBfdXJpOiBzdHJpbmc7XHJcbiAgICBwcml2YXRlIHJlYWRvbmx5IF9zY2hlZHVsZXI6IEtlcm5lbFNjaGVkdWxlcjxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGU+O1xyXG4gICAgcHJpdmF0ZSBfa2VybmVsOiBDb21wb3NpdGVLZXJuZWw7XHJcbiAgICBwcml2YXRlIF9kZWZhdWx0Q29ubmVjdG9yOiBjb25uZWN0aW9uLkNvbm5lY3RvcjtcclxuICAgIHByaXZhdGUgcmVhZG9ubHkgX2Nvbm5lY3RvcnM6IGNvbm5lY3Rpb24uQ29ubmVjdG9yW10gPSBbXTtcclxuXHJcbiAgICBjb25zdHJ1Y3RvcihrZXJuZWw6IENvbXBvc2l0ZUtlcm5lbCwgc2VuZGVyOiBjb25uZWN0aW9uLklLZXJuZWxDb21tYW5kQW5kRXZlbnRTZW5kZXIsIHJlY2VpdmVyOiBjb25uZWN0aW9uLklLZXJuZWxDb21tYW5kQW5kRXZlbnRSZWNlaXZlciwgaG9zdFVyaTogc3RyaW5nKSB7XHJcbiAgICAgICAgdGhpcy5fa2VybmVsID0ga2VybmVsO1xyXG4gICAgICAgIHRoaXMuX3VyaSA9IHJvdXRpbmdTbGlwLmNyZWF0ZUtlcm5lbFVyaShob3N0VXJpIHx8IFwia2VybmVsOi8vdnNjb2RlXCIpO1xyXG5cclxuICAgICAgICB0aGlzLl9rZXJuZWwuaG9zdCA9IHRoaXM7XHJcbiAgICAgICAgdGhpcy5fc2NoZWR1bGVyID0gbmV3IEtlcm5lbFNjaGVkdWxlcjxjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxDb21tYW5kRW52ZWxvcGU+KCk7XHJcblxyXG4gICAgICAgIHRoaXMuX3NjaGVkdWxlci5zZXRNdXN0VHJhbXBvbGluZSgoYyA9PiB7XHJcbiAgICAgICAgICAgIHJldHVybiAoYy5jb21tYW5kVHlwZSA9PT0gY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdElucHV0VHlwZSkgfHwgKGMuY29tbWFuZFR5cGUgPT09IGNvbW1hbmRzQW5kRXZlbnRzLlNlbmRFZGl0YWJsZUNvZGVUeXBlKTtcclxuICAgICAgICB9KSk7XHJcblxyXG4gICAgICAgIHRoaXMuX2RlZmF1bHRDb25uZWN0b3IgPSBuZXcgY29ubmVjdGlvbi5Db25uZWN0b3IoeyBzZW5kZXIsIHJlY2VpdmVyIH0pO1xyXG4gICAgICAgIHRoaXMuX2Nvbm5lY3RvcnMucHVzaCh0aGlzLl9kZWZhdWx0Q29ubmVjdG9yKTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0IGRlZmF1bHRDb25uZWN0b3IoKTogY29ubmVjdGlvbi5Db25uZWN0b3Ige1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9kZWZhdWx0Q29ubmVjdG9yO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBnZXQgdXJpKCk6IHN0cmluZyB7XHJcbiAgICAgICAgcmV0dXJuIHRoaXMuX3VyaTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0IGtlcm5lbCgpOiBDb21wb3NpdGVLZXJuZWwge1xyXG4gICAgICAgIHJldHVybiB0aGlzLl9rZXJuZWw7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHRyeUdldEtlcm5lbEJ5UmVtb3RlVXJpKHJlbW90ZVVyaTogc3RyaW5nKTogS2VybmVsIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fcmVtb3RlVXJpVG9LZXJuZWwuZ2V0KHJlbW90ZVVyaSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHRyeWdldEtlcm5lbEJ5T3JpZ2luVXJpKG9yaWdpblVyaTogc3RyaW5nKTogS2VybmVsIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fdXJpVG9LZXJuZWwuZ2V0KG9yaWdpblVyaSk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHRyeUdldEtlcm5lbEluZm8oa2VybmVsOiBLZXJuZWwpOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvIHwgdW5kZWZpbmVkIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fa2VybmVsVG9LZXJuZWxJbmZvLmdldChrZXJuZWwpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyBhZGRLZXJuZWxJbmZvKGtlcm5lbDogS2VybmVsLCBrZXJuZWxJbmZvOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvKSB7XHJcbiAgICAgICAga2VybmVsSW5mby51cmkgPSByb3V0aW5nU2xpcC5jcmVhdGVLZXJuZWxVcmkoYCR7dGhpcy5fdXJpfSR7a2VybmVsLm5hbWV9YCk7XHJcbiAgICAgICAgdGhpcy5fa2VybmVsVG9LZXJuZWxJbmZvLnNldChrZXJuZWwsIGtlcm5lbEluZm8pO1xyXG4gICAgICAgIHRoaXMuX3VyaVRvS2VybmVsLnNldChrZXJuZWxJbmZvLnVyaSwga2VybmVsKTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0S2VybmVsKGtlcm5lbENvbW1hbmRFbnZlbG9wZTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlKTogS2VybmVsIHtcclxuXHJcbiAgICAgICAgY29uc3QgdXJpVG9Mb29rdXAgPSBrZXJuZWxDb21tYW5kRW52ZWxvcGUuY29tbWFuZC5kZXN0aW5hdGlvblVyaSA/PyBrZXJuZWxDb21tYW5kRW52ZWxvcGUuY29tbWFuZC5vcmlnaW5Vcmk7XHJcbiAgICAgICAgbGV0IGtlcm5lbDogS2VybmVsIHwgdW5kZWZpbmVkID0gdW5kZWZpbmVkO1xyXG4gICAgICAgIGlmICh1cmlUb0xvb2t1cCkge1xyXG4gICAgICAgICAgICBrZXJuZWwgPSB0aGlzLl9rZXJuZWwuZmluZEtlcm5lbEJ5VXJpKHVyaVRvTG9va3VwKTtcclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGlmICgha2VybmVsKSB7XHJcbiAgICAgICAgICAgIGlmIChrZXJuZWxDb21tYW5kRW52ZWxvcGUuY29tbWFuZC50YXJnZXRLZXJuZWxOYW1lKSB7XHJcbiAgICAgICAgICAgICAgICBrZXJuZWwgPSB0aGlzLl9rZXJuZWwuZmluZEtlcm5lbEJ5TmFtZShrZXJuZWxDb21tYW5kRW52ZWxvcGUuY29tbWFuZC50YXJnZXRLZXJuZWxOYW1lKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAga2VybmVsID8/PSB0aGlzLl9rZXJuZWw7XHJcbiAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgVXNpbmcgS2VybmVsICR7a2VybmVsLm5hbWV9YCk7XHJcbiAgICAgICAgcmV0dXJuIGtlcm5lbDtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgY29ubmVjdFByb3h5S2VybmVsT25EZWZhdWx0Q29ubmVjdG9yKGxvY2FsTmFtZTogc3RyaW5nLCByZW1vdGVLZXJuZWxVcmk/OiBzdHJpbmcsIGFsaWFzZXM/OiBzdHJpbmdbXSk6IFByb3h5S2VybmVsIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5jb25uZWN0UHJveHlLZXJuZWxPbkNvbm5lY3Rvcihsb2NhbE5hbWUsIHRoaXMuX2RlZmF1bHRDb25uZWN0b3Iuc2VuZGVyLCB0aGlzLl9kZWZhdWx0Q29ubmVjdG9yLnJlY2VpdmVyLCByZW1vdGVLZXJuZWxVcmksIGFsaWFzZXMpO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyB0cnlBZGRDb25uZWN0b3IoY29ubmVjdG9yOiB7IHNlbmRlcjogY29ubmVjdGlvbi5JS2VybmVsQ29tbWFuZEFuZEV2ZW50U2VuZGVyLCByZWNlaXZlcjogY29ubmVjdGlvbi5JS2VybmVsQ29tbWFuZEFuZEV2ZW50UmVjZWl2ZXIsIHJlbW90ZVVyaXM/OiBzdHJpbmdbXSB9KSB7XHJcbiAgICAgICAgaWYgKCFjb25uZWN0b3IucmVtb3RlVXJpcykge1xyXG4gICAgICAgICAgICB0aGlzLl9jb25uZWN0b3JzLnB1c2gobmV3IGNvbm5lY3Rpb24uQ29ubmVjdG9yKGNvbm5lY3RvcikpO1xyXG4gICAgICAgICAgICByZXR1cm4gdHJ1ZTtcclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICBjb25zdCBmb3VuZCA9IGNvbm5lY3Rvci5yZW1vdGVVcmlzIS5maW5kKHVyaSA9PiB0aGlzLl9jb25uZWN0b3JzLmZpbmQoYyA9PiBjLmNhblJlYWNoKHVyaSkpKTtcclxuICAgICAgICAgICAgaWYgKCFmb3VuZCkge1xyXG4gICAgICAgICAgICAgICAgdGhpcy5fY29ubmVjdG9ycy5wdXNoKG5ldyBjb25uZWN0aW9uLkNvbm5lY3Rvcihjb25uZWN0b3IpKTtcclxuICAgICAgICAgICAgICAgIHJldHVybiB0cnVlO1xyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIHJldHVybiBmYWxzZTtcclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIHRyeVJlbW92ZUNvbm5lY3Rvcihjb25uZWN0b3I6IHsgcmVtb3RlVXJpcz86IHN0cmluZ1tdIH0pIHtcclxuICAgICAgICBpZiAoIWNvbm5lY3Rvci5yZW1vdGVVcmlzKSB7XHJcbiAgICAgICAgICAgIGZvciAobGV0IHVyaSBvZiBjb25uZWN0b3IucmVtb3RlVXJpcyEpIHtcclxuICAgICAgICAgICAgICAgIGNvbnN0IGluZGV4ID0gdGhpcy5fY29ubmVjdG9ycy5maW5kSW5kZXgoYyA9PiBjLmNhblJlYWNoKHVyaSkpO1xyXG4gICAgICAgICAgICAgICAgaWYgKGluZGV4ID49IDApIHtcclxuICAgICAgICAgICAgICAgICAgICB0aGlzLl9jb25uZWN0b3JzLnNwbGljZShpbmRleCwgMSk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgcmV0dXJuIHRydWU7XHJcbiAgICAgICAgfSBlbHNlIHtcclxuXHJcbiAgICAgICAgICAgIHJldHVybiBmYWxzZTtcclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGNvbm5lY3RQcm94eUtlcm5lbChsb2NhbE5hbWU6IHN0cmluZywgcmVtb3RlS2VybmVsVXJpOiBzdHJpbmcsIGFsaWFzZXM/OiBzdHJpbmdbXSk6IFByb3h5S2VybmVsIHtcclxuICAgICAgICB0aGlzLl9jb25uZWN0b3JzOy8vP1xyXG4gICAgICAgIGNvbnN0IGNvbm5lY3RvciA9IHRoaXMuX2Nvbm5lY3RvcnMuZmluZChjID0+IGMuY2FuUmVhY2gocmVtb3RlS2VybmVsVXJpKSk7XHJcbiAgICAgICAgaWYgKCFjb25uZWN0b3IpIHtcclxuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKGBDYW5ub3QgZmluZCBjb25uZWN0b3IgdG8gcmVhY2ggJHtyZW1vdGVLZXJuZWxVcml9YCk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIGxldCBrZXJuZWwgPSBuZXcgUHJveHlLZXJuZWwobG9jYWxOYW1lLCBjb25uZWN0b3Iuc2VuZGVyLCBjb25uZWN0b3IucmVjZWl2ZXIpO1xyXG4gICAgICAgIGtlcm5lbC5rZXJuZWxJbmZvLnJlbW90ZVVyaSA9IHJlbW90ZUtlcm5lbFVyaTtcclxuICAgICAgICB0aGlzLl9rZXJuZWwuYWRkKGtlcm5lbCwgYWxpYXNlcyk7XHJcbiAgICAgICAgcmV0dXJuIGtlcm5lbDtcclxuICAgIH1cclxuXHJcbiAgICBwcml2YXRlIGNvbm5lY3RQcm94eUtlcm5lbE9uQ29ubmVjdG9yKGxvY2FsTmFtZTogc3RyaW5nLCBzZW5kZXI6IGNvbm5lY3Rpb24uSUtlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlciwgcmVjZWl2ZXI6IGNvbm5lY3Rpb24uSUtlcm5lbENvbW1hbmRBbmRFdmVudFJlY2VpdmVyLCByZW1vdGVLZXJuZWxVcmk/OiBzdHJpbmcsIGFsaWFzZXM/OiBzdHJpbmdbXSk6IFByb3h5S2VybmVsIHtcclxuICAgICAgICBsZXQga2VybmVsID0gbmV3IFByb3h5S2VybmVsKGxvY2FsTmFtZSwgc2VuZGVyLCByZWNlaXZlcik7XHJcbiAgICAgICAga2VybmVsLmtlcm5lbEluZm8ucmVtb3RlVXJpID0gcmVtb3RlS2VybmVsVXJpO1xyXG4gICAgICAgIHRoaXMuX2tlcm5lbC5hZGQoa2VybmVsLCBhbGlhc2VzKTtcclxuICAgICAgICByZXR1cm4ga2VybmVsO1xyXG4gICAgfVxyXG5cclxuICAgIHB1YmxpYyB0cnlHZXRDb25uZWN0b3IocmVtb3RlVXJpOiBzdHJpbmcpIHtcclxuICAgICAgICByZXR1cm4gdGhpcy5fY29ubmVjdG9ycy5maW5kKGMgPT4gYy5jYW5SZWFjaChyZW1vdGVVcmkpKTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgYXN5bmMgY29ubmVjdCgpOiBQcm9taXNlPGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbFJlYWR5PiB7XHJcbiAgICAgICAgdGhpcy5fa2VybmVsLnN1YnNjcmliZVRvS2VybmVsRXZlbnRzKGUgPT4ge1xyXG4gICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC5pbmZvKGBLZXJuZWxIb3N0IGZvcndhcmRpbmcgZXZlbnQ6ICR7SlNPTi5zdHJpbmdpZnkoZSl9YCk7XHJcbiAgICAgICAgICAgIHRoaXMuX2RlZmF1bHRDb25uZWN0b3Iuc2VuZGVyLnNlbmQoZSk7XHJcbiAgICAgICAgfSk7XHJcblxyXG4gICAgICAgIHRoaXMuX2RlZmF1bHRDb25uZWN0b3IucmVjZWl2ZXIuc3Vic2NyaWJlKHtcclxuICAgICAgICAgICAgbmV4dDogKGtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU6IGNvbm5lY3Rpb24uS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZSkgPT4ge1xyXG5cclxuICAgICAgICAgICAgICAgIGlmIChjb25uZWN0aW9uLmlzS2VybmVsQ29tbWFuZEVudmVsb3BlKGtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUpKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgS2VybmVsSG9zdCBkaXNwYWN0aGluZyBjb21tYW5kOiAke0pTT04uc3RyaW5naWZ5KGtlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGUpfWApO1xyXG4gICAgICAgICAgICAgICAgICAgIHRoaXMuX3NjaGVkdWxlci5ydW5Bc3luYyhrZXJuZWxDb21tYW5kT3JFdmVudEVudmVsb3BlLCBjb21tYW5kRW52ZWxvcGUgPT4ge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBrZXJuZWwgPSB0aGlzLl9rZXJuZWw7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBrZXJuZWwuc2VuZChjb21tYW5kRW52ZWxvcGUpO1xyXG4gICAgICAgICAgICAgICAgICAgIH0pO1xyXG4gICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9XHJcbiAgICAgICAgfSk7XHJcblxyXG4gICAgICAgIGNvbnN0IGtlcm5lbEluZm9zID0gW3RoaXMuX2tlcm5lbC5rZXJuZWxJbmZvLCAuLi5BcnJheS5mcm9tKHRoaXMuX2tlcm5lbC5jaGlsZEtlcm5lbHMubWFwKGsgPT4gay5rZXJuZWxJbmZvKS5maWx0ZXIoa2kgPT4ga2kuaXNQcm94eSA9PT0gZmFsc2UpKV07XHJcblxyXG4gICAgICAgIGNvbnN0IGtlcm5la1JlYWR5OiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxSZWFkeSA9IHtcclxuICAgICAgICAgICAga2VybmVsSW5mb3M6IGtlcm5lbEluZm9zXHJcbiAgICAgICAgfTtcclxuXHJcbiAgICAgICAgY29uc3QgZXZlbnQgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZShjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxSZWFkeVR5cGUsIGtlcm5la1JlYWR5KTtcclxuICAgICAgICBldmVudC5yb3V0aW5nU2xpcC5zdGFtcCh0aGlzLl9rZXJuZWwua2VybmVsSW5mby51cmkhKTtcclxuXHJcbiAgICAgICAgYXdhaXQgdGhpcy5fZGVmYXVsdENvbm5lY3Rvci5zZW5kZXIuc2VuZChldmVudCk7XHJcblxyXG4gICAgICAgIHJldHVybiBrZXJuZWtSZWFkeTtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0S2VybmVsSW5mb3MoKTogY29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1tdIHtcclxuICAgICAgICBsZXQga2VybmVsSW5mb3MgPSBbdGhpcy5fa2VybmVsLmtlcm5lbEluZm9dO1xyXG4gICAgICAgIGZvciAobGV0IGtlcm5lbCBvZiB0aGlzLl9rZXJuZWwuY2hpbGRLZXJuZWxzKSB7XHJcbiAgICAgICAgICAgIGtlcm5lbEluZm9zLnB1c2goa2VybmVsLmtlcm5lbEluZm8pO1xyXG4gICAgICAgIH1cclxuICAgICAgICByZXR1cm4ga2VybmVsSW5mb3M7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGdldEtlcm5lbEluZm9Qcm9kdWNlZCgpOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlW10ge1xyXG4gICAgICAgIGxldCBldmVudHM6IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGVbXSA9IEFycmF5LmZyb20odGhpcy5nZXRLZXJuZWxJbmZvcygpLm1hcChrZXJuZWxJbmZvID0+IHtcclxuICAgICAgICAgICAgY29uc3QgZXZlbnQgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZShjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvUHJvZHVjZWRUeXBlLCA8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkPnsga2VybmVsSW5mbzoga2VybmVsSW5mbyB9KTtcclxuICAgICAgICAgICAgZXZlbnQucm91dGluZ1NsaXAuc3RhbXAoa2VybmVsSW5mby51cmkhKTtcclxuICAgICAgICAgICAgcmV0dXJuIGV2ZW50O1xyXG4gICAgICAgIH1cclxuICAgICAgICApKTtcclxuXHJcbiAgICAgICAgcmV0dXJuIGV2ZW50cztcclxuICAgIH1cclxufVxyXG4iLCIvLyBDb3B5cmlnaHQgKGMpIC5ORVQgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzLiBBbGwgcmlnaHRzIHJlc2VydmVkLlxyXG4vLyBMaWNlbnNlZCB1bmRlciB0aGUgTUlUIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIGZpbGUgaW4gdGhlIHByb2plY3Qgcm9vdCBmb3IgZnVsbCBsaWNlbnNlIGluZm9ybWF0aW9uLlxyXG5cclxuZXhwb3J0ICogZnJvbSAnLi9jb21wb3NpdGVLZXJuZWwnO1xyXG5leHBvcnQgKiBmcm9tICcuL2Nvbm5lY3Rpb24nO1xyXG5leHBvcnQgKiBmcm9tICcuL2NvbnNvbGVDYXB0dXJlJztcclxuZXhwb3J0ICogZnJvbSAnLi9jb21tYW5kc0FuZEV2ZW50cyc7XHJcbmV4cG9ydCAqIGZyb20gJy4vZGlzcG9zYWJsZXMnO1xyXG5leHBvcnQgKiBmcm9tICcuL2tlcm5lbCc7XHJcbmV4cG9ydCAqIGZyb20gJy4va2VybmVsSG9zdCc7XHJcbmV4cG9ydCAqIGZyb20gJy4va2VybmVsSW52b2NhdGlvbkNvbnRleHQnO1xyXG5leHBvcnQgKiBmcm9tICcuL2tlcm5lbFNjaGVkdWxlcic7XHJcbmV4cG9ydCAqIGZyb20gJy4vbG9nZ2VyJztcclxuZXhwb3J0ICogZnJvbSAnLi9wcm9taXNlQ29tcGxldGlvblNvdXJjZSc7XHJcbmV4cG9ydCAqIGZyb20gJy4vcHJveHlLZXJuZWwnO1xyXG5leHBvcnQgKiBmcm9tICcuL3JvdXRpbmdzbGlwJztcclxuIiwiLy8gQ29weXJpZ2h0IChjKSAuTkVUIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC5cclxuLy8gTGljZW5zZWQgdW5kZXIgdGhlIE1JVCBsaWNlbnNlLiBTZWUgTElDRU5TRSBmaWxlIGluIHRoZSBwcm9qZWN0IHJvb3QgZm9yIGZ1bGwgbGljZW5zZSBpbmZvcm1hdGlvbi5cclxuXHJcbmltcG9ydCAqIGFzIGNvbW1hbmRzQW5kRXZlbnRzIGZyb20gXCIuL2NvbW1hbmRzQW5kRXZlbnRzXCI7XHJcbmltcG9ydCAqIGFzIGNvbm5lY3Rpb24gZnJvbSBcIi4vY29ubmVjdGlvblwiO1xyXG5pbXBvcnQgeyBDb25zb2xlQ2FwdHVyZSB9IGZyb20gXCIuL2NvbnNvbGVDYXB0dXJlXCI7XHJcbmltcG9ydCB7IEtlcm5lbCwgSUtlcm5lbENvbW1hbmRJbnZvY2F0aW9uIH0gZnJvbSBcIi4va2VybmVsXCI7XHJcbmltcG9ydCB7IExvZ2dlciB9IGZyb20gXCIuL2xvZ2dlclwiO1xyXG5pbXBvcnQgKiBhcyBwb2x5Z2xvdE5vdGVib29rc0FwaSBmcm9tIFwiLi9hcGlcIjtcclxuXHJcbmV4cG9ydCBjbGFzcyBKYXZhc2NyaXB0S2VybmVsIGV4dGVuZHMgS2VybmVsIHtcclxuICAgIHByaXZhdGUgc3VwcHJlc3NlZExvY2FsczogU2V0PHN0cmluZz47XHJcbiAgICBwcml2YXRlIGNhcHR1cmU6IENvbnNvbGVDYXB0dXJlO1xyXG5cclxuICAgIGNvbnN0cnVjdG9yKG5hbWU/OiBzdHJpbmcpIHtcclxuICAgICAgICBzdXBlcihuYW1lID8/IFwiamF2YXNjcmlwdFwiLCBcIkphdmFTY3JpcHRcIik7XHJcbiAgICAgICAgdGhpcy5rZXJuZWxJbmZvLmRpc3BsYXlOYW1lID0gYCR7dGhpcy5rZXJuZWxJbmZvLmxvY2FsTmFtZX0gLSAke3RoaXMua2VybmVsSW5mby5sYW5ndWFnZU5hbWV9YDtcclxuICAgICAgICB0aGlzLmtlcm5lbEluZm8uZGVzY3JpcHRpb24gPSBgUnVuIEphdmFTY3JpcHQgY29kZWA7XHJcbiAgICAgICAgdGhpcy5zdXBwcmVzc2VkTG9jYWxzID0gbmV3IFNldDxzdHJpbmc+KHRoaXMuYWxsTG9jYWxWYXJpYWJsZU5hbWVzKCkpO1xyXG4gICAgICAgIHRoaXMucmVnaXN0ZXJDb21tYW5kSGFuZGxlcih7IGNvbW1hbmRUeXBlOiBjb21tYW5kc0FuZEV2ZW50cy5TdWJtaXRDb2RlVHlwZSwgaGFuZGxlOiBpbnZvY2F0aW9uID0+IHRoaXMuaGFuZGxlU3VibWl0Q29kZShpbnZvY2F0aW9uKSB9KTtcclxuICAgICAgICB0aGlzLnJlZ2lzdGVyQ29tbWFuZEhhbmRsZXIoeyBjb21tYW5kVHlwZTogY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdFZhbHVlSW5mb3NUeXBlLCBoYW5kbGU6IGludm9jYXRpb24gPT4gdGhpcy5oYW5kbGVSZXF1ZXN0VmFsdWVJbmZvcyhpbnZvY2F0aW9uKSB9KTtcclxuICAgICAgICB0aGlzLnJlZ2lzdGVyQ29tbWFuZEhhbmRsZXIoeyBjb21tYW5kVHlwZTogY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdFZhbHVlVHlwZSwgaGFuZGxlOiBpbnZvY2F0aW9uID0+IHRoaXMuaGFuZGxlUmVxdWVzdFZhbHVlKGludm9jYXRpb24pIH0pO1xyXG4gICAgICAgIHRoaXMucmVnaXN0ZXJDb21tYW5kSGFuZGxlcih7IGNvbW1hbmRUeXBlOiBjb21tYW5kc0FuZEV2ZW50cy5TZW5kVmFsdWVUeXBlLCBoYW5kbGU6IGludm9jYXRpb24gPT4gdGhpcy5oYW5kbGVTZW5kVmFsdWUoaW52b2NhdGlvbikgfSk7XHJcblxyXG4gICAgICAgIHRoaXMuY2FwdHVyZSA9IG5ldyBDb25zb2xlQ2FwdHVyZSgpO1xyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgaGFuZGxlU2VuZFZhbHVlKGludm9jYXRpb246IElLZXJuZWxDb21tYW5kSW52b2NhdGlvbik6IFByb21pc2U8dm9pZD4ge1xyXG4gICAgICAgIGNvbnN0IHNlbmRWYWx1ZSA9IDxjb21tYW5kc0FuZEV2ZW50cy5TZW5kVmFsdWU+aW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUuY29tbWFuZDtcclxuICAgICAgICBpZiAoc2VuZFZhbHVlLmZvcm1hdHRlZFZhbHVlKSB7XHJcbiAgICAgICAgICAgIHN3aXRjaCAoc2VuZFZhbHVlLmZvcm1hdHRlZFZhbHVlLm1pbWVUeXBlKSB7XHJcbiAgICAgICAgICAgICAgICBjYXNlICdhcHBsaWNhdGlvbi9qc29uJzpcclxuICAgICAgICAgICAgICAgICAgICAoPGFueT5nbG9iYWxUaGlzKVtzZW5kVmFsdWUubmFtZV0gPSBjb25uZWN0aW9uLkRlc2VyaWFsaXplKHNlbmRWYWx1ZS5mb3JtYXR0ZWRWYWx1ZS52YWx1ZSk7XHJcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgICAgICAgICBkZWZhdWx0OlxyXG4gICAgICAgICAgICAgICAgICAgICg8YW55Pmdsb2JhbFRoaXMpW3NlbmRWYWx1ZS5uYW1lXSA9IHNlbmRWYWx1ZS5mb3JtYXR0ZWRWYWx1ZS52YWx1ZTtcclxuICAgICAgICAgICAgICAgICAgICBicmVhaztcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICByZXR1cm4gUHJvbWlzZS5yZXNvbHZlKCk7XHJcbiAgICAgICAgfVxyXG4gICAgICAgIHRocm93IG5ldyBFcnJvcihcImZvcm1hdHRlZFZhbHVlIGlzIHJlcXVpcmVkXCIpO1xyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgYXN5bmMgaGFuZGxlU3VibWl0Q29kZShpbnZvY2F0aW9uOiBJS2VybmVsQ29tbWFuZEludm9jYXRpb24pOiBQcm9taXNlPHZvaWQ+IHtcclxuICAgICAgICBjb25zdCBzdWJtaXRDb2RlID0gPGNvbW1hbmRzQW5kRXZlbnRzLlN1Ym1pdENvZGU+aW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUuY29tbWFuZDtcclxuICAgICAgICBjb25zdCBjb2RlID0gc3VibWl0Q29kZS5jb2RlO1xyXG5cclxuICAgICAgICBzdXBlci5rZXJuZWxJbmZvLmxvY2FsTmFtZTsvLz9cclxuICAgICAgICBzdXBlci5rZXJuZWxJbmZvLnVyaTsvLz9cclxuICAgICAgICBzdXBlci5rZXJuZWxJbmZvLnJlbW90ZVVyaTsvLz9cclxuICAgICAgICBjb25zdCBjb2RlU3VibWlzc2lvblJlY2VpdmVkRXZlbnQgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsRXZlbnRFbnZlbG9wZShjb21tYW5kc0FuZEV2ZW50cy5Db2RlU3VibWlzc2lvblJlY2VpdmVkVHlwZSwgeyBjb2RlIH0sIGludm9jYXRpb24uY29tbWFuZEVudmVsb3BlKTtcclxuICAgICAgICBpbnZvY2F0aW9uLmNvbnRleHQucHVibGlzaChjb2RlU3VibWlzc2lvblJlY2VpdmVkRXZlbnQpO1xyXG4gICAgICAgIGludm9jYXRpb24uY29udGV4dC5jb21tYW5kRW52ZWxvcGUucm91dGluZ1NsaXA7Ly8/XHJcbiAgICAgICAgdGhpcy5jYXB0dXJlLmtlcm5lbEludm9jYXRpb25Db250ZXh0ID0gaW52b2NhdGlvbi5jb250ZXh0O1xyXG4gICAgICAgIGxldCByZXN1bHQ6IGFueSA9IHVuZGVmaW5lZDtcclxuXHJcbiAgICAgICAgdHJ5IHtcclxuICAgICAgICAgICAgY29uc3QgQXN5bmNGdW5jdGlvbiA9IGV2YWwoYE9iamVjdC5nZXRQcm90b3R5cGVPZihhc3luYyBmdW5jdGlvbigpe30pLmNvbnN0cnVjdG9yYCk7XHJcbiAgICAgICAgICAgIGNvbnN0IGV2YWx1YXRvciA9IEFzeW5jRnVuY3Rpb24oXCJjb25zb2xlXCIsIFwicG9seWdsb3ROb3RlYm9va3NcIiwgY29kZSk7XHJcbiAgICAgICAgICAgIHJlc3VsdCA9IGF3YWl0IGV2YWx1YXRvcih0aGlzLmNhcHR1cmUsIHBvbHlnbG90Tm90ZWJvb2tzQXBpKTtcclxuICAgICAgICAgICAgaWYgKHJlc3VsdCAhPT0gdW5kZWZpbmVkKSB7XHJcbiAgICAgICAgICAgICAgICBjb25zdCBmb3JtYXR0ZWRWYWx1ZSA9IGZvcm1hdFZhbHVlKHJlc3VsdCwgJ2FwcGxpY2F0aW9uL2pzb24nKTtcclxuICAgICAgICAgICAgICAgIGNvbnN0IGV2ZW50OiBjb21tYW5kc0FuZEV2ZW50cy5SZXR1cm5WYWx1ZVByb2R1Y2VkID0ge1xyXG4gICAgICAgICAgICAgICAgICAgIGZvcm1hdHRlZFZhbHVlczogW2Zvcm1hdHRlZFZhbHVlXVxyXG4gICAgICAgICAgICAgICAgfTtcclxuICAgICAgICAgICAgICAgIGNvbnN0IHJldHVyblZhbHVlUHJvZHVjZWRFdmVudCA9IG5ldyBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxFdmVudEVudmVsb3BlKGNvbW1hbmRzQW5kRXZlbnRzLlJldHVyblZhbHVlUHJvZHVjZWRUeXBlLCBldmVudCwgaW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUpO1xyXG4gICAgICAgICAgICAgICAgaW52b2NhdGlvbi5jb250ZXh0LnB1Ymxpc2gocmV0dXJuVmFsdWVQcm9kdWNlZEV2ZW50KTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH0gY2F0Y2ggKGUpIHtcclxuICAgICAgICAgICAgdGhyb3cgZTsvLz9cclxuICAgICAgICB9XHJcbiAgICAgICAgZmluYWxseSB7XHJcbiAgICAgICAgICAgIHRoaXMuY2FwdHVyZS5rZXJuZWxJbnZvY2F0aW9uQ29udGV4dCA9IHVuZGVmaW5lZDtcclxuICAgICAgICB9XHJcbiAgICB9XHJcblxyXG4gICAgcHJpdmF0ZSBoYW5kbGVSZXF1ZXN0VmFsdWVJbmZvcyhpbnZvY2F0aW9uOiBJS2VybmVsQ29tbWFuZEludm9jYXRpb24pOiBQcm9taXNlPHZvaWQ+IHtcclxuICAgICAgICBjb25zdCB2YWx1ZUluZm9zOiBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxWYWx1ZUluZm9bXSA9IFtdO1xyXG5cclxuICAgICAgICB0aGlzLmFsbExvY2FsVmFyaWFibGVOYW1lcygpLmZpbHRlcih2ID0+ICF0aGlzLnN1cHByZXNzZWRMb2NhbHMuaGFzKHYpKS5mb3JFYWNoKHYgPT4ge1xyXG4gICAgICAgICAgICBjb25zdCB2YXJpYWJsZVZhbHVlID0gdGhpcy5nZXRMb2NhbFZhcmlhYmxlKHYpO1xyXG4gICAgICAgICAgICB0cnkge1xyXG4gICAgICAgICAgICAgICAgY29uc3QgdmFsdWVJbmZvID0ge1xyXG4gICAgICAgICAgICAgICAgICAgIG5hbWU6IHYsXHJcbiAgICAgICAgICAgICAgICAgICAgdHlwZU5hbWU6IGdldFR5cGUodmFyaWFibGVWYWx1ZSksXHJcbiAgICAgICAgICAgICAgICAgICAgZm9ybWF0dGVkVmFsdWU6IGZvcm1hdFZhbHVlKHZhcmlhYmxlVmFsdWUsIFwidGV4dC9wbGFpblwiKSxcclxuICAgICAgICAgICAgICAgICAgICBwcmVmZXJyZWRNaW1lVHlwZXM6IFtdXHJcbiAgICAgICAgICAgICAgICB9O1xyXG4gICAgICAgICAgICAgICAgdmFsdWVJbmZvcy5wdXNoKHZhbHVlSW5mbyk7XHJcbiAgICAgICAgICAgIH0gY2F0Y2ggKGUpIHtcclxuICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmVycm9yKGBlcnJvciBmb3JtYXR0aW5nIHZhbHVlICR7dn0gOiAke2V9YCk7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9KTtcclxuXHJcbiAgICAgICAgY29uc3QgZXZlbnQ6IGNvbW1hbmRzQW5kRXZlbnRzLlZhbHVlSW5mb3NQcm9kdWNlZCA9IHtcclxuICAgICAgICAgICAgdmFsdWVJbmZvc1xyXG4gICAgICAgIH07XHJcblxyXG4gICAgICAgIGNvbnN0IHZhbHVlSW5mb3NQcm9kdWNlZEV2ZW50ID0gbmV3IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUoY29tbWFuZHNBbmRFdmVudHMuVmFsdWVJbmZvc1Byb2R1Y2VkVHlwZSwgZXZlbnQsIGludm9jYXRpb24uY29tbWFuZEVudmVsb3BlKTtcclxuICAgICAgICBpbnZvY2F0aW9uLmNvbnRleHQucHVibGlzaCh2YWx1ZUluZm9zUHJvZHVjZWRFdmVudCk7XHJcbiAgICAgICAgcmV0dXJuIFByb21pc2UucmVzb2x2ZSgpO1xyXG4gICAgfVxyXG5cclxuICAgIHByaXZhdGUgaGFuZGxlUmVxdWVzdFZhbHVlKGludm9jYXRpb246IElLZXJuZWxDb21tYW5kSW52b2NhdGlvbik6IFByb21pc2U8dm9pZD4ge1xyXG4gICAgICAgIGNvbnN0IHJlcXVlc3RWYWx1ZSA9IDxjb21tYW5kc0FuZEV2ZW50cy5SZXF1ZXN0VmFsdWU+aW52b2NhdGlvbi5jb21tYW5kRW52ZWxvcGUuY29tbWFuZDtcclxuICAgICAgICBjb25zdCByYXdWYWx1ZSA9IHRoaXMuZ2V0TG9jYWxWYXJpYWJsZShyZXF1ZXN0VmFsdWUubmFtZSk7XHJcbiAgICAgICAgY29uc3QgZm9ybWF0dGVkVmFsdWUgPSBmb3JtYXRWYWx1ZShyYXdWYWx1ZSwgcmVxdWVzdFZhbHVlLm1pbWVUeXBlIHx8ICdhcHBsaWNhdGlvbi9qc29uJyk7XHJcbiAgICAgICAgTG9nZ2VyLmRlZmF1bHQuaW5mbyhgcmV0dXJuaW5nICR7SlNPTi5zdHJpbmdpZnkoZm9ybWF0dGVkVmFsdWUpfSBmb3IgJHtyZXF1ZXN0VmFsdWUubmFtZX1gKTtcclxuICAgICAgICBjb25zdCBldmVudDogY29tbWFuZHNBbmRFdmVudHMuVmFsdWVQcm9kdWNlZCA9IHtcclxuICAgICAgICAgICAgbmFtZTogcmVxdWVzdFZhbHVlLm5hbWUsXHJcbiAgICAgICAgICAgIGZvcm1hdHRlZFZhbHVlXHJcbiAgICAgICAgfTtcclxuXHJcbiAgICAgICAgY29uc3QgdmFsdWVQcm9kdWNlZEV2ZW50ID0gbmV3IGNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUoY29tbWFuZHNBbmRFdmVudHMuVmFsdWVQcm9kdWNlZFR5cGUsIGV2ZW50LCBpbnZvY2F0aW9uLmNvbW1hbmRFbnZlbG9wZSk7XHJcbiAgICAgICAgaW52b2NhdGlvbi5jb250ZXh0LnB1Ymxpc2godmFsdWVQcm9kdWNlZEV2ZW50KTtcclxuICAgICAgICByZXR1cm4gUHJvbWlzZS5yZXNvbHZlKCk7XHJcbiAgICB9XHJcblxyXG4gICAgcHVibGljIGFsbExvY2FsVmFyaWFibGVOYW1lcygpOiBzdHJpbmdbXSB7XHJcbiAgICAgICAgY29uc3QgcmVzdWx0OiBzdHJpbmdbXSA9IFtdO1xyXG4gICAgICAgIHRyeSB7XHJcbiAgICAgICAgICAgIGZvciAoY29uc3Qga2V5IGluIGdsb2JhbFRoaXMpIHtcclxuICAgICAgICAgICAgICAgIHRyeSB7XHJcbiAgICAgICAgICAgICAgICAgICAgaWYgKHR5cGVvZiAoPGFueT5nbG9iYWxUaGlzKVtrZXldICE9PSAnZnVuY3Rpb24nKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlc3VsdC5wdXNoKGtleSk7XHJcbiAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgfSBjYXRjaCAoZSkge1xyXG4gICAgICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmVycm9yKGBlcnJvciBnZXR0aW5nIHZhbHVlIGZvciAke2tleX0gOiAke2V9YCk7XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9IGNhdGNoIChlKSB7XHJcbiAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmVycm9yKGBlcnJvciBzY2FubmluZyBnbG9ibGEgdmFyaWFibGVzIDogJHtlfWApO1xyXG4gICAgICAgIH1cclxuXHJcbiAgICAgICAgcmV0dXJuIHJlc3VsdDtcclxuICAgIH1cclxuXHJcbiAgICBwdWJsaWMgZ2V0TG9jYWxWYXJpYWJsZShuYW1lOiBzdHJpbmcpOiBhbnkge1xyXG4gICAgICAgIHJldHVybiAoPGFueT5nbG9iYWxUaGlzKVtuYW1lXTtcclxuICAgIH1cclxufVxyXG5cclxuZXhwb3J0IGZ1bmN0aW9uIGZvcm1hdFZhbHVlKGFyZzogYW55LCBtaW1lVHlwZTogc3RyaW5nKTogY29tbWFuZHNBbmRFdmVudHMuRm9ybWF0dGVkVmFsdWUge1xyXG4gICAgbGV0IHZhbHVlOiBzdHJpbmc7XHJcblxyXG4gICAgc3dpdGNoIChtaW1lVHlwZSkge1xyXG4gICAgICAgIGNhc2UgJ3RleHQvcGxhaW4nOlxyXG4gICAgICAgICAgICB2YWx1ZSA9IGFyZz8udG9TdHJpbmcoKSB8fCAndW5kZWZpbmVkJztcclxuICAgICAgICAgICAgaWYgKEFycmF5LmlzQXJyYXkoYXJnKSkge1xyXG4gICAgICAgICAgICAgICAgdmFsdWUgPSBgWyR7dmFsdWV9XWA7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgY2FzZSAnYXBwbGljYXRpb24vanNvbic6XHJcbiAgICAgICAgICAgIHZhbHVlID0gY29ubmVjdGlvbi5TZXJpYWxpemUoYXJnKTtcclxuICAgICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgZGVmYXVsdDpcclxuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKGB1bnN1cHBvcnRlZCBtaW1lIHR5cGU6ICR7bWltZVR5cGV9YCk7XHJcbiAgICB9XHJcblxyXG4gICAgcmV0dXJuIHtcclxuICAgICAgICBtaW1lVHlwZSxcclxuICAgICAgICB2YWx1ZSxcclxuICAgICAgICBzdXBwcmVzc0Rpc3BsYXk6IGZhbHNlXHJcbiAgICB9O1xyXG59XHJcblxyXG5leHBvcnQgZnVuY3Rpb24gZ2V0VHlwZShhcmc6IGFueSk6IHN0cmluZyB7XHJcbiAgICBsZXQgdHlwZTogc3RyaW5nID0gYXJnID8gdHlwZW9mIChhcmcpIDogXCJcIjsvLz9cclxuXHJcbiAgICBpZiAoQXJyYXkuaXNBcnJheShhcmcpKSB7XHJcbiAgICAgICAgdHlwZSA9IGAke3R5cGVvZiAoYXJnWzBdKX1bXWA7Ly8/XHJcbiAgICB9XHJcblxyXG4gICAgaWYgKGFyZyA9PT0gSW5maW5pdHkgfHwgYXJnID09PSAtSW5maW5pdHkgfHwgKGFyZyAhPT0gYXJnKSkge1xyXG4gICAgICAgIHR5cGUgPSBcIm51bWJlclwiO1xyXG4gICAgfVxyXG5cclxuICAgIHJldHVybiB0eXBlOyAvLz9cclxufVxyXG5cclxuIiwiLy8gQ29weXJpZ2h0IChjKSAuTkVUIEZvdW5kYXRpb24gYW5kIGNvbnRyaWJ1dG9ycy4gQWxsIHJpZ2h0cyByZXNlcnZlZC5cclxuLy8gTGljZW5zZWQgdW5kZXIgdGhlIE1JVCBsaWNlbnNlLiBTZWUgTElDRU5TRSBmaWxlIGluIHRoZSBwcm9qZWN0IHJvb3QgZm9yIGZ1bGwgbGljZW5zZSBpbmZvcm1hdGlvbi5cclxuXHJcbmltcG9ydCB7IENvbXBvc2l0ZUtlcm5lbCB9IGZyb20gXCIuLi9jb21wb3NpdGVLZXJuZWxcIjtcclxuaW1wb3J0IHsgSmF2YXNjcmlwdEtlcm5lbCB9IGZyb20gXCIuLi9qYXZhc2NyaXB0S2VybmVsXCI7XHJcbmltcG9ydCB7IExvZ0VudHJ5LCBMb2dnZXIgfSBmcm9tIFwiLi4vbG9nZ2VyXCI7XHJcbmltcG9ydCB7IEtlcm5lbEhvc3QgfSBmcm9tIFwiLi4va2VybmVsSG9zdFwiO1xyXG5pbXBvcnQgKiBhcyByeGpzIGZyb20gXCJyeGpzXCI7XHJcbmltcG9ydCAqIGFzIGNvbm5lY3Rpb24gZnJvbSBcIi4uL2Nvbm5lY3Rpb25cIjtcclxuaW1wb3J0ICogYXMgY29tbWFuZHNBbmRFdmVudHMgZnJvbSBcIi4uL2NvbW1hbmRzQW5kRXZlbnRzXCI7XHJcblxyXG5leHBvcnQgZnVuY3Rpb24gY3JlYXRlSG9zdChcclxuICAgIGdsb2JhbDogYW55LFxyXG4gICAgY29tcG9zaXRlS2VybmVsTmFtZTogc3RyaW5nLFxyXG4gICAgY29uZmlndXJlUmVxdWlyZTogKGludGVyYWN0aXZlOiBhbnkpID0+IHZvaWQsXHJcbiAgICBsb2dNZXNzYWdlOiAoZW50cnk6IExvZ0VudHJ5KSA9PiB2b2lkLFxyXG4gICAgbG9jYWxUb1JlbW90ZTogcnhqcy5PYnNlcnZlcjxjb25uZWN0aW9uLktlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU+LFxyXG4gICAgcmVtb3RlVG9Mb2NhbDogcnhqcy5PYnNlcnZhYmxlPGNvbm5lY3Rpb24uS2VybmVsQ29tbWFuZE9yRXZlbnRFbnZlbG9wZT4sXHJcbiAgICBvblJlYWR5OiAoKSA9PiB2b2lkKSB7XHJcbiAgICBMb2dnZXIuY29uZmlndXJlKGNvbXBvc2l0ZUtlcm5lbE5hbWUsIGxvZ01lc3NhZ2UpO1xyXG5cclxuICAgIGdsb2JhbC5pbnRlcmFjdGl2ZSA9IHt9O1xyXG4gICAgY29uZmlndXJlUmVxdWlyZShnbG9iYWwuaW50ZXJhY3RpdmUpO1xyXG5cclxuICAgIGNvbnN0IGNvbXBvc2l0ZUtlcm5lbCA9IG5ldyBDb21wb3NpdGVLZXJuZWwoY29tcG9zaXRlS2VybmVsTmFtZSk7XHJcbiAgICBjb25zdCBrZXJuZWxIb3N0ID0gbmV3IEtlcm5lbEhvc3QoY29tcG9zaXRlS2VybmVsLCBjb25uZWN0aW9uLktlcm5lbENvbW1hbmRBbmRFdmVudFNlbmRlci5Gcm9tT2JzZXJ2ZXIobG9jYWxUb1JlbW90ZSksIGNvbm5lY3Rpb24uS2VybmVsQ29tbWFuZEFuZEV2ZW50UmVjZWl2ZXIuRnJvbU9ic2VydmFibGUocmVtb3RlVG9Mb2NhbCksIGBrZXJuZWw6Ly8ke2NvbXBvc2l0ZUtlcm5lbE5hbWV9YCk7XHJcblxyXG4gICAga2VybmVsSG9zdC5kZWZhdWx0Q29ubmVjdG9yLnJlY2VpdmVyLnN1YnNjcmliZSh7XHJcbiAgICAgICAgbmV4dDogKGVudmVsb3BlKSA9PiB7XHJcbiAgICAgICAgICAgIGlmIChjb25uZWN0aW9uLmlzS2VybmVsRXZlbnRFbnZlbG9wZShlbnZlbG9wZSkgJiYgZW52ZWxvcGUuZXZlbnRUeXBlID09PSBjb21tYW5kc0FuZEV2ZW50cy5LZXJuZWxJbmZvUHJvZHVjZWRUeXBlKSB7XHJcbiAgICAgICAgICAgICAgICBjb25zdCBrZXJuZWxJbmZvUHJvZHVjZWQgPSA8Y29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkPmVudmVsb3BlLmV2ZW50O1xyXG4gICAgICAgICAgICAgICAgY29ubmVjdGlvbi5lbnN1cmVPclVwZGF0ZVByb3h5Rm9yS2VybmVsSW5mbyhrZXJuZWxJbmZvUHJvZHVjZWQua2VybmVsSW5mbywgY29tcG9zaXRlS2VybmVsKTtcclxuICAgICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgIH0pO1xyXG5cclxuICAgIC8vIHVzZSBjb21wb3NpdGUga2VybmVsIGFzIHJvb3RcclxuICAgIGdsb2JhbC5rZXJuZWwgPSB7XHJcbiAgICAgICAgZ2V0IHJvb3QoKSB7XHJcbiAgICAgICAgICAgIHJldHVybiBjb21wb3NpdGVLZXJuZWw7XHJcbiAgICAgICAgfVxyXG4gICAgfTtcclxuXHJcbiAgICBnbG9iYWwuc2VuZFNlbmRWYWx1ZUNvbW1hbmQgPSAoZm9ybTogYW55KSA9PiB7XHJcbiAgICAgICAgbGV0IGZvcm1WYWx1ZXM6IGFueSA9IHt9O1xyXG5cclxuICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IGZvcm0uZWxlbWVudHMubGVuZ3RoOyBpKyspIHtcclxuICAgICAgICAgICAgdmFyIGUgPSBmb3JtLmVsZW1lbnRzW2ldO1xyXG5cclxuICAgICAgICAgICAgaWYgKGUubmFtZSAmJiBlLm5hbWUgIT09ICcnKSB7XHJcbiAgICAgICAgICAgICAgICBsZXQgbmFtZSA9IGUubmFtZS5yZXBsYWNlKCctJywgJycpO1xyXG4gICAgICAgICAgICAgICAgZm9ybVZhbHVlc1tuYW1lXSA9IGUudmFsdWU7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcblxyXG4gICAgICAgIGxldCBjb21tYW5kID0ge1xyXG4gICAgICAgICAgICBmb3JtYXR0ZWRWYWx1ZToge1xyXG4gICAgICAgICAgICAgICAgbWltZVR5cGU6ICdhcHBsaWNhdGlvbi9qc29uJyxcclxuICAgICAgICAgICAgICAgIHZhbHVlOiBKU09OLnN0cmluZ2lmeShmb3JtVmFsdWVzKVxyXG4gICAgICAgICAgICB9LFxyXG4gICAgICAgICAgICBuYW1lOiBmb3JtLmlkLFxyXG4gICAgICAgICAgICB0YXJnZXRLZXJuZWxOYW1lOiAnLk5FVCdcclxuICAgICAgICB9O1xyXG5cclxuICAgICAgICBsZXQgZW52ZWxvcGUgPSBuZXcgY29tbWFuZHNBbmRFdmVudHMuS2VybmVsQ29tbWFuZEVudmVsb3BlKGNvbW1hbmRzQW5kRXZlbnRzLlNlbmRWYWx1ZVR5cGUsIGNvbW1hbmQpO1xyXG5cclxuICAgICAgICBmb3JtLnJlbW92ZSgpO1xyXG5cclxuICAgICAgICBjb21wb3NpdGVLZXJuZWwuc2VuZChlbnZlbG9wZSk7XHJcbiAgICB9O1xyXG5cclxuICAgIGdsb2JhbFtjb21wb3NpdGVLZXJuZWxOYW1lXSA9IHtcclxuICAgICAgICBjb21wb3NpdGVLZXJuZWwsXHJcbiAgICAgICAga2VybmVsSG9zdCxcclxuICAgIH07XHJcblxyXG4gICAgY29uc3QganNLZXJuZWwgPSBuZXcgSmF2YXNjcmlwdEtlcm5lbCgpO1xyXG4gICAgY29tcG9zaXRlS2VybmVsLmFkZChqc0tlcm5lbCwgW1wianNcIl0pO1xyXG5cclxuICAgIGtlcm5lbEhvc3QuY29ubmVjdCgpO1xyXG5cclxuICAgIG9uUmVhZHkoKTtcclxufVxyXG4iLCIvLyBDb3B5cmlnaHQgKGMpIC5ORVQgRm91bmRhdGlvbiBhbmQgY29udHJpYnV0b3JzLiBBbGwgcmlnaHRzIHJlc2VydmVkLlxyXG4vLyBMaWNlbnNlZCB1bmRlciB0aGUgTUlUIGxpY2Vuc2UuIFNlZSBMSUNFTlNFIGZpbGUgaW4gdGhlIHByb2plY3Qgcm9vdCBmb3IgZnVsbCBsaWNlbnNlIGluZm9ybWF0aW9uLlxyXG5cclxuaW1wb3J0ICogYXMgZnJvbnRFbmRIb3N0IGZyb20gJy4vZnJvbnRFbmRIb3N0JztcclxuaW1wb3J0ICogYXMgcnhqcyBmcm9tIFwicnhqc1wiO1xyXG5pbXBvcnQgKiBhcyBjb25uZWN0aW9uIGZyb20gXCIuLi9jb25uZWN0aW9uXCI7XHJcbmltcG9ydCB7IExvZ2dlciB9IGZyb20gXCIuLi9sb2dnZXJcIjtcclxuaW1wb3J0IHsgS2VybmVsSG9zdCB9IGZyb20gJy4uL2tlcm5lbEhvc3QnO1xyXG5pbXBvcnQgeyB2NCBhcyB1dWlkIH0gZnJvbSAndXVpZCc7XHJcbmltcG9ydCB7IEtlcm5lbEluZm8gfSBmcm9tICcuLi9jb250cmFjdHMnO1xyXG5pbXBvcnQgeyBLZXJuZWxDb21tYW5kRW52ZWxvcGUsIEtlcm5lbEV2ZW50RW52ZWxvcGUgfSBmcm9tICcuLi9jb21tYW5kc0FuZEV2ZW50cyc7XHJcblxyXG50eXBlIEtlcm5lbE1lc3NhZ2luZ0FwaSA9IHtcclxuICAgIG9uRGlkUmVjZWl2ZUtlcm5lbE1lc3NhZ2U6IChhcmc6IGFueSkgPT4gYW55O1xyXG4gICAgcG9zdEtlcm5lbE1lc3NhZ2U6IChkYXRhOiB1bmtub3duKSA9PiB2b2lkO1xyXG59O1xyXG5cclxuZXhwb3J0IGZ1bmN0aW9uIGFjdGl2YXRlKGNvbnRleHQ6IEtlcm5lbE1lc3NhZ2luZ0FwaSkge1xyXG4gICAgY29uZmlndXJlKHdpbmRvdywgY29udGV4dCk7XHJcbiAgICBMb2dnZXIuZGVmYXVsdC5pbmZvKGBzZXQgdXAgJ3dlYnZpZXcnIGhvc3QgbW9kdWxlIGNvbXBsZXRlYCk7XHJcbn1cclxuXHJcbmZ1bmN0aW9uIGNvbmZpZ3VyZShnbG9iYWw6IGFueSwgY29udGV4dDogS2VybmVsTWVzc2FnaW5nQXBpKSB7XHJcbiAgICBpZiAoIWdsb2JhbCkge1xyXG4gICAgICAgIGdsb2JhbCA9IHdpbmRvdztcclxuICAgIH1cclxuXHJcbiAgICBjb25zdCByZW1vdGVUb0xvY2FsID0gbmV3IHJ4anMuU3ViamVjdDxjb25uZWN0aW9uLktlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU+KCk7XHJcbiAgICBjb25zdCBsb2NhbFRvUmVtb3RlID0gbmV3IHJ4anMuU3ViamVjdDxjb25uZWN0aW9uLktlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGU+KCk7XHJcblxyXG4gICAgbG9jYWxUb1JlbW90ZS5zdWJzY3JpYmUoe1xyXG4gICAgICAgIG5leHQ6IGVudmVsb3BlID0+IHtcclxuICAgICAgICAgICAgY29uc3QgZW52ZWxvcGVKc29uID0gZW52ZWxvcGUudG9Kc29uKCk7XHJcbiAgICAgICAgICAgIGNvbnRleHQucG9zdEtlcm5lbE1lc3NhZ2UoeyBlbnZlbG9wZTogZW52ZWxvcGVKc29uIH0pO1xyXG4gICAgICAgIH1cclxuICAgIH0pO1xyXG5cclxuICAgIGNvbnN0IHdlYlZpZXdJZCA9IHV1aWQoKTtcclxuICAgIGNvbnRleHQub25EaWRSZWNlaXZlS2VybmVsTWVzc2FnZSgoYXJnOiBhbnkpID0+IHtcclxuICAgICAgICBpZiAoYXJnLmVudmVsb3BlICYmIGFyZy53ZWJWaWV3SWQgPT09IHdlYlZpZXdJZCkge1xyXG4gICAgICAgICAgICBjb25zdCBlbnZlbG9wZSA9IDxjb25uZWN0aW9uLktlcm5lbENvbW1hbmRPckV2ZW50RW52ZWxvcGVNb2RlbD48YW55PihhcmcuZW52ZWxvcGUpO1xyXG4gICAgICAgICAgICBpZiAoY29ubmVjdGlvbi5pc0tlcm5lbEV2ZW50RW52ZWxvcGVNb2RlbChlbnZlbG9wZSkpIHtcclxuICAgICAgICAgICAgICAgIExvZ2dlci5kZWZhdWx0LmluZm8oYGNoYW5uZWwgZ290ICR7ZW52ZWxvcGUuZXZlbnRUeXBlfSB3aXRoIHRva2VuICR7ZW52ZWxvcGUuY29tbWFuZD8udG9rZW59YCk7XHJcbiAgICAgICAgICAgICAgICBjb25zdCBldmVudCA9IEtlcm5lbEV2ZW50RW52ZWxvcGUuZnJvbUpzb24oZW52ZWxvcGUpO1xyXG4gICAgICAgICAgICAgICAgcmVtb3RlVG9Mb2NhbC5uZXh0KGV2ZW50KTtcclxuICAgICAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgICAgICAgIGNvbnN0IGNvbW1hbmQgPSBLZXJuZWxDb21tYW5kRW52ZWxvcGUuZnJvbUpzb24oZW52ZWxvcGUpO1xyXG4gICAgICAgICAgICAgICAgcmVtb3RlVG9Mb2NhbC5uZXh0KGNvbW1hbmQpO1xyXG4gICAgICAgICAgICB9XHJcblxyXG4gICAgICAgIH0gZWxzZSBpZiAoYXJnLndlYlZpZXdJZCA9PT0gd2ViVmlld0lkKSB7XHJcbiAgICAgICAgICAgIGNvbnN0IGtlcm5lbEhvc3QgPSAoPEtlcm5lbEhvc3Q+KGdsb2JhbFsnd2VidmlldyddLmtlcm5lbEhvc3QpKTtcclxuICAgICAgICAgICAgaWYgKGtlcm5lbEhvc3QpIHtcclxuICAgICAgICAgICAgICAgIHN3aXRjaCAoYXJnLnByZWxvYWRDb21tYW5kKSB7XHJcbiAgICAgICAgICAgICAgICAgICAgY2FzZSAnIyFjb25uZWN0Jzoge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBMb2dnZXIuZGVmYXVsdC5pbmZvKGBjb25uZWN0aW5nIHRvIGtlcm5lbHMgZnJvbSBleHRlbnNpb24gaG9zdGApO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICBjb25zdCBrZXJuZWxJbmZvcyA9IDxLZXJuZWxJbmZvW10+KGFyZy5rZXJuZWxJbmZvcyk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIGZvciAoY29uc3Qga2VybmVsSW5mbyBvZiBrZXJuZWxJbmZvcykge1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29uc3QgcmVtb3RlVXJpID0ga2VybmVsSW5mby5pc1Byb3h5ID8ga2VybmVsSW5mby5yZW1vdGVVcmkhIDoga2VybmVsSW5mby51cmk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiAoIWtlcm5lbEhvc3QudHJ5R2V0Q29ubmVjdG9yKHJlbW90ZVVyaSkpIHtcclxuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBrZXJuZWxIb3N0LmRlZmF1bHRDb25uZWN0b3IuYWRkUmVtb3RlSG9zdFVyaShyZW1vdGVVcmkpO1xyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgY29ubmVjdGlvbi5lbnN1cmVPclVwZGF0ZVByb3h5Rm9yS2VybmVsSW5mbyhrZXJuZWxJbmZvLCBrZXJuZWxIb3N0Lmtlcm5lbCk7XHJcbiAgICAgICAgICAgICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgICAgICB9XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICB9XHJcbiAgICB9KTtcclxuXHJcbiAgICBmcm9udEVuZEhvc3QuY3JlYXRlSG9zdChcclxuICAgICAgICBnbG9iYWwsXHJcbiAgICAgICAgJ3dlYnZpZXcnLFxyXG4gICAgICAgIGNvbmZpZ3VyZVJlcXVpcmUsXHJcbiAgICAgICAgZW50cnkgPT4ge1xyXG4gICAgICAgICAgICBjb250ZXh0LnBvc3RLZXJuZWxNZXNzYWdlKHsgbG9nRW50cnk6IGVudHJ5IH0pO1xyXG4gICAgICAgIH0sXHJcbiAgICAgICAgbG9jYWxUb1JlbW90ZSxcclxuICAgICAgICByZW1vdGVUb0xvY2FsLFxyXG4gICAgICAgICgpID0+IHtcclxuICAgICAgICAgICAgY29uc3Qga2VybmVsSW5mb3MgPSAoPEtlcm5lbEhvc3Q+KGdsb2JhbFsnd2VidmlldyddLmtlcm5lbEhvc3QpKS5nZXRLZXJuZWxJbmZvcygpO1xyXG4gICAgICAgICAgICBjb25zdCBob3N0VXJpID0gKDxLZXJuZWxIb3N0PihnbG9iYWxbJ3dlYnZpZXcnXS5rZXJuZWxIb3N0KSkudXJpO1xyXG4gICAgICAgICAgICBjb250ZXh0LnBvc3RLZXJuZWxNZXNzYWdlKHsgcHJlbG9hZENvbW1hbmQ6ICcjIWNvbm5lY3QnLCBrZXJuZWxJbmZvcywgaG9zdFVyaSwgd2ViVmlld0lkIH0pO1xyXG4gICAgICAgIH1cclxuICAgICk7XHJcbn1cclxuXHJcbmZ1bmN0aW9uIGNvbmZpZ3VyZVJlcXVpcmUoaW50ZXJhY3RpdmU6IGFueSkge1xyXG4gICAgaWYgKCh0eXBlb2YgKHJlcXVpcmUpICE9PSB0eXBlb2YgKEZ1bmN0aW9uKSkgfHwgKHR5cGVvZiAoKDxhbnk+cmVxdWlyZSkuY29uZmlnKSAhPT0gdHlwZW9mIChGdW5jdGlvbikpKSB7XHJcbiAgICAgICAgbGV0IHJlcXVpcmVfc2NyaXB0ID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudCgnc2NyaXB0Jyk7XHJcbiAgICAgICAgcmVxdWlyZV9zY3JpcHQuc2V0QXR0cmlidXRlKCdzcmMnLCAnaHR0cHM6Ly9jZG5qcy5jbG91ZGZsYXJlLmNvbS9hamF4L2xpYnMvcmVxdWlyZS5qcy8yLjMuNi9yZXF1aXJlLm1pbi5qcycpO1xyXG4gICAgICAgIHJlcXVpcmVfc2NyaXB0LnNldEF0dHJpYnV0ZSgndHlwZScsICd0ZXh0L2phdmFzY3JpcHQnKTtcclxuICAgICAgICByZXF1aXJlX3NjcmlwdC5vbmxvYWQgPSBmdW5jdGlvbiAoKSB7XHJcbiAgICAgICAgICAgIGludGVyYWN0aXZlLmNvbmZpZ3VyZVJlcXVpcmUgPSAoY29uZmluZzogYW55KSA9PiB7XHJcbiAgICAgICAgICAgICAgICByZXR1cm4gKDxhbnk+cmVxdWlyZSkuY29uZmlnKGNvbmZpbmcpIHx8IHJlcXVpcmU7XHJcbiAgICAgICAgICAgIH07XHJcblxyXG4gICAgICAgIH07XHJcbiAgICAgICAgZG9jdW1lbnQuZ2V0RWxlbWVudHNCeVRhZ05hbWUoJ2hlYWQnKVswXS5hcHBlbmRDaGlsZChyZXF1aXJlX3NjcmlwdCk7XHJcblxyXG4gICAgfSBlbHNlIHtcclxuICAgICAgICBpbnRlcmFjdGl2ZS5jb25maWd1cmVSZXF1aXJlID0gKGNvbmZpbmc6IGFueSkgPT4ge1xyXG4gICAgICAgICAgICByZXR1cm4gKDxhbnk+cmVxdWlyZSkuY29uZmlnKGNvbmZpbmcpIHx8IHJlcXVpcmU7XHJcbiAgICAgICAgfTtcclxuICAgIH1cclxufVxyXG4iXSwibmFtZXMiOlsidXVpZC5wYXJzZSIsInV1aWQudjQiLCJTeW1ib2xfb2JzZXJ2YWJsZSIsInJ4anMuU3ViamVjdCIsImNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbENvbW1hbmRFbnZlbG9wZSIsImNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbEV2ZW50RW52ZWxvcGUiLCJjb21tYW5kc0FuZEV2ZW50cy5Db21tYW5kU3VjY2VlZGVkVHlwZSIsImNvbW1hbmRzQW5kRXZlbnRzLkNvbW1hbmRGYWlsZWRUeXBlIiwicm91dGluZ3NsaXAuY3JlYXRlS2VybmVsVXJpIiwiY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdEtlcm5lbEluZm9UeXBlIiwiY29tbWFuZHNBbmRFdmVudHMuS2VybmVsSW5mb1Byb2R1Y2VkVHlwZSIsInJ4anMubWFwIiwiY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdENvbXBsZXRpb25zVHlwZSIsImNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3RTaWduYXR1cmVIZWxwVHlwZSIsImNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3REaWFnbm9zdGljc1R5cGUiLCJjb21tYW5kc0FuZEV2ZW50cy5SZXF1ZXN0SG92ZXJUZXh0VHlwZSIsImNvbm5lY3Rpb24uU2VyaWFsaXplIiwiY29tbWFuZHNBbmRFdmVudHMuRGlzcGxheWVkVmFsdWVQcm9kdWNlZFR5cGUiLCJjb25uZWN0aW9uLnVwZGF0ZUtlcm5lbEluZm8iLCJjb25uZWN0aW9uLmlzS2VybmVsRXZlbnRFbnZlbG9wZSIsInJvdXRpbmdTbGlwLmNyZWF0ZUtlcm5lbFVyaSIsImNvbW1hbmRzQW5kRXZlbnRzLlJlcXVlc3RJbnB1dFR5cGUiLCJjb21tYW5kc0FuZEV2ZW50cy5TZW5kRWRpdGFibGVDb2RlVHlwZSIsImNvbm5lY3Rpb24uQ29ubmVjdG9yIiwiY29ubmVjdGlvbi5pc0tlcm5lbENvbW1hbmRFbnZlbG9wZSIsImNvbW1hbmRzQW5kRXZlbnRzLktlcm5lbFJlYWR5VHlwZSIsImNvbW1hbmRzQW5kRXZlbnRzLlN1Ym1pdENvZGVUeXBlIiwiY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdFZhbHVlSW5mb3NUeXBlIiwiY29tbWFuZHNBbmRFdmVudHMuUmVxdWVzdFZhbHVlVHlwZSIsImNvbW1hbmRzQW5kRXZlbnRzLlNlbmRWYWx1ZVR5cGUiLCJjb25uZWN0aW9uLkRlc2VyaWFsaXplIiwiY29tbWFuZHNBbmRFdmVudHMuQ29kZVN1Ym1pc3Npb25SZWNlaXZlZFR5cGUiLCJjb21tYW5kc0FuZEV2ZW50cy5SZXR1cm5WYWx1ZVByb2R1Y2VkVHlwZSIsImNvbW1hbmRzQW5kRXZlbnRzLlZhbHVlSW5mb3NQcm9kdWNlZFR5cGUiLCJjb21tYW5kc0FuZEV2ZW50cy5WYWx1ZVByb2R1Y2VkVHlwZSIsImNvbm5lY3Rpb24uS2VybmVsQ29tbWFuZEFuZEV2ZW50U2VuZGVyIiwiY29ubmVjdGlvbi5LZXJuZWxDb21tYW5kQW5kRXZlbnRSZWNlaXZlciIsImNvbm5lY3Rpb24uZW5zdXJlT3JVcGRhdGVQcm94eUZvcktlcm5lbEluZm8iLCJ1dWlkIiwiY29ubmVjdGlvbi5pc0tlcm5lbEV2ZW50RW52ZWxvcGVNb2RlbCIsImZyb250RW5kSG9zdC5jcmVhdGVIb3N0Il0sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQUFBLElBQUksR0FBRyxDQUFDLENBQUMsSUFBSSxDQUFjLElBQUksQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsUUFBUSxFQUFFLE9BQU8sQ0FBQyxDQUFDLE1BQU0sSUFBSSxTQUFTLENBQUMsa0NBQWtDLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsTUFBTSxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFJLENBQUMsR0FBRyxFQUFFLEdBQUcsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEdBQUUsQ0FBQyxHQUFHLEVBQUUsR0FBRyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxLQUFLLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsRUFBRSxFQUFFLEdBQUcsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxFQUFFLEVBQUUsR0FBRyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxXQUFXLENBQUMsR0FBRyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxXQUFXLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFFBQVEsQ0FBQyxDQUFDLEtBQUssR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsUUFBUSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsS0FBSyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBQyxDQUFDLEtBQUssRUFBRSxHQUFHLENBQUMsRUFBRSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLFVBQVUsQ0FBQyxJQUFJLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLEVBQUUsS0FBSyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxPQUFPLENBQUMsR0FBRyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsTUFBTSxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxTQUFTLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxPQUFNLEdBQUcsQ0FBQyxJQUFJLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsTUFBTSxFQUFFLENBQUMsR0FBRyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxVQUFVLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsRUFBRSxFQUFFLEdBQUcsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxVQUFVLENBQUMsR0FBRyxDQUFDLEdBQUcsU0FBUyxDQUFDLE1BQU0sQ0FBQyxPQUFNLEdBQUcsQ0FBQyxJQUFJLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxNQUFNLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxHQUFHLEtBQUssQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxHQUFHLENBQUMsQ0FBQyxFQUFDLENBQUMsT0FBTyxLQUFLLENBQUMsR0FBRyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxRQUFRLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsT0FBTSxFQUFFLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTSxFQUFFLENBQUMsSUFBSSxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLEVBQUUsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxJQUFJLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sRUFBRSxFQUFFLEdBQUcsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLElBQUksSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxFQUFFLEdBQUcsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxHQUFHLEVBQUUsR0FBRyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sRUFBRSxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxFQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsRUFBRSxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsRUFBRSxFQUFFLEdBQUcsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsSUFBSSxDQUFDLENBQUMsRUFBRSxLQUFLLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEVBQUUsQ0FBQyxDQUFDLEVBQUUsR0FBRyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxFQUFFLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxNQUFNLENBQUMsT0FBTSxHQUFHLENBQUMsSUFBSSxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsR0FBRyxFQUFFLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU0sQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFFBQVEsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLEtBQUssQ0FBQyxHQUFHLENBQUMsRUFBRSxRQUFRLEVBQUUsT0FBTyxDQUFDLENBQUMsTUFBTSxJQUFJLFNBQVMsQ0FBQyxpQ0FBaUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxLQUFLLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLE1BQU0sRUFBRSxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsTUFBTSxHQUFHLENBQUMsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxHQUFHLENBQUMsQ0FBQyxPQUFNLEVBQUUsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLEtBQUksQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxPQUFPLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEdBQUcsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsS0FBSSxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsT0FBTSxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxHQUFHLElBQUksR0FBRyxDQUFDLEVBQUUsUUFBUSxFQUFFLE9BQU8sQ0FBQyxDQUFDLE1BQU0sSUFBSSxTQUFTLENBQUMsa0VBQWtFLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxPQUFPLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksRUFBRSxDQUFDLENBQUMsQ0FBQyxJQUFJLEVBQUUsRUFBRSxHQUFHLENBQUMsQ0FBQyxHQUFHLEVBQUUsRUFBRSxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsSUFBSSxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsRUFBRSxDQUFDLElBQUksQ0FBQyxFQUFFLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsTUFBTSxDQUFDLE9BQU8sQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsSUFBSSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxHQUFHLEVBQUUsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsT0FBTSxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxHQUFHLENBQUMsRUFBRSxDQUFDLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsU0FBUyxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsSUFBSSxDQUFDLEtBQUssQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLEVBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxLQUFLLENBQUMsR0FBRyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsT0FBTyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxFQUFFLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsSUFBSSxJQUFJLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxNQUFNLENBQUMsY0FBYyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxNQUFNLENBQUMsU0FBUyxDQUFDLGNBQWMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsV0FBVyxFQUFFLE9BQU8sTUFBTSxFQUFFLE1BQU0sQ0FBQyxXQUFXLEVBQUUsTUFBTSxDQUFDLGNBQWMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLFdBQVcsQ0FBQyxDQUFDLEtBQUssQ0FBQyxRQUFRLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxjQUFjLENBQUMsQ0FBQyxDQUFDLFlBQVksQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxJQUFJLENBQUMsSUFBSSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLElBQUksQ0FBQyxDQUFDLEtBQUssQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsUUFBUSxFQUFFLE9BQU8sT0FBTyxDQUFDLENBQUMsQ0FBQyxPQUFPLEdBQUcsT0FBTyxDQUFDLFFBQVEsQ0FBQyxLQUFLLEdBQUcsUUFBUSxFQUFFLE9BQU8sU0FBUyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsU0FBUyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxTQUFTLENBQUMsRUFBRSxFQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsTUFBTSxDQUFDLGNBQWMsRUFBRSxDQUFDLFNBQVMsQ0FBQyxFQUFFLENBQUMsV0FBVyxLQUFLLEVBQUUsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxFQUFDLENBQUMsRUFBRSxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLElBQUksQ0FBQyxJQUFJLENBQUMsQ0FBQyxNQUFNLENBQUMsU0FBUyxDQUFDLGNBQWMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLFVBQVUsRUFBRSxPQUFPLENBQUMsRUFBRSxJQUFJLEdBQUcsQ0FBQyxDQUFDLE1BQU0sSUFBSSxTQUFTLENBQUMsc0JBQXNCLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLCtCQUErQixDQUFDLENBQUMsU0FBUyxDQUFDLEVBQUUsQ0FBQyxJQUFJLENBQUMsV0FBVyxDQUFDLEVBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsSUFBSSxHQUFHLENBQUMsQ0FBQyxNQUFNLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxJQUFJLENBQUMsRUFBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsZ0JBQWdCLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsOERBQThELENBQUMsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxRQUFRLEVBQUUsT0FBTyxDQUFDLEVBQUUsSUFBSSxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsTUFBTSxFQUFFLENBQUMsQ0FBQyxJQUFJLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxTQUFTLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLElBQUksRUFBRSxDQUFDLENBQUMsSUFBSSxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsS0FBSyxFQUFFLENBQUMsQ0FBQyxJQUFJLENBQUMsUUFBUSxDQUFDLENBQUMsQ0FBQyxRQUFRLEVBQUUsQ0FBQyxHQUFHLElBQUksQ0FBQyxNQUFNLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLEVBQUUsSUFBSSxPQUFPLENBQUMsSUFBSSxNQUFNLENBQUMsSUFBSSxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLEtBQUssQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxRQUFRLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLE1BQU0sRUFBRSxDQUFDLENBQUMsTUFBTSxJQUFJLEtBQUssQ0FBQywwREFBMEQsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxZQUFZLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxhQUFhLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxnQkFBZ0IsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsUUFBUSxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsTUFBTSxFQUFFLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsTUFBTSxJQUFJLEtBQUssQ0FBQyxpREFBaUQsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLElBQUksQ0FBQyxHQUFHLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsTUFBTSxJQUFJLEtBQUssQ0FBQywwSUFBMEksQ0FBQyxDQUFDLEtBQUssR0FBRyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxNQUFNLElBQUksS0FBSyxDQUFDLDJIQUEySCxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxLQUFLLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsWUFBWSxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsRUFBRSxRQUFRLEVBQUUsT0FBTyxDQUFDLENBQUMsU0FBUyxFQUFFLFFBQVEsRUFBRSxPQUFPLENBQUMsQ0FBQyxRQUFRLEVBQUUsUUFBUSxFQUFFLE9BQU8sQ0FBQyxDQUFDLElBQUksRUFBRSxRQUFRLEVBQUUsT0FBTyxDQUFDLENBQUMsS0FBSyxFQUFFLFFBQVEsRUFBRSxPQUFPLENBQUMsQ0FBQyxNQUFNLEVBQUUsUUFBUSxFQUFFLE9BQU8sQ0FBQyxDQUFDLE1BQU0sRUFBRSxVQUFVLEVBQUUsT0FBTyxDQUFDLENBQUMsSUFBSSxFQUFFLFVBQVUsRUFBRSxPQUFPLENBQUMsQ0FBQyxRQUFRLENBQUMsQ0FBQyxNQUFNLENBQUMsY0FBYyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsUUFBUSxDQUFDLENBQUMsR0FBRyxDQUFDLFVBQVUsQ0FBQyxPQUFPLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxZQUFZLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxPQUFPLElBQUksQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsUUFBUSxDQUFDLE9BQU8sS0FBSyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFDLElBQUksR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxJQUFJLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsSUFBSSxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUFDLElBQUksR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLFFBQVEsQ0FBQyxJQUFJLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsSUFBSSxDQUFDLE1BQU0sRUFBRSxDQUFDLEdBQUcsSUFBSSxDQUFDLFNBQVMsRUFBRSxDQUFDLEdBQUcsSUFBSSxDQUFDLElBQUksRUFBRSxDQUFDLEdBQUcsSUFBSSxDQUFDLEtBQUssRUFBRSxDQUFDLEdBQUcsSUFBSSxDQUFDLFFBQVEsQ0FBQyxJQUFJLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxFQUFDLENBQUMsT0FBTyxJQUFJLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsT0FBTyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxRQUFRLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsUUFBUSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsT0FBTyxLQUFLLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsTUFBTSxDQUFDLFVBQVUsQ0FBQyxPQUFPLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxZQUFZLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLFFBQVEsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxJQUFJLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLEVBQUUsQ0FBQyxJQUFJLENBQUMsQ0FBQyxJQUFJLEdBQUcsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxFQUFFLElBQUksQ0FBQyxPQUFPLENBQUMsQ0FBQyxVQUFVLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLGNBQWMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLFFBQVEsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxVQUFVLENBQUMsT0FBTyxJQUFJLENBQUMsT0FBTyxHQUFHLElBQUksQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLE9BQU8sQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxZQUFZLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsUUFBUSxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsT0FBTyxLQUFLLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxJQUFJLENBQUMsVUFBVSxHQUFHLElBQUksQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxNQUFNLENBQUMsVUFBVSxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sSUFBSSxDQUFDLE9BQU8sR0FBRyxDQUFDLENBQUMsTUFBTSxDQUFDLElBQUksQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsVUFBVSxHQUFHLENBQUMsQ0FBQyxRQUFRLENBQUMsSUFBSSxDQUFDLFVBQVUsQ0FBQyxDQUFDLElBQUksQ0FBQyxJQUFJLEdBQUcsQ0FBQyxDQUFDLElBQUksQ0FBQyxJQUFJLENBQUMsSUFBSSxDQUFDLENBQUMsSUFBSSxDQUFDLE1BQU0sR0FBRyxDQUFDLENBQUMsTUFBTSxDQUFDLElBQUksQ0FBQyxNQUFNLENBQUMsQ0FBQyxJQUFJLENBQUMsU0FBUyxHQUFHLENBQUMsQ0FBQyxTQUFTLENBQUMsSUFBSSxDQUFDLFNBQVMsQ0FBQyxDQUFDLElBQUksQ0FBQyxLQUFLLEdBQUcsQ0FBQyxDQUFDLEtBQUssQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUFDLENBQUMsSUFBSSxDQUFDLFFBQVEsR0FBRyxDQUFDLENBQUMsUUFBUSxDQUFDLElBQUksQ0FBQyxRQUFRLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsRUFBRSxFQUFFLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxJQUFJLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsRUFBRSxFQUFFLENBQUMsRUFBRSxHQUFHLEVBQUUsQ0FBQyxFQUFFLEVBQUUsRUFBRSxDQUFDLEVBQUUsRUFBRSxFQUFFLENBQUMsRUFBRSxFQUFFLEVBQUUsQ0FBQyxFQUFFLEVBQUUsRUFBRSxFQUFFLEdBQUcsQ0FBQyxFQUFFLEVBQUUsR0FBRyxDQUFDLEVBQUUsRUFBRSxHQUFHLENBQUMsRUFBRSxHQUFHLEdBQUcsQ0FBQyxFQUFFLENBQUMsRUFBRSxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLEVBQUUsa0JBQWtCLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFJLENBQUMsS0FBSyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsRUFBRSxrQkFBa0IsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEVBQUUsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxDQUFDLE9BQU0sQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsRUFBRSxrQkFBa0IsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLElBQUksQ0FBQyxDQUFDLEtBQUssQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsR0FBRyxDQUFDLEVBQUUsRUFBRSxHQUFHLENBQUMsRUFBRSxLQUFLLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxLQUFLLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBQyxDQUFDLE9BQU8sS0FBSyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxNQUFNLENBQUMsQ0FBQyxFQUFFLE1BQU0sR0FBRyxDQUFDLENBQUMsTUFBTSxDQUFDLElBQUksQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsRUFBRSxHQUFHLENBQUMsQ0FBQyxJQUFJLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxJQUFJLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxFQUFFLEVBQUUsRUFBRSxDQUFDLENBQUMsSUFBSSxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsRUFBRSxFQUFFLEVBQUUsQ0FBQyxDQUFDLElBQUksQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLEVBQUUsRUFBRSxFQUFFLENBQUMsQ0FBQyxJQUFJLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxFQUFFLEVBQUUsR0FBRyxDQUFDLENBQUMsSUFBSSxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxXQUFXLEVBQUUsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxLQUFLLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxLQUFLLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxRQUFRLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLEVBQUUsR0FBRyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsTUFBTSxHQUFHLENBQUMsSUFBSSxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUUsSUFBRyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsV0FBVyxFQUFFLEVBQUUsT0FBTyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLE1BQU0sRUFBRSxDQUFDLEVBQUUsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLEVBQUUsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsR0FBRyxFQUFFLEVBQUUsQ0FBQyxFQUFFLEVBQUUsR0FBRyxDQUFDLENBQUMsR0FBRyxDQUFDLE1BQU0sQ0FBQyxNQUFNLENBQUMsWUFBWSxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsS0FBSyxHQUFHLENBQUMsQ0FBQyxNQUFNLEVBQUUsQ0FBQyxFQUFFLEVBQUUsR0FBRyxDQUFDLENBQUMsVUFBVSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFVBQVUsQ0FBQyxDQUFDLENBQUMsR0FBRyxFQUFFLEVBQUUsQ0FBQyxFQUFFLEVBQUUsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLE1BQU0sQ0FBQyxNQUFNLENBQUMsWUFBWSxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxHQUFHLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEVBQUMsQ0FBQyxPQUFPLENBQUMsR0FBRyxDQUFDLEVBQUUsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxFQUFFLEdBQUcsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLE9BQU8sa0JBQWtCLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsNkJBQTZCLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxFQUFFLFNBQVMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxHQUFHLFNBQVMsQ0FBQyxNQUFNLENBQUMsSUFBSSxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsTUFBTSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxJQUFJLENBQUMsR0FBRyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEtBQUssQ0FBQyxTQUFTLENBQUMsS0FBSyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsS0FBSyxDQUFDLFNBQVMsQ0FBQyxLQUFLLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEtBQUssRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFFBQVEsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLElBQUksSUFBSSxDQUFDLENBQUMsRUFBRSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxNQUFNLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLENBQUMsT0FBTyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsV0FBVyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsSUFBSSxJQUFJLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLE1BQU0sQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLFNBQVMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsS0FBSyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxFQUFFLENBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsU0FBUyxHQUFHLENBQUMsQ0FBQyxDQUFDLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxHQUFHLENBQUMsQ0FBQyxJQUFJLENBQUMsTUFBTSxFQUFFLENBQUMsQ0FBQyxJQUFJLEdBQUcsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLE9BQU8sQ0FBQyxHQUFHLENBQUMsQ0FBQyxNQUFNLEVBQUUsRUFBRSxHQUFHLENBQUMsQ0FBQyxVQUFVLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEVBQUUsQ0FBQyxDQUFDLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxJQUFJLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLENBQUMsQ0FBQyxRQUFRLENBQUMsU0FBUyxDQUFDLENBQUMsQ0FBQyxPQUFPLENBQUMsQ0FBQyxRQUFRLENBQUMsQ0FBQyxDQUFDLElBQUksQ0FBQyxDQUFDLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxTQUFTLENBQUMsQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLE9BQU8sQ0FBQyxDQUFDLENBQUMsSUFBSSxDQUFDLEVBQUMsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLENBQUMsRUFBRSxDQUFDLEVBQUMsQ0FBQyxHQUFHLENBQUMsR0FBRyxDQUFDLEVBQUMsQ0FBQyxHQUFHLENBQVEsS0FBSyxDQUFDLEdBQUcsQ0FBQyxLQUFLLENBQUMsQ0FBQyxHQUFHOztBQ0F2cVg7QUFRTSxTQUFVLGVBQWUsQ0FBQyxTQUFpQixFQUFBO0lBQzdDLE1BQU0sR0FBRyxHQUFHLEdBQUcsQ0FBQyxLQUFLLENBQUMsU0FBUyxDQUFDLENBQUM7SUFDakMsR0FBRyxDQUFDLFNBQVMsQ0FBQztJQUNkLEdBQUcsQ0FBQyxJQUFJLENBQUM7QUFDVCxJQUFBLElBQUksV0FBVyxHQUFHLENBQUEsRUFBRyxHQUFHLENBQUMsTUFBTSxDQUFNLEdBQUEsRUFBQSxHQUFHLENBQUMsU0FBUyxHQUFHLEdBQUcsQ0FBQyxJQUFJLElBQUksR0FBRyxF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QyxDQUFDLEdBQUcsQ0FBQyxDQUFDO0FBQ3JGO0FBQ0E7QUFDQSxFQUFFLElBQUksSUFBSSxHQUFHLENBQUMsU0FBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxTQUFTLENBQUMsR0FBRyxDQUFDLE1BQU0sR0FBRyxDQUFDLENBQUMsQ0FBQyxHQUFHLFNBQVMsQ0FBQyxHQUFHLENBQUMsTUFBTSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsU0FBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxHQUFHLEdBQUcsU0FBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxTQUFTLENBQUMsR0FBRyxDQUFDLE1BQU0sR0FBRyxDQUFDLENBQUMsQ0FBQyxHQUFHLEdBQUcsR0FBRyxTQUFTLENBQUMsR0FBRyxDQUFDLE1BQU0sR0FBRyxDQUFDLENBQUMsQ0FBQyxHQUFHLFNBQVMsQ0FBQyxHQUFHLENBQUMsTUFBTSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsR0FBRyxHQUFHLFNBQVMsQ0FBQyxHQUFHLENBQUMsTUFBTSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsU0FBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxHQUFHLEdBQUcsU0FBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsRUFBRSxDQUFDLENBQUMsR0FBRyxTQUFTLENBQUMsR0FBRyxDQUFDLE1BQU0sR0FBRyxFQUFFLENBQUMsQ0FBQyxHQUFHLFNBQVMsQ0FBQyxHQUFHLENBQUMsTUFBTSxHQUFHLEVBQUUsQ0FBQyxDQUFDLEdBQUcsU0FBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEdBQUcsRUFBRSxDQUFDLENBQUMsR0FBRyxTQUFTLENBQUMsR0FBRyxDQUFDLE1BQU0sR0FBRyxFQUFFLENBQUMsQ0FBQyxHQUFHLFNBQVMsQ0FBQyxHQUFHLENBQUMsTUFBTSxHQUFHLEVBQUUsQ0FBQyxDQUFDLEVBQUUsV0FBVyxFQUFFLENBQUM7QUFDemdCO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSxFQUFFLElBQUksQ0FBQyxRQUFRLENBQUMsSUFBSSxDQUFDLEVBQUU7QUFDdkIsSUFBSSxNQUFNLFNBQVMsQ0FBQyw2QkFBNkIsQ0FBQyxDQUFDO0FBQ25ELEdBQUc7QUFDSDtBQUNBLEVBQUUsT0FBTyxJQUFJLENBQUM7QUFDZDs7QUN6QkEsU0FBUyxLQUFLLENBQUMsSUFBSSxFQUFFO0FBQ3JCLEVBQUUsSUFBSSxDQUFDLFFBQVEsQ0FBQyxJQUFJLENBQUMsRUFBRTtBQUN2QixJQUFJLE1BQU0sU0FBUyxDQUFDLGNBQWMsQ0FBQyxDQUFDO0FBQ3BDLEdBQUc7QUFDSDtBQUNBLEVBQUUsSUFBSSxDQUFDLENBQUM7QUFDUixFQUFFLElBQUksR0FBRyxHQUFHLElBQUksVUFBVSxDQUFDLEVBQUUsQ0FBQyxDQUFDO0FBQy9CO0FBQ0EsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEdBQUcsUUFBUSxDQUFDLElBQUksQ0FBQyxLQUFLLENBQUMsQ0FBQyxFQUFFLENBQUMsQ0FBQyxFQUFFLEVBQUUsQ0FBQyxNQUFNLEVBQUUsQ0FBQztBQUN2RCxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEtBQUssRUFBRSxHQUFHLElBQUksQ0FBQztBQUMzQixFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEtBQUssQ0FBQyxHQUFHLElBQUksQ0FBQztBQUMxQixFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsSUFBSSxDQUFDO0FBQ3BCO0FBQ0EsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEdBQUcsUUFBUSxDQUFDLElBQUksQ0FBQyxLQUFLLENBQUMsQ0FBQyxFQUFFLEVBQUUsQ0FBQyxFQUFFLEVBQUUsQ0FBQyxNQUFNLENBQUMsQ0FBQztBQUN2RCxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsSUFBSSxDQUFDO0FBQ3BCO0FBQ0EsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEdBQUcsUUFBUSxDQUFDLElBQUksQ0FBQyxLQUFLLENBQUMsRUFBRSxFQUFFLEVBQUUsQ0FBQyxFQUFFLEVBQUUsQ0FBQyxNQUFNLENBQUMsQ0FBQztBQUN4RCxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsSUFBSSxDQUFDO0FBQ3BCO0FBQ0EsRUFBRSxHQUFHLENBQUMsQ0FBQyxDQUFDLEdBQUcsQ0FBQyxDQUFDLEdBQUcsUUFBUSxDQUFDLElBQUksQ0FBQyxLQUFLLENBQUMsRUFBRSxFQUFFLEVBQUUsQ0FBQyxFQUFFLEVBQUUsQ0FBQyxNQUFNLENBQUMsQ0FBQztBQUN4RCxFQUFFLEdBQUcsQ0FBQyxDQUFDLENBQUMsR0FBRyxDQUFDLEdBQUcsSUFBSSxDQUFDO0FBQ3BCO0FBQ0E7QUFDQSxFQUFFLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLENBQUMsR0FBRyxRQUFRLENBQUMsSUFBSSxDQUFDLEtBQUssQ0FBQyxFQUFFLEVBQUUsRUFBRSxDQUFDLEVBQUUsRUFBRSxDQUFDLElBQUksYUFBYSxHQUFHLElBQUksQ0FBQztBQUMxRSxFQUFFLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEdBQUcsV0FBVyxHQUFHLElBQUksQ0FBQztBQUNuQyxFQUFFLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEtBQUssRUFBRSxHQUFHLElBQUksQ0FBQztBQUM1QixFQUFFLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEtBQUssRUFBRSxHQUFHLElBQUksQ0FBQztBQUM1QixFQUFFLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEtBQUssQ0FBQyxHQUFHLElBQUksQ0FBQztBQUMzQixFQUFFLEdBQUcsQ0FBQyxFQUFFLENBQUMsR0FBRyxDQUFDLEdBQUcsSUFBSSxDQUFDO0FBQ3JCLEVBQUUsT0FBTyxHQUFHLENBQUM7QUFDYjs7QUM3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
