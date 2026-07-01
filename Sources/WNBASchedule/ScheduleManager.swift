import Foundation
import os.log

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
    
    /// Fetches all teams games (in-progress and upcoming)
    /// - Parameter season: The season year (e.g., "2025"). If nil, uses current year.
    /// - Returns: Tuple containing in-progress and upcoming games arrays
    func fetchAllTeamsGames(season: String?) async throws -> (inProgress: [Game], upcoming: [Game])
}

/// Manages the fetching and filtering of WNBA games
class ScheduleManager: ScheduleManagerProtocol {
    // MARK: - Properties
    
    private let client: NBAClientProtocol
    private let userPreferences: UserPreferences
    private let liveScoreManager: LiveScoreManager
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "ScheduleManager")
    
    // MARK: - Initialization
    
    init(client: NBAClientProtocol, userPreferences: UserPreferences = DependencyContainer.shared.userPreferences, liveScoreManager: LiveScoreManager = LiveScoreManager()) {
        self.client = client
        self.userPreferences = userPreferences
        self.liveScoreManager = liveScoreManager
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
        let allGames = response.results.schedule
        
        // Filter games first to reduce API calls
        let filteredGames = filterGames(from: allGames, forTeam: teamAbbr)
        
        // Only fetch live scores for the filtered in-progress games
        if !filteredGames.inProgressGames.isEmpty {
            let inProgressGames = filteredGames.inProgressGames.map { $0.game }
            let updatedInProgressGames = await liveScoreManager.fetchLiveScores(for: inProgressGames)
            
            let updatedMarkedGames = updatedInProgressGames.map { updatedGame in
                MarkedGame(
                    game: updatedGame,
                    isHomeGame: updatedGame.home.abbr == teamAbbr
                )
            }
            
            return FilteredGames(
                pastGames: filteredGames.pastGames,
                inProgressGames: updatedMarkedGames,
                upcomingGames: filteredGames.upcomingGames
            )
        }
        
        return filteredGames
    }
    
    func fetchAllTeamsGames(season: String? = nil) async throws -> (inProgress: [Game], upcoming: [Game]) {
        let currentYear = Calendar.current.component(.year, from: Date())
        let selectedSeason = season ?? String(currentYear)
        
        logger.info("Fetching all teams games for season \(selectedSeason)")
        
        let response = try await client.fetchSchedule(season: selectedSeason)
        let allGames = response.results.schedule
        
        // Filter and sort games by status
        let inProgressGames = allGames.filter { $0.isInProgress }
        let upcomingGames = allGames.filter { $0.isUpcoming }
            .sorted { $0.localGameTime < $1.localGameTime }
        
        logger.info("Found \(inProgressGames.count) in-progress and \(upcomingGames.count) upcoming games")
        
        return (inProgressGames, upcomingGames)
    }
    
    // MARK: - Private Methods
    
    private func filterGames(from allGames: [Game], forTeam teamAbbr: String) -> FilteredGames {
        // Filter and mark games for the specified team in a single pass
        let markedGames = allGames
            .filter { game in
                game.home.abbr == teamAbbr || game.visitor.abbr == teamAbbr
            }
            .map { game -> MarkedGame in
                let isHome = game.home.abbr == teamAbbr
                return MarkedGame(game: game, isHomeGame: isHome)
            }
        
        // Group games by status in a single pass using Dictionary grouping
        var pastGames: [MarkedGame] = []
        var inProgressGames: [MarkedGame] = []
        var upcomingGames: [MarkedGame] = []
        
        for markedGame in markedGames {
            if markedGame.game.isCompleted {
                pastGames.append(markedGame)
            } else if markedGame.game.isInProgress {
                inProgressGames.append(markedGame)
            } else if markedGame.game.isUpcoming {
                upcomingGames.append(markedGame)
            }
        }
        
        // Sort games by date
        let sortedPastGames = pastGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        let sortedInProgressGames = inProgressGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        let sortedUpcomingGames = upcomingGames.sorted { $0.game.localGameTime < $1.game.localGameTime }
        
        // Use user preferences for the number of games to display
        let pastGamesToShow = userPreferences.pastGamesToShow
        let upcomingGamesToShow = userPreferences.upcomingGamesToShow
        
        let recentPastGames = Array(sortedPastGames.suffix(pastGamesToShow))
        let nextUpcomingGames = Array(sortedUpcomingGames.prefix(upcomingGamesToShow))
        // Show all in-progress games (there shouldn't be many at once)
        let allInProgressGames = sortedInProgressGames
        
        logger.info(
            "Team \(teamAbbr): \(markedGames.count) games, \(recentPastGames.count) past, \(allInProgressGames.count) in-progress, \(nextUpcomingGames.count) upcoming"
        )
        
        return FilteredGames(
            pastGames: recentPastGames,
            inProgressGames: allInProgressGames,
            upcomingGames: nextUpcomingGames
        )
    }
}

/// Represents filtered games for a team
struct FilteredGames {
    let pastGames: [MarkedGame]
    let inProgressGames: [MarkedGame]
    let upcomingGames: [MarkedGame]
}

/// Represents a game marked as home or away for a specific team
struct MarkedGame: Identifiable {
    let game: Game
    let isHomeGame: Bool
    
    var id: String {
        return game.gid
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
}
