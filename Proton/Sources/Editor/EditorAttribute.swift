//
//  EditorAttribute.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

enum EditorAttribute {
    case bold
    case italics
    case underline
    case color(UIColor)
    case font(UIFont)
    case contentName(EditorContent.Name)
    case paragraph(NSParagraphStyle)
    case custom(Decodable)
}
