import Foundation

/// Utility for filtering games based on date ranges
enum GameFiltering {
    /// Filters games for all teams mode showing games from today to specified number of days
    /// - Parameters:
    ///   - allGames: Array of all games to filter
    ///   - daysToShow: Number of days to show from today
    /// - Returns: Filtered and sorted games
    /// - Throws: LiveScoreError.dateCalculationFailed if unable to calculate end date
    static func filterGamesForAllTeams(_ allGames: [Game], daysToShow: Int) throws -> [Game] {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        
        guard let endDate = calendar.date(
            byAdding: .day,
            value: daysToShow,
            to: startOfToday
        ) else {
            throw LiveScoreError.dateCalculationFailed
        }
        
        return allGames.filter { game in
            let gameDate = calendar.startOfDay(for: game.localGameTime)
            return gameDate >= startOfToday && gameDate < endDate
        }.sorted { $0.localGameTime < $1.localGameTime }
    }
}
