// App.swift — Nib: a Lettera-style markdown editor for macOS.
import SwiftUI
import AppKit

@main
struct NibApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var model = AppModel.shared

    var body: some Scene {
        Window("Nib", id: "main") {
            ContentView()
                .frame(minWidth: 720, minHeight: 440)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") { AppModel.shared.newFileInWorkspace() }
                    .keyboardShortcut("n")
                Button("Open File…") { AppModel.shared.chooseFile() }
                    .keyboardShortcut("o")
                Button("Open Folder as Workspace…") { AppModel.shared.chooseWorkspaceFolder() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                Divider()
                Button("Close Tab") {
                    if let doc = AppModel.shared.activeDocument { AppModel.shared.close(doc) }
                }
                .keyboardShortcut("w")
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { AppModel.shared.activeDocument?.save() }
                    .keyboardShortcut("s")
                Button("Save As…") { AppModel.shared.activeDocument?.saveAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                Divider()
                Menu("Copy & Export") { ExportMenuItems(model: AppModel.shared) }
                Button("Print…") {
                    if let doc = AppModel.shared.activeDocument { Exporter.printDocument(doc) }
                }
                .keyboardShortcut("p")
            }
            CommandMenu("Format") {
                Button("Bold") { format(.bold) }.keyboardShortcut("b")
                Button("Italic") { format(.italic) }.keyboardShortcut("i")
                Button("Code") { format(.code) }.keyboardShortcut("e")
                Button("Strikethrough") { format(.strikethrough) }
                    .keyboardShortcut("x", modifiers: [.command, .shift])
                Button("Link") { format(.link) }.keyboardShortcut("k")
            }
            CommandGroup(after: .sidebar) {
                Button(model.showOutline ? "Hide Outline" : "Show Outline") {
                    AppModel.shared.showOutline.toggle()
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
            }
        }
    }

    private func format(_ command: FormatCommand) {
        NotificationCenter.default.post(name: .nibFormat, object: command.rawValue)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Handles "Open With → Nib" from Finder and double-clicked .md files.
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            for url in urls {
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                if isDir.boolValue {
                    AppModel.shared.setWorkspace(url)
                } else {
                    AppModel.shared.open(fileURL: url)
                }
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        MainActor.assumeIsolated { AppModel.shared.saveAll() }
        return .terminateNow
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
