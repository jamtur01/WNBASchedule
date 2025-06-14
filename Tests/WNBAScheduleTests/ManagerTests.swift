import XCTest
@testable import WNBASchedule
import AppKit

final class ManagerTests: XCTestCase {
    // MARK: - StatusBarManager Tests
    
    func testStatusBarManagerCreation() {
        let mockUserPreferences = UserPreferences()
        mockUserPreferences.favoriteTeam = "NYL"
        
        let statusBarManager = StatusBarManager(userPreferences: mockUserPreferences)
        
        // Test status bar manager creation
        XCTAssertNotNil(statusBarManager)
        
        // Test that methods can be called without crashing (in headless environment)
        statusBarManager.updateTooltip()
        
        // Test getter returns nil in headless environment
        XCTAssertNil(statusBarManager.getStatusItem())
    }
    
    // MARK: - TimerManager Tests
    
    func testTimerManagerSetup() {
        let timerManager = TimerManager()
        let mockTarget = MockTimerTarget()
        
        // Test refresh timer setup
        timerManager.setupRefreshTimer(target: mockTarget, selector: #selector(MockTimerTarget.refreshAction))
        
        // Test memory audit timer setup
        timerManager.setupMemoryAuditTimer(target: mockTarget, selector: #selector(MockTimerTarget.memoryAuditAction))
        
        // Test live score timer setup with in-progress games
        timerManager.setupLiveScoreTimer(
            target: mockTarget,
            selector: #selector(MockTimerTarget.liveScoreAction),
            hasInProgressGames: true
        )
        
        // Test live score timer setup without in-progress games
        timerManager.setupLiveScoreTimer(
            target: mockTarget,
            selector: #selector(MockTimerTarget.liveScoreAction),
            hasInProgressGames: false
        )
        
        // Test bulk timer setup
        timerManager.setupAllTimers(
            target: mockTarget,
            refreshSelector: #selector(MockTimerTarget.refreshAction),
            memoryAuditSelector: #selector(MockTimerTarget.memoryAuditAction),
            liveScoreSelector: #selector(MockTimerTarget.liveScoreAction),
            hasInProgressGames: true
        )
        
        // Test timer invalidation
        timerManager.invalidateRefreshTimer()
        timerManager.invalidateMemoryAuditTimer()
        timerManager.invalidateLiveScoreTimer()
        timerManager.invalidateAllTimers()
        
        // All operations should complete without throwing
        XCTAssertTrue(true)
    }
    
    // MARK: - MenuManager Tests
    
    func testMenuManagerCreation() {
        let mockUserPreferences = UserPreferences()
        mockUserPreferences.favoriteTeam = "NYL"
        
        let menuManager = MenuManager(userPreferences: mockUserPreferences)
        
        // Test menu manager creation
        XCTAssertNotNil(menuManager)
    }
    
    func testMenuManagerCreationAndDelegateSetup() {
        let menuManager = MenuManager()
        let mockDelegate = MockMenuDelegate()
        
        // Test that we can create menu manager and call setup without crashing
        // Note: Actual NSStatusBar testing requires GUI environment
        XCTAssertNotNil(menuManager)
        
        // Test delegate setup with nil status item (simulating headless environment)
        menuManager.setupMenuDelegate(statusItem: nil, delegate: mockDelegate)
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testMenuManagerErrorMenuCreation() {
        let menuManager = MenuManager()
        let mockTarget = MockMenuTarget()
        
        let testError = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Test error menu creation with nil status item (simulating headless environment)
        menuManager.showErrorMenu(
            error: testError,
            statusItem: nil,
            target: mockTarget,
            updateMenuSelector: #selector(MockMenuTarget.updateMenu),
            teamSelectedSelector: #selector(MockMenuTarget.teamSelected(_:))
        )
        
        // Should not crash
        XCTAssertTrue(true)
    }
    func testMenuManagerTeamMenuUpdate() {
        let menuManager = MenuManager()
        
        // Create mock filtered games
        let pastGame = MarkedGame(
            game: createTestGame(state: 3),
            isHomeGame: true
        )
        let upcomingGame = MarkedGame(
            game: createTestGame(state: 0),
            isHomeGame: false
        )
        
        let filteredGames = FilteredGames(
            pastGames: [pastGame],
            inProgressGames: [],
            upcomingGames: [upcomingGame]
        )
        
        // Test menu UI update with nil status item (simulating headless environment)
        menuManager.updateMenuUI(
            with: filteredGames,
            statusItem: nil,
            refreshAction: { },
            changeTeamAction: { _ in }
        )
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testMenuManagerAllTeamsUpdate() {
        let menuManager = MenuManager()
        
        // Create mock games
        let upcomingGames = [createTestGame(state: 0)]
        let inProgressGames = [createTestGame(state: 1)]
        
        // Test all teams menu UI update with nil status item (simulating headless environment)
        menuManager.updateMenuUIForAllTeams(
            upcomingGames: upcomingGames,
            inProgressGames: inProgressGames,
            statusItem: nil,
            refreshAction: { },
            changeTeamAction: { _ in }
        )
        
        // Should not crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Helper Methods
    
    private func createTestGame(state: Int = 0) -> Game {
        return Game(
            gid: "testGame",
            easternTime: "2025-05-01T19:00:00Z",
            utcTime: "2025-05-01T23:00:00Z",
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            home: Team(tid: 1, abbr: "NYL", city: "New York", name: "Liberty", score: nil, losses: 2, wins: 10),
            visitor: Team(tid: 2, abbr: "LVA", city: "Las Vegas", name: "Aces", score: nil, losses: 3, wins: 9),
            state: state,
            id: 1,
            type: "game",
            title: "Test Game",
            homeTime: "2025-05-01T19:00:00Z",
            visitorTime: "2025-05-01T22:00:00Z",
            providers: nil,
            arenaName: "Test Arena",
            arenaState: "NY",
            arenaCity: "New York",
            gameStatusText: nil,
            gameLabel: nil,
            gameSubLabel: nil,
            seriesText: nil,
            seriesGameNumber: nil,
            ifNecessary: nil,
            gameSubtype: nil,
            name: nil,
            themeNightLabel: nil,
            ticketUrl: nil,
            isLeaguePassGame: nil,
            leaguePassVideoLink: nil
        )
    }
}

// MARK: - Mock Classes

class MockTimerTarget: NSObject {
    @objc
    func refreshAction() {
        // Mock implementation
    }
    
    @objc
    func memoryAuditAction() {
        // Mock implementation
    }
    
    @objc
    func liveScoreAction() {
        // Mock implementation
    }
}

class MockMenuDelegate: NSObject, NSMenuDelegate {
    // Mock menu delegate implementation
}

class MockMenuTarget: NSObject {
    @objc
    func updateMenu() {
        // Mock implementation
    }
    
    @objc
    func teamSelected(_ sender: NSMenuItem) {
        // Mock implementation
    }
}
