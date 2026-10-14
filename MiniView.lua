local ADDON, ns = ...
local View = {}
ns.MiniView = View

-- Optional APIs are read through _G, so one that this client lacks is simply nil.
local G = _G
local sin, cos, abs = math.sin, math.cos, math.abs
local sizes = {}

-- Yards east and north of you -> yards right and up on the minimap.
-- `facing` is GetPlayerFacing() (radians, counter-clockwise from north); pass nil when the minimap does not rotate.
function View.Offset(e, n, facing)
  if not facing then return e, n end
  local s, c = sin(facing), cos(facing)
  return e * c + n * s, -e * s + n * c
end

-- Radius of the area the minimap shows, in yards.
function View.Radius()
  local api = G.C_Minimap and G.C_Minimap.GetViewRadius
  if not api then return end
  local ok, r = pcall(api)
  if ok and type(r) == "number" and r > 0 then return r end
end

-- Your facing when the minimap is set to rotate, otherwise nil.
function View.Facing()
  if not (G.GetCVar and G.GetPlayerFacing) then return end
  if G.GetCVar("rotateMinimap") ~= "1" then return end
  local f = G.GetPlayerFacing()
  if type(f) ~= "number" or (G.issecretvalue and G.issecretvalue(f)) then return end
  return f
end

local function measure(id)
  local ok0, c0, a = pcall(G.C_Map.GetWorldPosFromMapPos, id, G.CreateVector2D(0, 0))
  local ok1, c1, b = pcall(G.C_Map.GetWorldPosFromMapPos, id, G.CreateVector2D(1, 1))
  if not (ok0 and ok1 and c0 == c1 and type(a) == "table" and type(b) == "table") then return end
  -- World x runs north and y runs west, so a map's width is the change in y.
  local w, h = abs((b.y or 0) - (a.y or 0)), abs((b.x or 0) - (a.x or 0))
  if w >= 50 and h >= 50 and w < 100000 and h < 100000 then return { w, h } end
end

-- Width and height of a map in yards, or nil when the client cannot say. Cached per map.
function View.MapYards(id)
  local s = sizes[id]
  if s == nil then
    s = false
    if G.C_Map and G.C_Map.GetWorldPosFromMapPos and G.CreateVector2D then s = measure(id) or false end
    sizes[id] = s
  end
  if s then return s[1], s[2] end
end
