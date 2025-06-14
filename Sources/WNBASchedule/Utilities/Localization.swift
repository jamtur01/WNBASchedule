import Foundation
import os.log

/// A utility for handling localization in the app
enum Localization {
    /// The logger for localization-related logs
    private static let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "Localization")
    
    /// Returns a localized string for the given key
    /// - Parameters:
    ///   - key: The localization key
    ///   - comment: A comment to provide context for translators
    /// - Returns: The localized string
    static func string(for key: String, comment: String = "") -> String {
        // Use Bundle.module for localization in Swift Package Manager
        let localizedString = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        
        // Log if we're falling back to the key (indicates missing translation)
        if localizedString == key {
            logger.warning("Missing localization for key: \(key)")
        }
        
        return localizedString
    }
    
    /// Returns a localized string with format arguments
    /// - Parameters:
    ///   - key: The localization key
    ///   - arguments: The arguments to format into the string
    ///   - comment: A comment to provide context for translators
    /// - Returns: The formatted localized string
    static func string(for key: String, arguments: CVarArg..., comment: String = "") -> String {
        let format = string(for: key, comment: comment)
        return String(format: format, arguments: arguments)
    }
    
    /// The current locale identifier
    static var currentLocaleIdentifier: String {
        return Locale.current.identifier
    }
    
    /// The current language code
    static var currentLanguageCode: String {
        return Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    /// The current region code
    static var currentRegionCode: String {
        return Locale.current.region?.identifier ?? "US"
    }
    
    /// Whether the current locale reads right-to-left
    static var isRightToLeft: Bool {
        return Locale.Language(identifier: currentLanguageCode).characterDirection == .rightToLeft
    }
    
    /// A list of supported locale identifiers
    static var supportedLocaleIdentifiers: [String] {
        return Bundle.module.localizations
    }
    
    /// Changes the app's locale to the specified identifier
    /// - Parameter identifier: The locale identifier to change to
    static func changeLocale(to identifier: String) {
        // This is a placeholder - in a real app, you would need to
        // save this preference and restart the app or reload the UI
        UserDefaults.standard.set([identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        logger.info("Changed locale to: \(identifier)")
    }
}

// MARK: - String Extension

extension String {
    /// Returns a localized version of the string
    var localized: String {
        return Localization.string(for: self)
    }
    
    /// Returns a localized version of the string with format arguments
    /// - Parameter arguments: The arguments to format into the string
    /// - Returns: The formatted localized string
    func localized(with arguments: CVarArg...) -> String {
        let format = self.localized
        return String(format: format, arguments: arguments)
    }
}
