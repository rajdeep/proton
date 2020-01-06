//
//  AttachmentSize.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import CoreGraphics

/// Rendering size of the `Attachment`
public enum AttachmentSize {
    /// Matches the size of the content view of attachment. Content view must provide size to `Attachment` using `didChangeBounds(:)`.
    case matchContent
    /// Takes up full width of the containing `EditorView`. Resizes automatically when size of the container changes for e.g. when device is rotated.  Height is dynamic based on content.
    case fullWidth
    /// Fixed width attachment irrespective of content size of the contained view. Height is dynamic based on content.
    case fixed(width: CGFloat)
    /// Width of attachment is locked between the min and max.  Height is dynamic based on content.
    case range(minWidth: CGFloat, maxWidth: CGFloat)
    /// Width in percent based on the size of containing `EditorView`. Absolute value of width changes if the size of the container changes for e.g. when device is rotated.  Height is dynamic based on content.
    case percent(width: CGFloat)
}
