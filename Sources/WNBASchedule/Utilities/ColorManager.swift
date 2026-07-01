import SwiftUI
import AppKit

/// Manages color schemes for better readability while maintaining team color identity.
///
/// Every foreground color is tuned to meet WCAG AA contrast (>= 4.5:1) against the menu's
/// light and dark backgrounds. Team colors keep brand identity while staying legible.
struct ColorManager {

    // MARK: - Team Colors (Light Mode)

    /// Team colors tuned for >= 4.5:1 contrast on the light menu background.
    private static let lightTeamColors: [String: String] = [
        "ATL": "#E31E45",
        "CHI": "#1F6FBF",
        "CON": "#C2410C",
        "DAL": "#5C6E0E",
        "GSV": "#6B5BA6",
        "IND": "#1A4B8C",
        "LAS": "#8A4FA8",
        "LVA": "#2A2A2A",
        "MIN": "#2E6699",
        "NYL": "#1F7A63",
        "PDX": "#C31333",
        "PHX": "#3D2A65",
        "SEA": "#4A6B52",
        "TOR": "#6B1C3D",
        "WAS": "#B01E3C"
    ]

    // MARK: - Team Colors (Dark Mode)

    /// Team colors tuned for >= 4.5:1 contrast on the dark menu background.
    private static let darkTeamColors: [String: String] = [
        "ATL": "#FF4A70",
        "CHI": "#6BB6FF",
        "CON": "#FF8A5B",
        "DAL": "#C4D630",
        "GSV": "#D4C4F0",
        "IND": "#5A8AD8",
        "LAS": "#B970D4",
        "LVA": "#8A8A8A",
        "MIN": "#5A9AE0",
        "NYL": "#4DBBA3",
        "PDX": "#FF4757",
        "PHX": "#9A7BC8",
        "SEA": "#7A9B82",
        "TOR": "#D46A8A",
        "WAS": "#FF6A88"
    ]

    // MARK: - Brand Colors

    /// WNBA brand orange used as text / section-header color (light mode).
    private static let brandTextLight = "#C2410C"
    /// WNBA brand orange used as text / section-header color (dark mode).
    private static let brandTextDark = "#FF7043"
    /// Fixed deep orange for filled buttons drawing white text (>= 4.5:1 with white).
    private static let brandButtonFillHex = "#C2410C"
    /// Broadcast (League Pass / TV) accent — text color, light mode.
    private static let broadcastLight = "#7C3AED"
    /// Broadcast accent — text color, dark mode.
    private static let broadcastDark = "#C4B5FD"
    /// Fixed broadcast fill for the hovered button drawing white text.
    private static let broadcastFillHex = "#7C3AED"

    // MARK: - State Colors (Win / Loss / Live)

    private static let winLight = "#15803D"
    private static let winDark = "#4ADE80"
    private static let lossLight = "#DC2626"
    private static let lossDark = "#F87171"
    private static let liveLight = "#C2410C"
    private static let liveDark = "#FB923C"

    // MARK: - Text Colors

    private static let primaryTextLight = "#1F2937"
    private static let primaryTextDark = "#F9FAFB"
    private static let secondaryTextLight = "#4B5563"
    private static let secondaryTextDark = "#D1D5DB"
    private static let lightTextLight = "#6B7280"
    private static let lightTextDark = "#9CA3AF"

    // MARK: - Surfaces

    private static let cardBackgroundLight = "#F9FAFB"
    private static let cardBackgroundDark = "#1F2937"
    private static let separatorLight = "#E5E7EB"
    private static let separatorDark = "#374151"

    // MARK: - Team Colors

    /// Team color tuned for the given scheme, preserving brand identity while staying legible.
    /// - Parameters:
    ///   - teamAbbreviation: Team abbreviation (e.g. "NYL").
    ///   - colorScheme: Current color scheme.
    /// - Returns: A legible SwiftUI color for the team.
    static func teamColor(for teamAbbreviation: String, colorScheme: ColorScheme) -> Color {
        let map = colorScheme == .dark ? darkTeamColors : lightTeamColors
        if let hex = map[teamAbbreviation], let color = Color(hex: hex) {
            return color
        }
        return wnbaBrandColor(colorScheme)
    }

