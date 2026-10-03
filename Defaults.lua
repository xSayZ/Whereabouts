local ADDON, ns = ...

-- CONFIG FILE. Edit the values below to change what a fresh install starts with.
-- Players can still change everything in game: Esc > Options > AddOns > Whereabouts, or /whereabouts.
-- If the game does not keep saved settings between sessions, edit this file to make a choice permanent.
ns.Defaults = {
  enabled = false,       -- share your location with your guild. Keep false: sharing is opt-in.
  theme = "classic",     -- classic, compact, solid, or any id you add in UserThemes.lua
  size = 1.0,            -- pin size multiplier
  alpha = 1.0,           -- pin opacity
  labels = true,         -- show names beside pins
  minimapButton = true,  -- show the minimap button
  mapButton = false,     -- show the On/Off button on the world map
}

-- Allowed range for numeric options: { min, max, step }.
ns.Ranges = {
  size = { 0.5, 2.0, 0.1 },
  alpha = { 0.2, 1.0, 0.1 },
}
