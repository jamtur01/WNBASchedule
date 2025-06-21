import SwiftUI
import AppKit
import SwiftDate
import LaunchAtLogin
import Combine

// MARK: - Menu View
/// Main menu view for single team schedules
/// Layout: Fixed height (800px) with Spacer to push buttons to bottom
/// Pattern: Header -> Content -> Spacer -> Actions (see BaseMenuLayout for shared approach)
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
    
    @Environment(\.colorScheme)
    var colorScheme
    
    var body: some View {
        StandardMenuLayout(
            header: {
                MenuHeader(
                    teamAbbreviation: teamAbbreviation,
                    showingTeamPicker: $showingTeamPicker,
                    changeTeamAction: changeTeamAction
                )
            },
            content: {
                VStack(alignment: .leading, spacing: 12) {
                        // Previous Games Section with animation
                        if !games.pastGames.isEmpty {
                            GameSection(
                                title: "menu.section.previous".localized,
                                titleColor: teamColor,
                                colorScheme: colorScheme
                            ) {
                                LazyVStack(alignment: .leading, spacing: 2) {
                                    ForEach(Array(games.pastGames.enumerated()), id: \.element.game.gid) { index, markedGame in
                                        PreviousGameRow(game: markedGame.game)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .trailing).combined(with: .opacity)
                                            ))
                                            .animation(
                                                DesignSystem.Animation.gentleSpring.delay(Double(index) * 0.05),
                                                value: games.pastGames.count
                                            )
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }

                        // In Progress Games Section with prominent animation
                        if !games.inProgressGames.isEmpty {
                            GameSection(
                                title: "menu.section.in_progress".localized,
                                titleColor: ColorManager.liveColor,
                                colorScheme: colorScheme
                            ) {
                                LazyVStack(alignment: .leading, spacing: 2) {
                                    ForEach(Array(games.inProgressGames.enumerated()), id: \.element.game.gid) { index, markedGame in
                                        InProgressGameRow(game: markedGame.game)
                                            .transition(.asymmetric(
                                                insertion: .scale.combined(with: .opacity),
                                                removal: .scale.combined(with: .opacity)
                                            ))
                                            .animation(
                                                DesignSystem.Animation.bouncy.delay(Double(index) * 0.1),
                                                value: games.inProgressGames.count
                                            )
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }

                        // Upcoming Games Section with anticipation animation
                        if !games.upcomingGames.isEmpty {
                            GameSection(
                                title: "menu.section.upcoming".localized,
                                titleColor: teamColor,
                                colorScheme: colorScheme
                            ) {
                                LazyVStack(alignment: .leading, spacing: 2) {
                                    ForEach(Array(games.upcomingGames.enumerated()), id: \.element.game.gid) { index, markedGame in
                                        UpcomingGameRow(game: markedGame.game)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)
                                            ))
                                            .animation(
                                                DesignSystem.Animation.gentleSpring.delay(Double(index) * 0.03),
                                                value: games.upcomingGames.count
                                            )
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                }
            },
            footer: {
                // Menu Actions (now includes Launch at Login)
                MenuActions(
                    teamAbbreviation: teamAbbreviation,
                    teamColor: teamColor,
                    refreshAction: refreshAction,
                    changeTeamAction: changeTeamAction
                )
            }
        )
    }
}

// MARK: - Game Section Component

/// Reusable section component for organized game display
struct GameSection<Content: View>: View {
    let title: String
    let titleColor: Color
    let colorScheme: ColorScheme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            Text(title)
                .designSystemSectionHeader(colorScheme: colorScheme)
                .foregroundColor(titleColor)
            
            // Section Content
            content
        }
    }
}
