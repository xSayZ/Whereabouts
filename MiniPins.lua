local ADDON, ns = ...
local Mini = {}
ns.MiniPins = Mini

-- Guildmates on the same map as you, placed by their distance from you in yards.
-- Peers send a position every few seconds, so these pins step rather than glide.
local SCALE = 1.1 -- of the world-map pin size; the minimap size setting multiplies it
local INTERVAL = 0.1
local pins, layer, acc = {}, nil, 0
Mini.why, Mini.shown = "not started", 0

local function hideFrom(n)
  for i = n, #pins do pins[i]:Hide() end
end

local function stop(why)
  Mini.why, Mini.shown = why, 0
  hideFrom(1)
end

local function pinAt(i)
  local p = pins[i]
  if not p then
    p = ns.PinPool.NewPin(layer)
    pins[i] = p
  end
  return p
end

function Mini.Update()
  if ns.Roster.Count() == 0 then return stop("no peers") end
  local map, mx, my = ns.OwnPos.Get()
  if not map then return stop("own position unavailable") end
  local r = ns.MiniView.Radius()
  if not r then return stop("minimap radius unavailable") end
  local w, h = ns.MiniView.MapYards(map)
  if not w then return stop("map size unavailable") end
  local facing = ns.MiniView.Facing()
  local k = Minimap:GetWidth() / 2 / r -- minimap units per yard
  local th, alpha = ns.Themes.Get(ns.Options.Get("theme")), ns.Options.Get("alpha")
  local names = ns.Options.Get("minimapNames")
  local scale, n = ns.PinArt.BASE_SCALE * SCALE * ns.Options.Get("minimapSize"), 0
  for name, peer in ns.Roster.Iterate() do
    if peer.mapID == map and not ns.Roster.IsSelf(name) then
      local sx, sy = ns.MiniView.Offset((peer.x / 1000 - mx) * w, -(peer.y / 1000 - my) * h, facing)
      if sx * sx + sy * sy <= r * r then
        n = n + 1
        local p = pinAt(n)
        if p.key ~= name then
          p.key, p.theme, p.label = name, nil, Ambiguate(name, "short")
          p.name:SetText(p.label)
        end
        local cls = ns.Classes.Get(p.label)
        if p.theme ~= th or p.cls ~= cls then ns.PinArt.Skin(p, th, cls) end
        p.px, p.py, p.pm = peer.x, peer.y, peer.mapID
        p:SetScale(scale)
        p:SetAlpha(alpha)
        p.name:SetShown(names)
        local f = Minimap:GetEffectiveScale() / p:GetEffectiveScale()
        p:ClearAllPoints()
        p:SetPoint("CENTER", Minimap, "CENTER", sx * k * f, sy * k * f)
        p:Show()
      end
    end
  end
  hideFrom(n + 1)
  Mini.shown = n
  Mini.why = n > 0 and "ok" or "no peer within range"
  Mini.radius, Mini.facing = r, facing
end

local function ensure()
  if layer then return layer end
  layer = CreateFrame("Frame", nil, Minimap)
  layer:SetAllPoints(Minimap)
  layer:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  layer:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc >= INTERVAL then
      acc = 0
      Mini.Update()
    end
  end)
  return layer
end

-- Shows or hides the layer to match the options. Hidden, it costs nothing.
function Mini.Refresh()
  if ns.IsEnabled() and ns.Options.Get("minimapPins") then
    ensure():Show()
  elseif layer then
    layer:Hide()
    stop("off")
  end
end

function Mini.Restyle()
  for i = 1, #pins do pins[i].theme = nil end
end

function Mini.Clear() if layer then stop("cleared") end end
function Mini.First() return pins[1] end
