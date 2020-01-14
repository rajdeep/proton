//
//  RendererViewDelegate.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import CoreGraphics

public protocol RendererViewDelegate: class {
    func didTap(_ renderer: RendererView, didTapAtLocation location: CGPoint, characterRange: NSRange?)
    func didChangeSelection(_ renderer: RendererView, range: NSRange)
}
