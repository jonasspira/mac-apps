# OpenPops

Folders of apps, files and links in the Mac's Dock; a free take on DockPops.
One of the apps in mac-apps. The rules in the top-level `AGENTS.md` apply here
too.

## Building

- A Swift package with no Xcode project. From this folder, `./build.sh` builds
  `build/OpenPops.app`; `--install` also copies it to /Applications, `--zip`
  writes `build/OpenPops.zip`. `swift test` runs the core tests, on Linux too.
- GitHub Actions builds and tests it on a macOS runner whenever something in
  this folder changes (`.github/workflows/openpops.yml` at the top of the
  repository). Check that run instead of claiming a change works.

## Releases

- Set `VERSION` in `build.sh` and commit it. Jonas then runs the OpenPops
  workflow by hand (Actions > OpenPops > Run workflow) with "Publish a release"
  ticked. It creates the tag `openpops-v<version>` and the release
  "OpenPops <version>". Sessions can't push tags.
