import Foundation

/// Manages WNBA team data
struct TeamManager {
    /// Represents a WNBA team
    struct TeamInfo {
        let abbreviation: String
        let fullName: String
        let city: String
        let nickname: String
    }
    
    /// All WNBA teams
    private static let allTeamsArray: [TeamInfo] = [
        TeamInfo(abbreviation: "ATL", fullName: "Atlanta Dream", city: "Atlanta", nickname: "Dream"),
        TeamInfo(abbreviation: "CHI", fullName: "Chicago Sky", city: "Chicago", nickname: "Sky"),
        TeamInfo(abbreviation: "CON", fullName: "Connecticut Sun", city: "Connecticut", nickname: "Sun"),
        TeamInfo(abbreviation: "DAL", fullName: "Dallas Wings", city: "Dallas", nickname: "Wings"),
        TeamInfo(abbreviation: "GSV", fullName: "Golden State Valkyries", city: "San Francisco", nickname: "Valkyries"),
        TeamInfo(abbreviation: "IND", fullName: "Indiana Fever", city: "Indiana", nickname: "Fever"),
        TeamInfo(abbreviation: "LAS", fullName: "Los Angeles Sparks", city: "Los Angeles", nickname: "Sparks"),
        TeamInfo(abbreviation: "LVA", fullName: "Las Vegas Aces", city: "Las Vegas", nickname: "Aces"),
        TeamInfo(abbreviation: "MIN", fullName: "Minnesota Lynx", city: "Minnesota", nickname: "Lynx"),
        TeamInfo(abbreviation: "NYL", fullName: "New York Liberty", city: "New York", nickname: "Liberty"),
        TeamInfo(abbreviation: "PHX", fullName: "Phoenix Mercury", city: "Phoenix", nickname: "Mercury"),
        TeamInfo(abbreviation: "PDX", fullName: "Portland Fire", city: "Portland", nickname: "Fire"),
        TeamInfo(abbreviation: "SEA", fullName: "Seattle Storm", city: "Seattle", nickname: "Storm"),
        TeamInfo(abbreviation: "TOR", fullName: "Toronto Tempo", city: "Toronto", nickname: "Tempo"),
        TeamInfo(abbreviation: "WAS", fullName: "Washington Mystics", city: "Washington", nickname: "Mystics")
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

    /// URL for a team's favicon logo on the WNBA CDN.
    /// - Parameters:
    ///   - abbreviation: The team's abbreviation (e.g. "NYL").
    ///   - size: The icon pixel size (e.g. 16, 32).
    /// - Returns: The favicon URL, or nil if it can't be built.
    static func faviconURL(abbreviation: String, size: Int) -> URL? {
        return URL(string: "https://cdn.wnba.com/static/next/teams/favicons/\(abbreviation)/icon-\(size).png")
    }
}
