// MarkdownHTML.swift — converts markdown to a standalone styled HTML document.
// Used for Copy as HTML/Rich Text/Plain Text and for PDF/HTML export.
import Foundation

enum MarkdownHTML {

    /// Full standalone HTML document (with CSS), ready to save or print.
    static func document(from markdown: String, title: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>\(escape(title))</title>
        <style>
        body { font: 15px/1.55 -apple-system, "Helvetica Neue", sans-serif; color: #1d1d1f;
               max-width: 44em; margin: 2.5em auto; padding: 0 2em; }
        h1 { font-size: 1.9em; } h2 { font-size: 1.5em; } h3 { font-size: 1.25em; }
        h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 1.3em 0 0.5em; }
        code { font: 0.9em ui-monospace, "SF Mono", Menlo, monospace;
               background: rgba(0,0,0,0.05); padding: 0.1em 0.35em; border-radius: 4px; }
        pre { background: rgba(0,0,0,0.05); padding: 1em; border-radius: 8px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { margin: 1em 0; padding: 0.1em 1.2em; border-left: 3px solid #c7c7cc; color: #555; }
        a { color: #2962cc; }
        img { max-width: 100%; }
        hr { border: none; border-top: 1px solid #d2d2d7; margin: 2em 0; }
        table { border-collapse: collapse; margin: 1em 0; }
        th, td { border: 1px solid #d2d2d7; padding: 0.4em 0.8em; text-align: left; }
        th { background: rgba(0,0,0,0.04); }
        li.task { list-style: none; margin-left: -1.3em; }
        </style>
        </head>
        <body>
        \(body(from: markdown))
        </body>
        </html>
        """
    }

    /// Just the HTML body content.
    static func body(from markdown: String) -> String {
        var html: [String] = []
        var lines = markdown.components(separatedBy: .newlines)[...]
        var paragraph: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            html.append("<p>" + paragraph.map(inline).joined(separator: "<br>") + "</p>")
            paragraph.removeAll()
        }

        while let line = lines.first {
            lines = lines.dropFirst()
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Blank line ends a paragraph
            if trimmed.isEmpty { flushParagraph(); continue }

            // Fenced code block
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                flushParagraph()
                let fence = String(trimmed.prefix(3))
                var code: [String] = []
                while let next = lines.first {
                    lines = lines.dropFirst()
                    if next.trimmingCharacters(in: .whitespaces).hasPrefix(fence) { break }
                    code.append(next)
                }
                html.append("<pre><code>" + escape(code.joined(separator: "\n")) + "</code></pre>")
                continue
            }

            // Heading
            if let m = match(#"^(#{1,6})[ \t]+(.*)$"#, trimmed) {
                flushParagraph()
                let level = m[1].count
                html.append("<h\(level)>\(inline(m[2]))</h\(level)>")
                continue
            }

            // Horizontal rule
            if match(#"^(-{3,}|\*{3,}|_{3,})$"#, trimmed) != nil {
                flushParagraph(); html.append("<hr>"); continue
            }

            // Blockquote — gather consecutive "> " lines
            if trimmed.hasPrefix(">") {
                flushParagraph()
                var quote = [String(trimmed.drop(while: { $0 == ">" || $0 == " " }))]
                while let next = lines.first, next.trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    lines = lines.dropFirst()
                    quote.append(String(next.trimmingCharacters(in: .whitespaces).drop(while: { $0 == ">" || $0 == " " })))
                }
                html.append("<blockquote><p>" + quote.map(inline).joined(separator: "<br>") + "</p></blockquote>")
                continue
            }

            // Table — needs a header row + separator row of dashes
            if trimmed.contains("|"),
               let sep = lines.first?.trimmingCharacters(in: .whitespaces),
               match(#"^\|?[ :\-|]+\|?$"#, sep) != nil, sep.contains("-") {
                flushParagraph()
                lines = lines.dropFirst() // consume separator
                var rows = ["<tr>" + cells(trimmed).map { "<th>\(inline($0))</th>" }.joined() + "</tr>"]
                while let next = lines.first?.trimmingCharacters(in: .whitespaces), next.contains("|"), !next.isEmpty {
                    lines = lines.dropFirst()
                    rows.append("<tr>" + cells(next).map { "<td>\(inline($0))</td>" }.joined() + "</tr>")
                }
                html.append("<table>" + rows.joined() + "</table>")
                continue
            }

            // Lists (bulleted, numbered, tasks) — gather consecutive items
            if isListItem(trimmed) {
                flushParagraph()
                let ordered = match(#"^\d{1,4}\."#, trimmed) != nil
                var items: [String] = [listItem(trimmed)]
                while let next = lines.first?.trimmingCharacters(in: .whitespaces), isListItem(next) {
                    lines = lines.dropFirst()
                    items.append(listItem(next))
                }
                let tag = ordered ? "ol" : "ul"
                html.append("<\(tag)>" + items.joined() + "</\(tag)>")
                continue
            }

            paragraph.append(trimmed)
        }
        flushParagraph()
        return html.joined(separator: "\n")
    }

    // MARK: Helpers

    private static func isListItem(_ line: String) -> Bool {
        match(#"^([-*+]|\d{1,4}\.)[ \t]+\S"#, line) != nil
    }

    private static func listItem(_ line: String) -> String {
        var rest = String(line.drop(while: { "-*+0123456789.".contains($0) }).drop(while: { $0 == " " || $0 == "\t" }))
        // Task checkbox
        if let m = match(#"^\[([ xX])\][ \t]+(.*)$"#, rest) {
            let checked = m[1].lowercased() == "x" ? " checked" : ""
            rest = m[2]
            return "<li class=\"task\"><input type=\"checkbox\" disabled\(checked)> \(inline(rest))</li>"
        }
        return "<li>\(inline(rest))</li>"
    }

    private static func cells(_ row: String) -> [String] {
        var r = row.trimmingCharacters(in: .whitespaces)
        if r.hasPrefix("|") { r.removeFirst() }
        if r.hasSuffix("|") { r.removeLast() }
        return r.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Inline markdown → HTML: escape first, then apply spans.
    private static func inline(_ text: String) -> String {
        var s = escape(text)
        s = replace(s, #"`([^`]+)`"#, "<code>$1</code>")
        s = replace(s, #"!\[([^\]]*)\]\(([^)]+)\)"#, "<img src=\"$2\" alt=\"$1\">")
        s = replace(s, #"(?<!!)\[([^\]]+)\]\(([^)]+)\)"#, "<a href=\"$2\">$1</a>")
        s = replace(s, #"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#, "<strong>$2</strong>")
        s = replace(s, #"(?<![\w*_])(\*|_)(?![\s*_])(.+?)(?<![\s*_])\1(?![\w*_])"#, "<em>$2</em>")
        s = replace(s, #"~~(?=\S)(.+?)(?<=\S)~~"#, "<del>$1</del>")
        return s
    }

    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func replace(_ s: String, _ pattern: String, _ template: String) -> String {
        let rx = try! NSRegularExpression(pattern: pattern)
        return rx.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template)
    }

    /// First regex match, returning capture groups as strings. Anchored per-line use.
    private static func match(_ pattern: String, _ s: String) -> [String]? {
        let rx = try! NSRegularExpression(pattern: pattern)
        guard let m = rx.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else { return nil }
        return (0..<m.numberOfRanges).map {
            guard let r = Range(m.range(at: $0), in: s) else { return "" }
            return String(s[r])
        }
    }
}
