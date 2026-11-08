local S = dofile("tests/stubs.lua"); S.install()
S.roster = { { "Bob-Realm", "WARRIOR" }, { "Ann-Realm", "MAGE" } }
local ns = S.ns(); S.loadAll(ns, "Core")
ns.Options.Init(); ns.Classes.Start(); ns.MiniPins.Init()
local M = ns.MiniPins
local function near(a, b) return math.abs(a - b) < 0.01 end
-- 1000 x 1000 yard zone; we stand in the middle. Minimap radius 70 units, zoom 0 outdoors:
-- 466.67 yards across, so 0.3 units per yard. Pin scale 0.75 * 0.6 = 0.45.
S.world[1429] = { cont = 1, left = 5000, top = 9000, w = 1000, h = 1000 }
S.pos = { map = 1429, x = 0.5, y = 0.5 }
local sc = 0.75 * 0.6

ns.Roster.Update("Bob-Realm", 1429, 600, 500) -- 100 yards east
M.Update()
assert(M.shown == 1, tostring(M.why))
local p = M.At(1)
assert(p.pt[2] == Minimap and near(p.pt[4], 30 / sc) and near(p.pt[5], 0), "east: " .. p.pt[4] .. "," .. p.pt[5])
assert(p.scale == sc and p.name.shown == false and p.icon.tex:find("Icons%-Classes"), "small, no name, class icon")

ns.Roster.Update("Bob-Realm", 1429, 500, 400) -- 100 yards north
M.Update(); assert(near(M.At(1).pt[4], 0) and near(M.At(1).pt[5], 30 / sc), "north is up")

-- Rotating minimap facing west: a player to the east is behind us, so below
_G.GetCVar = function(k) return k == "rotateMinimap" and "1" or nil end
_G.GetPlayerFacing = function() return math.pi / 2 end
ns.Roster.Update("Bob-Realm", 1429, 600, 500)
M.Update(); assert(near(M.At(1).pt[4], 0) and near(M.At(1).pt[5], -30 / sc), "rotated")
_G.GetCVar = nil

-- Close players merge; far ones are left off the minimap
ns.Roster.Update("Ann-Realm", 1429, 600, 505)
M.Update(); assert(M.shown == 1 and M.At(1).count == 2, "merged on the minimap")
ns.Roster.Update("Ann-Realm", 1429, 900, 500)
M.Update(); assert(M.shown == 1 and M.At(1).count == 1, "out of range: left off")
assert(M.At(2) == nil or not M.At(2).shown)

-- Another continent, the option, grouping, no own position
S.world[1430] = { cont = 2, left = 0, top = 0, w = 1, h = 1 }
ns.Roster.Update("Bob-Realm", 1430, 500, 500)
M.Update(); assert(M.shown == 0 and M.why == "nobody in minimap range", M.why)
ns.Roster.Update("Bob-Realm", 1429, 600, 500)
ns.Options.Set("minimapPins", false); M.Update(); assert(M.shown == 0 and not M.At(1).shown and M.why == "option off")
ns.Options.Set("minimapPins", true); S.inGroup = true; ns.Options.Set("hideInGroup", true)
M.Update(); assert(M.shown == 0 and M.why == "hidden while grouped")
S.inGroup = false; M.Update(); assert(M.shown == 1)
S.pos = { map = 1429, x = 0, y = 0 }; M.Update(); assert(M.shown == 0 and M.why == "no own world position")
