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
    func testSplashViewFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "YES", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        // 1. Verify splash elements are present
        XCTAssertTrue(app.staticTexts["Essential 8"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["What's New in Version 1.4"].exists)

        let checkbox = app.buttons["Always show on startup"]
        XCTAssertTrue(checkbox.exists)
        XCTAssertEqual(checkbox.value as? String, "Checked")

        // 2. Toggle checkbox
        checkbox.tap()
        XCTAssertEqual(checkbox.value as? String, "Unchecked")

        // 3. Dismiss splash screen
        app.buttons["Get Started"].tap()

        // 4. Verify home screen is visible
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHomeScreenShowsControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Application Control"].exists)
        XCTAssertTrue(app.staticTexts["Regular Backups"].exists)
    }

    @MainActor
    func testMicrosoft365AdditionalControlsSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
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
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        let aboutButton = app.buttons["About & Privacy"]
        for _ in 0..<3 where !aboutButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
        aboutButton.tap()

        XCTAssertTrue(app.navigationBars["About Essential 8"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Privacy Policy"].exists)
        
        // Verify Rate and Reset buttons are present
        XCTAssertTrue(app.buttons["Rate the App"].exists)
        
        let resetButton = app.buttons["Reset App Data"]
        XCTAssertTrue(resetButton.exists)
        
        // Tap reset and verify warning alert
        resetButton.tap()
        let alert = app.alerts["Reset App Data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        XCTAssertTrue(alert.buttons["Reset"].exists)
        alert.buttons["Cancel"].tap() // Dismiss alert

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
    func testReferenceOnlyModeToggle() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        // 1. Verify "Maturity Dashboard" header exists initially
        XCTAssertTrue(app.staticTexts["Maturity Dashboard"].waitForExistence(timeout: 5))

        // 2. Open About screen
        let aboutButton = app.buttons["About & Privacy"]
        for _ in 0..<3 where !aboutButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
        aboutButton.tap()

        // 3. Find and toggle "Reference Only Mode" to ON
        let toggle = app.switches["Reference Only Mode"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()

        // 4. Dismiss About screen
        app.buttons["Done"].tap()

        // 5. Verify "Maturity Dashboard" is now hidden
        XCTAssertFalse(app.staticTexts["Maturity Dashboard"].exists)

        // 6. Re-open About screen and turn Reference Only Mode OFF
        let aboutButton2 = app.buttons["About & Privacy"]
        for _ in 0..<3 where !aboutButton2.exists {
            app.swipeUp()
        }
        XCTAssertTrue(aboutButton2.waitForExistence(timeout: 5))
        aboutButton2.tap()
        
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
        
        app.buttons["Done"].tap()
        
        // 7. Verify "Maturity Dashboard" is back
        XCTAssertTrue(app.staticTexts["Maturity Dashboard"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTargetMaturityPickerPersistsAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Target Maturity Level"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ML3"].isSelected)

        app.buttons["ML1"].tap()
        XCTAssertTrue(app.buttons["ML1"].isSelected)

        app.terminate()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Target Maturity Level"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ML1"].isSelected)

        app.buttons["ML3"].tap()
    }

    @MainActor
    func testBeyondTargetBadgesShownForLowerTarget() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "1", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Application Control"].waitForExistence(timeout: 5))
        app.staticTexts["Application Control"].tap()

        XCTAssertTrue(app.navigationBars["Mitigation 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Beyond target"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
            app.launch()
        }
    }
}
