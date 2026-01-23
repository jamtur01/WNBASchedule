import SwiftUI

// MARK: - Team Picker Component

/// A view for selecting a team from a filterable list
/// Follows macOS HIG guidelines for combo box/searchable dropdown patterns
struct TeamPickerView: View {
    let selectedTeam: String
    let onTeamSelected: (String) -> Void

    @State private var searchText: String = ""
    @Environment(\.colorScheme) 
    var colorScheme
    @FocusState private var isSearchFocused: Bool

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
    
    private var listHeight: CGFloat {
        let itemHeight: CGFloat = 32 // Height per team item
        let maxItems = 8
        let itemCount = min(filteredTeams.count, maxItems)
        return CGFloat(itemCount) * itemHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title
            HStack {
                Text("menu.select_team".localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                Spacer()
                Text("\(filteredTeams.count) teams")
                    .font(.system(size: 11))
                    .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Search field - follows macOS combo box pattern
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                
                TextField("Search teams...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isSearchFocused)
                    .onSubmit {
                        // If there's exactly one filtered result, select it
                        if filteredTeams.count == 1 {
                            onTeamSelected(filteredTeams[0].abbreviation)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearchFocused = true
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                    })
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(colorScheme == .dark ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSearchFocused ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            
            // Divider
            Divider()
                .padding(.horizontal, 12)
            
            // Team list - adaptive height based on content
            if filteredTeams.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                    Text("No teams found")
                        .font(.system(size: 13))
                        .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                    Text("Try a different search term")
                        .font(.system(size: 11))
                        .foregroundColor(ColorManager.adaptiveLightText(colorScheme: colorScheme))
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredTeams, id: \.abbreviation) { team in
                            TeamRowButton(
                                team: team,
                                isSelected: team.abbreviation == selectedTeam,
                                colorScheme: colorScheme,
                                onSelect: {
                                    onTeamSelected(team.abbreviation)
                                }
                            )
                        }
                    }
                }
                .frame(height: min(listHeight, 240)) // Max height of 240pts
            }
            
            // Footer with quick actions
            Divider()
                .padding(.horizontal, 12)
            
            HStack(spacing: 8) {
                Button("All Teams") {
                    onTeamSelected(TeamSelection.allTeams)
                }
                .font(.system(size: 11))
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(TeamSelection.isAllTeams(selectedTeam) ? Color.accentColor : ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                
                Spacer()
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                        isSearchFocused = true
                    }
                    .font(.system(size: 11))
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(ColorManager.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorScheme == .dark ? Color(NSColor.separatorColor) : Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 4) // Add horizontal margins to prevent edge clipping
        .onAppear {
            // Auto-focus search field when picker appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }
}

// MARK: - Team Row Button Component

/// Individual team row button following macOS list selection patterns
private struct TeamRowButton: View {
    let team: TeamManager.TeamInfo
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Team logo area
                AsyncImage(
                    url: URL(string: "https://cdn.wnba.com/static/next/teams/favicons/\(team.abbreviation)/icon-16.png"),
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ColorManager.teamColor(for: team.abbreviation, colorScheme: colorScheme))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text(team.abbreviation.prefix(2))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                )
                
                // Team info
                VStack(alignment: .leading, spacing: 1) {
                    Text(team.fullName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(ColorManager.adaptivePrimaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    Text(team.abbreviation)
                        .font(.system(size: 11))
                        .foregroundColor(ColorManager.adaptiveSecondaryText(colorScheme: colorScheme))
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        Color.accentColor.opacity(0.15)
                    } else if isHovered {
                        ColorManager.adaptiveSeparator(colorScheme: colorScheme).opacity(0.5)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
