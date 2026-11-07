local ADDON, ns = ...
local Pins = {}
ns.Pins = Pins

local hooked, held = false, false
local draw
local TEST = { x = 500, y = 500 }

-- Options to hide every pin while grouped. Dungeons and raids need none: sharing pauses there.
function Pins.Suppressed()
  local O = ns.Options.Get
  if O("hideInRaid") and IsInRaid and IsInRaid() then return true end
  return O("hideInGroup") and IsInGroup and IsInGroup() and true or false
end

-- Hooks are insecure post-hooks only; no Blizzard map code is replaced.
local function ensureHooks(wm)
  if hooked then return end
  hooked = true
  if wm.HookScript then wm:HookScript("OnShow", function() draw() end) end
  if type(wm.OnMapChanged) == "function" then
    hooksecurefunc(wm, "OnMapChanged", function() draw() end)
  end
  if type(wm.OnCanvasScaleChanged) == "function" then
    hooksecurefunc(wm, "OnCanvasScaleChanged", function() draw() end)
  end
end

-- Fallbacks: other Forever addons rely on ScrollContainer existing even where GetCanvas does not.
local function getCanvas(wm)
  if wm.GetCanvas then return wm:GetCanvas() end
  return wm.ScrollContainer and wm.ScrollContainer.Child
end

local function getMapID(wm)
  if wm.GetMapID then return wm:GetMapID() end
  return wm.mapID
end

-- Pins.why records where the last draw stopped; /whereabouts debug prints it.
draw = function()
  local wm = WorldMapFrame
  if not wm then Pins.why = "no WorldMapFrame" return end
  ensureHooks(wm)
  Pins.draws = (Pins.draws or 0) + 1
  if not wm:IsShown() then Pins.why = "map closed" return end
  local canvas, mapID = getCanvas(wm), getMapID(wm)
  if not canvas then Pins.why = "no canvas" return end
  if not mapID then Pins.why = "no map id" return end
  local ov = ns.PinPool.Overlay(wm)
  local w, h, cs = canvas:GetWidth(), canvas:GetHeight(), canvas:GetScale()
  Pins.w, Pins.h, Pins.cs, Pins.mapID, Pins.canvas = w, h, cs, mapID, canvas
  if not w or not h or w <= 0 or h <= 0 or not cs or cs <= 0 then Pins.why = "bad canvas size" return end

  local O, Pool, M = ns.Options.Get, ns.PinPool, ns.Merge
  ov:SetFrameLevel(ns.Layer.Level(wm))
  if Pins.Suppressed() then
    Pool.HideFrom(1)
    Pins.shown, Pins.why = 0, "hidden while grouped"
    return
  end
  local th, alpha = ns.Themes.Get(O("theme")), O("alpha")
  local scale, names = ns.PinArt.BASE_SCALE * O("size"), O("labels") and not held
  local zones = O("zoneGroups")
  M.Reset()
  for name, peer in ns.Roster.Iterate() do
    local vx, vy = ns.Project.Get(peer, mapID) -- also maps zone positions onto parent maps
    if vx and not ns.Roster.IsSelf(name) then
      if zones and peer.mapID ~= mapID then -- zoomed out: one pin per zone
        local zx, zy = ns.Project.Centre(peer)
        M.Add(name, peer, vx / 1000 * w, vy / 1000 * h, peer.mapID, zx / 1000 * w, zy / 1000 * h)
      else
        M.Add(name, peer, vx / 1000 * w, vy / 1000 * h)
      end
    end
  end
  if Pins.test then M.Add("Test pin", TEST, w / 2, h / 2) end -- /whereabouts testpin: proves rendering without the roster
  -- Pins overlap when their centres are closer than one icon: icon units to canvas units.
  local n = M.Run(ns.PinArt.MERGE * scale * ov:GetEffectiveScale() / canvas:GetEffectiveScale())
  for c = 1, n do
    local p = Pool.Get(c, ov)
    M.Fill(p, c, th)
    p:SetScale(scale)
    M.Alpha(p, alpha)
    p.name:SetShown(names)
    local x, y = M.At(c)
    Pool.Put(p, canvas, x, y)
  end
  Pool.HideFrom(n + 1)
  Pins.shown = n
  Pins.why = n > 0 and "ok" or "no peer on the viewed map"
end

-- Coalesce bursts of roster updates into one redraw.
local dirty, acc = CreateFrame("Frame"), 0
dirty:Hide()
dirty:SetScript("OnUpdate", function(self, dt)
  acc = acc + dt
  if acc < 0.25 then return end
  acc = 0
  self:Hide()
  draw()
end)

function Pins.Refresh() dirty:Show() end

local group = CreateFrame("Frame")
group:RegisterEvent("GROUP_ROSTER_UPDATE")
group:SetScript("OnEvent", Pins.Refresh)

-- After a theme/size/alpha/labels change: force every pin to be re-skinned.
function Pins.Restyle()
  for i = 1, ns.PinPool.Count() do
    local p = ns.PinPool.At(i)
    p.theme, p.key = nil, nil -- key too, so labels pick up a new name format
  end
  Pins.Refresh()
end

-- Hold-to-hide key (Keys.lua). Applies instantly, without a redraw.
function Pins.SetNamesHeld(isHeld)
  held = isHeld and true or false
  local show = ns.Options.Get("labels") and not held
  for i = 1, ns.PinPool.Count() do ns.PinPool.At(i).name:SetShown(show) end
end

function Pins.Clear() ns.PinPool.HideFrom(1) end
function Pins.First() return ns.PinPool.At(1) end

function Pins.ToggleTest()
  Pins.test = not Pins.test
  Pins.Refresh()
  return Pins.test
end
