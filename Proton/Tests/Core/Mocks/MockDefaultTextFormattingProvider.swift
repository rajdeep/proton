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
    let font: UIFont?
    let paragraphStyle: NSMutableParagraphStyle

    init(font: UIFont, paragraphStyle: NSMutableParagraphStyle) {
        self.font = font
        self.paragraphStyle = paragraphStyle
    }
}
