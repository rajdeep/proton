//
//  MockAttachmentOffsetProvider.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class MockAttachmentOffsetProvider: AttachmentOffsetProviding {
    var offset = CGPoint.zero

    func offset(for _: Attachment, in _: NSTextContainer, proposedLineFragment _: CGRect, glyphPosition _: CGPoint, characterIndex _: Int) -> CGPoint {
        offset
    }
}
