import SwiftUI

// MARK: - Team Picker Component

/// A view for selecting a team from a filterable list
struct TeamPickerView: View {
    let selectedTeam: String
    let onTeamSelected: (String) -> Void

    @State private var searchText: String = ""
    @Environment(\.colorScheme) 
    var colorScheme

    var filteredTeams: [TeamManager.TeamInfo] {
        let teams: [TeamManager.TeamInfo]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            teams = TeamManager.allTeams
        } else {
            teams = TeamManager.allTeams.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.abbreviation.localizedCaseInsensitiveContains(searchText)
            }
        }
        return teams
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("menu.select_team".localized)
                .font(.system(size: 13, weight: .bold))
                .padding(.bottom, 3)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredTeams, id: \.abbreviation) { team in
                        Button(
                            action: {
                                onTeamSelected(team.abbreviation)
                            },
                            label: {
                                HStack {
                                    Text(team.fullName)
                                        .font(.system(size: 13))
                                        .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                                    Spacer()
                                    if team.abbreviation == selectedTeam {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 7)
                                .padding(.horizontal, 8)
                                .background(team.abbreviation == selectedTeam ? Color.blue.opacity(0.18) : Color.clear)
                                .cornerRadius(6)
                            }
                        )
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 170)
        }
        .padding(10)
        .background(ColorManager.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(7)
        .shadow(color: Color.black.opacity(0.13), radius: 3, x: 0, y: 1)
    }
}
