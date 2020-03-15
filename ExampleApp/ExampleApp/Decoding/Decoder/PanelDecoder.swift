//
//  PanelDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 17/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

struct PanelDecoder: EditorContentDecoding {
    func decode(mode: EditorContentMode, maxSize: CGSize, value: JSON) -> NSAttributedString {
        let frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 30))
        let attachment = PanelAttachment(frame: frame)
        //        attachment.readOnly = (mode == .readOnly)

        attachment.attributedText = EditorContentJSONDecoder().decode(
            mode: mode, maxSize: maxSize, value: value)
        return attachment.string
    }
}
