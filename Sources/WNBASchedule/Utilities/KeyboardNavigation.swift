import SwiftUI
import AppKit

// MARK: - Context Menu Support

struct ContextMenuSupport {
    
    /// Create context menu for game rows
    /// - Parameters:
    ///   - game: The game to create menu for
    ///   - onOpenGame: Action to open game details
    ///   - onOpenBroadcast: Action to open broadcast link
    /// - Returns: Context menu view
    static func gameRowContextMenu(
        game: Game,
        onOpenGame: @escaping () -> Void,
        onOpenBroadcast: (() -> Void)? = nil
    ) -> some View {
        Group {
            Button("context.open_game".localized) {
                onOpenGame()
            }
            .keyboardShortcut(.return, modifiers: [])
            
            if let onOpenBroadcast = onOpenBroadcast {
                Button("context.watch_game".localized) {
                    onOpenBroadcast()
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            Divider()
            
            Button("context.copy_game".localized) {
                copyGameInfo(game)
            }
            .keyboardShortcut("c", modifiers: .command)
        }
    }
    
    /// Create context menu for team selection
    /// - Parameters:
    ///   - teams: Available teams
    ///   - currentTeam: Currently selected team
    ///   - onTeamSelected: Action when team is selected
    /// - Returns: Context menu view
    static func teamContextMenu(
        teams: [TeamManager.TeamInfo],
        currentTeam: String,
        onTeamSelected: @escaping (String) -> Void
    ) -> some View {
        Group {
            ForEach(teams.prefix(5), id: \.abbreviation) { team in
                Button(team.fullName) {
                    onTeamSelected(team.abbreviation)
                }
                .disabled(team.abbreviation == currentTeam)
            }
            
            if teams.count > 5 {
                Divider()
                Button("context.show_all_teams".localized) {
                    onTeamSelected(TeamSelection.allTeams)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private static func copyGameInfo(_ game: Game) {
        let gameInfo = "\\(game.visitor.abbr) vs \\(game.home.abbr) - \\(game.formattedGameDate) \\(game.formattedGameTime)"
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(gameInfo, forType: .string)
    }
}

// MARK: - Accessibility Enhancements

extension View {
    /// Add comprehensive accessibility support
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Accessibility hint
    ///   - value: Accessibility value
    ///   - traits: Accessibility traits
    /// - Returns: View with accessibility support
    func accessibilityEnhanced(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Add accessibility support for buttons
    /// - Parameters:
    ///   - label: Button label
    ///   - hint: What the button does
    ///   - isEnabled: Whether button is enabled
    /// - Returns: View with button accessibility
    func accessibilityButton(
        label: String,
        hint: String,
        isEnabled: Bool = true
    ) -> some View {
        self.accessibilityEnhanced(
            label: label,
            hint: hint,
            traits: [.isButton]
        )
    }
}
