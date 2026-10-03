local ADDON, ns = ...
local Pins = {}
ns.Pins = Pins

local hooked, held = false, false
local draw

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

  local O, Pool, Art = ns.Options.Get, ns.PinPool, ns.PinArt
  local th, alpha = ns.Themes.Get(O("theme")), O("alpha")
  local scale, names = Art.BASE_SCALE * O("size"), O("labels") and not held
  local n = 0
  for name, peer in ns.Roster.Iterate() do
    local vx, vy = ns.Project.Get(peer, mapID) -- also maps zone positions onto parent maps
    if vx and not ns.Roster.IsSelf(name) then
      n = n + 1
      local p = Pool.Get(n, ov)
      if p.key ~= name then
        p.key, p.theme = name, nil
        p.label = Ambiguate(name, "short")
        p.name:SetText(p.label)
      end
      local cls = ns.Classes.Get(p.label)
      if p.theme ~= th or p.cls ~= cls then Art.Skin(p, th, cls) end
      p.px, p.py, p.pm = peer.x, peer.y, peer.mapID
      p:SetScale(scale)
      p:SetAlpha(alpha)
      p.name:SetShown(names)
      Pool.Put(p, canvas, vx, vy, w, h)
    end
  end
  if Pins.test then -- /whereabouts testpin: proves rendering independent of the roster
    n = n + 1
    local p = Pool.Get(n, ov)
    p.key, p.label, p.px, p.py, p.pm = "test", "Test pin", 500, 500, nil
    p.name:SetText("Test pin")
    Art.Skin(p, th, nil)
    p:SetScale(scale)
    p:SetAlpha(alpha)
    p.name:SetShown(names)
    Pool.Put(p, canvas, 500, 500, w, h)
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

-- After a theme/size/alpha/labels change: force every pin to be re-skinned.
function Pins.Restyle()
  for i = 1, ns.PinPool.Count() do ns.PinPool.At(i).theme = nil end
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
