import Foundation

class GameFormatter {
    private let detailed: Bool
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    
    init(detailed: Bool) {
        self.detailed = detailed
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .none
        
        self.timeFormatter = DateFormatter()
        self.timeFormatter.dateStyle = .none
        self.timeFormatter.timeStyle = .short
    }
    
    func displayGames(_ filteredGames: FilteredGames) {
        print("\n=== NY LIBERTY SCHEDULE ===\n")
        
        if !filteredGames.pastGames.isEmpty {
            print("PREVIOUS GAMES:")
            print("---------------")
            for (index, markedGame) in filteredGames.pastGames.enumerated() {
                print("\(index + 1). \(formatPastGame(markedGame))")
                if detailed {
                    printGameDetails(markedGame.game)
                }
            }
            print("")
        }
        
        if !filteredGames.upcomingGames.isEmpty {
            print("UPCOMING GAMES:")
            print("--------------")
            for (index, markedGame) in filteredGames.upcomingGames.enumerated() {
                print("\(index + 1). \(formatUpcomingGame(markedGame))")
                if detailed {
                    printGameDetails(markedGame.game)
                }
            }
            print("")
        }
    }
    
    private func formatPastGame(_ markedGame: MarkedGame) -> String {
        let game = markedGame.game
        let homeTeam = game.home
        let awayTeam = game.visitor
        
        let date = dateFormatter.string(from: game.localGameTime)
        let locationIndicator = markedGame.isHomeGame ? "HOME" : "AWAY"
        
        let result: String
        if let winner = game.winner {
            let didWin: Bool
            if let winnerTid = winner.tid, let homeTid = homeTeam.tid, let awayTid = awayTeam.tid {
                didWin = (markedGame.isHomeGame && winnerTid == homeTid) ||
                         (!markedGame.isHomeGame && winnerTid == awayTid)
            } else {
                // If we can't determine the winner by tid, use score comparison
                if let homeScore = homeTeam.score, let awayScore = awayTeam.score {
                    didWin = markedGame.isHomeGame ? homeScore > awayScore : awayScore > homeScore
                } else {
                    didWin = false
                }
            }
            result = didWin ? "WIN" : "LOSS"
        } else {
            result = "TIE"
        }
        
        return "\(date) - \(awayTeam.abbr) \(awayTeam.score ?? 0) @ \(homeTeam.abbr) \(homeTeam.score ?? 0) - \(result) [\(locationIndicator)]"
    }
    
    private func formatUpcomingGame(_ markedGame: MarkedGame) -> String {
        let game = markedGame.game
        let homeTeam = game.home
        let awayTeam = game.visitor
        
        // Format date in local time zone
        let date = dateFormatter.string(from: game.localGameTime)
        let time = timeFormatter.string(from: game.localGameTime)
        
        let locationIndicator = markedGame.isHomeGame ? "HOME" : "AWAY"
        
        return "\(date) at \(time) - \(awayTeam.abbr) @ \(homeTeam.abbr) [\(locationIndicator)]"
    }
    
    private func printGameDetails(_ game: Game) {
        if let arenaName = game.arenaName, let arenaCity = game.arenaCity, let arenaState = game.arenaState {
            print("   Arena: \(arenaName) in \(arenaCity), \(arenaState)")
        } else {
            print("   Arena: Information not available")
        }
        
        if let providers = game.providers, !providers.isEmpty {
            let broadcasts = providers.map { $0.broadcasterDisplay }.joined(separator: ", ")
            print("   Broadcast: \(broadcasts)")
        }
        
        if game.isLeaguePassGame == true, let link = game.leaguePassVideoLink {
            print("   League Pass: \(link)")
        }
        
        print("   Status: \(game.gameStatusText ?? "Unknown")")
        print("")
    }
}