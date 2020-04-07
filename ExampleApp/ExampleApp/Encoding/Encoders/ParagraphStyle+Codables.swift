//
//  ParagraphStyle+Codables.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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
            "isMonospace": fontDescriptor.symbolicTraits.contains(.traitMonoSpace),
            "textStyle": fontDescriptor.object(forKey: .textStyle) as? String ?? "UICTFontTextStyleBody"
        ]
        return .json(value: attributes)
    }
}
