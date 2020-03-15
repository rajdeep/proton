//
//  TextProcessorExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

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
            editor.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: 300),

            typeaheadLabel.topAnchor.constraint(equalTo: editor.bottomAnchor, constant: 50),
            typeaheadLabel.leadingAnchor.constraint(equalTo: editor.leadingAnchor),
        ])

        registerTextProcessors()
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
