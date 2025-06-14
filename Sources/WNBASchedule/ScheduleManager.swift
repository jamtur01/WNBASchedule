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
        var games = response.results.schedule
        
        // Fetch live scores for in-progress games
        games = await fetchLiveScores(for: games)
        
        return filterGames(from: games, forTeam: teamAbbr)
    }
    
    // MARK: - Private Methods
    
    private func filterGames(from allGames: [Game], forTeam teamAbbr: String) -> FilteredGames {
        // Filter games for the specified team
        let teamGames = allGames.filter { game in
            game.home.abbr == teamAbbr || game.visitor.abbr == teamAbbr
        }
        
        // Mark games as home or away for the specified team
        let markedGames = teamGames.map { game -> MarkedGame in
            let isHome = game.home.abbr == teamAbbr
            return MarkedGame(game: game, isHomeGame: isHome)
        }
        
        // Split into past, in-progress, and upcoming games
        let pastGames = markedGames.filter { $0.game.isCompleted }
        let inProgressGames = markedGames.filter { $0.game.isInProgress }
        let upcomingGames = markedGames.filter { $0.game.isUpcoming }
        
        // Sort past games by date (oldest first, latest last for display)
        let sortedPastGames = pastGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        
        // Sort in-progress games by date (earliest first)
        let sortedInProgressGames = inProgressGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        
        // Sort upcoming games by date (earliest first)
        let sortedUpcomingGames = upcomingGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        
        // Use user preferences for the number of games to display
        let pastGamesToShow = userPreferences.pastGamesToShow
        let upcomingGamesToShow = userPreferences.upcomingGamesToShow
        
        let recentPastGames = Array(sortedPastGames.suffix(pastGamesToShow))
        let nextUpcomingGames = Array(sortedUpcomingGames.prefix(upcomingGamesToShow))
        // Show all in-progress games (there shouldn't be many at once)
        let allInProgressGames = sortedInProgressGames
        
        logger.info(
            "Team \(teamAbbr): \(teamGames.count) games, \(recentPastGames.count) past, \(allInProgressGames.count) in-progress, \(nextUpcomingGames.count) upcoming"
        )
        
        return FilteredGames(
            pastGames: recentPastGames,
            inProgressGames: allInProgressGames,
            upcomingGames: nextUpcomingGames
        )
    }
    
    /// Fetches live scores for in-progress games
    /// - Parameter games: Array of games to check for live scores
    /// - Returns: Updated games array with live scores populated
    private func fetchLiveScores(for games: [Game]) async -> [Game] {
        var updatedGames = games
        
        // Find in-progress games
        let inProgressGameIndices = games.enumerated().compactMap { index, game in
            game.isInProgress ? index : nil
        }
        
        if inProgressGameIndices.isEmpty {
            logger.info("No in-progress games found, skipping live score fetch")
            return updatedGames
        }
        
        logger.info("Fetching live scores for \(inProgressGameIndices.count) in-progress games")
        
        // Fetch live scores concurrently
        await withTaskGroup(of: (Int, BoxscoreResponse?)?.self) { group in
            for index in inProgressGameIndices {
                let game = games[index]
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    do {
                        let boxscore = try await self.client.fetchBoxscore(gameId: game.gid)
                        return (index, boxscore)
                    } catch {
                        self.logger.error(
                            "Failed to fetch boxscore for game \(game.gid): \(error.localizedDescription)"
                        )
                        return (index, nil)
                    }
                }
            }
            
            for await result in group {
                guard let (index, boxscore) = result else { continue }
                
                // Update the game with live scores
                updatedGames[index].liveHomeScore = boxscore?.game.homeTeam.score
                updatedGames[index].liveVisitorScore = boxscore?.game.awayTeam.score
                
                if let homeScore = boxscore?.game.homeTeam.score,
                   let awayScore = boxscore?.game.awayTeam.score {
                    self.logger.info("Updated live scores for game \(games[index].gid): \(awayScore)-\(homeScore)")
                }
            }
        }
        
        return updatedGames
    }
}

/// Represents filtered games for a team
struct FilteredGames {
    let pastGames: [MarkedGame]
    let inProgressGames: [MarkedGame]
    let upcomingGames: [MarkedGame]
    
    var isEmpty: Bool {
        return pastGames.isEmpty && inProgressGames.isEmpty && upcomingGames.isEmpty
    }
    
    var hasUpcomingGames: Bool {
        return !upcomingGames.isEmpty
    }
    
    var hasPastGames: Bool {
        return !pastGames.isEmpty
    }
    
    var hasInProgressGames: Bool {
        return !inProgressGames.isEmpty
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
