# Whereabouts

Whereabouts shows your guildmates on the world map, so you can see where they are without being in a group
with them. It is made for WoW Forever.

It is opt-in: nothing is sent or shown until you turn it on. Every player who has it on shares their map and
position with their own guild over the game's guild addon channel, and every guildmate who has the addon draws
what it receives as a pin with a name. There is no server and no website behind it.

## Install
- Copy the `Whereabouts` folder to `World of Warcraft/_classic_beta_/Interface/AddOns/`.
- Everyone who wants to see or be seen needs the addon.

## Use
- `/whereabouts` opens the settings (Esc > Options > AddOns > Whereabouts).
- Minimap button: left-click turns sharing on or off, right-click opens settings, drag to move.
- Open the map (M). Guildmates with sharing on appear as pins with their names.

## Features
- Pins on zone, continent and world maps.
- Class icon and class-coloured name.
- Themes: Classic, Compact, Solid. Add your own in `UserThemes.lua`.
- Pin size and opacity.
- Key binding to hide names while held (Esc > Options > Key Bindings > AddOns).
- Optional On/Off button on the world map (off by default).
- Tells you when a guildmate runs a newer version.

## Commands
- `/whereabouts on | off | status | version | names | map | minimap | reset`
- `/whereabouts debug | probe | testpin` for troubleshooting.

## Privacy
- Off by default. Guild only.
- Sent: your map ID and two position numbers. Nothing inside instances or while sharing is off.
- Your own pin is never shown.
- A guildmate with a modified client could log positions. Turn it on only if you trust your guild.
- The source is open. Read it before you trust it.

## Settings in files
- `Defaults.lua`: starting values for every setting.
- `UserThemes.lua`: your own themes.
- Settings may not survive a restart on the Forever beta. Edit `Defaults.lua` to keep a choice.

## About this project
Whereabouts is written with Claude, Anthropic's AI assistant, used as a programming assistant.
- Claude wrote most of the code and the tests. I decide what the addon does, play-test it in the game, and
  publish it.
- The AI is a development tool only. The addon never contacts an AI, and it has no AI-generated art: every
  icon is one of Blizzard's own.
- AI-written code can be wrong. It is covered by automated tests and by playing the game, but not everything is
  verified in game yet. Known gaps are listed in `CHANGELOG.md`.
- The instructions I give the AI are public too: `CLAUDE.md` in the source repository.
- New to the idea? Simon Willison explains the difference between careless "vibe coding" and responsible
  AI-assisted programming: https://simonwillison.net/2025/Mar/19/vibe-coding/

## More
- Changes: `CHANGELOG.md`
- Source, downloads and bug reports: https://github.com/xSayZ/Whereabouts
