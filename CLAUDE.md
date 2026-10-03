# Whereabouts: WoW Forever guild map-sharing addon

Opt-in addon: guild members who enable it appear as pins on each other's world map. Off by default.
Design: `docs/ARCHITECTURE.md`. Read it only when changing module boundaries or the wire protocol.
Player docs that ship in the zip: `README.md`, `CHANGELOG.md`.

## Target
- WoW Forever beta, modern (Mainline-style) addon API. TOC `## Interface: 16001` (confirmed by third-party sources).
- Lua 5.1 only. No Classic-era APIs: use `C_Map`, `C_ChatInfo`, `C_Timer`.

## Workflow
- `make test`: offline suite (`tests/`, stubbed WoW API). Run after every change; always after touching `Comms`, `Inbox`, `Wire`.
- `make package`: lint (syntax + luacheck) + tests + `dist/Whereabouts-<version>.zip` (runtime files only, layout checked by
  `scripts/check-zip.sh`). `make source`: source zip. `make tag`: tests, clean-tree check, creates `vX.Y.Z` (does not push).
- Release: bump `## Version` in `Whereabouts.toc` (the only place), add the `CHANGELOG.md` entry, `make package`.
  `tests/test_release.lua` fails if the TOC and the changelog disagree.
- Publish: commit, `make tag` (or `git tag -a vX.Y.Z -m "Whereabouts X.Y.Z"`), `git push origin main vX.Y.Z`. The release workflow refuses a
  tag that differs from the TOC version, builds the zip and attaches it. 0.x releases are marked pre-release. CurseForge uploads
  start once the `CURSEFORGE_PROJECT_ID` variable and `CF_API_KEY` secret exist. Full runbook: `docs/RELEASING.md`.
- CI (`.github/workflows/ci.yml`): luacheck + tests, the player zip, and a BigWigs packager dry run. Keep the globals in
  `.luacheckrc` in step with the list under Conventions, and add a WoW API name to `read_globals` when you start using one.
- Files that must not ship are listed in `.pkgmeta` (`ignore:`); `tests/test_release.lua` fails if a new top-level file is neither
  runtime nor ignored.
- `UPDATE_URL` in `Version.lua` points at the repo's `/releases` list (not `/releases/latest`: that 404s while every release is a pre-release, as all 0.x are). Changing it changes player-visible text, so it needs a release.
- SemVer. Patch: fix. Minor: new feature or additive protocol message. Major: incompatible protocol or saved-settings change.
- In-game checks are still manual: `/reload`, `/console scriptErrors 1`, `/whereabouts debug`.

## Token-saving rules (follow strictly)
1. **Read one module, not the repo.** Each file has one job. Do not open other files unless you edit a function that calls them.
2. **File cap: 150 lines** (enforced by `test_release.lua`). Split before exceeding. No god files.
3. **Don't read `libs/` or `docs/API_NOTES.md` in full.** Grep for the specific symbol.
4. **No pasted API docs.** Link or cite the function name. Record only *verified* facts in `docs/API_NOTES.md`, one line each.
5. **Edit, don't rewrite.** Use targeted replacements. Never regenerate a whole file for a small change.
6. **Plan before code** for anything touching `Comms.lua`, `Inbox.lua` or the protocol. Otherwise code directly.
7. **Terse comments** (why, not what). No banner comments, no changelogs in code (that is `CHANGELOG.md`).
8. **Short replies.** Report what changed and what to test. Don't restate the diff.

## Conventions
- Namespace: `local ADDON, ns = ...`. Modules attach to `ns`. Cross-module calls go through `ns` only.
- Globals, and only these: `WhereaboutsDB` (SavedVariables), the slash handler, the named frame
  `WhereaboutsMinimapButton` (so button collectors find it), and for the key binding `WhereaboutsHideNamesKey`
  plus the two `BINDING_` strings.
- Settings: add a key to `Defaults.lua` (and a range in `ns.Ranges` if numeric). Read with `ns.Options.Get`, write
  with `ns.Options.Set`. Never touch `WhereaboutsDB` directly, except `minimapAngle`.
- Themes: data only (`Themes.lua`, `UserThemes.lua`). Drawing code reads theme fields; it never names a theme.
- Wire format lives in `Wire.lua`. Any format change bumps `VERSION` there. An additive message keeps the version;
  older builds must be able to ignore it.
- Hot paths (`OnUpdate`, receive handler): no table allocation, no string concatenation in loops.
- Wrap external-state reads (map position, roster) in nil checks. Positions can be nil or restricted.

## Do not
- Add any audience other than guild. The one `CHANNEL = "GUILD"` constant in `Comms.lua` serves every send and
  receive. No options, no other chat types.
- Broadcast anything while sharing is off, or from inside restricted instances. This includes version announcements.
- Send more than one message per interval (see `Comms.lua` constants).
- Draw or store our own character as a peer. Self is excluded by normalised name (`Roster.IsSelf`) and by echo
  learning in `Inbox.lua`. Never hide other players because a self check is unsure: fail towards showing.
- Add third-party libraries without asking. The reference addon QuestlineJournal uses none.
- Claim an API works on Forever without noting whether it was tested in-game.
