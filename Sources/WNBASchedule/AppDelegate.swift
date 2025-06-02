import AppKit
import Foundation
// Import Version.swift for version information

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
        
        Task {
            do {
                // Fetch the games
                let games = try await scheduleManager.fetchGames(forTeam: favoriteTeam)
                
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
                    
                    let pastGamesHeader = NSMenuItem(title: "PREVIOUS GAMES", action: nil, keyEquivalent: "")
                    pastGamesHeader.isEnabled = false
                    
                    let headerStyle = NSMutableParagraphStyle()
                    headerStyle.alignment = .left
                    headerStyle.firstLineHeadIndent = 8
                    
                    pastGamesHeader.attributedTitle = NSAttributedString(
                        string: "PREVIOUS GAMES",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 14),  
                            .foregroundColor: NSColor.black,    
                            .paragraphStyle: headerStyle
                        ]
                    )
                    menu.addItem(pastGamesHeader)
                    
                    for markedGame in games.pastGames {
                        let game = markedGame.game
                        let homeTeam = game.home
                        let awayTeam = game.visitor
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .none
                        let date = dateFormatter.string(from: game.localGameTime)
                        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                        
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .left
                        paragraphStyle.firstLineHeadIndent = 15
                        
                        let dateString = NSAttributedString(
                            string: "\(date)",
                            attributes: [
                                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                                .foregroundColor: NSColor.darkGray,
                                .paragraphStyle: paragraphStyle
                            ]
                        )
                                                
                        // Create a mutable attributed string for the score with different colors for winning/losing teams
                        let scoreString = NSMutableAttributedString()
                        
                        // Determine which team won
                        let homeWon = (homeTeam.score ?? 0) > (awayTeam.score ?? 0)
                        
                        // Winning team attributes (green)
                        let winningTeamAttributes: [NSAttributedString.Key: Any] = [
                            .font: NSFont.boldSystemFont(ofSize: 13),
                            .foregroundColor: NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0) // Green
                        ]
                        
                        // Losing team attributes (red)
                        let losingTeamAttributes: [NSAttributedString.Key: Any] = [
                            .font: NSFont.boldSystemFont(ofSize: 13),
                            .foregroundColor: NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // Red
                        ]
                        
                        // Neutral attributes for separator
                        let separatorAttributes: [NSAttributedString.Key: Any] = [
                            .font: NSFont.systemFont(ofSize: 13),
                            .foregroundColor: NSColor.darkGray
                        ]
                        
                        // Add away team name and score with appropriate color
                        let awayAttributes = homeWon ? losingTeamAttributes : winningTeamAttributes
                        scoreString.append(NSAttributedString(string: "  \(awayTeam.abbr) \(awayTeam.score ?? 0)", attributes: awayAttributes))
                        
                        // Add separator
                        scoreString.append(NSAttributedString(string: "  @  ", attributes: separatorAttributes))
                        
                        // Add home team name and score with appropriate color
                        let homeAttributes = homeWon ? winningTeamAttributes : losingTeamAttributes
                        scoreString.append(NSAttributedString(string: "\(homeTeam.abbr) \(homeTeam.score ?? 0)  ", attributes: homeAttributes))
                        
                        // Combine the attributed strings (without locationString and resultString)
                        let attributedTitle = NSMutableAttributedString()
                        attributedTitle.append(dateString)
                        attributedTitle.append(scoreString)
                        
                        item.attributedTitle = attributedTitle
                        menu.addItem(item)
                    }
                    
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Add upcoming games section
                if !games.upcomingGames.isEmpty {
                    let separator = NSMenuItem.separator()
                    menu.addItem(separator)
                    
                    let upcomingGamesHeader = NSMenuItem(title: "UPCOMING GAMES", action: nil, keyEquivalent: "")
                    upcomingGamesHeader.isEnabled = false
                    
                    // Create header style for upcoming games
                    let upcomingHeaderStyle = NSMutableParagraphStyle()
                    upcomingHeaderStyle.alignment = .left
                    upcomingHeaderStyle.firstLineHeadIndent = 8
                    
                    upcomingGamesHeader.attributedTitle = NSAttributedString(
                        string: "UPCOMING GAMES",
                        attributes: [
                            .font: NSFont.boldSystemFont(ofSize: 14),
                            .foregroundColor: NSColor.black,
                            .paragraphStyle: upcomingHeaderStyle
                        ]
                    )
                    menu.addItem(upcomingGamesHeader)
                    
                    for markedGame in games.upcomingGames {
                        let game = markedGame.game
                        let homeTeam = game.home
                        let awayTeam = game.visitor
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .none
                        let date = dateFormatter.string(from: game.localGameTime)
                        
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateStyle = .none
                        timeFormatter.timeStyle = .short
                        let time = timeFormatter.string(from: game.localGameTime)
                                                
                        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                        
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .left
                        paragraphStyle.firstLineHeadIndent = 15
                        
                        let dateString = NSAttributedString(
                            string: "\(date) at \(time)",
                            attributes: [
                                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                                .foregroundColor: NSColor.darkGray,
                                .paragraphStyle: paragraphStyle
                            ]
                        )
                        
                        let matchupAttributes: [NSAttributedString.Key: Any] = [
                            .font: NSFont.boldSystemFont(ofSize: 13),
                            .foregroundColor: NSColor.black
                        ]
                        
                        let matchupString = NSAttributedString(
                            string: "  \(awayTeam.abbr)  @  \(homeTeam.abbr)  ",
                            attributes: matchupAttributes
                        )
                        
                        let attributedTitle = NSMutableAttributedString()
                        attributedTitle.append(dateString)
                        attributedTitle.append(matchupString)
                        
                        item.attributedTitle = attributedTitle
                        menu.addItem(item)
                    }
                    
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Add a separator with styling
                let separator = NSMenuItem.separator()
                menu.addItem(separator)
                
                // Add refresh option with styling
                let refreshItem = NSMenuItem(title: "Refresh", action: #selector(self.updateMenu), keyEquivalent: "r")
                
                let refreshAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: NSColor.blue
                ]
                
                refreshItem.attributedTitle = NSAttributedString(
                    string: "Refresh",
                    attributes: refreshAttributes
                )
                
                menu.addItem(refreshItem)
                
                // Add version information
                let versionItem = NSMenuItem(title: "Version", action: nil, keyEquivalent: "")
                versionItem.isEnabled = false
                
                let versionAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: NSColor.darkGray
                ]
                
                versionItem.attributedTitle = NSAttributedString(
                    string: "Version \(AppVersion.version)",
                    attributes: versionAttributes
                )
                
                menu.addItem(versionItem)
                
                // Add quit option with styling
                let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                
                let quitAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: NSColor.darkGray
                ]
                
                quitItem.attributedTitle = NSAttributedString(
                    string: "Quit",
                    attributes: quitAttributes
                )
                
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