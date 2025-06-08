import Foundation

/// Manages WNBA team data
struct TeamManager {
    /// Represents a WNBA team
    struct TeamInfo {
        let abbreviation: String
        let fullName: String
        let city: String
        let nickname: String
        let primaryColor: String
        let tid: Int
        
        var displayName: String {
            return "\(city) \(nickname)"
        }
    }
    
    /// All WNBA teams
    static let allTeams: [TeamInfo] = [
        TeamInfo(
            abbreviation: "ATL",
            fullName: "Atlanta Dream",
            city: "Atlanta",
            nickname: "Dream",
            primaryColor: "#C8102E",
            tid: 1611661330
        ),
        TeamInfo(
            abbreviation: "CHI",
            fullName: "Chicago Sky",
            city: "Chicago",
            nickname: "Sky",
            primaryColor: "#418FDE",
            tid: 1611661329
        ),
        TeamInfo(
            abbreviation: "CON",
            fullName: "Connecticut Sun",
            city: "Connecticut",
            nickname: "Sun",
            primaryColor: "#FC4C02",
            tid: 1611661323
        ),
        TeamInfo(
            abbreviation: "DAL",
            fullName: "Dallas Wings",
            city: "Dallas",
            nickname: "Wings",
            primaryColor: "#C4D600",
            tid: 1611661321
        ),
        TeamInfo(
            abbreviation: "GSV",
            fullName: "Golden State Valkyries",
            city: "San Francisco",
            nickname: "Valkyries",
            primaryColor: "#AD96DC",
            tid: 1611661331
        ),
        TeamInfo(
            abbreviation: "IND",
            fullName: "Indiana Fever",
            city: "Indiana",
            nickname: "Fever",
            primaryColor: "#041E42",
            tid: 1611661325
        ),
        TeamInfo(
            abbreviation: "LAS",
            fullName: "Los Angeles Sparks",
            city: "Los Angeles",
            nickname: "Sparks",
            primaryColor: "#702F8A",
            tid: 1611661320
        ),
        TeamInfo(
            abbreviation: "LVA",
            fullName: "Las Vegas Aces",
            city: "Las Vegas",
            nickname: "Aces",
            primaryColor: "#010101",
            tid: 1611661319
        ),
        TeamInfo(
            abbreviation: "MIN",
            fullName: "Minnesota Lynx",
            city: "Minnesota",
            nickname: "Lynx",
            primaryColor: "#236192",
            tid: 1611661324
        ),
        TeamInfo(
            abbreviation: "NYL",
            fullName: "New York Liberty",
            city: "New York",
            nickname: "Liberty",
            primaryColor: "#6ECEB2",
            tid: 1611661313
        ),
        TeamInfo(
            abbreviation: "PHX",
            fullName: "Phoenix Mercury",
            city: "Phoenix",
            nickname: "Mercury",
            primaryColor: "#211747",
            tid: 1611661317
        ),
        TeamInfo(
            abbreviation: "SEA",
            fullName: "Seattle Storm",
            city: "Seattle",
            nickname: "Storm",
            primaryColor: "#2C5234",
            tid: 1611661328
        ),
        TeamInfo(
            abbreviation: "WAS",
            fullName: "Washington Mystics",
            city: "Washington",
            nickname: "Mystics",
            primaryColor: "#C8102E",
            tid: 1611661322
        )
    ]

    /// Get team information by abbreviation
    /// - Parameter abbreviation: The team's abbreviation (e.g., "NYL")
    /// - Returns: The team info if found, nil otherwise
    static func getTeamInfo(abbreviation: String) -> TeamInfo? {
        return allTeams.first { $0.abbreviation == abbreviation }
    }
    
    /// Get a team's full name by abbreviation
    /// - Parameter abbreviation: The team's abbreviation (e.g., "NYL")
    /// - Returns: The team's full name (e.g., "New York Liberty")
    static func getTeamFullName(abbreviation: String) -> String {
        if let team = getTeamInfo(abbreviation: abbreviation) {
            return team.fullName
        }
        return abbreviation // Return the abbreviation if team not found
    }
    
    /// Get a team's primary color by abbreviation
    /// - Parameter abbreviation: The team's abbreviation (e.g., "NYL")
    /// - Returns: The team's primary color as a hex string (e.g., "#006BB6")
    static func getTeamColor(abbreviation: String) -> String {
        if let team = getTeamInfo(abbreviation: abbreviation) {
            return team.primaryColor
        }
        return "#000000" // Default to black if team not found
    }
}
