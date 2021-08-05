//
//  TextContainer.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
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
import CoreGraphics

class TextContainer: PlatformTextContainer {
    #if os(iOS)
    weak var textView: RichTextView?
    // on macOS, `textView` it's already defined by NSTextContainer
    #endif
    
    override init(size: CGSize) {
        super.init(size: size)
        widthTracksTextView = true
        heightTracksTextView = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
