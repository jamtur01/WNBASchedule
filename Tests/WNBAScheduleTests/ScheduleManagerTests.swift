import XCTest
@testable import WNBASchedule

final class ScheduleManagerTests: XCTestCase {
    // MARK: - Properties
    
    private var mockClient: MockNBAClient?
    private var mockUserPreferences: MockUserPreferences?
    private var scheduleManager: ScheduleManager?
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockClient = MockNBAClient()
        mockUserPreferences = MockUserPreferences()
        if let mockClient = mockClient, let mockUserPreferences = mockUserPreferences {
            scheduleManager = ScheduleManager(client: mockClient, userPreferences: mockUserPreferences)
        }
    }
    
    override func tearDown() {
        mockClient = nil
        mockUserPreferences = nil
        scheduleManager = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testFetchGamesForTeam() async throws {
        // Setup test data
        let teamAbbr = "NYL"
        let mockResponse = createMockScheduleResponse()
        mockClient?.mockScheduleResponse = mockResponse
        
        // Execute
        guard let scheduleManager = scheduleManager else {
            XCTFail("scheduleManager not initialized")
            return
        }
        let games = try await scheduleManager.fetchGames(forTeam: teamAbbr)
        
        // Verify
        XCTAssertEqual(mockClient?.lastFetchedSeason, String(Calendar.current.component(.year, from: Date())))
        XCTAssertEqual(games.pastGames.count, 1)
        XCTAssertEqual(games.upcomingGames.count, 1)
        
        // Verify past games
        XCTAssertEqual(games.pastGames.first?.game.gid, "1022500001")
        XCTAssertEqual(games.pastGames.first?.isHomeGame, true)
        
        // Verify upcoming games
        XCTAssertEqual(games.upcomingGames.first?.game.gid, "1022500002")
        XCTAssertEqual(games.upcomingGames.first?.isHomeGame, false)
    }
    
    func testFetchGamesWithSpecificSeason() async throws {
        // Setup test data
        let teamAbbr = "NYL"
        let season = "2024"
        let mockResponse = createMockScheduleResponse()
        mockClient?.mockScheduleResponse = mockResponse
        
        // Execute
        guard let scheduleManager = scheduleManager else {
            XCTFail("scheduleManager not initialized")
            return
        }
        let games = try await scheduleManager.fetchGames(forTeam: teamAbbr, season: season)
        
        // Verify
        XCTAssertEqual(mockClient?.lastFetchedSeason, season)
        XCTAssertEqual(games.pastGames.count, 1)
        XCTAssertEqual(games.upcomingGames.count, 1)
    }
    
    func testFilterGamesRespectsPastGamesLimit() async throws {
        // Setup test data with multiple past games
        let teamAbbr = "NYL"
        mockUserPreferences?.pastGamesToShow = 2
        
        let mockResponse = createMockScheduleResponseWithMultiplePastGames(count: 5)
        mockClient?.mockScheduleResponse = mockResponse
        
        // Execute
        guard let scheduleManager = scheduleManager else {
            XCTFail("scheduleManager not initialized")
            return
        }
        let games = try await scheduleManager.fetchGames(forTeam: teamAbbr)
        
        // Verify
        XCTAssertEqual(games.pastGames.count, 2) // Should respect the limit from preferences
    }
    
    func testFilterGamesRespectsUpcomingGamesLimit() async throws {
        // Setup test data with multiple upcoming games
        let teamAbbr = "NYL"
        mockUserPreferences?.upcomingGamesToShow = 3
        
        let mockResponse = createMockScheduleResponseWithMultipleUpcomingGames(count: 5)
        mockClient?.mockScheduleResponse = mockResponse
        
        // Execute
        guard let scheduleManager = scheduleManager else {
            XCTFail("scheduleManager not initialized")
            return
        }
        let games = try await scheduleManager.fetchGames(forTeam: teamAbbr)
        
        // Verify
        XCTAssertEqual(games.upcomingGames.count, 3) // Should respect the limit from preferences
    }
    
    func testMarkedGameProperties() async throws {
        // Setup test data
        let teamAbbr = "NYL"
        let mockResponse = createMockScheduleResponse()
        mockClient?.mockScheduleResponse = mockResponse
        
        // Execute
        guard let scheduleManager = scheduleManager else {
            XCTFail("scheduleManager not initialized")
            return
        }
        let games = try await scheduleManager.fetchGames(forTeam: teamAbbr)

        // Verify MarkedGame properties for home game
        guard let homeGame = games.pastGames.first else {
            XCTFail("No past games found")
            return
        }
        XCTAssertTrue(homeGame.isHomeGame)
        XCTAssertTrue(homeGame.isHomeGame) // Use isHomeGame instead of teamIsHome
        XCTAssertFalse(!homeGame.isHomeGame) // Use !isHomeGame instead of teamIsAway
        XCTAssertEqual(homeGame.opponentTeam.abbr, "LVA")
        XCTAssertEqual(homeGame.teamScore, 85)
        XCTAssertEqual(homeGame.opponentScore, 80)
        XCTAssertTrue(homeGame.teamWon)

        // Verify MarkedGame properties for away game
        guard let awayGame = games.upcomingGames.first else {
            XCTFail("No upcoming games found")
            return
        }
        XCTAssertFalse(awayGame.isHomeGame)
        XCTAssertFalse(awayGame.isHomeGame) // Use isHomeGame instead of teamIsHome
        XCTAssertTrue(!awayGame.isHomeGame) // Use !isHomeGame instead of teamIsAway
        XCTAssertEqual(awayGame.opponentTeam.abbr, "CON")
    }
    
    // MARK: - Helper Methods
    
    private func createMockScheduleResponse() -> ScheduleResponse {
        // Create a past game (home)
        let pastGame = createGame(
            id: 1,
            gid: "1022500001",
            timestamp: Date().addingTimeInterval(-86400).timeIntervalSince1970 * 1000, // Yesterday
            teams: (
                home: createTeam(abbr: "NYL", score: 85),
                visitor: createTeam(abbr: "LVA", score: 80)
            ),
            state: 3 // Completed
        )
        
        // Create an upcoming game (away)
        let upcomingGame = createGame(
            id: 2,
            gid: "1022500002",
            timestamp: Date().addingTimeInterval(86400).timeIntervalSince1970 * 1000, // Tomorrow
            teams: (
                home: createTeam(abbr: "CON", score: nil),
                visitor: createTeam(abbr: "NYL", score: nil)
            ),
            state: 1 // Upcoming
        )
        
        return ScheduleResponse(results: Results(schedule: [pastGame, upcomingGame]))
    }
    
    private func createMockScheduleResponseWithMultiplePastGames(count: Int) -> ScheduleResponse {
        var games: [Game] = []
        
        // Create past games
        for i in 0..<count {
            let game = createGame(
                id: i,
                gid: "1022500\(i)",
                timestamp: Date().addingTimeInterval(Double(-86400 * (i + 1))).timeIntervalSince1970 * 1000,
                teams: (
                    home: createTeam(abbr: "NYL", score: 85 + i),
                    visitor: createTeam(abbr: "LVA", score: 80)
                ),
                state: 3 // Completed
            )
            games.append(game)
        }
        
        return ScheduleResponse(results: Results(schedule: games))
    }
    
    private func createMockScheduleResponseWithMultipleUpcomingGames(count: Int) -> ScheduleResponse {
        var games: [Game] = []
        
        // Create upcoming games
        for i in 0..<count {
            let game = createGame(
                id: i,
                gid: "1022500\(i)",
                timestamp: Date().addingTimeInterval(Double(86400 * (i + 1))).timeIntervalSince1970 * 1000,
                teams: (
                    home: createTeam(abbr: "CON", score: nil),
                    visitor: createTeam(abbr: "NYL", score: nil)
                ),
                state: 1 // Upcoming
            )
            games.append(game)
        }
        
        return ScheduleResponse(results: Results(schedule: games))
    }
    
    private func createGame(
        id: Int,
        gid: String,
        timestamp: TimeInterval,
        teams: (home: Team, visitor: Team),
        state: Int
    ) -> Game {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let utcTime = formatter.string(from: date)

        return Game(
            gid: gid,
            easternTime: utcTime,
            utcTime: utcTime,
            timestamp: Int64(timestamp),
            home: teams.home,
            visitor: teams.visitor,
            state: state,
            id: id,
            type: "game",
            title: "Test Game",
            homeTime: utcTime,
            visitorTime: utcTime,
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
    
    private func createTeam(abbr: String, score: Int? = nil) -> Team {
        return Team(
            tid: 1,
            abbr: abbr,
            city: abbr == "NYL" ? "New York" : (abbr == "LVA" ? "Las Vegas" : "Connecticut"),
            name: abbr == "NYL" ? "Liberty" : (abbr == "LVA" ? "Aces" : "Sun"),
            score: score,
            losses: 2,
            wins: 10
        )
    }
}

// MARK: - Mock Classes

class MockNBAClient: NBAClientProtocol {
    var mockScheduleResponse: ScheduleResponse?
    var mockBoxscoreResponse: BoxscoreResponse?
    var lastFetchedSeason: String?
    var lastFetchedGameId: String?
    var error: Error?
    
    func fetchSchedule(season: String?) async throws -> ScheduleResponse {
        // If season is nil, use current year (matching NBAClient behavior)
        lastFetchedSeason = season ?? String(Calendar.current.component(.year, from: Date()))
        
        if let error = error {
            throw error
        }
        
        guard let response = mockScheduleResponse else {
            throw NBAClientError.invalidResponse(404)
        }
        
        return response
    }
    
    func fetchBoxscore(gameId: String) async throws -> BoxscoreResponse {
        lastFetchedGameId = gameId
        
        if let error = error {
            throw error
        }
        
        guard let response = mockBoxscoreResponse else {
            // For now, just throw an error since ScheduleManager tests don't use boxscore
            throw NBAClientError.invalidResponse(404)
        }
        
        return response
    }
}

class MockUserPreferences: UserPreferences {
    override init() {
        super.init()
        // Override defaults for testing
        pastGamesToShow = 10
        upcomingGamesToShow = 5
    }
}

// End of ScheduleManagerTests
