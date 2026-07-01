import SwiftUI
import AppKit

// MARK: - Game Row Components

// MARK: - Previous Game Row

/// Displays a completed game with final scores
struct PreviousGameRow: View {
    let game: Game
    
    @State private var isHovered = false
    @Environment(\.colorScheme)
    var colorScheme
    
    /// Whether the home team won. `nil` when either score is missing, so a completed
    /// game with absent scores stays neutral instead of being mislabelled as a win/loss.
    private var homeWon: Bool? {
        guard let home = game.home.score, let visitor = game.visitor.score else { return nil }
        return home > visitor
    }

    private func scoreColor(isHome: Bool) -> Color {
        guard let homeWon = homeWon else {
            return ColorManager.adaptiveSecondaryText(colorScheme: colorScheme)
        }
        let teamWon = isHome ? homeWon : !homeWon
        return teamWon ? ColorManager.winColor(colorScheme) : ColorManager.lossColor(colorScheme)
    }

    private func scoreWeight(isHome: Bool) -> Font.Weight {
        guard let homeWon = homeWon else { return .medium }
        let teamWon = isHome ? homeWon : !homeWon
        return teamWon ? .bold : .medium
    }

    private func openGameURL() {
        LinkOpener.open(game.gameURL)
    }
    
    var body: some View {
        Button(action: openGameURL) {
            HStack(alignment: .center, spacing: 2) {
                // Enhanced date display with status indicator
                VStack(alignment: .leading, spacing: 1) {
                    Text(game.formattedGameDate)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                        .fontWeight(.medium)
                    
                    // Game status chip
                    Text("game.status.final_short".localized)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                        )
                }
                .frame(minWidth: 80, alignment: .leading)
                .lineLimit(1)

                Spacer(minLength: 1)

                // Enhanced score display with winner emphasis
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    // Visitor team with visual hierarchy
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(game.visitor.abbr)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                        
                        Text(game.visitor.score.map(String.init) ?? "–")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(scoreColor(isHome: false))
                            .fontWeight(scoreWeight(isHome: false))
                    }
                    
                    // VS indicator with subtle styling
                    Text("–")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(ColorManager.adaptiveLightText(colorScheme: colorScheme))
                        .padding(.horizontal, DesignSystem.Spacing.xxxs)
                    
                    // Home team with visual hierarchy
                    VStack(alignment: .leading, spacing: 1) {
                        Text(game.home.abbr)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                        
                        Text(game.home.score.map(String.init) ?? "–")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(scoreColor(isHome: true))
                            .fontWeight(scoreWeight(isHome: true))
                    }
                }
                .frame(minWidth: 100, alignment: .center)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(isHovered ? ColorManager.adaptiveSeparator(colorScheme: colorScheme).opacity(0.2) : Color.clear)
                    .animation(DesignSystem.Animation.quick, value: isHovered)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .interactiveHover($isHovered)
        .contextMenu {
            ContextMenuSupport.gameRowContextMenu(
                game: game,
                onOpenGame: openGameURL
            )
        }
        .accessibilityButton(
            label: "accessibility.previous_game".localized(with: game.visitor.abbr, game.visitor.score ?? 0, game.home.abbr, game.home.score ?? 0, game.formattedGameDate),
            hint: "accessibility.previous_game_hint".localized
        )
        .smoothAppearance(true)
    }
}

// MARK: - In Progress Game Row

/// Displays a live game with current scores and status
struct InProgressGameRow: View {
    let game: Game
    
    @State private var isHovered = false
    @Environment(\.colorScheme)
    var colorScheme
    
    private var homeWinning: Bool {
        return (game.currentHomeScore ?? 0) > (game.currentVisitorScore ?? 0)
    }

    private func openGameURL() {
        LinkOpener.open(game.gameURL)
    }
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: openGameURL) {
            HStack(alignment: .center, spacing: 2) {
                // Enhanced live status with pulsing animation
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Circle()
                            .fill(ColorManager.liveColor(colorScheme))
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0.6 : 1.0)
                            .animation(DesignSystem.Animation.loading, value: pulseAnimation)
                        
                        Text("game.status.live".localized)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(ColorManager.liveColor(colorScheme))
                    }
                    
                    Text(game.gameStatusText?.trimmingCharacters(in: .whitespaces) ?? game.statusDescription)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                }
                .frame(minWidth: 80, alignment: .leading)

                Spacer(minLength: 1)

                // Enhanced live scores with dynamic updates
                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    // Visitor team with live emphasis
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(game.visitor.abbr)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                        
                        Text("\(game.currentVisitorScore ?? 0)")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(homeWinning ? ColorManager.lossColor(colorScheme) : ColorManager.winColor(colorScheme))
                            .fontWeight(homeWinning ? .medium : .bold)
                            .contentTransition(.numericText())
                    }
                    
                    // Live indicator
                    VStack(spacing: DesignSystem.Spacing.xxxs) {
                        Text("–")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(ColorManager.liveColor(colorScheme))
                        
                        Circle()
                            .fill(ColorManager.liveColor(colorScheme))
                            .frame(width: 4, height: 4)
                            .opacity(pulseAnimation ? 0.3 : 1.0)
                    }
                    
                    // Home team with live emphasis
                    VStack(alignment: .leading, spacing: 1) {
                        Text(game.home.abbr)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                        
                        Text("\(game.currentHomeScore ?? 0)")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(homeWinning ? ColorManager.winColor(colorScheme) : ColorManager.lossColor(colorScheme))
                            .fontWeight(homeWinning ? .bold : .medium)
                            .contentTransition(.numericText())
                    }
                }
                .frame(minWidth: 120, alignment: .center)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: [
                                isHovered ? ColorManager.liveColor(colorScheme).opacity(0.15) : ColorManager.liveColor(colorScheme).opacity(0.05),
                                isHovered ? ColorManager.liveColor(colorScheme).opacity(0.1) : Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .animation(DesignSystem.Animation.quick, value: isHovered)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(ColorManager.liveColor(colorScheme).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .interactiveHover($isHovered)
        .contextMenu {
            ContextMenuSupport.gameRowContextMenu(
                game: game,
                onOpenGame: openGameURL
            )
        }
        .accessibilityButton(
            label: "accessibility.live_game".localized(with: game.visitor.abbr, game.currentVisitorScore ?? 0, game.home.abbr, game.currentHomeScore ?? 0),
            hint: "accessibility.live_game_hint".localized
        )
        .onAppear {
            pulseAnimation = true
        }
        .smoothAppearance(true)
    }
}

