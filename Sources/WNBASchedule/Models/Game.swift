import Foundation
import SwiftDate

struct ScheduleResponse: Codable {
    let results: Results
}

struct Results: Codable {
    let schedule: [Game]
}

struct Game: Codable, Identifiable {
    let id: Int?
    let type: String?
    let gid: String
    let title: String?
    let easternTime: String
    let homeTime: String?
    let visitorTime: String?
    let utcTime: String
    let timestamp: Int64
    let home: Team
    let visitor: Team
    let providers: [Provider]?
    let state: Int
    let arenaName: String?
    let arenaState: String?
    let arenaCity: String?
    let gameStatusText: String?
    let gameLabel: String?
    let gameSubLabel: String?
    let seriesText: String?
    let seriesGameNumber: String?
    let ifNecessary: Bool?
    let gameSubtype: String?
    let name: String?
    let themeNightLabel: String?
    let ticketUrl: String?
    let isLeaguePassGame: Bool?
    let leaguePassVideoLink: String?
    
    enum CodingKeys: String, CodingKey {
        case type, gid, title, easternTime, homeTime, visitorTime, utcTime, timestamp
        case home, visitor, providers, state, arenaName, arenaState, arenaCity
        case gameStatusText, gameLabel, gameSubLabel, seriesText, seriesGameNumber
        case ifNecessary, gameSubtype, id, name, themeNightLabel, ticketUrl
        case isLeaguePassGame, leaguePassVideoLink
    }
    
    var localGameTime: Date {
        // Using SwiftDate for better date parsing
        if let date = utcTime.toDate("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", region: Region.UTC) {
            return date.date
        }
        
        if let date = utcTime.toDate("yyyy-MM-dd'T'HH:mm:ss'Z'", region: Region.UTC) {
            return date.date
        }
        
        // If all else fails, use the timestamp (milliseconds since epoch)
        return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
    }
    
    // Add a convenience method to get the game time as a DateInRegion
    var gameTimeInRegion: DateInRegion {
        return localGameTime.toSwiftDate()
    }
    
    // Format the game date for display
    var formattedGameDate: String {
        return gameTimeInRegion.toString(.custom("EEE MMM d, yyyy"))
    }
    
    // Format the game time for display
    var formattedGameTime: String {
        return gameTimeInRegion.toString(.custom("h:mm a"))
    }
    
    // Format both date and time
    var formattedDateTime: String {
        return "\(formattedGameDate) at \(formattedGameTime)"
    }
    
    var isCompleted: Bool {
        return state == 3
    }
}

struct Team: Codable {
    let tid: Int?
    let abbr: String
    let city: String
    let name: String
    let score: Int?
    let losses: Int?
    let wins: Int?
    
    var fullName: String {
        return "\(city) \(name)"
    }
}

struct Provider: Codable {
    let broadcasterScope: String
    let broadcasterMedia: String
    let broadcasterId: Int
    let broadcasterDisplay: String
    let broadcasterAbbreviation: String
    let broadcasterDescription: String
    let tapeDelayComments: String
    let broadcasterVideoLink: String
    let broadcasterTeamId: Int
    let broadcasterRanking: Int
}