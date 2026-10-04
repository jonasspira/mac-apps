// Exporter.swift — "Copy as…" and "Export…" for the active document.
// Rich text / plain text / PDF all go through the HTML converter so the
// output looks like rendered markdown, not raw syntax.
import AppKit

@MainActor
enum Exporter {

    // MARK: Copy as…

    static func copyMarkdown(_ doc: Document) {
        setPasteboard(string: doc.text)
    }

    static func copyHTML(_ doc: Document) {
        setPasteboard(string: MarkdownHTML.document(from: doc.text, title: doc.displayName))
    }

    static func copyPlainText(_ doc: Document) {
        setPasteboard(string: rendered(doc)?.string ?? doc.text)
    }

    static func copyRichText(_ doc: Document) {
        guard let attr = rendered(doc),
              let rtf = attr.rtf(from: NSRange(location: 0, length: attr.length)) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData(rtf, forType: .rtf)
        pb.setString(attr.string, forType: .string)
    }

    private static func setPasteboard(string: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
    }

    // MARK: Export…

    static func exportHTML(_ doc: Document) {
        guard let url = savePanel(name: doc.displayName, ext: "html") else { return }
        let html = MarkdownHTML.document(from: doc.text, title: doc.displayName)
        try? html.write(to: url, atomically: true, encoding: .utf8)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func exportMarkdown(_ doc: Document) {
        guard let url = savePanel(name: doc.displayName, ext: "md") else { return }
        try? doc.text.write(to: url, atomically: true, encoding: .utf8)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func exportPDF(_ doc: Document) {
        guard let url = savePanel(name: doc.displayName, ext: "pdf"),
              let attr = rendered(doc) else { return }

        // Lay the rendered text into an offscreen text view sized like a page,
        // then let a silent print operation paginate it into a PDF.
        let printInfo = NSPrintInfo()
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.topMargin = 56; printInfo.bottomMargin = 56
        printInfo.leftMargin = 56; printInfo.rightMargin = 56
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url

        let pageWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: pageWidth, height: 100))
        textView.textStorage?.setAttributedString(attr)
        textView.isVerticallyResizable = true
        textView.sizeToFit()

        let op = NSPrintOperation(view: textView, printInfo: printInfo)
        op.showsPrintPanel = false
        op.showsProgressPanel = false
        op.run()
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func printDocument(_ doc: Document) {
        guard let attr = rendered(doc) else { return }
        let printInfo = NSPrintInfo()
        printInfo.horizontalPagination = .fit
        printInfo.topMargin = 56; printInfo.bottomMargin = 56
        printInfo.leftMargin = 56; printInfo.rightMargin = 56
        let pageWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: pageWidth, height: 100))
        textView.textStorage?.setAttributedString(attr)
        textView.isVerticallyResizable = true
        textView.sizeToFit()
        NSPrintOperation(view: textView, printInfo: printInfo).run()
    }

    // MARK: Rendering

    /// Markdown → styled NSAttributedString (via HTML), i.e. what the doc
    /// "looks like" rendered — used for RTF, plain text, PDF and printing.
    private static func rendered(_ doc: Document) -> NSAttributedString? {
        let html = MarkdownHTML.document(from: doc.text, title: doc.displayName)
        guard let data = html.data(using: .utf8) else { return nil }
        return NSAttributedString(
            html: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)
    }

    private static func savePanel(name: String, ext: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: ext)!]
        panel.nameFieldStringValue = "\(name).\(ext)"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
