import AppKit
import SwiftUI
import Foundation
import os.log

/// Manages menu UI creation and updates
class MenuManager {
    // MARK: - Properties
    private var hostingView: NSHostingView<AnyView>?
    private let userPreferences: UserPreferences
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "MenuManager")
    
    // MARK: - Initialization
    init(userPreferences: UserPreferences = DependencyContainer.shared.userPreferences) {
        self.userPreferences = userPreferences
    }
    
    // MARK: - Public Methods
    func updateMenuUI(
        with games: FilteredGames,
        statusItem: NSStatusItem?,
        refreshAction: @escaping () -> Void,
        changeTeamAction: @escaping (String) -> Void
    ) {
        let menuView = MenuView(
            games: games,
            teamAbbreviation: userPreferences.favoriteTeam,
            refreshAction: refreshAction,
            changeTeamAction: changeTeamAction
        )
        
        setMenuContent(AnyView(menuView), statusItem: statusItem)
        logger.info("Updated menu UI for team: \(self.userPreferences.favoriteTeam)")
    }
    
    func updateMenuUIForAllTeams(
        upcomingGames: [Game],
        inProgressGames: [Game],
        statusItem: NSStatusItem?,
        refreshAction: @escaping () -> Void,
        changeTeamAction: @escaping (String) -> Void
    ) {
        let menuView = AllTeamsMenuView(
            upcomingGames: upcomingGames,
            inProgressGames: inProgressGames,
            refreshAction: refreshAction,
            changeTeamAction: changeTeamAction,
            previouslySelectedTeam: userPreferences.previouslySelectedTeam
        )
        
        setMenuContent(AnyView(menuView), statusItem: statusItem)
        logger.info("Updated menu UI for all teams")
    }
    
    func showErrorMenu(
        error: Error,
        statusItem: NSStatusItem?,
        target: AnyObject,
        updateMenuSelector: Selector,
        teamSelectedSelector: Selector
    ) {
        let menu = NSMenu()
        
        // Add error message
        let errorMessage = "Error fetching WNBA schedule: \(error.localizedDescription)"
        menu.addItem(NSMenuItem(title: errorMessage, action: nil, keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Add refresh option
        let refreshItem = NSMenuItem(title: "Refresh", action: updateMenuSelector, keyEquivalent: "r")
        refreshItem.target = target
        menu.addItem(refreshItem)
        
        // Add team selection option
        let teamItem = NSMenuItem(title: "Change Team", action: nil, keyEquivalent: "")
        let teamSubmenu = NSMenu()
        
        for team in TeamManager.allTeams {
            let item = NSMenuItem(
                title: "\(team.fullName) (\(team.abbreviation))",
                action: teamSelectedSelector,
                keyEquivalent: ""
            )
            item.representedObject = team.abbreviation
            item.target = target
            teamSubmenu.addItem(item)
        }
        
        teamItem.submenu = teamSubmenu
        menu.addItem(teamItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add quit option
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // Set the menu
        statusItem?.menu = menu
        logger.error("Displayed error menu: \(error.localizedDescription)")
    }
    
    func setupMenuDelegate(statusItem: NSStatusItem?, delegate: NSMenuDelegate) {
        let menu = NSMenu()
        menu.delegate = delegate
        statusItem?.menu = menu
    }
    
    // MARK: - Private Methods
    private func setMenuContent(_ content: AnyView, statusItem: NSStatusItem?) {
        let hostingView = NSHostingView(rootView: content)
        self.hostingView = hostingView
        
        // Let SwiftUI handle the sizing instead of using fittingSize
        // This prevents truncation of content when there are many games
        
        if let menu = statusItem?.menu {
            menu.removeAllItems()
            let customMenuItem = NSMenuItem()
            customMenuItem.view = hostingView
            menu.addItem(customMenuItem)
        }
    }
}
