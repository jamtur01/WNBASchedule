import XCTest
@testable import WNBASchedule

final class BoxscoreTests: XCTestCase {
    
    // MARK: - BoxscoreResponse Tests
    
    func testBoxscoreResponseDecoding() throws {
        let response = try createCompleteBoxscoreResponse()
        
        // Test meta properties
        XCTAssertEqual(response.meta.version, 1)
        XCTAssertEqual(response.meta.code, 200)
        XCTAssertEqual(response.meta.request, "boxscore/1022500066")
        XCTAssertEqual(response.meta.time, "2025-05-01T23:30:00.000Z")
    }
    
    func testBoxscoreGameProperties() throws {
        let response = try createCompleteBoxscoreResponse()
        
        // Test game properties
        XCTAssertEqual(response.game.gameId, "1022500066")
        XCTAssertEqual(response.game.gameStatusText, "Final")
        XCTAssertEqual(response.game.gameStatus, 3)
        XCTAssertEqual(response.game.period, 4)
        XCTAssertEqual(response.game.gameClock, "00:00")
        XCTAssertEqual(response.game.attendance, 17732)
        XCTAssertEqual(response.game.sellout, "1")
    }
    
    func testBoxscoreArenaProperties() throws {
        let response = try createCompleteBoxscoreResponse()
        
        // Test arena properties
        XCTAssertNotNil(response.game.arena)
        XCTAssertEqual(response.game.arena?.arenaName, "Barclays Center")
        XCTAssertEqual(response.game.arena?.arenaCity, "Brooklyn")
        XCTAssertEqual(response.game.arena?.arenaState, "NY")
    }
    
    func testBoxscoreTeamProperties() throws {
        let response = try createCompleteBoxscoreResponse()
        
        // Test home team properties
        XCTAssertEqual(response.game.homeTeam.teamName, "Liberty")
        XCTAssertEqual(response.game.homeTeam.teamCity, "New York")
        XCTAssertEqual(response.game.homeTeam.teamTricode, "NYL")
        XCTAssertEqual(response.game.homeTeam.score, 85)
        XCTAssertEqual(response.game.homeTeam.timeoutsRemaining, 2)
        XCTAssertEqual(response.game.homeTeam.periods?.count, 4)
        
        // Test away team properties
        XCTAssertEqual(response.game.awayTeam.teamName, "Aces")
        XCTAssertEqual(response.game.awayTeam.teamCity, "Las Vegas")
        XCTAssertEqual(response.game.awayTeam.teamTricode, "LVA")
        XCTAssertEqual(response.game.awayTeam.score, 80)
        XCTAssertEqual(response.game.awayTeam.timeoutsRemaining, 1)
        XCTAssertEqual(response.game.awayTeam.periods?.count, 4)
    }
    
    func testBoxscorePeriodScoring() throws {
        let response = try createCompleteBoxscoreResponse()
        
        // Test period scoring
        if let homePeriods = response.game.homeTeam.periods {
            XCTAssertEqual(homePeriods[0].score, 22)
            XCTAssertEqual(homePeriods[1].score, 19)
            XCTAssertEqual(homePeriods[2].score, 24)
            XCTAssertEqual(homePeriods[3].score, 20)
        }
        
        if let awayPeriods = response.game.awayTeam.periods {
            XCTAssertEqual(awayPeriods[0].score, 18)
            XCTAssertEqual(awayPeriods[1].score, 21)
            XCTAssertEqual(awayPeriods[2].score, 20)
            XCTAssertEqual(awayPeriods[3].score, 21)
        }
    }
    
