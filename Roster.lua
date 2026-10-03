local ADDON, ns = ...
local Roster = {}
ns.Roster = Roster

local EXPIRY = 45 -- seconds without an update
local peers, count = {}, 0

-- Core wires this to Pins.Refresh so Roster never depends on Pins.
Roster.onChange = nil

local function changed()
  local f = Roster.onChange
  if f then f() end
end

-- Normalised compare (case, spaces, punctuation, realm all ignored) so our own echoes can
-- never slip in whatever format Forever sends the sender name in. Results cached per name.
local checked = {}
local function norm(n) return (string.lower(Ambiguate(n, "short")):gsub("[%s%p]", "")) end

function Roster.IsSelf(name)
  local c = checked[name]
  if c ~= nil then return c end
  local me = norm(UnitName("player") or "")
  c = me ~= "" and norm(name) == me
  checked[name] = c
  return c
end

-- Called by Comms when a sender is proven to be us (our own echo came back under that name).
function Roster.MarkSelf(name)
  checked[name] = true
  Roster.Remove(name)
end

function Roster.Update(name, mapID, x, y)
  if Roster.IsSelf(name) then return end
  local p = peers[name]
  if not p then
    p = {}
    peers[name] = p
    count = count + 1
  end
  p.mapID, p.x, p.y, p.t = mapID, x, y, GetTime()
  changed()
end

function Roster.Remove(name)
  if peers[name] then
    peers[name] = nil
    count = count - 1
    changed()
  end
end

function Roster.Clear()
  wipe(checked)
  if count == 0 then return end
  wipe(peers)
  count = 0
  changed()
end

function Roster.Iterate()
  return pairs(peers)
end

function Roster.Count()
  return count
end

function Roster.Expire(now)
  local removed = false
  for name, p in pairs(peers) do
    if now - p.t > EXPIRY then
      peers[name] = nil -- clearing during traversal is allowed
      count = count - 1
      removed = true
    end
  end
  if removed then changed() end
end
