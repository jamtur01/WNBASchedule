import AppKit
import Foundation
import os.log

/// Manages the status bar item and its appearance
class StatusBarManager {
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private let userPreferences: UserPreferences
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "StatusBarManager")
    
    // MARK: - Initialization
    init(userPreferences: UserPreferences = DependencyContainer.shared.userPreferences) {
        self.userPreferences = userPreferences
    }
    
    // MARK: - Public Methods
    func setupStatusItem() -> NSStatusItem? {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.title = "🏀"
            statusButton.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
            updateTooltip()
        }
        
        logger.info("Status bar item created")
        return statusItem
    }
    
    func updateTooltip() {
        if let statusButton = statusItem?.button {
            let team = TeamManager.getTeamFullName(abbreviation: userPreferences.favoriteTeam)
            statusButton.toolTip = "\(team) WNBA Schedule"
        }
    }
    
    func getStatusItem() -> NSStatusItem? {
        return statusItem
    }
}
