# Nib

A native markdown editor for macOS, inspired by Lettera.
One of the apps in mac-apps. The rules in the top-level `AGENTS.md` apply here
too.

## Building

- No Xcode project and no dependencies. From this folder, `zsh build.sh`
  compiles `Sources/` with `swiftc` into `build/Nib.app` and installs it in
  /Applications.
