//
//  Essential_8_Knowledge_BaseUITests.swift
//  Essential 8 Knowledge BaseUITests
//
//  Created by David Warner on 20/5/2026.
//

import XCTest

final class Essential_8_Knowledge_BaseUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeScreenShowsControls() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Application Control"].exists)
        XCTAssertTrue(app.staticTexts["Regular Backups"].exists)
    }

    @MainActor
    func testMicrosoft365AdditionalControlsSettings() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["M365 Additional Controls"].waitForExistence(timeout: 5))
        app.buttons["M365 Additional Controls"].tap()

        XCTAssertTrue(app.staticTexts["M365 Additional Controls"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["None"].exists)
        XCTAssertTrue(app.buttons["E3"].exists)
        XCTAssertTrue(app.buttons["E5"].exists)

        app.buttons["E3"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["P1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["P2"].exists)
        app.buttons["P2"].tap()
        app.buttons["E5"].tap()
        app.navigationBars["M365 Additional Controls"].buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAboutAndPrivacyScreen() throws {
        let app = XCUIApplication()
        app.launch()

        let aboutButton = app.buttons["About & Privacy"]
        for _ in 0..<3 where !aboutButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
        aboutButton.tap()

        XCTAssertTrue(app.navigationBars["About Essential 8"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Privacy Policy"].exists)
        XCTAssertTrue(app.staticTexts["References"].exists)

        let essentialEightReference = app.staticTexts["ASD Essential Eight maturity model"]
        for _ in 0..<3 where !essentialEightReference.exists {
            app.swipeUp()
        }

        XCTAssertTrue(essentialEightReference.exists)
        XCTAssertTrue(app.staticTexts["ASD Information Security Manual"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "does not collect")).firstMatch.exists)

        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
