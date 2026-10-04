// EditorView.swift — the markdown text editor. Wraps NSTextView so we get
// native text editing (undo, find bar, dictation, spelling) and apply the
// live markdown styling on every change.
import SwiftUI
import AppKit

// Formatting commands sent from the menu bar to whichever editor is active.
extension Notification.Name {
    static let nibFormat = Notification.Name("NibFormatCommand")
}
enum FormatCommand: String {
    case bold, italic, code, strikethrough, link
}

struct EditorView: NSViewRepresentable {
    @ObservedObject var document: Document

    func makeCoordinator() -> Coordinator { Coordinator(document: document) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let textView = scroll.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.font = Theme.body
        textView.textColor = Theme.text
        textView.drawsBackground = false
        scroll.drawsBackground = false

        // Comfortable text column with padding
        textView.textContainerInset = NSSize(width: 28, height: 24)
        textView.autoresizingMask = [.width]

        context.coordinator.textView = textView
        context.coordinator.setText(document.text)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.document = document

        // Document switched in this tab, or changed externally
        if let textView = coordinator.textView, textView.string != document.text {
            coordinator.setText(document.text)
        }
        // Outline click → scroll to heading
        if let target = document.pendingScrollLocation {
            DispatchQueue.main.async {
                coordinator.scroll(to: target)
                document.pendingScrollLocation = nil
            }
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var document: Document
        weak var textView: NSTextView?
        private var isProgrammaticChange = false

        init(document: Document) {
            self.document = document
            super.init()
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleFormat(_:)), name: .nibFormat, object: nil)
        }

        deinit { NotificationCenter.default.removeObserver(self) }

        func setText(_ text: String) {
            guard let textView else { return }
            isProgrammaticChange = true
            textView.string = text
            textView.undoManager?.removeAllActions()
            restyle()
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            isProgrammaticChange = false
            // Scroll after layout settles, otherwise the view can land at the bottom
            DispatchQueue.main.async { [weak textView] in
                textView?.scrollToBeginningOfDocument(nil)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard !isProgrammaticChange, let textView else { return }
            document.text = textView.string
            restyle()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isProgrammaticChange else { return }
            // Re-run styling so syntax markers on the cursor's line light up.
            restyle()
        }

        private func restyle() {
            guard let textView, let storage = textView.textStorage else { return }
            MarkdownStyler.style(storage, cursorLocation: textView.selectedRange().location)
        }

        func scroll(to location: Int) {
            guard let textView else { return }
            let loc = min(location, (textView.string as NSString).length)
            textView.setSelectedRange(NSRange(location: loc, length: 0))
            textView.scrollRangeToVisible(NSRange(location: loc, length: 0))
            textView.window?.makeFirstResponder(textView)
        }

        // Keep list typing pleasant: pressing Return inside a list item
        // continues the list with a fresh bullet/number.
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            let ns = textView.string as NSString
            let sel = textView.selectedRange()
            let lineRange = ns.lineRange(for: NSRange(location: sel.location, length: 0))
            let line = ns.substring(with: lineRange)

            let patterns: [(String, (String) -> String)] = [
                (#"^([ \t]*)([-*+])[ \t]+\[[ xX]\][ \t]+\S"#, { indent in "\(indent)- [ ] " }),
                (#"^([ \t]*)([-*+])[ \t]+\S"#, { indent in "\(indent)- " }),
            ]
            for (pattern, continuation) in patterns {
                if let m = try? NSRegularExpression(pattern: pattern)
                    .firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let indentRange = Range(m.range(at: 1), in: line) {
                    textView.insertText("\n" + continuation(String(line[indentRange])),
                                        replacementRange: sel)
                    return true
                }
            }
            // Numbered list: continue with next number
            if let m = try? NSRegularExpression(pattern: #"^([ \t]*)(\d{1,4})\.[ \t]+\S"#)
                .firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let indentRange = Range(m.range(at: 1), in: line),
               let numRange = Range(m.range(at: 2), in: line),
               let num = Int(line[numRange]) {
                textView.insertText("\n\(line[indentRange])\(num + 1). ", replacementRange: sel)
                return true
            }
            // Empty list item + Return = end the list
            if line.trimmingCharacters(in: .whitespacesAndNewlines)
                   .range(of: #"^([-*+]|\d{1,4}\.)([ \t]+\[[ xX]\])?$"#, options: .regularExpression) != nil {
                var content = lineRange
                if content.length > 0, ns.character(at: NSMaxRange(content) - 1) == 10 { content.length -= 1 }
                textView.insertText("", replacementRange: content)
                return true
            }
            return false
        }

        // MARK: Formatting shortcuts (Cmd+B etc.)

        @objc private func handleFormat(_ note: Notification) {
            guard let textView, textView.window?.isKeyWindow == true,
                  textView.window?.firstResponder == textView,
                  let raw = note.object as? String,
                  let command = FormatCommand(rawValue: raw) else { return }

            let marker: (String, String)
            switch command {
            case .bold:          marker = ("**", "**")
            case .italic:        marker = ("*", "*")
            case .code:          marker = ("`", "`")
            case .strikethrough: marker = ("~~", "~~")
            case .link:          marker = ("[", "](url)")
            }

            let sel = textView.selectedRange()
            let ns = textView.string as NSString
            let selected = sel.length > 0 ? ns.substring(with: sel) : ""
            let replacement = marker.0 + selected + marker.1

            if textView.shouldChangeText(in: sel, replacementString: replacement) {
                textView.replaceCharacters(in: sel, with: replacement)
                textView.didChangeText()
                if command == .link, sel.length > 0 {
                    // Select the "url" placeholder so you can paste right over it
                    let urlStart = sel.location + 1 + selected.utf16.count + 2
                    textView.setSelectedRange(NSRange(location: urlStart, length: 3))
                } else if sel.length == 0 {
                    // Put the cursor between the markers
                    textView.setSelectedRange(NSRange(location: sel.location + marker.0.utf16.count, length: 0))
                } else {
                    textView.setSelectedRange(NSRange(location: sel.location, length: replacement.utf16.count))
                }
            }
        }
    }
}
