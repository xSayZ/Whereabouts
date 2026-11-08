local ADDON, ns = ...
local Project = {}
ns.Project = Project

local function sane(l, r, t, b)
  return type(l) == "number" and type(r) == "number" and type(t) == "number" and type(b) == "number"
    and r > l and b > t and l > -0.01 and t > -0.01 and r < 1.01 and b < 1.01
end

-- Only project onto maps that contain the peer's map; GetMapRectOnMap on unrelated
-- maps has undocumented behaviour, so never trust it without this check.
local function isAncestor(view, id)
  if not (C_Map and C_Map.GetMapInfo) then return false end
  for _ = 1, 8 do
    local info = C_Map.GetMapInfo(id)
    local parent = info and info.parentMapID
    if not parent or parent == 0 then return false end
    if parent == view then return true end
    id = parent
  end
  return false
end

-- Peer position on the viewed map in permille, or nil if it cannot be shown there.
-- Result is cached on the peer entry until the peer moves or the view changes.
function Project.Get(peer, view)
  if peer.mapID == view then return peer.x, peer.y end
  if peer.vm ~= view or peer.vsm ~= peer.mapID or peer.sx ~= peer.x or peer.sy ~= peer.y then
    peer.vm, peer.vsm, peer.sx, peer.sy, peer.vx, peer.vy = view, peer.mapID, peer.x, peer.y, false, false
    peer.vcx, peer.vcy = false, false
    if C_Map and C_Map.GetMapRectOnMap and isAncestor(view, peer.mapID) then
      local ok, l, r, t, b = pcall(C_Map.GetMapRectOnMap, peer.mapID, view)
      if ok and sane(l, r, t, b) then
        peer.vx = (l + peer.x / 1000 * (r - l)) * 1000
        peer.vy = (t + peer.y / 1000 * (b - t)) * 1000
        peer.vcx, peer.vcy = (l + r) * 500, (t + b) * 500 -- centre of the peer's map, permille
      end
    end
  end
  if peer.vx then return peer.vx, peer.vy end
end

-- Centre of the peer's own map on the view; valid after Project.Get returned a position.
function Project.Centre(peer) return peer.vcx, peer.vcy end

local vec
-- World (yard) position of a map position; nil when the client cannot place it.
function Project.WorldPos(mapID, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
  vec = vec or CreateVector2D(0, 0) -- reused: the minimap calls this ten times a second
  vec:SetXY(x, y)
  local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, vec)
  if not ok or not cont or not pos then return end
  local wx, wy = pos:GetXY()
  if wx and wy then return cont, wx, wy end
end

-- Peer's world position, cached on the peer entry until it moves.
function Project.World(peer)
  if peer.wsm ~= peer.mapID or peer.wsx ~= peer.x or peer.wsy ~= peer.y then
    peer.wsm, peer.wsx, peer.wsy = peer.mapID, peer.x, peer.y
    peer.wc, peer.wx, peer.wy = Project.WorldPos(peer.mapID, peer.x / 1000, peer.y / 1000)
  end
  return peer.wc, peer.wx, peer.wy
end
