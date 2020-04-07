//
//  RendererCommandExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
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

class RendererCommandButton: UIButton {
    var command: RendererCommand!

    static func make(command: RendererCommand) -> RendererCommandButton {
        let button = RendererCommandButton(type: .system)
        button.command = command
        button.tintColor = .systemBlue
        button.backgroundColor = .systemBackground
        return button
    }
}

class RendererCommandsExampleViewController: ExamplesBaseViewController {
    let renderer = RendererView()
    let commandExecutor = RendererCommandExecutor()
    var buttons = [UIButton]()
    let searchText = UITextField()

    let commands: [(title: String, command: RendererCommand)] = [
        (title: "Reset", command: ResetCommand()),
        (title: "Highlight", command: HighlightTextCommand()),
        (title: "Scroll", command: ScrollCommand()),
    ]

    override func setup() {
        super.setup()

        renderer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(renderer)

        renderer.layer.borderColor = UIColor.systemBlue.cgColor
        renderer.layer.borderWidth = 1.0

        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        renderer.delegate = self

        self.buttons = makeCommandButtons()
        for button in buttons {
            stackView.addArrangedSubview(button)
        }
        view.addSubview(stackView)

        searchText.placeholder = "Search text"
        searchText.translatesAutoresizingMaskIntoConstraints = false
        searchText.borderStyle = .roundedRect
        searchText.autocorrectionType = .no
        searchText.autocapitalizationType = .none

        view.addSubview(searchText)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            searchText.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            searchText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchText.widthAnchor.constraint(equalToConstant: 300),

            renderer.topAnchor.constraint(equalTo: searchText.bottomAnchor, constant: 20),
            renderer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            renderer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            renderer.heightAnchor.constraint(equalToConstant: 300)
        ])

        setText()
    }

    func setText() {
        renderer.attributedText = NSAttributedString(string: """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus vel aliquam enim. Nam lobortis, ipsum ullamcorper accumsan aliquam, orci velit lobortis lacus, at volutpat augue sem at enim. Maecenas porta velit eget eleifend rutrum. Mauris vel dui diam. Suspendisse porttitor dictum massa, sit amet imperdiet mi facilisis a. Duis viverra facilisis justo, sit amet congue mauris. Nullam vitae pellentesque eros. Aenean ut erat ultrices, vulputate massa vel, ultricies velit. Nam at arcu lacinia, ullamcorper augue eget, lobortis dui. Vestibulum iaculis tortor id diam suscipit consectetur. Nulla sit amet pretium purus. Donec ac congue est, et porttitor dolor. Curabitur dictum, nunc et aliquam venenatis, quam nisi porta nunc, accumsan tincidunt magna tortor sed justo. Donec quis iaculis leo, sed feugiat lectus. Sed non libero nibh.

            Donec dignissim sollicitudin diam, a egestas mi elementum ac. Fusce orci ligula, consectetur vel eleifend at, consectetur a turpis. Sed sed volutpat nisl. Donec vel sollicitudin turpis. Vivamus auctor iaculis dui, eget consectetur sapien. Nullam hendrerit egestas efficitur. Nam vestibulum massa libero, eget facilisis mauris eleifend nec. Mauris placerat semper eros, nec sagittis ipsum dapibus in. Curabitur faucibus est quis enim sodales, placerat sollicitudin eros blandit. Proin a fringilla augue. Morbi ullamcorper a metus quis placerat.
        """
        )
    }

    func makeCommandButtons() -> [UIButton] {
        var buttons = [UIButton]()
        for (title, command) in commands {
            let button = RendererCommandButton.make(command: command)
            button.setTitle(title, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(runCommand(sender:)), for: .touchUpInside)

            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 5.0

            NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 80)])
            buttons.append(button)
        }
        return buttons
    }

    @objc
    func runCommand(sender: RendererCommandButton) {
        guard let command = sender.command else { return }
        if command is ScrollCommand {
            (command as? ScrollCommand)?.text = searchText.text ?? ""
        }
        commandExecutor.execute(command)
    }
}

extension RendererCommandsExampleViewController: RendererViewDelegate {
    func didTap(_ renderer: RendererView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        guard let charRange = characterRange else { return }
        print("Tapped: \(renderer.attributedText.attributedSubstring(from: charRange))")
    }

    func didChangeSelection(_ renderer: RendererView, range: NSRange) {
        print("Selected: \(renderer.attributedText.attributedSubstring(from: range))")
    }
}
