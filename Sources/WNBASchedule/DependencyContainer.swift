import Foundation

/// A singleton container for managing application dependencies
class DependencyContainer {
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    // MARK: - Dependencies
    lazy var nbaClient: NBAClientProtocol = {
        return NBAClient(cache: apiCache)
    }()
    
    lazy var scheduleManager: ScheduleManagerProtocol = {
        return ScheduleManager(client: nbaClient)
    }()
    
    lazy var userPreferences: UserPreferences = {
        return UserPreferences()
    }()
    
    lazy var apiCache: APICacheProtocol = {
        return APICache()
    }()
    
    // MARK: - Initialization
    private init() {}
    
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
