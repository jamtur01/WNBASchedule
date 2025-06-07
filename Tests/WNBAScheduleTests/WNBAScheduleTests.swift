import XCTest
@testable import WNBASchedule

final class WNBAScheduleTests: XCTestCase {
    func testGameModel() {
        // Create a sample game
        let homeTeam = Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: 85, losses: 2, wins: 10)
        let awayTeam = Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: 80, losses: 3, wins: 9)
        
        // Test team full name
        XCTAssertEqual(homeTeam.fullName, "New York Liberty")
        XCTAssertEqual(awayTeam.fullName, "Las Vegas Aces")
    }
    
    
    func testMarkedGame() {
        // This is a simple test to ensure the MarkedGame struct works as expected
        let homeTeam = Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: 85, losses: 2, wins: 10)
        let awayTeam = Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: 80, losses: 3, wins: 9)
        
        let game = Game(
            id: 1,
            type: "game",
            gid: "1234",
            title: "Test Game",
            easternTime: "2025-05-01T19:00:00Z",
            homeTime: "2025-05-01T19:00:00Z",
            visitorTime: "2025-05-01T19:00:00Z",
            utcTime: "2025-05-01T23:00:00Z",
            timestamp: 1746226800000,
            home: homeTeam,
            visitor: awayTeam,
            providers: nil,
            state: 3,
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
        
        let markedGame = MarkedGame(game: game, isHomeGame: true)
        
        XCTAssertTrue(markedGame.isHomeGame)
        XCTAssertEqual(markedGame.game.home.abbr, "NYL")
        XCTAssertEqual(markedGame.game.visitor.abbr, "LVA")
    }
    
    func testRobustDateParsing() {
        // Verify date parsing with various UTC time formats and timestamp fallback
        let game = Game(
            id: 3,
            type: "game",
            gid: "1022500041",
            title: "06/01/2025: Connecticut Sun @ New York Liberty - 1022500041",
            easternTime: "2025-06-01T15:00:00Z",
            homeTime: "2025-06-01T15:00:00Z",
            visitorTime: "2025-06-01T15:00:00Z",
            utcTime: "2025-06-01T19:00:00Z",
            timestamp: 1748804400000,
            home: Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: 100, losses: 0, wins: 7),
            visitor: Team(tid: 2, abbr: "CON", city: "Connecticut", name: "Sun", score: 52, losses: 6, wins: 1),
            providers: nil,
            state: 3,
            arenaName: nil,
            arenaState: nil,
            arenaCity: nil,
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
        
        // Get the date components
        let date = game.localGameTime
        
        // Verify that the date is not the default Date()
        XCTAssertNotEqual(date.timeIntervalSince1970, Date().timeIntervalSince1970)
        
        // Verify that the timestamp was used correctly
        let timestampDate = Date(timeIntervalSince1970: Double(game.timestamp) / 1000.0)
        XCTAssertEqual(date.timeIntervalSince1970, timestampDate.timeIntervalSince1970)
    }

    static var allTests = [
        ("testGameModel", testGameModel),
        ("testMarkedGame", testMarkedGame),
        ("testRobustDateParsing", testRobustDateParsing),
    ]
}