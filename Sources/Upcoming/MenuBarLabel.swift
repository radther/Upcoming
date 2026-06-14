import SwiftUI

/// The persistent menu-bar item. Shows a small calendar glyph and, when there's
/// a next event, a compact countdown so the bar is useful even at a glance.
///
/// The countdown is driven from the shared `Clock`, which ticks exactly on each
/// wall-clock minute boundary — so "in 3m" flips to "in 2m" precisely on `:00`.
struct MenuBarLabel: View {
    @ObservedObject var manager: CalendarManager
    @ObservedObject var clock: Clock

    /// The label shows the next upcoming event (not the one happening now), so
    /// the bar keeps pointing forward while an event is in progress.
    private var next: CalendarEvent? { manager.nextUpcoming }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: glyph)
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
            if let next, manager.authorization == .authorized {
                Text(shortLabel(for: next))
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: 140, alignment: .leading)
                    .help(next.title)
            }
        }
        .padding(.horizontal, 2)
        .animation(.snappy(duration: 0.25), value: next?.id)
    }

    private var glyph: String {
        guard let next else { return "calendar" }
        return (clock.now >= next.startDate && clock.now < next.endDate) ? "circle.fill" : "calendar"
    }

    private func shortLabel(for event: CalendarEvent) -> String {
        let isNow = clock.now >= event.startDate && clock.now < event.endDate
        if isNow {
            return "● \(truncate(event.title, to: 14))"
        }
        let countdown = EventFormatting.countdown(to: event.startDate, isAllDay: event.isAllDay, now: clock.now)
        return "\(truncate(event.title, to: 12)) · \(countdown)"
    }

    private func truncate(_ s: String, to max: Int) -> String {
        if s.count <= max { return s }
        return String(s.prefix(max - 1)) + "…"
    }
}
