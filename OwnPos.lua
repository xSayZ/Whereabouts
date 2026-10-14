local ADDON, ns = ...
local OwnPos = {}
ns.OwnPos = OwnPos

-- Your own map and position as fractions (0-1), or nil when the game gives none.
function OwnPos.Get()
  if not C_Map then return end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return end
  local pos = C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return end
  local x, y = pos:GetXY()
  if not x or not y then return end
  if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then return end
  if x == 0 and y == 0 then return end -- API's "no position" value
  return map, x, y
end
