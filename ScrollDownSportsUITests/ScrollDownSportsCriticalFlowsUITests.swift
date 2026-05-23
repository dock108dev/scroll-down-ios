@preconcurrency import XCTest

final class ScrollDownSportsCriticalFlowsUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    func testFirstLaunchShowsUsableHomeContent() {
        configureApp()
        app.launch()
        assertHomeLoaded()
        XCTAssertTrue(row("9001").isHittable || row("9001").exists)
        XCTAssertFalse(app.staticTexts["Unable to load games"].exists)
        XCTAssertFalse(app.staticTexts["No games match these filters"].exists)
    }

    @MainActor
    func testHomeInitialAnchorAndTimelineReachability() {
        configureApp()
        app.launchEnvironment["SDS_HOME_INITIAL_ANCHOR"] = "timeline"
        app.launch()
        assertHomeLoaded()

        let header = element("home.stickyHeader")
        let timeline = element("home.section.timeline")
        XCTAssertTrue(header.exists)
        XCTAssertTrue(timeline.waitForExistence(timeout: 5))
        XCTAssertLessThan(timeline.frame.minY, app.frame.height * 0.65)

        scrollUntilVisible(element("home.dateSection.timeline-yesterday"), direction: .down, maxSwipes: 5)
        XCTAssertTrue(element("home.dateSection.timeline-yesterday").exists)

        scrollUntilVisible(element("home.dateSection.timeline-upcoming"), direction: .up, maxSwipes: 8)
        XCTAssertTrue(element("home.dateSection.timeline-upcoming").exists)
        XCTAssertTrue(header.exists)
    }

    @MainActor
    func testHomeHidesPlaceholderCopyAndSupportsFilters() {
        configureApp()
        app.launch()
        assertHomeLoaded()
        assertNoPlaceholderLabels()
        XCTAssertFalse(app.staticTexts["TBD"].exists)

        app.buttons["NBA"].tap()
        XCTAssertTrue(row("9003").waitForExistence(timeout: 3))
        XCTAssertFalse(row("9001").isHittable)

        app.buttons["All"].tap()
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))

        let teamFilter = app.textFields["home.teamFilter"]
        XCTAssertTrue(teamFilter.waitForExistence(timeout: 3))
        teamFilter.tap()
        teamFilter.typeText("Canyon")
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))
        XCTAssertFalse(row("9003").isHittable)

        clearTextField(teamFilter)
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))
        XCTAssertTrue(row("9003").exists)
    }

    @MainActor
    func testPinAndUnpinRealGameWithoutLeavingHome() {
        configureApp()
        app.launch()
        assertHomeLoaded()
        XCTAssertFalse(app.staticTexts["Sample Game"].exists)

        let pin = app.buttons["home.gameRow.9001.pin"]
        XCTAssertTrue(pin.waitForExistence(timeout: 3))
        XCTAssertEqual(pin.label, "Pin game")
        pin.tap()

        let unpin = app.buttons["home.gameRow.9001.pin"]
        XCTAssertTrue(unpin.waitForExistence(timeout: 3))
        XCTAssertEqual(unpin.label, "Unpin game")
        XCTAssertTrue(element("home.section.pinned").waitForExistence(timeout: 3))

        unpin.tap()
        XCTAssertTrue(app.buttons["home.gameRow.9001.pin"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["home.gameRow.9001.pin"].label, "Pin game")
        XCTAssertTrue(app.navigationBars["Scroll Down"].exists)
    }

    @MainActor
    func testOpenFinalGameScorePlacementAndModeLabels() {
        configureApp()
        app.launch()
        openFinalGame()

        let header = element("detail.header")
        XCTAssertTrue(header.exists)
        XCTAssertTrue(header.label.contains("Harbor Pilots"))
        XCTAssertTrue(header.label.contains("Canyon Owls"))
        XCTAssertTrue(header.label.contains("Final"))
        XCTAssertTrue(element("detail.streamControls").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Important"].exists)
        XCTAssertTrue(app.buttons["Standard"].exists)
        XCTAssertTrue(app.buttons["All Plays"].exists)
        XCTAssertFalse(app.buttons["timeline"].exists)
        XCTAssertFalse(app.buttons["stream"].exists)
        XCTAssertFalse(app.buttons["flow"].exists)

        XCTAssertTrue(element("detail.playByPlay").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Harbor Pilots 5, Canyon Owls 3"].isHittable)

        XCTAssertTrue(element("detail.event.evt-9001-003").exists)

        XCTAssertTrue(element("detail.stickyNav").waitForExistence(timeout: 5))
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(element("detail.boxScore.finalScore").waitForExistence(timeout: 8))
    }

    @MainActor
    func testResumeBackAndStickyNavigationDoNotStrandUser() {
        configureApp()
        app.launch()
        openFinalGame()

        XCTAssertTrue(element("detail.playByPlay").waitForExistence(timeout: 5))
        let savedSpot = element("detail.event.evt-9001-003")
        XCTAssertTrue(savedSpot.exists)

        app.navigationBars["Catch Up"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Scroll Down"].waitForExistence(timeout: 5))
        openFinalGame()

        XCTAssertTrue(element("detail.resumeBanner").waitForExistence(timeout: 5))
        app.buttons["detail.resume"].tap()
        XCTAssertTrue(element("detail.event.evt-9001-003").waitForExistence(timeout: 5))

        XCTAssertTrue(element("detail.stickyNav").waitForExistence(timeout: 5))
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(element("detail.boxScore.finalScore").waitForExistence(timeout: 8))

        XCTAssertTrue(app.buttons["detail.stickyNav.return"].waitForExistence(timeout: 5))
        app.buttons["detail.stickyNav.return"].tap()
        XCTAssertTrue(element("detail.event.evt-9001-003").waitForExistence(timeout: 5))

        if app.buttons["detail.stickyNav.top"].waitForExistence(timeout: 5) {
            app.buttons["detail.stickyNav.top"].tap()
            XCTAssertTrue(element("detail.header").waitForExistence(timeout: 5))
        }
    }

    @MainActor
    private func configureApp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["SDS_UI_TEST_FIXTURE"] = "critical-final-game"
        app.launchEnvironment["SDS_RESET_STATE"] = "1"
    }

    @MainActor
    private func assertHomeLoaded() {
        XCTAssertTrue(app.navigationBars["Scroll Down"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.stickyHeader").waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.leaguePicker").exists)
        XCTAssertTrue(app.textFields["home.teamFilter"].exists)
        XCTAssertTrue(element("home.section.timeline").waitForExistence(timeout: 5))
        XCTAssertTrue(row("9001").waitForExistence(timeout: 5))
    }

    @MainActor
    private func openFinalGame() {
        assertHomeLoaded()
        tap(row("9001"))
        XCTAssertTrue(app.navigationBars["Catch Up"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func row(_ id: String) -> XCUIElement {
        let button = app.buttons["home.gameRow.\(id)"]
        if button.exists {
            return button
        }
        return element("home.gameRow.\(id)")
    }

    @MainActor
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func tap(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
            return
        }

        let frame = element.frame
        let x = min(max(frame.midX, app.frame.minX + 32), app.frame.maxX - 32)
        let y = min(max(frame.maxY - 6, app.frame.minY + 128), app.frame.maxY - 64)
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }

    private enum ScrollDirection {
        case up
        case down
    }

    @MainActor
    private func scrollUntilVisible(_ element: XCUIElement, direction: ScrollDirection, maxSwipes: Int) {
        for _ in 0..<maxSwipes where !element.isHittable {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            }
        }
    }

    @MainActor
    private func anyHittable(_ elements: [XCUIElement]) -> Bool {
        elements.contains { $0.exists && $0.isHittable }
    }

    @MainActor
    private func clearTextField(_ textField: XCUIElement) {
        textField.tap()
        let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: textField.valueText.count)
        textField.typeText(delete)
    }

    @MainActor
    private func assertNoPlaceholderLabels() {
        let forbidden = [
            "TBD",
            "Fake",
            "Placeholder",
            "Sample Game",
            "Demo Game",
            "Unknown Team",
            "Team A",
            "Team B"
        ]
        let labels = app.staticTexts.allElementsBoundByIndex.map { $0.label }.joined(separator: "\n").lowercased()
        for term in forbidden {
            XCTAssertFalse(labels.contains(term.lowercased()), "Found forbidden placeholder term: \(term)")
        }
    }
}

private extension XCUIElement {
    @MainActor
    var valueText: String {
        (value as? String) ?? ""
    }
}
