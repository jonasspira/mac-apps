# Pasties

A tiny macOS **menu bar clipboard queue** — copy several things, then paste them
one at a time in quick succession. Inspired by
[Paste Queue](https://apprywhere.com/paste-queue.html), but free, open, and
installable without the App Store (handy on a company-managed Mac).

No Xcode required — it builds from the command line with the same
`swiftc` setup used across SpiraOS.

## What it does

- Lives in your **menu bar** (no Dock icon, no window in the way).
- Every time you copy (`⌘C`), the text is added to a visible **queue**.
- The core flow: copy a bunch of things → go to your target app → press
  **`⌘⇧V`** repeatedly to paste them **in order, one per press**.
- Click any queued item to copy it, drag to **reorder**, delete individually,
  or **Clear All**.

### Two paste modes

| Mode | What `⌘⇧V` does | Needs permission? |
|------|-----------------|-------------------|
| **Default** | Loads the next item onto the clipboard — you then press `⌘V` | No |
| **Auto-paste** (toggle in the popover) | Pastes the next item for you automatically | Yes — macOS Accessibility |

Auto-paste makes the "quick succession" flow seamless: one `⌘⇧V` per item.
Flip the **Auto-paste** switch in the popover and macOS will prompt you to grant
Accessibility permission (System Settings ▸ Privacy & Security ▸ Accessibility).

## Install

You need Apple's **Command Line Tools** (you already have them if you've built
other SpiraOS apps). If not: `xcode-select --install`.

```sh
git clone https://github.com/jonasspira/Pasties.git
cd Pasties
./build.sh
```

`build.sh` compiles the app, renders the icon, ad-hoc signs it, and installs
**Pasties.app** to `/Applications`. Launch it from there — the icon appears
in your menu bar.

> Because it's built locally on your own machine, macOS Gatekeeper doesn't block
> it (no "unidentified developer" warning).

## Usage

1. Copy a few things with `⌘C` — they stack up in the queue (click the menu bar
   icon to see them).
2. Click into wherever you want to paste.
3. Press `⌘⇧V` for each item, in order.

## Design

Styled to the [Atlassian Design System](https://atlassian.design/foundations)
foundations:

- **Color** — brand blue `#0C66E4` for primary actions, navy `#172B4D` text,
  neutral grays (`#F7F8F9` / `#DCDFE4`), and `#C9372C` for destructive actions.
- **Type** — Atlassian's product UI uses the OS system font stack (SF Pro on
  macOS), with ADS's 14px body / 16px semibold heading scale. (Atlassian's
  proprietary *Charlie Sans* brand font can't be redistributed, so we use the
  same system-font approach their products do.)
- **Components** — ADS-style badges, keycap lozenges, subtle hover states, and
  primary/subtle buttons. Tokens live in `Sources/Theme.swift`.

## Notes

- The queue holds **text**. Images/files aren't queued (could be added later).
- The queue is in-memory and clears when you quit.
- Rebuilding changes the app's ad-hoc signature, so macOS may ask you to
  re-grant Accessibility after a rebuild. Day to day you won't rebuild, so this
  is a one-time thing.

## Project layout

```
Sources/
  App.swift             @main entry, menu bar scene, global hotkey wiring
  ClipboardQueue.swift  clipboard monitoring + the queue model
  QueueView.swift       the popover UI (Atlassian-styled)
  Theme.swift           Atlassian Design System tokens (color, type, buttons)
  HotKey.swift          global ⌘⇧V hotkey (Carbon, no permission needed)
  Paster.swift          ⌘V simulation for auto-paste (needs Accessibility)
scripts/make_icon.swift  generates the app icon
build.sh                 compile → sign → install
```
