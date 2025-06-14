import Foundation

// MARK: - Boxscore Response Models

/// Top-level response from the boxscore API
struct BoxscoreResponse: Codable {
    let meta: BoxscoreMeta
    let game: BoxscoreGame
}

/// Metadata for the boxscore response
struct BoxscoreMeta: Codable {
    let version: Int
    let code: Int
    let request: String
    let time: String
}

/// Detailed game information from boxscore
struct BoxscoreGame: Codable {
    let gameId: String
    let gameTimeLocal: String
    let gameTimeUTC: String
    let gameTimeHome: String
    let gameTimeAway: String
    let gameEt: String
    let duration: Int?
    let gameCode: String
    let gameStatusText: String
    let gameStatus: Int
    let regulationPeriods: Int
    let period: Int
    let gameClock: String
    let attendance: Int?
    let sellout: String?
    let arena: BoxscoreArena?
    let homeTeam: BoxscoreTeam
    let awayTeam: BoxscoreTeam
}

/// Arena information
struct BoxscoreArena: Codable {
    let arenaId: Int
    let arenaName: String
    let arenaCity: String
    let arenaState: String
    let arenaCountry: String
    let arenaTimezone: String
}

/// Team information with live scores
struct BoxscoreTeam: Codable {
    let teamId: Int
    let teamName: String
    let teamCity: String
    let teamTricode: String
    let score: Int
    let inBonus: String?
    let timeoutsRemaining: Int?
    let periods: [BoxscorePeriod]?
}

/// Period scoring information
struct BoxscorePeriod: Codable {
    let period: Int
    let periodType: String
    let score: Int
}
