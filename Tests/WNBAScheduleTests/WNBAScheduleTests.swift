import XCTest
import SwiftDate
@testable import WNBASchedule

final class WNBAScheduleTests: XCTestCase {
    // MARK: - Team Tests
    
    func testTeamModel() {
        // Create sample teams
        let homeTeam = Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: 85, losses: 2, wins: 10)
        let awayTeam = Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: 80, losses: 3, wins: 9)
        
        // Test basic properties
        XCTAssertEqual(homeTeam.abbr, "NYL")
        XCTAssertEqual(homeTeam.city, "New York")
        XCTAssertEqual(homeTeam.name, "Liberty")
        XCTAssertEqual(homeTeam.score, 85)
        XCTAssertEqual(homeTeam.losses, 2)
        XCTAssertEqual(homeTeam.wins, 10)
        
        // Test computed properties
        XCTAssertEqual(homeTeam.fullName, "New York Liberty")
        XCTAssertEqual(awayTeam.fullName, "Las Vegas Aces")
        
        // Test record string
        XCTAssertEqual(homeTeam.recordString, "10-2")
        XCTAssertEqual(awayTeam.recordString, "9-3")
        
        // Test team with missing record
        let teamWithoutRecord = Team(tid: 3, abbr: "CON", city: "Connecticut", name: "Sun", score: nil, losses: nil, wins: nil)
        XCTAssertNil(teamWithoutRecord.recordString)
        
        // Test primary color (this depends on TeamManager)
        XCTAssertFalse(homeTeam.primaryColor.isEmpty)
    }
    
    // MARK: - Game Tests
    
    func testGameProperties() {
        // Create a sample game
        let game = createTestGame()
        
        // Test basic properties
        XCTAssertEqual(game.gid, "1234")
        XCTAssertEqual(game.home.abbr, "NYL")
        XCTAssertEqual(game.visitor.abbr, "LVA")
        XCTAssertEqual(game.state, 3)
        
        // Test computed properties
        XCTAssertTrue(game.isCompleted)
        XCTAssertFalse(game.isInProgress)
        XCTAssertFalse(game.isUpcoming)
        XCTAssertEqual(game.statusDescription, "Final")
        
        // Test arena location
        XCTAssertEqual(game.arenaLocation, "Barclays Center, Brooklyn, NY")
        
        // Test game URL
        XCTAssertEqual(game.gameURL?.absoluteString, "https://www.wnba.com/game/1234/")
    }
    
    func testGameStatusProperties() {
        // Test different game states
        let completedGame = createTestGame(state: 3)
        let inProgressGame = createTestGame(state: 1)
        let halftimeGame = createTestGame(state: 2)
        let upcomingGame = createTestGame(state: 0)
        let unknownStateGame = createTestGame(state: 99)
        
        // Test status properties
        XCTAssertTrue(completedGame.isCompleted)
        XCTAssertFalse(completedGame.isInProgress)
        XCTAssertFalse(completedGame.isUpcoming)
        
        XCTAssertFalse(inProgressGame.isCompleted)
        XCTAssertTrue(inProgressGame.isInProgress)
        XCTAssertFalse(inProgressGame.isUpcoming)
        
        XCTAssertFalse(halftimeGame.isCompleted)
        XCTAssertTrue(halftimeGame.isInProgress)
        XCTAssertFalse(halftimeGame.isUpcoming)
        
        XCTAssertFalse(upcomingGame.isCompleted)
        XCTAssertFalse(upcomingGame.isInProgress)
        XCTAssertTrue(upcomingGame.isUpcoming)
        
        // Test status descriptions
        XCTAssertEqual(completedGame.statusDescription, "Final")
        XCTAssertEqual(inProgressGame.statusDescription, "In Progress")
        XCTAssertEqual(halftimeGame.statusDescription, "Halftime")
        XCTAssertEqual(upcomingGame.statusDescription, "Upcoming")
        XCTAssertEqual(unknownStateGame.statusDescription, "Unknown")
    }
    
    func testGameDateFormatting() {
        // Create a game with a known timestamp
        let timestamp: Int64 = 1746226800000 // May 1, 2025 23:00:00 UTC
        let game = createTestGame(timestamp: timestamp)
        
        // Get the expected date
        let expectedDate = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let expectedRegion = expectedDate.toSwiftDate()
        
        // Test date properties
        XCTAssertEqual(game.localGameTime.timeIntervalSince1970, expectedDate.timeIntervalSince1970)
        
        // Test formatted date strings
        XCTAssertEqual(game.formattedGameDate, expectedRegion.toString(.custom("EEE MMM d, yyyy")))
        XCTAssertEqual(game.formattedGameTime, expectedRegion.toString(.custom("h:mm a")))
        XCTAssertEqual(game.formattedDateTime, "\(game.formattedGameDate) at \(game.formattedGameTime)")
    }
    
    func testDateParsingWithDifferentFormats() {
        // Test with millisecond precision
        let gameWithMilliseconds = createTestGame(
            utcTime: "2025-05-01T23:00:00.123Z",
            timestamp: 1746226800123
        )
        
        // Test with second precision
        let gameWithSeconds = createTestGame(
            utcTime: "2025-05-01T23:00:00Z",
            timestamp: 1746226800000
        )
        
        // Test with invalid format but valid timestamp
        let gameWithInvalidFormat = createTestGame(
            utcTime: "invalid-date-format",
            timestamp: 1746226800000
        )
        
        // Verify dates
        let expectedDate1 = Date(timeIntervalSince1970: 1746226800.123)
        let expectedDate2 = Date(timeIntervalSince1970: 1746226800.0)
        
        // We now prioritize timestamp over string parsing
        XCTAssertEqual(gameWithMilliseconds.localGameTime.timeIntervalSince1970, expectedDate1.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(gameWithSeconds.localGameTime.timeIntervalSince1970, expectedDate2.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(gameWithInvalidFormat.localGameTime.timeIntervalSince1970, expectedDate2.timeIntervalSince1970, accuracy: 0.001)
    }
    
    // MARK: - MarkedGame Tests
    
    func testMarkedGameProperties() {
        // Create a home game
        let homeGame = createTestGame()
        let markedHomeGame = MarkedGame(game: homeGame, isHomeGame: true)
        
        // Create an away game
        let awayGame = createTestGame(
            home: Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: 80, losses: 3, wins: 9),
            visitor: Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: 85, losses: 2, wins: 10)
        )
        let markedAwayGame = MarkedGame(game: awayGame, isHomeGame: false)
        
        // Test basic properties
        XCTAssertTrue(markedHomeGame.isHomeGame)
        XCTAssertTrue(markedHomeGame.teamIsHome)
        XCTAssertFalse(markedHomeGame.teamIsAway)
        
        XCTAssertFalse(markedAwayGame.isHomeGame)
        XCTAssertFalse(markedAwayGame.teamIsHome)
        XCTAssertTrue(markedAwayGame.teamIsAway)
        
        // Test opponent team
        XCTAssertEqual(markedHomeGame.opponentTeam.abbr, "LVA")
        XCTAssertEqual(markedAwayGame.opponentTeam.abbr, "LVA")
        
        // Test scores
        XCTAssertEqual(markedHomeGame.teamScore, 85)
        XCTAssertEqual(markedHomeGame.opponentScore, 80)
        XCTAssertEqual(markedAwayGame.teamScore, 85)
        XCTAssertEqual(markedAwayGame.opponentScore, 80)
        
        // Test win/loss
        XCTAssertTrue(markedHomeGame.teamWon)
        XCTAssertTrue(markedAwayGame.teamWon)
        
        // Test with nil scores
        let gameWithNilScores = createTestGame(
            home: Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: nil, losses: 2, wins: 10),
            visitor: Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: nil, losses: 3, wins: 9)
        )
        let markedGameWithNilScores = MarkedGame(game: gameWithNilScores, isHomeGame: true)
        
        XCTAssertNil(markedGameWithNilScores.teamScore)
        XCTAssertNil(markedGameWithNilScores.opponentScore)
        XCTAssertFalse(markedGameWithNilScores.teamWon)
    }
    
    func testMarkedGameIdentifiable() {
        // Test that MarkedGame conforms to Identifiable
        let game = createTestGame()
        let markedGame = MarkedGame(game: game, isHomeGame: true)
        
        XCTAssertEqual(markedGame.id, game.gid)
    }
    
    // MARK: - Provider Tests
    
    func testProviderProperties() {
        let provider = Provider(
            broadcasterScope: "natl",
            broadcasterMedia: "tv",
            broadcasterId: 1,
            broadcasterDisplay: "ESPN",
            broadcasterAbbreviation: "ESPN",
            broadcasterDescription: "ESPN",
            tapeDelayComments: "",
            broadcasterVideoLink: "https://example.com",
            broadcasterTeamId: 0,
            broadcasterRanking: 1
        )
        
        // Test basic properties
        XCTAssertEqual(provider.broadcasterScope, "natl")
        XCTAssertEqual(provider.broadcasterMedia, "tv")
        XCTAssertEqual(provider.broadcasterId, 1)
        XCTAssertEqual(provider.broadcasterDisplay, "ESPN")
        
        // Test computed properties
        XCTAssertTrue(provider.isNational)
        XCTAssertFalse(provider.isLocal)
        
        // Test local provider
        let localProvider = Provider(
            broadcasterScope: "local",
            broadcasterMedia: "tv",
            broadcasterId: 2,
            broadcasterDisplay: "YES",
            broadcasterAbbreviation: "YES",
            broadcasterDescription: "YES Network",
            tapeDelayComments: "",
            broadcasterVideoLink: "https://example.com",
            broadcasterTeamId: 1,
            broadcasterRanking: 2
        )
        
        XCTAssertFalse(localProvider.isNational)
        XCTAssertTrue(localProvider.isLocal)
    }
    
    // MARK: - Helper Methods
    
    private func createTestGame(
        id: Int = 1,
        gid: String = "1234",
        utcTime: String = "2025-05-01T23:00:00Z",
        timestamp: Int64 = 1746226800000,
        home: Team? = nil,
        visitor: Team? = nil,
        state: Int = 3
    ) -> Game {
        let homeTeam = home ?? Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: 85, losses: 2, wins: 10)
        let awayTeam = visitor ?? Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: 80, losses: 3, wins: 9)
        
        return Game(
            gid: gid,
            easternTime: utcTime,
            utcTime: utcTime,
            timestamp: timestamp,
            home: homeTeam,
            visitor: awayTeam,
            state: state,
            id: id,
            type: "game",
            title: "Test Game",
            homeTime: utcTime,
            visitorTime: utcTime,
            providers: nil,
            arenaName: "Barclays Center",
            arenaState: "NY",
            arenaCity: "Brooklyn",
            gameStatusText: "Final",
            gameLabel: "",
            gameSubLabel: "",
            seriesText: "",
            seriesGameNumber: "",
            ifNecessary: false,
            gameSubtype: "",
            name: "test-game",
            themeNightLabel: "",
            ticketUrl: "",
            isLeaguePassGame: true,
            leaguePassVideoLink: "https://example.com"
        )
    }
    

    // MARK: - End of Tests
}