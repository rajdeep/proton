//
//  CommandsExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/1/20.
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
import ProtonExtensions

class EditorCommandButton: UIButton {
    let command: EditorCommand

    let highlightOnTouch: Bool

    init(command: EditorCommand, highlightOnTouch: Bool) {
        self.command = command
        self.highlightOnTouch = highlightOnTouch
        super.init(frame: .zero)
        titleLabel?.font = UIButton(type: .system).titleLabel?.font
        isSelected = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            setTitleColor(isSelected ? .white : .systemBlue, for: .normal)
            backgroundColor = isSelected ? .systemBlue : .systemBackground
        }
    }
}

class CommandsExampleViewController: ExamplesBaseViewController {

    let commandExecutor = EditorCommandExecutor()
    var buttons = [UIButton]()

    var encodedContents: JSON = ["contents": []]

    let commands: [(title: String, command: EditorCommand, highlightOnTouch: Bool)] = [
        (title: "Panel", command: PanelCommand(), highlightOnTouch: false),
        (title: "List", command: ListCommand(), highlightOnTouch: false),
        (title: "Bold", command: BoldCommand(), highlightOnTouch: true),
        (title: "Italics", command: ItalicsCommand(), highlightOnTouch: true),
        (title: "TextBlock", command: TextBlockCommand(), highlightOnTouch: false),
    ]

    let editorButtons: [(title: String, selector: Selector)] = [
        (title: "Encode", selector: #selector(encodeContents(sender:))),
        (title: "Decode", selector: #selector(decodeContents(sender:))),
        (title: "Sample", selector: #selector(loadSample(sender:))),
    ]

    let listFormattingProvider = ListFormattingProvider()

    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0

        editor.listFormattingProvider = listFormattingProvider

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        editor.delegate = self
        EditorViewContext.shared.delegate = self

        editor.registerProcessor(ListTextProcessor())
//        editor.paragraphStyle.paragraphSpacingBefore = 20


        self.buttons = makeCommandButtons()
        for button in buttons {
            stackView.addArrangedSubview(button)
        }

        let editorButtons = makeEditorButtons()
        for button in editorButtons {
            stackView.addArrangedSubview(button)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            scrollView.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: 10),

            stackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            editor.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
        ])
    }

    func makeCommandButtons() -> [UIButton] {
        var buttons = [UIButton]()
        for (title, command, highlightOnTouch) in commands {
            let button = EditorCommandButton(command: command, highlightOnTouch: highlightOnTouch)
            button.setTitle(title, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(runCommand(sender:)), for: .touchUpInside)

            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 5.0

            NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 70)])
            buttons.append(button)
        }
        return buttons
    }

    func makeEditorButtons() -> [UIButton] {
        var buttons = [UIButton]()
        for editorButton in editorButtons {
            let button = UIButton(type: .system)
            button.tintColor = .systemBlue
            button.setTitle(editorButton.title, for: .normal)
            button.backgroundColor = .systemBackground
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: editorButton.selector, for: .touchUpInside)

            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 5.0

            NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 70)])
            buttons.append(button)
        }
        return buttons
    }

    @objc
    func runCommand(sender: EditorCommandButton) {
        if sender.highlightOnTouch {
            sender.isSelected.toggle()
        }
        if sender.titleLabel?.text == "Encode" {
            sender.command.execute(on: editor)
            return
        } else if sender.titleLabel?.text == "List" {
            if let command = sender.command as? ListCommand,
                let editor = editor.editorViewContext.activeEditorView {
                var attributeValue: String? = "listItemValue"
                if editor.contentLength > 0,
                    editor.attributedText.attribute(.listItem, at: min(editor.contentLength - 1, editor.selectedRange.location), effectiveRange: nil) != nil {
                    attributeValue = nil
                }
                command.execute(on: editor, attributeValue: attributeValue)
                return
            }
        }
        commandExecutor.execute(sender.command)
    }

    @objc
    func encodeContents(sender: UIButton) {
        let value = editor.transformContents(using: JSONEncoder())
        let data = try! JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
        let jsonString = String(data: data, encoding: .utf8)!
        self.encodedContents = ["contents": value]

        let printableContents = """
            { "contents":  \(jsonString) }
        """

        print(printableContents)

        editor.attributedText = NSAttributedString()
    }

    @objc
    func decodeContents(sender: UIButton) {
        let text = EditorContentJSONDecoder().decode(mode: .editor, maxSize: editor.frame.size, value: encodedContents)
        self.editor.attributedText = text
    }

    @objc
    func loadSample(sender: UIButton) {
        guard let contents = Bundle.main.jsonFromFile("SampleDoc") else {
            return
        }

        let text = EditorContentJSONDecoder().decode(mode: .editor, maxSize: editor.frame.size, value: contents)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.editor.attributedText = text
        }
    }
}

extension CommandsExampleViewController: EditorViewDelegate {
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        guard let font = attributes[.font] as? UIFont else { return }

        buttons.first(where: { $0.titleLabel?.text == "Bold" })?.isSelected = font.isBold
        buttons.first(where: { $0.titleLabel?.text == "Italics" })?.isSelected = font.isItalics
    }

    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        print("Focussed: `\(editor.contentName?.rawValue ?? "<root editor>")` at depth: \(editor.nestingLevel)")
    }

    func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize) {
        print("Height changed from \(previousSize.height) to \(currentSize.height)")
    }
}

class ListFormattingProvider: EditorListFormattingProvider {
    let listLineFormatting: LineFormatting = LineFormatting(indentation: 25, spacingBefore: 0)
    let sequenceGenerators: [SequenceGenerator] =
        [NumericSequenceGenerator(),
         DiamondBulletSequenceGenerator(),
         SquareBulletSequenceGenerator()]

    func listLineMarkerFor(editor: EditorView, index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker {
        let sequenceGenerator = self.sequenceGenerators[(level - 1) % self.sequenceGenerators.count]
        return sequenceGenerator.value(at: index)
    }
}
