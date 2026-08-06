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
        // `showSplashOnStartup` is deliberately NOT passed as a launch argument. Launch
        // arguments land in NSArgumentDomain, which UserDefaults resolves ahead of the
        // app's persistent domain — so a setting pinned there can never be changed from
        // the UI, and this test needs to toggle it. The @AppStorage default is true.
        app.launchArguments = ["-targetMaturityLevel", "3", "-referenceOnlyMode", "NO", "-osScopeFilter", "both"]
        app.launch()

        // 1. Verify splash elements are present
        XCTAssertTrue(app.staticTexts["Essential 8"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["What's New in Version 1.8"].exists)

        let checkbox = app.buttons["Always show on startup"]
        XCTAssertTrue(checkbox.exists)
        XCTAssertEqual(checkbox.value as? String, "Checked")

        // 2. Toggle checkbox off, then back on so the next run still sees the splash.
        checkbox.tap()
        waitForValue("Unchecked", on: checkbox)
        checkbox.tap()
        waitForValue("Checked", on: checkbox)

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
        scrollTo(app.staticTexts["Regular Backups"], in: app)
        scrollTo(app.buttons["MITRE ATT&CK® Coverage"], in: app)
    }

    @MainActor
    func testAttackCoverageScreenIsReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["MITRE ATT&CK® Coverage"], in: app).tap()

        XCTAssertTrue(app.navigationBars["ATT&CK Coverage"].waitForExistence(timeout: 5))
        // Tactic sections sit below the summary header, and each header carries a
        // count — "Initial Access (5)" — so match on the prefix.
        let tacticHeader = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Initial Access")
        ).firstMatch
        scrollTo(tacticHeader, in: app)
    }

    @MainActor
    func testMicrosoft365AdditionalControlsSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["M365 Additional Controls"], in: app).tap()

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

        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        openAbout(app)
        XCTAssertTrue(app.staticTexts["Privacy Policy"].exists)
        
        // Verify Rate and Reset buttons are present
        scrollTo(app.buttons["Rate the App"], in: app)
        let resetButton = scrollTo(app.buttons["Reset App Data"], in: app)

        // Tap reset and verify warning alert
        resetButton.tap()
        let alert = app.alerts["Reset App Data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        XCTAssertTrue(alert.buttons["Reset"].exists)
        alert.buttons["Cancel"].tap() // Dismiss alert

        let essentialEightReference = app.staticTexts["ASD Essential Eight maturity model"]
        scrollTo(essentialEightReference, in: app)
        scrollTo(app.staticTexts["ASD Information Security Manual"], in: app)
        scrollToTop(app)
        scrollUntilExists(anyElement(containing: "does not collect", in: app), in: app)

        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testReferenceOnlyModeToggle() throws {
        let app = XCUIApplication()
        // `referenceOnlyMode` is deliberately NOT passed as a launch argument — this
        // test toggles it, and NSArgumentDomain would override anything the app writes.
        // The @AppStorage default is false, which is the state this test starts from.
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3"]
        app.launch()

        // 1. Verify "Maturity Dashboard" header exists initially
        XCTAssertTrue(app.staticTexts["Maturity Dashboard"].waitForExistence(timeout: 5))

        // 2. Open About screen
        openAbout(app)

        // 3. Find and toggle "Reference Only Mode" to ON
        setSwitch("Reference Only Mode", to: true, in: app)

        // 4. Dismiss About screen
        app.buttons["Done"].tap()

        // 5. Verify "Maturity Dashboard" is now hidden. Scroll back to the top first:
        // reaching About scrolled Home down, and a negative existence check is only
        // meaningful when the element would be on screen if it were there at all.
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        scrollToTop(app)
        XCTAssertFalse(app.staticTexts["Maturity Dashboard"].exists)
        XCTAssertFalse(app.buttons["MITRE ATT&CK® Coverage"].exists)

        // The rollup is a NavigationLink, so it surfaces as a button rather than a
        // static text. Match any element type so the assertion cannot pass merely
        // because it was looking at the wrong one.
        app.staticTexts["Application Control"].tap()
        XCTAssertTrue(app.navigationBars["Mitigation 1"].waitForExistence(timeout: 5))
        let rollup = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "ATT&CK techniques mapped")
        )
        XCTAssertEqual(rollup.count, 0)
        app.navigationBars["Mitigation 1"].buttons.element(boundBy: 0).tap()

        // 6. Re-open About screen and turn Reference Only Mode OFF
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        openAbout(app)

        setSwitch("Reference Only Mode", to: false, in: app)

        app.buttons["Done"].tap()
        
        // 7. Verify "Maturity Dashboard" is back
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        scrollToTop(app)
        XCTAssertTrue(app.staticTexts["Maturity Dashboard"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttackTechniqueCapsulePresentsDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO", "-osScopeFilter", "both"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Application Control"].waitForExistence(timeout: 5))
        app.staticTexts["Application Control"].tap()

        XCTAssertTrue(app.navigationBars["Mitigation 1"].waitForExistence(timeout: 5))
        scrollTo(maturityRow("ML1", in: app), in: app).tap()

        // T1204.002 is mapped from several steps on this level, so this identifier
        // matches more than one capsule — take the first rather than an ambiguous query.
        let capsule = app.buttons["attack-technique-T1204.002"].firstMatch
        XCTAssertTrue(capsule.waitForExistence(timeout: 5))
        scrollTo(capsule, in: app).tap()

        XCTAssertTrue(app.navigationBars["ATT&CK Technique"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Malicious File"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTargetMaturityPickerPersistsAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Target Maturity Level"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ML3"].isSelected)

        selectSegment("ML1", in: app)

        app.terminate()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-referenceOnlyMode", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Target Maturity Level"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ML1"].isSelected)

        // Restore the default target, and confirm it took — an unverified restore
        // leaves the next test running against ML1.
        selectSegment("ML3", in: app)
    }

    @MainActor
    func testBeyondTargetBadgesShownForLowerTarget() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "1", "-referenceOnlyMode", "NO"]
        app.launch()

        // Since v1.7 the target maturity level lives on the active profile, and the
        // `-targetMaturityLevel` launch argument is only consulted on the one-time
        // migration path — so set it through the UI, then restore it afterwards.
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        selectSegment("ML1", in: app)

        scrollTo(app.staticTexts["Application Control"], in: app).tap()

        XCTAssertTrue(app.navigationBars["Mitigation 1"].waitForExistence(timeout: 5))
        // "Beyond target" is rendered inside a NavigationLink label, which SwiftUI
        // flattens into the row's own accessibility element.
        scrollUntilExists(anyElement(containing: "Beyond target", in: app), in: app)

        app.navigationBars["Mitigation 1"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        selectSegment("ML3", in: app)
    }

    @MainActor
    func testAboutShowsScopePickerAndDynamicVersion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-osScopeFilter", "both"]
        app.launch()

        openAbout(app)

        selectSegment("Both", in: app)
        let version = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "Version [0-9]+\\.[0-9]+ \\([0-9]+\\)")).firstMatch
        scrollTo(version, in: app)
    }

    @MainActor
    func testAssessmentFeatureTogglesRevealProfiles() throws {
        let app = XCUIApplication()
        // `multiProfileEnabled` is deliberately NOT passed — this test toggles it, and
        // NSArgumentDomain would override the write. The @AppStorage default is false.
        app.launchArguments = ["-showSplashOnStartup", "NO", "-deepAuditEnabled", "NO"]
        app.launch()

        openAbout(app)

        scrollTo(app.switches["Multiple Profiles"], in: app)
        XCTAssertTrue(app.switches["Deep Audit Mode"].exists)
        // Go through enableSwitch rather than a bare flip: a coordinate tap on a list
        // toggle is occasionally swallowed, and an unverified flip leaves the Profiles
        // row absent for no visible reason.
        enableSwitch("Multiple Profiles", in: app)
        scrollTo(profilesRow(in: app), in: app)
    }

    @MainActor
    func testSecondProfileAndContextPersistAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-multiProfileEnabled", "YES"]
        app.launch()

        openAbout(app)
        openProfiles(app)
        let field = openCreateProfileAlert(app)
        field.typeText("Client A")
        app.alerts["Create Profile"].buttons["Create"].tap()
        app.navigationBars["Profiles"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["About Essential 8"].waitForExistence(timeout: 5))
        selectSegment("Server", in: app)
        app.buttons["Done"].tap()

        app.terminate()
        app.launchArguments = ["-showSplashOnStartup", "NO"]
        app.launch()
        openAbout(app)
        enableSwitch("Multiple Profiles", in: app)
        scrollTo(anyElement(containing: "Client A", in: app), in: app)
        scrollTo(app.buttons["Server"], in: app)
        waitUntilSelected(app.buttons["Server"])
    }

    @MainActor
    func testWorkstationScopePersistsAndReducesBackupStepCount() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "1", "-osScopeFilter", "both"]
        app.launch()

        openAbout(app)
        selectSegment("Workstation", in: app)
        app.buttons["Done"].tap()

        app.terminate()
        app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "1"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))

        // The step count below assumes an ML1 target. `-targetMaturityLevel` no longer
        // sets that (it lives on the profile since v1.7), so select it in the UI.
        selectSegment("ML1", in: app)

        scrollTo(app.staticTexts["Regular Backups"], in: app).tap()
        XCTAssertTrue(app.navigationBars["Mitigation 8"].waitForExistence(timeout: 5))
        scrollTo(app.staticTexts["0 of 2 steps complete"], in: app)

        // Restore the default target so later runs start from a known state.
        app.navigationBars["Mitigation 8"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Essential 8 Knowledge Base"].waitForExistence(timeout: 5))
        selectSegment("ML3", in: app)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-showSplashOnStartup", "NO", "-targetMaturityLevel", "3", "-referenceOnlyMode", "NO"]
            app.launch()
        }
    }

    // MARK: - Helpers

    /// Scrolls down until `element` is on screen and returns it.
    ///
    /// SwiftUI's `List` only materialises the rows it is currently displaying, so an
    /// off-screen row genuinely does not exist in the accessibility hierarchy until it
    /// has been scrolled into view. Asserting `.exists` on a row below the fold fails
    /// on smaller devices even though the row is present in the app.
    @MainActor
    @discardableResult
    private func scrollTo(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return element }
            let container = scrollContainer(in: app)
            // Once a row has been realised its frame is known even off screen, so
            // scroll back up if we have overshot rather than dragging blindly on.
            let overshot = element.exists
                && element.frame.height > 0
                && element.frame.midY < container.frame.minY
            drag(container, towards: overshot ? .up : .down)
        }
        XCTAssertTrue(
            element.exists && element.isHittable,
            "Could not scroll to element after \(maxSwipes) drags",
            file: file,
            line: line
        )
        return element
    }

    /// The scrollable container to drive. Swiping the application element does not
    /// scroll content inside a presented sheet, so prefer the topmost list or scroll
    /// view — when a sheet is up, that is the sheet's own.
    @MainActor
    private func scrollContainer(in app: XCUIApplication) -> XCUIElement {
        for query in [app.collectionViews, app.tables, app.scrollViews] {
            if let topmost = query.allElementsBoundByIndex.last(where: { $0.isHittable }) {
                return topmost
            }
        }
        return app
    }

    /// Taps the switch control itself rather than the element's centre. A SwiftUI
    /// `Toggle` in a `List` reports a frame spanning the whole row, and tapping the
    /// label half of that row does not flip the switch.
    @MainActor
    private func flip(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
    }

    /// Drives a SwiftUI list toggle to a known state without assuming the first
    /// coordinate tap lands. Re-resolve the switch between attempts because toggling
    /// can rebuild its row. Idempotent: a switch already in `state` is left alone.
    @MainActor
    private func setSwitch(
        _ label: String,
        to state: Bool,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let wanted = state ? "1" : "0"
        for _ in 0..<2 {
            let toggle = scrollTo(app.switches[label], in: app)
            if toggle.value as? String == wanted { return }
            flip(toggle)
            let settled = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", wanted), object: toggle
            )
            if XCTWaiter().wait(for: [settled], timeout: 5) == .completed { return }
        }
        XCTAssertEqual(
            app.switches[label].value as? String,
            wanted,
            "Switch '\(label)' never reached \(state ? "on" : "off")",
            file: file,
            line: line
        )
    }

    @MainActor
    private func enableSwitch(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        setSwitch(label, to: true, in: app, file: file, line: line)
    }

    /// Selects a segmented-control option, retrying once if the first tap is swallowed.
    @MainActor
    private func selectSegment(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<2 {
            let option = scrollTo(app.buttons[label], in: app)
            if option.isSelected { return }
            option.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: option
            )
            if XCTWaiter().wait(for: [selected], timeout: 5) == .completed { return }
        }
        XCTAssertTrue(
            app.buttons[label].isSelected,
            "Segment '\(label)' never became selected",
            file: file,
            line: line
        )
    }

    /// The control-detail maturity row for `shortName`, matched on its leading badge.
    @MainActor
    private func maturityRow(_ shortName: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", shortName)).firstMatch
    }

    /// Opens the About sheet, retrying once. The first tap is occasionally swallowed
    /// while the home list is still settling after being scrolled.
    @MainActor
    private func openAbout(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let about = app.navigationBars["About Essential 8"]
        for _ in 0..<2 {
            scrollTo(app.buttons["About & Privacy"], in: app).tap()
            if about.waitForExistence(timeout: 5) { return }
        }
        XCTAssertTrue(about.exists, "About sheet never presented", file: file, line: line)
    }

    /// Opens Profiles from About, retrying once if the navigation-link tap is swallowed.
    @MainActor
    private func openProfiles(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let profiles = app.navigationBars["Profiles"]
        for _ in 0..<2 {
            scrollTo(profilesRow(in: app), in: app).tap()
            if profiles.waitForExistence(timeout: 5) { return }
        }
        XCTAssertTrue(profiles.exists, "Profiles screen never presented", file: file, line: line)
    }

    /// Presents the Create Profile alert, retrying once if the toolbar tap is swallowed.
    @MainActor
    private func openCreateProfileAlert(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let field = app.textFields["Profile name"]
        for _ in 0..<2 {
            if field.exists { return field }
            let addProfile = app.buttons["Add Profile"]
            guard addProfile.waitForExistence(timeout: 5) else { break }
            addProfile.tap()
            if field.waitForExistence(timeout: 5) { return field }
        }
        XCTAssertTrue(field.exists, "Create Profile alert never presented", file: file, line: line)
        return field
    }

    /// The About sheet's Profiles navigation row. Restricted to buttons so it cannot
    /// also match the "Multiple Profiles" switch above it, which is not a button.
    @MainActor
    private func profilesRow(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Profiles")).firstMatch
    }

    /// Scrolls until `element` is merely present. Text nested inside a composed row
    /// exists in the hierarchy but is never hittable in its own right, so `scrollTo`
    /// would never be satisfied by it.
    @MainActor
    @discardableResult
    private func scrollUntilExists(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxDrags: Int = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        for _ in 0..<maxDrags {
            if element.exists { return element }
            drag(scrollContainer(in: app), towards: .down)
        }
        XCTAssertTrue(element.exists, "Element never appeared", file: file, line: line)
        return element
    }

    /// First element of any type whose label contains `text`. SwiftUI decides for
    /// itself whether a row surfaces as a button, a cell or plain static text, and that
    /// varies with how the row's label is composed — so do not assume a type.
    @MainActor
    private func anyElement(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    private enum DragDirection { case up, down }

    /// Drags the container by roughly 40% of its height. `swipeUp()`/`swipeDown()`
    /// fling with momentum, which in a long list overshoots the target by an
    /// unpredictable amount and makes these tests flaky. A pressed drag does not.
    @MainActor
    private func drag(_ container: XCUIElement, towards direction: DragDirection) {
        let near = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let far = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        switch direction {
        case .down: near.press(forDuration: 0.1, thenDragTo: far)
        case .up: far.press(forDuration: 0.1, thenDragTo: near)
        }
    }

    /// Scrolls back to the top, so a negative existence assertion is not satisfied
    /// merely because the list happens to be scrolled past the element.
    @MainActor
    private func scrollToTop(_ app: XCUIApplication, drags: Int = 10) {
        let container = scrollContainer(in: app)
        for _ in 0..<drags { drag(container, towards: .up) }
    }

    /// Waits for a segmented-control option to report itself selected. The tap returns
    /// before SwiftUI has republished the new selection.
    @MainActor
    private func waitUntilSelected(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == true"), object: element
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [selected], timeout: timeout),
            .completed,
            "Element never became selected",
            file: file,
            line: line
        )
    }

    /// Waits for `element` to report `value`, rather than reading it straight after a
    /// tap. A tap returns as soon as the event is delivered — SwiftUI may not have
    /// re-rendered and republished the accessibility value yet.
    @MainActor
    private func waitForValue(
        _ value: String,
        on element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "value == %@", value)
        let matched = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [matched], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected value '\(value)', got '\(String(describing: element.value))'",
            file: file,
            line: line
        )
    }
}
