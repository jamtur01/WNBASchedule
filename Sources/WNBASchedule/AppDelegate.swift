import AppKit
import Foundation
import SwiftUI
import SwiftDate
import os.log

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, @unchecked Sendable {
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var scheduleManager: ScheduleManagerProtocol
    private var timer: Timer?
    private var hostingView: NSHostingView<AnyView>?
    private var games: FilteredGames?
    private var userPreferences: UserPreferences
    private var apiCache: APICacheProtocol
    
    // Constants
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    private let memoryAuditInterval: TimeInterval = 1800 // 30 minutes
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "AppDelegate")
    
    // Memory audit timer
    private var memoryAuditTimer: Timer?
    
    // MARK: - Initialization
    init(
        scheduleManager: ScheduleManagerProtocol = DependencyContainer.shared.scheduleManager,
        userPreferences: UserPreferences = DependencyContainer.shared.userPreferences,
        apiCache: APICacheProtocol = DependencyContainer.shared.apiCache
    ) {
        self.scheduleManager = scheduleManager
        self.userPreferences = userPreferences
        self.apiCache = apiCache
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
        // Set up an empty menu and assign delegate
        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
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
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
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
        if let memoryAuditTimer = memoryAuditTimer {
            RunLoop.current.add(memoryAuditTimer, forMode: .common)
        }
        
        // Perform an initial audit
        performMemoryAudit()
    }
    
    private func invalidateMemoryAuditTimer() {
        memoryAuditTimer?.invalidate()
        memoryAuditTimer = nil
    }
    
    @objc
    private func performMemoryAudit() {
        // Log current memory usage
        let memoryUsage = MemoryAudit.shared.currentMemoryUsage()
        logger.info("Current memory usage: \(MemoryAudit.shared.formatMemorySize(memoryUsage))")
        
        // Perform memory audit
        MemoryAudit.shared.performAudit()
    }
    
    @objc
    func updateMenu() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.fetchGamesAndUpdateMenu()
        }
    }
    
    private func fetchGamesAndUpdateMenu() async {
        do {
            if userPreferences.favoriteTeam == "ALL" {
                // Fetch all games for the current season
                let currentYear = Calendar.current.component(.year, from: Date())
                let season = String(currentYear)
                let response = try await DependencyContainer.shared.nbaClient.fetchSchedule(season: season)
                let allGames: [Game] = response.results.schedule

                // Filter for games in the next N days (including today)
                let now = Date()
                let calendar = Calendar.current
                let startOfToday = calendar.startOfDay(for: now)
                guard let endDate = calendar.date(
                    byAdding: .day,
                    value: userPreferences.allTeamsDaysToShow,
                    to: startOfToday
                ) else {
                    logger.error("Failed to calculate end date for filtering games.")
                    return
                }
                let filteredGames = allGames.filter { game in
                    let gameDate = calendar.startOfDay(for: game.localGameTime)
                    return gameDate >= startOfToday && gameDate < endDate
                }.sorted { $0.localGameTime < $1.localGameTime }

                await MainActor.run {
                    self.updateMenuUIForAllTeams(upcomingGames: filteredGames)
                }
            } else {
                // Fetch the games for the selected team
                let games = try await scheduleManager.fetchGames(forTeam: userPreferences.favoriteTeam)
                await MainActor.run {
                    self.games = games
                    self.updateMenuUI(with: games)
                }
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
        
        // Wrap in AnyView for type erasure
        let hostingView = NSHostingView(rootView: AnyView(menuView))
        self.hostingView = hostingView
        
        // Size the hosting view to fit its content
        hostingView.frame.size = hostingView.fittingSize
        
        // Remove all items from the existing menu and add the new view
        if let menu = self.statusItem?.menu {
            menu.removeAllItems()
            let customMenuItem = NSMenuItem()
            customMenuItem.view = hostingView
            menu.addItem(customMenuItem)
        }
    }

    private func updateMenuUIForAllTeams(upcomingGames: [Game]) {
        // Create a SwiftUI view for "All Teams" mode
        let menuView = AllTeamsMenuView(
            upcomingGames: upcomingGames,
            refreshAction: { [weak self] in
                self?.updateMenu()
            },
            changeTeamAction: { [weak self] newTeam in
                self?.changeTeam(to: newTeam)
            }
        )

        let hostingView = NSHostingView(rootView: AnyView(menuView))
        self.hostingView = hostingView

        hostingView.frame.size = hostingView.fittingSize

        if let menu = self.statusItem?.menu {
            menu.removeAllItems()
            let customMenuItem = NSMenuItem()
            customMenuItem.view = hostingView
            menu.addItem(customMenuItem)
        }
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
            // MARK: - NSMenuDelegate
            func menuWillOpen(_ menu: NSMenu) {
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.fetchGamesAndUpdateMenu()
                }
            }
        }
        
        teamItem.submenu = teamSubmenu
        menu.addItem(teamItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add quit option
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // Set the menu
        self.statusItem?.menu = menu
    }
    
    @objc
    private func teamSelected(_ sender: NSMenuItem) {
        guard let teamAbbr = sender.representedObject as? String else { return }
        changeTeam(to: teamAbbr)
    }
    
    private func changeTeam(to teamAbbreviation: String) {
        userPreferences.favoriteTeam = teamAbbreviation
        userPreferences.savePreferences()
        updateStatusButtonTooltip()
        apiCache.clearCache() // Ensure fresh data is fetched for new team
        updateMenu()
    }
}
