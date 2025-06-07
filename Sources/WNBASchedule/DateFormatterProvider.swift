import Foundation

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