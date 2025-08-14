import Foundation
import SwiftDate

/// Centralized date formatting utilities for consistent date/time display
enum DateFormatting {
    // MARK: - Date Formatters
    
    /// Formats a date for schedule display (e.g., "Mon Jan 15, 2025")
    static func scheduleDate(from date: Date, useLocalTimeZone: Bool = true) -> String {
        let region = useLocalTimeZone ? Region.current : Region(zone: Zones.americaNewYork)
        return date.in(region: region).toString(.custom("EEE MMM d, yyyy"))
    }
    
    /// Formats a time for display (e.g., "7.30 PM")
    static func time(from date: Date, useLocalTimeZone: Bool = true) -> String {
        let region = Region(
            calendar: Calendars.gregorian,
            zone: useLocalTimeZone ? Zones.current : Zones.americaNewYork,
            locale: Locales.english
        )
        return date.in(region: region).toString(.custom("h.mm a"))
    }
    
    /// Formats a date and time together (e.g., "Mon Jan 15, 2025 at 7.30 PM")
    static func scheduleDateTime(from date: Date, useLocalTimeZone: Bool = true) -> String {
        return "\(scheduleDate(from: date, useLocalTimeZone: useLocalTimeZone)) at \(time(from: date, useLocalTimeZone: useLocalTimeZone))"
    }
    
    /// Returns a DateInRegion for the given date with appropriate timezone
    static func dateInRegion(from date: Date, useLocalTimeZone: Bool = true) -> DateInRegion {
        if useLocalTimeZone {
            return date.in(region: Region.current)
        } else {
            return date.in(region: Region(zone: Zones.americaNewYork))
        }
    }
    
    /// Formats a relative date string (e.g., "Today", "Tomorrow", "Mon Jan 15")
    static func relativeDate(from date: Date, useLocalTimeZone: Bool = true) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let gameDay = calendar.startOfDay(for: date)
        
        if gameDay == today {
            return Localization.string(for: "TODAY")
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today), gameDay == tomorrow {
            return Localization.string(for: "TOMORROW")
        } else {
            return scheduleDate(from: date, useLocalTimeZone: useLocalTimeZone)
        }
    }
}
