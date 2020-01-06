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

class MockBoundsObserver: BoundsObserving {
    var onBoundsChanged: ((CGRect) -> Void)?

    func didChangeBounds(_ bounds: CGRect) {
        onBoundsChanged?(bounds)
    }
}
