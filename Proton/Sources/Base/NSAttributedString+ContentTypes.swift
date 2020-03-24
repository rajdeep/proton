//
//  NSAttributedString+ContentTypes.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString.Key {
    static let viewOnly = NSAttributedString.Key("_viewOnly")
    static let contentType = NSAttributedString.Key("_contentType")
    static let isBlockAttachment = NSAttributedString.Key("_isBlockAttachment")
    static let isInlineAttachment = NSAttributedString.Key("_isInlineAttachment")
}

public extension NSAttributedString.Key {
    static let noFocus = NSAttributedString.Key("_noFocus")
}
