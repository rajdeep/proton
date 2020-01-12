//
//  MockAttachmentContentView.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

@testable import Proton

class RichTextAttachmentView: RichTextView, InlineContent {
    let name = EditorContent.Name(rawValue: "TestContentView")
}
