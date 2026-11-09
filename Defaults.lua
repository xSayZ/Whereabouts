local ADDON, ns = ...

-- CONFIG FILE. Edit the values below to change what a fresh install starts with.
-- Players can still change everything in game: Esc > Options > AddOns > Whereabouts, or /whereabouts.
-- Settings are saved per addon folder name: keep the folder named exactly Whereabouts, or each update starts fresh.
ns.Defaults = {
  enabled = true,        -- share your location with your guild. Players can turn it off at any time.
  theme = "classic",     -- classic, compact, solid, or any id you add in UserThemes.lua
  size = 1.0,            -- pin size multiplier
  alpha = 1.0,           -- pin opacity
  labels = true,         -- show names beside pins
  nameFormat = "full",   -- full (Firstname Lastname), short (F. Lastname) or initials (FL)
  minimapPins = true,    -- also show pins on the minimap
  hideInGroup = false,   -- hide every pin while in a party or raid group
  hideInRaid = false,    -- hide every pin while in a raid group
  underQuests = true,    -- draw world map pins under quest markers so they stay visible and clickable
  hoverFade = true,      -- fade a pin under the mouse so what is beneath shows through
  zoneGroups = false,    -- WIP: on continent and world maps, one pin per zone
  minimapButton = true,  -- show the minimap button
  mapButton = false,     -- show the On/Off button on the world map
  welcomed = false,      -- the one-time "sharing is on" chat notice has been shown
  onByDefault = false,   -- internal: install has been moved to on-by-default (0.5.0)
}

-- Allowed range for numeric options: { min, max, step }.
ns.Ranges = {
  size = { 0.5, 2.0, 0.1 },
  alpha = { 0.2, 1.0, 0.1 },
}
