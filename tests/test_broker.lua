-- Minimap button through LibDBIcon when another addon loaded it; our own button otherwise.
local S = dofile("tests/stubs.lua"); S.install()
_G.print = function() end
_G.WhereaboutsMinimapButton = nil

local registered, shown, objects = {}, {}, {}
local ldb = { NewDataObject = function(_, name, t) if objects[name] then return nil end objects[name] = t return t end }
local dbi = {
  Register = function(_, name, obj, db) registered[name] = { obj = obj, db = db } shown[name] = not db.hide end,
  Show = function(_, name) shown[name] = true end,
  Hide = function(_, name) shown[name] = false end,
}
_G.LibStub = function(name) return (name == "LibDataBroker-1.1" and ldb) or (name == "LibDBIcon-1.0" and dbi) or nil end

local ns = S.ns(); ns.IsEnabled = nil
S.loadAll(ns)
local core = S.frameWithEvent("ADDON_LOADED")
core.scripts.OnEvent(core, "ADDON_LOADED", "Whereabouts")
core.scripts.OnEvent(core, "PLAYER_LOGIN")

local r = registered.Whereabouts
assert(r and r.db == WhereaboutsDB.minimapIcon, "registered with LibDBIcon, position saved in our DB")
assert(_G.WhereaboutsMinimapButton == nil, "no second, custom button for collectors to wrap")
local obj = r.obj
assert(obj.icon and obj.text == "ON" and obj.iconG == 1 and obj.iconR < 1, "on: green tint")

obj.OnClick(nil, "LeftButton")
assert(WhereaboutsDB.enabled == false and obj.text == "OFF" and obj.iconR == 1 and obj.iconG < 1, "click: off, red tint")
obj.OnClick(nil, "LeftButton"); assert(WhereaboutsDB.enabled == true)

local lines = {}
local tt = { SetText = function(_, t) lines[#lines + 1] = t end, AddLine = function(_, t) lines[#lines + 1] = t end }
obj.OnTooltipShow(tt)
assert(lines[1]:find("Whereabouts", 1, true) and #lines >= 4, "our tooltip, not a generic one")

SlashCmdList.WHEREABOUTS("minimap"); assert(shown.Whereabouts == false and WhereaboutsDB.minimapIcon.hide == true)
SlashCmdList.WHEREABOUTS("minimap"); assert(shown.Whereabouts == true and WhereaboutsDB.minimapIcon.hide == false)
_G.LibStub = nil