    func testBoxscoreResponseMinimalDecoding() throws {
        let jsonString = """
        {
            "meta": {
                "version": 1,
                "code": 200,
                "request": "boxscore/1022500066",
                "time": "2025-05-01T23:30:00.000Z"
            },
            "game": {
                "gameId": "1022500066",
                "gameTimeLocal": "2025-05-01T19:00:00",
                "gameTimeUTC": "2025-05-01T23:00:00.000Z",
                "gameTimeHome": "2025-05-01T19:00:00",
                "gameTimeAway": "2025-05-01T22:00:00",
                "gameEt": "2025-05-01T19:00:00",
                "gameCode": "20250501/NYLLIB",
                "gameStatusText": "Q2",
                "gameStatus": 1,
                "regulationPeriods": 4,
                "period": 2,
                "gameClock": "05:30",
                "homeTeam": {
                    "teamId": 1611661313,
                    "teamName": "Liberty",
                    "teamCity": "New York",
                    "teamTricode": "NYL",
                    "score": 45
                },
                "awayTeam": {
                    "teamId": 1611661314,
                    "teamName": "Aces",
                    "teamCity": "Las Vegas",
                    "teamTricode": "LVA",
                    "score": 42
                }
            }
        }
        """
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw TestError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(BoxscoreResponse.self, from: jsonData)
        
        // Test minimal required properties
        XCTAssertEqual(response.game.gameStatusText, "Q2")
        XCTAssertEqual(response.game.gameStatus, 1)
        XCTAssertEqual(response.game.period, 2)
        XCTAssertEqual(response.game.gameClock, "05:30")
        XCTAssertEqual(response.game.homeTeam.score, 45)
        XCTAssertEqual(response.game.awayTeam.score, 42)
        
        // Test optional properties are nil
        XCTAssertNil(response.game.duration)
        XCTAssertNil(response.game.attendance)
        XCTAssertNil(response.game.sellout)
        XCTAssertNil(response.game.arena)
        XCTAssertNil(response.game.homeTeam.inBonus)
        XCTAssertNil(response.game.homeTeam.timeoutsRemaining)
        XCTAssertNil(response.game.homeTeam.periods)
    }
    
    // MARK: - Live Score Integration Tests
    
    func testGameCurrentScoreWithLiveData() {
        // Create an in-progress game (state 2)
        var game = createTestGame(state: 2, homeScore: 70, awayScore: 65)
        
        // Before live data
        XCTAssertEqual(game.currentHomeScore, 70)
        XCTAssertEqual(game.currentVisitorScore, 65)
        
        // Add live score data
        game.liveHomeScore = 75
        game.liveVisitorScore = 68
        
        // After live data - should use live scores
        XCTAssertEqual(game.currentHomeScore, 75)
        XCTAssertEqual(game.currentVisitorScore, 68)
    }
    
    func testGameCurrentScoreWithoutLiveData() {
        // Create a completed game
        let game = createTestGame(state: 3, homeScore: 85, awayScore: 80)
        
        // Should use original scores for completed games
        XCTAssertEqual(game.currentHomeScore, 85)
        XCTAssertEqual(game.currentVisitorScore, 80)
    }
    
    func testGameCurrentScoreForUpcomingGame() {
        // Create an upcoming game
        let game = createTestGame(state: 1, homeScore: nil, awayScore: nil)
        
        // Should return nil for upcoming games
        XCTAssertNil(game.currentHomeScore)
        XCTAssertNil(game.currentVisitorScore)
    }
    
    // MARK: - Game Status Tests (Updated)
    
    func testUpdatedGameStatusProperties() {
        // Test upcoming game (state 1)
        let upcomingGame = createTestGame(state: 1)
        XCTAssertTrue(upcomingGame.isUpcoming)
        XCTAssertFalse(upcomingGame.isInProgress)
        XCTAssertFalse(upcomingGame.isCompleted)
        XCTAssertEqual(upcomingGame.statusDescription, "Upcoming")
        
        // Test in-progress game (state 2)
        let inProgressGame = createTestGame(state: 2)
        XCTAssertFalse(inProgressGame.isUpcoming)
        XCTAssertTrue(inProgressGame.isInProgress)
        XCTAssertFalse(inProgressGame.isCompleted)
        XCTAssertEqual(inProgressGame.statusDescription, "In Progress")
        
        // Test completed game (state 3)
        let completedGame = createTestGame(state: 3)
        XCTAssertFalse(completedGame.isUpcoming)
        XCTAssertFalse(completedGame.isInProgress)
        XCTAssertTrue(completedGame.isCompleted)
        XCTAssertEqual(completedGame.statusDescription, "Final")
        
        // Test unknown state
        let unknownStateGame = createTestGame(state: 99)
        XCTAssertFalse(unknownStateGame.isUpcoming)
        XCTAssertFalse(unknownStateGame.isInProgress)
        XCTAssertFalse(unknownStateGame.isCompleted)
        XCTAssertEqual(unknownStateGame.statusDescription, "Unknown")
    }
    
}

