//
//  Essential_8_Knowledge_BaseUITestsLaunchTests.swift
//  Essential 8 Knowledge BaseUITests
//
//  Created by David Warner on 20/5/2026.
//

import XCTest

final class Essential_8_Knowledge_BaseUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
