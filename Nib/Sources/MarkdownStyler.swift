// MarkdownStyler.swift — live styling of markdown text inside the editor.
// Restyles the whole NSTextStorage: headings get big fonts, **bold** gets bold,
// `code` gets monospaced, etc. Syntax markers are dimmed almost to invisibility
// except on the line the cursor is currently on (the "hybrid editing" trick).
import AppKit

enum MarkdownStyler {

    // Compiled once; reused for every restyle.
    private static let rxHeading   = try! NSRegularExpression(pattern: #"^(#{1,6})[ \t]"#)
    private static let rxFence     = try! NSRegularExpression(pattern: #"^(```|~~~)"#)
    private static let rxQuote     = try! NSRegularExpression(pattern: #"^[ \t]*((?:>[ \t]?)+)"#)
    private static let rxBullet    = try! NSRegularExpression(pattern: #"^[ \t]*([-*+])[ \t]+(\[[ xX]\])?"#)
    private static let rxNumbered  = try! NSRegularExpression(pattern: #"^[ \t]*(\d{1,4}\.)[ \t]+"#)
    private static let rxHRule     = try! NSRegularExpression(pattern: #"^[ \t]*(-{3,}|\*{3,}|_{3,})[ \t]*$"#)
    private static let rxCode      = try! NSRegularExpression(pattern: #"`[^`\n]+`"#)
    private static let rxBold      = try! NSRegularExpression(pattern: #"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#)
    private static let rxItalic    = try! NSRegularExpression(pattern: #"(?<![\w*_])(\*|_)(?![\s*_])(.+?)(?<![\s*_])\1(?![\w*_])"#)
    private static let rxStrike    = try! NSRegularExpression(pattern: #"~~(?=\S)(.+?)(?<=\S)~~"#)
    private static let rxImage     = try! NSRegularExpression(pattern: #"!\[([^\]]*)\]\(([^)\n]+)\)"#)
    private static let rxLink      = try! NSRegularExpression(pattern: #"(?<!!)\[([^\]]+)\]\(([^)\n]+)\)"#)

    /// Restyle the entire text storage. `cursorLocation` is the insertion point;
    /// syntax markers on that line are shown more visibly.
    static func style(_ storage: NSTextStorage, cursorLocation: Int?) {
        let ns = storage.string as NSString
        let full = NSRange(location: 0, length: ns.length)

        // Range of the paragraph the cursor sits in (markers shown there).
        var cursorParagraph = NSRange(location: NSNotFound, length: 0)
        if let loc = cursorLocation, loc <= ns.length {
            cursorParagraph = ns.paragraphRange(for: NSRange(location: loc, length: 0))
        }

        storage.beginEditing()
        // Reset to base body style.
        storage.setAttributes([
            .font: Theme.body,
            .foregroundColor: Theme.text,
            .paragraphStyle: Theme.paragraphStyle(),
        ], range: full)

        var inFence = false
        var lineStart = 0
        while lineStart < ns.length {
            let lineRange = ns.lineRange(for: NSRange(location: lineStart, length: 0))
            defer { lineStart = NSMaxRange(lineRange) }
            // Content range without the trailing newline.
            var content = lineRange
            while content.length > 0 {
                let ch = ns.character(at: content.location + content.length - 1)
                if ch == 10 || ch == 13 { content.length -= 1 } else { break }
            }
            let active = NSIntersectionRange(lineRange, cursorParagraph).length > 0
                || lineRange.location == cursorParagraph.location

            // Fenced code blocks: everything monospaced until the closing fence.
            if rxFence.firstMatch(in: storage.string, range: content) != nil {
                inFence.toggle()
                storage.addAttributes([
                    .font: Theme.mono,
                    .foregroundColor: Theme.marker(active: true),
                    .backgroundColor: Theme.codeBackground,
                ], range: content)
                continue
            }
            if inFence {
                storage.addAttributes([
                    .font: Theme.mono,
                    .foregroundColor: Theme.text,
                    .backgroundColor: Theme.codeBackground,
                ], range: content)
                continue
            }

            styleLine(storage, ns: ns, content: content, active: active)
        }
        storage.endEditing()
    }

    private static func styleLine(_ storage: NSTextStorage, ns: NSString, content: NSRange, active: Bool) {
        let string = storage.string

        // Horizontal rule
        if rxHRule.firstMatch(in: string, range: content) != nil,
           rxBullet.firstMatch(in: string, range: content) == nil {
            storage.addAttribute(.foregroundColor, value: Theme.marker(active: active), range: content)
            return
        }

        var isHeading = false

        // Heading
        if let m = rxHeading.firstMatch(in: string, range: content) {
            isHeading = true
            let level = m.range(at: 1).length
            storage.addAttributes([
                .font: Theme.heading(level: level),
                .paragraphStyle: Theme.paragraphStyle(headingLevel: level),
            ], range: content)
            // Dim the "## " prefix
            let prefix = NSRange(location: content.location, length: min(level + 1, content.length))
            storage.addAttribute(.foregroundColor, value: Theme.marker(active: active), range: prefix)
        }

        // Blockquote
        if let m = rxQuote.firstMatch(in: string, range: content) {
            storage.addAttribute(.foregroundColor, value: Theme.quoteText, range: content)
            storage.addAttribute(.foregroundColor, value: Theme.marker(active: active), range: m.range(at: 1))
        }

        // List bullets & task checkboxes
        if let m = rxBullet.firstMatch(in: string, range: content) {
            storage.addAttribute(.foregroundColor, value: Theme.accent, range: m.range(at: 1))
            if m.range(at: 2).location != NSNotFound {
                storage.addAttribute(.foregroundColor, value: Theme.accent, range: m.range(at: 2))
            }
        } else if let m = rxNumbered.firstMatch(in: string, range: content) {
            storage.addAttribute(.foregroundColor, value: Theme.accent, range: m.range(at: 1))
        }

        // --- Inline styles ---

        // Bold
        rxBold.enumerateMatches(in: string, range: content) { m, _, _ in
            guard let m else { return }
            if !isHeading { applyTrait(.boldFontMask, storage: storage, range: m.range(at: 2)) }
            dimEnds(storage, match: m.range, markerLen: 2, active: active)
        }
        // Italic
        rxItalic.enumerateMatches(in: string, range: content) { m, _, _ in
            guard let m else { return }
            applyTrait(.italicFontMask, storage: storage, range: m.range(at: 2))
            dimEnds(storage, match: m.range, markerLen: 1, active: active)
        }
        // Strikethrough
        rxStrike.enumerateMatches(in: string, range: content) { m, _, _ in
            guard let m else { return }
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: m.range(at: 1))
            storage.addAttribute(.foregroundColor, value: Theme.secondaryText, range: m.range(at: 1))
            dimEnds(storage, match: m.range, markerLen: 2, active: active)
        }
        // Images: ![alt](url) — show alt in accent, dim the rest
        rxImage.enumerateMatches(in: string, range: content) { m, _, _ in
            guard let m else { return }
            storage.addAttribute(.foregroundColor, value: Theme.marker(active: active), range: m.range)
            storage.addAttribute(.foregroundColor, value: Theme.accent, range: m.range(at: 1))
        }
        // Links: [text](url) — text in accent, brackets/url dimmed
        rxLink.enumerateMatches(in: string, range: content) { m, _, _ in
            guard let m else { return }
            storage.addAttribute(.foregroundColor, value: Theme.marker(active: active), range: m.range)
            storage.addAttributes([
                .foregroundColor: Theme.accent,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: m.range(at: 1))
            // Make the whole thing clickable (Cmd+click opens)
            let urlString = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
            if let url = URL(string: urlString), url.scheme != nil {
                storage.addAttribute(.link, value: url, range: m.range(at: 1))
            }
        }
        // Inline code (last, so it wins over bold/italic overlaps)
        rxCode.enumerateMatches(in: string, range: content) { m, _, _ in
            guard let m else { return }
            storage.addAttributes([
                .font: Theme.mono,
                .foregroundColor: Theme.codeText,
                .backgroundColor: Theme.codeBackground,
            ], range: m.range)
            dimEnds(storage, match: m.range, markerLen: 1, active: active)
        }
    }

    /// Dim the opening and closing syntax markers of an inline match.
    private static func dimEnds(_ storage: NSTextStorage, match: NSRange, markerLen: Int, active: Bool) {
        guard match.length >= markerLen * 2 else { return }
        let color = Theme.marker(active: active)
        storage.addAttribute(.foregroundColor, value: color,
                             range: NSRange(location: match.location, length: markerLen))
        storage.addAttribute(.foregroundColor, value: color,
                             range: NSRange(location: NSMaxRange(match) - markerLen, length: markerLen))
    }

    /// Add a font trait (bold/italic) while keeping whatever font is already there.
    private static func applyTrait(_ trait: NSFontTraitMask, storage: NSTextStorage, range: NSRange) {
        guard range.location != NSNotFound, range.length > 0 else { return }
        storage.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let base = (value as? NSFont) ?? Theme.body
            let converted = NSFontManager.shared.convert(base, toHaveTrait: trait)
            storage.addAttribute(.font, value: converted, range: subRange)
        }
    }

    // MARK: Outline extraction (for the sidebar outline panel)

    struct HeadingItem: Identifiable {
        let id: Int        // character location in the document
        let level: Int
        let title: String
    }

    static func outline(of text: String) -> [HeadingItem] {
        let ns = text as NSString
        var items: [HeadingItem] = []
        var inFence = false
        var lineStart = 0
        while lineStart < ns.length {
            let lineRange = ns.lineRange(for: NSRange(location: lineStart, length: 0))
            defer { lineStart = NSMaxRange(lineRange) }
            let line = ns.substring(with: lineRange)
            if line.hasPrefix("```") || line.hasPrefix("~~~") { inFence.toggle(); continue }
            if inFence { continue }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("#") else { continue }
            let hashes = trimmed.prefix(while: { $0 == "#" })
            let level = hashes.count
            guard level <= 6 else { continue }
            let rest = trimmed.dropFirst(level)
            guard rest.first == " " || rest.first == "\t" else { continue }
            let title = rest.trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            items.append(HeadingItem(id: lineRange.location, level: level, title: title))
        }
        return items
    }

    // MARK: Document statistics

    struct Stats {
        var words = 0
        var characters = 0
        var paragraphs = 0
        var readingMinutes = 0
    }

    static func stats(of text: String) -> Stats {
        var s = Stats()
        s.characters = text.count
        text.enumerateSubstrings(in: text.startIndex..., options: [.byWords, .substringNotRequired]) { _, _, _, _ in
            s.words += 1
        }
        s.paragraphs = text
            .components(separatedBy: .newlines)
            .split(whereSeparator: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
            .count
        s.readingMinutes = max(1, Int((Double(s.words) / 200.0).rounded(.up)))
        if s.words == 0 { s.readingMinutes = 0 }
        return s
    }
}
