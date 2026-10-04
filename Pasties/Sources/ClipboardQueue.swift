import AppKit
import Combine

/// A single captured clipboard entry.
struct ClipItem: Identifiable, Equatable {
    let id = UUID()
    let text: String

    /// Short, single-line preview for the menu.
    var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let oneLine = trimmed.replacingOccurrences(of: "\n", with: " ↵ ")
        return oneLine.count > 64 ? String(oneLine.prefix(64)) + "…" : oneLine
    }
}

/// Watches the system clipboard and holds an ordered queue of copied text.
/// Item at index 0 is the *next* one to be pasted (FIFO).
@MainActor
final class ClipboardQueue: ObservableObject {
    static let shared = ClipboardQueue()

    @Published var items: [ClipItem] = []
    @Published var monitoring: Bool = true
    @Published var autoPaste: Bool {
        didSet { UserDefaults.standard.set(autoPaste, forKey: "autoPaste") }
    }

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    private init() {
        lastChangeCount = pasteboard.changeCount
        autoPaste = UserDefaults.standard.bool(forKey: "autoPaste")
    }

    /// Begin polling the clipboard. Polling needs no special permission.
    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    private func poll() {
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count
        guard monitoring else { return }
        guard let str = pasteboard.string(forType: .string),
              !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // Skip if identical to the most recently queued item (avoids dupes on re-copy).
        if items.last?.text == str { return }
        items.append(ClipItem(text: str))
    }

    // MARK: - Pasting

    /// Load the next queued item onto the clipboard and remove it from the queue.
    /// If auto-paste is on (and Accessibility is granted) it also performs ⌘V.
    func pasteNext() {
        guard let next = items.first else { return }
        items.removeFirst()
        deliver(next.text)
    }

    /// Promote a specific item to the clipboard. Removes it from the queue.
    func paste(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        deliver(item.text)
    }

    /// Copy an item to the clipboard *without* removing it from the queue.
    func copyToClipboard(_ item: ClipItem) {
        writeClipboard(item.text)
    }

    private func deliver(_ text: String) {
        writeClipboard(text)
        if autoPaste {
            // Small delay so the destination app sees the new clipboard contents.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                Paster.paste()
            }
        }
    }

    private func writeClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Treat our own write as already-seen so it isn't re-queued.
        lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Editing

    func remove(_ item: ClipItem) { items.removeAll { $0.id == item.id } }
    func clear() { items.removeAll() }
    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}
