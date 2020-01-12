//
//  MockAttachment.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 12/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class MockAttachment: Attachment {
    var onAddedAttributesOnContainingRange: ((NSRange, [NSAttributedString.Key: Any]) -> Void)?
    var onRemovedAttributesFromContainingRange: ((NSRange, [NSAttributedString.Key]) -> Void)?

    override func addedAttributesOnContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key : Any]) {
        onAddedAttributesOnContainingRange?(range, attributes)
    }

    override func removedAttributesFromContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key]) {
        onRemovedAttributesFromContainingRange?(range, attributes)
    }
}
