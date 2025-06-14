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
            // Title Row
            HStack(alignment: .center, spacing: 8) {
                Image.loadFromBundle(named: "wnbalogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                Text("menu.title.all_teams".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#FA4616") ?? .orange)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .padding(.top, 5)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 8)
                
                // Back button (only shown if there's a previously selected team)
                if let previousTeam = previouslySelectedTeam,
                   let teamInfo = TeamManager.getTeamInfo(abbreviation: previousTeam) {
                    Button(
                        action: {
                            changeTeamAction(previousTeam)
                        },
                        label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 10))
                                Text(teamInfo.abbreviation)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                    .help("Back to \(teamInfo.fullName)")
                }
                
                Button(
                    action: {
                        showingTeamPicker.toggle()
                    },
                    label: {
                        Image(systemName: "gear")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                )
                .buttonStyle(PlainButtonStyle())
            }

            // Team picker (shown when settings button is clicked)
            if showingTeamPicker {
                TeamPickerView(
                    selectedTeam: "ALL",
                    onTeamSelected: { newTeam in
                        changeTeamAction(newTeam)
                        showingTeamPicker = false
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingTeamPicker)
            }

            Divider()

            // In Progress Games Section
            if !inProgressGames.isEmpty {
                Text("menu.section.in_progress".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
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
                    .foregroundColor(Color(hex: "#FA4616") ?? .orange)
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

            Divider()

            // Menu Actions
            HStack {
                HStack(spacing: 8) {
                    Button(
                        action: {
                            refreshAction()
                        },
                        label: {
                            Text("action.refresh".localized)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#FA4616") ?? .orange)
                                .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                    Button(
                        action: {
                            NSApplication.shared.terminate(nil)
                        },
                        label: {
                            Text("action.quit".localized)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                Text(String(format: "app.version".localized, Version.version))
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .frame(minWidth: 320)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
