/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler, UITextFieldDelegate, ResultsViewControllerDelegate {
    private let webView = WKWebView()
    private let backButton = UIButton()
    private let searchField = InsetTextField()

    private let resultsViewController = ResultsViewController()
    private var resultsHiddenConstraint: NSLayoutConstraint!
    private var resultsVisibleConstraint: NSLayoutConstraint!

    private let siteDB = SiteDatabase.sharedInstance

    private lazy var readerHTML: String = {
        let cssPath = NSBundle.mainBundle().pathForResource("Reader", ofType: "css")!
        let css = try! String(contentsOfFile: cssPath)

        let htmlPath = NSBundle.mainBundle().pathForResource("Reader", ofType: "html")!
        let html = try! String(contentsOfFile: htmlPath)

        return html
            .stringByReplacingOccurrencesOfString("%READER-CSS%", withString: css)
            .stringByReplacingOccurrencesOfString("%READER-STYLE%", withString: "light")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        searchField.delegate = self

        view.addSubview(backButton)
        view.addSubview(searchField)
        view.addSubview(webView)
        view.addSubview(resultsViewController.view)

        backButton.setTitle("<", forState: .Normal)
        backButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        backButton.addTarget(webView, action: #selector(WKWebView.goBack), forControlEvents: .TouchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 10).active = true
        backButton.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: 10).active = true
        let heightConstraint = backButton.heightAnchor.constraintEqualToAnchor(searchField.heightAnchor)
        heightConstraint.priority = 999
        heightConstraint.active = true
        backButton.widthAnchor.constraintEqualToAnchor(backButton.heightAnchor).active = true

        searchField.backgroundColor = UIColor.whiteColor()
        searchField.clearButtonMode = .WhileEditing
        searchField.layer.cornerRadius = 3
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 10).active = true
        searchField.leadingAnchor.constraintEqualToAnchor(backButton.trailingAnchor, constant: 10).active = true
        searchField.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -10).active = true

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraintEqualToAnchor(searchField.bottomAnchor, constant: 10).active = true
        webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

        resultsViewController.delegate = self
        resultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        resultsHiddenConstraint = resultsViewController.view.topAnchor.constraintEqualToAnchor(webView.bottomAnchor)
        resultsVisibleConstraint = resultsViewController.view.topAnchor.constraintEqualToAnchor(webView.topAnchor)
        resultsHiddenConstraint.active = true
        resultsViewController.view.leadingAnchor.constraintEqualToAnchor(webView.leadingAnchor).active = true
        resultsViewController.view.trailingAnchor.constraintEqualToAnchor(webView.trailingAnchor).active = true
        resultsViewController.view.bottomAnchor.constraintEqualToAnchor(webView.bottomAnchor).active = true

        for resource in ["Readability", "ReaderParser"] {
            let path = NSBundle.mainBundle().pathForResource(resource, ofType: "js")!
            let source = try! String(contentsOfFile: path)
            let script = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
            webView.configuration.userContentController.addUserScript(script)
        }

        webView.configuration.userContentController.addScriptMessageHandler(self, name: "readerHandler")

        webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.google.com")!))

        print("site count: \(siteDB.database.documentCount)")

        // Uncomment line below to automatically browse to random articles.
//        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
    }

    var timer: NSTimer!
    var count = 0

    func fireTimer() {
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://en.wikipedia.org/wiki/Special:Random")!))
        count += 1
        if count > 1000 {
            timer.invalidate()
        }
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let URL = message.frameInfo.request.URL,
              let body = message.body as? [String: AnyObject],
              let text = body["text"] as? String,
              let doc = body["doc"] as? String,
              let title = body["title"] as? String else { return }

        // HACK: Prevent saving search engine results.
        // There are better ways to test this other than domain checks.
        guard URL.host?.containsString("google") == false else { return }

        let byline = body["byline"] as? String

        siteDB.docForURL(URL) { props, docID in
            guard let docID = docID, var props = props else {
                self.siteDB.addPage(URL, doc: doc, text: text, title: title, byline: byline)
                print("added site! \(URL.host!)")
                return
            }

            props["doc"] = doc
            props["text"] = text
            props["title"] = title
            props["byline"] = byline
            self.siteDB.updateDoc(docID, props: props)
            print("updated site! \(URL.host!)")
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        updateResultsVisibility(visible: !newText.isEmpty)
        siteDB.findSites(newText) { matches in
            dispatch_async(dispatch_get_main_queue()) {
                self.resultsViewController.results = matches
            }
        }

        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let query = textField.text!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = "https://www.google.com/search?q=\(query!)"
        webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
        searchField.text = nil
        updateResultsVisibility(visible: false)
        return true
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        updateResultsVisibility(visible: false)
        return true
    }

    func resultsViewControllerDidSelectMatch(resultsViewController: ResultsViewController, match: ReaderMatch) {
        let html = readerHTML
            .stringByReplacingOccurrencesOfString("%READER-TITLE%", withString: match.title)
            .stringByReplacingOccurrencesOfString("%READER-CREDITS%", withString: match.byline ?? "")
            .stringByReplacingOccurrencesOfString("%READER-CONTENT%", withString: match.doc)
        let readerURL = NSURL(string: "about:reader")
        webView.loadHTMLString(html, baseURL: readerURL)
        searchField.text = nil
        updateResultsVisibility(visible: false)
    }

    private func updateResultsVisibility(visible visible: Bool) {
        let wasVisible = resultsViewController.parentViewController != nil

        if visible != wasVisible {
            if visible {
                addChildViewController(resultsViewController)
                resultsViewController.didMoveToParentViewController(self)
            } else {
                resultsViewController.willMoveToParentViewController(self)
                resultsViewController.removeFromParentViewController()
            }

            view.layoutIfNeeded()
            UIView.animateWithDuration(0.2) {
                self.resultsHiddenConstraint.active = !visible
                self.resultsVisibleConstraint.active = visible
                self.view.layoutIfNeeded()
            }
        }
    }
}
