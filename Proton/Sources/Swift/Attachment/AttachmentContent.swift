//
//  AttachmentContent.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 22/5/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit

enum AttachmentContent {
    case view(AttachmentContentView, size: AttachmentSize)
    case image(UIImage)
}

@objc
class AttachmentContentView: UIView {
    let name: EditorContent.Name
    weak var attachment: Attachment?

    init(name: EditorContent.Name, frame: CGRect) {
        self.name = name
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Describes an image for which can be used in an `Attachment`
public struct AttachmentImage: AttachmentViewIdentifying {
    /// Content name for the image
    public let name: EditorContent.Name
    /// Image content
    public let image: UIImage
    /// Size of the image
    public let size: CGSize
    /// Denotes if the image is block content or an inline
    public var type: AttachmentType

    /// Initializes the Block Content image
    /// - Parameters:
    ///   - name: Content name
    ///   - image: Image
    ///   - size: Size of the image
    ///   - isBlockContent: Determines if image is a block content
    public init(name: EditorContent.Name, image: UIImage, size: CGSize, type: AttachmentType) {
        self.name = name
        self.image = image
        self.size = size
        self.type = type
    }
}
