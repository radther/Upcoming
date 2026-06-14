import EventKit
import Foundation

/// Wraps a calendar event with the derived fields the UI needs.
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let location: String?
    let url: URL?
    let notes: String?
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: CGColor
    let calendarTitle: String
    let attendees: [String]
    let hasConferenceURL: Bool
    let hasConflict: Bool

    /// How many minutes until this event starts (negative if in progress).
    var minutesUntilStart: Int {
        Int(startDate.timeIntervalSinceNow / 60)
    }

    var isNow: Bool { Date() >= startDate && Date() < endDate }

    var isUpcoming: Bool { startDate > Date() }
}

enum AuthorizationState: Equatable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
final class CalendarManager: ObservableObject {
    @Published private(set) var authorization: AuthorizationState = .notDetermined
    @Published private(set) var events: [CalendarEvent] = []
    @Published private(set) var lastUpdated: Date?
    @Published var error: String?
    @Published var isLoading: Bool = false

    private let store = EKEventStore()

    init() {
        authorization = currentAuthorization()
        // Prime the menu bar label as soon as authorization is known, without
        // blocking init.
        Task { @MainActor in
            if authorization == .notDetermined {
                await requestAccess()
            } else if authorization == .authorized {
                await refresh()
            }
        }
    }

    // MARK: - Authorization

    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            self.authorization = granted ? .authorized : .denied
            if granted {
                await refresh()
            }
        } catch {
            self.error = error.localizedDescription
            self.authorization = .denied
        }
    }

    private func currentAuthorization() -> AuthorizationState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .fullAccess, .writeOnly:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    // MARK: - Fetch

    func refresh() async {
        guard authorization == .authorized else {
            await requestAccess()
            return
        }
        isLoading = true
        defer { isLoading = false }

        let now = Date()
        let horizon = Calendar.appCal.date(byAdding: .day, value: 7, to: now)!
        let predicate = store.predicateForEvents(withStart: now, end: horizon, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        let prepared: [CalendarEvent] = ekEvents.map { makeEvent(from: $0, hasConflict: false) }
            .sorted { $0.startDate < $1.startDate }

        self.events = markConflicts(prepared)
        self.lastUpdated = Date()
    }

    private func makeEvent(from ev: EKEvent, hasConflict: Bool) -> CalendarEvent {
        let attendeeNames = (ev.attendees ?? []).compactMap { $0.name }
        return CalendarEvent(
            id: ev.eventIdentifier,
            title: ev.title?.isEmpty == false ? ev.title! : "(Untitled event)",
            location: ev.location?.isEmpty == false ? ev.location : nil,
            url: ev.url,
            notes: ev.notes,
            startDate: ev.startDate,
            endDate: ev.endDate,
            isAllDay: ev.isAllDay,
            calendarColor: ev.calendar.cgColor,
            calendarTitle: ev.calendar.title,
            attendees: attendeeNames,
            hasConferenceURL: conferenceURL(from: ev) != nil,
            hasConflict: hasConflict
        )
    }

    private func conferenceURL(from ev: EKEvent) -> URL? {
        if let u = ev.url { return u }
        if let notes = ev.notes,
           let range = notes.range(of: #"https?://[^\s)]+"#, options: .regularExpression)
        {
            let candidate = String(notes[range])
            return URL(string: candidate)
        }
        return nil
    }

    private func markConflicts(_ sorted: [CalendarEvent]) -> [CalendarEvent] {
        var conflictIds = Set<String>()
        for i in sorted.indices {
            for j in sorted.indices where i < j {
                let a = sorted[i]
                let b = sorted[j]
                if !a.isAllDay && !b.isAllDay,
                   a.startDate < b.endDate && b.startDate < a.endDate
                {
                    conflictIds.insert(a.id)
                    conflictIds.insert(b.id)
                }
            }
        }
        return sorted.map { ev in
            makeEvent(fromEKStub: ev, hasConflict: conflictIds.contains(ev.id))
        }
    }

    /// Re-build a `CalendarEvent` from our own value (used when we just need to flip flags).
    private func makeEvent(fromEKStub ev: CalendarEvent, hasConflict: Bool) -> CalendarEvent {
        CalendarEvent(
            id: ev.id,
            title: ev.title,
            location: ev.location,
            url: ev.url,
            notes: ev.notes,
            startDate: ev.startDate,
            endDate: ev.endDate,
            isAllDay: ev.isAllDay,
            calendarColor: ev.calendarColor,
            calendarTitle: ev.calendarTitle,
            attendees: ev.attendees,
            hasConferenceURL: ev.hasConferenceURL,
            hasConflict: hasConflict
        )
    }

    // MARK: - Categorization

    var today: [CalendarEvent] {
        let cal = Calendar.appCal
        return events.filter { cal.isDateInToday($0.startDate) || $0.isNow }
    }

    var tomorrow: [CalendarEvent] {
        events.filter { Calendar.appCal.isDateInTomorrow($0.startDate) }
    }

    var restOfWeek: [CalendarEvent] {
        let cal = Calendar.appCal
        let in7 = cal.date(byAdding: .day, value: 7, to: Date())!
        return events.filter { event in
            !cal.isDateInToday(event.startDate) &&
            !cal.isDateInTomorrow(event.startDate) &&
            event.startDate <= in7
        }
    }

    /// Soonest in-progress or upcoming event (drives the popover banner).
    var nextUp: CalendarEvent? {
        events.first(where: { $0.endDate > Date() })
    }

    /// The next event that hasn't started yet — used by the menu-bar label so the
    /// bar keeps pointing forward even while an event is happening now. Falls
    /// back to the in-progress event if there's nothing else coming up, so the
    /// bar never goes blank mid-event.
    var nextUpcoming: CalendarEvent? {
        events.first(where: { $0.startDate > Date() }) ?? nextUp
    }
}

private extension Calendar {
    static let appCal: Calendar = {
        var c = Calendar.current
        c.timeZone = .current
        return c
    }()
}
