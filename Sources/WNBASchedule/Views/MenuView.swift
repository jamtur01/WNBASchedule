import SwiftUI
import AppKit
import SwiftDate
import LaunchAtLogin

// MARK: - Menu View
struct MenuView: View {
    let games: FilteredGames
    let refreshAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Title
            Text("NY LIBERTY SCHEDULE")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.5, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
            
            Divider()
            
            // Previous Games Section
            if !games.pastGames.isEmpty {
                Text("PREVIOUS GAMES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.5, blue: 0.4))
                    .padding(.leading, 8)
                    .padding(.top, 5)
                
                ForEach(games.pastGames, id: \.game.gid) { markedGame in
                    PreviousGameRow(game: markedGame.game)
                }
                
                Divider()
            }
            
            // Upcoming Games Section
            if !games.upcomingGames.isEmpty {
                Text("UPCOMING GAMES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.5, blue: 0.4))
                    .padding(.leading, 8)
                    .padding(.top, 5)
                
                ForEach(games.upcomingGames, id: \.game.gid) { markedGame in
                    UpcomingGameRow(game: markedGame.game)
                }
                
                Divider()
            }
            
            // Launch at Login toggle
            LaunchAtLogin.Toggle()
                .padding(.vertical, 4)
            
            Divider()
            
            // Menu Actions on a single line with distinct styling
            HStack {
                // Buttons next to each other
                HStack(spacing: 8) {
                    // Refresh button - positive action (blue)
                    Button(action: {
                        refreshAction()
                    }) {
                        Text("Refresh")
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                    
                    // Quit button - more subtle (gray)
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Quit")
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
                
                Spacer()
                
                // Version as a small, subtle text on the far right
                Text("v\(Version.version)")
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.vertical, 8)
        }
        .frame(width: 320) // Increase width to accommodate the date and time
        .padding(.horizontal, 10)
    }
}

// MARK: - Previous Game Row
struct PreviousGameRow: View {
    let game: Game
    
    private var homeWon: Bool {
        return (game.home.score ?? 0) > (game.visitor.score ?? 0)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // Date
            Text(game.formattedGameDate)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 180, alignment: .leading) // Match the width of upcoming games
            
            // Game Score
            HStack(spacing: 5) {
                // Away Team
                Text("\(game.visitor.abbr) \(game.visitor.score ?? 0)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(homeWon ? .red : .green)
                
                // Separator
                Text("@")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                // Home Team
                Text("\(game.home.abbr) \(game.home.score ?? 0)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(homeWon ? .green : .red)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Upcoming Game Row
struct UpcomingGameRow: View {
    let game: Game
    
    var body: some View {
        // Use the same layout as PreviousGameRow for consistency
        HStack(alignment: .center) {
            // Date with time on the same line
            Text("\(game.formattedGameDate) \(game.formattedGameTime)")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 180, alignment: .leading) // Wider frame to accommodate the time
            
            // Game Matchup
            HStack(spacing: 5) {
                // Away Team
                Text(game.visitor.abbr)
                    .font(.system(size: 13, weight: .bold))
                
                // Separator
                Text("@")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                // Home Team
                Text(game.home.abbr)
                    .font(.system(size: 13, weight: .bold))
            }
        }
        .padding(.vertical, 2)
    }
}