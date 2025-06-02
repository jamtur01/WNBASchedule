import Foundation

/// Version information for the WNBASchedule app
enum AppVersion {
    /// Current version of the app
    static let version = "1.0.0"
    
    /// Build number, typically incremented for each build
    static let build = "20250602"
    
    /// Full version string including build number
    static var fullVersion: String {
        return "\(version) (\(build))"
    }
    
    /// Version string for display in the app
    static var displayVersion: String {
        return "v\(version)"
    }
}
