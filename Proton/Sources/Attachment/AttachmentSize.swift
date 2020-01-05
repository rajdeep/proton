//
//  AttachmentSize.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import CoreGraphics

public enum AttachmentSize {
    case matchContent
    case matchContainer
    case fixed(width: CGFloat)
    case range(minWidth: CGFloat, maxWidth: CGFloat)
    case percent(width: CGFloat)
}
