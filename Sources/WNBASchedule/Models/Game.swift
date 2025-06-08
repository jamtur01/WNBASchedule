import Foundation
import SwiftDate
import os.log

// MARK: - API Response Models

/// Top-level response from the NBA API
struct ScheduleResponse: Codable {
    let results: Results
}

/// Container for schedule data
struct Results: Codable {
    let schedule: [Game]
}

// MARK: - Game Model

/// Represents a WNBA game
struct Game: Codable, Identifiable {
    // MARK: - Required Properties
    
    /// Unique identifier for the game
    let gid: String
    
    /// Time in Eastern timezone
    let easternTime: String
    
    /// Time in UTC
    let utcTime: String
    
    /// Unix timestamp (milliseconds)
    let timestamp: Int64
    
    /// Home team
    let home: Team
    
    /// Visiting team
    let visitor: Team
    
    /// Game state (0: upcoming, 1: in progress, 2: halftime, 3: completed)
    let state: Int
    
    // MARK: - Optional Properties
    
    /// Internal ID
    let id: Int?
    
    /// Game type (regular season, playoff, etc.)
    let type: String?
    
    /// Game title
    let title: String?
    
    /// Time in home team's timezone
    let homeTime: String?
    
    /// Time in visitor team's timezone
    let visitorTime: String?
    
    /// Broadcast providers
    let providers: [Provider]?
    
    /// Arena name
    let arenaName: String?
    
    /// Arena state
    let arenaState: String?
    
    /// Arena city
    let arenaCity: String?
    
    /// Game status text
    let gameStatusText: String?
    
    /// Game label
    let gameLabel: String?
    
    /// Game sublabel
    let gameSubLabel: String?
    
    /// Series text (for playoffs)
    let seriesText: String?
    
    /// Series game number (for playoffs)
    let seriesGameNumber: String?
    
    /// If game is necessary (for playoffs)
    let ifNecessary: Bool?
    
    /// Game subtype
    let gameSubtype: String?
    
    /// Game name
    let name: String?
    
    /// Theme night label
    let themeNightLabel: String?
    
    /// Ticket URL
    let ticketUrl: String?
    
    /// Whether the game is available on League Pass
    let isLeaguePassGame: Bool?
    
    /// League Pass video link
    let leaguePassVideoLink: String?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case type, gid, title, easternTime, homeTime, visitorTime, utcTime, timestamp
        case home, visitor, providers, state, arenaName, arenaState, arenaCity
        case gameStatusText, gameLabel, gameSubLabel, seriesText, seriesGameNumber
        case ifNecessary, gameSubtype, id, name, themeNightLabel, ticketUrl
        case isLeaguePassGame, leaguePassVideoLink
    }
    
    // MARK: - Computed Properties
    
    /// The game time in the user's local timezone
    var localGameTime: Date {
        let logger = Logger(subsystem: "com.wnbaschedule", category: "Game")
        
        // Use the timestamp as primary source
        // NBA API provides timestamps in milliseconds
        let timestampDate = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        
        if let date = utcTime.toISODate(region: Region.UTC) {
            if abs(date.date.timeIntervalSince(timestampDate)) > 300 { // 5 minute difference
                logger.warning("Significant difference between timestamp date (\(timestampDate)) and UTC string date (\(date.date))")
            }
            return timestampDate
        } else {
            logger.warning("Failed to parse UTC time string: \(utcTime), using timestamp fallback")
        }
        
        return timestampDate
    }
    
    /// The game time as a DateInRegion for easier formatting
    var gameTimeInRegion: DateInRegion {
        let userPreferences = DependencyContainer.shared.userPreferences
        
        // Use the user's preference for timezone
        if userPreferences.useLocalTimeZone {
            return localGameTime.toSwiftDate()
        } else {
            // Use Eastern time (NBA's default)
            let region = Region.init(zone: Zones.americaNewYork)
            return localGameTime.in(region: region)
        }
    }
    
    /// Formatted game date for display
    var formattedGameDate: String {
        return gameTimeInRegion.toString(.custom("EEE MMM d, yyyy"))
    }
    
    /// Formatted game time for display
    var formattedGameTime: String {
        return gameTimeInRegion.toString(.custom("h:mm a"))
    }
    
    /// Formatted date and time
    var formattedDateTime: String {
        return "\(formattedGameDate) at \(formattedGameTime)"
    }
    
    /// Whether the game is completed
    var isCompleted: Bool {
        return state == 3
    }
    
    /// Whether the game is in progress
    var isInProgress: Bool {
        return state == 1 || state == 2
    }
    
    /// Whether the game is upcoming
    var isUpcoming: Bool {
        return state == 0
    }
    
    /// Game status description
    var statusDescription: String {
        switch state {
        case 0:
            return "Upcoming"
        case 1:
            return "In Progress"
        case 2:
            return "Halftime"
        case 3:
            return "Final"
        default:
            return "Unknown"
        }
    }
    
    /// Arena location if available
    var arenaLocation: String? {
        if let arenaName = arenaName {
            var location = arenaName
            
            if let city = arenaCity {
                location += ", \(city)"
                
                if let state = arenaState {
                    location += ", \(state)"
                }
            }
            
            return location
        }
        return nil
    }
    
    /// URL for the game on the WNBA website
    var gameURL: URL? {
        return URL(string: "https://www.wnba.com/game/\(gid)/")
    }
}

// MARK: - Team Model

/// Represents a WNBA team
struct Team: Codable {
    /// Team ID
    let tid: Int?
    
    /// Team abbreviation (e.g., "NYL")
    let abbr: String
    
    /// Team city
    let city: String
    
    /// Team name
    let name: String
    
    /// Team score (only available for completed or in-progress games)
    let score: Int?
    
    /// Team losses
    let losses: Int?
    
    /// Team wins
    let wins: Int?
    
    /// Full team name (city + name)
    var fullName: String {
        return "\(city) \(name)"
    }
    
    /// Team record as a string (if available)
    var recordString: String? {
        if let wins = wins, let losses = losses {
            return "\(wins)-\(losses)"
        }
        return nil
    }
    
    /// Team color from TeamManager
    var primaryColor: String {
        return TeamManager.getTeamColor(abbreviation: abbr)
    }
}

// MARK: - Provider Model

/// Represents a broadcast provider for a game
struct Provider: Codable {
    /// Broadcaster scope (national, local, etc.)
    let broadcasterScope: String
    
    /// Broadcaster media type (TV, streaming, etc.)
    let broadcasterMedia: String
    
    /// Broadcaster ID
    let broadcasterId: Int
    
    /// Broadcaster display name
    let broadcasterDisplay: String
    
    /// Broadcaster abbreviation
    let broadcasterAbbreviation: String
    
    /// Broadcaster description
    let broadcasterDescription: String
    
    /// Tape delay comments
    let tapeDelayComments: String
    
    /// Broadcaster video link
    let broadcasterVideoLink: String
    
    /// Broadcaster team ID
    let broadcasterTeamId: Int
    
    /// Broadcaster ranking
    let broadcasterRanking: Int
    
    /// Whether this is a national broadcast
    var isNational: Bool {
        return broadcasterScope.lowercased() == "natl"
    }
    
    /// Whether this is a local broadcast
    var isLocal: Bool {
        return broadcasterScope.lowercased() == "local"
    }
    
}