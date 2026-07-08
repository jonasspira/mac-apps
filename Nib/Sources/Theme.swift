// Theme.swift — fonts and colors for the editor. All colors are dynamic
// (they adapt to light/dark mode automatically via NSColor providers).
import AppKit

enum Theme {
    // MARK: Fonts
    static let bodySize: CGFloat = 15
    static let body = NSFont.systemFont(ofSize: bodySize)
    static let mono = NSFont.monospacedSystemFont(ofSize: 13.5, weight: .regular)

    static func heading(level: Int) -> NSFont {
        switch level {
        case 1: return .systemFont(ofSize: 27, weight: .bold)
        case 2: return .systemFont(ofSize: 22, weight: .bold)
        case 3: return .systemFont(ofSize: 19, weight: .semibold)
        case 4: return .systemFont(ofSize: 17, weight: .semibold)
        case 5: return .systemFont(ofSize: 15.5, weight: .semibold)
        default: return .systemFont(ofSize: 15, weight: .semibold)
        }
    }

    // MARK: Colors
    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
    }

    static let text = NSColor.labelColor
    static let secondaryText = NSColor.secondaryLabelColor

    /// Accent used for links, list bullets, active UI bits. Warm ink blue.
    static let accent = dynamic(
        light: NSColor(calibratedRed: 0.16, green: 0.38, blue: 0.80, alpha: 1),
        dark:  NSColor(calibratedRed: 0.45, green: 0.62, blue: 1.00, alpha: 1))

    static let codeText = dynamic(
        light: NSColor(calibratedRed: 0.72, green: 0.21, blue: 0.33, alpha: 1),
        dark:  NSColor(calibratedRed: 0.98, green: 0.55, blue: 0.60, alpha: 1))

    static let codeBackground = dynamic(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.05),
        dark:  NSColor(calibratedWhite: 1.0, alpha: 0.08))

    static let quoteText = dynamic(
        light: NSColor(calibratedWhite: 0.35, alpha: 1),
        dark:  NSColor(calibratedWhite: 0.70, alpha: 1))

    /// Markdown syntax markers (##, **, ``) — nearly invisible normally,
    /// more visible on the line the cursor is on.
    static func marker(active: Bool) -> NSColor {
        NSColor.labelColor.withAlphaComponent(active ? 0.45 : 0.14)
    }

    // MARK: Paragraph styles
    static func paragraphStyle(headingLevel: Int? = nil) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.lineSpacing = 3
        p.paragraphSpacing = 7
        if let level = headingLevel {
            p.paragraphSpacingBefore = level <= 2 ? 14 : 10
            p.paragraphSpacing = 6
        }
        return p
    }
}