// MARK: - Upcoming Game Row

/// Displays a scheduled upcoming game with date, time, and broadcast info
struct UpcomingGameRow: View {
    let game: Game
    
    @State private var isMainHovered = false
    @State private var isBroadcastHovered = false
    @Environment(\.colorScheme)
    var colorScheme
    
    private var timeUntilGame: String {
        let now = Date()
        let gameDate = game.localGameTime
        let timeInterval = gameDate.timeIntervalSince(now)
        
        guard timeInterval > 0 else { return "" }
        
        if timeInterval > 86400 { // More than 1 day
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        } else if timeInterval > 3600 { // More than 1 hour
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        }
    }

    private func openGameURL() {
        LinkOpener.open(game.gameURL)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            // Main game information with enhanced hierarchy
            Button(action: openGameURL) {
                HStack(spacing: 2) {
                    // Enhanced date/time display with countdown
                    VStack(alignment: .leading, spacing: 1) {
                        Text(game.formattedGameDate)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                            .fontWeight(.medium)
                        
                        HStack(spacing: 1) {
                            Text(game.formattedGameTime)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                            
                            if !timeUntilGame.isEmpty {
                                Text("(\(timeUntilGame))")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(ColorManager.adaptiveLightText(colorScheme: colorScheme))
                            }
                        }
                    }
                    .frame(minWidth: 90, alignment: .leading)

                    Spacer(minLength: 1)

                    // Enhanced team matchup with better visual hierarchy
                    HStack(spacing: 1) {
                        // Visitor team
                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                            Text(game.visitor.abbr)
                                .font(DesignSystem.Typography.bodyEmphasis)
                                .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                        }
                        
                        // Enhanced VS with subtle animation
                        Text("@")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorManager.adaptiveLightText(colorScheme: colorScheme))
                            .scaleEffect(isMainHovered ? 1.1 : 1.0)
                            .animation(DesignSystem.Animation.quick, value: isMainHovered)
                        
                        // Home team
                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                            Text(game.home.abbr)
                                .font(DesignSystem.Typography.bodyEmphasis)
                                .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                        }
                    }
                    .frame(minWidth: 80, alignment: .center)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(isMainHovered ? ColorManager.adaptiveSeparator(colorScheme: colorScheme).opacity(0.2) : Color.clear)
                        .animation(DesignSystem.Animation.quick, value: isMainHovered)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .interactiveHover($isMainHovered)

            // Enhanced broadcast button with better feedback
            if let provider = game.primaryBroadcastProvider,
               let broadcastURL = game.broadcastURL {
                Button(
                    action: {
                        LinkOpener.open(broadcastURL)
                    },
                    label: {
                        let broadcastColor = ColorManager.broadcastColor(colorScheme)
                        let broadcastFill = ColorManager.broadcastFill
                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                            Image(systemName: provider.isLeaguePass ? "play.tv.fill" : "tv.fill")
                                .font(.system(size: DesignSystem.ComponentSize.iconMedium))
                                .foregroundColor(isBroadcastHovered ? .white : broadcastColor)
                                .scaleEffect(isBroadcastHovered ? 1.1 : 1.0)
                            
                            Text(provider.isLeaguePass ? "broadcast.lp_short".localized : "broadcast.tv".localized)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(isBroadcastHovered ? .white : broadcastColor)
                        }
                        .frame(width: DesignSystem.ComponentSize.iconXLarge, height: DesignSystem.ComponentSize.iconXLarge)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                .fill(isBroadcastHovered ? broadcastFill : broadcastColor.opacity(0.12))
                        )
                    }
                )
                .buttonStyle(PlainButtonStyle())
                .interactiveHoverBouncy($isBroadcastHovered)
                .accessibilityButton(
                    label: "accessibility.watch_on".localized(with: provider.isLeaguePass ? "broadcast.league_pass".localized : "broadcast.tv".localized),
                    hint: "accessibility.watch_on_hint".localized
                )
            }
        }
        .contextMenu {
            ContextMenuSupport.gameRowContextMenu(
                game: game,
                onOpenGame: openGameURL,
                onOpenBroadcast: game.broadcastURL != nil ? { LinkOpener.open(game.broadcastURL) } : nil
            )
        }
        .accessibilityButton(
            label: "accessibility.upcoming_game".localized(with: game.visitor.abbr, game.home.abbr, game.formattedGameDate, game.formattedGameTime),
            hint: "accessibility.upcoming_game_hint".localized
        )
        .smoothAppearance(true)
        .padding(.vertical, 3)
    }
}
