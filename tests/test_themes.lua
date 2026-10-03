local S = dofile("tests/stubs.lua"); S.install()
local ns = S.ns(); S.load(ns, { "Defaults", "Themes", "UserThemes", "PinArt" })
local T, Art = ns.Themes, ns.PinArt

-- Built-ins
for _, id in ipairs({ "classic", "compact", "solid" }) do assert(T.Exists(id), id) end
assert(T.Get("classic").ring and not T.Get("compact").ring and T.Get("solid").icon == "solid")
assert(T.Get("nope").id == "classic", "unknown id falls back to the default theme")

-- Registering your own (what UserThemes.lua does)
assert(T.Register({ id = "mine", name = "Mine", icon = "Interface\\Icons\\X" }) and T.Exists("mine"))
assert(T.Register({ id = "bad id" }) == false and T.Register({}) == false and T.Register("x") == false, "invalid themes refused")
local n = #T.List()
assert(T.Register({ id = "mine", name = "Mine v2" }) and #T.List() == n and T.Get("mine").name == "Mine v2", "same id replaces")
assert(T.Register({ id = "noname" }) and T.Get("noname").name == "noname", "name defaults to id")

-- Cycling visits every theme and wraps
local seen, id = {}, "classic"
for _ = 1, #T.List() do seen[id] = true id = T.Next(id) end
assert(id == "classic" and #T.List() == (function() local c = 0 for _ in pairs(seen) do c = c + 1 end return c end)())

-- Skinning
local function pin() return Art.New(S.frame("Frame"), function() end, function() end) end
local p = pin()
Art.Skin(p, T.Get("classic"), "WARRIOR")
assert(p.ring.shown and p.ring.tex:find("TrackingBorder") and p.bg.shown)
assert(p.icon.tex == "Interface\\WorldStateFrame\\Icons-Classes" and p.icon.tc[2] == 0.25, "class icon")
assert(p.name.tcolor[1] == 0.78, "label takes the class colour")
Art.Skin(p, T.Get("classic"), nil)
assert(p.icon.tex:find("INV_Misc_Map_01"), "unknown class shows the fallback icon")
Art.Skin(p, T.Get("compact"), "MAGE")
assert(p.ring.shown == false and p.bg.shown == false and p.icon.w == 22, "compact: no ring, bigger icon")
Art.Skin(p, T.Get("solid"), "MAGE")
assert(p.icon.color and p.icon.color[3] == 0.92 and p.edge.shown, "solid: class-coloured square with an outline")
Art.Skin(p, T.Get("solid"), nil)
assert(p.icon.color[1] == 1 and p.icon.color[3] == 0, "solid with no class is gold")
T.Register({ id = "fixed", icon = "Interface\\Icons\\Y", ring = "R", ringColor = { 0.1, 0.2, 0.3 },
  label = { color = { 1, 0, 0 }, outline = false } })
Art.Skin(p, T.Get("fixed"), "WARRIOR")
assert(p.icon.tex == "Interface\\Icons\\Y" and p.ring.vc[1] == 0.1)
assert(p.name.tcolor[1] == 1 and p.name.tcolor[2] == 0 and p.name.flags == "", "fixed label colour, no outline")
