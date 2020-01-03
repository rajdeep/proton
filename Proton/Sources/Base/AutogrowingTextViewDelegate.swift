//
//  BoundsObserving.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 31/12/19.
//  Copyright © 2019 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

/// An object interested in listening to events raised from AutogrowingTextView.
protocol AutogrowingTextViewDelegate: class {
    func autogrowingTextView(_ autogrowingTextView: AutogrowingTextView, didChangeBounds bounds: CGRect)
}
