import Foundation

@MainActor
enum EventFormatting {
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("jmm")
        return f
    }()

    static let dayMonthTime: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM djmm")
        return f
    }()

    static let weekdayOnly: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f
    }()

    static let weekdayTime: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE · jmm")
        return f
    }()

    /// e.g. "3:00 – 4:00 PM"
    static func timeRange(start: Date, end: Date) -> String {
        let s = timeOnly.string(from: start)
        let e = timeOnly.string(from: end)
        return "\(s) – \(e)"
    }

    /// Compact relative countdown used by the menu-bar label and the banner.
    static func countdown(to date: Date, isAllDay: Bool, now: Date = Date()) -> String {
        let weekday = weekdayOnly.string(from: date)

        // All-day events are compared in whole calendar days to the event's day,
        // since the wall-clock time within the day is irrelevant.
        if isAllDay {
            let cal = Calendar.current
            let dayDiff = cal.dateComponents([.day],
                                             from: cal.startOfDay(for: now),
                                             to: cal.startOfDay(for: date)).day ?? 0
            if dayDiff <= 0 { return "today" }
            return "in \(dayDiff)d, \(weekday)"
        }

        let diff = date.timeIntervalSince(now)
        if diff < 0 { return "now" }
        let mins = Int(diff / 60)
        if mins < 1 { return "in <1m" }
        if mins < 60 { return "in \(mins)m" }
        let hours = mins / 60
        let remMins = mins % 60
        if hours < 24 {
            return remMins == 0 ? "in \(hours)h" : "in \(hours)h \(remMins)m"
        }
        let days = hours / 24
        return "in \(days)d, \(weekday)"
    }

    static func dayHeaderTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEE")
        return f.string(from: date)
    }
}
