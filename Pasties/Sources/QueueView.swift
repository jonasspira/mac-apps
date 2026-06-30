import SwiftUI

/// The popover shown when you click the menu bar icon.
struct QueueView: View {
    @EnvironmentObject var queue: ClipboardQueue
    @State private var accessibilityGranted = Paster.accessibilityGranted()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if queue.items.isEmpty {
                emptyState
            } else {
                list
            }

            Divider()
            footer
        }
        .frame(width: 340)
        .frame(minHeight: 200)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Image(systemName: "list.clipboard.fill")
                .foregroundStyle(.tint)
            Text("Paste Queue")
                .font(.headline)
            Spacer()
            Text("\(queue.items.count)")
                .font(.caption.monospacedDigit())
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .padding(12)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.secondary)
            Text("Copy something (⌘C) to start a queue.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Then press ⌘⇧V to paste items one at a time.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach(Array(queue.items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(index == 0 ? Color.white : .secondary)
                        .frame(width: 18, height: 18)
                        .background(index == 0 ? Color.accentColor : Color.clear, in: Circle())

                    Text(item.preview)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 4)

                    Button {
                        queue.copyToClipboard(item)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .help("Copy to clipboard (keep in queue)")

                    Button(role: .destructive) {
                        queue.remove(item)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove from queue")
                }
                .padding(.vertical, 2)
            }
            .onMove { queue.move(from: $0, to: $1) }
            .onDelete { offsets in
                offsets.map { queue.items[$0] }.forEach(queue.remove)
            }
        }
        .listStyle(.inset)
        .frame(height: min(CGFloat(queue.items.count) * 34 + 12, 340))
    }

    // MARK: Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("Auto-paste with ⌘⇧V", isOn: $queue.autoPaste)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: queue.autoPaste) { _, newValue in
                        if newValue {
                            accessibilityGranted = Paster.accessibilityGranted(prompt: true)
                        }
                    }
                Spacer()
            }

            if queue.autoPaste && !accessibilityGranted {
                Button {
                    accessibilityGranted = Paster.accessibilityGranted(prompt: true)
                    openAccessibilitySettings()
                } label: {
                    Label("Grant Accessibility permission to enable auto-paste",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                }
                .buttonStyle(.link)
            } else {
                Text(queue.autoPaste
                     ? "⌘⇧V pastes the next item automatically."
                     : "⌘⇧V loads the next item — then press ⌘V to paste it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Clear All") { queue.clear() }
                    .disabled(queue.items.isEmpty)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            .controlSize(.small)
        }
        .padding(12)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
