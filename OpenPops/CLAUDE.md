# OpenPops

Folders of apps, files and links in the Mac's Dock; a free take on DockPops.
Part of SPIIIRA Apps, Jonas's collection of Mac apps.

## Working with Jonas

- Jonas is not a programmer. Use plain language and give exact steps.
- No emojis.
- Ask before doing anything beyond the task.

## Building

- A Swift package with no Xcode project. `./build.sh` builds
  `build/OpenPops.app`; `--install` also copies it to /Applications, `--zip`
  writes `build/OpenPops.zip`.
- GitHub Actions builds and tests it on a macOS runner for every push
  (`.github/workflows/build.yml`). Cloud sessions can't build Mac apps
  themselves, so check that workflow run instead of claiming a change works.
- Releases: set `VERSION` in `build.sh` and commit it. Jonas then runs the
  Build workflow by hand with "Publish a release" ticked (sessions can't push
  tags).

## Housekeeping

- Keep README.md current when behavior changes.
- Claude sessions can push commits but can't delete branches or push tags.
- Web tools belong in jonasspira/jonasspira.github.io, not here.