// MARK: - BoxscoreTests Helper Extensions

extension BoxscoreTests {
    enum TestError: Error {
        case invalidJSON
    }
    
    func createCompleteBoxscoreResponse() throws -> BoxscoreResponse {
        let jsonString = createCompleteBoxscoreJSON()
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw TestError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(BoxscoreResponse.self, from: jsonData)
    }
    
    func createCompleteBoxscoreJSON() -> String {
        let meta = createMetaJSON()
        let game = createGameJSON()
        return "{\(meta),\(game)}"
    }
    
    func createMetaJSON() -> String {
        return """
        "meta": {
            "version": 1,
            "code": 200,
            "request": "boxscore/1022500066",
            "time": "2025-05-01T23:30:00.000Z"
        }
        """
    }
    
    func createGameJSON() -> String {
        let gameData = createGameDataJSON()
        let arena = createArenaJSON()
        let homeTeam = createHomeTeamJSON()
        let awayTeam = createAwayTeamJSON()
        
        return """
        "game": {
            \(gameData),
            \(arena),
            \(homeTeam),
            \(awayTeam)
        }
        """
    }
    
    func createGameDataJSON() -> String {
        return """
        "gameId": "1022500066",
        "gameTimeLocal": "2025-05-01T19:00:00",
        "gameTimeUTC": "2025-05-01T23:00:00.000Z",
        "gameTimeHome": "2025-05-01T19:00:00",
        "gameTimeAway": "2025-05-01T22:00:00",
        "gameEt": "2025-05-01T19:00:00",
        "duration": 125,
        "gameCode": "20250501/NYLLIB",
        "gameStatusText": "Final",
        "gameStatus": 3,
        "regulationPeriods": 4,
        "period": 4,
        "gameClock": "00:00",
        "attendance": 17732,
        "sellout": "1"
        """
    }
    
    func createArenaJSON() -> String {
        return """
        "arena": {
            "arenaId": 1,
            "arenaName": "Barclays Center",
            "arenaCity": "Brooklyn",
            "arenaState": "NY",
            "arenaCountry": "US",
            "arenaTimezone": "America/New_York"
        }
        """
    }
    
    func createHomeTeamJSON() -> String {
        return """
        "homeTeam": {
            "teamId": 1611661313,
            "teamName": "Liberty",
            "teamCity": "New York",
            "teamTricode": "NYL",
            "score": 85,
            "inBonus": "0",
            "timeoutsRemaining": 2,
            "periods": [
                {"period": 1, "periodType": "REGULAR", "score": 22},
                {"period": 2, "periodType": "REGULAR", "score": 19},
                {"period": 3, "periodType": "REGULAR", "score": 24},
                {"period": 4, "periodType": "REGULAR", "score": 20}
            ]
        }
        """
    }
    
    func createAwayTeamJSON() -> String {
        return """
        "awayTeam": {
            "teamId": 1611661314,
            "teamName": "Aces",
            "teamCity": "Las Vegas",
            "teamTricode": "LVA",
            "score": 80,
            "inBonus": "1",
            "timeoutsRemaining": 1,
            "periods": [
                {"period": 1, "periodType": "REGULAR", "score": 18},
                {"period": 2, "periodType": "REGULAR", "score": 21},
                {"period": 3, "periodType": "REGULAR", "score": 20},
                {"period": 4, "periodType": "REGULAR", "score": 21}
            ]
        }
        """
    }
    
    func createTestGame(
        state: Int,
        homeScore: Int? = nil,
        awayScore: Int? = nil
    ) -> Game {
        return Game(
            gid: "testGame",
            easternTime: "2025-05-01T19:00:00Z",
            utcTime: "2025-05-01T23:00:00Z",
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            home: Team(
                tid: 1,
                abbr: "NYL",
                city: "New York",
                name: "Liberty",
                score: homeScore,
                losses: 2,
                wins: 10
            ),
            visitor: Team(
                tid: 2,
                abbr: "LVA",
                city: "Las Vegas",
                name: "Aces",
                score: awayScore,
                losses: 3,
                wins: 9
            ),
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
}
