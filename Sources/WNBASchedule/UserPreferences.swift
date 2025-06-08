import Foundation
import os.log

/// Manages user preferences for the application
class UserPreferences {
    // MARK: - Properties
    
    /// The user's favorite team abbreviation (default: "NYL" for NY Liberty)
    var favoriteTeam: String {
        didSet {
            if oldValue != favoriteTeam {
                savePreferences()
            }
        }
    }
    
    /// The number of past games to display
    var pastGamesToShow: Int {
        didSet {
            if oldValue != pastGamesToShow {
                savePreferences()
            }
        }
    }
    
    /// The number of upcoming games to display
    var upcomingGamesToShow: Int {
        didSet {
            if oldValue != upcomingGamesToShow {
                savePreferences()
            }
        }
    }
    
    /// Whether to show game times in the user's local timezone
    var useLocalTimeZone: Bool {
        didSet {
            if oldValue != useLocalTimeZone {
                savePreferences()
            }
        }
    }
    
    /// The preferred language for the app (locale identifier)
    var preferredLanguage: String {
        didSet {
            if oldValue != preferredLanguage {
                savePreferences()
                // Update the app's locale
                Localization.changeLocale(to: preferredLanguage)
            }
        }
    }
    
    // MARK: - Constants
    private let defaultFavoriteTeam = "NYL"
    private let defaultPastGamesToShow = 10
    private let defaultUpcomingGamesToShow = 5
    private let defaultUseLocalTimeZone = true
    private let defaultPreferredLanguage = "en"
    
    private let favoriteTeamKey = "favoriteTeam"
    private let pastGamesToShowKey = "pastGamesToShow"
    private let upcomingGamesToShowKey = "upcomingGamesToShow"
    private let useLocalTimeZoneKey = "useLocalTimeZone"
    private let preferredLanguageKey = "preferredLanguage"
    
    private let logger = Logger(subsystem: "com.wnbaschedule", category: "UserPreferences")
    
    // MARK: - Initialization
    
    init() {
        // Load saved preferences or use defaults
        let userDefaults = UserDefaults.standard
        
        self.favoriteTeam = userDefaults.string(forKey: favoriteTeamKey) ?? defaultFavoriteTeam
        self.pastGamesToShow = userDefaults.integer(forKey: pastGamesToShowKey)
        self.upcomingGamesToShow = userDefaults.integer(forKey: upcomingGamesToShowKey)
        self.useLocalTimeZone = userDefaults.bool(forKey: useLocalTimeZoneKey)
        self.preferredLanguage = userDefaults.string(forKey: preferredLanguageKey) ?? defaultPreferredLanguage
        
        // If these values are 0, it means they weren't set before, so use defaults
        if self.pastGamesToShow == 0 {
            self.pastGamesToShow = defaultPastGamesToShow
        }
        
        if self.upcomingGamesToShow == 0 {
            self.upcomingGamesToShow = defaultUpcomingGamesToShow
        }
        
        logger.info("""
            Loaded user preferences: team=\(self.favoriteTeam), language=\(self.preferredLanguage), \
            pastGames=\(self.pastGamesToShow), upcomingGames=\(self.upcomingGamesToShow)
            """)
    }
    
    // MARK: - Methods
    
    /// Saves the current preferences to UserDefaults
    func savePreferences() {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(favoriteTeam, forKey: favoriteTeamKey)
        userDefaults.set(pastGamesToShow, forKey: pastGamesToShowKey)
        userDefaults.set(upcomingGamesToShow, forKey: upcomingGamesToShowKey)
        userDefaults.set(useLocalTimeZone, forKey: useLocalTimeZoneKey)
        userDefaults.set(preferredLanguage, forKey: preferredLanguageKey)
        
        logger.info("""
            Saved user preferences: team=\(self.favoriteTeam), language=\(self.preferredLanguage), \
            pastGames=\(self.pastGamesToShow), upcomingGames=\(self.upcomingGamesToShow)
            """)
    }
    
    /// Resets all preferences to default values
    func resetToDefaults() {
        favoriteTeam = defaultFavoriteTeam
        pastGamesToShow = defaultPastGamesToShow
        upcomingGamesToShow = defaultUpcomingGamesToShow
        useLocalTimeZone = defaultUseLocalTimeZone
        preferredLanguage = defaultPreferredLanguage
        
        savePreferences()
        logger.info("Reset user preferences to defaults")
    }
    
    /// Returns a list of available languages
    var availableLanguages: [String] {
        return Localization.supportedLocaleIdentifiers
    }
    
    /// Changes the app's language
    /// - Parameter languageCode: The language code to change to (e.g., "en", "es")
    func changeLanguage(to languageCode: String) {
        guard availableLanguages.contains(languageCode) else {
            logger.warning("Attempted to change to unsupported language: \(languageCode)")
            return
        }
        
        preferredLanguage = languageCode
        // The property observer will handle saving and updating the locale
    }
}
