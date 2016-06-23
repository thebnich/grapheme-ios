/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class ViewController: UIViewController {
    let webView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

        webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.google.com")!))
    }
}

