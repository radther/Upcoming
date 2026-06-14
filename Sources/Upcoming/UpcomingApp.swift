import SwiftUI
import AppKit

@main
struct UpcomingApp: App {
    @StateObject private var manager = CalendarManager()
    @StateObject private var clock = Clock()

    init() {
        // A menu bar app must persist; never let AppKit's automatic-termination
        // heuristics suspend us when the popover is closed. (NSApp is not yet up
        // during App.init(), so we only touch ProcessInfo here — the accessory
        // activation policy is already set via LSUIElement in Info.plist.)
        ProcessInfo.processInfo.disableAutomaticTermination("upcoming-menubar-active")
        ProcessInfo.processInfo.disableSuddenTermination()
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(manager: manager, clock: clock)
        } label: {
            MenuBarLabel(manager: manager, clock: clock)
        }
        .menuBarExtraStyle(.window)
    }
}
