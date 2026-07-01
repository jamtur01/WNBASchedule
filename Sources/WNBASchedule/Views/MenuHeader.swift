import SwiftUI
import AppKit

// MARK: - Menu Header Component

/// Header component for the main menu view
struct MenuHeader: View {
    let teamAbbreviation: String
    @Binding var showingTeamPicker: Bool
    let changeTeamAction: (String) -> Void
    
    @Environment(\.colorScheme) 
    var colorScheme
    
    private var teamInfo: TeamManager.TeamInfo? {
        return TeamManager.getTeamInfo(abbreviation: teamAbbreviation)
    }
    
    private var teamColor: Color {
        return ColorManager.adaptiveTeamColor(for: teamAbbreviation, colorScheme: colorScheme)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.xs) {
            // Team logo
            if let abbr = teamInfo?.abbreviation {
                AsyncImage(
                    url: TeamManager.faviconURL(abbreviation: abbr, size: 32),
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(teamColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(abbr.prefix(3))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                )
            }
            
            // Title with improved typography
            Text(
                String(
                    format: "menu.title".localized,
                    teamInfo?.fullName ?? "WNBA"
                )
            )
            .font(DesignSystem.Typography.title)
            .foregroundColor(teamColor)
            .lineLimit(1)
            .layoutPriority(1)
            .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: DesignSystem.Spacing.sm)
            
            // Settings button with enhanced styling
            SettingsPopoverButton(
                showingTeamPicker: $showingTeamPicker,
                selectedTeam: teamAbbreviation,
                onTeamSelected: changeTeamAction,
                colorScheme: colorScheme
            )
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}

// MARK: - All Teams Menu Header Component

/// Header component for the all teams menu view
struct AllTeamsMenuHeader: View {
    @Binding var showingTeamPicker: Bool
    let changeTeamAction: (String) -> Void
    let previouslySelectedTeam: String?
    
    @Environment(\.colorScheme) 
    var colorScheme
    
    @State private var isBackHovered = false
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            // WNBA Logo
            Image.loadFromBundle(named: "wnbalogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: DesignSystem.ComponentSize.logoMedium, height: DesignSystem.ComponentSize.logoMedium)
            
            // Title with improved typography
            Text("menu.title.all_teams".localized)
                .font(DesignSystem.Typography.title)
                .foregroundColor(ColorManager.wnbaBrandColor(colorScheme))
                .lineLimit(1)
                .layoutPriority(1)
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: DesignSystem.Spacing.sm)
            
            // Back button with enhanced styling
            if let previousTeam = previouslySelectedTeam,
               let teamInfo = TeamManager.getTeamInfo(abbreviation: previousTeam) {
                Button(
                    action: {
                        changeTeamAction(previousTeam)
                    },
                    label: {
                        HStack(spacing: DesignSystem.Spacing.xxxs) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: DesignSystem.ComponentSize.iconSmall))
                            Text(teamInfo.abbreviation)
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(isBackHovered ? .white : ColorManager.wnbaBrandColor(colorScheme))
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .fill(isBackHovered ? ColorManager.brandButtonFill : ColorManager.wnbaBrandColor(colorScheme).opacity(0.12))
                        )
                    }
                )
                .buttonStyle(PlainButtonStyle())
                .interactiveHover($isBackHovered)
                .help("help.back_to".localized(with: teamInfo.fullName))
            }
            
            // Settings button with enhanced styling
            SettingsPopoverButton(
                showingTeamPicker: $showingTeamPicker,
                selectedTeam: TeamSelection.allTeams,
                onTeamSelected: changeTeamAction,
                colorScheme: colorScheme
            )
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}

// MARK: - Settings Popover Button

/// Gear button shared by both headers that toggles the team-picker popover.
struct SettingsPopoverButton: View {
    @Binding var showingTeamPicker: Bool
    let selectedTeam: String
    let onTeamSelected: (String) -> Void
    let colorScheme: ColorScheme

    @State private var isSettingsHovered = false

    var body: some View {
        Button(
            action: {
                showingTeamPicker.toggle()
            },
            label: {
                Image(systemName: "gear")
                    .font(.system(size: DesignSystem.ComponentSize.iconSmall))
                    .foregroundColor(isSettingsHovered ? .primary : ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                    .frame(width: DesignSystem.ComponentSize.iconLarge, height: DesignSystem.ComponentSize.iconLarge)
                    .background(
                        Circle()
                            .fill(isSettingsHovered ? ColorManager.adaptiveSeparator(colorScheme: colorScheme).opacity(0.3) : Color.clear)
                    )
            }
        )
        .buttonStyle(PlainButtonStyle())
        .interactiveHover($isSettingsHovered)
        .popover(isPresented: $showingTeamPicker, arrowEdge: .top) {
            TeamPickerView(
                selectedTeam: selectedTeam,
                onTeamSelected: { newTeam in
                    onTeamSelected(newTeam)
                    showingTeamPicker = false
                }
            )
            .frame(width: 320, height: 400)
            .designSystemCard(colorScheme: colorScheme)
        }
    }
}
