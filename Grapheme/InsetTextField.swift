/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class InsetTextField: UITextField {
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 5, 5)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 5, 5)
    }
}