//
//  EditorViewViewportSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/11/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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
import XCTest
import SnapshotTesting

@testable import Proton

class EditorViewportSnapshotTests: SnapshotTestCase {
    override func setUp() {
        super.setUp()
        recordMode = false
    }

    func testNotifiesViewportRenderingWhenNoAttachments() {
        let ex = functionExpectation()

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let viewport = CGRect(
            origin: CGPoint(x: 0, y: 300),
            size: CGSize(width: 260, height: 300)
        )

        let asyncRenderingDelegate = MockAsyncAttachmentRenderingDelegate(viewport: viewport)

        editor.asyncAttachmentRenderingDelegate = asyncRenderingDelegate

        let viewportBorderView = UIView(frame: viewport)
        viewportBorderView.layer.borderColor = UIColor.red.cgColor
        viewportBorderView.layer.borderWidth = 2
        viewportBorderView.backgroundColor = .clear

        editor.addSubview(viewportBorderView)

        let text = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed sagittis felis ut nibh vehicula gravida. Etiam posuere dictum mauris, sed eleifend nulla suscipit ac. Duis dapibus malesuada hendrerit. In sapien enim, imperdiet sed eros quis, maximus tincidunt lacus. Nullam sodales hendrerit diam gravida scelerisque. Aenean varius quis ex nec hendrerit. Sed sagittis accumsan sapien eu dapibus. Quisque eu tortor suscipit, tristique sem varius, vulputate ex.

        Phasellus ac mattis quam. In blandit leo quis mauris tempor, et euismod leo maximus. Etiam vitae sagittis quam. Donec nec ipsum eu sem iaculis laoreet. Mauris eget dictum nisi. Integer eu sollicitudin nisl. Proin ac lorem sem. Sed hendrerit rutrum enim sed pellentesque. Ut tempus, lectus a dignissim tincidunt, odio est posuere felis, sed faucibus risus arcu ac tortor. Vestibulum in enim quis turpis luctus faucibus. Pellentesque maximus diam scelerisque condimentum pharetra. Fusce tincidunt blandit ante quis gravida. Sed sed tincidunt urna. Nunc porta porttitor laoreet.
        """

        editor.attributedText = NSAttributedString(string: text)
        var renderingNotified = false
        asyncRenderingDelegate.onDidCompleteRenderingViewport = { viewport, _ in
            renderingNotified = true
            XCTAssertEqual(viewport, asyncRenderingDelegate.prioritizedViewport)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(renderingNotified)
            assertSnapshot(matching: viewController.view, as: .image, record: self.recordMode)
            ex.fulfill()
        }

        viewController.render(size: CGSize(width: 300, height: 900))

        waitForExpectations(timeout: 1.0)
    }

    func testRendersViewport() {
        let ex = functionExpectation()
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let viewport = CGRect(
            origin: CGPoint(x: 0, y: 300),
            size: CGSize(width: 260, height: 300)
        )
        let asyncRenderingDelegate = MockAsyncAttachmentRenderingDelegate(viewport: viewport)

        editor.asyncAttachmentRenderingDelegate = asyncRenderingDelegate

        let viewportBorderView = UIView(frame: viewport)
        viewportBorderView.layer.borderColor = UIColor.red.cgColor
        viewportBorderView.layer.borderWidth = 2
        viewportBorderView.backgroundColor = .clear

        editor.addSubview(viewportBorderView)

        let panels = makePanelAttachments(count: 300, text: "Text in panel")
        let text = NSMutableAttributedString()
        for panel in panels {
            text.append(panel.string)
            text.append(NSAttributedString(string: "Text after panel"))
        }
        editor.attributedText = text

        asyncRenderingDelegate.onDidCompleteRenderingViewport = { viewport, _ in
            XCTAssertEqual(viewport, asyncRenderingDelegate.prioritizedViewport)
            assertSnapshot(matching: viewController.view, as: .image, record: self.recordMode)
            ex.fulfill()
        }

        viewController.render(size: CGSize(width: 300, height: 900))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        waitForExpectations(timeout: 1.0)
    }

    func testRendersSuccessiveViewports() {
        let ex = functionExpectation()
        ex.expectedFulfillmentCount = 2
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let viewport = CGRect(
            origin: CGPoint(x: 0, y: 150),
            size: CGSize(width: 260, height: 200)
        )
        let asyncRenderingDelegate = MockAsyncAttachmentRenderingDelegate(viewport: viewport)

        editor.asyncAttachmentRenderingDelegate = asyncRenderingDelegate

        let viewportBorderView = UIView(frame: viewport)
        viewportBorderView.layer.borderColor = UIColor.red.cgColor
        viewportBorderView.layer.borderWidth = 2
        viewportBorderView.backgroundColor = .clear

        editor.addSubview(viewportBorderView)

        let panels = makePanelAttachments(count: 300, text: "Text in panel")
        let text = NSMutableAttributedString()
        for panel in panels {
            text.append(panel.string)
            text.append(NSAttributedString(string: "Text after panel"))
        }
        editor.attributedText = text
        var expectedViewport = asyncRenderingDelegate.prioritizedViewport

        asyncRenderingDelegate.onDidCompleteRenderingViewport = { viewport, _ in
            XCTAssertEqual(viewport, expectedViewport)
            assertSnapshot(matching: viewController.view, as: .image, record: self.recordMode)
            asyncRenderingDelegate.prioritizedViewport =  CGRect(
                origin: CGPoint(x: 0, y: 600),
                size: CGSize(width: 260, height: 200)
            )
            viewportBorderView.frame = asyncRenderingDelegate.prioritizedViewport ?? viewportBorderView.frame
            expectedViewport = asyncRenderingDelegate.prioritizedViewport
            ex.fulfill()
        }

        viewController.render(size: CGSize(width: 300, height: 900))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        waitForExpectations(timeout: 1.0)
    }

    func makePanelAttachments(count: Int, text: String) -> [Attachment] {
        var attachments = [Attachment]()

        for i in 0..<count {
            var panel = PanelView()
            panel.editor.forceApplyAttributedText = true
            panel.backgroundColor = .cyan
            panel.layer.borderWidth = 1.0
            panel.layer.cornerRadius = 4.0
            panel.layer.borderColor = UIColor.black.cgColor

            let attachment = Attachment(panel, size: .fullWidth)
            panel.boundsObserver = attachment
            panel.attributedText = NSAttributedString(string: "\(i). \(text)")
            attachments.append(attachment)
        }

        return attachments
    }
}
