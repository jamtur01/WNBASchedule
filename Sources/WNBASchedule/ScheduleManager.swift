import Foundation

class ScheduleManager {
    private let client: NBAClient
    
    init(client: NBAClient) {
        self.client = client
    }
    
    func fetchGames(forTeam teamAbbr: String) async throws -> FilteredGames {
        let response = try await client.fetchSchedule()
        return filterGames(from: response.results.schedule, forTeam: teamAbbr)
    }
    
    private func filterGames(from allGames: [Game], forTeam teamAbbr: String) -> FilteredGames {
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
        
        // Configure the number of games to display
        let maxPastGames = 10 // Display up to 10 past games
        let recentPastGames = Array(sortedPastGames.prefix(maxPastGames))
        let nextUpcomingGames = Array(sortedUpcomingGames.prefix(5))
        
        return FilteredGames(
            pastGames: recentPastGames,
            upcomingGames: nextUpcomingGames
        )
    }
}

struct FilteredGames {
    let pastGames: [MarkedGame]
    let upcomingGames: [MarkedGame]
}

struct MarkedGame {
    let game: Game
    let isHomeGame: Bool
}