import Foundation
import os.log
import SwiftUI

/// Protocol for schedule management functionality
protocol ScheduleManagerProtocol {
    /// Fetches games for a specific team
    /// - Parameter teamAbbr: The team abbreviation (e.g., "NYL")
    /// - Returns: Filtered games for the team
    func fetchGames(forTeam teamAbbr: String) async throws -> FilteredGames
    
    /// Fetches games for a specific team and season
    /// - Parameters:
    ///   - teamAbbr: The team abbreviation (e.g., "NYL")
    ///   - season: The season year (e.g., "2025"). If nil, uses current year.
    /// - Returns: Filtered games for the team in the specified season
    func fetchGames(forTeam teamAbbr: String, season: String?) async throws -> FilteredGames
}

/// Manages the fetching and filtering of WNBA games
class ScheduleManager: ScheduleManagerProtocol {
    // MARK: - Properties
    
    private let client: NBAClientProtocol
    private let userPreferences: UserPreferences
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "ScheduleManager")
    
    // MARK: - Initialization
    
    init(client: NBAClientProtocol, userPreferences: UserPreferences = DependencyContainer.shared.userPreferences) {
        self.client = client
        self.userPreferences = userPreferences
        logger.info("ScheduleManager initialized")
    }
    
    // MARK: - Public Methods
    
    func fetchGames(forTeam teamAbbr: String) async throws -> FilteredGames {
        // Use the current season by default (let NBAClient handle it)
        return try await fetchGames(forTeam: teamAbbr, season: nil)
    }
    
    func fetchGames(forTeam teamAbbr: String, season: String?) async throws -> FilteredGames {
        let seasonDisplay = season ?? "current year"
        logger.info("Fetching games for team \(teamAbbr) in season \(seasonDisplay)")
        
        let response = try await client.fetchSchedule(season: season)
        return filterGames(from: response.results.schedule, forTeam: teamAbbr)
    }
    
    // MARK: - Private Methods
    
    private func filterGames(from allGames: [Game], forTeam teamAbbr: String) -> FilteredGames {
        // Filter games for the specified team
        let teamGames = allGames.filter { game in
            game.home.abbr == teamAbbr || game.visitor.abbr == teamAbbr
        }
        
        let now = Date()
        
        // Mark games as home or away for the specified team
        let markedGames = teamGames.map { game -> MarkedGame in
            let isHome = game.home.abbr == teamAbbr
            return MarkedGame(game: game, isHomeGame: isHome)
        }
        
        // Split into past and upcoming games
        let pastGames = markedGames.filter { $0.game.localGameTime < now }
        let upcomingGames = markedGames.filter { $0.game.localGameTime >= now }
        
        // Sort past games by date (oldest first)
        let sortedPastGames = pastGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        
        // Sort upcoming games by date (earliest first)
        let sortedUpcomingGames = upcomingGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        
        // Use user preferences for the number of games to display
        let pastGamesToShow = userPreferences.pastGamesToShow
        let upcomingGamesToShow = userPreferences.upcomingGamesToShow
        
        let recentPastGames = Array(sortedPastGames.prefix(pastGamesToShow))
        let nextUpcomingGames = Array(sortedUpcomingGames.prefix(upcomingGamesToShow))
        
        logger.info(
            "Team \(teamAbbr): \(teamGames.count) games, \(recentPastGames.count) past, \(nextUpcomingGames.count) upc"
        )
        
        return FilteredGames(
            pastGames: recentPastGames,
            upcomingGames: nextUpcomingGames
        )
    }
}

/// Represents filtered games for a team
struct FilteredGames {
    let pastGames: [MarkedGame]
    let upcomingGames: [MarkedGame]
    
    var isEmpty: Bool {
        return pastGames.isEmpty && upcomingGames.isEmpty
    }
    
    var hasUpcomingGames: Bool {
        return !upcomingGames.isEmpty
    }
    
    var hasPastGames: Bool {
        return !pastGames.isEmpty
    }
}

/// Represents a game marked as home or away for a specific team
struct MarkedGame: Identifiable {
    let game: Game
    let isHomeGame: Bool
    
    var id: String {
        return game.gid
    }
    
    var teamIsHome: Bool {
        return isHomeGame
    }
    
    var teamIsAway: Bool {
        return !isHomeGame
    }
    
    var opponentTeam: Team {
        return isHomeGame ? game.visitor : game.home
    }
    
    var teamScore: Int? {
        return isHomeGame ? game.home.score : game.visitor.score
    }
    
    var opponentScore: Int? {
        return isHomeGame ? game.visitor.score : game.home.score
    }
    
    var teamWon: Bool {
        guard let teamScore = teamScore, let opponentScore = opponentScore else {
            return false
        }
        return teamScore > opponentScore
    }
    
    /// Determines if the opponent won the game
    var opponentWon: Bool {
        guard let teamScore = teamScore, let opponentScore = opponentScore else {
            return false
        }
        return opponentScore > teamScore
    }
    
    /// Get the color for the team name and score
    func getTeamColor(teamColor: Color) -> Color {
        // Only apply win/loss colors for completed games
        if !game.isCompleted {
            return teamColor
        }
        return teamWon ? teamColor : .red
    }
    
    /// Get the color for the opponent name and score
    func getOpponentColor() -> Color {
        // Only apply win/loss colors for completed games
        if !game.isCompleted {
            return .gray
        }
        return opponentWon ? .green : .red
    }
}
