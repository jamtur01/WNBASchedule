import SwiftUI
import LaunchAtLogin

extension Image {
    static func loadFromBundle(named name: String) -> Image {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        
        // Fallback to system image
        return Image(systemName: "sportscourt")
    }
}

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
        VStack(alignment: .leading, spacing: 5) {
            // All Teams Menu Header
            AllTeamsMenuHeader(
                showingTeamPicker: $showingTeamPicker,
                changeTeamAction: changeTeamAction,
                previouslySelectedTeam: previouslySelectedTeam
            )

            Divider()

            // In Progress Games Section
            if !inProgressGames.isEmpty {
                Text("menu.section.in_progress".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ColorManager.liveColor)
                    .padding(.top, 5)

                ForEach(inProgressGames, id: \.gid) { game in
                    InProgressGameRow(game: game)
                }

                Divider()
            }

            // Upcoming Games Section
            if !upcomingGames.isEmpty {
                Text("menu.section.upcoming".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ColorManager.wnbaBrandColor)
                    .padding(.top, 5)

                ForEach(upcomingGames, id: \.gid) { game in
                    UpcomingGameRow(game: game)
                }

                Divider()
            } else if inProgressGames.isEmpty {
                Text("No hay partidos programados en este rango.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }

            // Launch at Login toggle
            LaunchAtLogin.Toggle()
                .padding(.vertical, 4)

            // All Teams Menu Actions
            AllTeamsMenuActions(refreshAction: refreshAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
