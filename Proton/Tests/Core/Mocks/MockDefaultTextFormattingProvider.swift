//
//  MockDefaultTextFormattingProvider.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

@testable import Proton

class MockDefaultTextFormattingProvider: DefaultTextFormattingProviding {
    var textColor: UIColor
    let font: UIFont
    let paragraphStyle: NSMutableParagraphStyle

    init(font: UIFont, textColor: UIColor = .black, paragraphStyle: NSMutableParagraphStyle) {
        self.font = font
        self.textColor = textColor
        self.paragraphStyle = paragraphStyle
    }
}
