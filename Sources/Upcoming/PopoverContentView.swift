import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var manager: CalendarManager
    @ObservedObject var clock: Clock
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            switch manager.authorization {
            case .notDetermined:
                permissionPrompt
            case .denied:
                deniedPrompt
            case .authorized:
                if manager.events.isEmpty {
                    emptyState
                } else {
                    contentList
                }
            }

            Divider()
            footer
        }
        .frame(width: 380, height: 480)
        .background(.regularMaterial)
        .onAppear {
            Task { await manager.refresh() }
            scheduleAutoRefresh()
        }
        .onDisappear { refreshTask?.cancel() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Upcoming")
                    .font(.system(size: 15, weight: .bold))
                if let next = manager.nextUpcoming {
                    Text("Next: \(next.title)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Next 7 days")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                Task { await manager.refresh() }
            } label: {
                Image(systemName: manager.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                    .rotationEffect(.degrees(manager.isLoading ? 360 : 0))
                    .animation(manager.isLoading
                               ? .linear(duration: 1).repeatForever(autoreverses: false)
                               : .default,
                               value: manager.isLoading)
            }
            .buttonStyle(.borderless)
            .help("Refresh")
            .disabled(manager.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Permission states

    private var permissionPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 30))
                .foregroundStyle(.tint)
            Text("Allow calendar access")
                .font(.headline)
            Text("Upcoming needs permission to read your calendars to show your events here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Continue") {
                Task { await manager.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 30))
                .foregroundStyle(.orange)
            Text("Calendar access denied")
                .font(.headline)
            Text("Grant access in System Settings › Privacy & Security › Calendars.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("Nothing coming up")
                .font(.headline)
            Text("You have no events in the next 7 days. Enjoy the break.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Event list

    private var contentList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let next = manager.nextUp {
                    nextUpBanner(event: next, now: clock.now)
                    Divider().padding(.leading, 14)
                }

                section(title: "Today", subtitle: todaySubtitle, events: manager.today, now: clock.now)
                section(title: "Tomorrow", subtitle: tomorrowSubtitle, events: manager.tomorrow, now: clock.now)
                section(title: "This Week", subtitle: thisWeekSubtitle, events: manager.restOfWeek, now: clock.now)
            }
            .padding(.vertical, 6)
        }
    }

    private func nextUpBanner(event: CalendarEvent, now: Date) -> some View {
        let isNow = now >= event.startDate && now < event.endDate
        return HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(cgColor: event.calendarColor))
                .frame(width: 3)
                .padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(isNow ? "Happening now" : "Up next")
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(isNow ? Color.accentColor : .secondary)
                    .tracking(0.5)
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(event.isAllDay ? "all day"
                         : EventFormatting.timeRange(start: event.startDate, end: event.endDate))
                    if !isNow {
                        Text("·")
                        Text(EventFormatting.countdown(to: event.startDate, isAllDay: event.isAllDay, now: now))
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isNow ? Color.accentColor.opacity(0.08) : Color.clear)
    }

    private func section(title: String, subtitle: String, events: [CalendarEvent], now: Date) -> some View {
        Group {
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.system(size: 12, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("\(events.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 2)

                    VStack(spacing: 1) {
                        ForEach(events) { ev in
                            EventRowView(event: ev, now: now)
                        }
                    }
                }
            }
        }
    }

    private var todaySubtitle: String {
        EventFormatting.timeOnly.string(from: Date())
    }
    private var tomorrowSubtitle: String {
        let cal = Calendar.current
        if let tmr = cal.date(byAdding: .day, value: 1, to: Date()) {
            return EventFormatting.weekdayOnly.string(from: tmr)
        }
        return ""
    }
    private var thisWeekSubtitle: String {
        "Next 7 days"
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if let last = manager.lastUpdated {
                Text("Updated \(last.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .help("Quit Upcoming")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    // MARK: - Auto refresh

    private func scheduleAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { break }
                await manager.refresh()
            }
        }
    }
}
