!function(e){var t={};function i(n){if(t[n])return t[n].exports;var a=t[n]={i:n,l:!1,exports:{}};return e[n].call(a.exports,a,a.exports,i),a.l=!0,a.exports}i.m=e,i.c=t,i.d=function(e,t,n){i.o(e,t)||Object.defineProperty(e,t,{configurable:!1,enumerable:!0,get:n})},i.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return i.d(t,"a",t),t},i.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},i.p="",i(i.s=7)}([,,,,,,,function(e,t,i){i(8),i(9),i(10),i(11),e.exports=i(12)},function(e,t){!function(){"use strict";const e=Object.getOwnPropertyDescriptors(HTMLFormElement.prototype),t=HTMLFormElement.prototype.submit;function i(t){var i=(e.target.get.apply(t)||"").toLowerCase();if("_blank"===i){var n=(e.method.get.apply(t)||"GET").toUpperCase();if("POST"===n){var a,r,o=(e.enctype.get.apply(t)||"").toLowerCase();if("application/x-www-form-urlencoded"===o)webkit.messageHandlers.formPostHelper.postMessage({action:e.action.get.apply(t)||window.location.href,method:n,target:i,enctype:o,requestBody:(a=t,r=[],[].slice.apply(a.elements).forEach(function(e){if(!e.disabled&&e.name&&"file"!==e.type){var t=encodeURIComponent(e.name);"select-multiple"===e.type?[].slice.apply(e.options).forEach(function(e){e.selected&&r.push(t+"="+encodeURIComponent(e.value||""))}):("checkbox"!==e.type&&"radio"!==e.type||e.checked)&&r.push(t+"="+encodeURIComponent(e.value||""))}}),r.join("&"))})}}}HTMLFormElement.prototype.submit=function(){return i(this),t.apply(this,arguments)},document.addEventListener("submit",function(e){var t=e.target;"FORM"===t.tagName&&i(t)},!0)}()},function(e,t){!function(){"use strict";var e=window.history.pushState,t=window.history.replaceState;window.history.pushState=function(t,i,n){e.apply(this,arguments),webkit.messageHandlers.historyStateHelper.postMessage({pushState:!0,state:t,title:i,url:n})},window.history.replaceState=function(e,i,n){t.apply(this,arguments),webkit.messageHandlers.historyStateHelper.postMessage({replaceState:!0,state:e,title:i,url:n})}}()},function(e,t){!function(){"use strict";Object.defineProperty(window.__firefox__,"NightMode",{enumerable:!1,configurable:!1,writable:!1,value:{enabled:!1}});const e="brightness(80%) invert(100%) hue-rotate(180deg)",t=`html {\n  -webkit-filter: hue-rotate(180deg) invert(100%) !important;\n}\nimg,video {\n  -webkit-filter: ${e} !important;\n}`;var i;function n(t){t.querySelectorAll('[style*="background"]').forEach(function(t){var i;(t.style.backgroundImage||"").startsWith("url")&&(i=t,r.push(i),i.__firefox__NightMode_originalFilter=i.style.webkitFilter,i.style.webkitFilter=e)})}function a(e){e.style.webkitFilter=e.__firefox__NightMode_originalFilter,delete e.__firefox__NightMode_originalFilter}var r=null,o=new MutationObserver(function(e){e.forEach(function(e){e.addedNodes.forEach(function(e){e.nodeType===Node.ELEMENT_NODE&&n(e)})})});Object.defineProperty(window.__firefox__.NightMode,"setEnabled",{enumerable:!1,configurable:!1,writable:!1,value:function(e){if(e!==window.__firefox__.NightMode.enabled){window.__firefox__.NightMode.enabled=e;var s=i||((i=document.createElement("style")).type="text/css",i.appendChild(document.createTextNode(t)),i);if(e)return r=[],document.documentElement.appendChild(s),n(document),void o.observe(document.documentElement,{childList:!0,subtree:!0});o.disconnect(),r.forEach(a);var l=s.parentNode;l&&l.removeChild(s),r=null}}})}()},function(e,t){!function(){"use strict";Object.defineProperty(window.__firefox__,"NoImageMode",{enumerable:!1,configurable:!1,writable:!1,value:{enabled:!1}});var e="__firefox__NoImageMode";Object.defineProperty(window.__firefox__.NoImageMode,"setEnabled",{enumerable:!1,configurable:!1,writable:!1,value:function(t){if(t!==window.__firefox__.NoImageMode.enabled)if(window.__firefox__.NoImageMode.enabled=t,t)!function(){var t="*{background-image:none !important;}img,iframe{visibility:hidden !important;}",i=document.getElementById(e);if(i)i.innerHTML=t;else{var n=document.createElement("style");n.type="text/css",n.id=e,n.appendChild(document.createTextNode(t)),document.documentElement.appendChild(n)}}();else{var i=document.getElementById(e);i&&i.remove(),[].slice.apply(document.getElementsByTagName("img")).forEach(function(e){var t=e.src;e.src="",e.src=t}),[].slice.apply(document.querySelectorAll('[style*="background"]')).forEach(function(e){var t=e.style.backgroundImage;e.style.backgroundImage="none",e.style.backgroundImage=t}),[].slice.apply(document.styleSheets).forEach(function(e){[].slice.apply(e.rules||[]).forEach(function(e){var t=e.style;if(t){var i=t.backgroundImage;t.backgroundImage="none",t.backgroundImage=i}})})}}}),window.addEventListener("DOMContentLoaded",function(e){window.__firefox__.NoImageMode.setEnabled(window.__firefox__.NoImageMode.enabled)})}()},function(e,t,i){!function(){"use strict";const e=!1;var t=null,n=null,a=/^http:\/\/localhost:\d+\/reader-mode\/page/,r=".content p > img:only-child, .content p > a:only-child > img:only-child, .content .wp-caption img, .content figure img";function o(t){e&&console.log(t)}function s(e){null!=n&&document.body.classList.remove(n.theme),document.body.classList.add(e.theme),null!=n&&document.body.classList.remove("font-size"+n.fontSize),document.body.classList.add("font-size"+e.fontSize),null!=n&&document.body.classList.remove(n.fontType),document.body.classList.add(e.fontType),n=e}function l(){s(JSON.parse(document.body.getAttribute("data-readerStyle"))),document.getElementById("reader-message").style.display="none",document.getElementById("reader-header").style.display="block",document.getElementById("reader-content").style.display="block",function(){for(var e=document.getElementById("reader-content"),t=window.innerWidth,i=e.offsetWidth,n=t+"px !important",a=function(e){e._originalWidth||(e._originalWidth=e.offsetWidth);var a=e._originalWidth;a<i&&a>.55*t&&(a=t);var r=Math.max((i-t)/2,(i-a)/2)+"px !important",o="max-width: "+n+";width: "+a+"px !important;margin-left: "+r+";margin-right: "+r+";";e.style.cssText=o},o=document.querySelectorAll(r),s=o.length;--s>=0;){var l=o[s];l.width>0?a(l):l.onload=function(){a(l)}}}()}Object.defineProperty(window.__firefox__,"reader",{enumerable:!1,configurable:!1,writable:!1,value:Object.freeze({checkReadability:function(){if(document.location.href.match(a))return o({Type:"ReaderModeStateChange",Value:"Active"}),void webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:"Active"});if(("http:"===document.location.protocol||"https:"===document.location.protocol)&&"/"!==document.location.pathname){if(t&&t.content)return o({Type:"ReaderModeStateChange",Value:"Available"}),void webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:"Available"});var e=i(13),n={spec:document.location.href,host:document.location.host,prePath:document.location.protocol+"//"+document.location.host,scheme:document.location.protocol.substr(0,document.location.protocol.indexOf(":")),pathBase:document.location.protocol+"//"+document.location.host+location.pathname.substr(0,location.pathname.lastIndexOf("/")+1)},r=(new XMLSerializer).serializeToString(document),s=new e(n,(new DOMParser).parseFromString(r,"text/html"));return o({Type:"ReaderModeStateChange",Value:null!==(t=s.parse())?"Available":"Unavailable"}),void webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:null!==t?"Available":"Unavailable"})}o({Type:"ReaderModeStateChange",Value:"Unavailable"}),webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:"Unavailable"})},readerize:function(){return t},setStyle:s})}),window.addEventListener("load",function(e){document.location.href.match(a)&&l()}),window.addEventListener("pageshow",function(e){document.location.href.match(a)&&webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderPageEvent",Value:"PageShow"})})}()},function(e,t,i){function n(e,t,i){var n;i=i||{},this._uri=e,this._doc=t,this._articleTitle=null,this._articleByline=null,this._articleDir=null,this._debug=!!i.debug,this._maxElemsToParse=i.maxElemsToParse||this.DEFAULT_MAX_ELEMS_TO_PARSE,this._nbTopCandidates=i.nbTopCandidates||this.DEFAULT_N_TOP_CANDIDATES,this._wordThreshold=i.wordThreshold||this.DEFAULT_WORD_THRESHOLD,this._classesToPreserve=this.CLASSES_TO_PRESERVE.concat(i.classesToPreserve||[]),this._flags=this.FLAG_STRIP_UNLIKELYS|this.FLAG_WEIGHT_CLASSES|this.FLAG_CLEAN_CONDITIONALLY,this._debug?(n=function(e){var t=e.nodeName+" ";if(e.nodeType==e.TEXT_NODE)return t+'("'+e.textContent+'")';var i=e.className&&"."+e.className.replace(/ /g,"."),n="";return e.id?n="(#"+e.id+i+")":i&&(n="("+i+")"),t+n},this.log=function(){if("undefined"!=typeof dump){var e=Array.prototype.map.call(arguments,function(e){return e&&e.nodeName?n(e):e}).join(" ");dump("Reader: (Readability) "+e+"\n")}else if("undefined"!=typeof console){var t=["Reader: (Readability) "].concat(arguments);console.log.apply(console,t)}}):this.log=function(){}}n.prototype={FLAG_STRIP_UNLIKELYS:1,FLAG_WEIGHT_CLASSES:2,FLAG_CLEAN_CONDITIONALLY:4,DEFAULT_MAX_ELEMS_TO_PARSE:0,DEFAULT_N_TOP_CANDIDATES:5,DEFAULT_TAGS_TO_SCORE:"section,h2,h3,h4,h5,h6,p,td,pre".toUpperCase().split(","),DEFAULT_WORD_THRESHOLD:500,REGEXPS:{unlikelyCandidates:/banner|breadcrumbs|combx|comment|community|cover-wrap|disqus|extra|foot|header|legends|menu|related|remark|replies|rss|shoutbox|sidebar|skyscraper|social|sponsor|supplemental|ad-break|agegate|pagination|pager|popup|yom-remote/i,okMaybeItsACandidate:/and|article|body|column|main|shadow/i,positive:/article|body|content|entry|hentry|h-entry|main|page|pagination|post|text|blog|story/i,negative:/hidden|^hid$| hid$| hid |^hid |banner|combx|comment|com-|contact|foot|footer|footnote|masthead|media|meta|outbrain|promo|related|scroll|share|shoutbox|sidebar|skyscraper|sponsor|shopping|tags|tool|widget/i,extraneous:/print|archive|comment|discuss|e[\-]?mail|share|reply|all|login|sign|single|utility/i,byline:/byline|author|dateline|writtenby|p-author/i,replaceFonts:/<(\/?)font[^>]*>/gi,normalize:/\s{2,}/g,videos:/\/\/(www\.)?(dailymotion|youtube|youtube-nocookie|player\.vimeo)\.com/i,nextLink:/(next|weiter|continue|>([^\|]|$)|»([^\|]|$))/i,prevLink:/(prev|earl|old|new|<|«)/i,whitespace:/^\s*$/,hasContent:/\S$/},DIV_TO_P_ELEMS:["A","BLOCKQUOTE","DL","DIV","IMG","OL","P","PRE","TABLE","UL","SELECT"],ALTER_TO_DIV_EXCEPTIONS:["DIV","ARTICLE","SECTION","P"],PRESENTATIONAL_ATTRIBUTES:["align","background","bgcolor","border","cellpadding","cellspacing","frame","hspace","rules","style","valign","vspace"],DEPRECATED_SIZE_ATTRIBUTE_ELEMS:["TABLE","TH","TD","HR","PRE"],CLASSES_TO_PRESERVE:["readability-styled","page"],_postProcessContent:function(e){this._fixRelativeUris(e),this._cleanClasses(e)},_removeNodes:function(e,t){for(var i=e.length-1;i>=0;i--){var n=e[i],a=n.parentNode;a&&(t&&!t.call(this,n,i,e)||a.removeChild(n))}},_replaceNodeTags:function(e,t){for(var i=e.length-1;i>=0;i--){var n=e[i];this._setNodeTag(n,t)}},_forEachNode:function(e,t){Array.prototype.forEach.call(e,t,this)},_someNode:function(e,t){return Array.prototype.some.call(e,t,this)},_concatNodeLists:function(){var e=Array.prototype.slice,t=e.call(arguments).map(function(t){return e.call(t)});return Array.prototype.concat.apply([],t)},_getAllNodesWithTag:function(e,t){return e.querySelectorAll?e.querySelectorAll(t.join(",")):[].concat.apply([],t.map(function(t){var i=e.getElementsByTagName(t);return Array.isArray(i)?i:Array.from(i)}))},_cleanClasses:function(e){var t=this._classesToPreserve,i=(e.getAttribute("class")||"").split(/\s+/).filter(function(e){return-1!=t.indexOf(e)}).join(" ");for(i?e.setAttribute("class",i):e.removeAttribute("class"),e=e.firstElementChild;e;e=e.nextElementSibling)this._cleanClasses(e)},_fixRelativeUris:function(e){var t=this._uri.scheme,i=this._uri.prePath,n=this._uri.pathBase;function a(e){return/^[a-zA-Z][a-zA-Z0-9\+\-\.]*:/.test(e)?e:"//"==e.substr(0,2)?t+"://"+e.substr(2):"/"==e[0]?i+e:0===e.indexOf("./")?n+e.slice(2):"#"==e[0]?e:n+e}var r=e.getElementsByTagName("a");this._forEachNode(r,function(e){var t=e.getAttribute("href");if(t)if(0===t.indexOf("javascript:")){var i=this._doc.createTextNode(e.textContent);e.parentNode.replaceChild(i,e)}else e.setAttribute("href",a(t))});var o=e.getElementsByTagName("img");this._forEachNode(o,function(e){var t=e.getAttribute("src");t&&e.setAttribute("src",a(t))})},_getArticleTitle:function(){var e=this._doc,t="",i="";try{"string"!=typeof(t=i=e.title)&&(t=i=this._getInnerText(e.getElementsByTagName("title")[0]))}catch(e){}var n=!1;function a(e){return e.split(/\s+/).length}if(/ [\|\-\\\/>»] /.test(t))n=/ [\\\/>»] /.test(t),a(t=i.replace(/(.*)[\|\-\\\/>»] .*/gi,"$1"))<3&&(t=i.replace(/[^\|\-\\\/>»]*[\|\-\\\/>»](.*)/gi,"$1"));else if(-1!==t.indexOf(": ")){var r=this._concatNodeLists(e.getElementsByTagName("h1"),e.getElementsByTagName("h2"));this._someNode(r,function(e){return e.textContent===t})||(a(t=i.substring(i.lastIndexOf(":")+1))<3?t=i.substring(i.indexOf(":")+1):a(i.substr(0,i.indexOf(":")))>5&&(t=i))}else if(t.length>150||t.length<15){var o=e.getElementsByTagName("h1");1===o.length&&(t=this._getInnerText(o[0]))}var s=a(t=t.trim());return s<=4&&(!n||s!=a(i.replace(/[\|\-\\\/>»]+/g,""))-1)&&(t=i),t},_prepDocument:function(){var e=this._doc;this._removeNodes(e.getElementsByTagName("style")),e.body&&this._replaceBrs(e.body),this._replaceNodeTags(e.getElementsByTagName("font"),"SPAN")},_nextElement:function(e){for(var t=e;t&&t.nodeType!=Node.ELEMENT_NODE&&this.REGEXPS.whitespace.test(t.textContent);)t=t.nextSibling;return t},_replaceBrs:function(e){this._forEachNode(this._getAllNodesWithTag(e,["br"]),function(e){for(var t=e.nextSibling,i=!1;(t=this._nextElement(t))&&"BR"==t.tagName;){i=!0;var n=t.nextSibling;t.parentNode.removeChild(t),t=n}if(i){var a=this._doc.createElement("p");for(e.parentNode.replaceChild(a,e),t=a.nextSibling;t;){if("BR"==t.tagName){var r=this._nextElement(t);if(r&&"BR"==r.tagName)break}var o=t.nextSibling;a.appendChild(t),t=o}}})},_setNodeTag:function(e,t){if(this.log("_setNodeTag",e,t),e.__JSDOMParser__)return e.localName=t.toLowerCase(),e.tagName=t.toUpperCase(),e;for(var i=e.ownerDocument.createElement(t);e.firstChild;)i.appendChild(e.firstChild);e.parentNode.replaceChild(i,e),e.readability&&(i.readability=e.readability);for(var n=0;n<e.attributes.length;n++)i.setAttribute(e.attributes[n].name,e.attributes[n].value);return i},_prepArticle:function(e){this._cleanStyles(e),this._markDataTables(e),this._cleanConditionally(e,"form"),this._cleanConditionally(e,"fieldset"),this._clean(e,"object"),this._clean(e,"embed"),this._clean(e,"h1"),this._clean(e,"footer"),this._forEachNode(e.children,function(e){this._cleanMatchedNodes(e,/share/)});var t=e.getElementsByTagName("h2");if(1===t.length){var i=(t[0].textContent.length-this._articleTitle.length)/this._articleTitle.length;if(Math.abs(i)<.5){(i>0?t[0].textContent.includes(this._articleTitle):this._articleTitle.includes(t[0].textContent))&&this._clean(e,"h2")}}this._clean(e,"iframe"),this._clean(e,"input"),this._clean(e,"textarea"),this._clean(e,"select"),this._clean(e,"button"),this._cleanHeaders(e),this._cleanConditionally(e,"table"),this._cleanConditionally(e,"ul"),this._cleanConditionally(e,"div"),this._removeNodes(e.getElementsByTagName("p"),function(e){return 0===e.getElementsByTagName("img").length+e.getElementsByTagName("embed").length+e.getElementsByTagName("object").length+e.getElementsByTagName("iframe").length&&!this._getInnerText(e,!1)}),this._forEachNode(this._getAllNodesWithTag(e,["br"]),function(e){var t=this._nextElement(e.nextSibling);t&&"P"==t.tagName&&e.parentNode.removeChild(e)})},_initializeNode:function(e){switch(e.readability={contentScore:0},e.tagName){case"DIV":e.readability.contentScore+=5;break;case"PRE":case"TD":case"BLOCKQUOTE":e.readability.contentScore+=3;break;case"ADDRESS":case"OL":case"UL":case"DL":case"DD":case"DT":case"LI":case"FORM":e.readability.contentScore-=3;break;case"H1":case"H2":case"H3":case"H4":case"H5":case"H6":case"TH":e.readability.contentScore-=5}e.readability.contentScore+=this._getClassWeight(e)},_removeAndGetNext:function(e){var t=this._getNextNode(e,!0);return e.parentNode.removeChild(e),t},_getNextNode:function(e,t){if(!t&&e.firstElementChild)return e.firstElementChild;if(e.nextElementSibling)return e.nextElementSibling;do{e=e.parentNode}while(e&&!e.nextElementSibling);return e&&e.nextElementSibling},_getNextNodeNoElementProperties:function(e,t){function i(e){do{e=e.nextSibling}while(e&&e.nodeType!==e.ELEMENT_NODE);return e}if(!t&&e.children[0])return e.children[0];var n=i(e);if(n)return n;do{(e=e.parentNode)&&(n=i(e))}while(e&&!n);return e&&n},_checkByline:function(e,t){if(this._articleByline)return!1;if(void 0!==e.getAttribute)var i=e.getAttribute("rel");return!("author"!==i&&!this.REGEXPS.byline.test(t)||!this._isValidByline(e.textContent))&&(this._articleByline=e.textContent.trim(),!0)},_getNodeAncestors:function(e,t){t=t||0;for(var i=0,n=[];e.parentNode&&(n.push(e.parentNode),!t||++i!==t);)e=e.parentNode;return n},_grabArticle:function(e){this.log("**** grabArticle ****");var t=this._doc,i=null!==e;if(!(e=e||this._doc.body))return this.log("No body found in document. Abort."),null;for(var n=e.innerHTML;;){for(var a=this._flagIsActive(this.FLAG_STRIP_UNLIKELYS),r=[],o=this._doc.documentElement;o;){var s=o.className+" "+o.id;if(this._checkByline(o,s))o=this._removeAndGetNext(o);else if(a&&this.REGEXPS.unlikelyCandidates.test(s)&&!this.REGEXPS.okMaybeItsACandidate.test(s)&&"BODY"!==o.tagName&&"A"!==o.tagName)this.log("Removing unlikely candidate - "+s),o=this._removeAndGetNext(o);else if("DIV"!==o.tagName&&"SECTION"!==o.tagName&&"HEADER"!==o.tagName&&"H1"!==o.tagName&&"H2"!==o.tagName&&"H3"!==o.tagName&&"H4"!==o.tagName&&"H5"!==o.tagName&&"H6"!==o.tagName||!this._isElementWithoutContent(o)){if(-1!==this.DEFAULT_TAGS_TO_SCORE.indexOf(o.tagName)&&r.push(o),"DIV"===o.tagName)if(this._hasSinglePInsideElement(o)){var l=o.children[0];o.parentNode.replaceChild(l,o),o=l,r.push(o)}else this._hasChildBlockElement(o)?this._forEachNode(o.childNodes,function(e){if(e.nodeType===Node.TEXT_NODE&&e.textContent.trim().length>0){var i=t.createElement("p");i.textContent=e.textContent,i.style.display="inline",i.className="readability-styled",o.replaceChild(i,e)}}):(o=this._setNodeTag(o,"P"),r.push(o));o=this._getNextNode(o)}else o=this._removeAndGetNext(o)}var c=[];this._forEachNode(r,function(e){if(e.parentNode&&void 0!==e.parentNode.tagName){var t=this._getInnerText(e);if(!(t.length<25)){var i=this._getNodeAncestors(e,3);if(0!==i.length){var n=0;n+=1,n+=t.split(",").length,n+=Math.min(Math.floor(t.length/100),3),this._forEachNode(i,function(e,t){if(e.tagName){if(void 0===e.readability&&(this._initializeNode(e),c.push(e)),0===t)var i=1;else i=1===t?2:3*t;e.readability.contentScore+=n/i}})}}}});for(var d=[],h=0,g=c.length;h<g;h+=1){var u=c[h],m=u.readability.contentScore*(1-this._getLinkDensity(u));u.readability.contentScore=m,this.log("Candidate:",u,"with score "+m);for(var f=0;f<this._nbTopCandidates;f++){var _=d[f];if(!_||m>_.readability.contentScore){d.splice(f,0,u),d.length>this._nbTopCandidates&&d.pop();break}}}var p,b=d[0]||null,y=!1;if(null===b||"BODY"===b.tagName){b=t.createElement("DIV"),y=!0;for(var N=e.childNodes;N.length;)this.log("Moving child out:",N[0]),b.appendChild(N[0]);e.appendChild(b),this._initializeNode(b)}else if(b){for(var E=[],v=1;v<d.length;v++)d[v].readability.contentScore/b.readability.contentScore>=.75&&E.push(this._getNodeAncestors(d[v]));if(E.length>=3)for(p=b.parentNode;"BODY"!==p.tagName;){for(var T=0,A=0;A<E.length&&T<3;A++)T+=Number(E[A].includes(p));if(T>=3){b=p;break}p=p.parentNode}b.readability||this._initializeNode(b),p=b.parentNode;for(var S=b.readability.contentScore,C=S/3;"BODY"!==p.tagName;)if(p.readability){var x=p.readability.contentScore;if(x<C)break;if(x>S){b=p;break}S=p.readability.contentScore,p=p.parentNode}else p=p.parentNode;for(p=b.parentNode;"BODY"!=p.tagName&&1==p.children.length;)p=(b=p).parentNode;b.readability||this._initializeNode(b)}var L=t.createElement("DIV");i&&(L.id="readability-content");for(var w=Math.max(10,.2*b.readability.contentScore),I=(p=b.parentNode).children,M=0,O=I.length;M<O;M++){var D=I[M],R=!1;if(this.log("Looking at sibling node:",D,D.readability?"with score "+D.readability.contentScore:""),this.log("Sibling has score",D.readability?D.readability.contentScore:"Unknown"),D===b)R=!0;else{var B=0;if(D.className===b.className&&""!==b.className&&(B+=.2*b.readability.contentScore),D.readability&&D.readability.contentScore+B>=w)R=!0;else if("P"===D.nodeName){var P=this._getLinkDensity(D),k=this._getInnerText(D),H=k.length;H>80&&P<.25?R=!0:H<80&&H>0&&0===P&&-1!==k.search(/\.( |$)/)&&(R=!0)}}R&&(this.log("Appending node:",D),-1===this.ALTER_TO_DIV_EXCEPTIONS.indexOf(D.nodeName)&&(this.log("Altering sibling:",D,"to div."),D=this._setNodeTag(D,"DIV")),L.appendChild(D),M-=1,O-=1)}if(this._debug&&this.log("Article content pre-prep: "+L.innerHTML),this._prepArticle(L),this._debug&&this.log("Article content post-prep: "+L.innerHTML),y)b.id="readability-page-1",b.className="page";else{var G=t.createElement("DIV");G.id="readability-page-1",G.className="page";for(var F=L.childNodes;F.length;)G.appendChild(F[0]);L.appendChild(G)}if(this._debug&&this.log("Article content after paging: "+L.innerHTML),!(this._getInnerText(L,!0).length<this._wordThreshold)){var U=[p,b].concat(this._getNodeAncestors(p));return this._someNode(U,function(e){if(!e.tagName)return!1;var t=e.getAttribute("dir");return!!t&&(this._articleDir=t,!0)}),L}if(e.innerHTML=n,this._flagIsActive(this.FLAG_STRIP_UNLIKELYS))this._removeFlag(this.FLAG_STRIP_UNLIKELYS);else if(this._flagIsActive(this.FLAG_WEIGHT_CLASSES))this._removeFlag(this.FLAG_WEIGHT_CLASSES);else{if(!this._flagIsActive(this.FLAG_CLEAN_CONDITIONALLY))return null;this._removeFlag(this.FLAG_CLEAN_CONDITIONALLY)}}},_isValidByline:function(e){return("string"==typeof e||e instanceof String)&&((e=e.trim()).length>0&&e.length<100)},_getArticleMetadata:function(){var e={},t={},i=this._doc.getElementsByTagName("meta"),n=/^\s*((twitter)\s*:\s*)?(description|title)\s*$/gi,a=/^\s*og\s*:\s*(description|title)\s*$/gi;return this._forEachNode(i,function(i){var r=i.getAttribute("name"),o=i.getAttribute("property");if(-1===[r,o].indexOf("author")){var s=null;if(n.test(r)?s=r:a.test(o)&&(s=o),s){var l=i.getAttribute("content");l&&(s=s.toLowerCase().replace(/\s/g,""),t[s]=l.trim())}}else e.byline=i.getAttribute("content")}),"description"in t?e.excerpt=t.description:"og:description"in t?e.excerpt=t["og:description"]:"twitter:description"in t&&(e.excerpt=t["twitter:description"]),e.title=this._getArticleTitle(),e.title||("og:title"in t?e.title=t["og:title"]:"twitter:title"in t&&(e.title=t["twitter:title"])),e},_removeScripts:function(e){this._removeNodes(e.getElementsByTagName("script"),function(e){return e.nodeValue="",e.removeAttribute("src"),!0}),this._removeNodes(e.getElementsByTagName("noscript"))},_hasSinglePInsideElement:function(e){return 1==e.children.length&&"P"===e.children[0].tagName&&!this._someNode(e.childNodes,function(e){return e.nodeType===Node.TEXT_NODE&&this.REGEXPS.hasContent.test(e.textContent)})},_isElementWithoutContent:function(e){return e.nodeType===Node.ELEMENT_NODE&&0==e.textContent.trim().length&&(0==e.children.length||e.children.length==e.getElementsByTagName("br").length+e.getElementsByTagName("hr").length)},_hasChildBlockElement:function(e){return this._someNode(e.childNodes,function(e){return-1!==this.DIV_TO_P_ELEMS.indexOf(e.tagName)||this._hasChildBlockElement(e)})},_getInnerText:function(e,t){t=void 0===t||t;var i=e.textContent.trim();return t?i.replace(this.REGEXPS.normalize," "):i},_getCharCount:function(e,t){return t=t||",",this._getInnerText(e).split(t).length-1},_cleanStyles:function(e){if(e&&"svg"!==e.tagName.toLowerCase()){if("readability-styled"!==e.className){for(var t=0;t<this.PRESENTATIONAL_ATTRIBUTES.length;t++)e.removeAttribute(this.PRESENTATIONAL_ATTRIBUTES[t]);-1!==this.DEPRECATED_SIZE_ATTRIBUTE_ELEMS.indexOf(e.tagName)&&(e.removeAttribute("width"),e.removeAttribute("height"))}for(var i=e.firstElementChild;null!==i;)this._cleanStyles(i),i=i.nextElementSibling}},_getLinkDensity:function(e){var t=this._getInnerText(e).length;if(0===t)return 0;var i=0;return this._forEachNode(e.getElementsByTagName("a"),function(e){i+=this._getInnerText(e).length}),i/t},_getClassWeight:function(e){if(!this._flagIsActive(this.FLAG_WEIGHT_CLASSES))return 0;var t=0;return"string"==typeof e.className&&""!==e.className&&(this.REGEXPS.negative.test(e.className)&&(t-=25),this.REGEXPS.positive.test(e.className)&&(t+=25)),"string"==typeof e.id&&""!==e.id&&(this.REGEXPS.negative.test(e.id)&&(t-=25),this.REGEXPS.positive.test(e.id)&&(t+=25)),t},_clean:function(e,t){var i=-1!==["object","embed","iframe"].indexOf(t);this._removeNodes(e.getElementsByTagName(t),function(e){if(i){var t=[].map.call(e.attributes,function(e){return e.value}).join("|");if(this.REGEXPS.videos.test(t))return!1;if(this.REGEXPS.videos.test(e.innerHTML))return!1}return!0})},_hasAncestorTag:function(e,t,i,n){i=i||3,t=t.toUpperCase();for(var a=0;e.parentNode;){if(i>0&&a>i)return!1;if(e.parentNode.tagName===t&&(!n||n(e.parentNode)))return!0;e=e.parentNode,a++}return!1},_getRowAndColumnCount:function(e){for(var t=0,i=0,n=e.getElementsByTagName("tr"),a=0;a<n.length;a++){var r=n[a].getAttribute("rowspan")||0;r&&(r=parseInt(r,10)),t+=r||1;for(var o=0,s=n[a].getElementsByTagName("td"),l=0;l<s.length;l++){var c=s[l].getAttribute("colspan")||0;c&&(c=parseInt(c,10)),o+=c||1}i=Math.max(i,o)}return{rows:t,columns:i}},_markDataTables:function(e){for(var t=e.getElementsByTagName("table"),i=0;i<t.length;i++){var n=t[i];if("presentation"!=n.getAttribute("role"))if("0"!=n.getAttribute("datatable"))if(n.getAttribute("summary"))n._readabilityDataTable=!0;else{var a=n.getElementsByTagName("caption")[0];if(a&&a.childNodes.length>0)n._readabilityDataTable=!0;else{if(["col","colgroup","tfoot","thead","th"].some(function(e){return!!n.getElementsByTagName(e)[0]}))this.log("Data table because found data-y descendant"),n._readabilityDataTable=!0;else if(n.getElementsByTagName("table")[0])n._readabilityDataTable=!1;else{var r=this._getRowAndColumnCount(n);r.rows>=10||r.columns>4?n._readabilityDataTable=!0:n._readabilityDataTable=r.rows*r.columns>10}}}else n._readabilityDataTable=!1;else n._readabilityDataTable=!1}},_cleanConditionally:function(e,t){if(this._flagIsActive(this.FLAG_CLEAN_CONDITIONALLY)){var i="ul"===t||"ol"===t;this._removeNodes(e.getElementsByTagName(t),function(e){if(this._hasAncestorTag(e,"table",-1,function(e){return e._readabilityDataTable}))return!1;var t=this._getClassWeight(e);if(this.log("Cleaning Conditionally",e),t+0<0)return!0;if(this._getCharCount(e,",")<10){for(var n=e.getElementsByTagName("p").length,a=e.getElementsByTagName("img").length,r=e.getElementsByTagName("li").length-100,o=e.getElementsByTagName("input").length,s=0,l=e.getElementsByTagName("embed"),c=0,d=l.length;c<d;c+=1)this.REGEXPS.videos.test(l[c].src)||(s+=1);var h=this._getLinkDensity(e),g=this._getInnerText(e).length;return a>1&&n/a<.5&&!this._hasAncestorTag(e,"figure")||!i&&r>n||o>Math.floor(n/3)||!i&&g<25&&(0===a||a>2)&&!this._hasAncestorTag(e,"figure")||!i&&t<25&&h>.2||t>=25&&h>.5||1===s&&g<75||s>1}return!1})}},_cleanMatchedNodes:function(e,t){for(var i=this._getNextNode(e,!0),n=this._getNextNode(e);n&&n!=i;)n=t.test(n.className+" "+n.id)?this._removeAndGetNext(n):this._getNextNode(n)},_cleanHeaders:function(e){for(var t=1;t<3;t+=1)this._removeNodes(e.getElementsByTagName("h"+t),function(e){return this._getClassWeight(e)<0})},_flagIsActive:function(e){return(this._flags&e)>0},_removeFlag:function(e){this._flags=this._flags&~e},isProbablyReaderable:function(e){var t=this._getAllNodesWithTag(this._doc,["p","pre"]),i=this._getAllNodesWithTag(this._doc,["div > br"]);if(i.length){var n=new Set;[].forEach.call(i,function(e){n.add(e.parentNode)}),t=[].concat.apply(Array.from(n),t)}var a=0;return this._someNode(t,function(t){if(e&&!e(t))return!1;var i=t.className+" "+t.id;if(this.REGEXPS.unlikelyCandidates.test(i)&&!this.REGEXPS.okMaybeItsACandidate.test(i))return!1;if(t.matches&&t.matches("li p"))return!1;var n=t.textContent.trim().length;return!(n<140)&&(a+=Math.sqrt(n-140))>20})},parse:function(){if(this._maxElemsToParse>0){var e=this._doc.getElementsByTagName("*").length;if(e>this._maxElemsToParse)throw new Error("Aborting parsing document; "+e+" elements found")}void 0===this._doc.documentElement.firstElementChild&&(this._getNextNode=this._getNextNodeNoElementProperties),this._removeScripts(this._doc),this._prepDocument();var t=this._getArticleMetadata();this._articleTitle=t.title;var i=this._grabArticle();if(!i)return null;if(this.log("Grabbed: "+i.innerHTML),this._postProcessContent(i),!t.excerpt){var n=i.getElementsByTagName("p");n.length>0&&(t.excerpt=n[0].textContent.trim())}var a=i.textContent;return{uri:this._uri,title:this._articleTitle,byline:t.byline||this._articleByline,dir:this._articleDir,content:i.innerHTML,textContent:a,length:a.length,excerpt:t.excerpt}}},e.exports=n}]);