import SwiftUI
import Carbon.HIToolbox

@main
struct SpiraPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var queue = ClipboardQueue.shared

    var body: some Scene {
        MenuBarExtra {
            QueueView()
                .environmentObject(queue)
        } label: {
            // Badge the icon with the queue count when non-empty.
            Image(systemName: queue.items.isEmpty ? "list.clipboard" : "list.clipboard.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pasteHotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app (LSUIElement also set in Info.plist).
        NSApp.setActivationPolicy(.accessory)

        ClipboardQueue.shared.start()

        // ⌘⇧V → paste the next queued item.
        pasteHotKey = HotKey(keyCode: UInt32(kVK_ANSI_V),
                             modifiers: UInt32(cmdKey | shiftKey)) {
            Task { @MainActor in ClipboardQueue.shared.pasteNext() }
        }
    }
}
