/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol ResultsViewControllerDelegate: class {
    func resultsViewControllerDidSelectMatch(resultsViewController: ResultsViewController, match: ReaderMatch)
}

let HighlightColor = UIColor(rgb: 0xccddee)
let ReuseIdentifier = "cell"

class ResultsViewController: UITableViewController {
    weak var delegate: ResultsViewControllerDelegate?

    var results = [ReaderMatch]() {
        didSet {
            tableView.reloadData()
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.rowHeight = 80
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: ReuseIdentifier)
        let snippet = results[indexPath.row].snippet

        // HACK: We highlight matches with [{these}] brackets, but those brackets could be in the original string
        // itself. Should find a safer way to identify matches.
        let regex = try! NSRegularExpression(pattern: "\\[\\{.+?\\}\\]", options: [])
        let range = NSRange(location: 0, length: snippet.characters.count)
        let snippetWithoutBrackets = snippet
            .stringByReplacingOccurrencesOfString("[{", withString: "")
            .stringByReplacingOccurrencesOfString("}]", withString: "")

        let attributed = NSMutableAttributedString(string: snippetWithoutBrackets)

        var removedBrackets = 0
        for match in regex.matchesInString(snippet, options: [], range: range) {
            let range = NSRange(location: match.range.location - removedBrackets, length: match.range.length - 4)
            attributed.addAttribute(NSBackgroundColorAttributeName, value: HighlightColor, range: range)
            removedBrackets += 4
        }

        cell.textLabel?.text = results[indexPath.row].title
        cell.textLabel?.font = UIFont.boldSystemFontOfSize(14)
        cell.textLabel?.numberOfLines = 1

        cell.detailTextLabel?.attributedText = attributed
        cell.detailTextLabel?.numberOfLines = 3
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.resultsViewControllerDidSelectMatch(self, match: results[indexPath.row])
    }
}