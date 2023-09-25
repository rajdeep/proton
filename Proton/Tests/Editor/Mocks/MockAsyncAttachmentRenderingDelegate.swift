//
//  MockAsyncAttachmentRenderingDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 20/9/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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

import Proton

class MockAsyncAttachmentRenderingDelegate: AsyncAttachmentRenderingDelegate {
    var onShouldRenderAsync: (Attachment) -> Bool = { _ in return true }
    var onDidRenderAttachment: ((Attachment, EditorView) -> Void)?

    func shouldRenderAsync(attachment: Attachment) -> Bool {
        onShouldRenderAsync(attachment)
    }

    func didRenderAttachment(_ attachment: Attachment, in editor: EditorView) {
        onDidRenderAttachment?(attachment, editor)
    }
}
