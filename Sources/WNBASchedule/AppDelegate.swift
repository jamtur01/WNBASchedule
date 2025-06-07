import AppKit
import Foundation
import SwiftUI
import SwiftDate

class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    private var statusItem: NSStatusItem?
    private var scheduleManager: ScheduleManager?
    private var timer: Timer?
    private var favoriteTeam = "NYL" // Default to NY Liberty
    private var hostingView: NSHostingView<MenuView>?
    private var games: FilteredGames?
    
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
                self.games = games
                
                // Create the SwiftUI menu
                let menuView = MenuView(games: games, refreshAction: { [weak self] in
                    self?.updateMenu()
                })
                
                // Create and configure the hosting view on the main actor
                Task { @MainActor in
                    // Create a hosting view for the SwiftUI view
                    let hostingView = NSHostingView(rootView: menuView)
                    self.hostingView = hostingView
                    
                    // Size the hosting view to fit its content
                    hostingView.frame.size = hostingView.fittingSize
                    
                    // Create a menu
                    let menu = NSMenu()
                    
                    // Create a custom menu item that contains the hosting view
                    let customMenuItem = NSMenuItem()
                    customMenuItem.view = hostingView
                    
                    // Add the custom menu item to the menu
                    menu.addItem(customMenuItem)
                    
                    // Set the menu
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