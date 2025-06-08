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
        HStack(alignment: .top, spacing: 0) {
            // Logo (fixed width)
            VStack {
                if let abbr = teamInfo?.abbreviation {
                    AsyncImage(
                        url: URL(string: "https://cdn.wnba.com/static/next/teams/favicons/\(abbr)/icon-32.png"),
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                        },
                        placeholder: {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .opacity(0.3)
                        }
                    )
                }
                Spacer()
            }
            .frame(width: 44, alignment: .top) // logo area

            // Content VStack
            VStack(alignment: .leading, spacing: 5) {
                // Title Row
                HStack(alignment: .center, spacing: 8) {
                    Text(
                        String(
                            format: "menu.title".localized,
                            teamInfo?.fullName ?? "WNBA"
                        )
                    )
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(teamColor)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .padding(.top, 5)
                    .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 8)
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
                    Text("menu.section.previous".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(teamColor)
                        .padding(.top, 5)

                    ForEach(games.pastGames, id: \.game.gid) { markedGame in
                        PreviousGameRow(game: markedGame.game)
                    }

                    Divider()
                }

                // Upcoming Games Section
                if !games.upcomingGames.isEmpty {
                    Text("menu.section.upcoming".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(teamColor)
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
                        // "All Teams" button
                        Button(action: {
                            changeTeamAction("ALL")
                        }) {
                            Text("All Teams".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(teamAbbreviation == "ALL" ? .white : Color(hex: "#FA4616"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(teamAbbreviation == "ALL" ? Color(hex: "#FA4616")! : Color(hex: "#FA4616")!.opacity(0.15))
                                .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Refresh button - positive action (blue)
                        Button(action: {
                            refreshAction()
                        }) {
                            Text("action.refresh".localized)
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
                            Text("action.quit".localized)
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
                    Text(String(format: "app.version".localized, Version.version))
                        .font(.system(size: 9))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(minWidth: 320)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .padding(.trailing, 24)
            .padding(.top, 8)
        }
    }
}
    

            

// MARK: - Team Picker View
struct TeamPickerView: View {
    let selectedTeam: String
    let onTeamSelected: (String) -> Void

    @State private var searchText: String = ""

    var filteredTeams: [TeamManager.TeamInfo] {
        let teams: [TeamManager.TeamInfo]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            teams = TeamManager.allTeams
        } else {
            teams = TeamManager.allTeams.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.abbreviation.localizedCaseInsensitiveContains(searchText)
            }
        }
        return teams
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("menu.select_team".localized)
                .font(.system(size: 13, weight: .bold))
                .padding(.bottom, 3)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredTeams, id: \.abbreviation) { team in
                        Button(action: {
                            onTeamSelected(team.abbreviation)
                        }) {
                            HStack {
                                Text(team.fullName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                if team.abbreviation == selectedTeam {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 8)
                            .background(team.abbreviation == selectedTeam ? Color.blue.opacity(0.18) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 170)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(7)
        .shadow(color: Color.black.opacity(0.13), radius: 3, x: 0, y: 1)
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
                    .frame(minWidth: 120, alignment: .leading)

                Spacer()

                HStack(spacing: 5) {
                    Text("\(game.visitor.abbr) \(game.visitor.score ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(homeWon ? .red : .green)
                    Text("vs")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("\(game.home.abbr) \(game.home.score ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(homeWon ? .green : .red)
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 100, alignment: .trailing)
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
        HStack(alignment: .center, spacing: 0) {
            // Main row (date/time + matchup): opens main WNBA game link
            Button(action: openGameURL) {
                HStack(spacing: 0) {
                    Text("\(game.formattedGameDate) \(game.formattedGameTime)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .frame(width: 160, alignment: .leading)

                    Spacer(minLength: 2)

                    HStack(spacing: 5) {
                        Text(game.visitor.abbr)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Text("vs")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        Text(game.home.abbr)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 110, alignment: .center)
                    .lineLimit(1)
                    .truncationMode(.tail)
                }
            }
            .buttonStyle(PlainButtonStyle())
            // End main row

            Spacer(minLength: 2)

            // Broadcast icon as a separate button (if available)
            if let provider = game.primaryBroadcastProvider, !provider.videoLink.isEmpty, let url = URL(string: provider.videoLink) {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }) {
                    Image(systemName: provider.isLeaguePass ? "play.tv" : "tv")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))
                        .frame(width: 20, alignment: .trailing)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Reserve width for alignment
                Color.clear.frame(width: 20)
            }
        }
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