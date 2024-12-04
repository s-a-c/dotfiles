/*
 * wallaby-core - v1.0.1650
 * https://wallabyjs.com
 * Copyright (c) 2014-2024 Wallaby.js - All Rights Reserved.
 *
 * This source code file is a part of wallaby-core and is a proprietary (closed source) software.

 * IMPORTANT:
 * Wallaby.js is a tool made by software developers for software developers with passion and love for what we do.
 * Pirating the tool is not only illegal and just morally wrong,
 * it is also unfair to other fellow programmers who are using it legally,
 * and very harmful for the tool and its future.
 */
!function(r){function A(t){var e,n=t.toString();return"[object"===n.substring(0,7)?(e=t.name?t.name.toString():"Error",t=t.message?t.message.toString():"",e&&t?e+": "+t:e||t||"Error"):n}function i(t){var e,n,s=v.is("array",t)?[]:{};for(e in t)u.call(t,e)&&(n=t[e],s[e]=n===Object(n)?i(n):n);return s}var o,c,d,f,h,p,H,Q,l,a={},P=(E(0)||"").replace(/(:\d+)+\)?/,"").replace(/.+\//,""),R=Object.prototype.toString,u=Object.prototype.hasOwnProperty,F=r.Date,m=F.now||function(){return(new F).getTime()},B=!1,_=!1,g=r.setTimeout,G=r.clearTimeout,b={document:void 0!==r.document,setTimeout:void 0!==r.setTimeout,sessionStorage:function(){var t="qunit-test-string";try{return sessionStorage.setItem(t,t),sessionStorage.removeItem(t),!0}catch(t){return!1}}()},v={},y={queue:[],blocking:!0,reorder:!0,altertitle:!0,scrolltop:!0,requireExpects:!1,maxDepth:5,urlConfig:[{id:"hidepassed",label:"Hide passed tests",tooltip:"Only show tests and assertions that fail. Stored as query-strings."},{id:"noglobals",label:"Check for Globals",tooltip:"Enabling this will test if any test introduces new properties on the `window` object. Stored as query-strings."},{id:"notrycatch",label:"No try-catch",tooltip:"Enabling this will run tests outside of a try-catch block. Makes debugging exceptions in IE reasonable. Stored as query-strings."}],modules:[],currentModule:{name:"",tests:[]},callbacks:{}};y.modules.push(y.currentModule);var t,e,V=r.location||{search:"",protocol:"file:"},n=V.search.slice(1).split("&"),$=n.length,s={};if(n[0])for(t=0;t<$;t++)(e=n[t].split("="))[0]=decodeURIComponent(e[0]),e[1]=!e[1]||decodeURIComponent(e[1]),s[e[0]]?s[e[0]]=[].concat(s[e[0]],e[1]):s[e[0]]=e[1];if(!0===s.filter&&delete s.filter,v.urlParams=s,y.filter=s.filter,s.maxDepth&&(y.maxDepth=-1===parseInt(s.maxDepth,10)?Number.POSITIVE_INFINITY:s.maxDepth),y.testId=[],s.testId)for(s.testId=decodeURIComponent(s.testId).split(","),t=0;t<s.testId.length;t++)y.testId.push(s.testId[t]);v.isLocal="file:"===V.protocol,v.version="1.18.0",M(v,{module:function(t,e){t={name:t,testEnvironment:e,tests:[]};e&&e.setup&&(e.beforeEach=e.setup,delete e.setup),e&&e.teardown&&(e.afterEach=e.teardown,delete e.teardown),y.modules.push(t),y.currentModule=t},asyncTest:function(t,e,n){2===arguments.length&&(n=e,e=null),v.test(t,e,n,!0)},test:function(t,e,n,s){2===arguments.length&&(n=e,e=null),new I({testName:t,expected:e,async:s,callback:n}).queue()},skip:function(t){new I({testName:t,skip:!0}).queue()},start:function(t){var e=B;if(y.current){if(y.current.semaphore-=t||1,0<y.current.semaphore)return;if(y.current.semaphore<0)return y.current.semaphore=0,void v.pushFailure("Called start() while already started (test's semaphore was 0 already)",E(2))}else{if(B=!0,_)throw new Error("Called start() outside of a test context while already started");if(e||1<t)throw new Error("Called start() outside of a test context too many times");if(y.autostart)throw new Error("Called start() outside of a test context when QUnit.config.autostart was true");if(!y.pageLoaded)return void(y.autostart=!0)}C()},stop:function(t){if(!y.current)throw new Error("Called stop() outside of a test context");y.current.semaphore+=t||1,K()},config:y,is:function(t,e){return v.objectType(e)===t},objectType:function(t){if(void 0===t)return"undefined";if(null===t)return"null";var e=R.call(t).match(/^\[object\s(.*)\]$/),n=e&&e[1]||"";switch(n){case"Number":return isNaN(t)?"nan":"number";case"String":case"Boolean":case"Array":case"Date":case"RegExp":case"Function":return n.toLowerCase()}return"object"==typeof t?"object":void 0},extend:M,load:function(){y.pageLoaded=!0,M(y,{stats:{all:0,bad:0},moduleStats:{all:0,bad:0},started:0,updateRate:1e3,autostart:!0,filter:""},!0),y.blocking=!1,y.autostart&&C()}});var w,z,q,W=["begin","done","log","testStart","testDone","moduleStart","moduleDone"];function X(e){function t(t){if("function"!==v.objectType(t))throw new Error("QUnit logging methods require a callback function as their first parameters.");y.callbacks[e].push(t)}return a[e]=t}for(w=0,z=W.length;w<z;w++)"undefined"===v.objectType(y.callbacks[q=W[w]])&&(y.callbacks[q]=[]),v[q]=X(q);function x(t,e){var n,s,i;if(e=void 0===e?4:e,t.stack){if(n=t.stack.split("\n"),/^error$/i.test(n[0])&&n.shift(),P){for(s=[],i=e;i<n.length&&-1===n[i].indexOf(P);i++)s.push(n[i]);if(s.length)return s.join("\n")}return n[e]}if(t.sourceURL&&!/qunit.js$/.test(t.sourceURL))return t.sourceURL+":"+t.line}function E(t){var e=new Error;if(!e.stack)try{throw e}catch(t){e=t}return x(e,t)}function T(t,e){if("array"===v.objectType(t))for(;t.length;)T(t.shift());else y.queue.push(t),y.autorun&&!y.blocking&&Y(e)}function Y(t){function e(){Y(t)}var n,s,i=m();for(y.depth=(y.depth||0)+1;y.queue.length&&!y.blocking;){if(!(!b.setTimeout||y.updateRate<=0||m()-i<y.updateRate)){g(e,13);break}y.current&&(y.current.usedAsync=!1),y.queue.shift()()}y.depth--,!t||y.blocking||y.queue.length||0!==y.depth||(y.autorun=!0,y.previousModule&&S("moduleDone",{name:y.previousModule.name,tests:y.previousModule.tests,failed:y.moduleStats.bad,passed:y.moduleStats.all-y.moduleStats.bad,total:y.moduleStats.all,runtime:m()-y.moduleStats.started}),delete y.previousModule,n=m()-y.started,s=y.stats.all-y.stats.bad,S("done",{failed:y.stats.bad,passed:s,total:y.stats.all,runtime:n}))}function J(){var t,e,n,s,i=[];if(!y.started){for(n in y.started=m(),a)v[n]!==a[n]&&(s=v[n],v[n]=a[n],v[n](s),r.console)&&r.console.warn&&r.console.warn("QUnit."+n+" was replaced with a new value.\nPlease, check out the documentation on how to apply logging callbacks.\nReference: http://api.qunitjs.com/category/callbacks/");for(""===y.modules[0].name&&0===y.modules[0].tests.length&&y.modules.shift(),t=0,e=y.modules.length;t<e;t++)i.push({name:y.modules[t].name,tests:y.modules[t].tests});S("begin",{totalTests:I.count,modules:i})}Y(!(y.blocking=!1))}function C(){_=!0,b.setTimeout?g(function(){y.current&&0<y.current.semaphore||(y.timeout&&G(y.timeout),J())},13):J()}function K(){y.blocking=!0,y.testTimeout&&b.setTimeout&&(G(y.timeout),y.timeout=g(function(){if(!y.current)throw new Error("Test timed out");y.current.semaphore=0,v.pushFailure("Test timed out",E(2)),C()},y.testTimeout))}function k(){if(y.pollution=[],y.noglobals)for(var t in r)!u.call(r,t)||/^qunit-test-output/.test(t)||y.pollution.push(t)}function Z(t,e){for(var n,s=t.slice(),i=0;i<s.length;i++)for(n=0;n<e.length;n++)if(s[i]===e[n]){s.splice(i,1),i--;break}return s}function M(t,e,n){for(var s in e)!u.call(e,s)||"constructor"===s&&t===r||(void 0===e[s]?delete t[s]:n&&void 0!==t[s]||(t[s]=e[s]));return t}function S(t,e){for(var n=y.callbacks[t],s=0,i=n.length;s<i;s++)n[s](e)}function tt(t,e){if(e.indexOf)return e.indexOf(t);for(var n=0,s=e.length;n<s;n++)if(e[n]===t)return n;return-1}function I(t){var e,n;for(++I.count,M(this,t),this.assertions=[],this.semaphore=0,this.usedAsync=!1,this.module=y.currentModule,this.stack=E(3),e=0,n=this.module.tests;e<n.length;e++)this.module.tests[e].name===this.testName&&(this.testName+=" ");this.testId=function(t,e){for(var n=0,s=0,i=t+""+e,r=i.length;n<r;n++)s=(s<<5)-s+i.charCodeAt(n),s|=0;(t=(4294967296+s).toString(16)).length<8&&(t="0000000"+t);return t.slice(-8)}(this.module.name,this.testName),this.module.tests.push({name:this.testName,testId:this.testId}),t.skip?(this.callback=function(){},this.async=!1,this.expected=0):this.assert=new j(this)}function j(t){this.test=t}function N(t,e){return t instanceof e.constructor||e instanceof t.constructor?e==t:e===t}function L(t){return'"'+t.toString().replace(/"/g,'\\"')+'"'}function D(t){return t+""}function U(t,e,n){var s=l.separator(),i=l.indent(),r=l.indent(1);return(e=e.join?e.join(","+s+r):e)?[t,r+e,i+n].join(s):t+n}function et(t,e){var n=t.length,s=new Array(n);if(l.maxDepth&&l.depth>l.maxDepth)return"[object Array]";for(this.up();n--;)s[n]=this.parse(t[n],void 0,e);return this.down(),U("[",s,"]")}if(o=r.onerror,r.onerror=function(t,e,n){var s=!1;if(!0===(s=o?o(t,e,n):s))return s;if(v.config.current){if(v.config.current.ignoreGlobalErrors)return!0;v.pushFailure(t,e+":"+n)}else v.test("global failure",M(function(){v.pushFailure(t,e+":"+n)},{validTest:!0}));return!1},I.count=0,I.prototype={before:function(){this.module===y.previousModule&&u.call(y,"previousModule")||(u.call(y,"previousModule")&&S("moduleDone",{name:y.previousModule.name,tests:y.previousModule.tests,failed:y.moduleStats.bad,passed:y.moduleStats.all-y.moduleStats.bad,total:y.moduleStats.all,runtime:m()-y.moduleStats.started}),y.previousModule=this.module,y.moduleStats={all:0,bad:0,started:m()},S("moduleStart",{name:this.module.name,tests:this.module.tests})),(y.current=this).testEnvironment=M({},this.module.testEnvironment),delete this.testEnvironment.beforeEach,delete this.testEnvironment.afterEach,this.started=m(),S("testStart",{name:this.testName,module:this.module.name,testId:this.testId}),y.pollution||k()},run:function(){var t;if((y.current=this).async&&v.stop(),this.callbackStarted=m(),y.notrycatch)t=this.callback.call(this.testEnvironment,this.assert),this.resolvePromise(t);else try{t=this.callback.call(this.testEnvironment,this.assert),this.resolvePromise(t)}catch(t){this.pushFailure("Died on test #"+(this.assertions.length+1)+" "+this.stack+": "+(t.message||t),x(t,0)),k(),y.blocking&&v.start()}},after:function(){var t,e;e=y.pollution,k(),0<(t=Z(y.pollution,e)).length&&v.pushFailure("Introduced global variable(s): "+t.join(", ")),0<(t=Z(e,y.pollution)).length&&v.pushFailure("Deleted global variable(s): "+t.join(", "))},queueHook:function(t,e){var n,s=this;return function(){if(y.current=s,y.notrycatch)n=t.call(s.testEnvironment,s.assert),s.resolvePromise(n,e);else try{n=t.call(s.testEnvironment,s.assert),s.resolvePromise(n,e)}catch(t){s.pushFailure(e+" failed on "+s.testName+": "+(t.message||t),x(t,0))}}},hooks:function(t){var e=[];return this.skip||this.module.testEnvironment&&"function"===v.objectType(this.module.testEnvironment[t])&&e.push(this.queueHook(this.module.testEnvironment[t],t)),e},finish:function(){y.current=this,y.requireExpects&&null===this.expected?this.pushFailure("Expected number of assertions to be defined, but expect() was not called.",this.stack):null!==this.expected&&this.expected!==this.assertions.length?this.pushFailure("Expected "+this.expected+" assertions, but "+this.assertions.length+" were run",this.stack):null!==this.expected||this.assertions.length||this.pushFailure("Expected at least one assertion, but none were run - call expect(0) to accept zero assertions.",this.stack);var t,e=0;for(this.runtime=m()-this.started,y.stats.all+=this.assertions.length,y.moduleStats.all+=this.assertions.length,t=0;t<this.assertions.length;t++)this.assertions[t].result||(e++,y.stats.bad++,y.moduleStats.bad++);S("testDone",{name:this.testName,module:this.module.name,skipped:!!this.skip,failed:e,passed:this.assertions.length-e,total:this.assertions.length,runtime:this.runtime,assertions:this.assertions,testId:this.testId,duration:this.runtime}),v.reset(),y.current=void 0},queue:function(){var t=this;function e(){T([function(){t.before()},t.hooks("beforeEach"),function(){t.run()},t.hooks("afterEach").reverse(),function(){t.after()},function(){t.finish()}])}this.valid()&&(v.config.reorder&&b.sessionStorage&&+sessionStorage.getItem("qunit-test-"+this.module.name+"-"+this.testName)?e():T(e,!0))},push:function(t,e,n,s){e={module:this.module.name,name:this.testName,result:t,message:s,actual:e,expected:n,testId:this.testId,runtime:m()-this.started};t||(n=E())&&(e.source=n),S("log",e),this.assertions.push({result:!!t,message:s})},pushFailure:function(t,e,n){if(!this instanceof I)throw new Error("pushFailure() assertion outside test context, was "+E(2));n={module:this.module.name,name:this.testName,result:!1,message:t||"error",actual:n||null,testId:this.testId,runtime:m()-this.started};e&&(n.source=e),S("log",n),this.assertions.push({result:!1,message:t})},resolvePromise:function(t,e){var n,s,i=this;null!=t&&(n=t.then,"function"===v.objectType(n))&&(v.stop(),n.call(t,v.start,function(t){s="Promise rejected "+(e?e.replace(/Each$/,""):"during")+" "+i.testName+": "+(t.message||t),i.pushFailure(s,x(t,0)),k(),v.start()}))},valid:function(){var t=y.filter&&y.filter.toLowerCase(),e=v.urlParams.module&&v.urlParams.module.toLowerCase(),n=(this.module.name+": "+this.testName).toLowerCase();return!(!this.callback||!this.callback.validTest)||!(0<y.testId.length&&tt(this.testId,y.testId)<0||e&&(!this.module.name||this.module.name.toLowerCase()!==e)||t&&((e="!"!==t.charAt(0))||(t=t.slice(1)),-1!==n.indexOf(t)?!e:e))}},v.reset=function(){var t;void 0!==r&&(t=b.document&&document.getElementById&&document.getElementById("qunit-fixture"))&&(t.innerHTML=y.fixture)},v.pushFailure=function(){var t;if(v.config.current)return(t=v.config.current).pushFailure.apply(t,arguments);throw new Error("pushFailure() assertion outside test context, in "+E(2))},v.assert=j.prototype={expect:function(t){if(1!==arguments.length)return this.test.expected;this.test.expected=t},async:function(){var t=this.test,e=!1;return t.semaphore+=1,t.usedAsync=!0,K(),function(){e?t.pushFailure("Called the callback returned from `assert.async` more than once",E(2)):(--t.semaphore,e=!0,C())}},push:function(){var t=this,e=t instanceof j&&t.test||v.config.current;if(e)return!0===e.usedAsync&&0===e.semaphore&&e.pushFailure("Assertion after the final `assert.async` was resolved",E(2)),(t=t instanceof j?t:e.assert).test.push.apply(t.test,arguments);throw new Error("assertion outside test context, in "+E(2))},ok:function(t,e){e=e||(t?"okay":"failed, expected argument to be truthy, was: "+v.dump.parse(t)),this.push(!!t,t,!0,e)},notOk:function(t,e){e=e||(t?"failed, expected argument to be falsy, was: "+v.dump.parse(t):"okay"),this.push(!t,t,!1,e)},equal:function(t,e,n){this.push(e==t,t,e,n)},notEqual:function(t,e,n){this.push(e!=t,t,e,n)},propEqual:function(t,e,n){t=i(t),e=i(e),this.push(v.equiv(t,e),t,e,n)},notPropEqual:function(t,e,n){t=i(t),e=i(e),this.push(!v.equiv(t,e),t,e,n)},deepEqual:function(t,e,n){this.push(v.equiv(t,e),t,e,n)},notDeepEqual:function(t,e,n){this.push(!v.equiv(t,e),t,e,n)},strictEqual:function(t,e,n){this.push(e===t,t,e,n)},notStrictEqual:function(t,e,n){this.push(e!==t,t,e,n)},throws:function(t,e,n){var s,i=e,r=!1,o=this instanceof j&&this.test||v.config.current;null==n&&"string"==typeof e&&(n=e,e=null),o.ignoreGlobalErrors=!0;try{t.call(o.testEnvironment)}catch(t){s=t}o.ignoreGlobalErrors=!1,s&&(t=v.objectType(e),e?"regexp"===t?r=e.test(A(s)):"string"===t?r=e===A(s):"function"===t&&s instanceof e?r=!0:"object"===t?r=s instanceof e.constructor&&s.name===e.name&&s.message===e.message:"function"===t&&!0===e.call({},s)&&(r=!(i=null)):(r=!0,i=null)),o.assert.push(r,s,i,n)}},j.prototype.raises=j.prototype.throws,v.equiv=(d=[],f=[],h=[],p=Object.getPrototypeOf||function(t){return t.__proto__},H={string:N,boolean:N,number:N,null:N,undefined:N,nan:function(t){return isNaN(t)},date:function(t,e){return"date"===v.objectType(t)&&e.valueOf()===t.valueOf()},regexp:function(t,e){return"regexp"===v.objectType(t)&&e.source===t.source&&e.global===t.global&&e.ignoreCase===t.ignoreCase&&e.multiline===t.multiline&&e.sticky===t.sticky},function:function(){var t=d[d.length-1];return t!==Object&&void 0!==t},array:function(t,e){var n,s,i,r,o,a;if("array"!==v.objectType(t))return!1;if((i=e.length)!==t.length)return!1;for(f.push(e),h.push(t),n=0;n<i;n++){for(r=!1,s=0;s<f.length;s++)if(o=f[s]===e[n],a=h[s]===t[n],o||a){if(!(e[n]===t[n]||o&&a))return f.pop(),h.pop(),!1;r=!0}if(!r&&!c(e[n],t[n]))return f.pop(),h.pop(),!1}return f.pop(),h.pop(),!0},object:function(t,e){var n,s,i,r,o,a=!0,u=[],l=[];if(e.constructor!==t.constructor&&!(null===p(e)&&p(t)===Object.prototype||null===p(t)&&p(e)===Object.prototype))return!1;for(n in d.push(e.constructor),f.push(e),h.push(t),e){for(i=!1,s=0;s<f.length;s++)if(r=f[s]===e[n],o=h[s]===t[n],r||o){if(!(e[n]===t[n]||r&&o)){a=!1;break}i=!0}if(u.push(n),!i&&!c(e[n],t[n])){a=!1;break}}for(n in f.pop(),h.pop(),d.pop(),t)l.push(n);return a&&c(u.sort(),l.sort())}},c=function(){var t,e,n,s=[].slice.apply(arguments);return s.length<2||(t=s[0],e=s[1],(t===e||null!==t&&null!==e&&void 0!==t&&void 0!==e&&v.objectType(t)===v.objectType(e)&&(n=H,t=[e,e=t],(e=v.objectType(e))?"function"===v.objectType(n[e])?n[e].apply(n,t):n[e]:void 0))&&c.apply(this,s.splice(1,s.length-1)))}),v.dump=(Q=/^function (\w+)/,l={parse:function(t,e,n){var s=tt(t,n=n||[]);return-1!==s?"recursion("+(s-n.length)+")":(e=e||this.typeOf(t),"function"==(e=typeof(s=this.parsers[e]))?(n.push(t),t=s.call(this,t,n),n.pop(),t):"string"==e?s:this.parsers.error)},typeOf:function(t){t=null===t?"null":void 0===t?"undefined":v.is("regexp",t)?"regexp":v.is("date",t)?"date":v.is("function",t)?"function":void 0!==t.setInterval&&void 0!==t.document&&void 0===t.nodeType?"window":9===t.nodeType?"document":t.nodeType?"node":"[object Array]"===R.call(t)||"number"==typeof t.length&&void 0!==t.item&&(t.length?t.item(0)===t[0]:null===t.item(0)&&void 0===t[0])?"array":t.constructor===Error.prototype.constructor?"error":typeof t;return t},separator:function(){return this.multiline?this.HTML?"<br />":"\n":this.HTML?"&#160;":" "},indent:function(t){var e;return this.multiline?(e=this.indentChar,this.HTML&&(e=e.replace(/\t/g,"   ").replace(/ /g,"&#160;")),new Array(this.depth+(t||0)).join(e)):""},up:function(t){this.depth+=t||1},down:function(t){this.depth-=t||1},setParser:function(t,e){this.parsers[t]=e},quote:L,literal:D,join:U,depth:1,maxDepth:v.config.maxDepth,parsers:{window:"[Window]",document:"[Document]",error:function(t){return'Error("'+t.message+'")'},unknown:"[Unknown]",null:"null",undefined:"undefined",function:function(t){var e="function",n="name"in t?t.name:(Q.exec(t)||[])[1];return n&&(e+=" "+n),U(e=[e+="( ",l.parse(t,"functionArgs"),"){"].join(""),l.parse(t,"functionCode"),"}")},array:et,nodelist:et,arguments:et,object:function(t,e){var n,s,i,r,o,a=[];if(l.maxDepth&&l.depth>l.maxDepth)return"[object Object]";for(s in l.up(),n=[],t)n.push(s);for(r in o=["message","name"])(s=o[r])in t&&tt(s,n)<0&&n.push(s);for(n.sort(),r=0;r<n.length;r++)i=t[s=n[r]],a.push(l.parse(s,"key")+": "+l.parse(i,void 0,e));return l.down(),U("{",a,"}")},node:function(t){var e,n,s,i=l.HTML?"&lt;":"<",r=l.HTML?"&gt;":">",o=t.nodeName.toLowerCase(),a=i+o,u=t.attributes;if(u)for(n=0,e=u.length;n<e;n++)(s=u[n].nodeValue)&&"inherit"!==s&&(a+=" "+u[n].nodeName+"="+l.parse(s,"attribute"));return a+=r,3!==t.nodeType&&4!==t.nodeType||(a+=t.nodeValue),a+i+"/"+o+r},functionArgs:function(t){var e,n=t.length;if(!n)return"";for(e=new Array(n);n--;)e[n]=String.fromCharCode(97+n);return" "+e.join(", ")+" "},key:L,functionCode:"[code]",attribute:L,string:L,date:L,regexp:D,number:D,boolean:D},HTML:!1,indentChar:"  ",multiline:!0}),v.jsDump=v.dump,void 0!==r){var nt,st=j.prototype;for(nt in st)v[nt]=function(e){return function(){var t=new j(v.config.current);e.apply(t,arguments)}}(st[nt]);for(var it=["test","module","expect","asyncTest","start","stop","ok","notOk","equal","notEqual","propEqual","notPropEqual","deepEqual","notDeepEqual","strictEqual","notStrictEqual","throws"],O=0,rt=it.length;O<rt;O++)r[it[O]]=v[it[O]];r.QUnit=v}"undefined"!=typeof module&&module&&module.exports&&(module.exports=v,module.exports.QUnit=v),"undefined"!=typeof exports&&exports&&(exports.QUnit=v),"function"==typeof define&&define.amd&&(define(function(){return v}),v.config.autostart=!1)}(function(){return this}()),QUnit.diff=function(){function s(){this.DiffTimeout=1,this.DiffEditCost=4}return s.prototype.DiffMain=function(t,e,n,s){var i,r,o,s=s=void 0===s?this.DiffTimeout<=0?Number.MAX_VALUE:(new Date).getTime()+1e3*this.DiffTimeout:s;if(null===t||null===e)throw new Error("Null input. (DiffMain)");return t===e?t?[[0,t]]:[]:(n=n=void 0===n?!0:n,o=this.diffCommonPrefix(t,e),i=t.substring(0,o),t=t.substring(o),e=e.substring(o),o=this.diffCommonSuffix(t,e),r=t.substring(t.length-o),t=t.substring(0,t.length-o),e=e.substring(0,e.length-o),o=this.diffCompute(t,e,n,s),i&&o.unshift([0,i]),r&&o.push([0,r]),this.diffCleanupMerge(o),o)},s.prototype.diffCleanupEfficiency=function(t){for(var e=!1,n=[],s=0,i=null,r=0,o=!1,a=!1,u=!1,l=!1;r<t.length;)0===t[r][0]?(i=t[r][1].length<this.DiffEditCost&&(u||l)?(o=u,a=l,t[n[s++]=r][1]):(s=0,null),u=l=!1):(-1===t[r][0]?l=!0:u=!0,i&&(o&&a&&u&&l||i.length<this.DiffEditCost/2&&o+a+u+l===3)&&(t.splice(n[s-1],0,[-1,i]),t[n[s-1]+1][0]=1,s--,o&&a?(u=l=!0,s=0):(r=0<--s?n[s-1]:-1,u=l=!1),e=!(i=null))),r++;e&&this.diffCleanupMerge(t)},s.prototype.diffPrettyHtml=function(t){for(var e,n,s=[],i=0;i<t.length;i++)switch(e=t[i][0],n=t[i][1],e){case 1:s[i]="<ins>"+n+"</ins>";break;case-1:s[i]="<del>"+n+"</del>";break;case 0:s[i]="<span>"+n+"</span>"}return s.join("")},s.prototype.diffCommonPrefix=function(t,e){var n,s,i,r;if(!t||!e||t.charAt(0)!==e.charAt(0))return 0;for(i=0,n=s=Math.min(t.length,e.length),r=0;i<n;)t.substring(r,n)===e.substring(r,n)?r=i=n:s=n,n=Math.floor((s-i)/2+i);return n},s.prototype.diffCommonSuffix=function(t,e){var n,s,i,r;if(!t||!e||t.charAt(t.length-1)!==e.charAt(e.length-1))return 0;for(i=0,n=s=Math.min(t.length,e.length),r=0;i<n;)t.substring(t.length-n,t.length-r)===e.substring(e.length-n,e.length-r)?r=i=n:s=n,n=Math.floor((s-i)/2+i);return n},s.prototype.diffCompute=function(t,e,n,s){var i,r,o,a,u;return t?e?(a=t.length>e.length?t:e,i=t.length>e.length?e:t,-1!==(o=a.indexOf(i))?(a=[[1,a.substring(0,o)],[0,i],[1,a.substring(o+i.length)]],t.length>e.length&&(a[0][0]=a[2][0]=-1),a):1===i.length?[[-1,t],[1,e]]:(o=this.diffHalfMatch(t,e))?(a=o[0],i=o[1],u=o[2],r=o[3],o=o[4],a=this.DiffMain(a,u,n,s),u=this.DiffMain(i,r,n,s),a.concat([[0,o]],u)):n&&100<t.length&&100<e.length?this.diffLineMode(t,e,s):this.diffBisect(t,e,s)):[[-1,t]]:[[1,e]]},s.prototype.diffHalfMatch=function(t,e){var f,n,s,i,r,o,a,u;return!(this.DiffTimeout<=0)&&(u=t.length>e.length?t:e,a=t.length>e.length?e:t,!(u.length<4||2*a.length<u.length))&&(f=this,o=l(u,a,Math.ceil(u.length/4)),a=l(u,a,Math.ceil(u.length/2)),o||a)?(u=!a||o&&o[4].length>a[4].length?o:a,t.length>e.length?(n=u[0],r=u[1],i=u[2],s=u[3]):(i=u[0],s=u[1],n=u[2],r=u[3]),[n,r,i,s,u[4]]):null;function l(t,e,n){for(var s,i,r,o,a,u,l=t.substring(n,n+Math.floor(t.length/4)),c=-1,d="";-1!==(c=e.indexOf(l,c+1));)s=f.diffCommonPrefix(t.substring(n),e.substring(c)),i=f.diffCommonSuffix(t.substring(0,n),e.substring(0,c)),d.length<i+s&&(d=e.substring(c-i,c)+e.substring(c,c+s),r=t.substring(0,n-i),o=t.substring(n+s),a=e.substring(0,c-i),u=e.substring(c+s));return 2*d.length>=t.length?[r,o,a,u,d]:null}},s.prototype.diffLineMode=function(t,e,n){var s,i,r,o,a,u,l,c,d=this.diffLinesToChars(t,e);for(t=d.chars1,e=d.chars2,i=d.lineArray,s=this.DiffMain(t,e,!1,n),this.diffCharsToLines(s,i),this.diffCleanupSemantic(s),s.push([0,""]),o=a=r=0,u=l="";r<s.length;){switch(s[r][0]){case 1:o++,u+=s[r][1];break;case-1:a++,l+=s[r][1];break;case 0:if(1<=a&&1<=o){for(s.splice(r-a-o,a+o),r=r-a-o,c=(d=this.DiffMain(l,u,!1,n)).length-1;0<=c;c--)s.splice(r,0,d[c]);r+=d.length}a=o=0,u=l=""}r++}return s.pop(),s},s.prototype.diffBisect=function(t,e,n){for(var s,i,r,o,a,u,l,c,d,f,h,p,m,g,b,v=t.length,y=e.length,w=Math.ceil((v+y)/2),q=w,x=2*w,E=new Array(x),T=new Array(x),C=0;C<x;C++)E[C]=-1,T[C]=-1;for(E[q+1]=0,i=(s=v-y)%2!=(T[q+1]=0),m=u=a=o=r=0;m<w&&!((new Date).getTime()>n);m++){for(g=-m+r;g<=m-o;g+=2){for(c=q+g,h=(d=g===-m||g!==m&&E[c-1]<E[c+1]?E[c+1]:E[c-1]+1)-g;d<v&&h<y&&t.charAt(d)===e.charAt(h);)d++,h++;if(v<(E[c]=d))o+=2;else if(y<h)r+=2;else if(i&&0<=(l=q+s-g)&&l<x&&-1!==T[l]&&(f=v-T[l])<=d)return this.diffBisectSplit(t,e,d,h,n)}for(b=-m+a;b<=m-u;b+=2){for(l=q+b,p=(f=b===-m||b!==m&&T[l-1]<T[l+1]?T[l+1]:T[l-1]+1)-b;f<v&&p<y&&t.charAt(v-f-1)===e.charAt(y-p-1);)f++,p++;if(v<(T[l]=f))u+=2;else if(y<p)a+=2;else if(!i&&0<=(c=q+s-b)&&c<x&&-1!==E[c]&&(h=q+(d=E[c])-c,(f=v-f)<=d))return this.diffBisectSplit(t,e,d,h,n)}}return[[-1,t],[1,e]]},s.prototype.diffBisectSplit=function(t,e,n,s,i){var r=t.substring(0,n),o=e.substring(0,s),t=t.substring(n),n=e.substring(s),e=this.DiffMain(r,o,!1,i),s=this.DiffMain(t,n,!1,i);return e.concat(s)},s.prototype.diffCleanupSemantic=function(t){for(var e,n,s,i,r=!1,o=[],a=0,u=null,l=0,c=0,d=0,f=0,h=0;l<t.length;)0===t[l][0]?(c=f,d=h,h=f=0,u=t[o[a++]=l][1]):(1===t[l][0]?f+=t[l][1].length:h+=t[l][1].length,u&&u.length<=Math.max(c,d)&&u.length<=Math.max(f,h)&&(t.splice(o[a-1],0,[-1,u]),t[o[a-1]+1][0]=1,a--,l=0<--a?o[a-1]:-1,h=f=d=c=0,r=!(u=null))),l++;for(r&&this.diffCleanupMerge(t),l=1;l<t.length;)-1===t[l-1][0]&&1===t[l][0]&&(e=t[l-1][1],n=t[l][1],s=this.diffCommonOverlap(e,n),(i=this.diffCommonOverlap(n,e))<=s?(s>=e.length/2||s>=n.length/2)&&(t.splice(l,0,[0,n.substring(0,s)]),t[l-1][1]=e.substring(0,e.length-s),t[l+1][1]=n.substring(s),l++):(i>=e.length/2||i>=n.length/2)&&(t.splice(l,0,[0,e.substring(0,i)]),t[l-1][0]=1,t[l-1][1]=n.substring(0,n.length-i),t[l+1][0]=-1,t[l+1][1]=e.substring(i),l++),l++),l++},s.prototype.diffCommonOverlap=function(t,e){var n,s,i,r,o=t.length,a=e.length;if(0===o||0===a)return 0;if(a<o?t=t.substring(o-a):o<a&&(e=e.substring(0,o)),n=Math.min(o,a),t===e)return n;for(s=0,i=1;;){if(r=t.substring(n-i),-1===(r=e.indexOf(r)))return s;i+=r,0!==r&&t.substring(n-i)!==e.substring(0,i)||(s=i,i++)}},s.prototype.diffLinesToChars=function(t,e){var o,a;function n(t){for(var e,n="",s=0,i=-1,r=o.length;i<t.length-1;)-1===(i=t.indexOf("\n",s))&&(i=t.length-1),e=t.substring(s,i+1),s=i+1,(a.hasOwnProperty?a.hasOwnProperty(e):void 0!==a[e])?n+=String.fromCharCode(a[e]):(n+=String.fromCharCode(r),a[e]=r,o[r++]=e);return n}return a={},(o=[])[0]="",{chars1:n(t),chars2:n(e),lineArray:o}},s.prototype.diffCharsToLines=function(t,e){for(var n,s,i,r=0;r<t.length;r++){for(n=t[r][1],s=[],i=0;i<n.length;i++)s[i]=e[n.charCodeAt(i)];t[r][1]=s.join("")}},s.prototype.diffCleanupMerge=function(t){var e,n,s,i,r,o,a;for(t.push([0,""]),s=n=e=0,i=r="";e<t.length;)switch(t[e][0]){case 1:s++,i+=t[e][1],e++;break;case-1:n++,r+=t[e][1],e++;break;case 0:1<n+s?(0!==n&&0!==s&&(0!==(o=this.diffCommonPrefix(i,r))&&(0<e-n-s&&0===t[e-n-s-1][0]?t[e-n-s-1][1]+=i.substring(0,o):(t.splice(0,0,[0,i.substring(0,o)]),e++),i=i.substring(o),r=r.substring(o)),0!==(o=this.diffCommonSuffix(i,r)))&&(t[e][1]=i.substring(i.length-o)+t[e][1],i=i.substring(0,i.length-o),r=r.substring(0,r.length-o)),0===n?t.splice(e-s,n+s,[1,i]):0===s?t.splice(e-n,n+s,[-1,r]):t.splice(e-n-s,n+s,[-1,r],[1,i]),e=e-n-s+(n?1:0)+(s?1:0)+1):0!==e&&0===t[e-1][0]?(t[e-1][1]+=t[e][1],t.splice(e,1)):e++,n=s=0,i=r=""}for(""===t[t.length-1][1]&&t.pop(),a=!1,e=1;e<t.length-1;)0===t[e-1][0]&&0===t[e+1][0]&&(t[e][1].substring(t[e][1].length-t[e-1][1].length)===t[e-1][1]?(t[e][1]=t[e-1][1]+t[e][1].substring(0,t[e][1].length-t[e-1][1].length),t[e+1][1]=t[e-1][1]+t[e+1][1],t.splice(e-1,1),a=!0):t[e][1].substring(0,t[e+1][1].length)===t[e+1][1]&&(t[e-1][1]+=t[e+1][1],t[e][1]=t[e][1].substring(t[e+1][1].length)+t[e+1][1],t.splice(e+1,1),a=!0)),e++;a&&this.diffCleanupMerge(t)},function(t,e){var n=new s,t=n.DiffMain(t,e);return n.diffCleanupEfficiency(t),n.diffPrettyHtml(t)}}(),function(){var d,u,o,f;function h(t){return t?(t+="").replace(/['"<>&]/g,function(t){switch(t){case"'":return"&#039;";case'"':return"&quot;";case"<":return"&lt;";case">":return"&gt;";case"&":return"&amp;"}}):""}function a(e,t,n){e.addEventListener?e.addEventListener(t,n,!1):e.attachEvent&&e.attachEvent("on"+t,function(){var t=window.event;t.target||(t.target=t.srcElement||document),n.call(e,t)})}function e(t,e,n){for(var s=t.length;s--;)a(t[s],e,n)}function l(t,e){return 0<=(" "+t.className+" ").indexOf(" "+e+" ")}function p(t,e){l(t,e)||(t.className+=(t.className?" ":"")+e)}function c(t,e){for(var n=" "+t.className+" ";0<=n.indexOf(" "+e+" ");)n=n.replace(" "+e+" "," ");t.className="function"==typeof n.trim?n.trim():n.replace(/^\s+|\s+$/g,"")}function m(t){return o.document&&document.getElementById&&document.getElementById(t)}function n(){var t=this,e={},n="selectedIndex"in t?t.options[t.selectedIndex].value||void 0:t.checked?t.defaultValue||!0:void 0;e[t.name]=n,e=g(e),"hidepassed"===t.name&&"replaceState"in window.history?(d[t.name]=n||!1,(n?p:c)(m("qunit-tests"),"hidepass"),window.history.replaceState(null,"",e)):window.location=e}function g(t){var e,n="?";for(e in t=QUnit.extend(QUnit.extend({},QUnit.urlParams),t))u.call(t,e)&&void 0!==t[e]&&(n+=encodeURIComponent(e),!0!==t[e]&&(n+="="+encodeURIComponent(t[e])),n+="&");return location.protocol+"//"+location.host+location.pathname+n.slice(0,-1)}function i(){var t=m("qunit-modulefilter"),e=m("qunit-filter-input").value,t=t?decodeURIComponent(t.options[t.selectedIndex].value):void 0;window.location=g({module:""===t?void 0:t,filter:""===e?void 0:e,testId:void 0})}function r(){var t=document.createElement("span");return t.innerHTML=function(){for(var t,e,n,s,i=!1,r=d.urlConfig.length,o="",a=0;a<r;a++)if(n=h((e="string"==typeof(e=d.urlConfig[a])?{id:e,label:e}:e).id),s=h(e.tooltip),void 0===d[e.id]&&(d[e.id]=QUnit.urlParams[e.id]),e.value&&"string"!=typeof e.value){if(o+="<label for='qunit-urlconfig-"+n+"' title='"+s+"'>"+e.label+": </label><select id='qunit-urlconfig-"+n+"' name='"+n+"' title='"+s+"'><option></option>",QUnit.is("array",e.value))for(t=0;t<e.value.length;t++)o+="<option value='"+(n=h(e.value[t]))+"'"+(d[e.id]===e.value[t]?(i=!0," selected='selected'"):"")+">"+n+"</option>";else for(t in e.value)u.call(e.value,t)&&(o+="<option value='"+h(t)+"'"+(d[e.id]===t?(i=!0," selected='selected'"):"")+">"+h(e.value[t])+"</option>");d[e.id]&&!i&&(o+="<option value='"+(n=h(d[e.id]))+"' selected='selected' disabled='disabled'>"+n+"</option>"),o+="</select>"}else o+="<input id='qunit-urlconfig-"+n+"' name='"+n+"' type='checkbox'"+(e.value?" value='"+h(e.value)+"'":"")+(d[e.id]?" checked='checked'":"")+" title='"+s+"' /><label for='qunit-urlconfig-"+n+"' title='"+s+"'>"+e.label+"</label>";return o}(),p(t,"qunit-url-config"),e(t.getElementsByTagName("input"),"click",n),e(t.getElementsByTagName("select"),"change",n),t}function b(){var t=m("qunit-testrunner-toolbar"),e=document.createElement("span"),n=function(){var t,e="";if(!f.length)return!1;for(f.sort(function(t,e){return t.localeCompare(e)}),e+="<label for='qunit-modulefilter'>Module: </label><select id='qunit-modulefilter' name='modulefilter'><option value='' "+(void 0===QUnit.urlParams.module?"selected='selected'":"")+">< All Modules ></option>",t=0;t<f.length;t++)e+="<option value='"+h(encodeURIComponent(f[t]))+"' "+(QUnit.urlParams.module===f[t]?"selected='selected'":"")+">"+h(f[t])+"</option>";return e+="</select>"}();t&&n&&(e.setAttribute("id","qunit-modulefilter-container"),e.innerHTML=n,a(e.lastChild,"change",i),t.appendChild(e))}function v(){var t,e,n,s=m("qunit-testrunner-toolbar");s&&(s.appendChild(r()),s.appendChild((s=document.createElement("form"),t=document.createElement("label"),e=document.createElement("input"),n=document.createElement("button"),p(s,"qunit-filter"),t.innerHTML="Filter: ",e.type="text",e.value=d.filter||"",e.name="filter",e.id="qunit-filter-input",n.innerHTML="Go",t.appendChild(e),s.appendChild(t),s.appendChild(n),a(s,"submit",function(t){return i(),t&&t.preventDefault&&t.preventDefault(),!1}),s)))}function y(t,e,n){var s,i=m("qunit-tests");i&&((s=document.createElement("strong")).innerHTML=w(t,n),(t=document.createElement("a")).innerHTML="Rerun",t.href=g({testId:e}),(n=document.createElement("li")).appendChild(s),n.appendChild(t),n.id="qunit-test-output-"+e,(s=document.createElement("ol")).className="qunit-assert-list",n.appendChild(s),i.appendChild(n))}function w(t,e){var n="";return e&&(n="<span class='module-name'>"+h(e)+"</span>: "),n+="<span class='test-name'>"+h(t)+"</span>"}QUnit.init=function(){var t,e,n=QUnit.config;n.stats={all:0,bad:0},n.moduleStats={all:0,bad:0},n.started=0,n.updateRate=1e3,n.blocking=!1,n.autostart=!0,n.autorun=!1,n.filter="",n.queue=[],"undefined"!=typeof window&&((n=m("qunit"))&&(n.innerHTML="<h1 id='qunit-header'>"+h(document.title)+"</h1><h2 id='qunit-banner'></h2><div id='qunit-testrunner-toolbar'></div><h2 id='qunit-userAgent'></h2><ol id='qunit-tests'></ol>"),n=m("qunit-tests"),t=m("qunit-banner"),e=m("qunit-testresult"),n&&(n.innerHTML=""),t&&(t.className=""),e&&e.parentNode.removeChild(e),n)&&((e=document.createElement("p")).id="qunit-testresult",e.className="result",n.parentNode.insertBefore(e,n),e.innerHTML="Running...<br />&#160;")},"undefined"!=typeof window&&(d=QUnit.config,u=Object.prototype.hasOwnProperty,o={document:void 0!==window.document,sessionStorage:function(){var t="qunit-test-string";try{return sessionStorage.setItem(t,t),sessionStorage.removeItem(t),!0}catch(t){return!1}}()},f=[],QUnit.begin(function(t){for(var e,n,s,i,r,o,a=m("qunit"),u=((n=m("qunit-fixture"))&&(d.fixture=n.innerHTML),a&&(a.innerHTML="<h1 id='qunit-header'>"+h(document.title)+"</h1><h2 id='qunit-banner'></h2><div id='qunit-testrunner-toolbar'></div><h2 id='qunit-userAgent'></h2><ol id='qunit-tests'></ol>"),(n=m("qunit-header"))&&(n.innerHTML="<a href='"+g({filter:void 0,module:void 0,testId:void 0})+"'>"+n.innerHTML+"</a> "),(n=m("qunit-banner"))&&(n.className=""),n=m("qunit-tests"),(e=m("qunit-testresult"))&&e.parentNode.removeChild(e),n&&(n.innerHTML="",(e=document.createElement("p")).id="qunit-testresult",e.className="result",n.parentNode.insertBefore(e,n),e.innerHTML="Running...<br />&#160;"),(n=m("qunit-userAgent"))&&(n.innerHTML="",n.appendChild(document.createTextNode("QUnit "+QUnit.version+"; "+navigator.userAgent))),v(),t.modules),l=0,c=u.length;l<c;l++)for((o=u[l]).name&&f.push(o.name),s=0,i=o.tests.length;s<i;s++)y((r=o.tests[s]).name,r.testId,o.name);b(),a&&d.hidepassed&&p(a.lastChild,"hidepass")}),QUnit.done(function(t){var e,n,s=m("qunit-banner"),i=m("qunit-tests"),r=["Tests completed in ",t.runtime," milliseconds.<br />","<span class='passed'>",t.passed,"</span> assertions of <span class='total'>",t.total,"</span> passed, <span class='failed'>",t.failed,"</span> failed."].join("");if(s&&(s.className=t.failed?"qunit-fail":"qunit-pass"),i&&(m("qunit-testresult").innerHTML=r),d.altertitle&&o.document&&document.title&&(document.title=[t.failed?"✖":"✔",document.title.replace(/^[\u2714\u2716] /i,"")].join(" ")),d.reorder&&o.sessionStorage&&0===t.failed)for(e=0;e<sessionStorage.length;e++)0===(n=sessionStorage.key(e++)).indexOf("qunit-test-")&&sessionStorage.removeItem(n);d.scrolltop&&window.scrollTo&&window.scrollTo(0,0)}),QUnit.testStart(function(t){var e,n=m("qunit-test-output-"+t.testId);n?n.className="running":y(t.name,t.testId,t.module),(n=m("qunit-testresult"))&&(e=QUnit.config.reorder&&o.sessionStorage&&+sessionStorage.getItem("qunit-test-"+t.module+"-"+t.name),n.innerHTML=(e?"Rerunning previously failed test: <br />":"Running: <br />")+w(t.name,t.module))}),QUnit.log(function(t){var e,n,s,i=m("qunit-test-output-"+t.testId);i&&(e="<span class='test-message'>"+(e=h(t.message)||(t.result?"okay":"failed"))+"</span>",e+="<span class='runtime'>@ "+t.runtime+" ms</span>",!t.result&&u.call(t,"expected")?(e+="<table><tr class='test-expected'><th>Expected: </th><td><pre>"+(n=h(QUnit.dump.parse(t.expected)))+"</pre></td></tr>",(s=h(QUnit.dump.parse(t.actual)))!==n?e+="<tr class='test-actual'><th>Result: </th><td><pre>"+s+"</pre></td></tr><tr class='test-diff'><th>Diff: </th><td><pre>"+QUnit.diff(n,s)+"</pre></td></tr>":-1===n.indexOf("[object Array]")&&-1===n.indexOf("[object Object]")||(e+="<tr class='test-message'><th>Message: </th><td>Diff suppressed as the depth of object is more than current max depth ("+QUnit.config.maxDepth+").<p>Hint: Use <code>QUnit.dump.maxDepth</code> to  run with a higher max depth or <a href='"+g({maxDepth:-1})+"'>Rerun</a> without max depth.</p></td></tr>"),t.source&&(e+="<tr class='test-source'><th>Source: </th><td><pre>"+h(t.source)+"</pre></td></tr>"),e+="</table>"):!t.result&&t.source&&(e+="<table><tr class='test-source'><th>Source: </th><td><pre>"+h(t.source)+"</pre></td></tr></table>"),s=i.getElementsByTagName("ol")[0],(n=document.createElement("li")).className=t.result?"pass":"fail",n.innerHTML=e,s.appendChild(n))}),QUnit.testDone(function(t){var e,n,s,i,r;m("qunit-tests")&&(n=m("qunit-test-output-"+t.testId),s=n.getElementsByTagName("ol")[0],r=t.passed,i=t.failed,d.reorder&&o.sessionStorage&&(i?sessionStorage.setItem("qunit-test-"+t.module+"-"+t.name,i):sessionStorage.removeItem("qunit-test-"+t.module+"-"+t.name)),0===i&&p(s,"qunit-collapsed"),(e=n.firstChild).innerHTML+=" <b class='counts'>("+(i?"<b class='failed'>"+i+"</b>, <b class='passed'>"+r+"</b>, ":"")+t.assertions.length+")</b>",t.skipped?(n.className="skipped",(r=document.createElement("em")).className="qunit-skipped-label",r.innerHTML="skipped",n.insertBefore(r,e)):(a(e,"click",function(){var t,e;(l(t=s,e="qunit-collapsed")?c:p)(t,e)}),n.className=i?"fail":"pass",(r=document.createElement("span")).className="runtime",r.innerHTML=t.runtime+" ms",n.insertBefore(r,s)))}),o.document?"complete"===document.readyState?QUnit.load():a(window,"load",QUnit.load):(d.pageLoaded=!0,d.autorun=!0))}();