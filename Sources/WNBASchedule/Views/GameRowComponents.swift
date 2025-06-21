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
    
    @State private var isHovered = false
    @Environment(\.colorScheme)
    var colorScheme
    
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
            HStack(alignment: .center, spacing: 2) {
                // Enhanced date display with status indicator
                VStack(alignment: .leading, spacing: 1) {
                    Text(game.formattedGameDate)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                        .fontWeight(.medium)
                    
                    // Game status chip
                    Text("FINAL")
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
                        
                        Text("\(game.visitor.score ?? 0)")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(homeWon ? ColorManager.lossColor : ColorManager.winColor)
                            .fontWeight(homeWon ? .medium : .bold)
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
                        
                        Text("\(game.home.score ?? 0)")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(homeWon ? ColorManager.winColor : ColorManager.lossColor)
                            .fontWeight(homeWon ? .bold : .medium)
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
            label: "\(game.visitor.abbr) \(game.visitor.score ?? 0) vs \(game.home.abbr) \(game.home.score ?? 0), \(game.formattedGameDate)",
            hint: "Open game details"
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
        if let url = URL(string: "https://www.wnba.com/game/\(game.gid)/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: openGameURL) {
            HStack(alignment: .center, spacing: 2) {
                // Enhanced live status with pulsing animation
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Circle()
                            .fill(ColorManager.liveColor)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0.6 : 1.0)
                            .animation(DesignSystem.Animation.loading, value: pulseAnimation)
                        
                        Text("LIVE")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(ColorManager.liveColor)
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
                            .foregroundColor(homeWinning ? ColorManager.lossColor : ColorManager.winColor)
                            .fontWeight(homeWinning ? .medium : .bold)
                            .contentTransition(.numericText())
                    }
                    
                    // Live indicator
                    VStack(spacing: DesignSystem.Spacing.xxxs) {
                        Text("–")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(ColorManager.liveColor)
                        
                        Circle()
                            .fill(ColorManager.liveColor)
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
                            .foregroundColor(homeWinning ? ColorManager.winColor : ColorManager.lossColor)
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
                                isHovered ? ColorManager.liveColor.opacity(0.15) : ColorManager.liveColor.opacity(0.05),
                                isHovered ? ColorManager.liveColor.opacity(0.1) : Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .animation(DesignSystem.Animation.quick, value: isHovered)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(ColorManager.liveColor.opacity(0.3), lineWidth: 1)
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
            label: "Live game: \(game.visitor.abbr) \(game.currentVisitorScore ?? 0) vs \(game.home.abbr) \(game.currentHomeScore ?? 0)",
            hint: "Open live game details"
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
    
    private func openGameURL() {
        if let url = URL(string: "https://www.wnba.com/game/\(game.gid)/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private var timeUntilGame: String {
        let now = Date()
        
        let gameDate = game.localGameTime
        if gameDate.timeIntervalSince(now) > 0 {
            let timeInterval = gameDate.timeIntervalSince(now)
            if timeInterval > 86400 { // More than 1 day
                let days = Int(timeInterval / 86400)
                return "\(days)d"
            } else if timeInterval > 3600 { // More than 1 hour
                let hours = Int(timeInterval / 3600)
                return "\(hours)h"
            } else if timeInterval > 0 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes)m"
            }
        }
        return ""
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
               !provider.videoLink.isEmpty,
               let url = URL(string: provider.videoLink) {
                Button(
                    action: {
                        NSWorkspace.shared.open(url)
                    },
                    label: {
                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                            Image(systemName: provider.isLeaguePass ? "play.tv.fill" : "tv.fill")
                                .font(.system(size: DesignSystem.ComponentSize.iconMedium))
                                .foregroundColor(isBroadcastHovered ? .white : .purple)
                                .scaleEffect(isBroadcastHovered ? 1.1 : 1.0)
                            
                            Text(provider.isLeaguePass ? "LP" : "TV")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(isBroadcastHovered ? .white : .purple)
                        }
                        .frame(width: DesignSystem.ComponentSize.iconXLarge, height: DesignSystem.ComponentSize.iconXLarge)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                                .fill(isBroadcastHovered ? Color.purple : Color.purple.opacity(0.1))
                        )
                    }
                )
                .buttonStyle(PlainButtonStyle())
                .interactiveHoverBouncy($isBroadcastHovered)
                .accessibilityButton(
                    label: "Watch on \(provider.isLeaguePass ? "League Pass" : "TV")",
                    hint: "Open broadcast link"
                )
            }
        }
        .contextMenu {
            ContextMenuSupport.gameRowContextMenu(
                game: game,
                onOpenGame: openGameURL,
                onOpenBroadcast: game.primaryBroadcastProvider != nil ? {
                    if let provider = game.primaryBroadcastProvider,
                       let url = URL(string: provider.videoLink) {
                        NSWorkspace.shared.open(url)
                    }
                } : nil
            )
        }
        .accessibilityButton(
            label: "Upcoming: \(game.visitor.abbr) at \(game.home.abbr), \(game.formattedGameDate) \(game.formattedGameTime)",
            hint: "Open game details"
        )
        .smoothAppearance(true)
        .padding(.vertical, 3)
    }
}
