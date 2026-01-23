import Foundation

/// Constants for team selection values used throughout the application
enum TeamSelection {
    /// Special value representing all teams view
    static let allTeams = "ALL"
    
    /// Default team abbreviation (New York Liberty)
    static let defaultTeam = "NYL"
    
    /// Validates if a team abbreviation is valid
    /// - Parameter abbreviation: Team abbreviation to validate
    /// - Returns: True if valid, false otherwise
    static func isValid(_ abbreviation: String) -> Bool {
        if abbreviation == allTeams {
            return true
        }
        return TeamManager.getTeamInfo(abbreviation: abbreviation) != nil
    }
    
    /// Checks if the given abbreviation represents all teams
    /// - Parameter abbreviation: Team abbreviation to check
    /// - Returns: True if represents all teams, false otherwise
    static func isAllTeams(_ abbreviation: String) -> Bool {
        return abbreviation == allTeams
    }
}
