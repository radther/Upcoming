import Foundation
import Combine

/// A single source of "now" that ticks exactly on each wall-clock minute boundary.
///
/// Used instead of `TimelineView`, which (when placed inside the always-on
/// `MenuBarExtra` label) drives continuous re-evaluation and pins a CPU core.
/// A one-shot `Timer` rescheduled each minute costs ~nothing and flips the
/// countdowns precisely when the clock's minute changes.
@MainActor
final class Clock: ObservableObject {
    @Published private(set) var now: Date = Date()

    private var timer: Timer?

    init() {
        reschedule()
    }

    deinit {
        timer?.invalidate()
    }

    /// Advance `now` and arm the next fire for the upcoming minute boundary.
    private func reschedule() {
        let calendar = Calendar.current
        let minuteStart = calendar.dateInterval(of: .minute, for: Date())!.start
        let nextBoundary = calendar.date(byAdding: .minute, value: 1, to: minuteStart)!
        let delay = max(nextBoundary.timeIntervalSinceNow, 0.1)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                self.reschedule()
            }
        }
    }
}
