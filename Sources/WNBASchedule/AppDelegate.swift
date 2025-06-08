import AppKit
import Foundation
import SwiftUI
import SwiftDate
import os.log

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var scheduleManager: ScheduleManagerProtocol
    private var timer: Timer?
    private var hostingView: NSHostingView<MenuView>?
    private var games: FilteredGames?
    private var userPreferences: UserPreferences
    
    // Constants
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    private let memoryAuditInterval: TimeInterval = 1800 // 30 minutes
    private let logger = Logger(subsystem: "com.wnbaschedule", category: "AppDelegate")
    
    // Memory audit timer
    private var memoryAuditTimer: Timer?
    
    // MARK: - Initialization
    init(scheduleManager: ScheduleManagerProtocol = DependencyContainer.shared.scheduleManager,
         userPreferences: UserPreferences = DependencyContainer.shared.userPreferences) {
        self.scheduleManager = scheduleManager
        self.userPreferences = userPreferences
        super.init()
    }
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Track this object for memory leaks
        trackForMemoryLeak(description: "AppDelegate")
        
        setupStatusItem()
        updateMenu()
        setupRefreshTimer()
        setupMemoryAuditTimer()
        
        // Log initial memory usage
        let memoryUsage = MemoryAudit.shared.currentMemoryUsage()
        logger.info("Initial memory usage: \(MemoryAudit.shared.formatMemorySize(memoryUsage))")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        invalidateTimer()
        invalidateMemoryAuditTimer()
        stopMemoryTracking()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        // Pause timers when app is in background to save resources
        invalidateTimer()
        invalidateMemoryAuditTimer()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Resume timers when app is active
        setupRefreshTimer()
        setupMemoryAuditTimer()
        updateMenu() // Refresh data
    }
    
    // MARK: - Private Methods
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            statusButton.title = "🏀"
            statusButton.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
            updateStatusButtonTooltip()
        }
    }
    
    private func updateStatusButtonTooltip() {
        if let statusButton = statusItem?.button {
            let team = TeamManager.getTeamFullName(abbreviation: userPreferences.favoriteTeam)
            statusButton.toolTip = "\(team) WNBA Schedule"
        }
    }
    
    private func setupRefreshTimer() {
        // Cancel existing timer if any
        invalidateTimer()
        
        // Create new timer
        timer = Timer.scheduledTimer(
            timeInterval: refreshInterval,
            target: self,
            selector: #selector(updateMenu),
            userInfo: nil,
            repeats: true
        )
        
        // Make sure timer fires even when scrolling
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func setupMemoryAuditTimer() {
        // Cancel existing timer if any
        invalidateMemoryAuditTimer()
        
        // Create new timer
        memoryAuditTimer = Timer.scheduledTimer(
            timeInterval: memoryAuditInterval,
            target: self,
            selector: #selector(performMemoryAudit),
            userInfo: nil,
            repeats: true
        )
        
        // Make sure timer fires even when scrolling
        RunLoop.current.add(memoryAuditTimer!, forMode: .common)
        
        // Perform an initial audit
        performMemoryAudit()
    }
    
    private func invalidateMemoryAuditTimer() {
        memoryAuditTimer?.invalidate()
        memoryAuditTimer = nil
    }
    
    @objc private func performMemoryAudit() {
        // Log current memory usage
        let memoryUsage = MemoryAudit.shared.currentMemoryUsage()
        logger.info("Current memory usage: \(MemoryAudit.shared.formatMemorySize(memoryUsage))")
        
        // Perform memory audit
        MemoryAudit.shared.performAudit()
    }
    
    @objc func updateMenu() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.fetchGamesAndUpdateMenu()
        }
    }
    
    private func fetchGamesAndUpdateMenu() async {
        do {
            // Fetch the games
            let games = try await scheduleManager.fetchGames(forTeam: userPreferences.favoriteTeam)
            
            // Update the UI on the main thread
            await MainActor.run {
                self.games = games
                self.updateMenuUI(with: games)
            }
        } catch {
            logger.error("Error updating menu: \(error.localizedDescription)")
            await MainActor.run {
                self.showErrorMenu(error: error)
            }
        }
    }
    
    private func updateMenuUI(with games: FilteredGames) {
        // Create the SwiftUI menu
        let menuView = MenuView(
            games: games,
            teamAbbreviation: userPreferences.favoriteTeam,
            refreshAction: { [weak self] in
                self?.updateMenu()
            },
            changeTeamAction: { [weak self] newTeam in
                self?.changeTeam(to: newTeam)
            }
        )
        
        // Create a hosting view for the SwiftUI view
        let hostingView = NSHostingView(rootView: menuView)
        self.hostingView = hostingView
        
        // Size the hosting view to fit its content
        hostingView.frame.size = hostingView.fittingSize
        
        // Create and set up the menu
        let menu = NSMenu()
        let customMenuItem = NSMenuItem()
        customMenuItem.view = hostingView
        menu.addItem(customMenuItem)
        self.statusItem?.menu = menu
    }
    
    private func showErrorMenu(error: Error) {
        let menu = NSMenu()
        
        // Add error message
        let errorMessage = "Error fetching WNBA schedule: \(error.localizedDescription)"
        menu.addItem(NSMenuItem(title: errorMessage, action: nil, keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Add refresh option
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(self.updateMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        // Add team selection option
        let teamItem = NSMenuItem(title: "Change Team", action: nil, keyEquivalent: "")
        let teamSubmenu = NSMenu()
        
        for team in TeamManager.allTeams {
            let item = NSMenuItem(
                title: "\(team.fullName) (\(team.abbreviation))",
                action: #selector(self.teamSelected(_:)),
                keyEquivalent: ""
            )
            item.representedObject = team.abbreviation
            item.target = self
            teamSubmenu.addItem(item)
        }
        
        teamItem.submenu = teamSubmenu
        menu.addItem(teamItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add quit option
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // Set the menu
        self.statusItem?.menu = menu
    }
    
    @objc private func teamSelected(_ sender: NSMenuItem) {
        guard let teamAbbr = sender.representedObject as? String else { return }
        changeTeam(to: teamAbbr)
    }
    
    private func changeTeam(to teamAbbreviation: String) {
        userPreferences.favoriteTeam = teamAbbreviation
        userPreferences.savePreferences()
        updateStatusButtonTooltip()
        updateMenu()
    }
}
