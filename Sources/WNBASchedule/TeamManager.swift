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
    }
    
    /// All WNBA teams
    private static let allTeamsArray: [TeamInfo] = [
        TeamInfo(
            abbreviation: "ATL",
            fullName: "Atlanta Dream",
            city: "Atlanta",
            nickname: "Dream",
            primaryColor: "#C8102E"
        ),
        TeamInfo(
            abbreviation: "CHI",
            fullName: "Chicago Sky",
            city: "Chicago",
            nickname: "Sky",
            primaryColor: "#418FDE"
        ),
        TeamInfo(
            abbreviation: "CON",
            fullName: "Connecticut Sun",
            city: "Connecticut",
            nickname: "Sun",
            primaryColor: "#FC4C02"
        ),
        TeamInfo(
            abbreviation: "DAL",
            fullName: "Dallas Wings",
            city: "Dallas",
            nickname: "Wings",
            primaryColor: "#C4D600"
        ),
        TeamInfo(
            abbreviation: "GSV",
            fullName: "Golden State Valkyries",
            city: "San Francisco",
            nickname: "Valkyries",
            primaryColor: "#AD96DC"
        ),
        TeamInfo(
            abbreviation: "IND",
            fullName: "Indiana Fever",
            city: "Indiana",
            nickname: "Fever",
            primaryColor: "#041E42"
        ),
        TeamInfo(
            abbreviation: "LAS",
            fullName: "Los Angeles Sparks",
            city: "Los Angeles",
            nickname: "Sparks",
            primaryColor: "#702F8A"
        ),
        TeamInfo(
            abbreviation: "LVA",
            fullName: "Las Vegas Aces",
            city: "Las Vegas",
            nickname: "Aces",
            primaryColor: "#010101"
        ),
        TeamInfo(
            abbreviation: "MIN",
            fullName: "Minnesota Lynx",
            city: "Minnesota",
            nickname: "Lynx",
            primaryColor: "#236192"
        ),
        TeamInfo(
            abbreviation: "NYL",
            fullName: "New York Liberty",
            city: "New York",
            nickname: "Liberty",
            primaryColor: "#6ECEB2"
        ),
        TeamInfo(
            abbreviation: "PHX",
            fullName: "Phoenix Mercury",
            city: "Phoenix",
            nickname: "Mercury",
            primaryColor: "#211747"
        ),
        TeamInfo(
            abbreviation: "PDX",
            fullName: "Portland Fire",
            city: "Portland",
            nickname: "Fire",
            primaryColor: "#DC143C"
        ),
        TeamInfo(
            abbreviation: "SEA",
            fullName: "Seattle Storm",
            city: "Seattle",
            nickname: "Storm",
            primaryColor: "#2C5234"
        ),
        TeamInfo(
            abbreviation: "TOR",
            fullName: "Toronto Tempo",
            city: "Toronto",
            nickname: "Tempo",
            primaryColor: "#5C1431"
        ),
        TeamInfo(
            abbreviation: "WAS",
            fullName: "Washington Mystics",
            city: "Washington",
            nickname: "Mystics",
            primaryColor: "#C8102E"
        )
    ]
    
    /// Dictionary lookup for efficient team access
    private static let teamLookup: [String: TeamInfo] = {
        Dictionary(uniqueKeysWithValues: allTeamsArray.map { ($0.abbreviation, $0) })
    }()
    
    /// All WNBA teams (computed property for external access)
    static var allTeams: [TeamInfo] {
        return allTeamsArray
    }

    /// Get team information by abbreviation
    /// - Parameter abbreviation: The team's abbreviation (e.g., "NYL")
    /// - Returns: The team info if found, nil otherwise
    static func getTeamInfo(abbreviation: String) -> TeamInfo? {
        return teamLookup[abbreviation]
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
