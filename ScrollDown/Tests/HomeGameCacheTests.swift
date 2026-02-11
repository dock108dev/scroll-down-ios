import XCTest
@testable import ScrollDown

final class HomeGameCacheTests: XCTestCase {

    private var cache: HomeGameCache!

    override func setUp() {
        super.setUp()
        cache = HomeGameCache()
        cache.clearAll()
    }

    override func tearDown() {
        cache.clearAll()
        super.tearDown()
    }

    func testSaveThenLoad() {
        let games = [TestFixtures.makeGameSummary(id: 1), TestFixtures.makeGameSummary(id: 2)]
        cache.save(games: games, lastUpdatedAt: "2025-01-15T22:00:00Z", range: .current, league: nil)

        let loaded = cache.load(range: .current, league: nil)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.games.count, 2)
    }

    func testLoadMissingReturnsNil() {
        let loaded = cache.load(range: .tomorrow, league: nil)
        XCTAssertNil(loaded)
    }

    func testClearAllRemovesData() {
        let games = [TestFixtures.makeGameSummary(id: 1)]
        cache.save(games: games, lastUpdatedAt: nil, range: .current, league: nil)
        cache.clearAll()

        let loaded = cache.load(range: .current, league: nil)
        XCTAssertNil(loaded)
    }

    func testDifferentRangesIsolated() {
        let todayGames = [TestFixtures.makeGameSummary(id: 1)]
        let tomorrowGames = [TestFixtures.makeGameSummary(id: 2)]

        cache.save(games: todayGames, lastUpdatedAt: nil, range: .current, league: nil)
        cache.save(games: tomorrowGames, lastUpdatedAt: nil, range: .tomorrow, league: nil)

        let loadedToday = cache.load(range: .current, league: nil)
        let loadedTomorrow = cache.load(range: .tomorrow, league: nil)

        XCTAssertEqual(loadedToday?.games.first?.id, 1)
        XCTAssertEqual(loadedTomorrow?.games.first?.id, 2)
    }
}
