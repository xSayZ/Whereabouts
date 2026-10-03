# Changelog

All notable changes to Whereabouts. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions: [Semantic Versioning](https://semver.org/). Below 1.0.0, a minor release may change behaviour.

Versions 0.1.0 and 0.2.0 were internal builds made while the addon was being written. They were never published.

## [0.3.1] - 2026-10-03

### Changed
- README describes what Whereabouts is and how it works, and says plainly that Claude (Anthropic's AI
  assistant) was used as a programming assistant: what that covers, what it does not (the addon never contacts
  an AI and has no AI-generated art), and a link to read more about AI-assisted programming.
- GitHub's automatic "Source code (zip)" and "(tar.gz)" downloads on a release no longer include the tests,
  docs, scripts and CI files. The player zip `Whereabouts-X.Y.Z.zip` was already clean.

### Protocol
- Unchanged (version 1).

## [0.3.0] - 2026-10-03

### Added
- Settings panel at Esc > Options > AddOns > Whereabouts, also opened by `/whereabouts`. Controls: sharing,
  theme, pin size, pin opacity, names, minimap button, world-map button, reset appearance. If the game has
  no Settings panel API, a stock window with the same controls opens instead.
- Themes: Classic, Compact, Solid. Add your own in `UserThemes.lua` (field list at the top of `Themes.lua`).
- Pin size (50% to 200%) and opacity (20% to 100%).
- Key binding "Hold to hide names on the map" (Esc > Options > Key Bindings > AddOns).
- Update notice. While sharing is on, each client announces its version to the guild every 10 minutes. If a
  guildmate runs a newer version you get a chat message, a line in the settings, and a note on the minimap
  button tooltip. The link points at the GitHub releases page and is one line in `Version.lua`
  (`UPDATE_URL`); if it is ever empty, the message says so.
- `Defaults.lua`: one file with every starting value. Edit it to change what a fresh install does.
- Commands: `/whereabouts version`, `names`, `map`, `reset`.
- Developer tooling: `Makefile` (`make test`, `make package`), an offline test suite in `tests/`, and release
  checks (TOC version equals the top changelog entry, every file is listed in the TOC, 150-line file cap, one
  `GUILD` constant, sharing defaults to off).
- GitHub Actions: luacheck and the tests run on every push and pull request, along with a dry run of the
  CurseForge packager. Pushing a version tag such as `v0.3.0` builds the player zip and publishes it as a
  GitHub release, with the notes taken from this file. Uploads to CurseForge start once a project is set up
  (see `docs/RELEASING.md` in the source).

### Changed
- The "Whereabouts: On/Off" button on the world map is now optional and off by default.
- The minimap button is now an ordinary setting. The old `hideMinimap` value is converted on load.
- Settings are checked when loaded and when changed. Unusable saved values fall back to the defaults.
- The version number is read from `Whereabouts.toc`, the only place it is written. The release file name
  carries it: `Whereabouts-0.3.0.zip`.
- Source split into smaller files: Comms (sending) and Inbox (receiving); Pins, PinPool and PinArt;
  Config, Panel and Widgets; MapToggle.
- Key binding file now declares `category="ADDONS"` so the binding is listed under AddOns.

### Protocol
- Still version 1. The new `V` message (`1|V|0.3.0`) is additive. Older builds count it as unreadable and
  ignore it, so mixed versions keep working. An announcement uses one send slot, and is skipped while
  sharing is off, inside instances, or outside a guild.

### Known limitations
- Not yet verified in game on Forever: the Settings panel registration, the key binding, the Compact and
  Solid themes, and version announcements.
- The update notice only works through guildmates who run a newer version with sharing on.
- Settings may not persist between sessions on the Forever beta (reported by a third party, unconfirmed).
  Edit `Defaults.lua` to make a choice permanent.
- A guildmate with a modified client could log the positions of everyone who has sharing on.

## [0.2.0] - internal build

### Added
- Round gold-ring marker with the player's class icon. Class comes from the guild roster, so the protocol
  did not change. Names are shown beside each pin in the class colour.
- Pins on parent maps: a friend in a zone also appears on the continent and World maps. Only maps that
  contain the friend's map are used (checked through the parent chain), and the returned rectangle is
  sanity-checked.
- Diagnostics: `/whereabouts debug` (send, receive, rejected, roster, map, canvas and per-pin state),
  `probe` (prints your encoded position, sends nothing), `testpin` (a pin at the map centre).
- Guild-only enforcement beyond the channel: one `GUILD` constant for all traffic, and a check that the sender
  is in your guild roster once it has loaded. A miss asks the server for a fresh roster.
- Minimap button with green ON / red OFF text. Left-click toggles sharing, right-click opens settings, drag
  moves it. It is a named frame created at login, the same pattern as QuestlineJournal, so button
  collectors such as HidingBar can find it.
- Settings window with a sharing checkbox, and an addon-compartment entry.
- README with a privacy section.

### Fixed
- Pins were invisible or nearly so. They were children of the map canvas and Blizzard's map art covered
  them. They now sit on their own overlay at a high frame level, clipped to the map's scroll area.
- Drawing stopped silently where `WorldMapFrame:GetCanvas` does not exist. It now falls back to
  `ScrollContainer.Child` and records why it stopped.
- The minimap button's drag handler could fail where `math.atan2` is missing.
- Your own character appeared as a peer. Fixed in stages: a normalised name compare, then echo learning
  (your own message coming back is recognised without relying on names). When a check is unsure it lets
  the pin through, so a friend is never hidden by it.

### Removed
- Protocol version 2, which put a hash of the character GUID in every message. It was tried and reverted:
  it could not talk to older builds and hid every peer. The format is back to version 1.

## [0.1.0] - internal build

### Added
- First working version: Core, Comms, Roster and Pins. Sharing is opt-in and off by default.
  `/whereabouts on`, `off`, `status`.
- Wire protocol version 1: `1|<map>|<x>|<y>` and `1|OFF`, coordinates 0 to 1000. Unknown versions and
  malformed messages are ignored.
- Send policy: 5 second tick; send only if you moved more than 5 per mille or 30 seconds passed; one message
  per tick; back off on throttle or lockdown; pause in instances and outside a guild. Peers expire after
  45 seconds.
- World-map pins for peers on the map you are viewing.
- Offline tests of the encoder, decoder and send policy.
- Project notes: architecture plan, API notes (each fact marked as untested in game), contributor rules.
