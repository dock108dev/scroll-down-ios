@preconcurrency import XCTest

final class ScrollDownSportsAccessibilityUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    func testHomeAccessibilityAuditAndSemanticLabels() throws {
        configureApp()
        app.launch()
        assertHomeLoaded()

        try runAccessibilityAudit()

        let game = row("9001")
        XCTAssertTrue(game.label.contains("Harbor Pilots"))
        XCTAssertTrue(game.label.contains("Canyon Owls"))
        XCTAssertTrue(game.label.localizedCaseInsensitiveContains("final"))
        XCTAssertEqual(app.buttons.matching(identifier: "home.gameRow.9001").count, 1)

        assertNonEmptyLabelsForInteractiveElements()
        assertNoRawEnumLeakage()
        assertMinimumTapTarget(app.buttons["home.gameRow.9001.pin"], named: "Home pin")
    }

    @MainActor
    func testGameDetailAccessibilityAuditReachabilityAndTapTargets() throws {
        configureApp()
        app.launch()
        openFinalGame()

        try runAccessibilityAudit()

        let header = element("detail.header")
        XCTAssertTrue(header.label.contains("Harbor Pilots"))
        XCTAssertTrue(header.label.contains("Canyon Owls"))
        XCTAssertTrue(header.label.localizedCaseInsensitiveContains("final"))

        XCTAssertTrue(element("detail.playByPlay").exists)
        XCTAssertTrue(element("detail.event.evt-9001-003").exists)
        XCTAssertTrue(element("detail.streamControls").exists)
        XCTAssertTrue(app.buttons["Important"].exists)
        XCTAssertTrue(app.buttons["Standard"].exists)
        XCTAssertTrue(app.buttons["All Plays"].exists)

        assertNonEmptyLabelsForInteractiveElements()
        assertNoRawEnumLeakage()
        assertMinimumTapTarget(app.buttons["detail.gameActions"], named: "Detail actions")
        assertMinimumTapTarget(app.buttons["detail.stickyNav.end"], named: "Sticky end")

        app.buttons["detail.stickyNav.end"].tap()
        let finalScore = element("detail.boxScore.finalScore")
        XCTAssertTrue(finalScore.waitForExistence(timeout: 8))
        XCTAssertFalse(finalScore.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @MainActor
    func testLargeDynamicTypeKeepsCriticalHomeAndDetailContentReachable() throws {
        configureApp(dynamicType: "accessibility5")
        app.launch()
        assertHomeLoaded()

        XCTAssertTrue(element("home.leaguePicker").exists)
        XCTAssertTrue(app.textFields["home.teamFilter"].exists)
        XCTAssertTrue(row("9001").exists)

        try runAccessibilityAudit(types: [.textClipped, .hitRegion])

        openFinalGame()
        XCTAssertTrue(element("detail.header").exists)
        XCTAssertTrue(element("detail.streamControls").waitForExistence(timeout: 5))
        XCTAssertTrue(element("detail.playByPlay").exists)
        scrollUntilVisible(element("detail.playerStats"), direction: .up, maxSwipes: 4)
        XCTAssertTrue(element("detail.playerStats").exists)
        scrollUntilVisible(element("detail.teamStats"), direction: .up, maxSwipes: 6)
        XCTAssertTrue(element("detail.teamStats").exists)

        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(element("detail.boxScore.finalScore").waitForExistence(timeout: 8))
    }

    @MainActor
    func testAccessibleSpokenContentDoesNotLeakRawBackendEnums() {
        configureApp()
        app.launch()
        assertHomeLoaded()
        assertNoRawEnumLeakage()

        openFinalGame()
        assertNoRawEnumLeakage()
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(element("detail.boxScore.finalScore").waitForExistence(timeout: 8))
        assertNoRawEnumLeakage()
    }

    @MainActor
    private func configureApp(dynamicType: String? = nil) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["SDS_UI_TEST_FIXTURE"] = "critical-final-game"
        app.launchEnvironment["SDS_RESET_STATE"] = "1"
        if let dynamicType {
            app.launchEnvironment["SDS_UI_TEST_DYNAMIC_TYPE"] = dynamicType
        }
    }

    @MainActor
    private func runAccessibilityAudit(types: XCUIAccessibilityAuditType = [
        .sufficientElementDescription,
        .hitRegion,
        .contrast,
        .dynamicType,
        .textClipped,
        .trait
    ]) throws {
        try app.performAccessibilityAudit(for: types) { issue in
            issue.auditType == .sufficientElementDescription
                && issue.compactDescription == "Element has no description"
                && issue.element?.elementType == .staticText
        }
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
        XCTAssertTrue(element("detail.header").waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertNonEmptyLabelsForInteractiveElements() {
        let interactiveTypes: [XCUIElement.ElementType] = [.button, .link, .cell]
        for type in interactiveTypes {
            for element in app.descendants(matching: type).allElementsBoundByIndex {
                let label = element.label.trimmingCharacters(in: .whitespacesAndNewlines)
                if label.isEmpty, element.identifier.isEmpty, !element.isHittable {
                    continue
                }
                XCTAssertFalse(
                    label.isEmpty,
                    "Interactive element has an empty label: id=\(element.identifier) hittable=\(element.isHittable) frame=\(element.frame)"
                )
            }
        }
    }

    @MainActor
    private func assertNoRawEnumLeakage() {
        let forbiddenPatterns = [
            #"\b[a-z]+_[a-z0-9_]+\b"#,
            #"\b(homeTeam|awayTeam|gameStatus|periodType|score_state|rawValue)\b"#,
            #"\b(pre_game|in_progress|post_game|recap_ready)\b"#,
            #"\b(UNKNOWN|undefined|null|nil)\b"#
        ]

        let semanticContainers = [
            "home.stickyHeader",
            "home.section.timeline",
            "home.gameRow.9001",
            "detail.header",
            "detail.streamControls",
            "detail.playByPlay",
            "detail.boxScore",
            "detail.boxScore.finalScore",
            "detail.stickyNav"
        ]
        .map(element)
        .filter(\.exists)

        let elements = app.buttons.allElementsBoundByIndex
            + app.links.allElementsBoundByIndex
            + app.cells.allElementsBoundByIndex
            + app.staticTexts.allElementsBoundByIndex
            + app.textFields.allElementsBoundByIndex
            + semanticContainers

        for element in elements {
            let spoken = [
                element.label,
                element.value as? String ?? "",
                element.placeholderValue ?? ""
            ]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !spoken.isEmpty else { continue }

            for pattern in forbiddenPatterns {
                XCTAssertNil(
                    spoken.range(of: pattern, options: [.regularExpression, .caseInsensitive]),
                    "Raw backend token leaked into accessibility text: \(spoken)"
                )
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
    private func row(_ id: String) -> XCUIElement {
        let button = app.buttons["home.gameRow.\(id)"]
        if button.exists {
            return button
        }
        return element("home.gameRow.\(id)")
    }

    @MainActor
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
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
}
