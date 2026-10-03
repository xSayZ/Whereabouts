local S = dofile("tests/stubs.lua"); S.install()
S.roster = { { "Bob-Realm", "WARRIOR" } }
local ns = S.ns(); S.loadAll(ns, "Core")
local wm, canvas = S.map(1429, 0.7)
ns.Options.Init(); ns.Classes.Start()
local function near(a, b) return math.abs(a - b) < 0.01 end
local function offsets(p) return p.pt[4], p.pt[5] end

-- Same-map placement. Pin scale is 0.75, canvas effective scale 0.7: offset = value * 0.7 / 0.75
ns.Roster.Update("Bob-Realm", 1429, 605, 500)
S.redraw()
local pin = ns.Pins.First()
assert(ns.Pins.why == "ok" and ns.Pins.shown == 1, tostring(ns.Pins.why))
local f = 0.7 / 0.75
local ox, oy = offsets(pin)
assert(near(ox, 0.605 * 1000 * f) and near(oy, -0.5 * 600 * f), ox .. "," .. oy)
assert(pin.pt[1] == "CENTER" and pin.pt[2] == canvas and pin.pt[3] == "TOPLEFT", "anchored to the canvas")
assert(pin.parent.level == 5000 and pin.parent.clips == true, "pins sit on a high, clipped overlay")
assert(pin.name.text == "Bob" and pin.px == 605 and pin.pm == 1429)
assert(pin.ring.shown and pin.icon.tex:find("Icons%-Classes"), "classic theme with class icon")

-- Size and opacity are applied, and offsets follow the new scale
ns.Options.Set("size", 2.0); ns.Options.Set("alpha", 0.5); ns.Pins.Restyle(); S.redraw()
assert(pin.scale == 1.5 and pin.alpha == 0.5)
ox, oy = offsets(pin); assert(near(ox, 0.605 * 1000 * 0.7 / 1.5), "offset recomputed for the new size")

-- Theme change re-skins existing pins
ns.Options.Set("theme", "compact"); ns.Pins.Restyle(); S.redraw()
assert(pin.ring.shown == false, "compact has no ring")
ns.Options.Set("theme", "solid"); ns.Pins.Restyle(); S.redraw()
assert(pin.icon.color and pin.edge.shown, "solid theme")
ns.Options.Set("theme", "classic"); ns.Options.Set("size", 1.0); ns.Options.Set("alpha", 1.0); ns.Pins.Restyle(); S.redraw()

-- Names: option, and the hold-to-hide key (instant, no redraw needed)
assert(pin.name.shown == true)
ns.Options.Set("labels", false); S.redraw(); assert(pin.name.shown == false)
ns.Options.Set("labels", true); S.redraw(); assert(pin.name.shown == true)
ns.Pins.SetNamesHeld(true); assert(pin.name.shown == false, "key held hides names at once")
S.redraw(); assert(pin.name.shown == false, "and a redraw keeps them hidden while held")
ns.Pins.SetNamesHeld(false); assert(pin.name.shown == true, "released")
ns.Options.Set("labels", false); ns.Pins.SetNamesHeld(true); ns.Pins.SetNamesHeld(false)
assert(pin.name.shown == false, "releasing the key must not override the 'names off' option")
ns.Options.Set("labels", true); S.redraw()

-- Parent maps: a zone peer is projected onto the continent map, tooltip keeps zone coordinates
S.parents[1429] = 1415; S.rects["1429:1415"] = { 0.5, 0.6, 0.6, 0.7 }
wm.mapID = 1415; S.redraw()
assert(ns.Pins.shown == 1, "projected pin shown")
ox, oy = offsets(pin)
assert(near(ox, 0.5605 * 1000 * f) and near(oy, -0.65 * 600 * f), "projected offsets " .. ox .. "," .. oy)
assert(pin.px == 605 and pin.py == 500, "tooltip keeps zone coordinates")
wm.mapID = 1436; S.redraw(); assert(ns.Pins.shown == 0, "unrelated map shows nothing")
wm.mapID = 1429; S.redraw(); assert(ns.Pins.shown == 1)

-- Your own character is never drawn
ns.Roster.Update("Me", 1429, 1, 1); S.redraw(); assert(ns.Pins.shown == 1)

-- A second player, then the test pin, then clear
ns.Roster.Update("Zed-Realm", 1429, 100, 100); S.redraw(); assert(ns.Pins.shown == 2)
ns.Pins.ToggleTest(); S.redraw(); assert(ns.Pins.shown == 3)
local ox2, oy2 = offsets(ns.PinPool.At(3)); assert(near(ox2, 0.5 * 1000 * f) and near(oy2, -0.5 * 600 * f), "test pin at map centre")
ns.Pins.ToggleTest(); S.redraw(); assert(ns.Pins.shown == 2)
ns.Pins.Clear(); assert(ns.PinPool.At(1).shown == false and ns.PinPool.At(2).shown == false)

-- Map closed: nothing drawn, and it says why
wm.IsShown = function() return false end; S.redraw(); assert(ns.Pins.why == "map closed")
