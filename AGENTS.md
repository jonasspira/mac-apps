# mac-apps

Jonas's Mac apps, one folder per app: Nib, Tally, Pasties and OpenPops. Each
app folder has its own `AGENTS.md` (how to build that app) and `README.md`.

## Working with Jonas

- Jonas is not a programmer. Use plain language and give exact steps.
- No emojis.
- Ask before doing anything beyond the task.

## What goes here

- Mac apps only, one top-level folder per app. The folder name is the app's name.
- To add an app: create its folder with a `README.md`, an `AGENTS.md` and a
  one-line `CLAUDE.md` (`@AGENTS.md`), and add a row to the table in the
  top-level `README.md`.
- Apps build from the command line with a `build.sh` in their folder and no
  Xcode project. Follow the pattern of the existing apps.

## What doesn't go here

- Web tools. They belong in `jonasspira/jonasspira.github.io`.
- Jonas keeps a few Mac-only folders inside his copy of this repository on
  purpose; git ignores them. Never add a new top-level folder to git without
  asking.

## Releases

- One repository holds several apps, so releases are named after the app: tag
  `<app>-v<version>` in lowercase (for example `tally-v1.1.0`), title
  `<App> <version>`.
- OpenPops publishes its releases through `.github/workflows/openpops.yml`; see
  `OpenPops/AGENTS.md`.
- The 1.0.0 releases stay on the archived per-app repositories.

## Housekeeping

- Several AI tools work on this repository (Claude, Codex, Muse). Start from the
  latest `main`. When the work is done, commit it, and push it or open a pull
  request when Jonas asks, so the next tool starts from it.
- Cloud sessions can't build or run Mac apps. Say so instead of claiming a change
  works; Jonas tests it on his Mac. OpenPops is the exception: GitHub Actions
  builds and tests it.
- Cloud sessions may not be able to delete branches or push tags. Leave those to
  Jonas.
- Keep each app's `README.md` current when its behavior changes.
