# Nib

A native markdown editor for macOS, inspired by [Lettera](https://lettera.md)
(the standalone editor from the Bear team). Built with SwiftUI + AppKit —
no Xcode project, no dependencies.

Nib works directly on your real files: open a single `.md` file, or open a
whole folder as a writing workspace. There's no library or database — what
you see in the sidebar is what's on disk.

## Download

Grab **Nib.zip** from the [latest release](https://github.com/jonasspira/Nib/releases/latest),
unzip it, and drag Nib.app into your Applications folder.

Nib is signed ad-hoc (not notarized with Apple), so the first launch needs
one extra step: macOS will say the app "cannot be opened". Go to
**System Settings → Privacy & Security**, scroll down, and click
**Open Anyway** next to the Nib message. This is only needed once.

Requires macOS 14+ on Apple Silicon.

## Features

- **Live hybrid editing** — markdown styles itself as you type: headings get
  big, `**bold**` gets bold, `` `code` `` gets monospaced. The syntax markers
  fade to near-invisible except on the line your cursor is on.
- **Folder workspaces** — open a folder and its markdown files appear in the
  sidebar, with a filter field and one-click switching.
- **Tabs** — work across several documents at once. The dot means unsaved
  changes (files autosave a second after you stop typing anyway).
- **Outline panel** — every heading in the document, click to jump.
- **Stats bar** — live word count, character count, paragraphs, reading time.
- **Copy as** Markdown / Rich Text / HTML / Plain Text — from the share
  button in the toolbar or File → Copy & Export.
- **Export** to PDF, HTML, or Markdown; printing works too.
- **Smart lists** — pressing Return inside a list continues it with a fresh
  bullet, number, or `- [ ]` checkbox; Return on an empty item ends the list.

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New document (in the workspace folder) |
| ⌘O | Open file |
| ⇧⌘O | Open folder as workspace |
| ⌘S / ⇧⌘S | Save / Save As |
| ⌘W | Close tab |
| ⌘B / ⌘I / ⌘E / ⌘K | Bold / Italic / Code / Link |
| ⇧⌘X | Strikethrough |
| ⌥⌘1 | Show/hide outline |
| ⌘F | Find in document |
| ⌘P | Print |

## Building

```
zsh build.sh
```

Compiles everything and installs Nib.app into /Applications. Requires
Xcode command line tools (`swiftc`) on Apple Silicon, macOS 14+.

The app icon is generated from `Icon.png`; a placeholder can be regenerated
with `swift scripts/make_placeholder_icon.swift Icon.png`.

## How it's organized

- `Sources/App.swift` — app entry point and the menu bar
- `Sources/AppModel.swift` — documents, tabs, workspace folder, autosave
- `Sources/ContentView.swift` — window layout: sidebar, tabs, outline, stats
- `Sources/EditorView.swift` — the text editor (wraps NSTextView)
- `Sources/MarkdownStyler.swift` — live styling, outline extraction, stats
- `Sources/MarkdownHTML.swift` — markdown → HTML (for copy/export)
- `Sources/Exporter.swift` — Copy as… and Export… implementations
- `Sources/Theme.swift` — fonts and colors (adapts to light/dark mode)
