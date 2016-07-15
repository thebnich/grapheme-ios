/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function () {

'use strict';

if (document.location.protocol === "about:") {
  console.log("reader mode; don't parse");
  return;
}

var uri = {
  spec: document.location.href,
  host: document.location.host,
  prePath: document.location.origin,
  scheme: document.location.protocol.substr(0, document.location.protocol.indexOf(":")),
  pathBase: document.location.origin + location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1)
};

// document.cloneNode() can cause the webview to break (bug 1128774).
// Serialize and then parse the document instead.
var docStr = new XMLSerializer().serializeToString(document);
var doc = new DOMParser().parseFromString(docStr, "text/html");
var readability = new Readability(uri, doc);
var result = readability.parse();

var text = document.body.innerText.replace(/\s+/g, ' ');

webkit.messageHandlers.readerHandler.postMessage({
  doc: result.content,
  text: text,
  title: result.title,
  byline: result.byline,
});

}) ();
