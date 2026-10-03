# Contributing

## Setup
- Lua 5.1 and `make`. Optional: `luacheck`. Nothing else; the tests fake the WoW API.
- `make test` lints and runs the offline tests. `make package` builds the player zip.

## Rules
- Keep every Lua file at 150 lines or fewer, and list new files in `Whereabouts.toc`.
- Settings go through `Defaults.lua` and `Options`. Themes are data (`Themes.lua`).
- Guild only, and nothing is sent while sharing is off. These are tested; do not weaken them.
- Say whether a change was tried in game. Untested is fine; unlabelled is not.

## Changes
- Player-visible changes get a line in `CHANGELOG.md` under the next version.
- Use short imperative commit messages. One topic per pull request.

## Releases
Maintainers: see `docs/RELEASING.md`.
