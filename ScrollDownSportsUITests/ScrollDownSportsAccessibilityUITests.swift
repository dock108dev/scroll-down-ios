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
        assertReachableLabelledControl(app.buttons["detail.stickyNav.end"], named: "Sticky end")

        app.buttons["detail.stickyNav.end"].tap()
        let finalScore = finalScore()
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
        XCTAssertTrue(element("detail.streamModePicker").exists)
        XCTAssertTrue(app.buttons["detail.gameActions"].exists)
        assertMinimumTapTarget(app.buttons["detail.gameActions"], named: "Detail actions")
        XCTAssertTrue(element("detail.playByPlay").exists)

        XCTAssertTrue(app.buttons["detail.stickyNav.end"].waitForExistence(timeout: 5))
        assertMinimumTapTarget(app.buttons["detail.stickyNav.end"], named: "Sticky end")
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))
        scrollUntilVisible(element("detail.playerStats"), direction: .up, maxSwipes: 2)
        XCTAssertTrue(element("detail.playerStats").exists)
        scrollUntilVisible(element("detail.teamStats"), direction: .up, maxSwipes: 3)
        XCTAssertTrue(element("detail.teamStats").exists)
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
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))
        assertNoRawEnumLeakage()
    }

    @MainActor
    func testIPadRegularWidthKeepsPrimaryControlsUniqueReachableAndLabelled() throws {
        configureApp()
        app.launch()
        assertHomeLoaded()
        guard isRegularWidth else {
            throw XCTSkip("Regular-width iPad accessibility route")
        }

        assertExactlyOneElement(identifier: "home.stickyHeader")
        assertExactlyOneElement(identifier: "home.leaguePicker")
        assertExactlyOneElement(identifier: "home.teamFilter")
        assertExactlyOneButton(identifier: "home.refresh")
        assertExactlyOneButton(identifier: "home.gameRow.9001")
        assertExactlyOneButton(identifier: "home.gameRow.9001.pin")
        assertReachableLabelledControl(app.buttons["home.refresh"], named: "Home refresh")

        selectLeague("NBA")
        XCTAssertTrue(row("9003").waitForExistence(timeout: 3))
        selectLeague("All")
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))

        let teamFilter = app.textFields["home.teamFilter"]
        XCTAssertTrue(teamFilter.isHittable)
        teamFilter.tap()
        teamFilter.typeText("Canyon")
        XCTAssertTrue(row("9001").waitForExistence(timeout: 3))
        clearTextField(teamFilter)
        dismissKeyboardIfVisible()

        openFinalGame()
        assertHomeAndDetailCoexist(gameId: "9001")
        assertExactlyOneElement(identifier: "detail.header")
        assertExactlyOneElement(identifier: "detail.streamControls")
        assertExactlyOneElement(identifier: "detail.playByPlay")
        assertAtMostOneHittableElement(identifier: "detail.stickyNav")
        assertReachableLabelledControl(app.buttons["detail.refresh"], named: "Detail refresh")
        assertExactlyOneButton(identifier: "detail.stickyNav.end")
        assertMinimumTapTarget(app.buttons["detail.gameActions"], named: "Detail actions")
        assertReachableLabelledControl(app.buttons["detail.stickyNav.end"], named: "Sticky end")
        assertNoDuplicateCriticalButtonLabels()

        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))
        assertAtMostOneHittableElement(identifier: "detail.boxScore.finalScore")
    }

    @MainActor
    func testIPadDynamicTypeKeepsFiltersAndStickyDetailControlsReachable() throws {
        configureApp(dynamicType: "accessibility5")
        app.launch()
        assertHomeLoaded()
        guard isRegularWidth else {
            throw XCTSkip("Regular-width iPad Dynamic Type route")
        }

        XCTAssertTrue(element("home.leaguePicker").exists)
        XCTAssertTrue(app.textFields["home.teamFilter"].exists)
        XCTAssertTrue(app.buttons["home.refresh"].exists)
        try runAccessibilityAudit(types: [.textClipped, .hitRegion])

        openFinalGame()
        if element("home.stickyHeader").exists {
            assertHomeAndDetailCoexist(gameId: "9001")
        } else {
            XCTAssertTrue(element("detail.header").exists)
            XCTAssertTrue(element("detail.streamControls").waitForExistence(timeout: 5))
            XCTAssertTrue(element("detail.playByPlay").waitForExistence(timeout: 5))
        }
        XCTAssertTrue(app.buttons["detail.gameActions"].exists)
        XCTAssertFalse(app.buttons["detail.gameActions"].label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(app.buttons["detail.stickyNav.end"].waitForExistence(timeout: 5))
        assertReachableLabelledControl(app.buttons["detail.stickyNav.end"], named: "Sticky end")
        app.buttons["detail.stickyNav.end"].tap()
        XCTAssertTrue(finalScore().waitForExistence(timeout: 8))
    }

    @MainActor
    private func configureApp(dynamicType: String? = nil) {
        continueAfterFailure = false
        app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
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
        XCTAssertTrue(element("detail.header").waitForExistence(timeout: 5))
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
    private func assertExactlyOneElement(identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = app.descendants(matching: .any).matching(identifier: identifier)
        XCTAssertEqual(matches.count, 1, "Expected exactly one element with id \(identifier)", file: file, line: line)
    }

    @MainActor
    private func assertExactlyOneButton(identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = app.buttons.matching(identifier: identifier)
        XCTAssertEqual(matches.count, 1, "Expected exactly one button with id \(identifier)", file: file, line: line)
    }

    @MainActor
    private func assertAtMostOneHittableElement(identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = app.descendants(matching: .any)
            .matching(identifier: identifier)
            .allElementsBoundByIndex
            .filter { $0.exists && $0.isHittable }

        XCTAssertLessThanOrEqual(
            matches.count,
            1,
            "Expected at most one hittable element with id \(identifier)",
            file: file,
            line: line
        )
    }

    @MainActor
    private func selectLeague(_ league: String, file: StaticString = #filePath, line: UInt = #line) {
        let directButton = app.buttons[league]
        if directButton.exists && directButton.isHittable {
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
    private func assertNoDuplicateCriticalButtonLabels(file: StaticString = #filePath, line: UInt = #line) {
        let identifiers = [
            "home.refresh",
            "detail.gameActions",
            "detail.stickyNav.top",
            "detail.stickyNav.end",
            "detail.stickyNav.return"
        ]
        let buttons = identifiers
            .map { app.buttons[$0] }
            .filter { $0.exists && $0.isHittable }
        let labels = Dictionary(grouping: buttons) { button in
            button.label.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for (label, matches) in labels where !label.isEmpty {
            XCTAssertEqual(
                matches.count,
                1,
                "Duplicate hittable critical button label '\(label)': \(matches.map(\.identifier))",
                file: file,
                line: line
            )
        }
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
            #"\b(pre_game|in_progress|post_game)\b"#,
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
        let minimumTapTarget: CGFloat = 44
        let layoutPrecisionTolerance: CGFloat = 0.5
        XCTAssertTrue(element.waitForExistence(timeout: 3), "\(name) does not exist")
        XCTAssertGreaterThanOrEqual(
            element.frame.width,
            minimumTapTarget - layoutPrecisionTolerance,
            "\(name) width is below 44 points"
        )
        XCTAssertGreaterThanOrEqual(
            element.frame.height,
            minimumTapTarget - layoutPrecisionTolerance,
            "\(name) height is below 44 points"
        )
    }

    @MainActor
    private func assertReachableLabelledControl(_ element: XCUIElement, named name: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 3), "\(name) does not exist")
        XCTAssertTrue(element.isHittable, "\(name) is not hittable")
        XCTAssertFalse(element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(name) has an empty label")
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
            let detailScroll = app.scrollViews["detail.scroll"]
            let scrollTarget: XCUIElement = detailScroll.exists ? detailScroll : app
            switch direction {
            case .up:
                scrollTarget.swipeUp()
            case .down:
                scrollTarget.swipeDown()
            }
        }
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
}

private extension XCUIElement {
    @MainActor
    var valueText: String {
        (value as? String) ?? ""
    }
}
