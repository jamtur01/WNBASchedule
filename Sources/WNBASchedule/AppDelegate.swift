import AppKit
import Foundation
import SwiftUI
import SwiftDate
import os.log

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, @unchecked Sendable {
    // MARK: - Properties
    private var games: FilteredGames?
    private let scheduleManager: ScheduleManagerProtocol
    private let userPreferences: UserPreferences
    private let apiCache: APICacheProtocol
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "AppDelegate")
    
    // Managers
    private let statusBarManager: StatusBarManager
    private let timerManager: TimerManager
    private let menuManager: MenuManager
    private let liveScoreManager: LiveScoreManager
    
    // MARK: - Initialization
    init(
        scheduleManager: ScheduleManagerProtocol = DependencyContainer.shared.scheduleManager,
        userPreferences: UserPreferences = DependencyContainer.shared.userPreferences,
        apiCache: APICacheProtocol = DependencyContainer.shared.apiCache
    ) {
        self.scheduleManager = scheduleManager
        self.userPreferences = userPreferences
        self.apiCache = apiCache
        
        // Initialize managers
        self.statusBarManager = StatusBarManager(userPreferences: userPreferences)
        self.timerManager = TimerManager()
        self.menuManager = MenuManager(userPreferences: userPreferences)
        self.liveScoreManager = LiveScoreManager()
        
        super.init()
    }
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        trackForMemoryLeak(description: "AppDelegate")
        
        setupApplication()
        logInitialMemoryUsage()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timerManager.invalidateAllTimers()
        stopMemoryTracking()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        timerManager.invalidateAllTimers()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        setupTimers()
        updateMenu()
    }
    
    // MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        Task { [weak self] in
            guard let self = self else { return }
            await self.fetchGamesAndUpdateMenu()
        }
    }
    
    // MARK: - Private Setup Methods
    private func setupApplication() {
        guard let statusItem = statusBarManager.setupStatusItem() else {
            logger.error("Failed to create status item")
            return
        }
        
        menuManager.setupMenuDelegate(statusItem: statusItem, delegate: self)
        updateMenu()
        setupTimers()
    }
    
    private func setupTimers() {
        let hasInProgressGames = self.hasInProgressGames()
        
        timerManager.setupAllTimers(
            target: self,
            refreshSelector: #selector(updateMenu),
            memoryAuditSelector: #selector(performMemoryAudit),
            liveScoreSelector: #selector(updateLiveScores),
            hasInProgressGames: hasInProgressGames
        )
    }
    
    private func logInitialMemoryUsage() {
        let memoryUsage = MemoryAudit.shared.currentMemoryUsage()
        logger.info("Initial memory usage: \(MemoryAudit.shared.formatMemorySize(memoryUsage))")
    }
    
    // MARK: - Timer Actions
    @objc
    private func performMemoryAudit() {
        let memoryUsage = MemoryAudit.shared.currentMemoryUsage()
        logger.info("Current memory usage: \(MemoryAudit.shared.formatMemorySize(memoryUsage))")
        MemoryAudit.shared.performAudit()
    }
    
    @objc
    private func updateLiveScores() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.performLiveScoreUpdate()
        }
    }
    
    @objc
    func updateMenu() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.fetchGamesAndUpdateMenu()
        }
    }
    
    // MARK: - Game Fetching and Menu Updates
    private func fetchGamesAndUpdateMenu() async {
        do {
            if userPreferences.favoriteTeam == "ALL" {
                try await handleAllTeamsMode()
            } else {
                try await handleIndividualTeamMode()
            }
        } catch {
            logger.error("Error updating menu: \(error.localizedDescription)")
            await MainActor.run {
                self.showErrorMenu(error: error)
            }
        }
    }
    
    private func handleAllTeamsMode() async throws {
        // Fetch all games for the current season
        let currentYear = Calendar.current.component(.year, from: Date())
        let season = String(currentYear)
        let response = try await DependencyContainer.shared.nbaClient.fetchSchedule(season: season)
        let allGames: [Game] = response.results.schedule

        // Filter for games in the specified date range
        let filteredGames = try filterGamesForAllTeams(allGames)

        // Split into in-progress and upcoming games
        var inProgressGames = filteredGames.filter { $0.isInProgress }
        let upcomingGames = filteredGames.filter { $0.isUpcoming }

        // Fetch live scores for in-progress games
        if !inProgressGames.isEmpty {
            inProgressGames = await liveScoreManager.fetchLiveScores(for: inProgressGames)
        }

        // Capture variables for MainActor
        let finalInProgressGames = inProgressGames
        let hasInProgressGames = !inProgressGames.isEmpty

        await MainActor.run {
            self.updateMenuUIForAllTeams(upcomingGames: upcomingGames, inProgressGames: finalInProgressGames)
            self.setupLiveScoreTimerIfNeeded(hasInProgressGames: hasInProgressGames)
        }
    }
    
    private func handleIndividualTeamMode() async throws {
        let games = try await scheduleManager.fetchGames(forTeam: userPreferences.favoriteTeam)
        
        await MainActor.run {
            self.games = games
            self.updateMenuUI(with: games)
            self.setupLiveScoreTimerIfNeeded(hasInProgressGames: !games.inProgressGames.isEmpty)
        }
    }
    
    // MARK: - Live Score Updates
    private func performLiveScoreUpdate() async {
        logger.info("Performing live score update")
        
        if userPreferences.favoriteTeam == "ALL" {
            await updateLiveScoresForAllTeams()
        } else {
            await updateLiveScoresForTeam()
        }
    }
    
    private func updateLiveScoresForAllTeams() async {
        await liveScoreManager.updateLiveScoresForAllTeams(userPreferences: userPreferences) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    if data.gameFinished {
                        logger.info("Game finished, refreshing entire schedule")
                        self.updateMenu()
                    } else {
                        self.updateMenuUIForAllTeams(
                            upcomingGames: data.upcomingGames,
                            inProgressGames: data.inProgressGames
                        )
                    }
                    
                    if data.inProgressGames.isEmpty {
                        self.timerManager.invalidateLiveScoreTimer()
                    }
                    
                case .failure(let error):
                    logger.error("Error updating live scores for all teams: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateLiveScoresForTeam() async {
        guard let currentGames = games else {
            logger.info("No current games, stopping live score updates")
            await MainActor.run {
                self.timerManager.invalidateLiveScoreTimer()
            }
            return
        }
        
        await liveScoreManager.updateLiveScoresForTeam(currentGames: currentGames) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    if data.gameFinished {
                        logger.info("Game finished, refreshing entire schedule")
                        self.updateMenu()
                    } else {
                        self.games = data.updatedGames
                        self.updateMenuUI(with: data.updatedGames)
                    }
                    
                    if data.updatedGames.inProgressGames.isEmpty {
                        self.timerManager.invalidateLiveScoreTimer()
                    }
                    
                case .failure(let error):
                    logger.error("Error updating live scores for team: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - UI Updates
    private func updateMenuUI(with games: FilteredGames) {
        menuManager.updateMenuUI(
            with: games,
            statusItem: statusBarManager.getStatusItem(),
            refreshAction: { [weak self] in self?.updateMenu() },
            changeTeamAction: { [weak self] newTeam in self?.changeTeam(to: newTeam) }
        )
    }
    
    private func updateMenuUIForAllTeams(upcomingGames: [Game], inProgressGames: [Game]) {
        menuManager.updateMenuUIForAllTeams(
            upcomingGames: upcomingGames,
            inProgressGames: inProgressGames,
            statusItem: statusBarManager.getStatusItem(),
            refreshAction: { [weak self] in self?.updateMenu() },
            changeTeamAction: { [weak self] newTeam in self?.changeTeam(to: newTeam) }
        )
    }
    
    private func showErrorMenu(error: Error) {
        menuManager.showErrorMenu(
            error: error,
            statusItem: statusBarManager.getStatusItem(),
            target: self,
            updateMenuSelector: #selector(updateMenu),
            teamSelectedSelector: #selector(teamSelected(_:))
        )
    }
    
    // MARK: - Team Management
    @objc
    private func teamSelected(_ sender: NSMenuItem) {
        guard let teamAbbr = sender.representedObject as? String else { return }
        changeTeam(to: teamAbbr)
    }
    
    private func changeTeam(to teamAbbreviation: String) {
        // If switching to "ALL", save the current team as previously selected
        if teamAbbreviation == "ALL" && userPreferences.favoriteTeam != "ALL" {
            userPreferences.previouslySelectedTeam = userPreferences.favoriteTeam
        }
        
        userPreferences.favoriteTeam = teamAbbreviation
        userPreferences.savePreferences()
        statusBarManager.updateTooltip()
        apiCache.clearCache()
        updateMenu()
    }
    
    // MARK: - Helper Methods
    private func hasInProgressGames() -> Bool {
        if let games = games {
            return !games.inProgressGames.isEmpty
        }
        return userPreferences.favoriteTeam == "ALL"
    }
    
    private func setupLiveScoreTimerIfNeeded(hasInProgressGames: Bool) {
        if hasInProgressGames {
            timerManager.setupLiveScoreTimer(
                target: self,
                selector: #selector(updateLiveScores),
                hasInProgressGames: hasInProgressGames
            )
        }
    }
    
    private func filterGamesForAllTeams(_ allGames: [Game]) throws -> [Game] {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        
        guard let endDate = calendar.date(
            byAdding: .day,
            value: userPreferences.allTeamsDaysToShow,
            to: startOfToday
        ) else {
            throw LiveScoreError.dateCalculationFailed
        }
        
        return allGames.filter { game in
            let gameDate = calendar.startOfDay(for: game.localGameTime)
            return gameDate >= startOfToday && gameDate < endDate
        }.sorted { $0.localGameTime < $1.localGameTime }
    }
}
