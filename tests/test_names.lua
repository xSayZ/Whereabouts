local S = dofile("tests/stubs.lua"); S.install()
S.roster = { { "Cnas Ohlson-Realm", "WARRIOR" } }
local ns = S.ns(); S.loadAll(ns, "Core")
S.map(1429, 0.7)
ns.Options.Init(); ns.Classes.Start()
local O, F = ns.Options, ns.Names.Format

-- The three formats; single-word and multi-byte names stay sensible
assert(O.Get("nameFormat") == "full" and F("Cnas Ohlson") == "Cnas Ohlson")
O.Set("nameFormat", "short"); assert(F("Cnas Ohlson") == "C. Ohlson" and F("Bob") == "Bob")
assert(F("Ann Mary Smith") == "A. Mary Smith")
O.Set("nameFormat", "initials"); assert(F("Cnas Ohlson") == "CO" and F("Bob") == "B")
assert(F("\195\137lise Ohlson") == "\195\137O", "UTF-8 initial kept whole")
assert(O.Set("nameFormat", "bogus") == false and O.Get("nameFormat") == "initials", "unknown format refused")

-- Cycling, and the panel label
assert(ns.Names.Next("full") == "short" and ns.Names.Next("short") == "initials" and ns.Names.Next("initials") == "full")
assert(ns.Names.Label("short") == "F. Lastname" and ns.Names.Label(nil) == "Firstname Lastname")

-- Pins relabel when the format changes; the class lookup still uses the real name
ns.Roster.Update("Cnas Ohlson-Realm", 1429, 500, 500)
O.Set("nameFormat", "full"); ns.Pins.Restyle(); S.redraw()
local p = ns.PinPool.At(1)
assert(p.name.text == "Cnas Ohlson" and p.cls == "WARRIOR")
O.Set("nameFormat", "short"); ns.Pins.Restyle(); S.redraw()
assert(p.name.text == "C. Ohlson" and p.cls == "WARRIOR", tostring(p.name.text))
local title
GameTooltip.SetText = function(_, t) title = t end
ns.Merge.OnEnter(p); assert(title == "Cnas Ohlson", "tooltip keeps the full name: " .. tostring(title))
O.Set("nameFormat", "initials"); ns.Pins.Restyle(); S.redraw()
assert(p.name.text == "CO"); ns.Merge.OnEnter(p); assert(title == "Cnas Ohlson", tostring(title))
O.Set("nameFormat", "short"); ns.Pins.Restyle(); S.redraw()

-- Level and class from the guild roster; merged tooltips show each level
S.roster[1][3], S.roster[1][4] = 42, "Warrior"
S.roster[2] = { "Ann-Realm", "MAGE", 60, "Mage" }
ns.Classes.Stop(); S.now = S.now + 31; ns.Classes.Start()
local lines = {}
GameTooltip.AddLine = function(_, t, r) lines[#lines + 1] = { t, r } end
ns.Merge.OnEnter(p)
assert(lines[1][1] == "Level 42 Warrior" and lines[1][2] == 0.78, tostring(lines[1][1]))
ns.Roster.Update("Ann-Realm", 1429, 501, 500); S.redraw()
lines = {}; ns.Merge.OnEnter(ns.PinPool.At(1))
assert(title == "2 guildmates" and #lines == 2, tostring(title))
local seen = {}
for _, l in ipairs(lines) do seen[l[1]:match("^[^%(]+%(%d+%)")] = true end
assert(seen["A. Mary"] == nil and seen["Ann (60)"] and seen["Cnas Ohlson (42)"], "levels and full names in merged tooltip")
S.roster[2] = nil

-- A bad saved value falls back to the default
WhereaboutsDB.nameFormat = 42; O.Init(); assert(O.Get("nameFormat") == "full")
