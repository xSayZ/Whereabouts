local S = dofile("tests/stubs.lua"); S.install()
S.roster = { { "Bob-Realm", "WARRIOR" }, { "Ann-Realm", "MAGE" }, { "Zed-Realm", "WARRIOR" } }
local ns = S.ns(); S.loadAll(ns, "Core")
local wm, canvas = S.map(1429, 0.7)
ns.Options.Init(); ns.Classes.Start()
local function pinWithCount(c)
  for i = 1, ns.Pins.shown do local p = ns.PinPool.At(i) if p.count == c then return p end end
end

-- Two players 10 canvas units apart merge (threshold 20 * 0.75 / 0.7); a third stays apart
ns.Roster.Update("Bob-Realm", 1429, 500, 500)
ns.Roster.Update("Ann-Realm", 1429, 510, 500)
ns.Roster.Update("Zed-Realm", 1429, 800, 800)
S.redraw()
assert(ns.Pins.shown == 2, "merged into two pins, got " .. tostring(ns.Pins.shown))
local m = assert(pinWithCount(2), "a pin holds two players")
assert(m.name.text == "Ann +1", "label names the alphabetically first player: " .. tostring(m.name.text))
assert(m.num.shown and m.num.text == 2 and m.icon.alpha < 1, "count over a dimmed icon")
assert(#m.members == 2 and m.mpeers[1] and m.mpeers[2], "members kept for the tooltip")
local single = assert(pinWithCount(1))
assert(single.num.shown == false and single.name.text == "Zed")

-- Tooltip lists every member in class colour
local title, lines = nil, {}
GameTooltip.SetText = function(_, t) title = t end
GameTooltip.AddLine = function(_, t, r) lines[#lines + 1] = { t, r } end
ns.Merge.OnEnter(m)
assert(title == "2 guildmates" and #lines == 2, tostring(title))
for _, l in ipairs(lines) do
  if l[1]:find("^Ann") then assert(l[2] == 0.25, "mage colour") else assert(l[2] == 0.78, "warrior colour") end
end

-- Zooming in separates them again
canvas.w, canvas.h = 4000, 2400; S.redraw()
assert(ns.Pins.shown == 3, "zoomed in: three pins")
for i = 1, 3 do local p = ns.PinPool.At(i) assert(p.count == 1 and not p.num.shown and not p.name.text:find("+", 1, true)) end
canvas.w, canvas.h = 1000, 600; S.redraw(); assert(ns.Pins.shown == 2)

-- Hide while grouped: any group, or raid groups only
S.inGroup = true; ns.Options.Set("hideInGroup", true); S.redraw()
assert(ns.Pins.shown == 0 and ns.Pins.why == "hidden while grouped" and not ns.PinPool.At(1).shown)
ns.Options.Set("hideInGroup", false); ns.Options.Set("hideInRaid", true); S.redraw()
assert(ns.Pins.shown == 2, "a party is not a raid")
S.inRaid = true; S.redraw(); assert(ns.Pins.shown == 0, "raid group hides")
S.inGroup, S.inRaid = false, false; S.redraw(); assert(ns.Pins.shown == 2)

-- Under quest markers: overlay sits just below the lowest quest pin; on top without any
local ov = ns.PinPool.At(1).parent
assert(ov.level == 5000, "no pin enumeration: on top")
local levels = { QuestPinTemplate = { 300, 280 }, WorldQuestPinTemplate = { 400 } }
wm.EnumeratePinsByTemplate = function(_, t)
  local i, l = 0, levels[t] or {}
  return function() i = i + 1 if l[i] then return { GetFrameLevel = function() return l[i] end } end end
end
S.redraw(); assert(ov.level == 278, "under the lowest quest marker, got " .. ov.level)
ns.Options.Set("underQuests", false); S.redraw(); assert(ov.level == 5000, "option off: on top")
ns.Options.Set("underQuests", true); levels = {}; S.redraw(); assert(ov.level == 5000, "no quest markers: on top")
wm.EnumeratePinsByTemplate = function() error("boom") end
S.redraw(); assert(ov.level == 5000 and ns.Pins.shown == 2, "enumeration errors are contained")

-- Other addons' quest templates in the map's pin pools count too; area blobs do not
wm.pinPools = { MyQuestAddonPinTemplate = true, QuestBlobPinTemplate = true, GatherNodeTemplate = true }
levels = { MyQuestAddonPinTemplate = { 250 }, QuestBlobPinTemplate = { 10 }, GatherNodeTemplate = { 20 } }
wm.EnumeratePinsByTemplate = function(_, t)
  local i, l = 0, levels[t] or {}
  return function() i = i + 1 if l[i] then return { GetFrameLevel = function() return l[i] end } end end
end
S.redraw(); assert(ov.level == 248, "addon quest pins counted, blobs and others ignored: " .. ov.level)
ns.Debug.Layers()
wm.pinPools, wm.EnumeratePinsByTemplate = nil, nil

-- Hover fade survives redraws and is undone on leave; off when the option is off
local hp = ns.PinPool.At(1)
ns.Merge.OnEnter(hp); assert(hp.alpha == ns.Merge.FADE)
S.redraw(); assert(hp.alpha == ns.Merge.FADE, "redraw keeps the fade")
ns.Merge.OnLeave(hp); assert(hp.alpha == 1)
ns.Options.Set("hoverFade", false); ns.Merge.OnEnter(hp); assert(hp.alpha == 1); ns.Merge.OnLeave(hp)
ns.Options.Set("hoverFade", true)

-- Zone groups (WIP): on a parent map, players in the same zone share a pin at the zone's centre
ns.Roster.Remove("Zed-Realm")
ns.Roster.Update("Bob-Realm", 1429, 100, 100); ns.Roster.Update("Ann-Realm", 1429, 900, 900)
S.parents[1429] = 1415; S.rects["1429:1415"] = { 0.2, 0.6, 0.2, 0.6 }
wm.mapID = 1415; S.redraw(); assert(ns.Pins.shown == 2, "far apart: two pins without zone groups")
ns.Options.Set("zoneGroups", true); S.redraw()
assert(ns.Pins.shown == 1, "one pin for the zone")
local z = ns.PinPool.At(1)
assert(z.count == 2 and z.name.text == "Map1429 (2)", tostring(z.name.text))
assert(math.abs(z.pt[4] - 400 * 0.7 / 0.75) < 0.01 and math.abs(z.pt[5] + 240 * 0.7 / 0.75) < 0.01, "at the zone centre")
title = nil; ns.Merge.OnEnter(z); assert(title == "Map1429: 2 guildmates"); ns.Merge.OnLeave(z)
ns.Roster.Remove("Ann-Realm"); S.redraw()
assert(ns.Pins.shown == 1 and ns.PinPool.At(1).name.text == "Bob", "alone in a zone: a normal pin")
assert(math.abs(ns.PinPool.At(1).pt[4] - 240 * 0.7 / 0.75) < 0.01, "at their real position")
wm.mapID = 1429; ns.Roster.Update("Ann-Realm", 1429, 105, 100); S.redraw()
assert(ns.Pins.shown == 1 and ns.PinPool.At(1).name.text == "Ann +1", "on the zone map itself: normal merging")
