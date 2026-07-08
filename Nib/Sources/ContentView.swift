// ContentView.swift — window layout: sidebar (file tree) • tabs + editor • outline.
import SwiftUI

struct ContentView: View {
    @ObservedObject var model = AppModel.shared

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            VStack(spacing: 0) {
                TabBarView(model: model)
                Divider()
                HStack(spacing: 0) {
                    if let doc = model.activeDocument {
                        EditorView(document: doc)
                            .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                            .id(doc.id)
                        if model.showOutline {
                            Divider()
                            OutlinePanel(document: doc)
                                .frame(width: 210)
                        }
                    }
                }
                Divider()
                if let doc = model.activeDocument {
                    StatsBar(document: doc)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.newFileInWorkspace()
                } label: { Label("New Document", systemImage: "square.and.pencil") }
                .help("New document (⌘N)")

                Button {
                    withAnimation { model.showOutline.toggle() }
                } label: { Label("Outline", systemImage: "list.bullet.indent") }
                .help("Show or hide the outline panel")

                Menu {
                    ExportMenuItems(model: model)
                } label: { Label("Export", systemImage: "square.and.arrow.up") }
                .help("Copy or export the document")
            }
        }
        .navigationTitle(model.activeDocument.map { $0.displayName } ?? "Nib")
    }
}

/// Shared between the toolbar menu and the File menu.
struct ExportMenuItems: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if let doc = model.activeDocument {
            Section("Copy as") {
                Button("Markdown") { Exporter.copyMarkdown(doc) }
                Button("Rich Text") { Exporter.copyRichText(doc) }
                Button("HTML") { Exporter.copyHTML(doc) }
                Button("Plain Text") { Exporter.copyPlainText(doc) }
            }
            Section("Export as") {
                Button("PDF…") { Exporter.exportPDF(doc) }
                Button("HTML…") { Exporter.exportHTML(doc) }
                Button("Markdown…") { Exporter.exportMarkdown(doc) }
            }
        }
    }
}

// MARK: - Sidebar (workspace file tree)

struct SidebarView: View {
    @ObservedObject var model: AppModel
    @State private var filter = ""

    var body: some View {
        VStack(spacing: 0) {
            if model.workspaceURL != nil {
                List {
                    OutlineGroup(filteredTree, children: \.children) { node in
                        FileRow(node: node, model: model)
                    }
                }
                .listStyle(.sidebar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    TextField("Filter files", text: $filter)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .padding(8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Open a folder to use it\nas a writing workspace")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Open Folder…") { model.chooseWorkspaceFolder() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let workspace = model.workspaceURL {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill").font(.caption)
                    Text(workspace.lastPathComponent).font(.caption).lineLimit(1)
                    Spacer()
                    Button { model.refreshTree() } label: {
                        Image(systemName: "arrow.clockwise").font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh file list")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.bar)
            }
        }
    }

    private var filteredTree: [FileNode] {
        guard !filter.isEmpty else { return model.fileTree }
        return filterNodes(model.fileTree)
    }

    private func filterNodes(_ nodes: [FileNode]) -> [FileNode] {
        nodes.compactMap { node in
            if node.isFolder {
                let kids = filterNodes(node.children ?? [])
                if kids.isEmpty { return nil }
                var copy = node
                copy.children = kids
                return copy
            }
            return node.name.localizedCaseInsensitiveContains(filter) ? node : nil
        }
    }
}

struct FileRow: View {
    let node: FileNode
    @ObservedObject var model: AppModel

    var body: some View {
        if node.isFolder {
            Label(node.name, systemImage: "folder")
        } else {
            Button {
                model.open(fileURL: node.url)
            } label: {
                Label(node.name, systemImage: "doc.text")
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([node.url])
                }
            }
        }
    }

    private var isActive: Bool {
        model.activeDocument?.url == node.url
    }
}

// MARK: - Tab bar

struct TabBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1) {
                ForEach(model.openDocuments) { doc in
                    TabItem(document: doc, model: model)
                }
            }
        }
        .frame(height: 32)
        .background(.bar)
    }
}

struct TabItem: View {
    @ObservedObject var document: Document
    @ObservedObject var model: AppModel
    @State private var hovering = false

    var isActive: Bool { model.activeDocumentID == document.id }

    var body: some View {
        HStack(spacing: 5) {
            Button {
                model.close(document)
            } label: {
                Image(systemName: document.isDirty && !hovering ? "circle.fill" : "xmark")
                    .font(.system(size: document.isDirty && !hovering ? 7 : 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .opacity(hovering || document.isDirty ? 1 : 0)

            Text(document.displayName)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .frame(minWidth: 90, maxWidth: 190)
        .background(isActive ? Color(nsColor: .textBackgroundColor) : .clear)
        .contentShape(Rectangle())
        .onTapGesture { model.activeDocumentID = document.id }
        .onHover { hovering = $0 }
    }
}

// MARK: - Outline panel

struct OutlinePanel: View {
    @ObservedObject var document: Document

    var body: some View {
        let items = MarkdownStyler.outline(of: document.text)
        VStack(alignment: .leading, spacing: 0) {
            Text("Outline")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            Divider()
            if items.isEmpty {
                Text("No headings yet")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(items) { item in
                    Button {
                        document.pendingScrollLocation = item.id
                    } label: {
                        Text(item.title)
                            .font(.system(size: item.level == 1 ? 13 : 12,
                                          weight: item.level <= 2 ? .medium : .regular))
                            .lineLimit(1)
                            .padding(.leading, CGFloat(item.level - 1) * 12)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }
}

// MARK: - Stats bar

struct StatsBar: View {
    @ObservedObject var document: Document

    var body: some View {
        let stats = MarkdownStyler.stats(of: document.text)
        HStack(spacing: 14) {
            stat("\(stats.words)", "words")
            stat("\(stats.characters)", "characters")
            stat("\(stats.paragraphs)", "paragraphs")
            Spacer()
            if stats.readingMinutes > 0 {
                stat("\(stats.readingMinutes) min", "read")
            }
            if let url = document.url {
                Text(url.abbreviatingWithTilde)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            } else {
                Text("Not saved yet").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(.bar)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(value).font(.caption.weight(.medium))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

private extension URL {
    var abbreviatingWithTilde: String {
        (path as NSString).abbreviatingWithTildeInPath
    }
}
