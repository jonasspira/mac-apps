// AppModel.swift — documents, tabs, and the folder workspace.
import SwiftUI
import AppKit

// MARK: - Document

final class Document: ObservableObject, Identifiable {
    let id = UUID()
    @Published var url: URL?
    @Published var text: String {
        didSet {
            guard text != oldValue else { return }
            isDirty = true
            scheduleAutosave()
        }
    }
    @Published var isDirty = false
    /// Set by the outline panel; the editor scrolls here and clears it.
    @Published var pendingScrollLocation: Int?

    private var autosaveTask: Task<Void, Never>?

    init(url: URL?, text: String) {
        self.url = url
        self.text = text
    }

    var displayName: String {
        url?.deletingPathExtension().lastPathComponent ?? "Untitled"
    }

    /// Autosave 1 second after the last keystroke (only for files that exist on disk).
    private func scheduleAutosave() {
        guard url != nil else { return }
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }

    @discardableResult
    func save() -> Bool {
        guard let url else { return saveAs() }
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            isDirty = false
            return true
        } catch {
            NSAlert(error: error).runModal()
            return false
        }
    }

    @discardableResult
    func saveAs() -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.nameFieldStringValue = displayName == "Untitled" ? "Untitled.md" : displayName + ".md"
        guard panel.runModal() == .OK, let dest = panel.url else { return false }
        url = dest
        return save()
    }
}

// MARK: - File tree

struct FileNode: Identifiable {
    let url: URL
    let isFolder: Bool
    var children: [FileNode]?   // nil for files (required by OutlineGroup)
    var id: URL { url }
    var name: String { isFolder ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent }

    static let editableExtensions: Set<String> = ["md", "markdown", "mdown", "txt", "text"]

    /// Recursively scan a folder for markdown files, folders first, alphabetical.
    static func scan(_ folder: URL) -> [FileNode] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) else { return [] }
        var nodes: [FileNode] = []
        for item in items {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                let children = scan(item)
                // Hide folders that contain no markdown anywhere inside
                if !children.isEmpty {
                    nodes.append(FileNode(url: item, isFolder: true, children: children))
                }
            } else if editableExtensions.contains(item.pathExtension.lowercased()) {
                nodes.append(FileNode(url: item, isFolder: false, children: nil))
            }
        }
        return nodes.sorted {
            if $0.isFolder != $1.isFolder { return $0.isFolder }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

// MARK: - App model

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var workspaceURL: URL?
    @Published var fileTree: [FileNode] = []
    @Published var openDocuments: [Document] = []
    @Published var activeDocumentID: UUID?
    @Published var showOutline = true

    var activeDocument: Document? {
        openDocuments.first { $0.id == activeDocumentID }
    }

    private init() {
        // Restore last workspace and last open file
        if let path = UserDefaults.standard.string(forKey: "workspacePath"),
           FileManager.default.fileExists(atPath: path) {
            setWorkspace(URL(fileURLWithPath: path))
        }
        if let filePath = UserDefaults.standard.string(forKey: "lastFilePath"),
           FileManager.default.fileExists(atPath: filePath) {
            open(fileURL: URL(fileURLWithPath: filePath))
        }
        if openDocuments.isEmpty { newDocument() }
    }

    // MARK: Workspace

    func setWorkspace(_ url: URL) {
        workspaceURL = url
        refreshTree()
        UserDefaults.standard.set(url.path, forKey: "workspacePath")
    }

    func closeWorkspace() {
        workspaceURL = nil
        fileTree = []
        UserDefaults.standard.removeObject(forKey: "workspacePath")
    }

    func refreshTree() {
        guard let workspaceURL else { return }
        fileTree = FileNode.scan(workspaceURL)
    }

    func chooseWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.prompt = "Open Folder"
        if panel.runModal() == .OK, let url = panel.url { setWorkspace(url) }
    }

    // MARK: Documents & tabs

    func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = FileNode.editableExtensions.compactMap { .init(filenameExtension: $0) }
        if panel.runModal() == .OK {
            for url in panel.urls { open(fileURL: url) }
        }
    }

    func open(fileURL: URL) {
        // Already open? Just switch to its tab.
        if let existing = openDocuments.first(where: { $0.url == fileURL }) {
            activeDocumentID = existing.id
            return
        }
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
            let alert = NSAlert()
            alert.messageText = "Couldn't open \(fileURL.lastPathComponent)"
            alert.informativeText = "The file isn't plain text (UTF-8)."
            alert.runModal()
            return
        }
        // Replace a pristine untitled tab instead of stacking a new one next to it
        if openDocuments.count == 1, let only = openDocuments.first,
           only.url == nil, only.text.isEmpty {
            openDocuments.removeAll()
        }
        let doc = Document(url: fileURL, text: text)
        openDocuments.append(doc)
        activeDocumentID = doc.id
        UserDefaults.standard.set(fileURL.path, forKey: "lastFilePath")
    }

    func newDocument() {
        let doc = Document(url: nil, text: "")
        openDocuments.append(doc)
        activeDocumentID = doc.id
    }

    /// Create a new .md file inside the workspace folder and open it.
    func newFileInWorkspace() {
        guard let workspaceURL else { newDocument(); return }
        var name = "Untitled.md"
        var counter = 2
        while FileManager.default.fileExists(atPath: workspaceURL.appendingPathComponent(name).path) {
            name = "Untitled \(counter).md"
            counter += 1
        }
        let url = workspaceURL.appendingPathComponent(name)
        try? "".write(to: url, atomically: true, encoding: .utf8)
        refreshTree()
        open(fileURL: url)
    }

    func close(_ doc: Document) {
        if doc.isDirty {
            let alert = NSAlert()
            alert.messageText = "Save changes to “\(doc.displayName)”?"
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                guard doc.save() else { return }
            case .alertThirdButtonReturn:
                return
            default: break
            }
        }
        openDocuments.removeAll { $0.id == doc.id }
        if activeDocumentID == doc.id {
            activeDocumentID = openDocuments.last?.id
        }
        if openDocuments.isEmpty { newDocument() }
    }

    func saveAll() {
        for doc in openDocuments where doc.isDirty && doc.url != nil { doc.save() }
    }
}
