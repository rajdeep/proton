//
//  MockRendererViewDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

class MockRendererViewDelegate: RendererViewDelegate {
    var onDidTap: ((RendererView, CGPoint, NSRange?) -> Void)?
    var onDidChangeSelection: ((RendererView, NSRange) -> Void)?

    func didTap(
        _ renderer: RendererView, didTapAtLocation location: CGPoint, characterRange: NSRange?
    ) {
        onDidTap?(renderer, location, characterRange)
    }

    func didChangeSelection(_ renderer: RendererView, range: NSRange) {
        onDidChangeSelection?(renderer, range)
    }
}
