import XCTest
@testable import WNBASchedule

final class UtilitiesTests: XCTestCase {
    // MARK: - Localization Tests
    
    func testLocalizationStringRetrieval() {
        // Since we can't easily mock NSLocalizedString in tests,
        // we'll test the extension method functionality
        
        let key = "test.key"
        let localizedString = key.localized
        
        // In tests, this will return the key itself since there's no actual .strings file
        XCTAssertEqual(localizedString, key)
        
        // Test with arguments
        let formattedString = key.localized(with: "arg1", 123)
        XCTAssertTrue(formattedString.contains(key))
    }
    
    func testLocalizationHelperMethods() {
        // Test current locale information
        XCTAssertFalse(Localization.currentLocaleIdentifier.isEmpty)
        XCTAssertFalse(Localization.currentLanguageCode.isEmpty)
        XCTAssertFalse(Localization.currentRegionCode.isEmpty)
        
        // Test RTL detection (this will depend on the test environment)
        if Localization.currentLanguageCode == "ar" || Localization.currentLanguageCode == "he" {
            XCTAssertTrue(Localization.isRightToLeft)
        } else {
            XCTAssertFalse(Localization.isRightToLeft)
        }
        
        // Test supported locales
        XCTAssertFalse(Localization.supportedLocaleIdentifiers.isEmpty)
    }
    
    // End of UtilitiesTests
}
