# Whereabouts: Architecture

## Goal
Let opted-in guildmembers see each other on the world map without being in a party. No server: each client
broadcasts its own position over the hidden guild addon channel and draws what it receives.

## Files
```
Whereabouts.toc    version (single source of truth), load order
Bindings.xml       key binding: hold to hide names
Defaults.lua       every default, editable; numeric ranges
Options.lua        validated Get/Set, change listeners, reset
Version.lua        current version, compare, update notice, UPDATE_URL
Themes.lua         theme registry + built-ins;  UserThemes.lua: player-added themes
Roster.lua         peer table, expiry, self exclusion
Project.lua        peer position on the viewed map (zone -> continent -> world)
Classes.lua        class + guild membership from the guild roster
Wire.lua           pure encode/decode of the message format
Comms.lua          send side: position, heartbeat, throttle, version announcement
Inbox.lua          receive side: channel/guild/self checks, dispatch
PinArt.lua         skin one pin from a theme
PinPool.lua        overlay frame, pin reuse, placement
Pins.lua           map hooks, draw loop, hold-to-hide
Widgets.lua        checkbox, stepper, cycle, copy box
Panel.lua          the settings controls
Config.lua         Settings category, fallback window, status text
MapToggle.lua      optional On/Off button on the world map
MinimapButton.lua  minimap button
Keys.lua           key binding handler
Debug.lua          /whereabouts debug
Core.lua           events, slash commands, start/stop decision
tests/             offline tests; Makefile builds the zip
```

## Dependencies
One-way: `Core -> Comms -> Roster <- Pins`. Roster and Classes call back through `onChange` hooks that Core wires
to `Pins.Refresh`, so neither depends on Pins. Pins never calls Comms. `Inbox` reads `Comms.PREFIX/CHANNEL/stats`
and `Comms.LastSent()`. UI modules read and write settings only through `Options`.

## Data flow
```
Send:    tick (5s) -> own mapID/x/y -> moved >5 permille, or 30s heartbeat? -> Wire.Pos -> one queued message
         -> SendAddonMessage(prefix, msg, GUILD). Every 10 min a version announcement takes one tick's slot.
Receive: CHAT_MSG_ADDON -> Inbox: prefix + GUILD channel -> own echo? -> self name? -> Wire.Decode
         -> sender in guild roster? -> Roster.Update / Remove, or Version.Note
Draw:    Roster change -> Pins.Refresh (coalesced 0.25s) -> per peer Project.Get -> theme skin -> PinPool.Put
Expire:  tick (10s) -> Roster.Expire (45s without an update)
Toggle:  off -> send "OFF" once -> stop timers and receiving -> clear roster and pins
```

## Wire protocol (v1, Wire.lua)
- Prefix `WHRBT`. Position `1|<mapID>|<x>|<y>` (x, y integers 0-1000). Stop `1|OFF`. Version `1|V|<x.y.z>`.
- Unknown version or malformed message: ignored. `V` is additive; builds before 0.3.0 ignore it.
- Sender identity comes from the addon message event, not the payload.
- A v2 with a GUID tag was tried and reverted (incompatible with older builds, hid every peer).

## Settings and themes
- `Defaults.lua` defines the keys. `Options.Init` fills gaps and repairs bad values; `Options.Set` validates, clamps
  to `ns.Ranges`, and notifies listeners. Core's listener applies changes everywhere at once.
- A theme is a table (fields at the top of `Themes.lua`). `PinArt.Skin` applies it. New themes need no code changes.

## Guild only and privacy
- One `CHANNEL = "GUILD"` constant in `Comms.lua`. Receive also requires the sender in the guild roster once it
  has loaded (fail-open before that, because the server already limits the channel).
- Nothing is sent while sharing is off, in instances, or outside a guild. The version announcement obeys the same rules.

## Failure modes
| Risk | Handling |
|---|---|
| Addon messaging restricted in instances | Stop sending, clear pins on `IsInInstance()`; resume on exit |
| Own position nil or restricted | Skip the tick |
| Throttling or lockdown | One queued message; back off 15s / 60s |
| Stale pins after crash | 45s expiry |
| Own name format unknown | Name compare + echo learning; never hide others |
| Map art covering pins | Own overlay at frame level 5000, clipped to the scroll area |
| Forever API drift | API calls isolated in Comms, Inbox, Pins, PinPool, Config |
| Modified guild client logging positions | Accepted limitation; opt-in, default off |
| Settings not persisting | `Defaults.lua` is editable |

## Update notice
Addons cannot reach the internet. Clients announce their version in the guild channel; a client that hears a newer
one tells its player and shows `Version.UPDATE_URL`. It only works while sharing is on, and only if a guildmate
already runs the newer version.

## Releasing and CI
- `.github/workflows/ci.yml`: on every push and pull request: luacheck + tests; the player zip (`make package`,
  uploaded as an artifact); a BigWigs packager dry run that must detect Forever and pass `scripts/check-zip.sh`.
- `.github/workflows/release.yml`: on a `v*` tag: `scripts/check-tag.sh` (tag = TOC version, changelog entry exists),
  lint, tests, then a GitHub release (zip + changelog section; pre-release below 1.0.0). A CurseForge job runs only
  when `CURSEFORGE_PROJECT_ID` and `CF_API_KEY` are configured.
- `.pkgmeta` lists what the CurseForge zip leaves out; `Makefile` builds the same file list for the GitHub zip.
  `tests/test_release.lua` fails if a new top-level file is neither shipped nor ignored.
- Runbook and one-time setup: `docs/RELEASING.md`. Rules for contributors: `CLAUDE.md`, `CONTRIBUTING.md`.
