import SwiftUI
import AppKit
import SwiftDate

// MARK: - Game Row Components

/// Container for game row components
struct GameRowComponents {
    // This struct serves as a namespace for game row components
}

// MARK: - Previous Game Row

/// Displays a completed game with final scores
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
                        .foregroundColor(homeWon ? ColorManager.lossColor : ColorManager.winColor)
                    Text("vs")
                        .font(.system(size: 13))
                        .foregroundColor(ColorManager.textSecondary)
                    Text("\(game.home.abbr) \(game.home.score ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(homeWon ? ColorManager.winColor : ColorManager.lossColor)
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 100, alignment: .trailing)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 2)
    }
}

// MARK: - In Progress Game Row

/// Displays a live game with current scores and status
struct InProgressGameRow: View {
    let game: Game
    
    private var homeWinning: Bool {
        return (game.currentHomeScore ?? 0) > (game.currentVisitorScore ?? 0)
    }
    
    private func openGameURL() {
        if let url = URL(string: "https://www.wnba.com/game/\(game.gid)/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    var body: some View {
        Button(action: openGameURL) {
            HStack(alignment: .center) {
                // Game status
                Text(game.gameStatusText?.trimmingCharacters(in: .whitespaces) ?? game.statusDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorManager.liveColor)
                    .frame(minWidth: 80, alignment: .leading)

                Spacer()

                HStack(spacing: 5) {
                    Text("\(game.visitor.abbr) \(game.currentVisitorScore ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(homeWinning ? ColorManager.lossColor : ColorManager.winColor)
                    Text("vs")
                        .font(.system(size: 13))
                        .foregroundColor(ColorManager.textSecondary)
                    Text("\(game.home.abbr) \(game.currentHomeScore ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(homeWinning ? ColorManager.winColor : ColorManager.lossColor)
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 120, alignment: .trailing)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 2)
    }
}

// MARK: - Upcoming Game Row

/// Displays a scheduled upcoming game with date, time, and broadcast info
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
                        .frame(width: 180, alignment: .leading)

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

            Spacer(minLength: 2)

            // Broadcast icon as a separate button (if available)
            if let provider = game.primaryBroadcastProvider,
               !provider.videoLink.isEmpty,
               let url = URL(string: provider.videoLink) {
                Button(
                    action: {
                        NSWorkspace.shared.open(url)
                    },
                    label: {
                        Image(systemName: provider.isLeaguePass ? "play.tv" : "tv")
                            .foregroundColor(.purple)
                            .font(.system(size: 18))
                            .frame(width: 20, alignment: .trailing)
                    }
                )
                .buttonStyle(PlainButtonStyle())
            } else {
                // Reserve width for alignment
                Color.clear.frame(width: 20)
            }
        }
        .padding(.vertical, 2)
    }
}
