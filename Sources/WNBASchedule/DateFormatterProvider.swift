import Foundation
import SwiftDate

// Keep the original DateFormatter extensions for backward compatibility
extension DateFormatter {
    /// Provides a shared date formatter with the WNBA schedule format
    static let sharedScheduleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d, yyyy" // Space after day abbreviation, not comma
        return formatter
    }()
    
    /// Provides a shared time formatter
    static let sharedTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// Add SwiftDate extensions for more convenient date formatting
extension Date {
    /// Convert a Date to a SwiftDate DateInRegion for easier formatting
    func toSwiftDate() -> DateInRegion {
        return DateInRegion(self, region: Region.current)
    }
    
    /// Format a date using the WNBA schedule format
    func toScheduleString() -> String {
        return self.toSwiftDate().toString(.custom("EEE MMM d, yyyy"))
    }
    
    /// Format a time using the short time format
    func toTimeString() -> String {
        return self.toSwiftDate().toString(.custom("h:mm a"))
    }
    
    /// Format a date and time together
    func toScheduleTimeString() -> String {
        return "\(self.toScheduleString()) at \(self.toTimeString())"
    }
}