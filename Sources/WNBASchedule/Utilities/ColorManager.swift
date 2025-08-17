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
        "DAL": "#8BA614",    // Darkened from #D4E815 for better readability (Dallas lime)
        "GSV": "#B8A8E8",    // Lightened from #AD96DC (Golden State purple)
        "IND": "#1A4B8C",    // Lightened from #041E42 (Indiana navy)
        "LAS": "#8A4FA8",    // Lightened from #702F8A (LA Sparks purple)
        "LVA": "#2A2A2A",    // Lightened from pure black #010101 (Vegas)
        "MIN": "#3A7BB8",    // Brightened from #236192 (Minnesota blue)
        "NYL": "#2D8A72",    // Darkened from #7FD6C2 for better readability (NY Liberty teal)
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
    
    // MARK: - Dark Mode Colors
    
    /// Dark mode variants of team colors with adjusted brightness for contrast
    private static let darkModeTeamColors: [String: String] = [
        "ATL": "#FF4A70",    // Brighter red for dark backgrounds
        "CHI": "#6BB6FF",    // Lighter blue for dark backgrounds
        "CON": "#FF8A5B",    // Warmer red-orange for dark backgrounds
        "DAL": "#C4D630",    // Moderately bright lime for dark backgrounds (readable)
        "GSV": "#D4C4F0",    // Lighter purple for dark backgrounds
        "IND": "#4A7BC8",    // Brighter navy for dark backgrounds
        "LAS": "#B970D4",    // Lighter purple for dark backgrounds
        "LVA": "#6A6A6A",    // Lighter gray for dark backgrounds
        "MIN": "#5A9AE0",    // Brighter blue for dark backgrounds
        "NYL": "#4DBBA3",    // Moderately bright teal for dark backgrounds (readable)
        "PHX": "#6A4A9A",    // Lighter purple for dark backgrounds
        "SEA": "#7A9B82",    // Lighter green for dark backgrounds
        "WAS": "#FF4A70"     // Same as Atlanta for dark backgrounds
    ]
    
    /// Dark mode UI colors
    static let darkPrimaryText = "#F9FAFB"      // Light text for dark backgrounds
    static let darkSecondaryText = "#D1D5DB"    // Medium light text for dark backgrounds
    static let darkLightText = "#9CA3AF"        // Gray text for dark backgrounds
    static let darkCardBackground = "#1F2937"   // Dark background for cards
    static let darkSeparatorColor = "#374151"   // Dark separator lines
    
    // MARK: - Color Access Methods
    
    /// Get enhanced team color that maintains brand identity while improving readability
    /// - Parameters:
    ///   - teamAbbreviation: Team abbreviation (e.g., "NYL")
    ///   - colorScheme: Current color scheme (light or dark)
    /// - Returns: SwiftUI Color with enhanced readability for the current theme
    static func teamColor(for teamAbbreviation: String, colorScheme: ColorScheme = .light) -> Color {
        let colorMap = colorScheme == .dark ? darkModeTeamColors : enhancedTeamColors
        let fallbackColor = colorScheme == .dark ? "#FF8A5B" : wnbaOrange
        
        if let hexColor = colorMap[teamAbbreviation] {
            return Color(hex: hexColor) ?? (colorScheme == .dark ? .orange : .blue)
        }
        return Color(hex: fallbackColor) ?? .orange
    }
    
    /// Get enhanced team color that maintains brand identity while improving readability (legacy method)
    /// - Parameter teamAbbreviation: Team abbreviation (e.g., "NYL")
    /// - Returns: SwiftUI Color with enhanced readability
    static func teamColor(for teamAbbreviation: String) -> Color {
        return teamColor(for: teamAbbreviation, colorScheme: .light)
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
    
    // MARK: - Adaptive Colors (Color Scheme Aware)
    
    /// Adaptive team color that responds to color scheme
    /// - Parameters:
    ///   - teamAbbreviation: Team abbreviation
    ///   - colorScheme: Current color scheme
    /// - Returns: Adaptive color for the team
    static func adaptiveTeamColor(for teamAbbreviation: String, colorScheme: ColorScheme) -> Color {
        return teamColor(for: teamAbbreviation, colorScheme: colorScheme)
    }
    
    /// Adaptive primary text color
    /// - Parameter colorScheme: Current color scheme
    /// - Returns: Adaptive primary text color
    static func adaptivePrimaryText(colorScheme: ColorScheme) -> Color {
        let colorHex = colorScheme == .dark ? darkPrimaryText : primaryText
        return Color(hex: colorHex) ?? .primary
    }
    
    /// Adaptive secondary text color
    /// - Parameter colorScheme: Current color scheme
    /// - Returns: Adaptive secondary text color
    static func adaptiveSecondaryText(colorScheme: ColorScheme) -> Color {
        let colorHex = colorScheme == .dark ? darkSecondaryText : secondaryText
        return Color(hex: colorHex) ?? .secondary
    }
    
    /// Adaptive light text color
    /// - Parameter colorScheme: Current color scheme
    /// - Returns: Adaptive light text color
    static func adaptiveLightText(colorScheme: ColorScheme) -> Color {
        let colorHex = colorScheme == .dark ? darkLightText : lightText
        return Color(hex: colorHex) ?? .gray
    }
    
    /// Adaptive card background color
    /// - Parameter colorScheme: Current color scheme
    /// - Returns: Adaptive card background color
    static func adaptiveCardBackground(colorScheme: ColorScheme) -> Color {
        let colorHex = colorScheme == .dark ? darkCardBackground : cardBackground
        return Color(hex: colorHex) ?? .clear
    }
    
    /// Adaptive separator color
    /// - Parameter colorScheme: Current color scheme
    /// - Returns: Adaptive separator color
    static func adaptiveSeparator(colorScheme: ColorScheme) -> Color {
        let colorHex = colorScheme == .dark ? darkSeparatorColor : separatorColor
        return Color(hex: colorHex) ?? .gray
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
