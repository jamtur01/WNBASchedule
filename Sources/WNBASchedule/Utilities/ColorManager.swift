import SwiftUI
import AppKit

/// Manages color schemes for better readability while maintaining team color identity
struct ColorManager {
    
    // MARK: - Team Colors with Improved Readability
    
    /// Enhanced team colors optimized for readability while preserving brand identity
    private static let enhancedTeamColors: [String: String] = [
        "ATL": "#E31E45",    // Brightened from #C8102E (Atlanta red)
        "CHI": "#4A9EF2",    // Lightened from #418FDE (Chicago blue)  
        "CON": "#FF6B35",    // Warmed from #E03A3E (Connecticut red-orange)
        "DAL": "#D4E815",    // Slightly brightened from #C4D600 (Dallas lime)
        "GSV": "#B8A8E8",    // Lightened from #AD96DC (Golden State purple)
        "IND": "#1A4B8C",    // Lightened from #041E42 (Indiana navy)
        "LAS": "#8A4FA8",    // Lightened from #702F8A (LA Sparks purple)
        "LVA": "#2A2A2A",    // Lightened from pure black #010101 (Vegas)
        "MIN": "#3A7BB8",    // Brightened from #236192 (Minnesota blue)
        "NYL": "#7FD6C2",    // Slightly darkened from #6ECEB2 (NY Liberty teal)
        "PHX": "#3D2A65",    // Lightened from #211747 (Phoenix purple)
        "SEA": "#4A6B52",    // Lightened from #2C5234 (Seattle green)  
        "WAS": "#E31E45"     // Same as Atlanta - brightened from #C8102E (Washington red)
    ]
    
    // MARK: - WNBA Brand Colors
    
    /// Main WNBA brand orange with better contrast
    static let wnbaOrange = "#FF5722"  // Slightly adjusted from #FA4616 for better readability
    
    /// Secondary WNBA colors
    static let wnbaNavy = "#1A365D"
    static let wnbaGray = "#4A5568"
    
    // MARK: - State Colors
    
    /// Win/loss state colors optimized for accessibility
    static let winGreen = "#22C55E"     // More vibrant than default green
    static let lossRed = "#EF4444"      // Softer than harsh red
    static let inProgressOrange = "#F59E0B"  // Warmer orange for live games
    
    // MARK: - UI Colors
    
    /// Text colors with improved contrast
    static let primaryText = "#1F2937"   // Dark gray instead of pure black
    static let secondaryText = "#6B7280" // Medium gray for secondary info
    static let lightText = "#9CA3AF"     // Light gray for timestamps
    
    /// Background colors
    static let cardBackground = "#F9FAFB"
    static let separatorColor = "#E5E7EB"
    
    // MARK: - Color Access Methods
    
    /// Get enhanced team color that maintains brand identity while improving readability
    /// - Parameter teamAbbreviation: Team abbreviation (e.g., "NYL")
    /// - Returns: SwiftUI Color with enhanced readability
    static func teamColor(for teamAbbreviation: String) -> Color {
        if let hexColor = enhancedTeamColors[teamAbbreviation] {
            return Color(hex: hexColor) ?? .blue
        }
        return Color(hex: wnbaOrange) ?? .orange
    }
    
    /// Get original team color from TeamManager for comparison/fallback
    /// - Parameter teamAbbreviation: Team abbreviation
    /// - Returns: Original team color
    static func originalTeamColor(for teamAbbreviation: String) -> Color {
        let originalColor = TeamManager.getTeamColor(abbreviation: teamAbbreviation)
        return Color(hex: originalColor) ?? .blue
    }
    
    /// WNBA brand color as SwiftUI Color
    static var wnbaBrandColor: Color {
        Color(hex: wnbaOrange) ?? .orange
    }
    
    /// Win state color
    static var winColor: Color {
        Color(hex: winGreen) ?? .green
    }
    
    /// Loss state color  
    static var lossColor: Color {
        Color(hex: lossRed) ?? .red
    }
    
    /// In-progress game color
    static var liveColor: Color {
        Color(hex: inProgressOrange) ?? .orange
    }
    
    /// Primary text color
    static var textPrimary: Color {
        Color(hex: primaryText) ?? .primary
    }
    
    /// Secondary text color
    static var textSecondary: Color {
        Color(hex: secondaryText) ?? .secondary
    }
    
    /// Light text color for timestamps
    static var textLight: Color {
        Color(hex: lightText) ?? .gray
    }
    
    // MARK: - NSColor Support for Legacy Code
    
    /// Convert hex string to NSColor for AppKit/attributed strings
    /// - Parameter hex: Hex color string
    /// - Returns: NSColor or default color
    static func nsColor(hex: String) -> NSColor {
        let color = Color(hex: hex) ?? .primary
        return NSColor(color)
    }
    
    /// Get team color as NSColor
    /// - Parameter teamAbbreviation: Team abbreviation
    /// - Returns: NSColor for team
    static func teamNSColor(for teamAbbreviation: String) -> NSColor {
        if let hexColor = enhancedTeamColors[teamAbbreviation] {
            return nsColor(hex: hexColor)
        }
        return nsColor(hex: wnbaOrange)
    }
    
    /// Win color as NSColor
    static var winNSColor: NSColor {
        nsColor(hex: winGreen)
    }
    
    /// Loss color as NSColor  
    static var lossNSColor: NSColor {
        nsColor(hex: lossRed)
    }
    
    /// WNBA brand color as NSColor
    static var wnbaNSColor: NSColor {
        nsColor(hex: wnbaOrange)
    }
}

// MARK: - Color Extension (Enhanced)

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (with or without #)
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}