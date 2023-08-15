//
//  GestureRegognizerDelegateOverride.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 15/8/2023.
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

class GestureRecognizerDelegateOverride: NSObject, UIGestureRecognizerDelegate {
    let baseDelegate: UIGestureRecognizerDelegate

    init(baseDelegate: UIGestureRecognizerDelegate) {
        self.baseDelegate = baseDelegate
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        baseDelegate.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        baseDelegate.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let isAttachment = isInAttachment(gestureRecognizer.view)
        let isOtherAttachment = isInAttachment(otherGestureRecognizer.view)
        return baseDelegate.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) ?? isAttachment == isOtherAttachment
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let isAttachment = isInAttachment(gestureRecognizer.view)
        let isOtherAttachment = isInAttachment(otherGestureRecognizer.view)
        return baseDelegate.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) ?? isAttachment == isOtherAttachment
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer,
            baseDelegate.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) == true {
            return isInAttachment(touch.view) == false
        }
        return baseDelegate.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) ?? true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        baseDelegate.gestureRecognizer?(gestureRecognizer, shouldReceive: press) ?? true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        if #available(iOS 13.4, *) {
            return baseDelegate.gestureRecognizer?(gestureRecognizer, shouldReceive: event) ?? true
        } else {
            return true
        }
    }

    private func isInAttachment(_ view: UIView?) -> Bool {
        (view as? RichTextView)?.editorView?.isContainedInAnAttachment == true
    }
}
