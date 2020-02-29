//
//  SelectionView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

class SelectionView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alpha = 0.5
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let originalResult = super.hitTest(point, with: event),
            event?.type == .touches else {
                return nil
        }
        
        guard originalResult == self else {
            return originalResult
        }
        removeFromSuperview()

        for other in (superview?.subviews ?? []) where other != self {
            let convertedPoint = convert(point, to: other)
            if let hit = other.hitTest(convertedPoint, with: event) {
                return hit
            }
        }
        return nil
    }
    
    func addTo(parent: UIView) {
        applyTintColor()
        self.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: parent.topAnchor),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
    }
    
    private func applyTintColor() {
        // TintColor needs to be picked up from UIButton as it is the only control that
        // provides correct color for macOS accents.
        self.backgroundColor = UIButton().tintColor
    }
}
