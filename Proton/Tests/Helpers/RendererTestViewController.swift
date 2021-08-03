//
//  RendererTestViewController.swift
//  ProtonTests
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
import Proton
#if os(iOS)
import UIKit
#else
import AppKit
#endif

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
            view.bottomAnchor.constraint(greaterThanOrEqualTo: renderer.bottomAnchor, constant: 20),
        ])
    }
}
