local S = dofile("tests/stubs.lua"); S.install()
S.roster = { { "Bob-Realm", "WARRIOR" } }
local ns = S.ns(); S.loadAll(ns, "Core")
ns.Options.Init(); ns.Classes.Start()
local function near(a, b) return math.abs(a - b) < 0.01 end

-- Pure maths: no rotation passes through; rotation turns the view so "forward" is up.
local ex, ny = ns.MiniView.Offset(30, 40, nil); assert(ex == 30 and ny == 40)
local a, b = ns.MiniView.Offset(0, 100, math.pi / 2) -- facing west: north is on your right
assert(near(a, 100) and near(b, 0), a .. "," .. b)
a, b = ns.MiniView.Offset(-100, 0, math.pi / 2) -- west is straight ahead
assert(near(a, 0) and near(b, 100), a .. "," .. b)
a, b = ns.MiniView.Offset(0, 100, math.pi) -- facing south: north is behind you
assert(near(a, 0) and near(b, -100), a .. "," .. b)

-- Map size from the world positions of two corners; unknown maps and bad data give nil
local w, h = ns.MiniView.MapYards(1429); assert(w == 4000 and h == 3000, tostring(w) .. "," .. tostring(h))
assert(ns.MiniView.MapYards(9999) == nil)
S.yards[1] = { 10, 10 }; assert(ns.MiniView.MapYards(1) == nil, "implausible size rejected")

-- Radius 200 yards over a 140 wide minimap: 0.35 units per yard. Map is 4000 x 3000 yards.
-- I stand at 0.5,0.5. Bob is 100 yards east (0.025 of the width) and 60 yards north (0.02 of the height).
S.pos = { map = 1429, x = 0.5, y = 0.5 }
ns.Roster.Update("Bob-Realm", 1429, 525, 480)
ns.MiniPins.Refresh(); ns.MiniPins.Update()
local pin = ns.MiniPins.First()
assert(ns.MiniPins.why == "ok" and ns.MiniPins.shown == 1, tostring(ns.MiniPins.why))
local f = 1 / (0.75 * 1.1)
assert(near(pin.pt[4], 100 * 0.35 * f) and near(pin.pt[5], 60 * 0.35 * f), pin.pt[4] .. "," .. pin.pt[5])
assert(pin.pt[2] == _G.Minimap and pin.name.shown == true and pin.name.text == "Bob", "anchored to the minimap, with name")
assert(pin.label == "Bob" and pin.px == 525 and pin.pm == 1429, "tooltip data")

-- Names can be switched off
ns.Options.Set("minimapNames", false); ns.MiniPins.Update(); assert(pin.name.shown == false)
ns.Options.Set("minimapNames", true); ns.MiniPins.Update(); assert(pin.name.shown == true)

-- Minimap size is its own setting and does not follow the world-map size
ns.Options.Set("size", 2.0); ns.MiniPins.Update(); assert(near(pin.scale, 0.75 * 1.1), "world-map size ignored")
ns.Options.Set("size", 1.0)
ns.Options.Set("minimapSize", 2.0); ns.MiniPins.Update()
assert(near(pin.scale, 0.75 * 1.1 * 2), "minimap size applied")
f = 1 / pin.scale
assert(near(pin.pt[4], 100 * 0.35 * f), "offset follows the new scale")
ns.Options.Set("minimapSize", 1.0); ns.MiniPins.Update(); f = 1 / (0.75 * 1.1)

-- Rotation: facing west puts north (Bob is 60 yards north, 100 east) to the right of up
S.rotate, S.facing = "1", math.pi / 2
ns.MiniPins.Update()
local rx, ry = ns.MiniView.Offset(100, 60, math.pi / 2)
assert(near(pin.pt[4], rx * 0.35 * f) and near(pin.pt[5], ry * 0.35 * f), "rotated placement")
S.rotate = "0"

-- Out of range, other map, myself, and the peers that must not appear
ns.Roster.Update("Far-Realm", 1429, 900, 500); ns.MiniPins.Update()
assert(ns.MiniPins.shown == 1, "outside the minimap radius is not drawn")
ns.Roster.Update("Elsewhere-Realm", 1436, 500, 500); ns.MiniPins.Update()
assert(ns.MiniPins.shown == 1, "other map is not drawn")
ns.Roster.Update("Me", 1429, 500, 500); ns.MiniPins.Update()
assert(ns.MiniPins.shown == 1, "never drawn for yourself")

-- Missing data hides everything and says why, rather than guessing
S.radius = nil; ns.MiniPins.Update(); assert(ns.MiniPins.shown == 0 and ns.MiniPins.why:find("radius"))
S.radius = 200; S.yards[1429] = nil; ns.MiniView.MapYards(1429)
S.yards[1429] = { 4000, 3000 }
S.pos = { map = nil }; ns.MiniPins.Update(); assert(ns.MiniPins.shown == 0 and ns.MiniPins.why:find("position"))
S.pos = { map = 1429, x = 0.5, y = 0.5 }; ns.MiniPins.Update(); assert(ns.MiniPins.shown == 1)

-- Option off hides the layer and the pins; on brings it back
ns.Options.Set("minimapPins", false); ns.MiniPins.Refresh()
assert(pin.shown == false and ns.MiniPins.why == "off")
ns.Options.Set("minimapPins", true); ns.MiniPins.Refresh(); ns.MiniPins.Update(); assert(ns.MiniPins.shown == 1)

-- Clearing (sharing turned off, or leaving the guild) hides everything
ns.MiniPins.Clear(); assert(ns.MiniPins.shown == 0 and pin.shown == false)
