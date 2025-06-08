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
    
    // MARK: - Memory Audit Tests
    
    func testMemoryAuditTracking() {
        let memoryAudit = MemoryAudit.shared
        
        // Create an object to track
        let object = NSObject()
        let description = "Test Object"
        
        // Track the object
        memoryAudit.trackObject(object, description: description)
        
        // Perform an audit (should not crash)
        memoryAudit.performAudit()
        
        // Stop tracking
        memoryAudit.stopTracking(object)
        
        // Perform another audit (should not crash)
        memoryAudit.performAudit()
    }
    
    func testMemoryUsageFormatting() {
        let memoryAudit = MemoryAudit.shared
        
        // Test KB formatting
        let kbSize: UInt64 = 1024 * 5 // 5 KB
        let kbFormatted = memoryAudit.formatMemorySize(kbSize)
        XCTAssertTrue(kbFormatted.contains("KB"))
        XCTAssertFalse(kbFormatted.contains("MB"))
        
        // Test MB formatting
        let mbSize: UInt64 = 1024 * 1024 * 10 // 10 MB
        let mbFormatted = memoryAudit.formatMemorySize(mbSize)
        XCTAssertTrue(mbFormatted.contains("MB"))
        XCTAssertFalse(mbFormatted.contains("KB"))
    }
    
    func testNSObjectMemoryTrackingExtension() {
        // Create a test object
        let object = NSObject()
        
        // Track it
        object.trackForMemoryLeak()
        
        // Stop tracking
        object.stopMemoryTracking()
        
        // Track with custom description
        object.trackForMemoryLeak(description: "Custom description")
        
        // Stop tracking again
        object.stopMemoryTracking()
    }
    
    func testMemoryLeakDetection() {
        let memoryAudit = MemoryAudit.shared
        
        // Create a scope to test weak references
        autoreleasepool {
            // Create an object that will go out of scope
            let tempObject = NSObject()
            memoryAudit.trackObject(tempObject, description: "Temporary object")
        }
        
        // After the autorelease pool, tempObject should be deallocated
        // Perform an audit to clean up the reference
        memoryAudit.performAudit()
        
        // Create a retained object
        let retainedObject = NSObject()
        memoryAudit.trackObject(retainedObject, description: "Retained object")
        
        // This object should still be tracked
        memoryAudit.performAudit()
        
        // Clean up
        memoryAudit.stopTracking(retainedObject)
    }
    
    
    func testCurrentMemoryUsage() {
        let memoryAudit = MemoryAudit.shared
        
        // Get current memory usage
        let usage = memoryAudit.currentMemoryUsage()
        
        // It should be greater than zero
        XCTAssertGreaterThan(usage, 0)
        
        // The formatted string should not be empty
        let formatted = memoryAudit.formatMemorySize(usage)
        XCTAssertFalse(formatted.isEmpty)
    }
    
    // End of UtilitiesTests
}
