//
//  EditorContentIdentifying.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

/// Identifies a content type withing the `Editor`
public protocol EditorContentIdentifying {
    var name: EditorContent.Name { get }
}

// Convenience type for a UIView that can be placed within the Editor as the content of an `Attachment`
typealias AttachmentView = UIView & EditorContentIdentifying

public protocol BlockAttachment: EditorContentIdentifying { }

public protocol InlineAttachment: EditorContentIdentifying { }
