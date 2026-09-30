# Pasties

A menu bar clipboard queue for macOS: copy several things, then paste them one
at a time. Part of SPIIIRA Apps, Jonas's collection of Mac apps.

## Working with Jonas

- Jonas is not a programmer. Use plain language and give exact steps.
- No emojis.
- Ask before doing anything beyond the task.

## Building

- No Xcode project. `./build.sh` compiles `Sources/` with `swiftc` into
  `build/Pasties.app` and installs it in /Applications.
- Cloud sessions can't build or run Mac apps. Say so instead of claiming a change
  works; Jonas tests it on his Mac.

## Housekeeping

- Keep README.md current when behavior changes.
- Claude sessions can push commits but can't delete branches or push tags.
- Web tools belong in jonasspira/jonasspira.github.io, not here.
