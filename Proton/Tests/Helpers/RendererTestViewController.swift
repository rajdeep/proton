//
//  RendererTestViewController.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class RendererTestViewController: SnapshotTestViewController {
    let renderer: RendererView

    init(renderer: RendererView? = nil) {
        self.renderer = renderer ?? RendererView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        renderer.translatesAutoresizingMaskIntoConstraints = false
        renderer.addBorder()

        view.addSubview(renderer)
        NSLayoutConstraint.activate([
            renderer.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            renderer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: renderer.trailingAnchor, constant: 20),
        ])
    }
}
