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
    static let viewOnly =  NSAttributedString.Key("viewOnly")
    static let contentType =  NSAttributedString.Key("contentType")
    static let isBlockAttachment = NSAttributedString.Key("isBlockAttachment")
    static let isInlineAttachment = NSAttributedString.Key("isInlineAttachment")
}
