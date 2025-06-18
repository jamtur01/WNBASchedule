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
                    selectedTeam: teamAbbreviation,
                    onTeamSelected: { newTeam in
                        changeTeamAction(newTeam)
                        showingTeamPicker = false
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingTeamPicker)
            }
        }
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
                    .foregroundColor(ColorManager.wnbaBrandColor)
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
                            .foregroundColor(ColorManager.wnbaBrandColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(ColorManager.wnbaBrandColor.opacity(0.1))
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
        }
    }
}
