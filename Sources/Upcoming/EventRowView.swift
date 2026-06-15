import AppKit
import SwiftUI

struct EventRowView: View {
    let event: CalendarEvent
    var now: Date = Date()

    private var isNowLive: Bool { now >= event.startDate && now < event.endDate }
    private var isUpcomingLive: Bool { event.startDate > now }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Time block (compact)
            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.system(size: 12, weight: isNowLive ? .bold : .semibold))
                    .monospacedDigit()
                    .foregroundStyle(isNowLive ? Color.accentColor : .primary)
                if !event.isAllDay {
                    Text(EventFormatting.timeOnly.string(from: event.endDate))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(width: 48, alignment: .leading)

            // Calendar color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(cgColor: event.calendarColor))
                .frame(width: 4)
                .padding(.vertical, 2)

            // Title + meta
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    if event.hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                            .help("Overlaps with another event")
                    }
                    if event.hasConferenceURL {
                        Image(systemName: "video")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .help("Has a meeting link")
                    }
                }

                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9))
                        Text(location)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }

                if !event.attendees.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 9))
                        Text(
                            event.attendees.count <= 2
                                ? event.attendees.joined(separator: ", ")
                                : "\(event.attendees.prefix(2).joined(separator: ", ")) +\(event.attendees.count - 2)"
                        )
                        .lineLimit(1)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }

                if isNowLive {
                    Text("● Happening now")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                } else if isUpcomingLive {
                    Text(
                        EventFormatting.countdown(
                            to: event.startDate, isAllDay: event.isAllDay, now: now)
                    )
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(
            Rectangle()
                .fill(isNowLive ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button("Copy event title") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(event.title, forType: .string)
            }
            if let notes = event.notes, !notes.isEmpty {
                Button("Copy notes") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(notes, forType: .string)
                }
            }
        }
    }

    private var timeText: String {
        if event.isAllDay { return "all-day" }
        return EventFormatting.timeOnly.string(from: event.startDate)
    }
}
