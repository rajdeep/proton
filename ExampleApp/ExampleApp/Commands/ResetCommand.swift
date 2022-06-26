//
//  ResetCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
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

class ResetCommand: EditorCommand {
    let name = CommandName("resetCommand")

    func execute(on renderer: EditorView) {
        renderer.attributedText = NSAttributedString(string: """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus vel aliquam enim. Nam lobortis, ipsum ullamcorper accumsan aliquam, orci velit lobortis lacus, at volutpat augue sem at enim. Maecenas porta velit eget eleifend rutrum. Mauris vel dui diam. Suspendisse porttitor dictum massa, sit amet imperdiet mi facilisis a. Duis viverra facilisis justo, sit amet congue mauris. Nullam vitae pellentesque eros. Aenean ut erat ultrices, vulputate massa vel, ultricies velit. Nam at arcu lacinia, ullamcorper augue eget, lobortis dui. Vestibulum iaculis tortor id diam suscipit consectetur. Nulla sit amet pretium purus. Donec ac congue est, et porttitor dolor. Curabitur dictum, nunc et aliquam venenatis, quam nisi porta nunc, accumsan tincidunt magna tortor sed justo. Donec quis iaculis leo, sed feugiat lectus. Sed non libero nibh.

            Donec dignissim sollicitudin diam, a egestas mi elementum ac. Fusce orci ligula, consectetur vel eleifend at, consectetur a turpis. Sed sed volutpat nisl. Donec vel sollicitudin turpis. Vivamus auctor iaculis dui, eget consectetur sapien. Nullam hendrerit egestas efficitur. Nam vestibulum massa libero, eget facilisis mauris eleifend nec. Mauris placerat semper eros, nec sagittis ipsum dapibus in. Curabitur faucibus est quis enim sodales, placerat sollicitudin eros blandit. Proin a fringilla augue. Morbi ullamcorper a metus quis placerat.
        """
        )
    }
}
