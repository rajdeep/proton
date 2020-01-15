//
//  CommandsExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class EditorCommandButton: UIButton {
    let command: EditorCommand

    init(command: EditorCommand) {
        self.command = command
        super.init(frame: .zero)

        setTitleColor(.blue, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            let color: UIColor = isSelected ? .lightGray : .white
            backgroundColor = color
        }
    }
}

class CommandsExampleViewController: ExamplesBaseViewController {
    let editor = EditorView()
    let commandExecutor = EditorCommandExecutor()
    var buttons = [UIButton]()

    let commands: [(title: String, command: EditorCommand)] = [
        (title: "Panel", command: PanelCommand()),
        (title: "Bold", command: BoldCommand()),
        (title: "Italics", command: ItalicsCommand()),
    ]

    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.blue.cgColor
        editor.layer.borderWidth = 1.0

        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        editor.delegate = self

        self.buttons = makeCommandButtons()
        for button in buttons {
            stackView.addArrangedSubview(button)
        }
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            editor.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        editor.setFocus()
    }

    func makeCommandButtons() -> [UIButton] {
        var buttons = [UIButton]()
        for command in commands {
            let button = EditorCommandButton(command: command.command)
            button.setTitle(command.title, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(runCommand(sender:)), for: .touchUpInside)

            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 5.0

            NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 60)])
            buttons.append(button)
        }
        return buttons

    }

    @objc
    func runCommand(sender: EditorCommandButton) {
        if sender.titleLabel?.text != "Panel" {
            sender.isSelected = !sender.isSelected
        }
        commandExecutor.execute(sender.command)
    }
}

extension CommandsExampleViewController: EditorViewDelegate {
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        guard let font = attributes[.font] as? UIFont else { return }

        buttons.first(where: { $0.titleLabel?.text == "Bold"})?.isSelected = font.isBold
        buttons.first(where: { $0.titleLabel?.text == "Italics"})?.isSelected = font.isItalics
    }
}
