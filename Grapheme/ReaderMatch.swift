/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReaderMatch {
    let title: String
    let byline: String?
    let URL: NSURL
    let doc: String
    let snippet: String

    init(URL: NSURL, doc: String, title: String, byline: String?, snippet: String) {
        self.URL = URL
        self.doc = doc
        self.title = title
        self.byline = byline
        self.snippet = snippet
    }
}