    /// Adaptive team color (alias kept for call-site clarity).
    static func adaptiveTeamColor(for teamAbbreviation: String, colorScheme: ColorScheme) -> Color {
        return teamColor(for: teamAbbreviation, colorScheme: colorScheme)
    }

    // MARK: - Brand

    /// WNBA brand color for text and section headers.
    static func wnbaBrandColor(_ colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? brandTextDark : brandTextLight) ?? .orange
    }

    /// Fixed brand fill for buttons that draw white text on top.
    static var brandButtonFill: Color {
        Color(hex: brandButtonFillHex) ?? .orange
    }

    /// Broadcast (League Pass / TV) accent for the given scheme.
    static func broadcastColor(_ colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? broadcastDark : broadcastLight) ?? .purple
    }

    /// Fixed broadcast fill for the hovered button drawing white text on top.
    static var broadcastFill: Color {
        Color(hex: broadcastFillHex) ?? .purple
    }

    // MARK: - State

    /// Win color for the given scheme.
    static func winColor(_ colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? winDark : winLight) ?? .green
    }

    /// Loss color for the given scheme.
    static func lossColor(_ colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? lossDark : lossLight) ?? .red
    }

    /// Live / in-progress color for the given scheme.
    static func liveColor(_ colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? liveDark : liveLight) ?? .orange
    }

    // MARK: - Adaptive Text

    /// Adaptive primary text color.
    static func adaptivePrimaryText(colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? primaryTextDark : primaryTextLight) ?? .primary
    }

    /// Adaptive secondary text color.
    static func adaptiveSecondaryText(colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? secondaryTextDark : secondaryTextLight) ?? .secondary
    }

    /// Adaptive light text color for timestamps and metadata.
    static func adaptiveLightText(colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? lightTextDark : lightTextLight) ?? .gray
    }

    // MARK: - Adaptive Surfaces

    /// Adaptive card background color.
    static func adaptiveCardBackground(colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? cardBackgroundDark : cardBackgroundLight) ?? .clear
    }

    /// Adaptive separator color.
    static func adaptiveSeparator(colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? separatorDark : separatorLight) ?? .gray
    }

    // MARK: - Contrast Helper

    /// Returns black or white, whichever is more legible on top of the given fill color.
    /// - Parameter color: The background fill.
    /// - Returns: `.black` or `.white` for maximum contrast.
    static func contrastingText(on color: Color) -> Color {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return .white }
        func channel(_ value: CGFloat) -> Double {
            let normalized = Double(value)
            return normalized <= 0.03928 ? normalized / 12.92 : pow((normalized + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * channel(srgb.redComponent)
            + 0.7152 * channel(srgb.greenComponent)
            + 0.0722 * channel(srgb.blueComponent)
        return luminance > 0.179 ? .black : .white
    }
}

// MARK: - Color Extension (Enhanced)

extension Color {
    /// Initialize a color from a hex string.
    ///
    /// Accepts `#RGB`, `#RRGGBB`, and `#RRGGBBAA` (with or without a leading `#`).
    /// Returns `nil` for malformed input or unexpected lengths.
    /// - Parameter hex: Hex color string.
    init?(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&value) else { return nil }

        let red, green, blue, alpha: Double
        switch sanitized.count {
        case 3: // RGB (4 bits per channel)
            red = Double((value & 0xF00) >> 8) / 15.0
            green = Double((value & 0x0F0) >> 4) / 15.0
            blue = Double(value & 0x00F) / 15.0
            alpha = 1.0
        case 6: // RRGGBB
            red = Double((value & 0xFF0000) >> 16) / 255.0
            green = Double((value & 0x00FF00) >> 8) / 255.0
            blue = Double(value & 0x0000FF) / 255.0
            alpha = 1.0
        case 8: // RRGGBBAA
            red = Double((value & 0xFF000000) >> 24) / 255.0
            green = Double((value & 0x00FF0000) >> 16) / 255.0
            blue = Double((value & 0x0000FF00) >> 8) / 255.0
            alpha = Double(value & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
