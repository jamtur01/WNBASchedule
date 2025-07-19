import Foundation
import SwiftDate

// MARK: - SwiftDate Convenience Extensions
extension Date {
    /// Convert a Date to a SwiftDate DateInRegion for easier formatting
    func toSwiftDate() -> DateInRegion {
        return DateInRegion(self, region: Region.current)
    }
    
    /// Format a date using the WNBA schedule format
    @available(*, deprecated, message: "Use DateFormatting.scheduleDate instead")
    func toScheduleString() -> String {
        return DateFormatting.scheduleDate(from: self)
    }
    
    /// Format a time using the short time format
    @available(*, deprecated, message: "Use DateFormatting.time instead")
    func toTimeString() -> String {
        return DateFormatting.time(from: self)
    }
    
    /// Format a date and time together
    @available(*, deprecated, message: "Use DateFormatting.scheduleDateTime instead")
    func toScheduleTimeString() -> String {
        return DateFormatting.scheduleDateTime(from: self)
    }
}
