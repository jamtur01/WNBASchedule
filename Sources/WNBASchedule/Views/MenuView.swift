import SwiftUI
import AppKit
import SwiftDate
import LaunchAtLogin
import Combine

// MARK: - Menu View
struct MenuView: View {
    // MARK: - Properties
    
    let games: FilteredGames
    let teamAbbreviation: String
    let refreshAction: () -> Void
    let changeTeamAction: (String) -> Void
    
    @State private var showingTeamPicker = false
    
    private var teamInfo: TeamManager.TeamInfo? {
        return TeamManager.getTeamInfo(abbreviation: teamAbbreviation)
    }
    
    private var teamColor: Color {
        if let hexColor = teamInfo?.primaryColor {
            return Color(hex: hexColor) ?? Color.blue
        }
        return Color.blue
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Title
            HStack {
                Text("\(teamInfo?.fullName.uppercased() ?? "WNBA") SCHEDULE")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(teamColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                
                Button(action: {
                    showingTeamPicker.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Team picker (shown when settings button is clicked)
            if showingTeamPicker {
                TeamPickerView(
                    selectedTeam: teamAbbreviation,
                    onTeamSelected: { newTeam in
                        changeTeamAction(newTeam)
                        showingTeamPicker = false
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingTeamPicker)
            }
            
            Divider()
            
            // Previous Games Section
            if !games.pastGames.isEmpty {
                Text("PREVIOUS GAMES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(teamColor)
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
                    .foregroundColor(teamColor)
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
                            .background(teamColor)
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
        .frame(width: 320) // Width to accommodate the date and time
        .padding(.horizontal, 10)
    }
}

// MARK: - Team Picker View
struct TeamPickerView: View {
    let selectedTeam: String
    let onTeamSelected: (String) -> Void

    @State private var searchText: String = ""

    var filteredTeams: [TeamManager.TeamInfo] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return TeamManager.allTeams
        } else {
            return TeamManager.allTeams.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.abbreviation.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Select Team")
                .font(.system(size: 12, weight: .bold))
                .padding(.bottom, 2)

            // Search field for filtering teams
            TextField("Search teams...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 12))
                .padding(.bottom, 4)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredTeams, id: \.abbreviation) { team in
                        Button(action: {
                            onTeamSelected(team.abbreviation)
                        }) {
                            HStack {
                                Text(team.fullName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)

                                Spacer()

                                if team.abbreviation == selectedTeam {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(team.abbreviation == selectedTeam ? Color.blue.opacity(0.15) : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 150)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Previous Game Row
struct PreviousGameRow: View {
    let game: Game
    
    private var homeWon: Bool {
        return (game.home.score ?? 0) > (game.visitor.score ?? 0)
    }
    
    private func openGameURL() {
        if let url = URL(string: "https://www.wnba.com/game/\(game.gid)/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    var body: some View {
        Button(action: openGameURL) {
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
                    Text("at")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    // Home Team
                    Text("\(game.home.abbr) \(game.home.score ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(homeWon ? .green : .red)
                }
            }
        }
        .buttonStyle(PlainButtonStyle()) // Keep the original appearance
        .padding(.vertical, 2)
    }
}

// MARK: - Upcoming Game Row
struct UpcomingGameRow: View {
    let game: Game
    
    private func openGameURL() {
        if let url = URL(string: "https://www.wnba.com/game/\(game.gid)/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    var body: some View {
        Button(action: openGameURL) {
            HStack(alignment: .center, spacing: 0) {
                // Date/time left-aligned, gray, fixed width (match previous games)
                Text("\(game.formattedGameDate) \(game.formattedGameTime)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .frame(width: 160, alignment: .leading)

                Spacer(minLength: 2)

                // Matchup centered, bold, black, wide enough to never wrap
                HStack(spacing: 5) {
                    Text(game.visitor.abbr)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text("at")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text(game.home.abbr)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(width: 110, alignment: .center)
                .lineLimit(1)
                .truncationMode(.tail)

                Spacer(minLength: 2)

                // Broadcast icon right-aligned if present
                if let provider = game.primaryBroadcastProvider {
                    Image(systemName: provider.isLeaguePass ? "play.tv" : "tv")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))
                        .frame(width: 20, alignment: .trailing)
                } else {
                    // Reserve width for alignment
                    Color.clear.frame(width: 20)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 2)
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}