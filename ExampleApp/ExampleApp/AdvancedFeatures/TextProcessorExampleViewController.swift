//
//  TextProcessorExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 9/1/20.
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
import UIKit

import Proton

class TextProcessorExampleViewController: ExamplesBaseViewController {

    let typeaheadLabel = UILabel()

    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        typeaheadLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(editor)
        view.addSubview(typeaheadLabel)

        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: 300),

            typeaheadLabel.topAnchor.constraint(equalTo: editor.bottomAnchor, constant: 50),
            typeaheadLabel.leadingAnchor.constraint(equalTo: editor.leadingAnchor)
        ])

        registerTextProcessors()

        editor.attributedText = NSAttributedString(string: "test")
    }

    private func registerTextProcessors() {
        editor.registerProcessor(MarkupProcessor())
        let typeaheadProcessor = TypeaheadTextProcessor()
        typeaheadProcessor.delegate = self
        editor.registerProcessor(typeaheadProcessor)
    }
}

extension TextProcessorExampleViewController: TypeaheadTextProcessorDelegate {
    func typeaheadQueryDidChange(trigger: String, query: String, range: NSRange) {
        let text = "Trigger: `\(trigger)` Query: `\(query)` @ \(range.location)-\(range.length)"
        typeaheadLabel.text = text
    }

    func typeadheadQueryDidEnd(reason: TypeaheadExitReason) {
        let reason = reason == .completed ? "completed" : "trigger deleted"
        typeaheadLabel.text = "Typeahead ended with reason: \(reason)"
    }
}
