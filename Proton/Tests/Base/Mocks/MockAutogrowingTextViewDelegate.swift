//
//  MockAutogrowingTextViewDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

@testable import Proton

class MockAutogrowingTextViewDelegate: AutogrowingTextViewDelegate {
    var onBoundsChanged: ((CGRect) -> Void)?

    func autogrowingTextView(_ autogrowingTextView: AutogrowingTextView, didChangeBounds bounds: CGRect) {
        onBoundsChanged?(bounds)
    }
}
