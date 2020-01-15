//
//  ParagraphStyle+Codables.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

protocol Encoding {
    var key: String { get }
    var value: JSON? { get }
}

extension NSParagraphStyle: Encoding {
    var key: String { return "style" }

    var value: JSON? {
        let attributes: JSON = [
            "alignment": alignment.rawValue,
            "firstLineHeadIndent": firstLineHeadIndent,
            "linespacing": lineSpacing,
            "paragraphSpacing": paragraphSpacing
            ]
        return attributes
    }
}

extension UIFont: InlineEncoding {
    var key: String { return "font" }

    var value: InlineValueType {
        let attributes: JSON = [
            "name": fontName,
            "family": familyName,
            "size": fontDescriptor.pointSize,
            "isBold": fontDescriptor.symbolicTraits.contains(.traitBold),
            "isItalics": fontDescriptor.symbolicTraits.contains(.traitItalic),
            "isMonospace": fontDescriptor.symbolicTraits.contains(.traitMonoSpace)
        ]
        return .json(value: attributes)
    }
}

