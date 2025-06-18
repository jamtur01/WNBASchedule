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
        return ColorManager.teamColor(for: teamAbbreviation)
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
                // Menu Header
                MenuHeader(
                    teamAbbreviation: teamAbbreviation,
                    showingTeamPicker: $showingTeamPicker,
                    changeTeamAction: changeTeamAction
                )

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

                // In Progress Games Section
                if !games.inProgressGames.isEmpty {
                    Text("menu.section.in_progress".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ColorManager.liveColor)
                        .padding(.top, 5)

                    ForEach(games.inProgressGames, id: \.game.gid) { markedGame in
                        InProgressGameRow(game: markedGame.game)
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

                // Menu Actions
                MenuActions(
                    teamAbbreviation: teamAbbreviation,
                    teamColor: teamColor,
                    refreshAction: refreshAction,
                    changeTeamAction: changeTeamAction
                )
            }
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

