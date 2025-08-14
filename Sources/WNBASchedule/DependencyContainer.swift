import Foundation

/// A singleton container for managing application dependencies
class DependencyContainer {
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    // MARK: - Dependencies
    var nbaClient: NBAClientProtocol
    var scheduleManager: ScheduleManagerProtocol
    var userPreferences: UserPreferences
    var apiCache: APICacheProtocol
    
    // MARK: - Initialization
    private init() {
        self.apiCache = APICache()
        self.userPreferences = UserPreferences()
        self.nbaClient = NBAClient(cache: apiCache)
        self.scheduleManager = ScheduleManager(client: nbaClient, userPreferences: userPreferences)
    }
    
    // MARK: - Testing Support
    /// Resets the container with mock implementations for testing
    func configureMockServices(
        nbaClient: NBAClientProtocol? = nil,
        scheduleManager: ScheduleManagerProtocol? = nil,
        userPreferences: UserPreferences? = nil,
        apiCache: APICacheProtocol? = nil
    ) {
        if let nbaClient = nbaClient {
            self.nbaClient = nbaClient
        }
        
        if let scheduleManager = scheduleManager {
            self.scheduleManager = scheduleManager
        }
        
        if let userPreferences = userPreferences {
            self.userPreferences = userPreferences
        }
        
        if let apiCache = apiCache {
            self.apiCache = apiCache
        }
    }
}
