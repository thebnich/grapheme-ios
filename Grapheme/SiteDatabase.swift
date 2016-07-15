/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CouchbaseLite

class SiteDatabase {
    static let sharedInstance = SiteDatabase()

    let manager: CBLManager
    let database: CBLDatabase
    let viewSiteText: CBLView
    let viewURLs: CBLView

    init() {
        manager = CBLManager.sharedInstance()
        try! database = manager.databaseNamed("sites")

        viewSiteText = database.viewNamed("bodies")
        viewSiteText.setMapBlock({ doc, emit in
            guard let text = doc["text"] as? String else { return }
            emit(CBLTextKey(text), nil)
        }, version: "1")

        viewURLs = database.viewNamed("URLs")
        viewURLs.setMapBlock({ doc, emit in
            guard let URL = doc["url"] as? String else { return }
            emit(URL, nil)
        }, version: "1")
    }

    func addPage(URL: NSURL, doc: String, text: String, title: String, byline: String?) {
        var props = [
            "url": URL.absoluteString,
            "doc": doc,
            "text": text,
            "title": title,
        ]

        props["byline"] = byline

        let doc = database.createDocument()
        try! doc.putProperties(props)
    }

    func findSites(search: String, callback: [ReaderMatch] -> ()) {
        let query = viewSiteText.createQuery()
        query.fullTextQuery = "\(search)*"
        query.fullTextSnippets = true
        query.runAsync() { rows, error in
            callback(rows.flatMap { row in
                guard let row = row as? CBLFullTextQueryRow,
                      let document = row.document,
                      let URLString = document.userProperties!["url"] as? String,
                      let URL = NSURL(string: URLString),
                      let doc = document.userProperties!["doc"] as? String,
                      let title = document.userProperties!["title"] as? String else {
                    return nil
                }

                let byline = document.userProperties!["byline"] as? String

                let snippet = row.snippetWithWordStart("[{", wordEnd: "}]")
                return ReaderMatch(URL: URL, doc: doc, title: title, byline: byline, snippet: snippet)
            })
        }
    }

    func docForURL(URL: NSURL, callback: (props: [String: AnyObject]?, docID: String?) -> ()) {
        let query = viewURLs.createQuery()
        query.prefetch = true
        query.keys = [URL.absoluteString]
        query.runAsync() { rows, error in
            if let row = rows.nextRow() {
                callback(props: row.documentProperties, docID: row.documentID)
            } else {
                callback(props: nil, docID: nil)
            }
        }
    }

    func updateDoc(docID: String, props: [String: AnyObject]) {
        guard let doc = database.documentWithID(docID) else { return }
        _ = try? doc.putProperties(props)
    }
}