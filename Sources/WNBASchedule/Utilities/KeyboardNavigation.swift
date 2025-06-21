import SwiftUI
import AppKit

/// Enhanced keyboard navigation and shortcuts for the menu bar app
struct KeyboardNavigation {
    
    // MARK: - Keyboard Shortcuts
    
    enum Shortcut: CaseIterable {
        case refresh
        case showAllTeams
        case nextTeam
        case previousTeam
        case quit
        case toggleTeamPicker
        
        var keyEquivalent: KeyEquivalent {
            switch self {
            case .refresh:
                return KeyEquivalent("r")
            case .showAllTeams:
                return KeyEquivalent("a")
            case .nextTeam:
                return KeyEquivalent("]")
            case .previousTeam:
                return KeyEquivalent("[")
            case .quit:
                return KeyEquivalent("q")
            case .toggleTeamPicker:
                return KeyEquivalent("t")
            }
        }
        
        var modifiers: EventModifiers {
            switch self {
            case .refresh, .showAllTeams, .toggleTeamPicker:
                return .command
            case .nextTeam, .previousTeam:
                return [.command, .shift]
            case .quit:
                return .command
            }
        }
        
        var description: String {
            switch self {
            case .refresh:
                return "Refresh schedule data"
            case .showAllTeams:
                return "Show all teams schedule"
            case .nextTeam:
                return "Switch to next team"
            case .previousTeam:
                return "Switch to previous team"
            case .quit:
                return "Quit application"
            case .toggleTeamPicker:
                return "Toggle team picker"
            }
        }
    }
}

// MARK: - Keyboard Shortcut Modifier

extension View {
    /// Add keyboard shortcut with consistent styling
    /// - Parameters:
    ///   - shortcut: The keyboard shortcut to add
    ///   - action: Action to perform when shortcut is triggered
    /// - Returns: View with keyboard shortcut
    func keyboardShortcut(_ shortcut: KeyboardNavigation.Shortcut, action: @escaping () -> Void) -> some View {
        self.keyboardShortcut(shortcut.keyEquivalent, modifiers: shortcut.modifiers)
    }
    
    /// Add help text for keyboard shortcuts
    /// - Parameter shortcut: The keyboard shortcut to describe
    /// - Returns: View with help text
    func shortcutHelp(_ shortcut: KeyboardNavigation.Shortcut) -> some View {
        self.help(shortcut.description)
    }
}

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
            Button("Open Game Details") {
                onOpenGame()
            }
            .keyboardShortcut(.return, modifiers: [])
            
            if let onOpenBroadcast = onOpenBroadcast {
                Button("Watch Game") {
                    onOpenBroadcast()
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            Divider()
            
            Button("Copy Game Info") {
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
                Button("Show All Teams...") {
                    onTeamSelected("ALL")
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

// MARK: - Focus Management

struct FocusSupport {
    
    enum FocusField: Hashable {
        case teamPicker
        case searchField
        case gameList
        case actionButtons
    }
    
    /// Apply focus ring styling consistent with macOS
    /// - Parameter isFocused: Whether the element is focused
    /// - Returns: View with focus styling
    static func focusRing<Content: View>(_ content: Content, isFocused: Bool) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(
                        isFocused ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
                    .animation(DesignSystem.Animation.quick, value: isFocused)
            )
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
