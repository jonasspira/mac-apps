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
- Several AI tools work on this repository (Claude, Codex, Muse). Start from the
  latest `main`. When the work is done, commit it, and push it or open a pull
  request when Jonas asks, so the next tool starts from it.
- Cloud sessions may not be able to delete branches or push tags. Leave those to
  Jonas.
- Web tools belong in jonasspira/jonasspira.github.io, not here.
