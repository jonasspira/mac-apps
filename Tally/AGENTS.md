# Tally

A notepad that calculates: a Soulver-style calculator for macOS.
One of the apps in mac-apps. The rules in the top-level `AGENTS.md` apply here
too.

## Building

- No Xcode project. From this folder, `zsh build.sh` compiles `Sources/` with
  `swiftc` into `build/Tally.app` and installs it in /Applications.
- The engine tests run without building the app; the command is under Building
  in README.md.
