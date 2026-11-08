local ADDON, ns = ...
local Mini = {}
ns.MiniPins = Mini

-- Minimap diameter in yards per zoom level 0-5 (values as used by HereBeDragons-Pins).
local INDOOR = { [0] = 300, 240, 180, 120, 80, 50 }
local OUTDOOR = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 6, 200, 133 + 1 / 3 }
local TICK, SMALLER = 0.1, 0.6 -- minimap pins are 60% of world map pins
local pins, frame, acc = {}, nil, 0
Mini.shown, Mini.why = 0, "not started"

local function hideFrom(i)
  for j = i, #pins do pins[j]:Hide() end
end

local function stop(why)
  Mini.shown, Mini.why = 0, why
  hideFrom(1)
end

local function ownWorld()
  if not C_Map then return end
  local map = C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return end
  local x, y = pos:GetXY()
  if not x or not y or (issecretvalue and (issecretvalue(x) or issecretvalue(y))) then return end
  if x == 0 and y == 0 then return end
  return ns.Project.WorldPos(map, x, y)
end

local function cvar(name)
  local get = (C_CVar and C_CVar.GetCVar) or GetCVar
  return get and get(name)
end

-- sin/cos of the minimap's rotation; 0/1 when it does not rotate.
local function rotation()
  if cvar("rotateMinimap") ~= "1" or not GetPlayerFacing then return 0, 1 end
  local f = GetPlayerFacing()
  if not f or (issecretvalue and issecretvalue(f)) then return 0, 1 end
  return math.sin(f), math.cos(f)
end

local function pin(i)
  local p = pins[i]
  if not p then
    p = ns.PinArt.New(Minimap, ns.Merge.OnEnter, ns.Merge.OnLeave)
    p:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    pins[i] = p
  end
  return p
end

local function update()
  if not ns.Options.Get("minimapPins") then return stop("option off") end
  if ns.Roster.Count() == 0 then return stop("no peers") end
  if ns.Pins.Suppressed() then return stop("hidden while grouped") end
  local cont, mx, my = ownWorld()
  if not cont then return stop("no own world position") end
  local yards = ((IsIndoors and IsIndoors()) and INDOOR or OUTDOOR)[Minimap:GetZoom() or 0]
  local r = Minimap:GetWidth() / 2
  if not yards or r <= 0 then return stop("bad minimap size") end
  local per, lim = r / (yards / 2), r - 3 -- minimap units per yard; keep pins off the rim
  local sin, cos = rotation()
  local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
  local O, M = ns.Options.Get, ns.Merge
  M.Reset()
  for name, peer in ns.Roster.Iterate() do
    local c, wx, wy = ns.Project.World(peer)
    if c == cont and not ns.Roster.IsSelf(name) then
      local east, north = (my - wy) * per, (wx - mx) * per -- world x points north, world y west
      local x, y = east * cos + north * sin, north * cos - east * sin
      if square and math.abs(x) <= lim and math.abs(y) <= lim or not square and x * x + y * y <= lim * lim then
        M.Add(name, peer, x, y)
      end
    end
  end
  local scale = ns.PinArt.BASE_SCALE * O("size") * SMALLER
  local n = M.Run(ns.PinArt.MERGE * scale)
  local th, alpha = ns.Themes.Get(O("theme")), O("alpha")
  for c = 1, n do
    local p = pin(c)
    M.Fill(p, c, th)
    p:SetScale(scale)
    M.Alpha(p, alpha)
    p.name:Hide()
    local x, y = M.At(c)
    p:ClearAllPoints()
    p:SetPoint("CENTER", Minimap, "CENTER", x / scale, y / scale) -- offsets are in the pin's units
    p:Show()
  end
  hideFrom(n + 1)
  Mini.shown, Mini.why = n, n > 0 and "ok" or "nobody in minimap range"
end
Mini.Update = update

function Mini.Init()
  if frame or not Minimap then return end
  frame = CreateFrame("Frame", nil, Minimap)
  frame:SetScript("OnUpdate", function(_, dt)
    acc = acc + dt
    if acc < TICK then return end
    acc = 0
    update()
  end)
end

function Mini.At(i) return pins[i] end
