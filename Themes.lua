local ADDON, ns = ...
local Themes = {}
ns.Themes = Themes

local list, byId = {}, {}

-- A theme is a table; only `id` is required. Add your own in UserThemes.lua.
--   id            unique, letters/digits/-/_
--   name          shown in the settings
--   ring          texture for a ring around the marker (nil = no ring)
--   ringColor     { r, g, b } tint for the ring
--   background    texture behind the icon (nil = none)
--   icon          "class" (class icon), "solid" (class-coloured square) or a texture path
--   fallbackIcon  texture used when the class is not known
--   iconSize      icon size in pixels (default 17 with a ring, 22 without)
--   label         { color = "class" | { r, g, b }, outline = true | false }
function Themes.Register(def)
  if type(def) ~= "table" or type(def.id) ~= "string" or not def.id:match("^[%w%-_]+$") then
    return false
  end
  def.name = def.name or def.id
  local old = byId[def.id]
  if old then
    for i = 1, #list do if list[i] == old then list[i] = def end end
  else
    list[#list + 1] = def
  end
  byId[def.id] = def
  return true
end

function Themes.Exists(id) return byId[id] ~= nil end
function Themes.List() return list end

function Themes.Get(id)
  return byId[id] or byId[ns.Defaults.theme] or list[1]
end

function Themes.Next(id)
  for i = 1, #list do
    if list[i].id == id then return list[i % #list + 1].id end
  end
  return list[1].id
end

local MAP = "Interface\\Icons\\INV_Misc_Map_01"

Themes.Register({
  id = "classic", name = "Classic",
  ring = "Interface\\Minimap\\MiniMap-TrackingBorder",
  background = "Interface\\Minimap\\UI-Minimap-Background",
  icon = "class", fallbackIcon = MAP,
  label = { color = "class", outline = true },
})
Themes.Register({
  id = "compact", name = "Compact",
  icon = "class", fallbackIcon = MAP, iconSize = 22,
  label = { color = "class", outline = true },
})
Themes.Register({
  id = "solid", name = "Solid",
  icon = "solid", iconSize = 12,
  label = { color = "class", outline = true },
})
