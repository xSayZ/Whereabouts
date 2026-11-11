# Whereabouts

> **AI disclosure:** Whereabouts is written with Claude, Anthropic's AI assistant, used as a programming
> assistant. Claude wrote most of the code and tests; I decide what it does, play-test every version and
> release it. The addon itself never uses AI. Details: [About this project](#about-this-project).

Whereabouts shows your guildmates on the world map, so you can see where they are without being in a group
with them. It is made for WoW Forever.

Sharing is on by default; `/whereabouts off` (or a left-click on the minimap button) stops it. Every player who has it on shares their map and
position with their own guild over the game's guild addon channel, and every guildmate who has the addon draws
what it receives as a pin with a name. There is no server and no website behind it.

## Install
- Copy the `Whereabouts` folder to `World of Warcraft/_classic_beta_/Interface/AddOns/`.
- The folder must be named exactly `Whereabouts` (not `Whereabouts-0.5.0`, and not nested inside another
  folder). The game saves settings by folder name, so a renamed folder loses them on every update.
- Everyone who wants to see or be seen needs the addon.

## Use
- `/whereabouts` opens the settings (Esc > Options > AddOns > Whereabouts).
- Minimap button: left-click turns sharing on or off, right-click opens settings, drag to move.
- Open the map (M). Guildmates with sharing on appear as pins with their names.

## Features
- Pins on zone, continent and world maps, and on the minimap.
- Guildmates standing close together share one pin with a count; hover it for every name.
- Pins stay under quest markers on the world map, and fade when you hover them.
- Optional: hide all pins while in a group, or only in a raid group.
- Work in progress, off by default: one pin per zone on continent and world maps (`/whereabouts zones`).
- Class icon and class-coloured name. Hover a pin for level and class.
- Themes: Classic, Compact, Solid. Add your own in `UserThemes.lua`.
- Pin size and opacity. Names as Firstname Lastname, F. Lastname, or initials (FL).
- Key binding to hide names while held (Esc > Options > Key Bindings > AddOns).
- Optional On/Off button on the world map (off by default).
- Tells you when a guildmate runs a newer version.

## Commands
- `/whereabouts on | off | status | version | names | zones | map | minimap | reset`
- `/whereabouts debug | probe | layers | testpin` for troubleshooting.
- `/whereabouts dev` for addon developers: stops announcing your version, so a build that is not published yet
  does not tell guildmates to update. Saved; type it again to turn it off.

## Privacy
- On by default; `/whereabouts off` stops it. Guild only.
- Sent: your map ID and two position numbers. Nothing inside instances or while sharing is off.
- Your own pin is never shown.
- A guildmate with a modified client could log positions. Turn it off if you do not trust your guild.
- The source is open. Read it before you trust it.

## Settings in files
- `Defaults.lua`: starting values for every setting.
- `UserThemes.lua`: your own themes.
- Settings are saved per folder name: keep the folder named `Whereabouts` so they carry over between versions.

## About this project
Whereabouts is written with Claude, Anthropic's AI assistant, used as a programming assistant.
- Claude wrote most of the code and the tests. I decide what the addon does, play-test it in the game, and
  publish it.
- The AI is a development tool only. The addon never contacts an AI, and it has no AI-generated art: every
  icon is one of Blizzard's own.
- AI-written code can be wrong, so every version is play-tested in the game before it is released, on top of
  the automated tests.
- The instructions I give the AI are public too: `CLAUDE.md` in the source repository.
- New to the idea? Simon Willison explains the difference between careless "vibe coding" and responsible
  AI-assisted programming: https://simonwillison.net/2025/Mar/19/vibe-coding/

## More
- Changes: `CHANGELOG.md`
- License: MIT, see `LICENSE`.
- Source, downloads and bug reports: https://github.com/xSayZ/Whereabouts
