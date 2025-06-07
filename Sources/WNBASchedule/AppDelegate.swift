import AppKit
import Foundation
import SwiftDate

class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    private var statusItem: NSStatusItem?
    private var scheduleManager: ScheduleManager?
    private var timer: Timer?
    private var favoriteTeam = "NYL" // Default to NY Liberty
    
    // Constants
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // Set the icon - use a basketball emoji for better visibility
        if let statusButton = statusItem?.button {
            statusButton.title = "🏀"
            
            let font = NSFont.systemFont(ofSize: 18, weight: .semibold)
            statusButton.font = font
            
            statusButton.toolTip = "NY Liberty WNBA Schedule"
        }
        
        // Initialize the client and schedule manager
        let client = NBAClient()
        scheduleManager = ScheduleManager(client: client)
        
        // Update the menu initially
        updateMenu()
        
        // Set up a timer to update the menu periodically
        timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(updateMenu), userInfo: nil, repeats: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
    
    @objc func updateMenu() {
        guard let scheduleManager = scheduleManager else { return }
        
        Task { [self] in
            do {
                // Fetch the games
                let games = try await scheduleManager.fetchGames(forTeam: self.favoriteTeam)
                
                // Create the menu
                let menu = NSMenu()
                
                let titleItem = NSMenuItem(title: "NY LIBERTY SCHEDULE", action: nil, keyEquivalent: "")
                titleItem.isEnabled = false
                
                let titleParagraphStyle = NSMutableParagraphStyle()
                titleParagraphStyle.alignment = .center
                
                titleItem.attributedTitle = NSAttributedString(
                    string: "NY LIBERTY SCHEDULE",
                    attributes: [
                        .font: NSFont.boldSystemFont(ofSize: 16),
                        .foregroundColor: NSColor(red: 0.0, green: 0.5, blue: 0.4, alpha: 1.0), // Seafoam green
                        .paragraphStyle: titleParagraphStyle
                    ]
                )
                menu.addItem(titleItem)
                menu.addItem(NSMenuItem.separator())
                
                // Add past games section
                if !games.pastGames.isEmpty {
                    let separator = NSMenuItem.separator()
                    menu.addItem(separator)
                    
                    // Add a bit of extra space before the section
                    menu.addItem(NSMenuItem.separator())
                    
                    let pastGamesHeader = NSMenuItem(title: "PREVIOUS GAMES", action: nil, keyEquivalent: "")
                    pastGamesHeader.isEnabled = false
                    
                    let headerStyle = NSMutableParagraphStyle()
                    headerStyle.alignment = .left
                    headerStyle.firstLineHeadIndent = 8
                    
                    // Using our custom NSAttributedString extension
                    pastGamesHeader.attributedTitle = NSAttributedString.header("PREVIOUS GAMES")
                    
                    menu.addItem(pastGamesHeader)
                    
                    for markedGame in games.pastGames {
                        let game = markedGame.game
                        let homeTeam = game.home
                        let awayTeam = game.visitor
                        
                        // Using the new convenience methods from Game.swift
                        let formattedDate = game.formattedGameDate
                        
                        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                        
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .left
                        paragraphStyle.firstLineHeadIndent = 15
                        
                        // Determine which team won
                        let homeWon = (homeTeam.score ?? 0) > (awayTeam.score ?? 0)
                        
                        // Using our gameRow helper for better alignment
                        // homeWon is already defined above
                        item.attributedTitle = NSAttributedString.gameRow(
                            date: formattedDate,
                            awayTeam: awayTeam.abbr,
                            awayScore: awayTeam.score,
                            homeTeam: homeTeam.abbr,
                            homeScore: homeTeam.score,
                            homeWon: homeWon
                        )
                        
                        menu.addItem(item)
                    }
                    
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Add upcoming games section
                if !games.upcomingGames.isEmpty {
                    let separator = NSMenuItem.separator()
                    menu.addItem(separator)
                    
                    // Add a bit of extra space before the section
                    menu.addItem(NSMenuItem.separator())
                    
                    let upcomingGamesHeader = NSMenuItem(title: "UPCOMING GAMES", action: nil, keyEquivalent: "")
                    upcomingGamesHeader.isEnabled = false
                    
                    // Create header style for upcoming games
                    let upcomingHeaderStyle = NSMutableParagraphStyle()
                    upcomingHeaderStyle.alignment = .left
                    upcomingHeaderStyle.firstLineHeadIndent = 8
                    
                    // Using our custom NSAttributedString extension
                    upcomingGamesHeader.attributedTitle = NSAttributedString.header("UPCOMING GAMES")
                    
                    menu.addItem(upcomingGamesHeader)
                    
                    for markedGame in games.upcomingGames {
                        let game = markedGame.game
                        let homeTeam = game.home
                        let awayTeam = game.visitor
                        
                        // Using the new convenience methods from Game.swift
                        let formattedDate = game.formattedGameDate
                        let formattedTime = game.formattedGameTime
                        
                        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                        
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .left
                        paragraphStyle.firstLineHeadIndent = 15
                        
                        // Get broadcast info
                        let broadcastInfo = game.providers?.first?.broadcasterAbbreviation
                        
                        // Using our upcomingGameRow helper for better alignment
                        item.attributedTitle = NSAttributedString.upcomingGameRow(
                            date: formattedDate,
                            time: formattedTime,
                            awayTeam: awayTeam.abbr,
                            homeTeam: homeTeam.abbr,
                            broadcast: broadcastInfo
                        )
                        
                        menu.addItem(item)
                    }
                    
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Add a separator with styling
                let separator = NSMenuItem.separator()
                menu.addItem(separator)
                
                // Add refresh option with styling
                let refreshItem = NSMenuItem(title: "Refresh", action: #selector(self.updateMenu), keyEquivalent: "r")
                refreshItem.attributedTitle = NSAttributedString.menuItem("Refresh", color: .blue)
                menu.addItem(refreshItem)
                
                // Add version information
                let versionItem = NSMenuItem(title: "Version", action: nil, keyEquivalent: "")
                versionItem.isEnabled = false
                versionItem.attributedTitle = NSAttributedString.menuItem("Version \(Version.version)")
                menu.addItem(versionItem)
                
                // Add quit option with styling
                let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                quitItem.attributedTitle = NSAttributedString.menuItem("Quit")
                
                menu.addItem(quitItem)
                
                Task { @MainActor in
                    self.statusItem?.menu = menu
                }
            } catch {
                print("Error updating menu: \(error.localizedDescription)")
                
                // Create an error menu
                let menu = NSMenu()
                menu.addItem(NSMenuItem(title: "Error fetching WNBA schedule", action: nil, keyEquivalent: ""))
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Refresh", action: #selector(self.updateMenu), keyEquivalent: "r"))
                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
                
                Task { @MainActor in
                    self.statusItem?.menu = menu
                }
            }
        }
    }
}