import XCTest
@testable import ScrollDownSports

@MainActor
final class ReadingHistoryStoreTests: XCTestCase {
    func testLegacyProgressDecodingMigratesResumeIntoReadingHistory() throws {
        let data = Data(
            """
            {
              "gameId": 77,
              "selectedMode": "timeline",
              "firstViewedAt": "2026-05-22T12:00:00Z",
              "lastViewedAt": "2026-05-22T12:05:00Z",
              "lastReadEventID": "provider-play-2",
              "lastReadEventIndex": 2,
              "expandedSectionIDs": [],
              "expandedRawFeedKeys": [],
              "reachedScoreboard": true,
              "followLivePreference": "automatic",
              "lastKnownEventCount": 3,
              "newEventCount": 0,
              "updatedAt": "2026-05-22T12:06:00Z"
            }
            """.utf8
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let progress = try decoder.decode(GameProgressRecord.self, from: data)
        let history = progress.readingHistory

        XCTAssertEqual(history.lastReadCardID, "provider-play-2")
        XCTAssertEqual(history.lastResumedCardID, "provider-play-2")
        XCTAssertTrue(history.cardsByID["provider-play-2"]?.isRead == true)
        XCTAssertTrue(history.isCompleted)
        XCTAssertTrue(history.isRevealed)
    }

    func testNormalizedCardHistorySurvivesRegeneratedCopy() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })
        let firstPass = [
            makeEvent(sequence: 1, sourceEventID: "source-1", cardID: "card-source-1", headline: "Original copy"),
            makeEvent(sequence: 2, sourceEventID: "source-2", cardID: "card-source-2", headline: "Second card")
        ]
        store.recordEventRefresh(gameId: 801, events: firstPass, diff: .unchanged)
        store.recordReadEvent(gameId: 801, eventID: firstPass[0].readingHistoryCardID, eventIndex: 0, knownEventCount: firstPass.count)

        let regenerated = [
            makeEvent(sequence: 1, sourceEventID: "source-1", cardID: "card-source-1", headline: "Regenerated copy"),
            makeEvent(sequence: 2, sourceEventID: "source-2", cardID: "card-source-2", headline: "Second card")
        ]
        let diff = GameEventListDiffer.diff(previous: firstPass, current: regenerated)
        store.recordEventRefresh(gameId: 801, events: regenerated, diff: diff)

        let history = try XCTUnwrap(store.progress(for: 801)?.readingHistory)
        XCTAssertEqual(history.cardsByID.count, 2)
        XCTAssertTrue(history.cardsByID["card-source-1"]?.isRead == true)
        XCTAssertFalse(history.cardsByID["card-source-2"]?.isRead == true)
        XCTAssertEqual(history.lastReadCardID, "card-source-1")
    }

    func testHistoryTracksCompletionResumeAndRevealWithoutText() throws {
        let resumedAt = TestFixtures.fixedDate("2026-05-22T12:10:00Z")
        var currentDate = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let store = InMemoryGameStateStore(now: { currentDate })
        let events = [
            makeEvent(sequence: 1, sourceEventID: "source-1", cardID: "card-source-1", headline: "Start"),
            makeEvent(sequence: 2, sourceEventID: "source-2", cardID: "card-source-2", headline: "Middle")
        ]

        store.recordEventRefresh(gameId: 802, events: events, diff: .unchanged)
        store.recordReadEvent(gameId: 802, eventID: events[1].readingHistoryCardID, eventIndex: 1, knownEventCount: events.count)
        currentDate = resumedAt
        store.markViewed(gameId: 802)
        store.setReachedScoreboard(gameId: 802, reached: true)

        let history = try XCTUnwrap(store.progress(for: 802)?.readingHistory)
        XCTAssertEqual(history.readCardCount, 2)
        XCTAssertEqual(history.unreadCardCount, 0)
        XCTAssertEqual(history.lastResumedCardID, "card-source-2")
        XCTAssertTrue(history.isCompleted)
        XCTAssertTrue(history.isRevealed)
        XCTAssertTrue(history.cardsByID.values.allSatisfy { $0.cardID.hasPrefix("card-source-") })
    }

    private func makeEvent(sequence: Int, sourceEventID: String, cardID: String, headline: String) -> GameEvent {
        TestFixtures.makeEvent(
            sequence: sequence,
            sourceEventID: sourceEventID,
            headline: headline,
            normalizedCard: NormalizedPlayCard(
                schemaVersion: 1,
                cardID: cardID,
                visualImportance: .medium,
                accent: nil,
                clock: nil,
                headline: NormalizedPlayCardText(text: headline, tone: nil, maxLines: nil),
                body: nil,
                contextItems: [],
                resultItems: [],
                score: nil,
                team: nil,
                situation: nil,
                rawFeed: nil,
                accessibility: NormalizedPlayCardAccessibility(label: headline, value: nil, hint: nil, situationSummary: nil)
            )
        )
    }
}
