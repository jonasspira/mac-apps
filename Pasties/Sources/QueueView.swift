import SwiftUI

/// The popover shown when you click the menu bar icon. Styled to Atlassian
/// Design System foundations (color, type, spacing).
struct QueueView: View {
    @EnvironmentObject var queue: ClipboardQueue
    @State private var accessibilityGranted = Paster.accessibilityGranted()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Rectangle().fill(ADS.border).frame(height: 1)

            if queue.items.isEmpty {
                emptyState
            } else {
                list
            }

            Rectangle().fill(ADS.border).frame(height: 1)
            footer
        }
        .frame(width: 340)
        .frame(minHeight: 220)
        .background(ADS.surface)
        .foregroundStyle(ADS.text)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            // Brand mark — Atlassian-blue rounded square with a queue glyph.
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(hex: 0x2684FF), ADS.brand],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text("Pasties")
                .font(.adsHeading)
                .foregroundStyle(ADS.text)

            Spacer()

            // ADS-style badge (lozenge).
            Text("\(queue.items.count)")
                .font(.adsSmallBold)
                .foregroundStyle(ADS.textSubtle)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(ADS.subtleHover, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(ADS.brandSubtle).frame(width: 48, height: 48)
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(ADS.brand)
            }
            Text("Your queue is empty")
                .font(.adsBodyMedium)
                .foregroundStyle(ADS.text)
            HStack(spacing: 4) {
                Text("Copy something with")
                Keycap(text: "⌘C")
                Text("to begin")
            }
            .font(.adsSmall)
            .foregroundStyle(ADS.textSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach(Array(queue.items.enumerated()), id: \.element.id) { index, item in
                QueueRow(index: index, item: item)
                    .environmentObject(queue)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onMove { queue.move(from: $0, to: $1) }
            .onDelete { offsets in
                offsets.map { queue.items[$0] }.forEach(queue.remove)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ADS.surface)
        .frame(height: min(CGFloat(queue.items.count) * 38 + 8, 360))
    }

    // MARK: Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $queue.autoPaste) {
                HStack(spacing: 5) {
                    Text("Auto-paste with").font(.adsBody).foregroundStyle(ADS.text)
                    Keycap(text: "⌘⇧V")
                }
            }
            .toggleStyle(.switch)
            .tint(ADS.brand)
            .controlSize(.small)
            .onChange(of: queue.autoPaste) { _, newValue in
                if newValue { accessibilityGranted = Paster.accessibilityGranted(prompt: true) }
            }

            if queue.autoPaste && !accessibilityGranted {
                Button {
                    accessibilityGranted = Paster.accessibilityGranted(prompt: true)
                    openAccessibilitySettings()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Grant Accessibility permission to enable auto-paste")
                    }
                    .font(.adsSmall)
                    .foregroundStyle(ADS.danger)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 4) {
                    if queue.autoPaste {
                        Text("Press"); Keycap(text: "⌘⇧V"); Text("to paste the next item.")
                    } else {
                        Text("Press"); Keycap(text: "⌘⇧V"); Text("then"); Keycap(text: "⌘V")
                        Text("to paste.")
                    }
                }
                .font(.adsSmall)
                .foregroundStyle(ADS.textSubtle)
            }

            HStack {
                Button("Clear All") { queue.clear() }
                    .buttonStyle(ADSSubtleButton(role: .destructive))
                    .disabled(queue.items.isEmpty)
                    .opacity(queue.items.isEmpty ? 0.4 : 1)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(ADSSubtleButton())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

/// A single row in the queue, with Atlassian-style hover highlight.
private struct QueueRow: View {
    @EnvironmentObject var queue: ClipboardQueue
    let index: Int
    let item: ClipItem
    @State private var hovering = false

    private var isNext: Bool { index == 0 }

    var body: some View {
        HStack(spacing: 9) {
            // Position badge — the next item gets a bold brand circle.
            Text("\(index + 1)")
                .font(.adsSmallBold)
                .foregroundStyle(isNext ? .white : ADS.textSubtle)
                .frame(width: 20, height: 20)
                .background(isNext ? AnyShapeStyle(ADS.brand)
                                   : AnyShapeStyle(ADS.subtleHover),
                            in: Circle())

            Text(item.preview)
                .font(.adsBody)
                .foregroundStyle(ADS.text)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            if hovering {
                Button { queue.copyToClipboard(item) } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(ADS.textSubtlest)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard (keep in queue)")

                Button { queue.remove(item) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ADS.textSubtlest)
                }
                .buttonStyle(.plain)
                .help("Remove from queue")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(hovering ? ADS.subtleHover : Color.clear,
                    in: RoundedRectangle(cornerRadius: ADS.radius))
        .onHover { hovering = $0 }
    }
}
