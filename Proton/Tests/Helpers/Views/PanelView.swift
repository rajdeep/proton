//
//  PanelView.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
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

class PanelView: PlatformView, BlockContent, EditorContentView {
    let editor: EditorView
    let iconView = PlatformImageView()

    var name: EditorContent.Name {
        return EditorContent.Name("panel")
    }

    init(context: EditorViewContext) {
        self.editor = EditorView(frame: .zero, context: context)
        super.init(frame: .zero)

        setup()
    }

    override init(frame: CGRect) {
        self.editor = EditorView(frame: frame)
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(iOS)
    override var backgroundColor: UIColor? {
        didSet {
            editor.backgroundColor = backgroundColor
        }
    }
    #endif

    private func setup() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.paragraphStyle.firstLineHeadIndent = 0

        addSubview(iconView)
        addSubview(editor)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),

            editor.topAnchor.constraint(equalTo: iconView.topAnchor, constant: -editor.textContainerInset.top),
            editor.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            editor.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            editor.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
        
        iconView.caLayer.borderColor = PlatformColor.black.cgColor
        iconView.caLayer.borderWidth = 1.0
        iconView.setBackgroundColor(PlatformColor.white)

        caLayer.cornerRadius = 5.0
        clipsToBounds = true
    }
}
