import Foundation
import SwiftDate

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
        let region = Region(calendar: Calendars.gregorian, zone: Zones.current, locale: Locales.english)
        return self.in(region: region).toString(.custom("h.mm a"))
    }
    
    /// Format a date and time together
    func toScheduleTimeString() -> String {
        return "\(self.toScheduleString()) at \(self.toTimeString())"
    }
}
