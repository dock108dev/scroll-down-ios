@preconcurrency import XCTest

final class ScrollDownSportsPerformanceSmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    func testLongLiveDetailAppendAndFiltersStayUsable() {
        configureApp()
        app.launch()
        assertHomeLoaded()

        let timing = SmokeUITiming()
        timing.measure("open 90-event detail") {
            selectLeague("MLB")
            let teamFilter = app.textFields["home.teamFilter"]
            XCTAssertTrue(teamFilter.waitForExistence(timeout: 3))
            teamFilter.tap()
            teamFilter.typeText("Harbor Club 0")
            XCTAssertTrue(row("9101").waitForExistence(timeout: 5))
            tap(row("9101"))
            XCTAssertTrue(app.navigationBars["Catch Up"].waitForExistence(timeout: 8))
            XCTAssertTrue(element("detail.event.evt-perf-001").waitForExistence(timeout: 8))
        }

        app.buttons["All Plays"].tap()
        scrollUntilVisible(element("detail.event.evt-perf-045"), direction: .up, maxSwipes: 14)
        XCTAssertTrue(element("detail.event.evt-perf-045").exists)

        timing.measure("append while reading away") {
            app.buttons["detail.refresh"].tap()
            XCTAssertTrue(waitForPendingNewPlays(count: 15))
            XCTAssertTrue(element("detail.event.evt-perf-045").exists)
        }

        timing.measure("jump latest exposes return affordance") {
            jumpToPendingLatest()
            XCTAssertTrue(app.buttons["detail.stickyNav.return"].waitForExistence(timeout: 5))
        }

        XCTAssertLessThan(timing.maxDuration, 120)
        XCTContext.runActivity(named: "performance smoke UI timings") { activity in
            activity.add(XCTAttachment(string: timing.report))
        }
    }

    @MainActor
    private func configureApp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["SDS_UI_TEST_FIXTURE"] = "performance-long-stream"
        app.launchEnvironment["SDS_RESET_STATE"] = "1"
    }

    @MainActor
    private func assertHomeLoaded() {
        XCTAssertTrue(app.navigationBars["Scroll Down"].waitForExistence(timeout: 8))
        XCTAssertTrue(element("home.stickyHeader").waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.leaguePicker").exists)
        XCTAssertTrue(app.textFields["home.teamFilter"].exists)
        XCTAssertTrue(row("9101").waitForExistence(timeout: 8))
    }

    @MainActor
    private func row(_ id: String) -> XCUIElement {
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
    private func waitForPendingNewPlays(count: Int) -> Bool {
        let newPlays = app.buttons["detail.newPlaysAffordance"]
        if newPlays.waitForExistence(timeout: 2) {
            return newPlays.label.contains("\(count) new plays")
        }

        let inlineJump = app.buttons["detail.jumpEnd"]
        if inlineJump.waitForExistence(timeout: 2) {
            return element("detail.streamControls").label.contains("\(count) new")
        }

        if element("detail.stickyNav").waitForExistence(timeout: 5) {
            return element("detail.stickyNav").label.contains("\(count) new")
        }

        return false
    }

    @MainActor
    private func jumpToPendingLatest() {
        let stickyEnd = app.buttons["detail.stickyNav.end"]
        if stickyEnd.waitForExistence(timeout: 1) {
            stickyEnd.tap()
            return
        }

        let newPlays = app.buttons["detail.newPlaysAffordance"]
        if newPlays.waitForExistence(timeout: 1) {
            newPlays.tap()
            return
        }

        let inlineJump = app.buttons["detail.jumpEnd"]
        if inlineJump.waitForExistence(timeout: 1) {
            inlineJump.tap()
            return
        }

        XCTAssertTrue(stickyEnd.waitForExistence(timeout: 5))
        stickyEnd.tap()
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
    private func clearTextField(_ textField: XCUIElement) {
        textField.tap()
        guard let value = textField.value as? String, !value.isEmpty else { return }
        textField.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) {
            app.menuItems["Select All"].tap()
        }
        textField.typeText(XCUIKeyboardKey.delete.rawValue)
    }
}

private final class SmokeUITiming {
    private(set) var samples: [(String, TimeInterval)] = []

    var maxDuration: TimeInterval {
        samples.map(\.1).max() ?? 0
    }

    var report: String {
        samples
            .map { "\($0.0): \(String(format: "%.4f", $0.1))s" }
            .joined(separator: "\n")
    }

    func measure(_ name: String, operation: () -> Void) {
        let start = Date()
        operation()
        samples.append((name, Date().timeIntervalSince(start)))
    }
}
