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
    func testBlankHomeFixtureShowsEmptySlateWithoutNetworkError() {
        configureApp(fixture: "blank-home")
        app.launch()

        XCTAssertTrue(element("home.stickyHeader").waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.empty.noGames").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No games available"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Unable to load games"].exists)
        XCTAssertFalse(row("9001").exists)
    }

    @MainActor
    func testFutureGameFixtureShowsScheduledHomeRow() {
        configureApp(fixture: "future-game")
        app.launch()

        XCTAssertTrue(element("home.stickyHeader").waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.section.timeline").waitForExistence(timeout: 5))
        XCTAssertTrue(row("9101").waitForExistence(timeout: 5))
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

        selectLeague("NBA")
        XCTAssertTrue(row("9003").waitForExistence(timeout: 3))
        XCTAssertFalse(row("9001").isHittable)

        guard !isRegularWidth else { return }

        selectLeague("All")
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
    func testHomeTeamSearchKeyboardFlowKeepsRowsReachable() throws {
        configureApp()
        app.launch()
        assertHomeLoaded()
        guard !isRegularWidth else {
            throw XCTSkip("Compact-width keyboard route")
        }

        let teamFilter = app.textFields["home.teamFilter"]
        teamFilter.tap()
        teamFilter.typeText("Canyon")

        XCTAssertTrue(element("home.stickyHeader").exists)
        XCTAssertTrue(element("home.leaguePicker").exists)
        XCTAssertTrue(teamFilter.exists)
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))
        XCTAssertFalse(row("9003").isHittable)

        dismissKeyboardIfVisible()
        app.swipeUp()
        XCTAssertTrue(row("9001").exists)

        teamFilter.tap()
        clearTextField(teamFilter)
        teamFilter.typeText("No Such Team")
        dismissKeyboardIfVisible()

        XCTAssertTrue(app.staticTexts["No games match these filters"].waitForExistence(timeout: 3))
        app.buttons["Clear filters"].tap()
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))
        XCTAssertTrue(row("9003").exists)
    }

    @MainActor
    func testPinAndUnpinRealGameWithoutLeavingHome() throws {
        configureApp()
        app.launch()
        assertHomeLoaded()
        guard !isRegularWidth else {
            throw XCTSkip("Compact-width home pin route")
        }
        XCTAssertFalse(app.staticTexts["Sample Game"].exists)

        let pin = app.buttons["home.gameRow.9001.pin"]
        XCTAssertTrue(pin.waitForExistence(timeout: 3))
        XCTAssertEqual(pin.label, "Pin game")
        tap(pin)

        let unpin = app.buttons["home.gameRow.9001.pin"]
        XCTAssertTrue(unpin.waitForExistence(timeout: 3))
        XCTAssertEqual(unpin.label, "Unpin game")
        XCTAssertTrue(element("home.section.pinned").waitForExistence(timeout: 3))

        tap(unpin)
        XCTAssertTrue(app.buttons["home.gameRow.9001.pin"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["home.gameRow.9001.pin"].label, "Pin game")
        if !isRegularWidth {
            XCTAssertTrue(app.navigationBars["Scroll Down"].exists)
        }
    }

    @MainActor
    func testOpenFinalGameScorePlacementAndModeLabels() {
        configureApp()
        app.launch()
        openFinalGame()

        assertDetailHeaderContains(["Harbor Pilots", "Canyon Owls", "Final"])
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
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))
    }

    @MainActor
    func testResumeBackAndStickyNavigationDoNotStrandUser() {
        configureApp()
        app.launch()
        openFinalGame()

        XCTAssertTrue(element("detail.playByPlay").waitForExistence(timeout: 5))
        let savedSpot = element("detail.event.evt-9001-003")
        XCTAssertTrue(savedSpot.exists)

        if isRegularWidth {
            tap(row("9003"))
            assertHomeAndDetailCoexist(gameId: "9003")
            assertDetailHeaderContains(["Prairie Jets"])
            tap(row("9001"))
        } else {
            app.navigationBars["Catch Up"].buttons.element(boundBy: 0).tap()
            XCTAssertTrue(element("home.stickyHeader").waitForExistence(timeout: 5))
            openFinalGame()
        }

        XCTAssertTrue(element("detail.resumeBanner").waitForExistence(timeout: 5))
        let resumeMore = app.buttons["detail.resume.more"]
        XCTAssertTrue(resumeMore.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "detail.resume").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "detail.resume.more").count, 1)
        XCTAssertEqual(resumeMore.label, "More resume actions")
        assertMinimumTapTarget(resumeMore, named: "Resume actions")
        XCTAssertTrue(app.buttons["detail.resume"].isHittable)

        XCTAssertTrue(element("detail.stickyNav").waitForExistence(timeout: 5))
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))

        XCTAssertTrue(app.buttons["detail.stickyNav.return"].waitForExistence(timeout: 5))
        app.buttons["detail.stickyNav.return"].tap()
        XCTAssertTrue(element("detail.playByPlay").waitForExistence(timeout: 5))

        if app.buttons["detail.stickyNav.top"].waitForExistence(timeout: 5) {
            app.buttons["detail.stickyNav.top"].tap()
            XCTAssertTrue(element("detail.header").waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testIPadSmokeRoutePreservesSplitSelectionAndHomeState() throws {
        configureApp()
        app.launch()
        assertHomeLoaded()
        guard isRegularWidth else {
            throw XCTSkip("Regular-width iPad smoke route")
        }

        openFinalGame()
        assertHomeAndDetailCoexist(gameId: "9001")

        XCTAssertTrue(element("detail.stickyNav").waitForExistence(timeout: 5))
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))

        selectLeague("NBA")
        XCTAssertTrue(row("9003").waitForExistence(timeout: 3))
        XCTAssertTrue(element("home.stickyHeader").exists)
        XCTAssertTrue(element("home.section.timeline").exists)

        tap(row("9003"))
        assertHomeAndDetailCoexist(gameId: "9003")
        assertDetailHeaderContains(["Prairie Jets", "Summit Bears"])
    }

    @MainActor
    private func configureApp(fixture: String = "critical-final-game") {
        continueAfterFailure = false
        app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["SDS_UI_TEST_FIXTURE"] = fixture
        app.launchEnvironment["SDS_RESET_STATE"] = "1"
    }

    @MainActor
    private func assertHomeLoaded() {
        XCTAssertTrue(element("home.stickyHeader").waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.leaguePicker").exists)
        XCTAssertTrue(app.textFields["home.teamFilter"].exists)
        XCTAssertTrue(element("home.section.timeline").waitForExistence(timeout: 5))
        XCTAssertTrue(row("9001").waitForExistence(timeout: 5))
        if !isRegularWidth {
            XCTAssertTrue(app.navigationBars["Scroll Down"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    private func openFinalGame() {
        assertHomeLoaded()
        tap(row("9001"))
        XCTAssertTrue(element("detail.header").waitForExistence(timeout: 5))
        if isRegularWidth {
            assertHomeAndDetailCoexist(gameId: "9001")
        } else {
            XCTAssertTrue(app.navigationBars["Catch Up"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    private var isRegularWidth: Bool {
        app.frame.width >= 900
    }

    @MainActor
    private func assertHomeAndDetailCoexist(gameId: String) {
        XCTAssertTrue(element("home.stickyHeader").exists)
        XCTAssertTrue(element("home.section.timeline").exists)
        XCTAssertTrue(row(gameId).exists)
        XCTAssertTrue(element("detail.header").waitForExistence(timeout: 5))
        XCTAssertTrue(element("detail.streamControls").waitForExistence(timeout: 5))
        XCTAssertTrue(element("detail.playByPlay").waitForExistence(timeout: 5))
    }

    @MainActor
    private func selectLeague(_ league: String, file: StaticString = #filePath, line: UInt = #line) {
        let directButton = app.buttons[league]
        if directButton.exists {
            tap(directButton)
            return
        }

        let picker = app.buttons["home.leaguePicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 3), "League picker is missing", file: file, line: line)
        tap(picker)

        let menuButton = app.buttons[league]
        if menuButton.waitForExistence(timeout: 3) {
            tap(menuButton)
            return
        }

        let menuText = app.staticTexts[league]
        XCTAssertTrue(menuText.waitForExistence(timeout: 3), "League option \(league) is missing", file: file, line: line)
        tap(menuText)
    }

    @MainActor
    private func assertDetailHeaderContains(
        _ expectedParts: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let firstPart = expectedParts.first else { return }
        let predicate = NSPredicate(format: "label CONTAINS %@", firstPart)
        let header = app.descendants(matching: .any)
            .matching(identifier: "detail.header")
            .matching(predicate)
            .firstMatch

        XCTAssertTrue(header.waitForExistence(timeout: 5), "No detail header contained \(firstPart)", file: file, line: line)
        for part in expectedParts.dropFirst() {
            XCTAssertTrue(header.label.contains(part), "Detail header missing \(part): \(header.label)", file: file, line: line)
        }
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
    private func finalScore() -> XCUIElement {
        app.staticTexts["detail.boxScore.finalScore"]
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
    private func assertMinimumTapTarget(_ element: XCUIElement, named name: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 3), "\(name) does not exist")
        XCTAssertGreaterThanOrEqual(element.frame.width, 44, "\(name) width is below 44 points")
        XCTAssertGreaterThanOrEqual(element.frame.height, 44, "\(name) height is below 44 points")
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
    private func dismissKeyboardIfVisible() {
        let done = app.buttons["home.teamFilter.done"]
        if done.waitForExistence(timeout: 1) {
            done.tap()
            return
        }

        let search = app.keyboards.buttons["Search"]
        if search.waitForExistence(timeout: 1) {
            search.tap()
            return
        }

        if app.keyboards.firstMatch.exists {
            app.keyboards.firstMatch.typeText("\n")
        }
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
