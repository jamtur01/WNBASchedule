import XCTest
@testable import WNBASchedule

final class LiveScoreManagerTests: XCTestCase {
    // MARK: - Properties
    
    private var liveScoreManager: LiveScoreManager?
    private var mockClient: MockNBAClientWithBoxscore?
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        let manager = LiveScoreManager()
        let client = MockNBAClientWithBoxscore()
        
        liveScoreManager = manager
        mockClient = client
        
        // Configure dependency container with mock client
        DependencyContainer.shared.configureMockServices(nbaClient: client)
    }
    
    override func tearDown() {
        liveScoreManager = nil
        mockClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testFetchLiveScoresWithNoInProgressGames() async {
        // Setup test data with no in-progress games
        let games = [
            createTestGame(state: 1), // Upcoming
            createTestGame(state: 3)  // Completed
        ]
        
        // Execute
        let updatedGames = await liveScoreManager?.fetchLiveScores(for: games) ?? []
        
        // Verify no API calls were made and games unchanged
        XCTAssertEqual(updatedGames.count, 2)
        XCTAssertNil(mockClient?.lastFetchedGameId)
        XCTAssertEqual(updatedGames[0].liveHomeScore, nil)
        XCTAssertEqual(updatedGames[0].liveVisitorScore, nil)
    }
    
    func testFetchLiveScoresWithInProgressGames() async {
        // Setup test data with in-progress games
        let games = [
            createTestGame(gid: "game1", state: 2), // In progress
            createTestGame(gid: "game2", state: 2), // Halftime
            createTestGame(gid: "game3", state: 1)  // Upcoming
        ]
        
        // Setup mock responses
        mockClient?.mockBoxscoreResponses = [
            "game1": createMockBoxscoreResponse(gameId: "game1", homeScore: 45, awayScore: 42, status: "Q2"),
            "game2": createMockBoxscoreResponse(gameId: "game2", homeScore: 55, awayScore: 48, status: "Halftime")
        ]
        
        // Execute
        let updatedGames = await liveScoreManager?.fetchLiveScores(for: games) ?? []
        
        // Verify live scores were updated
        XCTAssertEqual(updatedGames.count, 3)
        XCTAssertEqual(updatedGames[0].liveHomeScore, 45)
        XCTAssertEqual(updatedGames[0].liveVisitorScore, 42)
        XCTAssertEqual(updatedGames[1].liveHomeScore, 55)
        XCTAssertEqual(updatedGames[1].liveVisitorScore, 48)
        XCTAssertNil(updatedGames[2].liveHomeScore) // Upcoming game unchanged
    }
    
    func testFetchLiveScoresAndCheckCompletionWithFinishedGame() async {
        // Setup test data with in-progress game that finishes
        let games = [
            createTestGame(gid: "game1", state: 2), // In progress
            createTestGame(gid: "game2", state: 2)  // Halftime
        ]
        
        // Setup mock responses - one game finishes
        mockClient?.mockBoxscoreResponses = [
            "game1": createMockBoxscoreResponse(gameId: "game1", homeScore: 85, awayScore: 80, status: "Final"),
            "game2": createMockBoxscoreResponse(gameId: "game2", homeScore: 55, awayScore: 48, status: "Q3")
        ]
        
        // Execute
        var gameFinished = false
        let updatedGames = await liveScoreManager?.fetchLiveScoresAndCheckCompletion(
            for: games,
            gameFinished: &gameFinished
        ) ?? []
        
        // Verify game completion was detected
        XCTAssertTrue(gameFinished)
        XCTAssertEqual(updatedGames[0].liveHomeScore, 85)
        XCTAssertEqual(updatedGames[0].liveVisitorScore, 80)
        XCTAssertEqual(updatedGames[1].liveHomeScore, 55)
        XCTAssertEqual(updatedGames[1].liveVisitorScore, 48)
    }
    
    func testUpdateLiveScoresForTeam() async {
        // Setup current games with in-progress games
        let inProgressGames = [
            MarkedGame(game: createTestGame(gid: "game1", state: 2), isHomeGame: true)
        ]
        let currentGames = FilteredGames(
            pastGames: [],
            inProgressGames: inProgressGames,
            upcomingGames: []
        )
        
        // Setup mock response
        mockClient?.mockBoxscoreResponses = [
            "game1": createMockBoxscoreResponse(gameId: "game1", homeScore: 45, awayScore: 42, status: "Q2")
        ]
        
        // Execute
        let expectation = XCTestExpectation(description: "Live scores updated")
        await liveScoreManager?.updateLiveScoresForTeam(currentGames: currentGames) { result in
            switch result {
            case .success(let data):
                XCTAssertFalse(data.gameFinished)
                XCTAssertEqual(data.updatedGames.inProgressGames.count, 1)
                XCTAssertEqual(data.updatedGames.inProgressGames[0].game.liveHomeScore, 45)
                XCTAssertEqual(data.updatedGames.inProgressGames[0].game.liveVisitorScore, 42)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testUpdateLiveScoresForAllTeams() async {
        // Setup mock user preferences
        let mockUserPreferences = UserPreferences()
        mockUserPreferences.allTeamsDaysToShow = 3
        
        // Setup mock schedule response
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            XCTFail("Failed to create tomorrow date")
            return
        }
        
        let games = [
            createTestGame(gid: "game1", state: 2, timestamp: Int64(today.timeIntervalSince1970 * 1000)),
            createTestGame(gid: "game2", state: 1, timestamp: Int64(tomorrow.timeIntervalSince1970 * 1000))
        ]
        
        mockClient?.mockScheduleResponse = ScheduleResponse(results: Results(schedule: games))
        mockClient?.mockBoxscoreResponses = [
            "game1": createMockBoxscoreResponse(gameId: "game1", homeScore: 45, awayScore: 42, status: "Q2")
        ]
        
        // Execute
        let expectation = XCTestExpectation(description: "All teams live scores updated")
        await liveScoreManager?.updateLiveScoresForAllTeams(userPreferences: mockUserPreferences) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data.inProgressGames.count, 1)
                XCTAssertEqual(data.upcomingGames.count, 1)
                XCTAssertFalse(data.gameFinished)
                XCTAssertEqual(data.inProgressGames[0].liveHomeScore, 45)
                XCTAssertEqual(data.inProgressGames[0].liveVisitorScore, 42)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testLiveScoreErrorHandling() async {
        // Setup test data
        let games = [createTestGame(gid: "game1", state: 2)]
        
        // Setup mock to return error
        mockClient?.shouldReturnError = true
        mockClient?.error = NBAClientError.invalidResponse(404)
        
        // Execute
        let updatedGames = await liveScoreManager?.fetchLiveScores(for: games) ?? []
        
        // Verify error was handled gracefully
        XCTAssertEqual(updatedGames.count, 1)
        XCTAssertNil(updatedGames[0].liveHomeScore)
        XCTAssertNil(updatedGames[0].liveVisitorScore)
    }
    
    // MARK: - Helper Methods
    
    private func createTestGame(
        gid: String = "testGame",
        state: Int = 1,
        timestamp: Int64? = nil
    ) -> Game {
        let gameTimestamp = timestamp ?? Int64(Date().timeIntervalSince1970 * 1000)
        
        return Game(
            gid: gid,
            easternTime: "2025-05-01T19:00:00Z",
            utcTime: "2025-05-01T23:00:00Z",
            timestamp: gameTimestamp,
            home: Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: nil, losses: 2, wins: 10),
            visitor: Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: nil, losses: 3, wins: 9),
            state: state,
            id: 1,
            type: "game",
            title: "Test Game",
            homeTime: "2025-05-01T19:00:00Z",
            visitorTime: "2025-05-01T22:00:00Z",
            providers: nil,
            arenaName: "Test Arena",
            arenaState: "NY",
            arenaCity: "New York",
            gameStatusText: nil,
            gameLabel: nil,
            gameSubLabel: nil,
            seriesText: nil,
            seriesGameNumber: nil,
            ifNecessary: nil,
            gameSubtype: nil,
            name: nil,
            themeNightLabel: nil,
            ticketUrl: nil,
            isLeaguePassGame: nil,
            leaguePassVideoLink: nil
        )
    }
    
    private func createMockBoxscoreResponse(
        gameId: String,
        homeScore: Int,
        awayScore: Int,
        status: String
    ) -> BoxscoreResponse {
        let meta = BoxscoreMeta(version: 1, code: 200, request: "/boxscore", time: "2025-01-01T00:00:00Z")
        let game = BoxscoreGame(
            gameId: gameId,
            gameTimeLocal: "2025-05-01T19:00:00",
            gameTimeUTC: "2025-05-01T23:00:00Z",
            gameTimeHome: "2025-05-01T19:00:00",
            gameTimeAway: "2025-05-01T22:00:00",
            gameEt: "2025-05-01T19:00:00",
            duration: nil,
            gameCode: "TEST",
            gameStatusText: status,
            gameStatus: status == "Final" ? 3 : 1,
            regulationPeriods: 4,
            period: 2,
            gameClock: "10:30",
            attendance: nil,
            sellout: nil,
            arena: nil,
            homeTeam: BoxscoreTeam(
                teamId: 1,
                teamName: "Liberty",
                teamCity: "New York",
                teamTricode: "NYL",
                score: homeScore,
                inBonus: nil,
                timeoutsRemaining: nil,
                periods: nil
            ),
            awayTeam: BoxscoreTeam(
                teamId: 2,
                teamName: "Aces", 
                teamCity: "Las Vegas",
                teamTricode: "LVA",
                score: awayScore,
                inBonus: nil,
                timeoutsRemaining: nil,
                periods: nil
            )
        )
        
        return BoxscoreResponse(meta: meta, game: game)
    }
}

// MARK: - Mock Classes

class MockNBAClientWithBoxscore: NBAClientProtocol {
    var mockScheduleResponse: ScheduleResponse?
    var mockBoxscoreResponses: [String: BoxscoreResponse] = [:]
    var lastFetchedSeason: String?
    var lastFetchedGameId: String?
    var error: Error?
    var shouldReturnError = false
    
    func fetchSchedule(season: String?) async throws -> ScheduleResponse {
        lastFetchedSeason = season ?? String(Calendar.current.component(.year, from: Date()))
        
        if shouldReturnError, let error = error {
            throw error
        }
        
        guard let response = mockScheduleResponse else {
            throw NBAClientError.invalidResponse(404)
        }
        
        return response
    }
    
    func fetchBoxscore(gameId: String) async throws -> BoxscoreResponse {
        lastFetchedGameId = gameId
        
        if shouldReturnError, let error = error {
            throw error
        }
        
        guard let response = mockBoxscoreResponses[gameId] else {
            throw NBAClientError.invalidResponse(404)
        }
        
        return response
    }
}
