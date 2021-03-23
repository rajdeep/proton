//
//  RendererViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
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

/// An object that is interested in listening to events raised within the Renderer.
public protocol RendererViewDelegate: AnyObject {

    /// Invoked on tap/mouse click on the Renderer.
    /// - Parameters:
    ///   - renderer: Renderer view receiving the event.
    ///   - location: Location of tap.
    ///   - characterRange: Range at the tapped location.
    func didTap(_ renderer: RendererView, didTapAtLocation location: CGPoint, characterRange: NSRange?)
    func didChangeSelection(_ renderer: RendererView, range: NSRange)
}
