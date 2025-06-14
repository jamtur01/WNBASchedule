import Foundation
import os.log

/// Manages live score fetching and game completion detection
class LiveScoreManager {
    // MARK: - Properties
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "LiveScoreManager")
    
    // MARK: - Public Methods
    
    /// Fetches live scores and checks if any games have finished
    /// - Parameters:
    ///   - games: Array of games to check for live scores
    ///   - gameFinished: Inout parameter to indicate if any game finished
    /// - Returns: Updated games array with live scores populated
    func fetchLiveScoresAndCheckCompletion(for games: [Game], gameFinished: inout Bool) async -> [Game] {
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
        await withTaskGroup(of: (Int, BoxscoreResponse?, Bool)?.self) { group in
            for index in inProgressGameIndices {
                let game = games[index]
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    do {
                        let boxscore = try await DependencyContainer.shared.nbaClient.fetchBoxscore(gameId: game.gid)
                        
                        // Check if game finished
                        let finished = boxscore.game.gameStatusText == "Final"
                        
                        return (index, boxscore, finished)
                    } catch {
                        self.logger.error(
                            "Failed to fetch boxscore for game \(game.gid): \(error.localizedDescription)"
                        )
                        return (index, nil, false)
                    }
                }
            }
            
            for await result in group {
                guard let (index, boxscore, finished) = result else { continue }
                
                // Update the game with live scores
                updatedGames[index].liveHomeScore = boxscore?.game.homeTeam.score
                updatedGames[index].liveVisitorScore = boxscore?.game.awayTeam.score
                
                // Mark if any game finished
                if finished {
                    gameFinished = true
                    logger.info("Game \(games[index].gid) finished!")
                }
                
                if let homeScore = boxscore?.game.homeTeam.score,
                   let awayScore = boxscore?.game.awayTeam.score {
                    self.logger.info("Updated live scores for game \(games[index].gid): \(awayScore)-\(homeScore)")
                }
            }
        }
        
        return updatedGames
    }
    
    /// Fetches live scores for in-progress games without completion checking
    /// - Parameter games: Array of games to check for live scores
    /// - Returns: Updated games array with live scores populated
    func fetchLiveScores(for games: [Game]) async -> [Game] {
        var gameFinished = false
        return await fetchLiveScoresAndCheckCompletion(for: games, gameFinished: &gameFinished)
    }
    
    /// Updates live scores for all teams mode
    /// - Parameters:
    ///   - userPreferences: User preferences for filtering
    ///   - completion: Completion handler with results
    func updateLiveScoresForAllTeams(
        userPreferences: UserPreferences,
        completion: @escaping (Result<AllTeamsLiveScoreResult, Error>) -> Void
    ) async {
        // Get current games for All Teams mode
        let currentYear = Calendar.current.component(.year, from: Date())
        let season = String(currentYear)
        
        do {
            let response = try await DependencyContainer.shared.nbaClient.fetchSchedule(season: season)
            let allGames: [Game] = response.results.schedule
            
            // Filter for games in the next N days (including today)
            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            guard let endDate = calendar.date(
                byAdding: .day,
                value: userPreferences.allTeamsDaysToShow,
                to: startOfToday
            ) else {
                logger.error("Failed to calculate end date for filtering games.")
                completion(.failure(LiveScoreError.dateCalculationFailed))
                return
            }
            
            let filteredGames = allGames.filter { game in
                let gameDate = calendar.startOfDay(for: game.localGameTime)
                return gameDate >= startOfToday && gameDate < endDate
            }.sorted { $0.localGameTime < $1.localGameTime }
            
            // Split games
            var inProgressGames = filteredGames.filter { $0.isInProgress }
            let upcomingGames = filteredGames.filter { $0.isUpcoming }
            
            // Check if any games finished
            var gameFinished = false
            
            if !inProgressGames.isEmpty {
                // Fetch live scores and check for completed games
                inProgressGames = await fetchLiveScoresAndCheckCompletion(
                    for: inProgressGames, 
                    gameFinished: &gameFinished
                )
            }
            
            completion(.success(AllTeamsLiveScoreResult(
                inProgressGames: inProgressGames,
                upcomingGames: upcomingGames,
                gameFinished: gameFinished
            )))
            
        } catch {
            logger.error("Error updating live scores for all teams: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    /// Updates live scores for individual team mode
    /// - Parameters:
    ///   - currentGames: Current filtered games
    ///   - completion: Completion handler with results
    func updateLiveScoresForTeam(
        currentGames: FilteredGames,
        completion: @escaping (Result<(updatedGames: FilteredGames, gameFinished: Bool), Error>) -> Void
    ) async {
        var gameFinished = false
        var updatedInProgressGames: [MarkedGame] = []
        
        if !currentGames.inProgressGames.isEmpty {
            // Fetch live scores and check for completion
            let inProgressGames = currentGames.inProgressGames.map { $0.game }
            let updatedGamesList = await fetchLiveScoresAndCheckCompletion(
                for: inProgressGames, 
                gameFinished: &gameFinished
            )
            
            // Create updated MarkedGame instances
            updatedInProgressGames = updatedGamesList.map { game in
                let originalMarkedGame = currentGames.inProgressGames.first { $0.game.gid == game.gid }
                return MarkedGame(game: game, isHomeGame: originalMarkedGame?.isHomeGame ?? false)
            }
        } else {
            updatedInProgressGames = currentGames.inProgressGames
        }
        
        // Create new FilteredGames instance
        let updatedGames = FilteredGames(
            pastGames: currentGames.pastGames,
            inProgressGames: updatedInProgressGames,
            upcomingGames: currentGames.upcomingGames
        )
        
        completion(.success((updatedGames: updatedGames, gameFinished: gameFinished)))
    }
}

// MARK: - Supporting Types
struct AllTeamsLiveScoreResult {
    let inProgressGames: [Game]
    let upcomingGames: [Game]
    let gameFinished: Bool
}

// MARK: - LiveScoreError
enum LiveScoreError: Error, LocalizedError {
    case dateCalculationFailed
    
    var errorDescription: String? {
        switch self {
        case .dateCalculationFailed:
            return "Failed to calculate end date for filtering games"
        }
    }
}
