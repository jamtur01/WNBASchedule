import SwiftUI

import os.log

extension Image {
    static func loadFromBundle(named name: String) -> Image {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        
        // Log missing asset for translators/designers
        let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "Assets")
        logger.warning("Missing bundle asset: \(name).png - falling back to system image")
        
        // Fallback to system image
        return Image(systemName: "sportscourt")
    }
}

/// All teams menu view showing games across all WNBA teams
/// Layout: Fixed height (800px) with Spacer to push buttons to bottom  
/// Pattern: Header -> Content -> Spacer -> Actions (see StandardMenuLayout for shared approach)
struct AllTeamsMenuView: View {
    let upcomingGames: [Game]
    let inProgressGames: [Game]
    let refreshAction: () -> Void
    let changeTeamAction: (String) -> Void
    let previouslySelectedTeam: String?

    @State private var showingTeamPicker = false

    private var daysRange: Int {
        DependencyContainer.shared.userPreferences.allTeamsDaysToShow
    }

    var body: some View {
        StandardMenuLayout(
            header: {
                AllTeamsMenuHeader(
                    showingTeamPicker: $showingTeamPicker,
                    changeTeamAction: changeTeamAction,
                    previouslySelectedTeam: previouslySelectedTeam
                )
            },
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    // In Progress Games Section
            if !inProgressGames.isEmpty {
                Text("menu.section.in_progress".localized)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorManager.liveColor)
                    .padding(.top, 2)

                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(inProgressGames, id: \.gid) { game in
                        InProgressGameRow(game: game)
                    }
                }

                Divider()
            }

            // Upcoming Games Section
            if !upcomingGames.isEmpty {
                Text("menu.section.upcoming".localized)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorManager.wnbaBrandColor)
                    .padding(.top, 2)

                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(upcomingGames, id: \.gid) { game in
                        UpcomingGameRow(game: game)
                    }
                }

                Divider()
            } else if inProgressGames.isEmpty {
                Text("menu.no_games_scheduled".localized)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
                }
            },
            footer: {
                // All Teams Menu Actions (now includes Launch at Login)
                AllTeamsMenuActions(refreshAction: refreshAction)
            }
        )
    }
}
