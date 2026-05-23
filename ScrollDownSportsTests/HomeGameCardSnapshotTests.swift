import SwiftUI
import XCTest
@testable import ScrollDownSports

@MainActor
final class HomeGameCardSnapshotTests: SnapshotTestCase {
    func testScheduledCard() {
        assertCardSnapshot(item: ComponentSnapshotFixtures.scheduledHomeItem(), named: "scheduled")
    }

    func testLiveCard() {
        assertCardSnapshot(item: ComponentSnapshotFixtures.liveHomeItem(), named: "live")
    }

    func testFinalUnreadCard() {
        assertCardSnapshot(item: ComponentSnapshotFixtures.finalUnreadHomeItem(), named: "final-unread")
    }

    func testFinalReadCardShowsScore() {
        assertCardSnapshot(item: ComponentSnapshotFixtures.finalReadHomeItem(), named: "final-read-score-visible")
    }

    func testResumeCard() {
        assertCardSnapshot(item: ComponentSnapshotFixtures.resumeHomeItem(), named: "resume")
    }

    func testLongTeamNamesCompactWidth() {
        assertCardSnapshot(
            item: ComponentSnapshotFixtures.longNameHomeItem(),
            named: "long-team-names",
            width: .compact,
            height: 170
        )
    }

    func testMissingAbbreviationFallsBack() {
        assertCardSnapshot(item: ComponentSnapshotFixtures.missingAbbreviationHomeItem(), named: "missing-abbreviation")
    }

    func testPinnedAndUnpinnedChrome() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                cardChrome(item: ComponentSnapshotFixtures.liveHomeItem(isPinned: false))
                cardChrome(item: ComponentSnapshotFixtures.liveHomeItem(isPinned: true))
            },
            named: "pin-chrome",
            width: .standard,
            height: 320
        )
    }

    private func assertCardSnapshot(
        item: HomeGameItem,
        named name: String,
        width: SnapshotWidth = .standard,
        height: CGFloat = 150,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSwiftUISnapshot(
            of: GameRowView(item: item)
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: name,
            width: width,
            height: height,
            testName: testName,
            line: line
        )
    }

    private func cardChrome(item: HomeGameItem) -> some View {
        ZStack(alignment: .topTrailing) {
            GameRowView(item: item)
            HomePinButton(isPinned: item.isPinned) {}
                .padding(.top, 12)
                .padding(.trailing, 12)
        }
        .padding(12)
        .background(SportsTheme.Colors.paper)
    }
}
