# Pasties

A menu bar clipboard queue for macOS: copy several things, then paste them one
at a time.
One of the apps in mac-apps. The rules in the top-level `AGENTS.md` apply here
too.

## Building

- No Xcode project. From this folder, `./build.sh` compiles `Sources/` with
  `swiftc` into `build/Pasties.app` and installs it in /Applications.
