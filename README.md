# Whereabouts

Shows your guildmates on the world map. For WoW Forever. Off until you turn it on.

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

## Settings in files
- `Defaults.lua`: starting values for every setting.
- `UserThemes.lua`: your own themes.
- Settings may not survive a restart on the Forever beta. Edit `Defaults.lua` to keep a choice.

## More
- Changes: `CHANGELOG.md`
- Download and updates: https://github.com/xSayZ/Whereabouts/releases
