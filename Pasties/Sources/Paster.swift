import AppKit
import CoreGraphics
import ApplicationServices

/// Simulates a ⌘V keystroke into whatever app is frontmost.
/// Posting synthetic key events requires the app to be granted
/// Accessibility permission (System Settings ▸ Privacy & Security ▸ Accessibility).
enum Paster {
    private static let vKeyCode: CGKeyCode = 0x09 // kVK_ANSI_V

    /// Whether this app may post synthetic keystrokes.
    /// Pass `prompt: true` to ask macOS to show the permission dialog.
    static func accessibilityGranted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Send ⌘V to the frontmost application.
    static func paste() {
        let src = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false)
        else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cgAnnotatedSessionEventTap)
        up.post(tap: .cgAnnotatedSessionEventTap)
    }
}
