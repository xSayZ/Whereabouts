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
    if C_Map and C_Map.GetMapRectOnMap and isAncestor(view, peer.mapID) then
      local ok, l, r, t, b = pcall(C_Map.GetMapRectOnMap, peer.mapID, view)
      if ok and sane(l, r, t, b) then
        peer.vx = (l + peer.x / 1000 * (r - l)) * 1000
        peer.vy = (t + peer.y / 1000 * (b - t)) * 1000
      end
    end
  end
  if peer.vx then return peer.vx, peer.vy end
end
